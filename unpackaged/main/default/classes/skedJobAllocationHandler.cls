public class skedJobAllocationHandler extends skedTriggerHub {
    
    public static boolean isRunningPostProcess = FALSE;
    
    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
        if (!skedSetting.instance.Admin.migrationMode) {
            onDeleteJobAllocation((Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            removeResourceForLinkedActivities((Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            removeResourceHoursRecord(this.context.oldMap.values());
        }
    }
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
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
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
        populateData(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
        }
    }

    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            onStatusChanged(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            onTravelTimeChanged(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            updateDriveVehicleTypes(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            removeResourceForLinkedActivities(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
            syncToResourceHoursRecord(this.context.newRecords, (Map<Id, sked__Job_Allocation__c>)this.context.oldMap);
        }
    }
    /**************************************** PRIVATE METHOD ********************************************/
    private void processPostInsert(List<sked__Job_Allocation__c> newRecords) {
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            jobAllocationIds.add(newRecord.Id);
        }
        if (!Test.isRunningTest() && !System.isBatch() && !skedSetting.instance.Admin.migrationMode) {
            Database.executeBatch(new skedJobAllocationTravelTimeBatch(jobAllocationIds), 100);
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
        }
    }

    private void removeResourceForLinkedActivities(Map<Id, sked__Job_Allocation__c> oldMap) {
        Set<String> jobAlloctionIds = new Set<string>();

        for (sked__Job_Allocation__c oldData : oldMap.values()) {
            jobAlloctionIds.add(oldData.Id);
        }

        if (!jobAlloctionIds.isEmpty()) {
            syncResourceForLinkedActivity(jobAlloctionIds, FALSE, TRUE);
        }
    }

    private void removeResourceForLinkedActivities(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        List<string> statuses = new List<string> {skedConstants.JOB_ALLOCATION_STATUS_DELETED, skedConstants.JOB_ALLOCATION_STATUS_DECLINED};
        Set<string> jobAlloctionIds = new Set<string>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldData = oldMap.get(newRecord.Id);

            if (statuses.contains(newRecord.sked__Status__c) && newRecord.sked__Status__c != oldData.sked__Status__c) {
                jobAlloctionIds.add(newRecord.Id);
            }
        }

        if (!jobAlloctionIds.isEmpty()) {
            syncResourceForLinkedActivity(jobAlloctionIds, FALSE, TRUE);
        }
    }

    private void syncResourceForLinkedActivity(Set<string> jobAlloctionIds, Boolean isAdd, Boolean isRemove) {
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
        boolean processTravelTimeException = FALSE;
        maintainExceptionLog(oldMap.values(), processDriveShiftException, processTravelTimeException);
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
            boolean processTravelTimeException = FALSE;
            maintainExceptionLog(mapDeletedRecord.values(), processDriveShiftException, processTravelTimeException);
        }
    }
    
    private void onTravelTimeChanged(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        List<sked__Job_Allocation__c> recordsToProcess = new List<sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c allocation : newRecords) {
            sked__Job_Allocation__c oldData = oldMap.get(allocation.Id);
            if (allocation.sked_Geoservice_Travel_Time_To__c != oldData.sked_Geoservice_Travel_Time_To__c || allocation.sked_Geoservice_Travel_Time_Back__c != oldData.sked_Geoservice_Travel_Time_Back__c) {
                recordsToProcess.add(allocation);
            }
        }
        if (!recordsToProcess.isEmpty()) {
            boolean processDriveShiftException = FALSE;
            boolean processTravelTimeException = TRUE;
            maintainExceptionLog(recordsToProcess, processDriveShiftException, processTravelTimeException);
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
        skedJobAllocationHandler.updateDriveVehicleTypes(jobAllocationIds);
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
        if (!jobAllocationIds.isEmpty()) {
            updateDriveVehicleTypes(jobAllocationIds);
        }
    }
    
    public static void updateDriveVehicleTypes(Set<Id> jobAllocationIds) {
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

    /**************************************** RESOURCE HOURS RECORD ********************************************/
    private void syncToResourceHoursRecord(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        Set<Id> ignoreRecordIds = syncHoursAfterChangeStatus(newRecords, oldMap);
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);
        
        Map<string, jobAllocationModel> mapUniqueKey_Allocations = new Map<string, jobAllocationModel>();
        Map<Id, sked__Job_Allocation__c> mapAllocationNeedToSync = new Map<Id, sked__Job_Allocation__c>();
        List<sked__Job_Allocation__c> jobAllocationsNeedToDeleteResourceHoursRecordDetail = new List<sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldRecord = oldMap.get(newRecord.Id);
            if (!ignoreRecordIds.contains(newRecord.Id) && (oldRecord.sked__Start__c != newRecord.sked__Start__c || oldRecord.sked__Duration__c != newRecord.sked__Duration__c)) {
                string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                Date oldEventDate = skedDateTimeUtils.getDate(oldRecord.sked__Start__c, oldRecord.sked_Job_Timezone__c);
                Date newEventDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked_Job_Timezone__c);
                Date oldStartOfWeek = skedDateTimeUtils.findWeekStartDate(oldEventDate, workWeekday);
                Date newStartOfWeek = skedDateTimeUtils.findWeekStartDate(newEventDate, workWeekday);
                if (oldStartOfWeek != newStartOfWeek) {
                    jobAllocationsNeedToDeleteResourceHoursRecordDetail.add(newRecord);

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
                    mapAllocationNeedToSync.put(newRecord.Id,  newRecord);
                }
            }
        }
        if (!mapAllocationNeedToSync.isEmpty()) {
            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = [SELECT Id, sked_Duration__c, sked_Job_Allocation__c, sked_Job_Allocation_Status__c
                                                                                    FROM sked_Resource_Hours_Record_Detail__c
                                                                                    WHERE sked_Job_Allocation__c IN :mapAllocationNeedToSync.keySet()];
            for (sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail : resourceHoursRecordDetails) {
                sked__Job_Allocation__c jobAllocation = mapAllocationNeedToSync.get(resourceHoursRecordDetail.sked_Job_Allocation__c);
                resourceHoursRecordDetail.sked_Duration__c = jobAllocation.sked_Duration_with_Travel_Time__c;
                resourceHoursRecordDetail.sked_Job_Allocation_Status__c = jobAllocation.sked__Status__c;
            }
            update resourceHoursRecordDetails;
        }
        
        if (!jobAllocationsNeedToDeleteResourceHoursRecordDetail.isEmpty()) {
            delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Job_Allocation__c IN :jobAllocationsNeedToDeleteResourceHoursRecordDetail];
        }
        if (!mapUniqueKey_Allocations.isEmpty()) {
            List<sked_Resource_Hours_Record__c> existingResourceHoursRecords = [SELECT Id, sked_Unique_Key__c
                                                                                FROM sked_Resource_Hours_Record__c
                                                                                WHERE sked_Unique_Key__c IN :mapUniqueKey_Allocations.keySet()];
            for (jobAllocationModel model : mapUniqueKey_Allocations.values()) {
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
            for (jobAllocationModel model : mapUniqueKey_Allocations.values()) {
                if (!model.hasKey) {
                    newResourceHoursRecords.add(model.resourceHoursRecord);
                }
            }
            insert newResourceHoursRecords;

            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
            for (jobAllocationModel model : mapUniqueKey_Allocations.values()) {
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
    }

    private void removeResourceHoursRecord(List<sked__Job_Allocation__c> newRecords) {
        delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Job_Allocation__c IN :newRecords];
    }

    private Set<Id> syncHoursAfterChangeStatus(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> oldMap) {
        Set<Id> ignoreRecordIds = new Set<Id>();
        List<string> excludedStatuses = new List<string>();
        excludedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DECLINED);
        excludedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DELETED);

        Set<Id> needToDeleteRecords = new Set<Id>();
        for (sked__Job_Allocation__c newRecord : newRecords) {
            sked__Job_Allocation__c oldRecord = oldMap.get(newRecord.Id);
            if (oldRecord.sked__Status__c != newRecord.sked__Status__c && excludedStatuses.contains(newRecord.sked__Status__c) && !excludedStatuses.contains(oldRecord.sked__Status__c)) {
                needToDeleteRecords.add(newRecord.Id);
                ignoreRecordIds.add(newRecord.Id);
            }
        }
        if (!needToDeleteRecords.isEmpty()) {
            delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Job_Allocation__c IN :needToDeleteRecords];
        }

        return ignoreRecordIds;
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
    private void maintainExceptionLog(List<sked__Job_Allocation__c> skedAllocations, boolean processDriveShiftException, boolean processTravelTimeException) {
        exceptionMasterModel master = intializeMasterModel(skedAllocations);
        
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        
        if (processDriveShiftException == TRUE) {
            List<skedHC__Exception__c> driveShiftExceptionLog = captureDriveShiftExceptionLog(master);
            exceptionLog.addAll(driveShiftExceptionLog);
        }
        
        if (processTravelTimeException == TRUE) {
            List<skedHC__Exception__c> travelTimeExceptionLog = captureTravelTimeExceptionLog(master);
            exceptionLog.addAll(travelTimeExceptionLog);
        }
        
        if (!exceptionLog.isEmpty()) {
            upsert exceptionLog;
        }
    }
    
    private exceptionMasterModel intializeMasterModel(List<sked__Job_Allocation__c> skedAllocations) {
        exceptionMasterModel master = new exceptionMasterModel();
        Set<Id> jobIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            jobAllocationIds.add(skedAllocation.Id);
            jobIds.add(skedAllocation.sked__Job__c);
            resourceIds.add(skedAllocation.sked__Resource__c);
        }
        master.jobAllocations = [SELECT Id, Name, sked__Job__r.sked_Drive__c, sked__Job__r.sked_Drive_Shift__c,
                                 sked__Resource__c, sked__Job__c, sked_Geoservice_Travel_Time_To__c, sked_Geoservice_Travel_Time_Back__c,
                                 (SELECT Id, skedHC__Status__c, sked_Exception_Code__c
                                  FROM skedHC__Exception_Log__r
                                  WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_MAXIMUM_TRAVEL_TIME_VIOLATION
                                  AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN)
                                 FROM sked__Job_Allocation__c
                                 WHERE Id IN :jobAllocationIds];
        
        master.mapJob = new Map<Id, sked__Job__c>([SELECT Id, sked__Start__c, sked__Finish__c, sked__GeoLocation__c, sked__Type__c, sked__Duration__c,
                                                   sked_Drive__r.sked_Account__c, sked_Drive__r.sked_Drive_Site__c, sked_Drive_Shift__c,
                                                   (SELECT Id, sked__Tag__c, sked__Tag__r.Name
                                                    FROM sked__JobTags__r)
                                                   FROM sked__Job__c
                                                   WHERE Id IN :jobIds]);
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
        
        master.mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked_Maximum_Travel_Radius__c, sked_Turnaround_Time__c, sked__Resource_Type__c,
                                                             sked__GeoLocation__c, sked_Max_Travel_Time__c,
                                                             (SELECT Id, sked__Tag__c, sked__Expiry_Date__c, sked_Start__c
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
                                                             WHERE Id IN :resourceIds]);
    	return master;
    }
    
    private List<skedHC__Exception__c> captureDriveShiftExceptionLog(exceptionMasterModel master) {
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
                                                                                     (SELECT Id, sked__Tag__c, sked_Expiry_Date__c, sked_Start__c
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
                                    boolean isNotExpired = resourceTag.sked_Start__c <= driveShiftAllocation.sked__Start__c
                                        && (resourceTag.sked_Expiry_Date__c == NULL || driveShiftAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c <= resourceTag.sked_Expiry_Date__c);
                                    if (isNotExpired) {
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
    
    private List<skedHC__Exception__c> captureTravelTimeExceptionLog(exceptionMasterModel master) {
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
    
    /**************************************** NESTED CLASS ********************************************/
    public class exceptionMasterModel {
        public List<sked__Job_Allocation__c> jobAllocations;
        public Map<Id, sked_Drive_Shift__c> mapDriveShift;
        public Map<Id, sked__Job__c> mapJob;
        public Map<Id, sked__Resource__c> mapResource;
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