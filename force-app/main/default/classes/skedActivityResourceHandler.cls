public class skedActivityResourceHandler extends skedTriggerHub implements Callable {
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
        populateResourceType(this.context.newRecords);
    }

    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
        	captureExceptionLogs(this.context.newRecords);
        	syncToResourceHoursRecord(this.context.newRecords);
        }
        createAvailabilityForOnCallResources(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Activity_Resource__c>)this.context.oldMap);
        }
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
        	syncToResourceHoursRecord(this.context.newRecords, (Map<Id, sked__Activity_Resource__c>)this.context.oldMap);
        }
        syncOnCallAvailabilities(this.context.newRecords, (Map<Id, sked__Activity_Resource__c>)this.context.oldMap);
    }

    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.oldRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        if (!skedSetting.instance.Admin.migrationMode) {
        	removeExceptionLogs((Map<Id, sked__Activity_Resource__c>)this.context.oldMap);
        	removeResourceHoursRecord(this.context.oldMap.values());
        }
        skedFutureCallEventHandler.publishFutureCallEvent(
            skedActivityResourceHandler.class.getName(),
            'deleteAvailabilityForOnCallResources',
            this.context.oldMap.keySet()
        );
    }
    /*********************************************************** Callable Interface ***********************************************************/
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'deleteAvailabilityForOnCallResources' {
                    deleteAvailabilityForOnCallResources((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedBiomedCollectionOpHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }
    /*********************************************************** Private methods ***********************************************************/
    private void captureExceptionLogs(List<sked__Activity_Resource__c> newRecords) {
        Set<Id> activityIds = new Set<Id>();
        for (sked__Activity_Resource__c newRecord : newRecords) {
            activityIds.add(newRecord.sked__Activity__c);
        }
        Map<Id, sked__Activity__c> mapActivity = new Map<Id, sked__Activity__c>([
            SELECT Id, Name, sked__Start__c, sked__End__c, sked__Type__c, sked_Is_Group_Activity__c
            FROM sked__Activity__c
            WHERE Id IN :activityIds
        ]);
        
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
		for (sked__Activity_Resource__c newRecord : newRecords) {
            sked__Activity__c activity = mapActivity.get(newRecord.sked__Activity__c);
            skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
            unavailability.resourceId = newRecord.sked__Resource__c;
            unavailability.startTime = newRecord.sked_Start1__c;
            unavailability.endTime = newRecord.sked_End__c;
            unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
            unavailability.exceptionText = 'Conflict with ' + activity.Name;
            unavailability.relatedEventFieldApi = 'skedHC__Activity__c';
            unavailability.recordId = activity.Id;
            unavailabilityList.add(unavailability);
		}
		if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
			service.captureExceptionLogs(unavailabilityList);
		}
    }

    private void doDateTimeConversion(List<sked__Activity_Resource__c> newRecords) {
        for (sked__Activity_Resource__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Start1__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked__Activity_Resource__c> newRecords, Map<Id, sked__Activity_Resource__c> updatedRecords) {
        for (sked__Activity_Resource__c newRecord : newRecords) {
            sked__Activity_Resource__c oldData = updatedRecords.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Start1__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void populateData(List<sked__Activity_Resource__c> newRecords) {
        Set<Id> activityIdsToPopulateDateTime = new Set<Id>();
        for (sked__Activity_Resource__c newRecord : newRecords) {
            if (newRecord.sked_Start1__c == NULL || newRecord.sked_End__c == NULL) {
                activityIdsToPopulateDateTime.add(newRecord.sked__Activity__c);
            }
        }
        if (!activityIdsToPopulateDateTime.isEmpty()) {
            Map<Id, sked__Activity__c> mapActivity = new Map<Id, sked__Activity__c>([SELECT Id, sked__Start__c, sked__End__c
                                                                                     FROM sked__Activity__c
                                                                                     WHERE Id IN :activityIdsToPopulateDateTime]);
            for (sked__Activity_Resource__c newRecord : newRecords) {
                sked__Activity__c skedActivity = mapActivity.get(newRecord.sked__Activity__c);
                if (newRecord.sked_Start1__c == NULL) {
                    newRecord.sked_Start1__c = skedActivity.sked__Start__c;
                }
                if (newRecord.sked_End__c == NULL) {
                    newRecord.sked_End__c = skedActivity.sked__End__c;
                }
            }
        }
    }
    
    private void populateResourceType(List<sked__Activity_Resource__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Activity_Resource__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Resource_Type__c, sked_Asset_Type__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        for (sked__Activity_Resource__c newRecord : newRecords) {
         	sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
            newRecord.sked_Resource_Type__c = skedResource.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON 
                								? skedConstants.RESOURCE_TYPE_PERSON : skedResource.sked_Asset_Type__c;
        }
    }
    
    private void removeExceptionLogs(Map<Id, sked__Activity_Resource__c> oldMap) {
        Set<Id> activityIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Activity_Resource__c oldData : oldMap.values()) {
            activityIds.add(oldData.sked__Activity__c);
            resourceIds.add(oldData.sked__Resource__c);
        }
        
        List<skedHC__Exception__c> exceptions = [SELECT Id, skedHC__Status__c 
                                                 FROM skedHC__Exception__c 
                                                 WHERE skedHC__Resource__c IN :resourceIds 
                                                 AND skedHC__Activity__c IN :activityIds];
        for (skedHC__Exception__c item : exceptions) {
            item.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
        }
        update exceptions;
    }

    /**************************************** RESOURCE HOURS RECORD ********************************************/
    private void syncToResourceHoursRecord(List<sked__Activity_Resource__c> newRecords) {
        Map<string, activityResourceModel> mapUniqueKey_ActivityResources = buildMapKey_ActivityResourceModels(newRecords);
        
        List<sked_Resource_Hours_Record__c> resourceHoursRecords = [SELECT Id, sked_End_Date__c, sked_Resource__c, sked_Start_Date__c, sked_Unique_Key__c
                                                                    FROM sked_Resource_Hours_Record__c
                                                                    WHERE sked_Unique_Key__c IN :mapUniqueKey_ActivityResources.keySet()
                                                                    ORDER BY sked_Unique_Key__c ASC];
        for (activityResourceModel model : mapUniqueKey_ActivityResources.values()) {
            model.hasKey = FALSE;
            for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {
                if (model.key.equalsIgnoreCase(resourceHoursRecord.sked_Unique_Key__c)) {
                    for (sked__Activity_Resource__c activityResource : model.activityResources) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = resourceHoursRecord.Id, 
                            sked_Activity_Resource__c = activityResource.Id,
                            sked_Duration__c = activityResource.sked_Duration__c
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
        for (activityResourceModel model : mapUniqueKey_ActivityResources.values()) {
            if (!model.hasKey) {
                newResourceHoursRecords.add(model.resourceHoursRecord);
            }
        }
        insert newResourceHoursRecords;

        List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        for (activityResourceModel model : mapUniqueKey_ActivityResources.values()) {
            if (!model.hasKey) {
                for (sked__Activity_Resource__c activityResource : model.activityResources) {
                    sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                        sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                        sked_Activity_Resource__c = activityResource.Id,
                        sked_Duration__c = activityResource.sked_Duration__c
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
    
    private void syncToResourceHoursRecord(List<sked__Activity_Resource__c> newRecords, Map<Id, sked__Activity_Resource__c> oldMap) {
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);

        Map<string, activityResourceModel> mapUniqueKey_ActivityResources = new Map<string, activityResourceModel>();
        Map<Id, sked__Activity_Resource__c> mapActivityResourceNeedToSync = new Map<Id, sked__Activity_Resource__c>();
        List<sked__Activity_Resource__c> activityResourcesNeedToDeleteResourceHoursRecordDetail = new List<sked__Activity_Resource__c>();
        for (sked__Activity_Resource__c newRecord : newRecords) {
            sked__Activity_Resource__c oldRecord = oldMap.get(newRecord.Id);
            if (oldRecord.sked_Start1__c != newRecord.sked_Start1__c || oldRecord.sked_End__c != newRecord.sked_End__c) {
                string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                Date oldEventDate = skedDateTimeUtils.getDate(oldRecord.sked_Start1__c, oldRecord.sked_Timezone__c);
                Date newEventDate = skedDateTimeUtils.getDate(newRecord.sked_Start1__c, newRecord.sked_Timezone__c);
                Date oldStartOfWeek = skedDateTimeUtils.findWeekStartDate(oldEventDate, workWeekday);
                Date newStartOfWeek = skedDateTimeUtils.findWeekStartDate(newEventDate, workWeekday);
                if (oldStartOfWeek != newStartOfWeek) {
                    activityResourcesNeedToDeleteResourceHoursRecordDetail.add(newRecord);
                    
                    Date startOfWeek = newStartOfWeek;
                    Date endOfWeek = startOfWeek.addDays(6);
                    string key = skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
                    
                    if (mapUniqueKey_ActivityResources.containsKey(key)) {
                        activityResourceModel model = mapUniqueKey_ActivityResources.get(key);
                        model.activityResources.add(newRecord);
                    }
                    else {
                        activityResourceModel model = new activityResourceModel();
                        model.resourceId = newRecord.sked__Resource__c;
                        model.startDate = startOfWeek;
                        model.endDate = endOfWeek;
                        model.key = key;
                        model.activityResources = new List<sked__Activity_Resource__c>();
                        model.activityResources.add(newRecord);
                        mapUniqueKey_ActivityResources.put(model.key, model);
                    }
                }
                else {
                    mapActivityResourceNeedToSync.put(newRecord.Id,  newRecord);
                }
            }
        }

        if (!mapActivityResourceNeedToSync.isEmpty()) {
            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = [SELECT Id, sked_Duration__c, sked_Activity_Resource__c
                                                                                    FROM sked_Resource_Hours_Record_Detail__c
                                                                                    WHERE sked_Activity_Resource__c IN :mapActivityResourceNeedToSync.keySet()];
            for (sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail : resourceHoursRecordDetails) {
                sked__Activity_Resource__c activityResource = mapActivityResourceNeedToSync.get(resourceHoursRecordDetail.sked_Activity_Resource__c);
                resourceHoursRecordDetail.sked_Duration__c = activityResource.sked_Duration__c;
            }
            update resourceHoursRecordDetails;
        }
        
        if (!activityResourcesNeedToDeleteResourceHoursRecordDetail.isEmpty()) {
            delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Activity_Resource__c IN :activityResourcesNeedToDeleteResourceHoursRecordDetail];
            
            List<sked_Resource_Hours_Record__c> existingResourceHoursRecords = [SELECT Id, sked_Unique_Key__c
                                                                                FROM sked_Resource_Hours_Record__c
                                                                                WHERE sked_Unique_Key__c IN :mapUniqueKey_ActivityResources.keySet()];
            for (activityResourceModel model : mapUniqueKey_ActivityResources.values()) {
                model.hasKey = FALSE;
                for (sked_Resource_Hours_Record__c existingResourceHoursRecord : existingResourceHoursRecords) {
                    if (model.key == existingResourceHoursRecord.sked_Unique_Key__c) {
                        for (sked__Activity_Resource__c activityResource : model.activityResources) {
                            sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                                sked_Resource_Hours_Record__c = existingResourceHoursRecord.Id, 
                                sked_Activity_Resource__c = activityResource.Id,
                                sked_Duration__c = activityResource.sked_Duration__c
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
            for (activityResourceModel model : mapUniqueKey_ActivityResources.values()) {
                if (!model.hasKey) {
                    newResourceHoursRecords.add(model.resourceHoursRecord);
                }
            }
            insert newResourceHoursRecords;

            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
            for (activityResourceModel model : mapUniqueKey_ActivityResources.values()) {
                if (!model.hasKey) {
                    for (sked__Activity_Resource__c activityResource : model.activityResources) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                            sked_Activity_Resource__c = activityResource.Id,
                            sked_Duration__c = activityResource.sked_Duration__c
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

    private void removeResourceHoursRecord(List<sked__Activity_Resource__c> newRecords) {
        delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Activity_Resource__c IN :newRecords];
    }

    private Map<string, activityResourceModel> buildMapKey_ActivityResourceModels(List<sked__Activity_Resource__c> newRecords) {
        Map<string, activityResourceModel> mapUniqueKey_ActivityResources = new Map<string, activityResourceModel>();
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);

        for (sked__Activity_Resource__c newRecord : newRecords) {
            string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
            Date eventDate = skedDateTimeUtils.getDate(newRecord.sked_Start1__c, newRecord.sked_Timezone__c);
            Date startOfWeek = skedDateTimeUtils.findWeekStartDate(eventDate, workWeekday);
            Date endOfWeek = startOfWeek.addDays(6);
            string key = skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
            if (mapUniqueKey_ActivityResources.containsKey(key)) {
                activityResourceModel model = mapUniqueKey_ActivityResources.get(key);
                model.activityResources.add(newRecord);
            }
            else {
                activityResourceModel model = new activityResourceModel();
                model.resourceId = newRecord.sked__Resource__c;
                model.startDate = startOfWeek;
                model.endDate = endOfWeek;
                model.key = key;
                model.activityResources = new List<sked__Activity_Resource__c>();
                model.activityResources.add(newRecord);
                mapUniqueKey_ActivityResources.put(model.key, model);
            }
        }
        return mapUniqueKey_ActivityResources;
    }

    private static Map<Id, sked__Resource__c> getResourceMapFromActivityResources(List<sked__Activity_Resource__c> activityResources) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Activity_Resource__c activityResource : activityResources) {
            resourceIds.add(activityResource.sked__Resource__c);
        }

        return new Map<Id, sked__Resource__c>([
            SELECT Id, Name, sked_Daily_Time_Off_Hours__c, sked_Employee_ID__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
    }
    
    private Map<Id, string> getMapRecord_WorkWeekday(List<sked__Activity_Resource__c> newRecords) {
        Map<Id, string> mapRecord_WorkWeekday = new Map<Id, string>();
        List<sked__Activity_Resource__c> activityResources = [SELECT Id, sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c
                                                              FROM sked__Activity_Resource__c
                                                              WHERE Id IN :newRecords];
        for (sked__Activity_Resource__c activityResource : activityResources) {
            string workWeekday = 'Sunday';
            if (string.isNotBlank(activityResource.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c)) {
                workWeekday = activityResource.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            }
            mapRecord_WorkWeekday.put(activityResource.Id, workWeekday);
        }

        return mapRecord_WorkWeekday;
    }

    private void createAvailabilityForOnCallResources(List<sked__Activity_Resource__c> newRecords) {
        List<sked__Availability__c> availabilityRecords = new List<sked__Availability__c>();
        Set<Id> activityIds = new Set<Id>();
        for (sked__Activity_Resource__c activityResource : newRecords) {
            activityIds.add(activityResource.sked__Activity__c);
        }

        Map<Id, sked__Activity__c> activityById = new Map<Id, sked__Activity__c>([
            SELECT Id, sked__Type__c, sked__Start__c, sked__End__c
            FROM sked__Activity__c
            WHERE Id IN :activityIds
            AND sked__Type__c = :skedConstants.AVAILABILITY_TYPE_ON_CALL
        ]);

        for (sked__Activity_Resource__c activityResource : newRecords) {
            sked__Activity__c activity = activityById.get(activityResource.sked__Activity__c);
            if (activity != null && activity.sked__Type__c == skedConstants.AVAILABILITY_TYPE_ON_CALL) {
                availabilityRecords.add(new sked__Availability__c(
                    sked__Resource__c = activityResource.sked__Resource__c,
                    sked__Type__c = skedConstants.AVAILABILITY_TYPE_ON_CALL,
                    sked__Is_Available__c = TRUE,
                    sked__Start__c = activityResource.sked_Start1__c,
                    sked__Finish__c = activityResource.sked_End__c,
                    sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED
                ));
            }
        }

        if (!availabilityRecords.isEmpty()) {
            insert availabilityRecords;
        }
    }

    private void syncOnCallAvailabilities(List<sked__Activity_Resource__c> newRecords, Map<Id, sked__Activity_Resource__c> oldMap) {
        List<sked__Activity_Resource__c> updatedActivityResources = new List<sked__Activity_Resource__c>();
        Map<Id, sked__Activity_Resource__c> newActivityResourceById = new Map<Id, sked__Activity_Resource__c>();
        for (sked__Activity_Resource__c activityResource : newRecords) {
            newActivityResourceById.put(activityResource.Id, activityResource);
            sked__Activity_Resource__c oldRecord = oldMap.get(activityResource.Id);
            if (activityResource.sked_Start1__c != oldRecord.sked_Start1__c 
                || activityResource.sked_End__c != oldRecord.sked_End__c
                || activityResource.sked_Start_Date__c != oldRecord.sked_Start_Date__c
                || activityResource.sked_End_Date__c != oldRecord.sked_End_Date__c) {
                    updatedActivityResources.add(oldRecord);
            }
        }

        if (!updatedActivityResources.isEmpty()) {
            List<sked__Availability__c> availabilities = skedActivityResourceUtils.getAvailabilityRecordsForOnCalls(updatedActivityResources);
            if (availabilities != null && !availabilities.isEmpty()) {
                for (sked__Availability__c availability : availabilities) {
                    for (sked__Activity_Resource__c activityResource : updatedActivityResources) {
                        if (availability.sked__Resource__c == activityResource.sked__Resource__c
                            && availability.sked__Start__c == activityResource.sked_Start1__c
                            && availability.sked__Finish__c == activityResource.sked_End__c) {
                                sked__Activity_Resource__c newActivityResource = newActivityResourceById.get(activityResource.Id);
                                availability.sked__Start__c = newActivityResource.sked_Start1__c;
                                availability.sked__Finish__c = newActivityResource.sked_End__c;
                        }
                    }
                }
                update availabilities;
            }
        }
    }

    private static void deleteAvailabilityForOnCallResources(Set<Id> recordIds) {
        List<sked__Activity_Resource__c> activityResources = [
            SELECT Id, sked__Resource__c, sked_Start1__c, sked_End__c, sked__Activity__r.sked__Type__c
            FROM sked__Activity_Resource__c
            WHERE Id IN :recordIds
            AND sked__Activity__r.sked__Type__c = :skedConstants.AVAILABILITY_TYPE_ON_CALL
        ];

        if (activityResources != null && !activityResources.isEmpty()) {
            delete skedActivityResourceUtils.GetAvailabilityRecordsForOnCalls(activityResources);
        }
    }

    /*********************************************************** Nested classes ***********************************************************/
    public class activityResourceModel {
        public Boolean hasKey;
        public string key;
        public string resourceId;
        public Date startDate;
        public Date endDate;
        public List<sked__Activity_Resource__c> activityResources;
        public List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails;
        public sked_Resource_Hours_Record__c resourceHoursRecord;

        public activityResourceModel() {
            activityResources = new List<sked__Activity_Resource__c>();
            resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        }
    }

}