global class skedJobAllocationPostProcessBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    public static final string TAG_DRIVER = 'Driver';
    public static final string TAG_DRIVER_DOT = 'Driver - DOT';
    public static final string TAG_DRIVER_CDL = 'Driver CDL B';
    
    public batchSetting setting;
    public Set<Id> jobAllocationIds;
    
    protected Set<Id> newExceptionIds;

    global skedJobAllocationPostProcessBatch(batchSetting setting, Set<Id> jobAllocationIds) {
        this.setting = setting;
        this.jobAllocationIds = jobAllocationIds;
        this.newExceptionIds = new Set<Id>();
    }

    global List<sObject> start(Database.BatchableContext BC) {
        skedJobAllocationHandler.isRunningPostProcess = TRUE;
        return [
            SELECT Id, Name, sked__Job__c, sked__Resource__c, sked__Travel_Distance__c, sked__Status__c,
                sked__Start__c, sked__Duration__c, sked__Set_End__c, sked_Job_Timezone__c,
                sked_Geoservice_Travel_Time_To__c, sked_Geoservice_Travel_Time_Back__c, 
                sked_Is_Handled_Exception_from_Client__c, sked_Exclude_TAT_Exception__c, sked_Resource_Role__c, 
                sked__Job__r.sked_Drive__c, sked__Job__r.sked_Drive__r.sked_Drive_Date__c, sked__Job__r.sked_Drive__r.Name, sked_Premium_Pay__c,
                sked_DOT__c, sked_CDL__c, sked_Additional_Roles__c
            FROM sked__Job_Allocation__c
            WHERE Id IN :this.jobAllocationIds
        ];
    }

    global void execute(Database.BatchableContext BC, List<sked__Job_Allocation__c> skedAllocations) {
        if (!skedSetting.instance.Admin.migrationMode) {
            captureExceptionLog(skedAllocations);
            updateResourceForLinkedActivities(skedAllocations);
            syncToResourceHoursRecord(skedAllocations);
        }
            
        syncOperationRecordStaff(skedAllocations);
    }

    global void finish(Database.BatchableContext BC) {
        skedJobAllocationHandler.isRunningPostProcess = FALSE;
        if (!this.newExceptionIds.isEmpty()) {
            List<sObject> newExceptions = new List<SObject>();
            for (Id exceptionId : this.newExceptionIds) {
                skedHC__Exception__c ex = new skedHC__Exception__c(Id = exceptionId);
                newExceptions.add(ex);
            }

            skedNotificationService notificationService = new skedTriggerActionNotificationService('Insert', 'skedHC__Exception__c');
            notificationService.generateNotifications(newExceptions);
        }
    }

    /**************************************** PRIVATE METHOD ********************************************/
    private void captureExceptionLog(List<sked__Job_Allocation__c> skedAllocations) {
        List<sked__Job_Allocation__c> allocationsNeedToCaptureException = new List<sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            if (skedAllocation.sked_Is_Handled_Exception_from_Client__c != TRUE) {
                allocationsNeedToCaptureException.add(skedAllocation);
            }
        }
        if (!allocationsNeedToCaptureException.isEmpty()) {
            skedExceptionMasterModel master = initializeMasterModel(allocationsNeedToCaptureException);
            
            List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
            exceptionLog.addAll(captureTravelTimeExceptionLog(master));
            exceptionLog.addAll(captureTurnaroundTimeExceptionLog(master));
            exceptionLog.addAll(captureRequiredTagExceptionLog(master));
            exceptionLog.addAll(capture14hrsMoreExceptionLog(master));
            exceptionLog.addAll(captureBlacklistExceptionLog(master));
            exceptionLog.addAll(captureDriveShiftExceptionLog(master));
            exceptionLog.addAll(captureNonWorkingExceptionLog(master));
            exceptionLog.addAll(captureInvalidCollectionOp(master));
            exceptionLog.addAll(captureRoleRestrictedExceptionLog(master));
            exceptionLog.addAll(captureLinkedDriveMismatchedAssetExceptionLog(master));

            if (!exceptionLog.isEmpty()) {
                upsert exceptionLog;
            }
            
            List<skedHC__Exception__c> unavailabilityExceptionLog = captureUnavailabilityExceptionLog(master);
            exceptionLog.addAll(unavailabilityExceptionLog);
            
            for (skedHC__Exception__c item : exceptionLog) {
                this.newExceptionIds.add(item.Id);
            }
        }
    }

    private void updateResourceForLinkedActivities(List<sked__Job_Allocation__c> newRecords) {
        Set<String> jobAlloctionIds = new Set<string>();

        for (sked__Job_Allocation__c newRecord : newRecords) {
            jobAlloctionIds.add(newRecord.Id);
        }

        if (!jobAlloctionIds.isEmpty()) {
            syncResourceForLinkedActivity(jobAlloctionIds);
        }
    }

    private void syncResourceForLinkedActivity(Set<string> jobAlloctionIds) {
        Set<Id> driveIds = new Set<Id>();
        Set<Id> linkedDriveIds = new Set<Id>();
        Map<string, Set<string>> mapDrive_JobAllocationResourceIds = new Map<string, Set<string>>();
        Map<String, Set<String>> mapLinkedDrive_JobAllocationResourceIds = new Map<String, Set<String>>();
        List<sked__Job_Allocation__c> skedJobAllocations = [
            SELECT Id, sked__Job__c, sked__Job__r.sked_Drive__c, sked__Resource__c,
                sked__Job__r.sked_Drive__r.sked_Linked_Drives__c
            FROM sked__Job_Allocation__c 
            WHERE Id IN :jobAlloctionIds
        ];
        
        for (sked__Job_Allocation__c skedJobAllocation : skedJobAllocations) {
            if (string.isNotBlank(skedJobAllocation.sked__Job__r.sked_Drive__c)) {
                Id driveId = skedJobAllocation.sked__Job__r.sked_Drive__c;
                driveIds.add(driveId);
                Set<string> jobAllocationResourceIdsForDrive = mapDrive_JobAllocationResourceIds.get(driveId);
                if (jobAllocationResourceIdsForDrive == NULL) {
                    jobAllocationResourceIdsForDrive = new Set<string>();
                }
                jobAllocationResourceIdsForDrive.add(skedJobAllocation.sked__Resource__c);
                mapDrive_JobAllocationResourceIds.put(driveId, jobAllocationResourceIdsForDrive);
            }

            if (skedJobAllocation.sked__Job__r.sked_Drive__r != null 
                && string.isNotBlank(skedJobAllocation.sked__Job__r.sked_Drive__r.sked_Linked_Drives__c)) {
                Id linkedDriveId = skedJobAllocation.sked__Job__r.sked_Drive__r.sked_Linked_Drives__c;
                linkedDriveIds.add(linkedDriveId);
                Set<String> jobAllocationResourceIdsForLinkedDrive = mapLinkedDrive_JobAllocationResourceIds.get(linkedDriveId);
                if (jobAllocationResourceIdsForLinkedDrive == null) {
                    jobAllocationResourceIdsForLinkedDrive = new Set<String>();
                }

                jobAllocationResourceIdsForLinkedDrive.add(skedJobAllocation.sked__Resource__c);
                mapLinkedDrive_JobAllocationResourceIds.put(linkedDriveId, jobAllocationResourceIdsForLinkedDrive);
            }
        }

        Map<Id, sked__Activity__c> skedActivitiesById = new Map<Id, sked__Activity__c>();
        if (!driveIds.isEmpty() || !linkedDriveIds.isEmpty()) {
            skedActivitiesById.putAll(new Map<Id, sked__Activity__c>([
                SELECT Id, Name, sked_Drive__c, sked_Linked_Drives__c
                FROM sked__Activity__c
                WHERE ((sked_Drive__c IN :driveIds AND sked_Inherit_Resources_From_Drive__c = TRUE) 
                       OR sked_Linked_Drives__c IN :linkedDriveIds)
                AND sked_Is_Group_Activity__c = TRUE
            ]));
        }

        Map<string, Set<string>> mapDrive_ActivityResourceIds;
        Map<String, Set<String>> mapLinkedDrive_ActivityResourceIds;
        Map<string, sked__Activity_Resource__c> mapActivityIdResourceId_ActivityResourceId = new Map<string, sked__Activity_Resource__c>();
        
        if (!skedActivitiesById.isEmpty()) {
            List<sked__Activity_Resource__c> skedActivityResources = [
                SELECT Id, sked__Activity__c, sked__Activity__r.sked_Drive__c, sked__Resource__c, 
                    sked__Activity__r.sked_Linked_Drives__c
                FROM sked__Activity_Resource__c 
                WHERE sked__Activity__c IN :skedActivitiesById.keySet()
            ];
            mapDrive_ActivityResourceIds = new Map<string, Set<string>>();
            mapLinkedDrive_ActivityResourceIds = new Map<string, Set<string>>();
            for (sked__Activity_Resource__c skedActivityResource : skedActivityResources) {
                if (skedActivityResource.sked__Activity__r.sked_Linked_Drives__c == null) {
                    string key = skedActivityResource.sked__Activity__r.sked_Drive__c + ':' + skedActivityResource.sked__Activity__c;
                    Set<string> driveActivityResourceIds = mapDrive_ActivityResourceIds.get(key);
                    if (driveActivityResourceIds == NULL) {
                        driveActivityResourceIds = new Set<string>();
                    }
                    driveActivityResourceIds.add(skedActivityResource.sked__Resource__c);
                    mapDrive_ActivityResourceIds.put(key, driveActivityResourceIds);
                } else {
                    string key = skedActivityResource.sked__Activity__r.sked_Linked_Drives__c + ':' + skedActivityResource.sked__Activity__c;
                    Set<String> linkedDriveActivityResourceIds = mapLinkedDrive_ActivityResourceIds.get(key);
                    if (linkedDriveActivityResourceIds == null) {
                        linkedDriveActivityResourceIds = new Set<String>();
                    }

                    linkedDriveActivityResourceIds.add(skedActivityResource.sked__Resource__c);
                    mapLinkedDrive_ActivityResourceIds.put(key, linkedDriveActivityResourceIds);
                }
                mapActivityIdResourceId_ActivityResourceId.put(skedActivityResource.sked__Activity__c + ':' + skedActivityResource.sked__Resource__c, skedActivityResource);
            }
        }

        List<sked__Activity_Resource__c> newActivityResources = new List<sked__Activity_Resource__c>();
        List<sked__Activity_Resource__c> deleteActivityResources = new List<sked__Activity_Resource__c>();
        if (mapDrive_ActivityResourceIds != NULL && !mapDrive_ActivityResourceIds.isEmpty()) {
            for (string key : mapDrive_ActivityResourceIds.keySet()) {
                Set<string> activityResourceIdsForDrive = mapDrive_ActivityResourceIds.get(key);
                List<string> keyTokens = key.split(':');
                string driveId = keyTokens.get(0);
                string activityId = keyTokens.get(1);
                Set<string> jobAllocationResourceIds = mapDrive_JobAllocationResourceIds.get(driveId);
                for (string jobAllocationResourceId : jobAllocationResourceIds) {
                    if (!activityResourceIdsForDrive.contains(jobAllocationResourceId)) {
                        sked__Activity_Resource__c newActivityResource = new sked__Activity_Resource__c(
                            sked__Resource__c = jobAllocationResourceId,
                            sked__Activity__c = activityId,
                            sked_Inherited_From_Drive__c = true
                        );
                        newActivityResources.add(newActivityResource);
                    }
                }
            }
        } else if (skedActivitiesById != null && !skedActivitiesById.isEmpty()) {
            for (Id activityId : skedActivitiesById.keySet()) {
                sked__Activity__c activity = skedActivitiesById.get(activityId);
                if (activity.sked_Drive__c != null) {
                    Set<String> jobAllocationResourceIds = mapDrive_JobAllocationResourceIds.get(activity.sked_Drive__c);
                    for (String jobAllocationResourceId : jobAllocationResourceIds) {
                        newActivityResources.add(new sked__Activity_Resource__c(
                            sked__Resource__c = jobAllocationResourceId,
                            sked__Activity__c = activityId,
                            sked_Inherited_From_Drive__c = true
                        ));
                    }
                }
            }
        }

        if (mapLinkedDrive_ActivityResourceIds != null && !mapLinkedDrive_ActivityResourceIds.isEmpty()) {
            for (String key : mapLinkedDrive_ActivityResourceIds.keySet()) {
                Set<String> activityResourceIdsForLinkedDrive = mapLinkedDrive_ActivityResourceIds.get(key);
                List<string> keyTokens = key.split(':');
                string linkedDriveId = keyTokens.get(0);
                string activityId = keyTokens.get(1);
                Set<string> jobAllocationResourceIds = mapLinkedDrive_JobAllocationResourceIds.get(linkedDriveId);
                if (jobAllocationResourceIds != NULL) {
                    for (string jobAllocationResourceId : jobAllocationResourceIds) {
                        if (!activityResourceIdsForLinkedDrive.contains(jobAllocationResourceId)) {
                            sked__Activity_Resource__c newActivityResource = new sked__Activity_Resource__c(
                                sked__Resource__c = jobAllocationResourceId,
                                sked__Activity__c = activityId,
                                sked_Inherited_From_Drive__c = true
                            );
                            newActivityResources.add(newActivityResource);
                        }
                    }
                }
            }
        } else if (skedActivitiesById != null && !skedActivitiesById.isEmpty()) {
            for (Id activityId : skedActivitiesById.keySet()) {
                sked__Activity__c activity = skedActivitiesById.get(activityId);
                if (activity.sked_Linked_Drives__c != null) {
                    Set<String> jobAllocationResourceIds = mapLinkedDrive_JobAllocationResourceIds.get(activity.sked_Linked_Drives__c);
                    if (jobAllocationResourceIds != NULL) {
                        for (String jobAllocationResourceId : jobAllocationResourceIds) {
                            newActivityResources.add(new sked__Activity_Resource__c(
                                sked__Resource__c = jobAllocationResourceId,
                                sked__Activity__c = activityId,
                                sked_Inherited_From_Drive__c = true
                            ));
                        }
                    }
                }
            }
        }
        
        if (!newActivityResources.isEmpty()) {
            insert newActivityResources;
        }
        if (!deleteActivityResources.isEmpty()) {
            delete deleteActivityResources;
        }
    }

    private void syncOperationRecordStaff(List<sked__Job_Allocation__c> newRecords) {
        Map<string, string> mapRoleToPremiumOpPay = skedUtils.getMapRoleToPremiumOpPay();

        Set<string> driveIds = new Set<string>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            if (newRecord.sked_Resource_Role__c != NULL) {
                driveIds.add(newRecord.sked__Job__r.sked_Drive__c);
            }
        }
        List<sked_Operation_Record__c> operationRecords = [SELECT Id, sked_Drive__c
                                                          FROM sked_Operation_Record__c
                                                          WHERE sked_Drive__c IN :driveIds];
        
        Map<string, sked_Operation_Record__c> mapDrive_OperationRecord = new Map<string, sked_Operation_Record__c>();
        for (sked_Operation_Record__c operationRecord : operationRecords) {
            mapDrive_OperationRecord.put(operationRecord.sked_Drive__c, operationRecord);
        }

        List<sked_Operation_Record_Staff__c> newOperationRecordStaffs = new List<sked_Operation_Record_Staff__c>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            if (mapDrive_OperationRecord.containsKey(newRecord.sked__Job__r.sked_Drive__c)) {
                sked_Operation_Record__c operation = mapDrive_OperationRecord.get(newRecord.sked__Job__r.sked_Drive__c);
                sked_Operation_Record_Staff__c newOperationRecordStaff = new sked_Operation_Record_Staff__c(
                    sked_Operation_Record__c = operation.Id,
                    sked_Job__c = newRecord.sked__Job__c,
                    sked_Job_Allocation__c = newRecord.Id,
                    sked_Resource__c = newRecord.sked__Resource__c
                );
                List<string> premiumsOpPayList = new List<string>();
                if (!string.isBlank(newRecord.sked_Resource_Role__c) && mapRoleToPremiumOpPay.containsKey(newRecord.sked_Resource_Role__c)) {
                    string premiumsOpPay = mapRoleToPremiumOpPay.get(newRecord.sked_Resource_Role__c);
                    if (!premiumsOpPayList.contains(premiumsOpPay)) {
                        premiumsOpPayList.add(premiumsOpPay);
                    }
                }
                if (!premiumsOpPayList.isEmpty()) {
                    newOperationRecordStaff.sked_Premiums_Op_Pay__c = string.join(premiumsOpPayList, ';');
                }
                newOperationRecordStaffs.add(newOperationRecordStaff);
            }
        }

        if (!newOperationRecordStaffs.isEmpty()) {
            insert newOperationRecordStaffs;
        }
    }

    /**************************************** RESOURCE HOURS RECORD ********************************************/
    private void syncToResourceHoursRecord(List<sked__Job_Allocation__c> newRecords) {
        Map<string, jobAllocationModel> mapUniqueKey_Allocations = buildMapKey_AllocationModels(newRecords);
        
        List<sked_Resource_Hours_Record__c> resourceHoursRecords = [
            SELECT Id, sked_End_Date__c, sked_Resource__c, sked_Start_Date__c, sked_Unique_Key__c
            FROM sked_Resource_Hours_Record__c
            WHERE sked_Unique_Key__c IN :mapUniqueKey_Allocations.keySet()
            ORDER BY sked_Unique_Key__c ASC
        ];

        List<sked_Resource_Hours_Record__c> newResourceHoursRecords = new List<sked_Resource_Hours_Record__c>();
        for (jobAllocationModel model : mapUniqueKey_Allocations.values()) {
            model.hasKey = false;
            for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {
                if (model.key.equalsIgnoreCase(resourceHoursRecord.sked_Unique_Key__c)) {
                    model.hasKey = true;
                    model.resourceHoursRecord = resourceHoursRecord;
                    break;
                }
            }
            
            if (!model.hasKey) {
                sked_Resource_Hours_Record__c resourceHoursRecord = new sked_Resource_Hours_Record__c(
                    sked_End_Date__c = model.endDate, 
                    sked_Resource__c = model.resourceId, 
                    sked_Start_Date__c = model.startDate, 
                    sked_Unique_Key__c = model.key
                    );
                    
                    model.resourceHoursRecord = resourceHoursRecord;
                    newResourceHoursRecords.add(model.resourceHoursRecord);
                    model.hasKey = true;
                }
        }

        if (!newResourceHoursRecords.isEmpty()) {
            insert newResourceHoursRecords;
        }

        syncToResourceHoursRecordDetail(mapUniqueKey_Allocations);
    }

    private void syncToResourceHoursRecordDetail(Map<string, jobAllocationModel> jobAllocationModelByKey) {
        List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        for (jobAllocationModel model : jobAllocationModelByKey.values()) {
            for (sked__Job_Allocation__c jobAllocation : model.jobAllocations) {
                sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                    sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                    sked_Job_Allocation__c = jobAllocation.Id,
                    sked_Job_Allocation_Status__c = jobAllocation.sked__Status__c,
                    sked_Duration__c = jobAllocation.sked__Duration__c,
                    sked_Job__c = jobAllocation.sked__Job__c
                );
                resourceHoursRecordDetails.add(resourceHoursRecordDetail);
            }
        }

        if (!resourceHoursRecordDetails.isEmpty()) {
            insert resourceHoursRecordDetails;
        }
    }

    private Map<string, jobAllocationModel> buildMapKey_AllocationModels(List<sked__Job_Allocation__c> newRecords) {
        List<string> excludedStatuses = new List<string>();
        excludedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DECLINED);
        excludedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DELETED);
        Map<string, jobAllocationModel> mapUniqueKey_Allocations = new Map<string, jobAllocationModel>();
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);

        for (sked__Job_Allocation__c newRecord : newRecords) {
            if (!excludedStatuses.contains(newRecord.sked__Status__c)) {
                string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                Date jobDate = newRecord.sked__Job__r.sked_Drive__r.sked_Drive_Date__c;
                Date startOfWeek = skedDateTimeUtils.findWeekStartDate(jobDate, workWeekday); 
                Date endOfWeek = startOfWeek.addDays(6);
                string key = skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
                if (mapUniqueKey_Allocations.containsKey(key)) {
                    jobAllocationModel model = mapUniqueKey_Allocations.get(key);
                    model.jobAllocations.add(newRecord);
                }
                else {
                    jobAllocationModel model = new jobAllocationModel();
                    model.resourceId = newRecord.sked__Resource__c;
                    model.startDate = startOfWeek;
                    model.endDate = endOfWeek;
                    model.key = key;
                    model.jobAllocations = new List<sked__Job_Allocation__c>();
                    model.jobAllocations.add(newRecord);
                    mapUniqueKey_Allocations.put(model.key, model);
                }
            }
        }
        return mapUniqueKey_Allocations;
    }

    private Map<Id, string> getMapRecord_WorkWeekday(List<sked__Job_Allocation__c> newRecords) {
        Map<Id, string> mapRecord_WorkWeekday = new Map<Id, string>();
        List<sked__Job_Allocation__c> jobAllocations = [SELECT Id, sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c
                                                        FROM sked__Job_Allocation__c
                                                        WHERE Id IN :newRecords];
        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
            string workWeekday = 'Sunday';
            if (string.isNotBlank(jobAllocation.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c)) {
                workWeekday = jobAllocation.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            }
            mapRecord_WorkWeekday.put(jobAllocation.Id, workWeekday);
        }

        return mapRecord_WorkWeekday;
    }
    
    /**************************************** EXCEPTION LOG PRIVATE METHOD ********************************************/
    private skedExceptionMasterModel initializeMasterModel(List<sked__Job_Allocation__c> skedAllocations) {
        skedExceptionMasterModel master = new skedExceptionMasterModel();
        master.jobAllocations = skedAllocations;
        Set<Id> jobIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            jobIds.add(skedAllocation.sked__Job__c);
            resourceIds.add(skedAllocation.sked__Resource__c);
        }
        master.mapJob = new Map<Id, sked__Job__c>([
            SELECT Id, Name, sked__Start__c, sked__Finish__c, sked__GeoLocation__c, sked__Type__c, sked__Duration__c,
            sked_Drive__c, sked_Drive__r.sked_Account__c, sked_Drive__r.sked_Drive_Site__c, sked_Drive_Shift__c,
            sked_Start_Date__c, sked_Finish_Date__c, sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Collection_Operation__c,
            sked_Drive__r.sked_Linked_Drives__c, sked_Asset_Type__c,sked_Drive__r.Name,//HRP-12840
            (SELECT Id, sked__Tag__c, sked__Tag__r.Name
            FROM sked__JobTags__r)
            FROM sked__Job__c
            WHERE Id IN :jobIds
        ]);

		Set<Id> accountIds = new Set<Id>();
        Set<Id> locationIds = new Set<Id>();
        for (sked__Job__c skedJob : master.mapJob.values()) {
            if (skedJob.sked_Drive__r != NULL) {
                if (skedJob.sked_Drive__r.sked_Account__c != NULL) {
                    accountIds.add(skedJob.sked_Drive__r.sked_Account__c);
                }
                if (skedJob.sked_Drive__r.sked_Drive_Site__c != NULL) {
                    locationIds.add(skedJob.sked_Drive__r.sked_Drive_Site__c);
                }
            }
        }
        
        master.mapResource = new Map<Id, sked__Resource__c>([
            SELECT Id, sked_Maximum_Travel_Radius__c, sked_Turnaround_Time__c, sked__Resource_Type__c,
            sked__GeoLocation__c, sked__Primary_Region__r.sked__Timezone__c, sked_Max_Travel_Time__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, sked_Asset_Type__c,
            (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked_Expiry_Date__c, sked_Start_Date__c, sked_Role_Status__c, sked_Restriction_Start_Date__c, sked_Restriction_End_Date__c
            FROM sked__ResourceTags__r
            WHERE (sked_Role_Status__c = NULL OR sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE)
            ),
            (SELECT Id, sked__Account__c, sked__Resource__c
            FROM sked__Account_Resource_Scores__r
            WHERE sked__Account__c IN :accountIds
            AND sked__Blacklisted__c = TRUE
            ),
            (SELECT Id, sked__Location__c, sked__Resource__c
            FROM sked__Location_Resource_Scores__r
            WHERE sked__Location__c IN :locationIds
            AND sked__Blacklisted__c = TRUE
            ),
            (SELECT Id, sked_Biomed_Collection_Op_Center__c, sked_Start_Date__c, sked_End_Date__c
            FROM sked_Resource_Biomed_Collection_Ops__r
            ),
            (SELECT Id, sked_Collection_Operation__c, sked__Start__c, sked__End__c, sked_Start_Date__c, sked_End_Date__c
            FROM sked__Resource_Overrides__r
            )
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
    	return master;
    }
    
    private List<skedHC__Exception__c> captureTravelTimeExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
            sked__Resource__c resource = master.mapResource.get(skedAllocation.sked__Resource__c);
            
            if (resource.sked_Max_Travel_Time__c != NULL 
                && skedAllocation.sked_Geoservice_Travel_Time_To__c != NULL
                && skedAllocation.sked_Geoservice_Travel_Time_Back__c != NULL) 
            {
                if (resource.sked_Max_Travel_Time__c < skedAllocation.sked_Geoservice_Travel_Time_To__c 
                    || resource.sked_Max_Travel_Time__c < skedAllocation.sked_Geoservice_Travel_Time_Back__c) 
                {
                    skedHC__Exception__c newException = skedExceptionUtils.generateException(skedAllocation, skedConstants.EXCEPTION_CODE_MAXIMUM_TRAVEL_TIME_VIOLATION, '');
                    exceptionLog.add(newException);
                }
            }
        }
        return exceptionLog;
    }
    
    private List<skedHC__Exception__c> captureTurnaroundTimeExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        
        DateTime minTime, maxTime;
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
            resourceIds.add(skedAllocation.sked__Resource__c);
            jobAllocationIds.add(skedAllocation.Id);
            
            sked__Resource__c resource = master.mapResource.get(skedAllocation.sked__Resource__c);
            
            Integer turnaroundTimeHrs = resource.sked_Turnaround_Time__c != NULL ? integer.valueOf(resource.sked_Turnaround_Time__c) : 0;
            sked__Job__c job = master.mapJob.get(skedAllocation.sked__Job__c);
            
            DateTime allowedLatestJobFinishBefore = job.sked__Start__c.addHours(-turnaroundTimeHrs);
            DateTime allowedSoonestJobStartAfter = job.sked__Finish__c.addHours(turnaroundTimeHrs);
            
            if (minTime == NULL || minTime > allowedLatestJobFinishBefore) {
                minTime = allowedLatestJobFinishBefore;
            }
            if (maxTime == NULL || maxTime < allowedSoonestJobStartAfter) {
                maxTime = allowedSoonestJobStartAfter;
            }
        }
        
        if (!jobAllocationIds.isEmpty()) {
            List<sked__Job_Allocation__c> allJobAllocationsInPeriod = [SELECT Id, sked__Resource__c, sked__Job__c,
                                                                       sked__Start__c, sked__Set_End__c
                                                                       FROM sked__Job_Allocation__c
                                                                       WHERE Id NOT IN:jobAllocationIds
                                                                       AND sked__Resource__c IN :resourceIds
                                                                       AND sked__Start__c < :maxTime
                                                                       AND sked__Set_End__c > :minTime
                                                                       AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                                       ORDER BY sked__Start__c ASC];
            Map<Id, List<sked__Job_Allocation__c>> map_resourceId_allocations = new Map<Id, List<sked__Job_Allocation__c>>();
            for (sked__Job_Allocation__c jobAllocation : allJobAllocationsInPeriod) {
                List<sked__Job_Allocation__c> jobAllocations;
                if (map_resourceId_allocations.containsKey(jobAllocation.sked__Resource__c)) {
                    jobAllocations = map_resourceId_allocations.get(jobAllocation.sked__Resource__c);
                }
                else {
                    jobAllocations = new List<sked__Job_Allocation__c>();
                    map_resourceId_allocations.put(jobAllocation.sked__Resource__c, jobAllocations);
                }
                jobAllocations.add(jobAllocation);
            }
            
            for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
                sked__Resource__c resource = master.mapResource.get(skedAllocation.sked__Resource__c);
                if (resource.sked_Turnaround_Time__c != NULL) {
                    if (map_resourceId_allocations.containsKey(skedAllocation.sked__Resource__c)) {
                        Integer turnaroundTimeHrs = integer.valueOf(resource.sked_Turnaround_Time__c);
                        sked__Job__c job = master.mapJob.get(skedAllocation.sked__Job__c);
                        
                        DateTime allowedLatestJobFinishBefore = job.sked__Start__c.addHours(-turnaroundTimeHrs);
                        DateTime allowedSoonestJobStartAfter = job.sked__Finish__c.addHours(turnaroundTimeHrs);
                        
                        List<sked__Job_Allocation__c> jobAllocationsInPeriod = map_resourceId_allocations.get(skedAllocation.sked__Resource__c);
                        for (sked__Job_Allocation__c jobAllocationInPeriod : jobAllocationsInPeriod) {
                            boolean isConflicted = jobAllocationInPeriod.sked__Start__c < job.sked__Finish__c && jobAllocationInPeriod.sked__Set_End__c > job.sked__Start__c;
                            if (!isConflicted) {
                                if (jobAllocationInPeriod.sked__Start__c < allowedSoonestJobStartAfter && jobAllocationInPeriod.sked__Set_End__c > allowedLatestJobFinishBefore) {
                                    skedHC__Exception__c newException = skedExceptionUtils.generateException(jobAllocationInPeriod, skedConstants.EXCEPTION_CODE_TURNAROUND_TIME_VIOLATION, '');
                                    exceptionLog.add(newException);
                                    break;
                                }
                                if (jobAllocationInPeriod.sked__Start__c > allowedSoonestJobStartAfter) {
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return exceptionLog;
    }
    
    private List<skedHC__Exception__c> captureRequiredTagExceptionLog(skedExceptionMasterModel master) {
        List<string> driverTagNames = new List<string>();
        driverTagNames.add(TAG_DRIVER);
        driverTagNames.add(TAG_DRIVER_DOT);
        driverTagNames.add(TAG_DRIVER_CDL);
        
        List<sked__Tag__c> driverTags = [SELECT Id, Name
                                         FROM sked__Tag__c
                                         WHERE Name IN :driverTagNames];
        Map<string, sked__Tag__c> mapDriverTag = new Map<string, sked__Tag__c>();
        for (sked__Tag__c driverTag : driverTags) {
        	mapDriverTag.put(driverTag.Name, driverTag);
        }
        
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
            sked__Job__c job = master.mapJob.get(skedAllocation.sked__Job__c);
            if (job.sked__JobTags__r != NULL && !job.sked__JobTags__r.isEmpty()) {
                if (master.mapResource.containsKey(skedAllocation.sked__Resource__c)) {
                    sked__Resource__c resource = master.mapResource.get(skedAllocation.sked__Resource__c);
                    
                    Set<Id> resourceTagIds = new Set<Id>();
                    if (resource.sked__ResourceTags__r != NULL) {
                        for (sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {
                            if (resourceTag.sked_Start_Date__c <= job.sked_Drive__r.sked_Drive_Date__c) {
                                resourceTagIds.add(resourceTag.sked__Tag__c);
                            }
                        }
                    }
                    
                    for (sked__Job_Tag__c jobTag : job.sked__JobTags__r) {
                        Id tagId = jobTag.sked__Tag__c;
                        string tagName = jobTag.sked__Tag__r.Name;
                        if (tagId == mapDriverTag.get(TAG_DRIVER).Id) {
                            if (skedAllocation.sked_DOT__c == TRUE) {
                                sked__Tag__c driverDotTag = mapDriverTag.get(TAG_DRIVER_DOT);
                                tagId = driverDotTag.Id;
                                tagName = driverDotTag.Name;
                            }
                            if (skedAllocation.sked_CDL__c == TRUE) {
                                sked__Tag__c driverCdlTag = mapDriverTag.get(TAG_DRIVER_CDL);
                                tagId = driverCdlTag.Id;
                                tagName = driverCdlTag.Name;
                            }
                        }
                        
                        if (!resourceTagIds.contains(tagId)) {
                            skedHC__Exception__c newException = skedExceptionUtils.generateException(skedAllocation, skedConstants.EXCEPTION_CODE_MISSING_REQUIRED_TAG, 'Missing required tag ' + tagName);
                            exceptionLog.add(newException);
                        }
                    }
                }
            }
        }
        return exceptionLog;
    }

    private List<skedHC__Exception__c> capture14hrsMoreExceptionLog(skedExceptionMasterModel master) {
        integer maxCDLDOTDurationInMinutes = skedSetting.instance.Admin.maxCDLDOTDuration * 60;

        List<sked_Resource_Role_Group__c> resourceRoleGroups = [SELECT Id, sked_Resource_Role_Group__c, sked_Resource_Roles__c
                                                                FROM sked_Resource_Role_Group__c
                                                                WHERE sked_Resource_Role_Group__c = :skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES];
        List<string> resourceRoles = new List<string>();
        if (resourceRoleGroups != NULL && !resourceRoleGroups.isEmpty()) {
            resourceRoles = resourceRoleGroups.get(0).sked_Resource_Roles__c.split(';');
        }
        
        string exceptionCodeTemplate = 'CDL/DOT staff cannot be scheduled to drive a CDL/DOT vehicle for a shift length that exceeds {{hours}} hours';
        exceptionCodeTemplate = exceptionCodeTemplate.replace('{{hours}}', string.valueOf(skedSetting.instance.Admin.maxCDLDOTDuration));

        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
            sked__Job__c job = master.mapJob.get(skedAllocation.sked__Job__c);
            if (resourceRoles.contains(skedAllocation.sked_Resource_Role__c) && job.sked__Duration__c >= maxCDLDOTDurationInMinutes) {
                skedHC__Exception__c newException = skedExceptionUtils.generateException(skedAllocation, skedConstants.EXCEPTION_CODE_CDL_DOT_HOURS_VIOLATION, exceptionCodeTemplate);
                exceptionLog.add(newException);
            }
        }
        return exceptionLog;
    }
    
    private List<skedHC__Exception__c> captureBlacklistExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        
        Set<string> blacklistedResources = new Set<string>();
        for (sked__Resource__c skedResource : master.mapResource.values()) {
            if (skedResource.sked__Account_Resource_Scores__r != NULL && !skedResource.sked__Account_Resource_Scores__r.isEmpty()) {
                for (sked__Account_Resource_Score__c score : skedResource.sked__Account_Resource_Scores__r) {
                    blacklistedResources.add(score.sked__Account__c + ':' + score.sked__Resource__c);
                }
            }
            if (skedResource.sked__Location_Resource_Scores__r != NULL && !skedResource.sked__Location_Resource_Scores__r.isEmpty()) {
                for (sked__Location_Resource_Score__c score : skedResource.sked__Location_Resource_Scores__r) {
                    blacklistedResources.add(score.sked__Location__c + ':' + score.sked__Resource__c);
                }
            }
        }
        
        for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
            sked__Resource__c resource = master.mapResource.get(skedAllocation.sked__Resource__c);
            sked__Job__c job = master.mapJob.get(skedAllocation.sked__Job__c);
            
            string accountKey = job.sked_Drive__r.sked_Account__c + ':' + resource.id;
            if (blacklistedResources.contains(accountKey)) {
                skedHC__Exception__c newException = skedExceptionUtils.generateException(skedAllocation, skedConstants.EXCEPTION_CODE_RESOURCE_ACCOUNT_DECLINED, '');
                exceptionLog.add(newException);
            }
            string locationKey = job.sked_Drive__r.sked_Drive_Site__c + ':' + resource.id;
            if (blacklistedResources.contains(locationKey)) {
                skedHC__Exception__c newException = skedExceptionUtils.generateException(skedAllocation, skedConstants.EXCEPTION_CODE_RESOURCE_SITE_DECLINED, '');
                exceptionLog.add(newException);
            }
        }
        return exceptionLog;
    }
    
    private List<skedHC__Exception__c> captureDriveShiftExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        
        Set<Id> driveShiftIds = new Set<Id>();
        for (sked__Job__c skedJob : master.mapJob.values()) {
            if (skedJob.sked_Drive_Shift__c != NULL) {
                driveShiftIds.add(skedJob.sked_Drive_Shift__c);
            }
        }
        
        List<sked_Drive_Shift_Tag__c> driveShiftTags = [SELECT Id, sked_Drive_Shift__c, sked_Drive_Shift__r.sked_Drive__c, sked_Tag__c, sked_Tag__r.Name, sked_Minimum_Quantity__c,
                                                        (SELECT Id, skedHC__Status__c, sked_Exception_Code__c
                                                         FROM sked_Exception_Log__r
                                                         WHERE skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN)
                                                        FROM sked_Drive_Shift_Tag__c
                                                        WHERE sked_Drive_Shift__c IN :driveShiftIds
                                                        AND sked_Minimum_Quantity__c != NULL 
                                                        AND sked_Minimum_Quantity__c > 0];
        if (!driveShiftTags.isEmpty()) {
            List<sked__Job_Allocation__c> allJobAllocations = [SELECT Id, sked__Job__r.sked_Drive_Shift__c, sked__Resource__c,
                                                               sked__Start__c, sked__Set_End__c, sked__Job__r.sked_Drive__r.sked_Drive_Date__c
                                                               FROM sked__Job_Allocation__c
                                                               WHERE sked__Job__r.sked_Drive_Shift__c IN :driveShiftIds
                                                               AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                               AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED];
            
            Map<Id, List<sked__Job_Allocation__c>> map_driveShiftId_jobAllocations = new Map<Id, List<sked__Job_Allocation__c>>();
            Set<Id> resourceIds = new Set<Id>();
            for (sked__Job_Allocation__c jobAllocation : allJobAllocations) {
                resourceIds.add(jobAllocation.sked__Resource__c);
                List<sked__Job_Allocation__c> driveShiftAllocations = map_driveShiftId_jobAllocations.get(jobAllocation.sked__Job__r.sked_Drive_Shift__c);

                if (driveShiftAllocations == null) {
                    driveShiftAllocations = new List<sked__Job_Allocation__c>();
                }

                driveShiftAllocations.add(jobAllocation);
                map_driveShiftId_jobAllocations.put(jobAllocation.sked__Job__r.sked_Drive_Shift__c, driveShiftAllocations);
            }
            
            Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id,
                                                                                     (SELECT Id, sked__Tag__c, sked_Start__c, sked_Role_Status__c
                                                                                      FROM sked__ResourceTags__r
                                                                                      WHERE (sked_Role_Status__c = NULL OR sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE))
                                                                                     FROM sked__Resource__c
                                                                                     WHERE Id IN :resourceIds]);

            string messageTemplate = 'Not enough {{resourceTagName}}';
            for (sked_Drive_Shift_Tag__c driveShiftTag : driveShiftTags) {
                decimal minimumQuantity = driveShiftTag.sked_Minimum_Quantity__c;
                decimal numberOfResourcesHaveTag = 0;
                
                List<sked__Job_Allocation__c> driveShiftAllocations = map_driveShiftId_jobAllocations.get(driveShiftTag.sked_Drive_Shift__c);
                for (sked__Job_Allocation__c driveShiftAllocation : driveShiftAllocations) {
                    sked__Resource__c resource = mapResource.get(driveShiftAllocation.sked__Resource__c);
                    for (sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {
                        if (resourceTag.sked__Tag__c == driveShiftTag.sked_Tag__c) {
                            boolean isValid = resourceTag.sked_Start__c <= driveShiftAllocation.sked__Start__c;
                            if (isValid) {
                                numberOfResourcesHaveTag++;
                                break;
                            }
                        }
                    }
                }
                skedHC__Exception__c existingException;
                if (!driveShiftTag.sked_Exception_Log__r.isEmpty()) {
                    for (skedHC__Exception__c skedException : driveShiftTag.sked_Exception_Log__r) {
                        if (skedException.sked_Exception_Code__c == skedConstants.EXCEPTION_CODE_MINIMUM_QUANTITY_NOT_MET) {
                            existingException = skedException;
                            break;
                        }
                    }
                }
                if (minimumQuantity > numberOfResourcesHaveTag) {
                    if (existingException == NULL) {
                        string message = messageTemplate.replace('{{resourceTagName}}', driveShiftTag.sked_Tag__r.Name);
                        skedHC__Exception__c skedException = new skedHC__Exception__c (
                            sked_Drive__c = driveShiftTag.sked_Drive_Shift__r.sked_Drive__c,
                            sked_Drive_Shift__c = driveShiftTag.sked_Drive_Shift__c,
                            sked_Drive_Shift_Tag__c = driveShiftTag.Id,
                            sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_MINIMUM_QUANTITY_NOT_MET,
                            skedHC__Exception__c = message,
                            skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                        );
                        exceptionLog.add(skedException);
                    }
                }
                else {
                    if (existingException != NULL) {
                        existingException.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                        exceptionLog.add(existingException);
                    }
                }
            }
        }
        return exceptionLog;
    }
    
    private List<skedHC__Exception__c> captureUnavailabilityExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
            
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
        unavailabilityList.addAll(getUnavailabilityExceptionModelForConflictedActivities(master.jobAllocations));
        unavailabilityList.addAll(getUnavailabilityExceptionModelForConflictedUnavailabilities(master.jobAllocations));
   
        for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
            skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
            unavailability.resourceId = skedAllocation.sked__Resource__c;
            unavailability.startTime = skedAllocation.sked__Start__c;
            unavailability.endTime = skedAllocation.sked__Set_End__c;
            unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
            unavailability.exceptionText = 'Conflict with ' +  skedAllocation.sked__Job__r.sked_Drive__r.name; //HRP-12840
            unavailability.relatedEventFieldApi = 'skedHC__Job_Allocation__c';
            unavailability.recordId = skedAllocation.Id;
            unavailability.jobId = skedAllocation.sked__Job__c;
            unavailability.jobAllocationId = skedAllocation.Id;
            unavailability.driveId = skedAllocation.sked__Job__r.sked_Drive__c;
            unavailability.driveName = skedAllocation.sked__Job__r.sked_Drive__r.Name;
            unavailabilityList.add(unavailability);
        }
        if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
            exceptionLog = service.captureExceptionLogs(unavailabilityList);
        }
        return exceptionLog;
    }

    private List<skedHC__Exception__c> captureInvalidCollectionOp(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLogs = new List<skedHC__Exception__c>();

        for (sked__Job_Allocation__c jobAllocation : master.jobAllocations) {
            sked__Job__c job = master.mapJob.get(jobAllocation.sked__Job__c);
            Id driveCo = job.sked_Drive__r.sked_Collection_Operation__c;
            sked__Resource__c resource = master.mapResource.get(jobAllocation.sked__Resource__c);

            if (!skedResourceUtils.getResourceBelongsToCollectionOp(resource, driveCo, job.sked_Drive__r.sked_Drive_Date__c)) {
                exceptionLogs.add(new skedHC__Exception__c(
                    sked_Drive__c = job.sked_Drive__c,
                    skedHC__Job__c = job.Id,
                    skedHC__Job_Allocation__c = jobAllocation.Id,
                    skedHC__Resource__c = resource.Id,
                    sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_NOT_AVAILABLE_FOR_CO,
                    skedHC__Exception__c = 'Resource is not available to work in Collection Operation',
                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                ));
            }
        }

        return exceptionLogs;
    }

    private List<skedHC__Exception__c> captureNonWorkingExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();

        DateTime minStart;
        DateTime maxEnd;
        Set<Date> inputDates = new Set<Date>();
        for (sked__Job__c skedJob : master.mapJob.values()) {
            if (minStart == NULL || minStart > skedJob.sked__Start__c) {
                minStart = skedJob.sked__Start__c;
            }
            if (maxEnd == NULL || maxEnd < skedJob.sked__Finish__c) {
                maxEnd = skedJob.sked__Finish__c;
            }
            inputDates.add(skedJob.sked_Start_Date__c);
            inputDates.add(skedJob.sked_Finish_Date__c);
        }
        if (minStart != NULL && maxEnd != NULL) {
            skedAutoMapper autoMapper = skedAutoMapper.instance;
            
            Map<Id, skedModels.resource> mapResource = new Map<Id, skedModels.resource>();
            for (sked__Resource__c skedResource : master.mapResource.values()) {
                skedModels.resource resource = (skedModels.resource)autoMapper.mapTo(skedResource, skedModels.resource.class);
                mapResource.put(resource.Id, resource);
            }

            DateTime startTime = skedDateTimeUtils.getStartOfDate(minStart, UserInfo.getTimeZone().getID());
            DateTime endTime = skedDateTimeUtils.getEndOfDate(maxEnd, UserInfo.getTimeZone().getID());

            skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
            resourceService.populateNonWorkingEvents(mapResource.values(), inputDates, startTime, endTime);

            for (sked__Job_Allocation__c skedJobAllocation : master.jobAllocations) {
                skedModels.resource resource = mapResource.get(skedJobAllocation.sked__Resource__c);
                string resourceTimezoneSidId = resource.timezoneSidId != NULL ? resource.timezoneSidId : UserInfo.getTimeZone().getID();
                
                boolean conflictNonWorkingTime = false;
                for (skedModels.event event : resource.availability) {
                    DateTime resourceEventStart = skedDateTimeUtils.newDateTimeInstance(event.startDate, 0, resourceTimezoneSidId);
                    if (resourceEventStart != NULL && event.startTimeInMinutes != NULL) {
                        resourceEventStart = resourceEventStart.addMinutes(event.startTimeInMinutes);
                    }
                    
                    DateTime resourceEventFinish = skedDateTimeUtils.newDateTimeInstance(event.endDate, 0, resourceTimezoneSidId);
                    if (resourceEventFinish != NULL && event.endTimeInMinutes != NULL) {
                        resourceEventFinish = resourceEventFinish.addMinutes(event.endTimeInMinutes);
                    }

                    if (resourceEventStart != NULL && resourceEventFinish != NULL) {
                        if (resourceEventStart < skedJobAllocation.sked__Set_End__c && resourceEventFinish > skedJobAllocation.sked__Start__c) {
                            conflictNonWorkingTime = TRUE;
                            break;
                        }
                    }
                }
                if (conflictNonWorkingTime) {
                    sked__Job__c skedJob = master.mapJob.get(skedJobAllocation.sked__Job__c);
                    skedHC__Exception__c skedException = new skedHC__Exception__c (
                        sked_Drive__c = skedJob.sked_Drive__c,
                        skedHC__Job__c = skedJob.Id,
                        skedHC__Job_Allocation__c = skedJobAllocation.Id,
                        skedHC__Resource__c = resource.Id,
                        sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT,
                        skedHC__Exception__c = 'Non-working time',
                        skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                    );
                    exceptionLog.add(skedException);
                }
            }
        }
        return exceptionLog;
    }

    private List<skedHC__Exception__c> captureRoleRestrictedExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();

        for (sked__Job_Allocation__c skedJobAllocation : master.jobAllocations) {
            List<String> performedRoles = new List<String>();
            performedRoles.add(skedJobAllocation.sked_Resource_Role__c);
            if (String.isNotBlank(skedJobAllocation.sked_Additional_Roles__c)) {
                performedRoles.addAll(skedJobAllocation.sked_Additional_Roles__c.split(';'));
            }
            Date driveDate = skedJobAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c;
            sked__Resource__c resource = master.mapResource.get(skedJobAllocation.sked__Resource__c);
            if (resource.sked__ResourceTags__r != null && !resource.sked__ResourceTags__r.isEmpty()) {
                for (sked__Resource_Tag__c rt : resource.sked__ResourceTags__r) {
                    if (performedRoles.contains(rt.sked__Tag__r.Name)) {
                        if (rt.sked_Restriction_Start_Date__c != null && rt.sked_Restriction_Start_Date__c <= driveDate &&
                            (rt.sked_Restriction_End_Date__c == null || rt.sked_Restriction_End_Date__c >= driveDate)) {
                                exceptionLog.add(new skedHC__Exception__c(
                                    sked_Drive__c = skedJobAllocation.sked__Job__r.sked_Drive__c,
                                    skedHC__Job__c = skedJobAllocation.sked__Job__c,
                                    skedHC__Job_Allocation__c = skedJobAllocation.Id,
                                    skedHC__Resource__c = resource.Id,
                                    sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_ROLE_RESTRICTED,
                                    skedHC__Exception__c = 'Resource Role Restricted: ' + rt.sked__Tag__r.Name,
                                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                                ));
                        }
                    }
                }
            }
        }
        return exceptionLog;
    }

    public static List<skedHC__Exception__c> captureLinkedDriveMismatchedAssetExceptionLog(skedExceptionMasterModel master) {
        Set<Id> linkedDriveIds = new Set<Id>();
        for (sked__Job_Allocation__c ja : master.jobAllocations) {
            sked__Job__c skedJob = master.mapJob.get(ja.sked__Job__c);
            Boolean belongsToLinkedDrive = skedJob.sked_Drive__r.sked_Linked_Drives__c != null;
            if (belongsToLinkedDrive && skedJob.sked_Asset_Type__c != null) {
                linkedDriveIds.add(skedJob.sked_Drive__r.sked_Linked_Drives__c);
            }
        }

        List<sked_Linked_Drives__c> linkedDrives = new List<sked_Linked_Drives__c>([
            SELECT Id, Name,
            (SELECT Id, sked_Drive_Date__c, Name
             FROM sked_Drives__r),
            (SELECT Id, skedHC__Exception__c
             FROM sked_Exception_Logs__r
             WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_LINKED_DRIVE_MISMATCHING_ASSETS)
            FROM sked_Linked_Drives__c
            WHERE Id IN :linkedDriveIds
        ]);

        Set<Id> affectedDriveIds = new Set<Id>();
        for (sked_Linked_Drives__c linkedDrive : linkedDrives) {
            Set<Id> driveIds = new Set<Id>();
            for (sked_Drive__c ldDrive : linkedDrive.sked_Drives__r) {
                driveIds.add(ldDrive.Id);
            }
            affectedDriveIds.addAll(driveIds);
        }

        List<String> deletedStatuses = new List<String>{
            skedConstants.JOB_ALLOCATION_STATUS_DECLINED,
            skedConstants.JOB_ALLOCATION_STATUS_DELETED
        };
        Map<Id, sked__Job_Allocation__c> jobAllocationById = new Map<Id, sked__Job_Allocation__c>([
            SELECT Id, sked__Status__c, sked__Resource__c, sked__Job__r.Name, sked__Job__r.sked_Drive__c, 
                sked__Job__r.sked_Drive__r.Name, sked__Job__r.sked_Drive__r.sked_Linked_Drives__c
            FROM sked__Job_Allocation__c
            WHERE sked__Job__r.sked_Drive__c IN :affectedDriveIds
            AND sked__Job__r.sked_Asset_Type__c != null
            AND sked__Status__c NOT IN :deletedStatuses
        ]);

        Map<Id, List<sked__Job_Allocation__c>> jasByDriveId = new Map<Id, List<sked__Job_Allocation__c>>();
        for (Id jaId : jobAllocationById.keySet()) {
            sked__Job_Allocation__c ja = jobAllocationById.get(jaId);
            List<sked__Job_Allocation__c> jaForDrives = jasByDriveId.get(ja.sked__Job__r.sked_Drive__c);
            if (jaForDrives == null) {
                jaForDrives = new List<sked__Job_Allocation__c>();
            }

            jaForDrives.add(ja);
            jasByDriveId.put(ja.sked__Job__r.sked_Drive__c, jaForDrives);
        }

        Map<Id, String> assetSetByDriveId = new Map<Id, String>();
        for (Id driveId : jasByDriveId.keySet()) {
            Set<String> assetSet = new Set<String>();
            for (sked__Job_Allocation__c ja : jasByDriveId.get(driveId)) {
                assetSet.add(ja.sked__Resource__c);
            }
            if (!assetSet.isEmpty()) {
                List<String> assetList = new List<String>(assetSet);
                assetList.sort();
                assetSetByDriveId.put(driveId, String.join(assetList, ','));
            }
        }

        List<skedHC__Exception__c> exceptionLogs = new List<skedHC__Exception__c>();
        for (sked_Linked_Drives__c linkedDrive : linkedDrives) {
            Set<String> assetSetsForDrives = new Set<String>();
            for (sked_Drive__c drive : linkedDrive.sked_Drives__r) {
                if (assetSetByDriveId.containsKey(drive.Id)) {
                    assetSetsForDrives.add(assetSetByDriveId.get(drive.Id));
                }
            }

            Boolean hasMatchingAllocationForAllDrives = assetSetsForDrives.size() <= 1;
            Boolean hasExistingExceptions = linkedDrive.sked_Exception_Logs__r != null && !linkedDrive.sked_Exception_Logs__r.isEmpty();
            if (hasExistingExceptions) {
                String exceptionStatus = hasMatchingAllocationForAllDrives ? 
                    skedConstants.EXCEPTION_LOG_STATUS_CLOSED : skedConstants.EXCEPTION_LOG_STATUS_OPEN; 
                for (skedHC__Exception__c skedException : linkedDrive.sked_Exception_Logs__r) {
                    skedException.skedHC__Status__c = exceptionStatus;
                    exceptionLogs.add(skedException);
                }
            } else if (!hasMatchingAllocationForAllDrives) {
                exceptionLogs.add(new skedHC__Exception__c(
                    sked_Linked_Drive__c = linkedDrive.Id,
                    sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_LINKED_DRIVE_MISMATCHING_ASSETS,
                    skedHC__Exception__c = 'Linked Drive has mismatching Asset allocations across drives',
                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                ));
            }
        }

        return exceptionLogs;
    }

    /**************************************** Private Get Methods *************************************/
    private skedExceptionLogService.resourceUnavailabilityModel getResourceUnavailabilityModel(
        String resourceId,
        String relatedEventFieldApi,
        String recordId,
        String exceptionText,
        DateTime startTime,
        DateTime endTime
    ) {
        skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
        unavailability.resourceId = resourceId;
        unavailability.startTime = startTime;
        unavailability.endTime = endTime;
        unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
        unavailability.exceptionText = exceptionText;
        unavailability.relatedEventFieldApi = relatedEventFieldApi;
        unavailability.recordId = recordId;
        return unavailability;
    }

    private List<sked__Activity_Resource__c> getConflictedActivities(List<sked__Job_Allocation__c> jobAllocations) {
        Set<Id> resourceIds = new Set<Id>();
        DateTime minDt, maxDt;
        Boolean hasTermination = false;

        for (sked__Job_Allocation__c skedAllocation : jobAllocations) {
            resourceIds.add(skedAllocation.sked__Resource__c);
            if (minDt == NULL || skedAllocation.sked__Start__c < minDt) {
                minDt = skedAllocation.sked__Start__c;
            }
            if (skedAllocation.sked__Set_End__c != NULL) {
                if (maxDt == NULL || skedAllocation.sked__Set_End__c > maxDt) {
                    maxDt = skedAllocation.sked__Set_End__c;
                }
            }
            else {
                hasTermination = true;
            }
        }
        if (hasTermination) {
            maxDt = NULL;
        }

        skedQueryBuilder activityResourceBuilder = new skedQueryBuilder();
        activityResourceBuilder.setFromClause('sked__Activity_Resource__c');
        activityResourceBuilder.addField('Id');
        activityResourceBuilder.addField('Name');
        activityResourceBuilder.addField('sked__Activity__c');
        activityResourceBuilder.addField('sked__Resource__c');
        activityResourceBuilder.addField('sked_Start1__c');
        activityResourceBuilder.addField('sked_End__c');
        activityResourceBuilder.addField('sked__Activity__r.sked_Activity_Title__c');
        
        activityResourceBuilder.addCondition('sked__Resource__c IN {0}', resourceIds);
        if (minDt != NULL && maxDt != NULL) {
            activityResourceBuilder.addCondition('sked_Start1__c < {0}', maxDt);
            activityResourceBuilder.addCondition('sked_End__c > {0}', minDt);
        }
        else if (minDt != NULL) {
            activityResourceBuilder.addCondition('sked_Start1__c >= {0}', minDt);			
        }

        string queryString = activityResourceBuilder.toString();
        return (List<sked__Activity_Resource__c>)Database.query(queryString);
    }

    private List<sked__Availability__c> getConflictedUnavailabilities(List<sked__Job_Allocation__c> jobAllocations) {
        Set<Id> resourceIds = new Set<Id>();
        DateTime minDt, maxDt;
        Boolean hasTermination = false;

        List<string> activeStatuses = new List<string> {
            skedConstants.AVAILABILITY_STATUS_APPROVED,
            skedConstants.AVAILABILITY_STATUS_PENDING,
            skedConstants.AVAILABILITY_STATUS_WAITLIST
        };

        List<String> excludedCalloutTypes = new List<String> {
            skedConstants.AVAILABILITY_CALLOUT_TYPE_EARLY_DEPARTURE,
            skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL
        };

        for (sked__Job_Allocation__c skedAllocation : jobAllocations) {
            resourceIds.add(skedAllocation.sked__Resource__c);
            if (minDt == NULL || skedAllocation.sked__Start__c < minDt) {
                minDt = skedAllocation.sked__Start__c;
            }
            if (skedAllocation.sked__Set_End__c != NULL) {
                if (maxDt == NULL || skedAllocation.sked__Set_End__c > maxDt) {
                    maxDt = skedAllocation.sked__Set_End__c;
                }
            }
            else {
                hasTermination = true;
            }
        }
        if (hasTermination) {
            maxDt = NULL;
        }

        skedQueryBuilder availabilityBuilder = new skedQueryBuilder();
        availabilityBuilder.setFromClause('sked__Availability__c');
        availabilityBuilder.addField('Id');
        availabilityBuilder.addField('Name');
        availabilityBuilder.addField('sked__Is_Available__c');
        availabilityBuilder.addField('sked__Type__c');
        availabilityBuilder.addField('sked__Resource__c');
        availabilityBuilder.addField('sked__Start__c');
        availabilityBuilder.addField('sked__Finish__c');
        availabilityBuilder.addField('sked__Status__c');
        availabilityBuilder.addField('sked_Call_Out_Type__c');
        
        availabilityBuilder.addCondition('sked__Resource__c IN {0}', resourceIds);
        availabilityBuilder.addCondition('sked__Status__c IN {0}', activeStatuses);
        availabilityBuilder.addCondition('sked_Call_Out_Type__c NOT IN {0}', excludedCalloutTypes);
        availabilityBuilder.addCondition('sked__Is_Available__c = {0}', false);

        if (minDt != NULL && maxDt != NULL) {
            availabilityBuilder.addCondition('sked__Start__c < {0}', maxDt);
            availabilityBuilder.addCondition('sked__Finish__c > {0}', minDt);
        }
        else if (minDt != NULL) {
            availabilityBuilder.addCondition('sked__Start__c >= {0}', minDt);			
        }

        string queryString = availabilityBuilder.toString();
        return (List<sked__Availability__c>)Database.query(queryString);
    }

    private List<skedExceptionLogService.resourceUnavailabilityModel> getUnavailabilityExceptionModelForConflictedActivities(
        List<sked__Job_Allocation__c> jobAllocations
    ) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();

        List<sked__Activity_Resource__c> conflictedActivities = getConflictedActivities(jobAllocations);
        if(conflictedActivities != NULL && !conflictedActivities.isEmpty()) {
            for(sked__Activity_Resource__c conflictActivity : conflictedActivities) {
                unavailabilityList.add(getResourceUnavailabilityModel(
                    conflictActivity.sked__Resource__c,
                    'skedHC__Activity__c',
                    conflictActivity.sked__Activity__c,
                    'Conflict with ' + conflictActivity.sked__Activity__r.sked_Activity_Title__c,
                    conflictActivity.sked_Start1__c,
                    conflictActivity.sked_End__c
                ));
            }
        }
        return unavailabilityList;
    }

    private List<skedExceptionLogService.resourceUnavailabilityModel> getUnavailabilityExceptionModelForConflictedUnavailabilities(
        List<sked__Job_Allocation__c> jobAllocations
    ) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();

        List<sked__Availability__c> conflictedUnavailabilities = getConflictedUnavailabilities(jobAllocations);
        if(conflictedUnavailabilities != NULL && !conflictedUnavailabilities.isEmpty()) {
            for(sked__Availability__c conflictedUnavailability : conflictedUnavailabilities) {
                unavailabilityList.add(getResourceUnavailabilityModel(
                    conflictedUnavailability.sked__Resource__c,
                    'skedHC__Availability__c',
                    conflictedUnavailability.Id,
                    conflictedUnavailability.sked__Type__c,
                    conflictedUnavailability.sked__Start__c,
                    conflictedUnavailability.sked__Finish__c
                ));
            }
        }
        return unavailabilityList;
    }

    /**************************************** NESTED CLASS ********************************************/
    global class batchSetting {
        public boolean geographicException;
    }

    public class jobAllocationModel {
        public Boolean hasKey;
        public string key;
        public string resourceId;
        public Date startDate;
        public Date endDate;
        public List<sked__Job_Allocation__c> jobAllocations;
        public List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails;
        public sked_Resource_Hours_Record__c resourceHoursRecord;

        public jobAllocationModel() {
            jobAllocations = new List<sked__Job_Allocation__c>();
            resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        }
    }

}