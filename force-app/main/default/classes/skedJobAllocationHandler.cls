public class skedJobAllocationHandler extends skedTriggerHub implements Callable {
    private static final List<String> PERMITTED_INSERT_EDIT_PROFILES = new List<String>{
        'Global Admin', 'System Administrator', 'Integration User', 'APS Admin', 'Collections', 'Collection Management'
    };

    private static final List<String> PERMITTED_DELETE_PROFILES = new List<String>{
        'Global Admin', 'System Administrator', 'Integration User', 'APS Admin'
    };
    
    public static boolean isRunningPostProcess = FALSE;
    
    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.oldRecords, skedConstants.RECORD_CHANGES_INVALID_FROM_LIST_VIEW, PERMITTED_DELETE_PROFILES);
        if (!skedSetting.instance.Admin.migrationMode) {
            onDeleteJobAllocation((Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            removeResourceForLinkedActivities((Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            deleteResourceHoursRecordDetails(this.context.oldMap.values());
        }
    }
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.RECORD_CHANGES_INVALID_FROM_LIST_VIEW, PERMITTED_INSERT_EDIT_PROFILES);
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
        populatePremiumPay(this.context.newRecords);
    }

    public override void onAfterInsert() {
        processPostInsert(this.context.newRecords);
        updateDriveVehicleTypes(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.RECORD_CHANGES_INVALID_FROM_LIST_VIEW, PERMITTED_INSERT_EDIT_PROFILES);
        populateData(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
        }
    }

    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            onStatusChanged(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            captureNonGroupException(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            updateDriveVehicleTypes(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            removeResourceForLinkedActivities(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            syncToResourceHoursRecord(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            syncToOperationRecordStaffRecords(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            sendNotifications(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
        }
    }

    /**************************************** CALLABLE INTERFACE  ***************************************/
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'performResourceHoursRecordDetailsSync' {
                    performResourceHoursRecordDetailsSync((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));
                }
                when 'manageResourceHoursRecordDetails' {
                    manageResourceHoursRecordDetails(
                        (Map<String, jobAllocationModel>) JSON.deserialize((String) params.get('param1'), Map<String, jobAllocationModel>.class),
                        (Set<Id>) JSON.deserialize((String) params.get('param2'), Set<Id>.class)
                    );
                }
                when 'performActivityResourceSync' {
                    performActivityResourceSync((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));
                }
                when 'performOperationRecordStaffSync' {
                    performOperationRecordStaffSync((Map<Id, sked__Job_Allocation__c>) JSON.deserialize((String) params.get('param1'), Map<Id, sked__Job_Allocation__c>.class));
                }
                when 'maintainExceptionLog' {
                    maintainExceptionLog(
                        (List<sked__Job_Allocation__c>) JSON.deserialize((String) params.get('param1'), List<sked__Job_Allocation__c>.class),
                        (Boolean) JSON.deserialize((String) params.get('param2'), Boolean.class),
                        (Boolean) JSON.deserialize((String) params.get('param3'), Boolean.class),
                        (String) params.get('param4')
                    );
                }
                when 'performDriveVehicleTypeSync' {
                    performDriveVehicleTypeSync((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedJobAllocationHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }

    /**************************************** PRIVATE METHOD ********************************************/
    private void processPostInsert(List<sked__Job_Allocation__c> newRecords) {
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            jobAllocationIds.add(newRecord.Id);
        }
        if (!Test.isRunningTest() && !System.isBatch() && !skedSetting.instance.Admin.migrationMode) {
            Database.executeBatch(new skedJobAllocationTravelTimeBatch(jobAllocationIds), 40);
        }
    }

    private void doDateTimeConversion(List<sked__Job_Allocation__c> newRecords) {
        for (sked__Job_Allocation__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Set_End__c', 'sked_Set_End_Date__c', 'sked_Set_End_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Time_Checked_In__c', 'sked_Time_Checked_In_Date__c', 'sked_Time_Checked_In_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Time_Completed__c', 'sked_Time_Completed_Date__c', 'sked_Time_Completed_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Time_In_Progress__c', 'sked_Time_In_Progress_Date__c', 'sked_Time_In_Progress_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Time_Published__c', 'sked_Time_Published_Date__c', 'sked_Time_Published_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Time_Responded__c', 'sked_Time_Responded_Date__c', 'sked_Time_Responded_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Time_Start_Travel__c', 'sked_Time_Start_Travel_Date__c', 'sked_Time_Start_Travel_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_DateTime_of_Call_Out__c', 'sked_Date_of_Call_Out__c', 'sked_Time_of_Call_Out__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_DateTime_Call_Out_Received__c', 'sked_Date_Call_Out_Received__c', 'sked_Time_Call_Out_Received__c', 'sked_Job_Timezone__c');
        }
    }

    private void doDateTimeConversion(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Set_End__c', 'sked_Set_End_Date__c', 'sked_Set_End_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Time_Checked_In__c', 'sked_Time_Checked_In_Date__c', 'sked_Time_Checked_In_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Time_Completed__c', 'sked_Time_Completed_Date__c', 'sked_Time_Completed_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Time_In_Progress__c', 'sked_Time_In_Progress_Date__c', 'sked_Time_In_Progress_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Time_Published__c', 'sked_Time_Published_Date__c', 'sked_Time_Published_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Time_Responded__c', 'sked_Time_Responded_Date__c', 'sked_Time_Responded_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Time_Start_Travel__c', 'sked_Time_Start_Travel_Date__c', 'sked_Time_Start_Travel_Time__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_DateTime_of_Call_Out__c', 'sked_Date_of_Call_Out__c', 'sked_Time_of_Call_Out__c', 'sked_Job_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_DateTime_Call_Out_Received__c', 'sked_Date_Call_Out_Received__c', 'sked_Time_Call_Out_Received__c', 'sked_Job_Timezone__c');
        }
    }

    private void removeResourceForLinkedActivities(Map<Id, sked__Job_Allocation__c> oldMap) {
        Set<Id> jobAlloctionIds = new Set<Id>();

        for (sked__Job_Allocation__c oldData : oldMap.values()) {
            jobAlloctionIds.add(oldData.Id);
        }

        if (!jobAlloctionIds.isEmpty()) {
            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    skedJobAllocationHandler.class.getName(),
                    'performActivityResourceSync',
                    jobAlloctionIds
                );
            } else {
                performActivityResourceSync(jobAlloctionIds);
            }
        }
    }

    private void removeResourceForLinkedActivities(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        List<string> statuses = new List<string> {skedConstants.JOB_ALLOCATION_STATUS_DELETED, skedConstants.JOB_ALLOCATION_STATUS_DECLINED};
        Set<Id> jobAlloctionIds = new Set<Id>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldData = oldMap.get(newRecord.Id);

            if (statuses.contains(newRecord.sked__Status__c) && newRecord.sked__Status__c != oldData.sked__Status__c) {
                jobAlloctionIds.add(newRecord.Id);
            }
        }

        if (!jobAlloctionIds.isEmpty()) {
            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    skedJobAllocationHandler.class.getName(),
                    'performActivityResourceSync',
                    jobAlloctionIds
                );
            } else {
                performActivityResourceSync(jobAlloctionIds);
            }
        }
    }

    private static void performActivityResourceSync(Set<Id> jobAllocationIds) {
        syncResourceForLinkedActivity(jobAllocationIds, FALSE, TRUE);
    }

    private static void syncResourceForLinkedActivity(Set<Id> jobAlloctionIds, Boolean isAdd, Boolean isRemove) {
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
                    if (!activityResourceIdsForDrive.contains(jobAllocationResourceId) && isAdd) {
                        sked__Activity_Resource__c newActivityResource = new sked__Activity_Resource__c(
                            sked__Resource__c = jobAllocationResourceId,
                            sked__Activity__c = activityId
                        );
                        newActivityResources.add(newActivityResource);
                    }
                    if (activityResourceIdsForDrive.contains(jobAllocationResourceId) && isRemove) {
                        sked__Activity_Resource__c deleteActivityResource = mapActivityIdResourceId_ActivityResourceId.get(activityId + ':' + jobAllocationResourceId);
                        deleteActivityResources.add(deleteActivityResource);
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
                            sked__Activity__c = activityId
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
                if (jobAllocationResourceIds != null && !jobAllocationResourceIds.isEmpty()) {
                    for (string jobAllocationResourceId : jobAllocationResourceIds) {
                        if (!activityResourceIdsForLinkedDrive.contains(jobAllocationResourceId) && isAdd) {
                            sked__Activity_Resource__c newActivityResource = new sked__Activity_Resource__c(
                                sked__Resource__c = jobAllocationResourceId,
                                sked__Activity__c = activityId
                            );
                            newActivityResources.add(newActivityResource);
                        }
                        if (activityResourceIdsForLinkedDrive.contains(jobAllocationResourceId) && isRemove) {
                            sked__Activity_Resource__c deleteActivityResource = mapActivityIdResourceId_ActivityResourceId.get(activityId + ':' + jobAllocationResourceId);
                            deleteActivityResources.add(deleteActivityResource);
                        }
                    }
                }
            }
        } else if (skedActivitiesById != null && !skedActivitiesById.isEmpty()) {
            for (Id activityId : skedActivitiesById.keySet()) {
                sked__Activity__c activity = skedActivitiesById.get(activityId);
                if (activity.sked_Linked_Drives__c != null) {
                    Set<String> jobAllocationResourceIds = mapLinkedDrive_JobAllocationResourceIds.get(activity.sked_Linked_Drives__c);
                    for (String jobAllocationResourceId : jobAllocationResourceIds) {
                        newActivityResources.add(new sked__Activity_Resource__c(
                            sked__Resource__c = jobAllocationResourceId,
                            sked__Activity__c = activityId
                        ));
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
    
    private void onDeleteJobAllocation(Map<Id, sked__Job_Allocation__c> oldMap) {
        delete [SELECT Id FROM skedHC__Exception__c WHERE skedHC__Job_Allocation__c IN :oldMap.keySet()];
        delete [SELECT Id FROM sked_Operation_Record_Staff__c WHERE sked_Job_Allocation__c IN :oldMap.keySet()];
        
        boolean processDriveShiftException = TRUE;
        boolean processLinkedDriveException = TRUE;
        string processOtherException = '';

        if (!System.isBatch()) {
            skedFutureCallEventHandler.publishFutureCallEvent(
                skedJobAllocationHandler.class.getName(),
                'maintainExceptionLog',
                oldMap.values(),
                processDriveShiftException,
                processLinkedDriveException,
                processOtherException
            );
        } else {
            maintainExceptionLog(oldMap.values(), processDriveShiftException, processLinkedDriveException, processOtherException);
        }
    }
    
    private void onStatusChanged(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        Map<Id, sked__Job_Allocation__c> mapDeletedRecord = new Map<Id, sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c allocation : newRecords) {
            sked__Job_Allocation__c oldData = oldMap.get(allocation.Id);
            if (allocation.sked__Status__c != oldData.sked__Status__c) {
                if (allocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                    mapDeletedRecord.put(allocation.Id, allocation);
                }
            }
        }
        if (!mapDeletedRecord.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
            service.removeExceptionLogs(mapDeletedRecord.keySet());
            
            boolean processDriveShiftException = TRUE;
            boolean processLinkedDriveException = TRUE;
            string processOtherException = '';

            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    skedJobAllocationHandler.class.getName(),
                    'maintainExceptionLog',
                    mapDeletedRecord.values(),
                    processDriveShiftException,
                    processLinkedDriveException,
                    processOtherException
                );
            } else {
                maintainExceptionLog(mapDeletedRecord.values(), processDriveShiftException, processLinkedDriveException, processOtherException);
            }
        }
    }
    
    private void captureNonGroupException(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        Map<string, List<sked__Job_Allocation__c>> mapRecordsToProcess = new Map<string, List<sked__Job_Allocation__c>>();
        for (sked__Job_Allocation__c allocation : newRecords) {
            if (allocation.sked__Status__c != skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                sked__Job_Allocation__c oldData = oldMap.get(allocation.Id);
                
                List<string> otherExceptionCodes = new List<string>();
                if (allocation.sked_Geoservice_Travel_Time_To__c != oldData.sked_Geoservice_Travel_Time_To__c || allocation.sked_Geoservice_Travel_Time_Back__c != oldData.sked_Geoservice_Travel_Time_Back__c) {
                	string otherExceptionCode = 'travelTimeException';    
                    otherExceptionCodes.add(otherExceptionCode);
                }
                if (allocation.sked_Additional_Roles__c != oldData.sked_Additional_Roles__c) {
                    string otherExceptionCode = 'additionalRolesException';
                    otherExceptionCodes.add(otherExceptionCode);
                }
                if (allocation.sked_DOT__c != oldData.sked_DOT__c || allocation.sked_CDL__c != oldData.sked_CDL__c) {
                    otherExceptionCodes.add('requiredTagException');
                }
                for (string otherExceptionCode : otherExceptionCodes) {
                    List<sked__Job_Allocation__c> recordsToProcess = mapRecordsToProcess.get(otherExceptionCode);
                    if (recordsToProcess == NULL) {
                        recordsToProcess = new List<sked__Job_Allocation__c>();
                        mapRecordsToProcess.put(otherExceptionCode, recordsToProcess);
                    }
                    recordsToProcess.add(allocation);
                }
            }
        }
        
        if (!mapRecordsToProcess.isEmpty()) {
            for (string otherExceptionCode : mapRecordsToProcess.keySet()) {
                List<sked__Job_Allocation__c> recordsToProcess = mapRecordsToProcess.get(otherExceptionCode);
                boolean processDriveShiftException = FALSE;
                boolean processLinkedDriveException = FALSE;
                
                if (!System.isBatch()) {
                    skedFutureCallEventHandler.publishFutureCallEvent(
                        skedJobAllocationHandler.class.getName(),
                        'maintainExceptionLog',
                        recordsToProcess,
                        processDriveShiftException,
                        processLinkedDriveException,
                        otherExceptionCode
                    );
                } else {
                    maintainExceptionLog(recordsToProcess, processDriveShiftException, processLinkedDriveException, otherExceptionCode);
                }
            }
        }
    }

    private void populateData(List<sked__Job_Allocation__c> newRecords) {
        DateTime currentTime = system.now();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            newRecord.sked_Roles_Assignment_Str__c = newRecord.sked_Resource_Role__c;
            
            if (!string.isBlank(newRecord.sked_Dual_Role__c)) {
                List<string> addtionalRoles = new List<string>();
                if (newRecord.sked_Additional_Roles__c != NULL) {
                    addtionalRoles = newRecord.sked_Additional_Roles__c.split(';');
                }
                if (!addtionalRoles.contains(newRecord.sked_Dual_Role__c)) {
                	addtionalRoles.add(newRecord.sked_Dual_Role__c);
                }
                newRecord.sked_Additional_Roles__c = string.join(addtionalRoles, ';');
            }
            
            if (!string.isBlank(newRecord.sked_Roles_Assignment_Str__c) && newRecord.sked_Additional_Roles__c != NULL) {
                newRecord.sked_Roles_Assignment_Str__c = newRecord.sked_Roles_Assignment_Str__c + ', ' + newRecord.sked_Additional_Roles__c.replace(';', ', ');
            }
            
            if (newRecord.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED) {
                newRecord.sked__Time_Published__c = currentTime;
                newRecord.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED;
                newRecord.sked_Locked__c = TRUE;
            }
        }
    }
    
    private void populateData(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        DateTime currentTime = system.now();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Additional_Roles__c != oldData.sked_Additional_Roles__c) {
                newRecord.sked_Roles_Assignment_Str__c = newRecord.sked_Resource_Role__c;
                if (!string.isBlank(newRecord.sked_Roles_Assignment_Str__c) && newRecord.sked_Additional_Roles__c != NULL) {
                    newRecord.sked_Roles_Assignment_Str__c = newRecord.sked_Roles_Assignment_Str__c + ', ' + newRecord.sked_Additional_Roles__c.replace(';', ', ');
                }
            }
            if (newRecord.sked__Status__c != oldData.sked__Status__c && newRecord.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED) {
                newRecord.sked__Time_Published__c = currentTime;
                newRecord.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED;
                newRecord.sked_Locked__c = TRUE;
            }

            if (newRecord.sked_Call_Out_Type__c != oldData.sked_Call_Out_Type__c && newRecord.sked_Call_Out_Type__c != null) {
                newRecord.sked_DateTime_of_Call_Out__c = newRecord.sked_DateTime_of_Call_Out__c == null 
                    ? currentTime : newRecord.sked_DateTime_of_Call_Out__c;
                newRecord.sked_DateTime_Call_Out_Received__c = newRecord.sked_DateTime_Call_Out_Received__c == null 
                    ? newRecord.sked_DateTime_of_Call_Out__c : newRecord.sked_DateTime_Call_Out_Received__c;
                if (newRecord.sked_DateTime_Call_Out_Received__c != null && newRecord.sked__Start__c != null) {
                    newRecord.sked_Call_Out_Notice__c = skedDateTimeUtils.getDifferentMinutesText(newRecord.sked_DateTime_Call_Out_Received__c, newRecord.sked__Start__c);	
                }
            }
        }
    }
    
    private void populatePremiumPay(List<sked__Job_Allocation__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked_Resource_Role__c)) {
            	resourceIds.add(newRecord.sked__Resource__c);
            }
        }
        if (!resourceIds.isEmpty()) {
            Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked_Premium_Pay_Roles__c
                                                                                     FROM sked__Resource__c
                                                                                     WHERE Id IN :resourceIds]);
            for (sked__Job_Allocation__c newRecord : newRecords) {
                if (!string.isBlank(newRecord.sked_Resource_Role__c)) {
                    sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
                    if (skedResource.sked_Premium_Pay_Roles__c != NULL && skedResource.sked_Premium_Pay_Roles__c.contains(newRecord.sked_Resource_Role__c)) {
                        newRecord.sked_Premium_Pay__c = TRUE;
                    }
                }
            }
        }
    }
    
    private void updateDriveVehicleTypes(List<sked__Job_Allocation__c> newRecords) {
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            jobAllocationIds.add(newRecord.Id);
        }
        if (!System.isBatch() && !jobAllocationIds.isEmpty()) {
            skedFutureCallEventHandler.publishFutureCallEvent(
                skedJobAllocationHandler.class.getName(),
                'performDriveVehicleTypeSync',
                jobAllocationIds
            );
        } else {
            performDriveVehicleTypeSync(jobAllocationIds);
        } 
    }
    
    private void updateDriveVehicleTypes(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Status__c != oldData.sked__Status__c) {
                if (newRecord.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                    jobAllocationIds.add(newRecord.Id);
                }
            }
        }
        if (!System.isBatch() && !jobAllocationIds.isEmpty()) {
            skedFutureCallEventHandler.publishFutureCallEvent(
                skedJobAllocationHandler.class.getName(),
                'performDriveVehicleTypeSync',
                jobAllocationIds
            );
        } else {
            performDriveVehicleTypeSync(jobAllocationIds);
        } 
    }
    
    public static void performDriveVehicleTypeSync(Set<Id> jobAllocationIds) {
        List<sked__Job_Allocation__c> inputJobAllocations = [SELECT Id, sked__Job__r.sked_Drive__c
                                                             FROM sked__Job_Allocation__c
                                                             WHERE Id IN :jobAllocationIds
                                                             AND sked__Job__r.sked_Drive__c != NULL
                                                             AND sked__Job__r.sked_Asset_Type__c = 'Vehicle'];
        Set<Id> driveIds = new Set<Id>();
        for (sked__Job_Allocation__c inputJobAllocation : inputJobAllocations) {
            driveIds.add(inputJobAllocation.sked__Job__r.sked_Drive__c);
        }
        if (!driveIds.isEmpty()) {
            List<sked__Job_Allocation__c> skedJobAllocations = [SELECT Id, sked__Job__r.sked_Drive__c, sked__Resource__r.sked__Category__c,
                                                                sked__Resource__r.sked_Pres_Donor_Capacity__c,
                                                                sked__Resource__r.sked_CDL__c, sked__Resource__r.sked_DOT__c
                                                                FROM sked__Job_Allocation__c
                                                                WHERE sked__Job__r.sked_Drive__c IN :driveIds
                                                                AND sked__Job__r.sked_Asset_Type__c = 'Vehicle'
                                                                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
            Map<Id, List<sked__Job_Allocation__c>> map_driveId_vehicleAllocations = new Map<Id, List<sked__Job_Allocation__c>>();
            for (sked__Job_Allocation__c skedJobAllocation : skedJobAllocations) {
                List<sked__Job_Allocation__c> vehicleAllocations;
                if (map_driveId_vehicleAllocations.containsKey(skedJobAllocation.sked__Job__r.sked_Drive__c)) {
                    vehicleAllocations = map_driveId_vehicleAllocations.get(skedJobAllocation.sked__Job__r.sked_Drive__c);
                }
                else {
                    vehicleAllocations = new List<sked__Job_Allocation__c>();
                    map_driveId_vehicleAllocations.put(skedJobAllocation.sked__Job__r.sked_Drive__c, vehicleAllocations);
                }
                vehicleAllocations.add(skedJobAllocation);
            }
            
            if (!map_driveId_vehicleAllocations.isEmpty()) {
                List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
                for (string driveId : map_driveId_vehicleAllocations.keySet()) {
                    List<sked__Job_Allocation__c> vehicleAllocations = map_driveId_vehicleAllocations.get(driveId);
                    
                    Integer noOfAllocatedBuses = 0;
                    Integer noOfAllocatedCDL = 0;
                    Integer noOfAllocatedDOT = 0;
                    List<string> vehicleTypeList = new List<string>();
                    decimal vehicleCapacity = 0;
                    for (sked__Job_Allocation__c vehicleAllocation : vehicleAllocations) {
                        if (!vehicleTypeList.contains(vehicleAllocation.sked__Resource__r.sked__Category__c)) {
                        	vehicleTypeList.add(vehicleAllocation.sked__Resource__r.sked__Category__c);
                        }
                        if (vehicleAllocation.sked__Resource__r.sked__Category__c == skedConstants.RESOURCE_CATEGORY_BUS) {
                            noOfAllocatedBuses++;
                        }
                        if (vehicleAllocation.sked__Resource__r.sked_CDL__c == TRUE) {
                            noOfAllocatedCDL++;
                        }
                        if (vehicleAllocation.sked__Resource__r.sked_DOT__c == TRUE) {
                            noOfAllocatedDOT++;
                        }
                        if (vehicleAllocation.sked__Resource__r.sked_Pres_Donor_Capacity__c != NULL) {
                            vehicleCapacity += vehicleAllocation.sked__Resource__r.sked_Pres_Donor_Capacity__c;
                        }
                    }
                    
                    sked_Drive__c skedDrive = new sked_Drive__c(
                        Id = driveId,
                        sked_No_of_Allocated_Buses__c = noOfAllocatedBuses,
                        sked_No_of_Allocated_CDL__c = noOfAllocatedCDL,
                        sked_No_of_Allocated_DOT__c = noOfAllocatedDOT,
                        sked_Vehicle_Types__c = string.join(vehicleTypeList, ';'),
                        sked_Vehicle_Capacity__c = vehicleCapacity
                    );
                    drivesToUpdate.add(skedDrive);
                }
                update drivesToUpdate;
            }
        }
    }
    
    private void syncToOperationRecordStaffRecords(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        Map<Id, sked__Job_Allocation__c> map_jobAllocationId_jobAllocation = new Map<Id, sked__Job_Allocation__c>();
        
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldRecord = oldMap.get(newRecord.Id);
            if(newRecord.sked_Start_Date__c != oldRecord.sked_Start_Date__c || 
                newRecord.sked_Start_Time__c != oldRecord.sked_Start_Time__c ||
                newRecord.sked_Set_End_Date__c != oldRecord.sked_Set_End_Date__c ||
                newRecord.sked_Set_End_Time__c != oldRecord.sked_Set_End_Time__c
            ) {
                map_jobAllocationId_jobAllocation.put(newRecord.Id, newRecord);
            }
        }

        if (!map_jobAllocationId_jobAllocation.isEmpty()) {
            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    skedJobAllocationHandler.class.getName(),
                    'performOperationRecordStaffSync',
                    map_jobAllocationId_jobAllocation
                );
            } else {
                performOperationRecordStaffSync(map_jobAllocationId_jobAllocation);
            }
        }
    }

    public static void performOperationRecordStaffSync(Map<Id, sked__Job_Allocation__c> map_jobAllocationId_jobAllocation) {
        List<sked_Operation_Record_Staff__c> opRecordStaffListToUpdate = [SELECT Id, sked_Job_Allocation__c, sked_Timezone__c,
                                                                            Scheduled_Shift_Start__c, Scheduled_Shift_End__c,
                                                                            Scheduled_Shift_Start_Date__c,  Scheduled_Shift_Start_Time__c,
                                                                            Scheduled_Shift_End_Date__c, Scheduled_Shift_End_Time__c
                                                                            FROM sked_Operation_Record_Staff__c
                                                                            WHERE sked_Job_Allocation__c = :map_jobAllocationId_jobAllocation.keySet()];
            
        for(sked_Operation_Record_Staff__c opRecordStaff : opRecordStaffListToUpdate) {
            sked__Job_Allocation__c relatedJobAllocation = map_jobAllocationId_jobAllocation.get(opRecordStaff.sked_Job_Allocation__c);
            opRecordStaff.Scheduled_Shift_Start_Date__c = relatedJobAllocation.sked_Start_Date__c;
            opRecordStaff.Scheduled_Shift_Start_Time__c = relatedJobAllocation.sked_Start_Time__c;
            opRecordStaff.Scheduled_Shift_End_Date__c = relatedJobAllocation.sked_Set_End_Date__c;
            opRecordStaff.Scheduled_Shift_End_Time__c = relatedJobAllocation.sked_Set_End_Time__c;
        }
        update opRecordStaffListToUpdate;

    }

    /**************************************** RESOURCE HOURS RECORD ********************************************/
    private void syncToResourceHoursRecord(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        Set<Id> recordIdsToDelete = getDeletedJobAllocationIds(newRecords, oldMap);
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);
        
        Map<string, jobAllocationModel> mapUniqueKey_Allocations = new Map<string, jobAllocationModel>();
        Set<Id> recordIdsRequiringSync = new Set<Id>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldRecord = oldMap.get(newRecord.Id);
            if (!recordIdsToDelete.contains(newRecord.Id) && (oldRecord.sked__Start__c != newRecord.sked__Start__c || oldRecord.sked__Duration__c != newRecord.sked__Duration__c)) {
                string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                Date oldEventDate = skedDateTimeUtils.getDate(oldRecord.sked__Start__c, oldRecord.sked_Job_Timezone__c);
                Date newEventDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked_Job_Timezone__c);
                Date oldStartOfWeek = skedDateTimeUtils.findWeekStartDate(oldEventDate, workWeekday);
                Date newStartOfWeek = skedDateTimeUtils.findWeekStartDate(newEventDate, workWeekday);
                if (oldStartOfWeek != newStartOfWeek) {
                    recordIdsToDelete.add(newRecord.Id);

                    Date startOfWeek = newStartOfWeek;
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
                else {
                    recordIdsRequiringSync.add(newRecord.Id);
                }
            }
        }

        if (!recordIdsRequiringSync.isEmpty()) {
            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    skedJobAllocationHandler.class.getName(),
                    'performResourceHoursRecordDetailsSync',
                    recordIdsRequiringSync
                );
            } else {
                performResourceHoursRecordDetailsSync(recordIdsRequiringSync);
            }
        }

        if (!mapUniqueKey_Allocations.isEmpty() || !recordIdsToDelete.isEmpty()) {
            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    skedJobAllocationHandler.class.getName(),
                    'manageResourceHoursRecordDetails',
                    mapUniqueKey_Allocations,
                    recordIdsToDelete
                );
            } else {
                manageResourceHoursRecordDetails(mapUniqueKey_Allocations, recordIdsToDelete);
            }
        }
    }

    private static void manageResourceHoursRecordDetails(Map<String, jobAllocationModel> jobAllocationModelsByKey, Set<Id> recordIdsToDelete) {
        if (recordIdsToDelete != null && !recordIdsToDelete.isEmpty()) {
            deleteResourceHoursRecordDetails(recordIdsToDelete);
        }

        if (jobAllocationModelsByKey == null || jobAllocationModelsByKey.isEmpty()) return; 

        List<sked_Resource_Hours_Record__c> existingResourceHoursRecords = [
            SELECT Id, sked_Unique_Key__c
            FROM sked_Resource_Hours_Record__c
            WHERE sked_Unique_Key__c IN :jobAllocationModelsByKey.keySet()
        ];
            
        for (jobAllocationModel model : jobAllocationModelsByKey.values()) {
            model.hasKey = FALSE;
            for (sked_Resource_Hours_Record__c existingResourceHoursRecord : existingResourceHoursRecords) {
                if (model.key == existingResourceHoursRecord.sked_Unique_Key__c) {
                    for (sked__Job_Allocation__c jobAllocation : model.jobAllocations) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = existingResourceHoursRecord.Id, 
                            sked_Job_Allocation__c = jobAllocation.Id,
                            sked_Job_Allocation_Status__c = jobAllocation.sked__Status__c,
                            sked_Duration__c = jobAllocation.sked_Duration_with_Travel_Time__c,
                            sked_Job__c = jobAllocation.sked__Job__c
                        );
                        model.resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                    }
                    model.hasKey = TRUE;
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
            }
        }
        
        List<sked_Resource_Hours_Record__c> newResourceHoursRecords = new List<sked_Resource_Hours_Record__c>();
        for (jobAllocationModel model : jobAllocationModelsByKey.values()) {
            if (!model.hasKey) {
                newResourceHoursRecords.add(model.resourceHoursRecord);
            }
        }
        insert newResourceHoursRecords;

        List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        for (jobAllocationModel model : jobAllocationModelsByKey.values()) {
            if (!model.hasKey) {
                for (sked__Job_Allocation__c jobAllocation : model.jobAllocations) {
                    sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                        sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                        sked_Job_Allocation__c = jobAllocation.Id,
                        sked_Job_Allocation_Status__c = jobAllocation.sked__Status__c,
                        sked_Duration__c = jobAllocation.sked_Duration_with_Travel_Time__c,
                        sked_Job__c = jobAllocation.sked__Job__c
                    );
                    resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                }
            }
            else {
                resourceHoursRecordDetails.addAll(model.resourceHoursRecordDetails);
            }
        }
        insert resourceHoursRecordDetails;
    }

    private static void performResourceHoursRecordDetailsSync(Set<Id> jobAllocationIds) {
        Map<Id, sked__Job_Allocation__c> jobAllocationById = new Map<Id, sked__Job_Allocation__c>([
            SELECT Id, sked_Duration_with_Travel_Time__c, sked__Status__c
            FROM sked__Job_Allocation__c
            WHERE Id IN :jobAllocationIds
        ]);

        List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = [
            SELECT Id, sked_Duration__c, sked_Job_Allocation__c, sked_Job_Allocation_Status__c
            FROM sked_Resource_Hours_Record_Detail__c
            WHERE sked_Job_Allocation__c IN :jobAllocationById.keySet()
        ];
                
        for (sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail : resourceHoursRecordDetails) {
            sked__Job_Allocation__c jobAllocation = jobAllocationById.get(resourceHoursRecordDetail.sked_Job_Allocation__c);
            resourceHoursRecordDetail.sked_Duration__c = jobAllocation.sked_Duration_with_Travel_Time__c;
            resourceHoursRecordDetail.sked_Job_Allocation_Status__c = jobAllocation.sked__Status__c;
        }
        update resourceHoursRecordDetails;       
    }

    private static void deleteResourceHoursRecordDetails(List<sked__Job_Allocation__c> records) {
        delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Job_Allocation__c IN :records];
    }

    private static void deleteResourceHoursRecordDetails(Set<Id> recordIds) {
        delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Job_Allocation__c IN :recordIds];
    }

    private Set<Id> getDeletedJobAllocationIds(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        Set<Id> recordIdsToIgnore = new Set<Id>();
        
        List<string> deletedStatuses = new List<string>();
        deletedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DECLINED);
        deletedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DELETED);
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldRecord = oldMap.get(newRecord.Id);
            if (oldRecord.sked__Status__c != newRecord.sked__Status__c && deletedStatuses.contains(newRecord.sked__Status__c) && !deletedStatuses.contains(oldRecord.sked__Status__c)) {
                recordIdsToIgnore.add(newRecord.Id);
            }
        }

        return recordIdsToIgnore;
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
	private static void maintainExceptionLog(List<sked__Job_Allocation__c> skedAllocations, boolean processDriveShiftException, boolean processLinkedDriveExceptions, string otherExceptionCode) {
        skedExceptionMasterModel master = intializeMasterModel(skedAllocations);
        
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        
        if (processDriveShiftException == TRUE) {
            exceptionLog.addAll(captureDriveShiftExceptionLog(master));
        }

        if (processLinkedDriveExceptions == TRUE) {
            exceptionLog.addAll(captureLinkedDriveExceptionLog(master));
        }
        
        if (otherExceptionCode == 'travelTimeException') {
            exceptionLog.addAll(captureTravelTimeExceptionLog(master));
        }
        
        if (otherExceptionCode == 'additionalRolesException') {
            exceptionLog.addAll(captureAdditionalRolesExceptionLog(master));
        }

        if (otherExceptionCode == 'requiredTagException') {
            exceptionLog.addAll(captureRequiredTagExceptionLog(master));
        }
        
        if (!exceptionLog.isEmpty()) {
            upsert exceptionLog;
        }
    }
    
    private static skedExceptionMasterModel intializeMasterModel(List<sked__Job_Allocation__c> skedAllocations) {
        skedExceptionMasterModel master = new skedExceptionMasterModel();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            jobAllocationIds.add(skedAllocation.Id);
            jobIds.add(skedAllocation.sked__Job__c);
            resourceIds.add(skedAllocation.sked__Resource__c);
        }
        
        List<string> exceptionCodes = new List<string>();
        exceptionCodes.add(skedConstants.EXCEPTION_CODE_MAXIMUM_TRAVEL_TIME_VIOLATION);
        exceptionCodes.add(skedConstants.EXCEPTION_CODE_MISSING_REQUIRED_TAG);
        
        master.jobAllocations = [
            SELECT Id, Name, sked__Status__c, sked_Additional_Roles__c, sked__Job__r.sked_Drive__c, sked__Job__r.sked_Drive_Shift__c,
            sked__Resource__c, sked__Job__c, sked_Geoservice_Travel_Time_To__c, sked_Geoservice_Travel_Time_Back__c,
            (SELECT Id, skedHC__Status__c, sked_Exception_Code__c, skedHC__Exception__c
            FROM skedHC__Exception_Log__r
            WHERE sked_Exception_Code__c IN :exceptionCodes
            AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN)
            FROM sked__Job_Allocation__c
            WHERE Id IN :jobAllocationIds
        ];
        
        master.mapJob = new Map<Id, sked__Job__c>([
            SELECT Id, sked__Start__c, sked__Finish__c, sked__GeoLocation__c, sked__Type__c, sked__Duration__c, sked_Asset_Type__c,
            sked_Drive__r.sked_Account__c, sked_Drive__r.sked_Drive_Site__c, sked_Drive_Shift__c, sked_Drive__r.sked_Linked_Drives__c,
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
            sked__GeoLocation__c, sked_Max_Travel_Time__c,
            (SELECT Id, sked__Tag__c, sked__Expiry_Date__c, sked_Start__c, sked__Tag__r.Name
            FROM sked__ResourceTags__r),
            (SELECT Id, sked__Account__c, sked__Resource__c
            FROM sked__Account_Resource_Scores__r
            WHERE sked__Account__c IN :accountIds
            AND sked__Blacklisted__c = TRUE),
            (SELECT Id, sked__Location__c, sked__Resource__c
            FROM sked__Location_Resource_Scores__r
            WHERE sked__Location__c IN :locationIds
            AND sked__Blacklisted__c = TRUE)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
    	return master;
    }
    
    private static List<skedHC__Exception__c> captureDriveShiftExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        
        Set<Id> driveShiftIds = new Set<Id>();
        for (sked__Job__c skedJob : master.mapJob.values()) {
            if (skedJob.sked_Drive_Shift__c != NULL) {
                driveShiftIds.add(skedJob.sked_Drive_Shift__c);
            }
        }
        
        List<sked_Drive_Shift_Tag__c> driveShiftTags = [SELECT Id, sked_Drive_Shift__c, sked_Drive_Shift__r.sked_Drive__c, 
                                                        sked_Tag__c, sked_Tag__r.Name, sked_Minimum_Quantity__c,
                                                        (SELECT Id, skedHC__Status__c, sked_Exception_Code__c
                                                         FROM sked_Exception_Log__r
                                                         WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_MINIMUM_QUANTITY_NOT_MET
                                                         AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN)
                                                        FROM sked_Drive_Shift_Tag__c
                                                        WHERE sked_Drive_Shift__c IN :driveShiftIds
                                                        AND sked_Minimum_Quantity__c != NULL 
                                                        AND sked_Minimum_Quantity__c > 0];

        if (!driveShiftTags.isEmpty()) {
            List<sked__Job_Allocation__c> allJobAllocations = [SELECT Id, sked__Job__r.sked_Drive_Shift__c, sked__Resource__c,
                                                               sked__Start__c, sked__Set_End__c,
                                                               sked__Job__r.sked_Drive__r.sked_Drive_Date__c
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
                                                                                     (SELECT Id, sked__Tag__c, sked_Start__c
                                                                                      FROM sked__ResourceTags__r)
                                                                                     FROM sked__Resource__c
                                                                                     WHERE Id IN :resourceIds]);

            string messageTemplate = 'Not enough {{resourceTagName}}';
            for (sked_Drive_Shift_Tag__c driveShiftTag : driveShiftTags) {
                decimal minimumQuantity = driveShiftTag.sked_Minimum_Quantity__c;
                decimal numberOfResourcesHaveTag = 0;
                
                if (map_driveShiftId_jobAllocations.containsKey(driveShiftTag.sked_Drive_Shift__c)) {
                    List<sked__Job_Allocation__c> driveShiftAllocations = map_driveShiftId_jobAllocations.get(driveShiftTag.sked_Drive_Shift__c);
                    for (sked__Job_Allocation__c driveShiftAllocation : driveShiftAllocations) {
                        if (mapResource.containsKey(driveShiftAllocation.sked__Resource__c)) {
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
    
    private static List<skedHC__Exception__c> captureTravelTimeExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        
        for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
            sked__Resource__c resource = master.mapResource.get(skedAllocation.sked__Resource__c);
            
            skedHC__Exception__c existingTravelTimeException;
            if (skedAllocation.skedHC__Exception_Log__r != NULL && !skedAllocation.skedHC__Exception_Log__r.isEmpty()) {
                for (skedHC__Exception__c exceptionItem : skedAllocation.skedHC__Exception_Log__r) {
                    if (exceptionItem.sked_Exception_Code__c == skedConstants.EXCEPTION_CODE_MAXIMUM_TRAVEL_TIME_VIOLATION) {
                        existingTravelTimeException = exceptionItem;
                    }
                }
            }
            boolean isViolated = resource.sked_Max_Travel_Time__c < skedAllocation.sked_Geoservice_Travel_Time_To__c
                || resource.sked_Max_Travel_Time__c < skedAllocation.sked_Geoservice_Travel_Time_Back__c;
            if (isViolated && existingTravelTimeException == NULL) {
                skedHC__Exception__c skedException = new skedHC__Exception__c(
                    skedHC__Job__c = skedAllocation.sked__Job__c,
                    skedHC__Job_Allocation__c = skedAllocation.Id,
                    skedHC__Resource__c = skedAllocation.sked__Resource__c,
                    sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_MAXIMUM_TRAVEL_TIME_VIOLATION,
                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                );
                exceptionLog.add(skedException);
            }
            if (!isViolated && existingTravelTimeException != NULL) {
                existingTravelTimeException.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                exceptionLog.add(existingTravelTimeException);
            }
        }
        
        return exceptionLog;
    }

    private static List<skedHC__Exception__c> captureLinkedDriveExceptionLog(skedExceptionMasterModel master) {
        return skedJobAllocationPostProcessBatch.captureLinkedDriveMismatchedAssetExceptionLog(master);
    }
    
    private static List<skedHC__Exception__c> captureAdditionalRolesExceptionLog(skedExceptionMasterModel master) {
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        
        for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
            if (skedAllocation.sked_Additional_Roles__c != NULL && !string.isBlank(skedAllocation.sked_Additional_Roles__c)) {
                List<string> additionalRoles = skedAllocation.sked_Additional_Roles__c.split(';');
                
                sked__Resource__c resource = master.mapResource.get(skedAllocation.sked__Resource__c);
                sked__Job__c job = master.mapJob.get(skedAllocation.sked__Job__c);
                
                Set<string> excludedExceptionList = new Set<string>();
                for (sked__Job_Tag__c jobTag : job.sked__JobTags__r) {
                    excludedExceptionList.add('Missing required tag ' + jobTag.sked__Tag__r.Name);
                }
                
                Map<string, skedHC__Exception__c> mapExistingAdditionalRoleException = new Map<string, skedHC__Exception__c>();
                if (skedAllocation.skedHC__Exception_Log__r != NULL && !skedAllocation.skedHC__Exception_Log__r.isEmpty()) {
                    for (skedHC__Exception__c exceptionItem : skedAllocation.skedHC__Exception_Log__r) {
                        if (exceptionItem.sked_Exception_Code__c == skedConstants.EXCEPTION_CODE_MISSING_REQUIRED_TAG && !excludedExceptionList.contains(exceptionItem.skedHC__Exception__c)) {
                            mapExistingAdditionalRoleException.put(exceptionItem.skedHC__Exception__c, exceptionItem);
                        }
                    }
                }
                
                Set<string> activeExceptionList = new Set<string>();
                for (string additionalRole : additionalRoles) {
                    boolean isValid = FALSE;
                    for (sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {
                        if (resourceTag.sked__Tag__r.Name == additionalRole) {
                            isValid = TRUE;
                            break;
                        }
                    }
                    if (!isValid) {
                        string exceptionText = 'Missing required tag ' + additionalRole;
                        activeExceptionList.add(exceptionText);
                        
                        if (!mapExistingAdditionalRoleException.containsKey(exceptionText)) {
                            skedHC__Exception__c skedException = skedExceptionUtils.generateException(skedAllocation, skedConstants.EXCEPTION_CODE_MISSING_REQUIRED_TAG, exceptionText);
                            exceptionLog.add(skedException);
                        }
                    }
                }
                
                if (!mapExistingAdditionalRoleException.isEmpty()) {
                    for (skedHC__Exception__c exceptionItem : mapExistingAdditionalRoleException.values()) {
                        if (!activeExceptionList.contains(exceptionItem.skedHC__Exception__c)) {
                            exceptionItem.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                            exceptionLog.add(exceptionItem);
                        }
                    }
                }
            }
        }
        
        return exceptionLog;
    }
    
    private static List<skedHC__Exception__c> captureRequiredTagExceptionLog(skedExceptionMasterModel master) {
        List<string> driverTagNames = new List<string>{
            skedConstants.TAG_DRIVER,
            skedConstants.TAG_DRIVER_DOT,
            skedConstants.TAG_DRIVER_CDL
        };
        Map<string, sked__Tag__c> mapDriverTag = new Map<string, sked__Tag__c>();
        for (sked__Tag__c driverTag : [SELECT Id, Name FROM sked__Tag__c WHERE Name IN :driverTagNames]) {
            mapDriverTag.put(driverTag.Name, driverTag);
        }

        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        for (sked__Job_Allocation__c skedAllocation : master.jobAllocations) {
            sked__Job__c job = master.mapJob.get(skedAllocation.sked__Job__c);
            if (job.sked__JobTags__r == null || job.sked__JobTags__r.isEmpty()) continue;
            if (!master.mapResource.containsKey(skedAllocation.sked__Resource__c)) continue;

            sked__Resource__c resource = master.mapResource.get(skedAllocation.sked__Resource__c);
            Set<Id> resourceTagIds = new Set<Id>();
            if (resource.sked__ResourceTags__r != null) {
                for (sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {
                    if (resourceTag.sked_Start_Date__c <= job.sked_Drive__r.sked_Drive_Date__c) {
                        resourceTagIds.add(resourceTag.sked__Tag__c);
                    }
                }
            }

            // Find existing MISSING_REQUIRED_TAG exceptions for driver tags only
            Map<string, skedHC__Exception__c> existingExceptions = new Map<string, skedHC__Exception__c>();
            if (skedAllocation.skedHC__Exception_Log__r != null) {
                for (skedHC__Exception__c exc : skedAllocation.skedHC__Exception_Log__r) {
                    if (exc.sked_Exception_Code__c == skedConstants.EXCEPTION_CODE_MISSING_REQUIRED_TAG) {
                        for (string tagName : driverTagNames) {
                            if (exc.skedHC__Exception__c == 'Missing required tag ' + tagName) {
                                existingExceptions.put(exc.skedHC__Exception__c, exc);
                            }
                        }
                    }
                }
            }

            Set<string> activeExceptions = new Set<string>();
            for (sked__Job_Tag__c jobTag : job.sked__JobTags__r) {
                Id requiredTagId = jobTag.sked__Tag__c;
                string requiredTagName = jobTag.sked__Tag__r.Name;

                sked__Tag__c driverTag = mapDriverTag.get(skedConstants.TAG_DRIVER);
                if (driverTag != null && requiredTagId == driverTag.Id) {
                    if (skedAllocation.sked_DOT__c == true) {
                        sked__Tag__c driverDotTag = mapDriverTag.get(skedConstants.TAG_DRIVER_DOT);
                        requiredTagId = driverDotTag.Id;
                        requiredTagName = driverDotTag.Name;
                    }
                    if (skedAllocation.sked_CDL__c == true) {
                        sked__Tag__c driverCdlTag = mapDriverTag.get(skedConstants.TAG_DRIVER_CDL);
                        requiredTagId = driverCdlTag.Id;
                        requiredTagName = driverCdlTag.Name;
                    }
                }

                if (!resourceTagIds.contains(requiredTagId)) {
                    string exceptionText = 'Missing required tag ' + requiredTagName;
                    activeExceptions.add(exceptionText);
                    if (!existingExceptions.containsKey(exceptionText)) {
                        exceptionLog.add(skedExceptionUtils.generateException(skedAllocation, skedConstants.EXCEPTION_CODE_MISSING_REQUIRED_TAG, exceptionText));
                    }
                }
            }

            // Close exceptions that are no longer active
            for (skedHC__Exception__c exc : existingExceptions.values()) {
                if (!activeExceptions.contains(exc.skedHC__Exception__c)) {
                    exc.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                    exceptionLog.add(exc);
                }
            }
        }
        return exceptionLog;
    }

    private void sendNotifications(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        List<sked__Job_Allocation__c> impactedJobAllocations = new List<sked__Job_Allocation__c>();
        Map<Id, sked__Job_Allocation__c> oldImpactedJobAllocationMap = new Map<Id, sked__Job_Allocation__c>();
        Map<Id, sked__Job_Allocation__c> skedJobAllocationMap = new Map<Id, sked__Job_Allocation__c>([
            SELECT Id, sked__Resource__r.sked__Resource_Type__c
            FROM sked__Job_Allocation__c
            WHERE Id IN :newRecords
        ]);

        Set<Id> newRecordIds = new Set<Id>();
        for (sked__Job_Allocation__c job : newRecords) {
            newRecordIds.add(job.Id);
        }

        List<String> detectChangeFields = new List<String> {
            'sked__Start__c',
            'sked__Set_End__c'
        };
        List<String> excludedStatuses = new List<String> {
            skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            skedConstants.JOB_ALLOCATION_STATUS_DECLINED,
            skedConstants.JOB_ALLOCATION_STATUS_DELETED
        };

        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c skedJobAllocation = skedJobAllocationMap.get(newRecord.Id);
            if (!excludedStatuses.contains(newRecord.sked__Status__c) && skedJobAllocation.sked__Resource__r.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON) {
                sked__Job_Allocation__c oldData = oldMap.get(newRecord.Id);
                for (String detectChangeField : detectChangeFields) {
                    if (newRecord.get(detectChangeField) != oldData.get(detectChangeField)) {
                        impactedJobAllocations.add(newRecord);
                        oldImpactedJobAllocationMap.put(newRecord.Id, oldData);
                        break;
                    }
                }
            }
            
        }
        if (!impactedJobAllocations.isEmpty()) {
            new skedCustomNotificationService(
                new List<string> {
                    'sked_Job_Allocation_Info_Changed_OneOff',
                    'sked_Job_Allocation_Info_Changed_Email',
                    'sked_Job_Allocation_Info_Changed_SFPush'
                }
            ).generateNotifications(impactedJobAllocations, oldImpactedJobAllocationMap);
        }
    }

    /**************************************** NESTED CLASS ********************************************/
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