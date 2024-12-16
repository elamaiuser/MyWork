public class skedActivityHandler extends skedTriggerHub {

    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
        populateCollectionOperationData(this.context.newRecords);
    }
    
	public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            captureExceptionLogs(this.context.newRecords);
            syncResourcesFromLinkedDrive(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        populateData(this.context.newRecords, (Map<Id, sked__Activity__c>)this.context.oldMap);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Activity__c>)this.context.oldMap);
        }
        repopulateDistrict(this.context.newRecords, (Map<Id, sked__Activity__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            rescheduleActivity(this.context.newRecords, (Map<Id, sked__Activity__c>)this.context.oldMap);
            captureExceptionLogs(this.context.newRecords, (Map<Id, sked__Activity__c>)this.context.oldMap);
            syncResourcesFromLinkedDrive(this.context.newRecords, (Map<Id, sked__Activity__c>)this.context.oldMap);
        }
    }

    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.oldRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        createSkedDebugLog(this.context.oldMap.values());
        if (!skedSetting.instance.Admin.migrationMode) {
        	removeExceptionLogs((Map<Id, sked__Activity__c>)this.context.oldMap);
            removeResourceHoursForActivityResources(this.context.oldMap.values());
        }
        deleteAvailabilityForOnCallResources(this.context.oldMap.values());
    }

    /**************************************** Private methods ********************************************/
    private void createSkedDebugLog(List<sked__Activity__c> deletedRecords) {
        Set<Id> activityIds = new Set<Id>();
        for (sked__Activity__c activity : deletedRecords) {
            activityIds.add(activity.Id);
        }

        List<sked__Activity__c> deletedActivities = [
            SELECT Id, Name, sked_Activity_Title__c, sked__Start__c, sked__End__c, sked__Address__c,
            sked_Collection_Operation__r.Name, CreatedBy.Name, sked__Type__c, sked_SubType__c
            FROM sked__Activity__c
            WHERE Id IN :activityIds
        ];

        List<sked__Debug_Log__c> debugLogs = new List<sked__Debug_Log__c>();
        for (sked__Activity__c deletedRecord : deletedActivities) {
            String startDate = deletedRecord.sked__Start__c == null ? null : deletedRecord.sked__Start__c.format('MM/dd/yyyy HH:mm:ss', UserInfo.getTimezone().getID());
            String endDate = deletedRecord.sked__End__c == null ? null : deletedRecord.sked__End__c.format('MM/dd/yyyy HH:mm:ss', UserInfo.getTimezone().getID());
            debugLogs.add(new sked__Debug_Log__c(
                sked__Type__c = 'Activity Deleted',
                sked__Message__c = 'NOTICE: An Activity Record has been deleted',
                sked__Summary__c = 'An Activity Record with the following details has been deleted: ' +
                '\n\n ' +
                '\nName: ' + deletedRecord.Name +
                '\nActivity Title: ' + deletedRecord.sked_Activity_Title__c +
                '\nActivity Date: ' + startDate + ' - ' + endDate + 
                '\nActivity Address:' + deletedRecord.sked__Address__c +
                '\nCollection Operation: ' + deletedRecord.sked_Collection_Operation__r.Name +
                '\nType: ' + deletedRecord.sked__Type__c +
                '\nSubType: ' + deletedRecord.sked_Subtype__c +
                '\n\n Record was deleted by: ' + UserInfo.getName() + ' :: ' + UserInfo.getUserEmail() + 
                '\n Record was deleted at: ' + System.now()
            ));
        }

        if(!debugLogs.isEmpty()) {
            insert debugLogs;
        }
    }

    private void syncResourcesFromLinkedDrive(List<sked__Activity__c> newActivities, Map<Id, sked__Activity__c> oldActivities) {
        Set<Id> activityResourcesToDelete = new Set<Id>();
        List<sked__Activity__c> activitiesToSync = new List<sked__Activity__c>();

        for (sked__Activity__c newActivity : newActivities) {
            sked__Activity__c oldActivity = oldActivities.get(newActivity.Id);

            if (newActivity.sked_Drive__c != oldActivity.sked_Drive__c) {
                activityResourcesToDelete.add(newActivity.Id);
                if (newActivity.sked_Drive__c != null) {
                    activitiesToSync.add(newActivity);
                }
            }
        }

        delete [
            SELECT Id 
            FROM sked__Activity_Resource__c 
            WHERE sked__Activity__c IN :activityResourcesToDelete
            AND sked_Inherited_From_Drive__c = TRUE
        ];

        syncResourcesFromLinkedDrive(activitiesToSync);
    }

    private void syncResourcesFromLinkedDrive(List<sked__Activity__c> activities) {
        List<sked__Activity__c> linkedDriveActivities = new List<sked__Activity__c>();
        Set<Id> driveIds = new Set<Id>();
        for (sked__Activity__c activity : activities) {
            if (activity.sked_Drive__c != null && activity.sked_Inherit_Resources_From_Drive__c) {
                linkedDriveActivities.add(activity);
                driveIds.add(activity.sked_Drive__c);
            }
        }

        if (!linkedDriveActivities.isEmpty()) {
            List<String> nonDeletedJobAllocationStatuses = new List<String>{
                skedConstants.JOB_ALLOCATION_STATUS_DECLINED,
                skedConstants.JOB_ALLOCATION_STATUS_DELETED
            };
            List<sked__Job_Allocation__c> driveJAs = [
                SELECT Id, sked__Job__r.sked_Drive__c, sked__Resource__c
                FROM sked__Job_Allocation__c
                WHERE sked__Job__r.sked_Drive__c IN :driveIds
                AND sked__Status__c NOT IN :nonDeletedJobAllocationStatuses
            ];

            Map<Id, List<sked__Job_Allocation__c>> jobAllocationsByDriveId = getJobAllocationsByDriveId(driveJAs);

            List<sked__Activity_Resource__c> newActivityResources = new List<sked__Activity_Resource__c>();

            for (sked__Activity__c activity : linkedDriveActivities) {
                if (jobAllocationsByDriveId.containsKey(activity.sked_Drive__c)) {
                    for (sked__Job_Allocation__c jobAllocation : jobAllocationsByDriveId.get(activity.sked_Drive__c)) {
                        newActivityResources.add(new sked__Activity_Resource__c(
                            sked__Activity__c = activity.Id,
                            sked__Resource__c = jobAllocation.sked__Resource__c,
                            sked_Inherited_From_Drive__c = true
                        ));
                    }
                }
            }

            if (!newActivityResources.isEmpty()) {
                insert newActivityResources;
            }
        }
    }

    private Map<Id, List<sked__Job_Allocation__c>> getJobAllocationsByDriveId(List<sked__Job_Allocation__c> driveJobAllocations) {
        Map<Id, List<sked__Job_Allocation__c>> jobAllocationsByDriveId = new Map<Id, List<sked__Job_Allocation__c>>();
        for (sked__Job_Allocation__c driveJobAllocation : driveJobAllocations) {
            List<sked__Job_Allocation__c> jobAllocationsForDrive = jobAllocationsByDriveId.get(driveJobAllocation.sked__Job__r.sked_Drive__c);

            if (jobAllocationsForDrive == null) {
                jobAllocationsForDrive = new List<sked__Job_Allocation__c>();
            }

            jobAllocationsForDrive.add(driveJobAllocation);
            jobAllocationsByDriveId.put(driveJobAllocation.sked__Job__r.sked_Drive__c, jobAllocationsForDrive);
        }

        return jobAllocationsByDriveId;
    }

    private void captureExceptionLogs(List<sked__Activity__c> newRecords) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
		for (sked__Activity__c newRecord : newRecords) {
            if (newRecord.sked_Is_Group_Activity__c == FALSE) {
                skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
                unavailability.resourceId = newRecord.sked__Resource__c;
                unavailability.startTime = newRecord.sked__Start__c;
                unavailability.endTime = newRecord.sked__End__c;
                unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
                unavailability.exceptionText = 'Conflict with ' + newRecord.Name;
                unavailability.relatedEventFieldApi = 'skedHC__Activity__c';
                unavailability.recordId = newRecord.Id;
                unavailabilityList.add(unavailability);
            }
		}
		if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
			service.captureExceptionLogs(unavailabilityList);
		}
    }
    
    private void captureExceptionLogs(List<sked__Activity__c> newRecords, Map<Id, sked__Activity__c> updatedRecords) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
        Set<Id> groupActivityIds = new Set<Id>();
        for (sked__Activity__c record : newRecords) {
            if (record.sked_Is_Group_Activity__c == TRUE) {
                groupActivityIds.add(record.Id);
            }
        }
        List<sked__Activity_Resource__c> groupActivities = new List<sked__Activity_Resource__c>();
        if (!groupActivityIds.isEmpty()) {
            groupActivities = [SELECT Id, sked__Resource__c, sked__Activity__c, sked__Activity__r.Name,
                               sked__Activity__r.sked__Start__c, sked__Activity__r.sked__End__c, sked__Activity__r.sked__Type__c
                               FROM sked__Activity_Resource__c
                               WHERE sked__Activity__c IN :groupActivityIds];
        }
        for (sked__Activity__c record : newRecords) {
            if (record.sked_Is_Group_Activity__c == FALSE) {
                sked__Activity__c oldRecord = updatedRecords.get(record.Id);
                if (record.sked__Start__c != oldRecord.sked__Start__c || record.sked__End__c != oldRecord.sked__End__c) {
                    skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
                    unavailability.resourceId = record.sked__Resource__c;
                    unavailability.startTime = record.sked__Start__c;
                    unavailability.endTime = record.sked__End__c;
                    unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
                    unavailability.exceptionText = 'Conflict with ' + record.Name;
                    unavailability.relatedEventFieldApi = 'skedHC__Activity__c';
                    unavailability.recordId = record.Id;
                    unavailabilityList.add(unavailability);
                }
            }
        }
        if (!groupActivities.isEmpty()) {
            for (sked__Activity_Resource__c item : groupActivities) {
                skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
                unavailability.resourceId = item.sked__Resource__c;
                unavailability.startTime = item.sked__Activity__r.sked__Start__c;
                unavailability.endTime = item.sked__Activity__r.sked__End__c;
                unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
                unavailability.exceptionText = 'Conflict with ' + item.sked__Activity__r.Name;
                unavailability.relatedEventFieldApi = 'skedHC__Activity__c';
                unavailability.recordId = item.sked__Activity__c;
                unavailabilityList.add(unavailability);
            }
        }
        if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
            service.captureExceptionLogs(unavailabilityList);
        }
    }
    
    private void populateData(List<sked__Activity__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> regionIds = new Set<Id>();
        for (sked__Activity__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked__Resource__c)) {
                resourceIds.add(newRecord.sked__Resource__c);
            }
            if (!string.isBlank(newRecord.sked_Region__c)) {
                regionIds.add(newRecord.sked_Region__c);
            }
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Primary_Region__c, sked__Primary_Region__r.sked__Timezone__c,
                                                                                 sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        Map<Id, sked__Region__c> mapRegion = new Map<Id, sked__Region__c>([SELECT Id, sked__Timezone__c, sked_Biomed_Collection_Op_Center__c
                                                                           FROM sked__Region__c
                                                                           WHERE Id IN :regionIds]);
        
        for (sked__Activity__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked__Resource__c) && mapResource.containsKey(newRecord.sked__Resource__c)) {
                sked__Resource__c resource = mapResource.get(newRecord.sked__Resource__c);
                if (resource.sked__Primary_Region__c != NULL) {
                    newRecord.sked__Timezone__c = resource.sked__Primary_Region__r.sked__Timezone__c;
                }
            }
            else if (!string.isBlank(newRecord.sked_Region__c) && mapRegion.containsKey(newRecord.sked_Region__c)) {
                sked__Region__c region = mapRegion.get(newRecord.sked_Region__c);
                newRecord.sked__Timezone__c = region.sked__Timezone__c;
                newRecord.sked_Collection_Operation__c = region.sked_Biomed_Collection_Op_Center__c;
            }
            if (newRecord.sked__Start__c != NULL) {
                string timezoneSidId = newRecord.sked__Timezone__c != NULL ? newRecord.sked__Timezone__c : UserInfo.getTimeZone().getID();
                newRecord.sked_Day_of_Week__c = newRecord.sked__Start__c.format('EEEE', timezoneSidId);
            }
            if (newRecord.sked_Fixed_Site_Staff_Quantity__c != NULL || newRecord.sked_Mobile_Staff_Quantity__c != NULL) {
                decimal fixedSiteStaffQuantity = newRecord.sked_Fixed_Site_Staff_Quantity__c != NULL ? newRecord.sked_Fixed_Site_Staff_Quantity__c : 0;
                decimal mobileStaffQuantity = newRecord.sked_Mobile_Staff_Quantity__c != NULL ? newRecord.sked_Mobile_Staff_Quantity__c : 0;
                newRecord.sked__Quantity__c = fixedSiteStaffQuantity + mobileStaffQuantity;
            }
        }
    }
    
    private void populateData(List<sked__Activity__c> newRecords, Map<Id, sked__Activity__c> updatedRecords) {
        for (sked__Activity__c newRecord : newRecords) {
            sked__Activity__c oldData = updatedRecords.get(newRecord.Id);
            if (newRecord.sked__Start__c != oldData.sked__Start__c && newRecord.sked__Start__c != NULL) {
                string timezoneSidId = newRecord.sked__Timezone__c != NULL ? newRecord.sked__Timezone__c : UserInfo.getTimeZone().getID();
                newRecord.sked_Day_of_Week__c = newRecord.sked__Start__c.format('EEEE');
            }
            if (newRecord.sked_Fixed_Site_Staff_Quantity__c != oldData.sked_Fixed_Site_Staff_Quantity__c || newRecord.sked_Mobile_Staff_Quantity__c != oldData.sked_Mobile_Staff_Quantity__c) {
                decimal fixedSiteStaffQuantity = newRecord.sked_Fixed_Site_Staff_Quantity__c != NULL ? newRecord.sked_Fixed_Site_Staff_Quantity__c : 0;
                decimal mobileStaffQuantity = newRecord.sked_Mobile_Staff_Quantity__c != NULL ? newRecord.sked_Mobile_Staff_Quantity__c : 0;
                newRecord.sked__Quantity__c = fixedSiteStaffQuantity + mobileStaffQuantity;
            }
        }
    }
    
    private void populateCollectionOperationData(List<sked__Activity__c> newRecords) {
        List<sked__Activity__c> recordsToPopulate = new List<sked__Activity__c>();
        Date minDate = System.today();
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked__Activity__c newRecord : newRecords) {
            recordsToPopulate.add(newRecord);
            
            if (newRecord.sked_Collection_Operation__c != NULL) {
                collectionOperationIds.add(newRecord.sked_Collection_Operation__c);
            }
            if (newRecord.sked_Start_Date__c != NULL && newRecord.sked_Start_Date__c < minDate) {
                minDate = newRecord.sked_Start_Date__c;
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>();
            if (!collectionOperationIds.isEmpty()) {
                mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([SELECT Id, sked_Hold_Threshold__c, sked_Travel_Time_Included_Mobile__c,
                                                                     sked_Travel_Time_Included_Fixed_Site__c,
                                                                     (SELECT Id, sked_End_Date__c, sked_Start_Date__c, sked_Territory__c
                                                                      FROM sked_Territory_Collection_Operations__r)
                                                                     FROM Biomed_Collection_Op_Center__c
                                                                     WHERE Id IN :collectionOperationIds]);
            }
            
            for (sked__Activity__c recordToPopulate : recordsToPopulate) {
                if (mapCO.containsKey(recordToPopulate.sked_Collection_Operation__c)) {
                    Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(recordToPopulate.sked_Collection_Operation__c);
                    
                    for (sked_Territory_Collection_Operation__c territoryCO : collectionOperation.sked_Territory_Collection_Operations__r) {
                        boolean isStartDateMatched = territoryCO.sked_Start_Date__c == NULL || territoryCO.sked_Start_Date__c <= recordToPopulate.sked_Start_Date__c;
                        boolean isEndDateMatched = territoryCO.sked_End_Date__c == NULL || territoryCO.sked_End_Date__c >= recordToPopulate.sked_Start_Date__c;
                        if (isStartDateMatched && isEndDateMatched) {
                            recordToPopulate.sked_District__c = territoryCO.sked_Territory__c;
                            break;
                        }
                    }
                }
            }
        }
    }

    private void repopulateDistrict(List<sked__Activity__c> newRecords, Map<Id, sked__Activity__c> updatedRecords) {
        List<sked__Activity__c> recordsToPopulate = new List<sked__Activity__c>();
        for (sked__Activity__c newRecord : newRecords) {
            sked__Activity__c oldData = updatedRecords.get(newRecord.Id);
            if (newRecord.sked_Collection_Operation__c != oldData.sked_Collection_Operation__c || newRecord.sked_Start_Date__c != oldData.sked_Start_Date__c) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            populateCollectionOperationData(recordsToPopulate);
        }
    }
    
    private void doDateTimeConversion(List<sked__Activity__c> newRecords) {
        for (sked__Activity__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked__Timezone__c');
        }
    }

    private void doDateTimeConversion(List<sked__Activity__c> newRecords, Map<Id, sked__Activity__c> updatedRecords) {
        for (sked__Activity__c newRecord : newRecords) {
            sked__Activity__c oldData = updatedRecords.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked__Timezone__c');
        }
    }

    private void removeExceptionLogs(Map<Id, sked__Activity__c> oldMap) {
        Set<Id> activityIds = new Set<Id>();
        for (sked__Activity__c oldData : oldMap.values()) {
            activityIds.add(oldData.Id);
        }
        if (!activityIds.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
            service.removeExceptionLogs(oldMap.keySet());
        }
    }
    
    private void rescheduleActivity(List<sked__Activity__c> newRecords, Map<Id, sked__Activity__c> oldMap) {
        Set<Id> rescheduledActivityIds = new Set<Id>();
        for (sked__Activity__c newRecord : newRecords) {
            sked__Activity__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Start__c != oldData.sked__Start__c || newRecord.sked__End__c != oldData.sked__End__c) {
                rescheduledActivityIds.add(newRecord.Id);
            }
        }
        if (!rescheduledActivityIds.isEmpty()) {
            List<sked__Activity__c> rescheduledActivitys = [SELECT Id, sked__Start__c, sked__End__c,
                                                            (SELECT Id, sked_Start1__c, sked_End__c
                                                             FROM sked__Activity_Resources__r)
                                                            FROM sked__Activity__c
                                                            WHERE Id IN :rescheduledActivityIds];
            List<sked__Activity_Resource__c> activityResourcesToUpdate = new List<sked__Activity_Resource__c>();
            for (sked__Activity__c rescheduledActivity : rescheduledActivitys) {
                if (rescheduledActivity.sked__Activity_Resources__r != NULL && !rescheduledActivity.sked__Activity_Resources__r.isEmpty()) {
                    sked__Activity__c oldData = oldMap.get(rescheduledActivity.Id);
                    for (sked__Activity_Resource__c activityResource : rescheduledActivity.sked__Activity_Resources__r) {
                        if (rescheduledActivity.sked__Start__c != oldData.sked__Start__c) {
                            integer difference = skedDateTimeUtils.getDifferentMinutes(oldData.sked__Start__c, rescheduledActivity.sked__Start__c);
                            activityResource.sked_Start1__c = activityResource.sked_Start1__c.addMinutes(difference);
                        }
                        if (rescheduledActivity.sked__End__c != oldData.sked__End__c) {
                            integer difference = skedDateTimeUtils.getDifferentMinutes(oldData.sked__End__c, rescheduledActivity.sked__End__c);
                            activityResource.sked_End__c = rescheduledActivity.sked__End__c;
                        }
                        if (activityResource.sked_Start1__c < rescheduledActivity.sked__Start__c || activityResource.sked_Start1__c > rescheduledActivity.sked__End__c) {
                            activityResource.sked_Start1__c = rescheduledActivity.sked__Start__c;
                        }
                        if (activityResource.sked_End__c > rescheduledActivity.sked__End__c || activityResource.sked_End__c < rescheduledActivity.sked__Start__c) {
                            activityResource.sked_End__c = rescheduledActivity.sked__End__c;
                        }
                        activityResourcesToUpdate.add(activityResource);
                    }
                }
            }
            if (!activityResourcesToUpdate.isEmpty()) {
                update activityResourcesToUpdate;
            }
        }
    }

    private void removeResourceHoursForActivityResources(List<sked__Activity__c> deletedRecords) {
        List<sked__Activity_Resource__c> activityResources = [
            SELECT Id
            FROM sked__Activity_Resource__c
            WHERE sked__Activity__c
            IN :deletedRecords
        ];

        if (activityResources != null && !activityResources.isEmpty()) {
            delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Activity_Resource__c IN :activityResources];
        }
    }

    private void deleteAvailabilityForOnCallResources(List<sked__Activity__c> deletedRecords) {
        List<sked__Activity_Resource__c> activityResources = [
            SELECT Id, sked__Resource__c, sked_Start1__c, sked_End__c,
            sked__Activity__r.sked__Type__c, sked__Activity__r.sked__Start__c, sked__Activity__r.sked__End__c
            FROM sked__Activity_Resource__c
            WHERE sked__Activity__c IN :deletedRecords
            AND sked__Activity__r.sked__Type__c = :skedConstants.AVAILABILITY_TYPE_ON_CALL
        ];
        
        if (activityResources != null && !activityResources.isEmpty()) {
            List<sked__Availability__c> availabilities = [SELECT Id
                                                          FROM sked__Availability__c
                                                          WHERE sked_Activity_Resource__c IN :activityResources];
            if (!availabilities.isEmpty()) {
                delete availabilities;
            }
        }
    }
    
}