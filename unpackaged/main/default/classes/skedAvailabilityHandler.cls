public class skedAvailabilityHandler extends skedTriggerHub implements Callable {
    
    private List<unavailabilityWrapper> mUnavailabilityWrappers;
    protected List<unavailabilityWrapper> unavailabilityWrappers {
        get {
            if (mUnavailabilityWrappers == NULL) {
                mUnavailabilityWrappers = new List<unavailabilityWrapper>();
                List<sked__Availability__c> newRecords = (List<sked__Availability__c>)this.context.newRecords;
                List<sked__Availability__c> unavailabilityRecords = new List<sked__Availability__c>();
                Set<Id> resourceIds = new Set<Id>();
                for (sked__Availability__c newRecord : newRecords) {
                    if (newRecord.sked__Is_Available__c == FALSE) {
                        unavailabilityRecords.add(newRecord);
                        resourceIds.add(newRecord.sked__Resource__c);
                    }
                }
                if (!unavailabilityRecords.isEmpty()) {
                    Set<Date> availabilityDates = new Set<Date>();
                    
                    Map<Id, sked__Resource__c> mapResources = new Map<Id, sked__Resource__c>([SELECT Id, sked__Primary_Region__c, 
                                                                                              sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                                                                                              sked__Primary_Region__r.sked__Timezone__c,
                                                                                              (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Tag__r.sked_Priority__c
                                                                                               FROM sked__ResourceTags__r
                                                                                               WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                                                                                               AND sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE
                                                                                               ORDER BY sked__Tag__r.sked_Priority__c ASC NULLS LAST)
                                                                                              FROM sked__Resource__c
                                                                                              WHERE Id IN :resourceIds]);
                    for (sked__Availability__c unavailability : unavailabilityRecords) {
                        sked__Resource__c skedResource = mapResources.get(unavailability.sked__Resource__c);
                        if (skedResource.sked__ResourceTags__r != NULL && !skedResource.sked__ResourceTags__r.isEmpty()) {
                            unavailabilityWrapper wrapper = new unavailabilityWrapper();
                            wrapper.unavailability = unavailability;
                            wrapper.biomedCollectionOpId = skedResource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
                            wrapper.role = skedResource.sked__ResourceTags__r.get(0).sked__Tag__r.Name;
                            wrapper.timezoneSidId = skedResource.sked__Primary_Region__r.sked__Timezone__c;
                            wrapper.unavailabilityDate = skedDateTimeUtils.getDate(unavailability.sked__Start__c, wrapper.timezoneSidId);
                            wrapper.key = wrapper.biomedCollectionOpId + ':' + unavailability.sked__Start__c.format(skedDateTimeUtils.DATE_ISO_FORMAT, wrapper.timezoneSidId);
                            wrapper.resource = skedResource;
                            mUnavailabilityWrappers.add(wrapper);
                        }
                    }
                }
            }
            return mUnavailabilityWrappers;
        }
    }
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        populateData(this.context.newRecords, null);
        handleAutoApprovals(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
        populateResourceType(this.context.newRecords);
    }
    
    public override void onAfterInsert() {
        populateStaffingBudgetAvailabilities(this.context.newRecords);
        captureExceptionLogs(this.context.newRecords);
        syncToResourceHoursRecord(this.context.newRecords);
        if (!skedSetting.instance.Admin.migrationMode) {
            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    skedAvailabilityHandler.class.getName(),
                    'doWorkdaySync',
                    getApprovedRecordIds(this.context.newRecords)   
                );
            }
        }
    }
    
    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        populateData(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
        }
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            captureExceptionLogs(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
            syncToResourceHoursRecord(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
            syncToStaffingBudgetAvailabilities(this.context.newRecords);
            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    skedAvailabilityHandler.class.getName(),
                    'doWorkdaySync',
                    getApprovedRecordIds(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap)
                );
            }
        }
    }

    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.oldRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        if (!skedSetting.instance.Admin.migrationMode) {
        	removeExceptionLogs((Map<Id, sked__Availability__c>)this.context.oldMap);
        	removeResourceHoursRecord(this.context.oldMap.values());
        }
    }

    /*********************************************************** Private methods ***********************************************************/
    private void captureExceptionLogs(List<sked__Availability__c> newRecords) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
		for (sked__Availability__c newRecord : newRecords) {
			if (newRecord.sked__Is_Available__c || newRecord.sked__Status__c != skedConstants.AVAILABILITY_STATUS_APPROVED) {
				continue;
			}
			skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
			unavailability.resourceId = newRecord.sked__Resource__c;
			unavailability.startTime = newRecord.sked__Start__c;
			unavailability.endTime = newRecord.sked__Finish__c;
			unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
            unavailability.exceptionText = newRecord.sked__Type__c;
            unavailability.relatedEventFieldApi = 'skedHC__Availability__c';
            unavailability.recordId = newRecord.Id;
			unavailabilityList.add(unavailability);
		}
		if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
			service.captureExceptionLogs(unavailabilityList);
		}
    }
    
    private void captureExceptionLogs(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> updatedRecords) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
        for (sked__Availability__c record : newRecords) {
            if (record.sked__Is_Available__c || record.sked__Status__c != skedConstants.AVAILABILITY_STATUS_APPROVED) {
                continue;
            }
            sked__Availability__c oldRecord = updatedRecords.get(record.Id);
            if (record.sked__Start__c != oldRecord.sked__Start__c || record.sked__Finish__c != oldRecord.sked__Finish__c) {
                skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
                unavailability.resourceId = record.sked__Resource__c;
                unavailability.startTime = record.sked__Start__c;
                unavailability.endTime = record.sked__Finish__c;
                unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
                unavailability.exceptionText = record.sked__Type__c;
                unavailability.relatedEventFieldApi = 'skedHC__Availability__c';
                unavailability.recordId = record.Id;
                unavailabilityList.add(unavailability);
            }
        }
        if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
            service.captureExceptionLogs(unavailabilityList);
        }
    }
    
    private void populateData(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Availability__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
        }

        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([
            SELECT Id, sked__Resource_Type__c, sked__Primary_Region__r.sked__Timezone__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);

        for (sked__Availability__c newRecord : newRecords) {
            Boolean isCancelled = false;
            if (oldMap != null && oldMap.containsKey(newRecord.Id)) {
                sked__Availability__c oldAvailability = oldMap.get(newRecord.Id);
                if (oldAvailability.sked_Custom_Status__c != newRecord.sked_Custom_Status__c && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_CANCELLED) {
                    isCancelled = true;
                }
            }

            sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
            newRecord.sked__Timezone__c = skedResource.sked__Primary_Region__r.sked__Timezone__c;
            if (!string.isBlank(newRecord.sked_Custom_Status__c)) {
                newRecord.sked__Status__c = newRecord.sked_Custom_Status__c;
                if (newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_WAITLIST) {
                    newRecord.sked__Status__c = skedConstants.AVAILABILITY_STATUS_PENDING;
                }
                else if (newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_CANCELLED) {
                    newRecord.sked__Status__c = skedConstants.AVAILABILITY_STATUS_DECLINED;
                }
                else if (newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_EXPIRED) {
                    newRecord.sked__Status__c = skedConstants.AVAILABILITY_STATUS_DECLINED;
                }
            }
            else {
                newRecord.sked_Custom_Status__c = newRecord.sked__Status__c;
            }
            
            if (!isCancelled && (skedResource.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_ASSET || newRecord.sked__Is_Available__c == TRUE)) {
                newRecord.sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                newRecord.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
            }

            newRecord.sked_Last_Modified_By__c = newRecord.sked_Approved_Via_Automation__c ?
                skedTriggerHub_Cache.getAutoProcessUserFromCache().Id : UserInfo.getUserId();
            newRecord.sked_Approved_Via_Automation__c = false;
        }
    }

    private void handleAutoApprovals(List<sked__Availability__c> availabilities) {
        for (sked__Availability__c availability : availabilities) {
            if (!availability.sked__Is_Available__c && availability.sked__Type__c != skedConstants.UNAVAILABILITY_TYPE_FLOATING_HOLIDAY && availability.sked__Type__c != skedConstants.UNAVAILABILITY_TYPE_PTO) {
                List<String> autoApprovePermissionSets = new List<String>{'sked_Global_Admin', 'sked_APS', 'sked_APS_Admin', 'sked_APS_Manager', 'sked_APS_Planner'};

                if (skedTriggerUtils.hasAnyPermissionSetAssignment(autoApprovePermissionSets)) {
                    availability.sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                    availability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                }
            }
        }
    }

    private void populateStaffingBudgetAvailabilities(List<sked__Availability__c> newRecords) {
        Set<string> unavailabilityTypesToPopulate = new Set<string>();
        unavailabilityTypesToPopulate.add('Floating Holiday');
        unavailabilityTypesToPopulate.add('PTO');
        
        List<sked__Availability__c> recordsToPopulate = new List<sked__Availability__c>();
        for (sked__Availability__c newRecord : newRecords) {
            if (newRecord.sked__Type__c != NULL && unavailabilityTypesToPopulate.contains(newRecord.sked__Type__c)) {
                recordsToPopulate.add(newRecord);
            }
        }
        
        if (!recordsToPopulate.isEmpty()) {
            List<sked_Staffing_Budget_Availability__c> staffingBudgetAvailabilities = new List<sked_Staffing_Budget_Availability__c>();
            if (!unavailabilityWrappers.isEmpty()) {
                Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>();
                Map<Id, Set<Date>> datesByResourceId = new Map<Id, Set<Date>>();
                for (unavailabilityWrapper wrapper : unavailabilityWrappers) {
                    resourceById.put(wrapper.resource.Id, wrapper.resource);
                    
                    Set<Date> datesForResource = datesByResourceId.get(wrapper.resource.Id);
                    if (datesForResource == null) {
                        datesForResource = new Set<Date>();
                    }
                    datesForResource.add(wrapper.unavailabilityDate);
                    datesByResourceId.put(wrapper.resource.Id, datesForResource);
                }
                
                Map<Date, List<skedStaffingBudgetWrapper>> staffingBudgetWrappersByDate = skedStaffingBudgetUtils.getSkedStaffingBudgetWrappersByDate(datesByResourceId, resourceById);
                for (unavailabilityWrapper wrapper : unavailabilityWrappers) {
                    Boolean hasMatchingStaffingBudgetSlot = false;
                    List<skedStaffingBudgetWrapper> staffingBudgetWrappersForDate = staffingBudgetWrappersByDate.get(wrapper.unavailabilityDate);
                    
                    if (staffingBudgetWrappersForDate == null) {
                        staffingBudgetWrappersForDate = new List<skedStaffingBudgetWrapper>();
                    }
                    
                    if (!staffingBudgetWrappersForDate.isEmpty()) {
                        for (skedStaffingBudgetWrapper staffingBudgetWrapper : staffingBudgetWrappersForDate) {
                            List<String> staffingBudgetRoles = staffingBudgetWrapper.staffingBudget.sked_Roles__c.split(';');
                            if (staffingBudgetWrapper.collectionOpId == wrapper.resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c) {
                                if (staffingBudgetRoles.contains(wrapper.role)) {
                                    hasMatchingStaffingBudgetSlot = true;
                                    staffingBudgetAvailabilities.add(new sked_Staffing_Budget_Availability__c(
                                        sked_Availability__c = wrapper.unavailability.Id,
                                        sked_Staffing_Budget__c = staffingBudgetWrapper.staffingBudget.Id,
                                        sked_Availability_Status__c = wrapper.unavailability.sked_Custom_Status__c
                                    ));
                                    staffingBudgetWrapper.approvedSlots++;
                                    
                                    if (wrapper.unavailability.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED && staffingBudgetWrapper.availableSlots < 0) {
                                        wrapper.unavailability.addError(skedConstants.AVAILABILITY_STAFFING_BUDGET_NO_CAPACITY);
                                    }
                                }
                            }
                        }
                    }

                    if (!hasMatchingStaffingBudgetSlot && !Test.isRunningTest()) {
                        wrapper.unavailability.addError(skedConstants.AVAILABILITY_STAFFING_BUDGET_NO_CAPACITY);
                    }
                }
                
                if (!staffingBudgetAvailabilities.isEmpty()) {
                    insert staffingBudgetAvailabilities;
                }
            }
        }
    }

    private void syncToStaffingBudgetAvailabilities(List<sked__Availability__c> newRecords) {
        Map<Id, sked__Availability__c> availabilityById = new Map<Id, sked__Availability__c>();
        for (sked__Availability__c availability : newRecords) {
            availabilityById.put(availability.Id, availability);
        }

        List<sked_Staffing_Budget_Availability__c> staffingBudgetAvailabilities = [
            SELECT Id, sked_Availability_Status__c, sked_Availability__c
            FROM sked_Staffing_Budget_Availability__c
            WHERE sked_Availability__c IN :availabilityById.keySet()
        ];

        if (!staffingBudgetAvailabilities.isEmpty()) {
            for (sked_Staffing_Budget_Availability__c sba : staffingBudgetAvailabilities) {
                sked__Availability__c relatedAvailability = availabilityById.get(sba.sked_Availability__c);
                sba.sked_Availability_Status__c = relatedAvailability.sked_Custom_Status__c;
            }
    
            update staffingBudgetAvailabilities;
        }
    }
    
    private void doDateTimeConversion(List<sked__Availability__c> newRecords) {
        for (sked__Availability__c newRecord : newRecords) {
        	skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Finish__c', 'sked_Finish_Date__c', 'sked_Finish_Time__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked__Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
        	skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Finish__c', 'sked_Finish_Date__c', 'sked_Finish_Time__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked__Timezone__c');
        }
    }
    
    private void onDeclined(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Map<Id, sked__Availability__c> mapDeclinedRecord = new Map<Id, sked__Availability__c>();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Status__c != oldData.sked__Status__c && newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_DECLINED) {
                mapDeclinedRecord.put(newRecord.Id, newRecord);
            }
        }
        if (!mapDeclinedRecord.isEmpty()) {
            removeExceptionLogs((Map<Id, sked__Availability__c>)this.context.oldMap);
        	removeResourceHoursRecord(mapDeclinedRecord.values());
        }
    }
    
    private void populateResourceType(List<sked__Availability__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Availability__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Resource_Type__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        for (sked__Availability__c newRecord : newRecords) {
         	sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
            newRecord.sked_Resource_Type__c = skedResource.sked__Resource_Type__c;
        }
    }
    
    private void removeExceptionLogs(Map<Id, sked__Availability__c> oldMap) {
        skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
        service.removeExceptionLogs(oldMap.keySet());
    }

    /**************************************** RESOURCE HOURS RECORD ********************************************/
    private void syncToResourceHoursRecord(List<sked__Availability__c> newRecords) {
        Map<string, availabilityModel> mapUniqueKey_Availabilities = buildMapKey_AvailabilityModels(newRecords);
        Map<Id, sked__Resource__c> resourcesById = getResourceMapFromAvailabilities(newRecords);

        if (!mapUniqueKey_Availabilities.isEmpty()) {
            List<sked_Resource_Hours_Record__c> resourceHoursRecords = [
                SELECT Id, sked_End_Date__c, sked_Resource__c, sked_Start_Date__c, sked_Unique_Key__c
                FROM sked_Resource_Hours_Record__c
                WHERE sked_Unique_Key__c IN :mapUniqueKey_Availabilities.keySet()
                ORDER BY sked_Unique_Key__c ASC
            ];

            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                model.hasKey = FALSE;
                sked__Resource__c availabilityResource = resourcesById.get(model.resourceId);
                for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {
                    if (model.key.equalsIgnoreCase(resourceHoursRecord.sked_Unique_Key__c)) {
                        for (sked__Availability__c availability : model.availabilities) {
                            sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                                sked_Resource_Hours_Record__c = resourceHoursRecord.Id, 
                                sked_Availability__c = availability.Id,
                                sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability)
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
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                if (!model.hasKey) {
                    newResourceHoursRecords.add(model.resourceHoursRecord);
                }
            }
            insert newResourceHoursRecords;
            
            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                sked__Resource__c availabilityResource = resourcesById.get(model.resourceId);
                if (!model.hasKey) {
                    for (sked__Availability__c availability : model.availabilities) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                            sked_Availability__c = availability.Id,
                            sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability)
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

    private void syncToResourceHoursRecord(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<Id> ignoreRecordIds = syncHoursAfterChangeStatus(newRecords, oldMap);
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);
        Map<Id, sked__Resource__c> resourceById = getResourceMapFromAvailabilities(newRecords);

        Map<string, availabilityModel> mapUniqueKey_Availabilities = new Map<string, availabilityModel>();
        Map<Id, sked__Availability__c> mapAvailabilityNeedToSync = new Map<Id, sked__Availability__c>();
        List<sked__Availability__c> availabilitiesNeedToDeleteResourceHoursRecordDetail = new List<sked__Availability__c>();
        for (sked__Availability__c newRecord : newRecords) {
            if (newRecord.sked__Is_Available__c == FALSE && !ignoreRecordIds.contains(newRecord.Id)) {
                sked__Availability__c oldRecord = oldMap.get(newRecord.Id);
                if ((newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED && newRecord.sked_Custom_Status__c != oldRecord.sked_Custom_Status__c)
                   || oldRecord.sked__Start__c != newRecord.sked__Start__c || oldRecord.sked__Finish__c != newRecord.sked__Finish__c) {
                    string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                    Date oldEventDate = skedDateTimeUtils.getDate(oldRecord.sked__Start__c, oldRecord.sked__Timezone__c);
                    Date newEventDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked__Timezone__c);
                    Date oldStartOfWeek = skedDateTimeUtils.findWeekStartDate(oldEventDate, workWeekday);
                    Date newStartOfWeek = skedDateTimeUtils.findWeekStartDate(newEventDate, workWeekday);
                    if (oldStartOfWeek != newStartOfWeek) {
                        availabilitiesNeedToDeleteResourceHoursRecordDetail.add(newRecord);

                        Date startOfWeek = newStartOfWeek;
                        Date endOfWeek = startOfWeek.addDays(6);
                        string key = skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
                        
                        if (mapUniqueKey_Availabilities.containsKey(key)) {
                            availabilityModel model = mapUniqueKey_Availabilities.get(key);
                            model.availabilities.add(newRecord);
                        }
                        else {
                            availabilityModel model = new availabilityModel();
                            model.resourceId = newRecord.sked__Resource__c;
                            model.startDate = startOfWeek;
                            model.endDate = endOfWeek;
                            model.key = key;
                            model.availabilities = new List<sked__Availability__c>();
                            model.availabilities.add(newRecord);
                            mapUniqueKey_Availabilities.put(model.key, model);
                        }
                    }
                    else {
                        mapAvailabilityNeedToSync.put(newRecord.Id,  newRecord);
                    }
                }
            }
        }

        if (!mapAvailabilityNeedToSync.isEmpty()) {
            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = [SELECT Id, sked_Duration__c, sked_Availability__c
                                                                                    FROM sked_Resource_Hours_Record_Detail__c
                                                                                    WHERE sked_Availability__c IN :mapAvailabilityNeedToSync.keySet()];
            for (sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail : resourceHoursRecordDetails) {
                sked__Availability__c availability = mapAvailabilityNeedToSync.get(resourceHoursRecordDetail.sked_Availability__c);
                sked__Resource__c availabilityResource = resourceById.get(availability.sked__Resource__c);
                resourceHoursRecordDetail.sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability);
            }
            update resourceHoursRecordDetails;
        }
        
        if (!availabilitiesNeedToDeleteResourceHoursRecordDetail.isEmpty()) {
            delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Availability__c IN :availabilitiesNeedToDeleteResourceHoursRecordDetail];
            
            List<sked_Resource_Hours_Record__c> existingResourceHoursRecords = [SELECT Id, sked_Unique_Key__c
                                                                                FROM sked_Resource_Hours_Record__c
                                                                                WHERE sked_Unique_Key__c IN :mapUniqueKey_Availabilities.keySet()];
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                model.hasKey = FALSE;
                sked__Resource__c availabilityResource = resourceById.get(model.resourceId);
                for (sked_Resource_Hours_Record__c existingResourceHoursRecord : existingResourceHoursRecords) {
                    if (model.key == existingResourceHoursRecord.sked_Unique_Key__c) {
                        for (sked__Availability__c availability : model.availabilities) {
                            sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                                sked_Resource_Hours_Record__c = existingResourceHoursRecord.Id, 
                                sked_Availability__c = availability.Id,
                                sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability)
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
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                if (!model.hasKey) {
                    newResourceHoursRecords.add(model.resourceHoursRecord);
                }
            }
            insert newResourceHoursRecords;

            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                sked__Resource__c availabilityResource = resourceById.get(model.resourceId);
                if (!model.hasKey) {
                    for (sked__Availability__c availability : model.availabilities) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                            sked_Availability__c = availability.Id,
                            sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability)
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

    private void removeResourceHoursRecord(List<sked__Availability__c> newRecords) {
        List<sked_Resource_Hours_Record_Detail__c> resourceHourDetailRecords = [SELECT Id 
                                                                                FROM sked_Resource_Hours_Record_Detail__c 
                                                                                WHERE sked_Availability__c IN :newRecords];
        if (!resourceHourDetailRecords.isEmpty()) {
            delete resourceHourDetailRecords;
        }
    }

    private Set<Id> syncHoursAfterChangeStatus(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<Id> ignoreRecordIds = new Set<Id>();

        Map<Id, sked__Availability__c> mapNeedToCreateRecords = new Map<Id, sked__Availability__c>();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldRecord = oldMap.get(newRecord.Id);
            if ((newRecord.sked__Is_Available__c == FALSE && oldRecord.sked__Is_Available__c != newRecord.sked__Is_Available__c && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED)
                || (newRecord.sked__Is_Available__c == FALSE && oldRecord.sked_Custom_Status__c != newRecord.sked_Custom_Status__c && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED)) {
                mapNeedToCreateRecords.put(newRecord.Id, newRecord);
                ignoreRecordIds.add(newRecord.Id);
            }
        }
        if (!mapNeedToCreateRecords.isEmpty()) {
            syncToResourceHoursRecord(mapNeedToCreateRecords.values());
        }

        Set<Id> needToDeleteRecords = new Set<Id>();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldRecord = oldMap.get(newRecord.Id);
            if ((newRecord.sked__Is_Available__c == TRUE && oldRecord.sked__Is_Available__c != newRecord.sked__Is_Available__c)
                || (oldRecord.sked_Custom_Status__c != newRecord.sked_Custom_Status__c && newRecord.sked_Custom_Status__c != skedConstants.AVAILABILITY_STATUS_APPROVED)) {
                needToDeleteRecords.add(newRecord.Id);
                ignoreRecordIds.add(newRecord.Id);
            }
        }
        if (!needToDeleteRecords.isEmpty()) {
            delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Availability__c IN :needToDeleteRecords];
        }

        return ignoreRecordIds;
    }

    private Map<string, availabilityModel> buildMapKey_AvailabilityModels(List<sked__Availability__c> newRecords) {
        Map<string, availabilityModel> mapUniqueKey_Availabilities = new Map<string, availabilityModel>();
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);

        for (sked__Availability__c newRecord : newRecords) {
            if (newRecord.sked__Type__c == skedConstants.UNAVAILABILITY_TYPE_UNAVAILABLE ||
                newRecord.sked__Type__c == skedConstants.AVAILABILITY_TYPE_CALL_OUT) continue;
                
            if (newRecord.sked__Is_Available__c == FALSE && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED) {
                string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                Date eventDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked__Timezone__c);
                Date startOfWeek = skedDateTimeUtils.findWeekStartDate(eventDate, workWeekday);
                Date endOfWeek = startOfWeek.addDays(6);
                string key = skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
                if (mapUniqueKey_Availabilities.containsKey(key)) {
                    availabilityModel model = mapUniqueKey_Availabilities.get(key);
                    model.availabilities.add(newRecord);
                }
                else {
                    availabilityModel model = new availabilityModel();
                    model.resourceId = newRecord.sked__Resource__c;
                    model.startDate = startOfWeek;
                    model.endDate = endOfWeek;
                    model.key = key;
                    model.availabilities = new List<sked__Availability__c>();
                    model.availabilities.add(newRecord);
                    mapUniqueKey_Availabilities.put(model.key, model);
                }
            }
        }
        return mapUniqueKey_Availabilities;
    }

    private Map<Id, string> getMapRecord_WorkWeekday(List<sked__Availability__c> newRecords) {
        Map<Id, string> mapRecord_WorkWeekday = new Map<Id, string>();
        List<sked__Availability__c> availabilities = [SELECT Id, sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c
                                                      FROM sked__Availability__c
                                                      WHERE Id IN :newRecords];
        for (sked__Availability__c availability : availabilities) {
            string workWeekday = 'Sunday';
            if (string.isNotBlank(availability.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c)) {
                workWeekday = availability.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            }
            mapRecord_WorkWeekday.put(availability.Id, workWeekday);
        }

        return mapRecord_WorkWeekday;
    }
    
    /*********************************************************** Utility ***********************************************************/
    private static Map<Id, sked__Resource__c> getResourceMapFromAvailabilities(List<sked__Availability__c> availabilities) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Availability__c availability : availabilities) {
            resourceIds.add(availability.sked__Resource__c);
        }

        return new Map<Id, sked__Resource__c>([
            SELECT Id, Name, sked_Daily_Time_Off_Hours__c, sked_Employee_ID__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
    }

    private static Decimal getResourceHoursRecordDuration(sked__Resource__c resource, sked__Availability__c availability) {
        Decimal duration = 0.00;
        if (!availability.sked__Is_Available__c && availability.sked_Is_All_Day__c) {
            duration = resource.sked_Daily_Time_Off_Hours__c * 60;
        } else {
            duration = availability.sked_Duration__c;
        }

        return duration;
    }

    /*********************************************************** Workday Sync ***********************************************************/
    private Set<Id> getApprovedRecordIds(List<sked__Availability__c> records) {
        Set<Id> approvedRecordIds = new Set<Id>();
        Set<string> unavailabilityTypesToSync = getUnavailabilityTypesToSync();
        
        for (sked__Availability__c record : records) {
            if (!unavailabilityTypesToSync.contains(record.sked__Type__c)) {
                if (record.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED) {
                    approvedRecordIds.add(record.Id);
                }
            }
        }

        return approvedRecordIds;
    }


    private Set<Id> getApprovedRecordIds(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldRecordsMap) {
        Set<Id> approvedRecordIds = new Set<Id>();
        Set<string> unavailabilityTypesToSync = getUnavailabilityTypesToSync();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldRecordsMap.get(newRecord.Id);
            if (!unavailabilityTypesToSync.contains(newRecord.sked__Type__c)) {
                if (oldData.sked_Custom_Status__c != newRecord.sked_Custom_Status__c && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED) {
                    approvedRecordIds.add(newRecord.Id);
                }
            }
        }

        return approvedRecordIds;
    }
    
    private Set<string> getUnavailabilityTypesToSync() {
        Set<string> unavailabilityTypesToSync = new Set<String>();
        unavailabilityTypesToSync.add('Floating Holiday');
        unavailabilityTypesToSync.add('PTO');
        unavailabilityTypesToSync.add('Sick');
        return unavailabilityTypesToSync;
    }

    private static void doWorkdaySync(Set<Id> recordIds) {
        if (!recordIds.isEmpty()) {
            List<sked__Availability__c> records = [
                SELECT Id, sked_Start_Date__c, sked_Finish_Date__c, sked__Notes__c,
                    sked__Resource__c, sked__Is_Available__c, sked_Is_All_Day__c, sked_Duration__c,
                    sked__Type__c
                FROM sked__Availability__c
                WHERE Id IN :recordIds
            ];

            Map<Id, sked__Resource__c> resourcesById = getResourceMapFromAvailabilities(records);
            for (sked__Availability__c record : records) {
                sked__Resource__c availabilityResource = resourcesById.get(record.sked__Resource__c);
                skedWorkdayApiManager.processTimeOffRequest ptoReq = new skedWorkdayApiManager.processTimeOffRequest();
                ptoReq.employeeId = resourcesById.get(record.sked__Resource__c).sked_Employee_ID__c;
                ptoReq.comment = record.sked__Notes__c;
                ptoReq.ptoDate = record.sked_Start_Date__c;
                ptoReq.hoursRequested = String.valueOf(getResourceHoursRecordDuration(availabilityResource, record));
                ptoReq.ptoEntryId = record.Id;
                ptoReq.ptoReason = getWorkdayPtoReason(record);
                
                if (!Test.isRunningTest()) {
                    skedWorkdayApiManager.processTimeOffResponse response = skedWorkdayApiManager.processTimeOffApproval(ptoReq);
                    
                    if (!response.isSuccess) {
                        record.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PENDING;
                        record.sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WD_SYNC_STATUS_FAILED;
                        record.sked_Workday_Sync_Message__c = response.faultString;
                    } else {
                        record.sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WD_SYNC_STATUS_SUCCESS;
                    }
                }
            }

            skedHubBase.BypassUpdateTriggers = true;
            update records;
            skedHubBase.BypassUpdateTriggers = false;
        }
    }

    private static String getWorkdayPtoReason(sked__Availability__c record) {
        String ptoReason = skedConstants.WD_PTO_UNPLANNED;

        if (record.sked__Type__c == skedConstants.UNAVAILABILITY_TYPE_FLOATING_HOLIDAY || 
            record.sked__Type__c == skedConstants.UNAVAILABILITY_TYPE_PTO
        ) {
            ptoReason = skedConstants.WD_PTO_PLANNED;
        }

        return ptoReason;
    }

    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'doWorkdaySync' {
                    doWorkdaySync((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));

                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedAvailabilityHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    private class unavailabilityWrapper {
        public sked__Availability__c unavailability {get;set;}
        public sked__Resource__c resource {get;set;}
        public string key {get;set;}
        public string role {get;set;}
        public string biomedCollectionOpId {get;set;}
        public Date unavailabilityDate {get;set;}
        public string timezoneSidId {get;set;}
    }
    
    public class availabilityModel {
        public Boolean hasKey;
        public string key;
        public string resourceId;
        public Date startDate;
        public Date endDate;
        public List<sked__Availability__c> availabilities;
        public List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails;
        public sked_Resource_Hours_Record__c resourceHoursRecord;

        public availabilityModel() {
            availabilities = new List<sked__Availability__c>();
            resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        }
    }

}