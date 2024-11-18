global virtual class skedBaseController {

    @remoteAction
    global static skedRemoteResultModel search(searchRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            skedMappingConfigContainer.mappingConfigModel mappingConfig = skedMappingConfigContainer.instance.getMappingConfig(request.objectType);
            skedDataService service = new skedUntypedService(mappingConfig.sObjectName);
            skedDataService.queryModelBase query = new skedDataService.queryModelBase();

            skedQueryBuilder queryBuilder = query.getQueryBuilder(mappingConfig.sObjectName);
            if (!string.isBlank(request.queryText)) {
                string queryTextCondition = 'Name LIKE \'%{0}%\'';
                queryTextCondition = queryTextCondition.replace('{0}', request.queryText);
                queryBuilder.addCondition(queryTextCondition);
            }
            if (request.criteria != NULL && !request.criteria.isEmpty()) {
                Map<string, skedMappingConfigContainer.fieldConfigModel> map_domainField_fieldConfig = new Map<string, skedMappingConfigContainer.fieldConfigModel>();
                for (skedMappingConfigContainer.fieldConfigModel fieldConfig : mappingConfig.fieldConfigs) {
                    map_domainField_fieldConfig.put(fieldConfig.domainFieldName, fieldConfig);
                }
                for (string domainField : request.criteria.keySet()) {
                    string value = string.valueOf(request.criteria.get(domainField));
                    skedMappingConfigContainer.fieldConfigModel fieldConfig = map_domainField_fieldConfig.get(domainField);
                    string condition = fieldConfig.sObjectFieldPath + ' = {0}';
                    queryBuilder.addCondition(condition, value);
                }
            }
            if (!string.isBlank(request.subQueryIndicator)) {
                skedQueryBuilder subQuery = query.getQueryBuilder(request.subQueryIndicator);
            }
            
            //TODO: need to handle index field on Mapping Config
            queryBuilder.limitRecords = 100;
            List<skedModels.modelBase> searchResults = service.getList(query);
            result.data = searchResults;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    public static Map<string, object> getConfigData(List<string> keys) {
        Map<string, object> result = new Map<string, object>();
        if (keys != NULL && !keys.isEmpty()) {
            skedCommonService commonService = (skedCommonService)skedServiceFactory.instance.resolve('Common');
            if (keys.contains('activityTypes')) {
                result.put('activityTypes', skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c'));
            }
            if (keys.contains('activitySubTypes')) {
                result.put('activitySubTypes', skedUtils.getPickListValues('sked__Activity__c', 'sked_Subtype__c'));
            }
            if (keys.contains('availabilityDeclineReasons')) {
                result.put('availabilityDeclineReasons', skedUtils.getPickListValues('sked__Availability__c', 'sked_Decline_Reason__c'));
            }
            if (keys.contains('availabilityStatuses')) {
                result.put('availabilityStatuses', skedUtils.getPickListValues('sked__Availability__c', 'sked_Custom_Status__c'));
            }
            if (keys.contains('availabilityTypes')) {
                result.put('availabilityTypes', skedUtils.getPickListValues('sked__Availability__c', 'sked__Type__c'));
            }
            if (keys.contains('biomedCollectionOps')) {
                result.put('biomedCollectionOps', commonService.getAllBiomedCollectionOp());
            }
            if (keys.contains('callOutReasons')) {
                result.put('callOutReasons', skedUtils.getPickListValues('sked__Job_Allocation__c', 'sked_Call_Out_Reason_Code__c'));
            }
            if (keys.contains('customAvailabilityTypes')) {
                result.put('customAvailabilityTypes', skedUtils.getPickListValues('sked_Custom_Availability__c', 'sked_Type__c'));
            }
            if (keys.contains('driveTypes')) {
                result.put('driveTypes', skedUtils.getPickListValues('sked_Drive__c', 'sked_Type_of_Drive__c'));
            }
            if (keys.contains('jobCancellationReasons')) {
                result.put('jobCancellationReasons', skedUtils.getPickListValues('sked__Job__c', 'sked_Cancellation_Reason__c'));
            }
            if (keys.contains('jobTypes')) {
                result.put('jobTypes', skedUtils.getPickListValues('sked__Job__c', 'sked__Type__c'));
            }
            if (keys.contains('jobStatuses')) {
                result.put('jobStatuses', skedUtils.getPickListValues('sked__Job__c', 'sked__Job_Status__c'));
            }
            if (keys.contains('jobStatusSettings')) {
               result.put('jobStatusSettings', skedUtils.getJobStatusSettings());
            }
            if (keys.contains('holidays')) {
                result.put('holidays', commonService.getAllHolidays());
            }
            if (keys.contains('locationAvailabilityTypes')) {
                result.put('locationAvailabilityTypes', skedUtils.getPickListValues('sked_Location_Availability__c', 'sked_Type__c'));
            }
            if (keys.contains('locationTypes')) {
                result.put('locationTypes', skedUtils.getPickListValues('sked__Location__c', 'sked__Type__c'));
            }
            if (keys.contains('profiles')) {
                result.put('profiles', commonService.getAllProfiles());
            }
            if (keys.contains('regions')) {
                result.put('regions', commonService.getAllRegions());
            }
            if (keys.contains('resourceCategories')) {
                result.put('resourceCategories', skedUtils.getPickListValues('sked__Resource__c', 'sked__Category__c'));
            }
            if (keys.contains('resourceEmploymentTypes')) {
                result.put('resourceEmploymentTypes', skedUtils.getPickListValues('sked__Resource__c', 'sked__Employment_Type__c'));
            }
            if (keys.contains('resourceTypes')) {
                result.put('resourceTypes', skedUtils.getPickListValues('sked__Resource__c', 'sked__Resource_Type__c'));
            }
            if (keys.contains('roles')) {
                result.put('roles', skedUtils.getPickListValues('sked__Resource__c', 'sked_Roles__c'));
            }
            if (keys.contains('staffingBudgetRoles')) {
                result.put('staffingBudgetRoles', skedUtils.getPickListValues('sked_Staffing_Budget__c', 'sked_Roles__c'));
            }
            if (keys.contains('staffingBudgetRequestTypes')) {
                result.put('staffingBudgetRequestTypes', skedUtils.getPickListValues('sked_Staffing_Budget__c', 'sked_Request_Type__c'));
            }
            if (keys.contains('skeduloPermissionSets')) {
                result.put('skeduloPermissionSets', commonService.getAllSkeduloPermissionSets());
            }
            if (keys.contains('skeduloUserTypes')) {
                result.put('skeduloUserTypes', skedUtils.getPickListValues('User', 'sked__skeduloUserType__c'));
            }
            if (keys.contains('tags')) {
                result.put('tags', commonService.getAllTags());
            }
            if (keys.contains('territories')) {
                result.put('territories', commonService.getAllTerritories());
            }
            if (keys.contains('timezones')) {
                result.put('timezones', commonService.getAllTimezones());
            }
        }
        return result;
    }

    public static skedDataService.saveResult saveEvent(saveRequestModel request) {
        skedEventService service = (skedEventService)skedServiceFactory.instance.resolve(request.sObjectType);
        string timezoneSidId = skedSetting.instance.App.timezoneSidId;

        request.model.objectType = request.objectType;
        request.model.updateStartFinish(timezoneSidId);

        if (request.recurringOptions != NULL) {
            skedRecurringFactory recurringFactory = new skedRecurringFactory();
            if (string.isBlank(request.recurringOptions.editAction)) {
                skedModels.recurringSchedule recurringSchedule = recurringFactory.process(request.model, request.recurringOptions);
                return service.saveRecurringSchedule(recurringSchedule);
            }
            else {
                List<skedModels.event> editingEvents = recurringFactory.editRecurring(request.model, request.recurringOptions);
                service.applyRelationshipRecurringSchedule(request.model, editingEvents);
                if (!editingEvents.isEmpty()) {
                    return service.saveRecords(editingEvents);
                }
                return new skedDataService.saveResult();
            }
        }
        else {
            return service.saveRecord(request.model);
        }
    }

    public static skedDataService.saveResult deleteEvent(saveRequestModel request) {
        string timezoneSidId = skedSetting.instance.App.timezoneSidId;
        request.model.updateStartFinish(timezoneSidId);

        Id eventRecordId = (Id)request.model.Id;
        string eventRecordObjApiName = eventRecordId.getSobjectType().getDescribe().getName();
        string className = eventRecordObjApiName.removeEnd(skedMappingConfigContainer.CUSTOM_FIELDS_EXTENSION);
        className = className.startsWith('sked_') ? className.remove('sked_') : className;
        className = className.remove('_');
        skedEventService service = (skedEventService)skedServiceFactory.instance.resolve(className);

        if (request.recurringOptions != NULL && !string.isBlank(request.model.scheduleId)) {
            skedRecurringFactory recurringFactory = new skedRecurringFactory();
            request.model.objectType = className;
            List<skedModels.event> deletingEvents = recurringFactory.getRecurringRecords(request.model, request.recurringOptions, request.sObjectType);
            return service.deleteRecords(deletingEvents);
        }
        else {
            return service.deleteRecord(request.model);
        }
    }

    /*********************************************************** Nested classes ***********************************************************/
    global virtual class getDataRequestModel extends skedRemoteRequestModel {
        public string orderBy;
        public integer orderDirection;
        public integer pageNo;
        public integer pageSize;
        public string queryText;
        public List<string> searchColumns;
    }
    
    global virtual class recurringOption extends skedRecurringFactory.recurringOption {
        //used to receive data from FE
        public List<string> selectedDates;
        
    }
    
    global virtual class saveRequestModel extends skedRemoteRequestModel {
        public string sObjectType;
        public string objectType;
        public skedModels.event model;
        public recurringOption recurringOptions;
        public List<skedModels.event> allEvents;
    }

    global virtual class searchRequestModel extends skedRemoteRequestModel {
        public string objectType;
        public string queryText;
        public Map<string, object> criteria;
        public string subQueryIndicator;
    }

}