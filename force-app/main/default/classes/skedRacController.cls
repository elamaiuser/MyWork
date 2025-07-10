global virtual class skedRacController extends skedBaseController {

    @remoteAction
    global static skedRemoteResultModel initialize(skedRemoteRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            Map<string, object> mapConfigData = getConfigData(request.configKeys);
            System.debug(mapConfigData.get('biomedCollectionOps'));

            User loginUser = [SELECT Id, sked__SkeduloUserType__c, Profile.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()];
                
            if (mapConfigData.containsKey('availabilityTypes')) {
                List<string> availabilityTypes = (List<String>) mapConfigData.get('availabilityTypes');
                availabilityTypes.remove(availabilityTypes.indexOf(skedConstants.AVAILABILITY_TYPE_ON_CALL));
                if (loginUser.sked__SkeduloUserType__c != null && !loginUser.sked__SkeduloUserType__c.contains(skedConstants.USER_TYPE_ADMIN) && !loginUser.sked__SkeduloUserType__c.contains(skedConstants.USER_TYPE_SCHEDULER)) {     //HRP-14943
                    List<string> results = new List<string>();
                    for (string availabilityType : availabilityTypes) {
                        if (availabilityType != skedConstants.AVAILABILITY_TYPE_AVAILABILITY_TEMPLATE_OVERRIDE) {
                            results.add(availabilityType);
                        }
                    }
                    mapConfigData.put('availabilityTypes', results);
                }
            }
            
            Map<string, List<string>> mapResourceTypeCategories = 
                    skedPicklistFieldUtils.getMapDependentOptions(sked__Resource__c.sked__Resource_Type__c, sked__Resource__c.sked__Category__c);
            mapConfigData.put('mapResourceTypeCategories', mapResourceTypeCategories);
            
            Map<string, List<string>> mapResourceTypeAvailabilityTypes = 
                    skedPicklistFieldUtils.getMapDependentOptions(sked__Availability__c.sked_Resource_Type__c, sked__Availability__c.sked__Type__c);
            mapConfigData.put('mapResourceTypeAvailabilityTypes', mapResourceTypeAvailabilityTypes);
            
            Map<string, List<string>> mapActivityTypeSubtypes = 
                    skedPicklistFieldUtils.getMapDependentOptions(sked__Activity__c.sked__Type__c, sked__Activity__c.sked_Subtype__c);
            mapConfigData.put('mapActivityTypeSubtypes', mapActivityTypeSubtypes);

            Map<string, List<string>> mapCallOutTypeReason = 
                    skedPicklistFieldUtils.getMapDependentOptions(sked__Job_Allocation__c.sked_Call_Out_Type__c, sked__Job_Allocation__c.sked_Call_Out_Reason_Code__c);
            mapConfigData.put('mapCallOutTypeReason', mapCallOutTypeReason);
            
            mapConfigData.put('callOutTypes', skedUtils.getPickListValues('sked__Job_Allocation__c', 'sked_Call_Out_Type__c'));
            mapConfigData.put('consoleSettings', skedSetting.instance.RAC);
            mapConfigData.put('adminSettings', skedSetting.instance.Admin);
            mapConfigData.put('eventTypeSettings', skedSetting.instance.RAC.mapShiftTypeSetting.values());
            mapConfigData.put('userTimezoneSidId', UserInfo.getTimeZone().getID());
            mapConfigData.put('userProfileName', loginUser.Profile.Name);

            result.data = mapConfigData;

            //result.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getResourceData(getResourceRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedResourceService.queryModel query = new skedResourceService.queryModel();
            query.availabilityStatuses = request.availabilityStatuses;
            query.biomedCollectionOpIds = request.biomedCollectionOpIds;
            query.categories = request.resourceCategories;
            query.employmentTypes = request.resourceEmploymentTypes;
            query.endDate = request.endDate;
            query.jobAllocationStatuses = request.jobAllocationStatuses;
            query.orderBy = request.orderBy;
            query.orderAscending = request.orderDirection == 1 ? 'ASC' : 'DESC';
            query.pageNo = request.pageNo;
            query.pageSize = request.pageSize;
            query.queryText = request.queryText;
            if (!string.isBlank(request.resourceId)) {
                query.recordIds = new List<string>();
                query.recordIds.add(request.resourceId);
            }
            query.regionIds = request.regionIds;
            query.resourceTypes = request.resourceTypes;
            query.searchColumns = new List<string>();
            query.searchColumns.add('Name');
            query.startDate = request.startDate;
            query.subQueryIndicator = skedSObjectType.RESOURCE_RAC_DATA;
            query.tagIds = request.tagIds;
            query.matchAllSelectedTags = request.matchAllSelectedTags;
            query.tagExpiry = skedDateTimeUtils.getDateFromIsoString(request.startDate);
            query.patternIds = request.patternIds;
            query.activeTagsOnly = true;
            query.activityTypes = request.activityTypes;
            query.availabilityTypes = request.availabilityTypes;
            query.excludedAvailabilityTypes = new List<String>{skedConstants.AVAILABILITY_TYPE_ON_CALL};
            query.customAvailabilityStatuses = new List<String>{skedConstants.AVAILABILITY_STATUS_APPROVED};
            query.hasNoAssignment = request.hasNoAssignment;
            query.hasTemporaryRelocation = request.hasTemporaryRelocation;
            query.additionalFilterOnDate = request.additionalFilterOnDate;
            
            skedResourceService service = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
            skedDataService.paginationQueryModel paginationResult = service.doPaginationQuery(query);
            
            List<string> activityIds = new List<string>();
            List<sked__Resource__c> skedResources = (List<sked__Resource__c>)paginationResult.records;
            for (sked__Resource__c skedResource : skedResources) {
                if (skedResource.sked__Activity_Resources__r != NULL && !skedResource.sked__Activity_Resources__r.isEmpty()) {
                    for (sked__Activity_Resource__c skedActivityResource : skedResource.sked__Activity_Resources__r) {
                        activityIds.add(skedActivityResource.sked__Activity__c);
                    }
                }
            }
            
            List<sked__Activity__c> skedGroupActivities = new List<sked__Activity__c>();
            if (!activityIds.isEmpty()) {
                skedActivityService.queryModel groupActivityQuery = new skedActivityService.queryModel();
                groupActivityQuery.recordIds = activityIds;
                groupActivityQuery.subQueryIndicator = skedSObjectType.ACTIVITY_RESOURCE;
                skedActivityService activityService = (skedActivityService)skedServiceFactory.instance.resolve('sked__Activity__c');
                skedGroupActivities = (List<sked__Activity__c>)activityService.query(groupActivityQuery);
            }

            resourceDataModel data = new resourceDataModel();
            data.today = system.now().format(skedDateTimeUtils.DATE_ISO_FORMAT, UserInfo.getTimeZone().getID());
            data.resources = paginationResult.records;
            data.groupActivities = skedGroupActivities;
            if (skedSetting.instance.RAC.enableAvailabilityTemplate) {
                data.patterns = getAvailabilityPatterns(skedResources); 
            }

            List<sked_Custom_Availability__c> customAvailabilities = new List<sked_Custom_Availability__c>();
            for (sked__Resource__c resource : (List<sked__Resource__c>)paginationResult.records) {
                if (resource.sked_Custom_Availabilities__r != NULL && !resource.sked_Custom_Availabilities__r.isEmpty()) {
                    customAvailabilities.addAll(resource.sked_Custom_Availabilities__r);
                }
            }
            data.customAvailabilities = customAvailabilities;
            data.totalRecords = paginationResult.totalRecords;
            data.totalPages = (integer)Math.ceil(decimal.valueOf(data.totalRecords) / request.pageSize);
            
            skedModels.userFilter filter = getUserFilterByCategory(skedSetting.instance.RAC.filters, 'RAC');
            filter.jsonData = Json.serialize(request);
            
            skedDataService userFilterService = skedServiceFactory.instance.resolve('sked_User_Filter__c');
            skedDataService.saveResult saveResult = userFilterService.saveRecord(filter);
            
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getResources(getResourceRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedResourceService.queryModel query = new skedResourceService.queryModel();
            query.categories = request.resourceCategories;
            query.biomedCollectionOpIds = request.biomedCollectionOpIds;
            query.employmentTypes = request.resourceEmploymentTypes;
            query.jobAllocationStatuses = request.jobAllocationStatuses;
            query.orderBy = skedAutoMapper.instance.mapToSObjectFieldPath('resource', request.orderBy);
            query.orderAscending = request.orderDirection == 1 ? 'ASC' : 'DESC';
            query.pageNo = request.pageNo;
            query.pageSize = request.pageSize;
            query.queryText = request.queryText;
            query.regionIds = request.regionIds;
            query.resourceTypes = request.resourceTypes;
            query.searchColumns = new List<string>();
            query.searchColumns.add('Name');
            query.subQueryIndicator = skedSObjectType.RESOURCE_TAG | skedSObjectType.AVAILABILITY_PATTERN_RESOURCE;
            query.tagIds = request.tagIds;
            query.matchAllSelectedTags = request.matchAllSelectedTags;
            query.startDate = request.startDate;
            query.endDate = request.endDate;
            query.activeTagsOnly = true;

            skedResourceService service = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
            skedDataService.paginationListModel paginationResult = service.doPaginationList(query);

            resourceDataModel data = new resourceDataModel();
            data.resources = paginationResult.models;
            data.totalRecords = paginationResult.totalRecords;
            data.totalPages = (integer)Math.ceil(decimal.valueOf(data.totalRecords) / request.pageSize);
            
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getIndividualResourceData(getResourceRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = skedResourceUtils.getResourceTimezonesidId(request.resourceId);
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            resourceDataModel data = new resourceDataModel();

            Date startDate = skedDateTimeUtils.getDateFromIsoString(request.startDate);
            Date endDate = skedDateTimeUtils.getDateFromIsoString(request.endDate);
            Date tempDate = startDate;
            request.inputDates = new Set<Date>();
            while (tempDate <= endDate) {
                request.inputDates.add(tempDate);
                tempDate = tempDate.addDays(1);
            }

            skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
            List<string> recordIds = new List<string>();
            recordIds.add(request.resourceId);

            skedResourceService.queryModel query = new skedResourceService.queryModel();
            query.startDate = request.startDate;
            query.endDate = request.endDate;
            query.jobAllocationStatuses = request.jobAllocationStatuses;
            query.customAvailabilityStatuses = new List<String>{skedConstants.AVAILABILITY_STATUS_APPROVED};
            query.subQueryIndicator = skedSObjectType.RESOURCE_RAC_DATA;
            query.recordIds = recordIds;
            
            List<skedModels.resource> resources = (List<skedModels.resource>)resourceService.getList(query);
            skedModels.resource resource = resources.get(0);
            resource.availability = new List<skedModels.event>();
            resource.events = new List<skedModels.event>();
            
            if (resource.availabilities != NULL && !resource.availabilities.isEmpty()) {
                resource.availability.addAll(resource.availabilities);
                resource.availabilities = NULL;
            }
            if (resource.activities != NULL && !resource.activities.isEmpty()) {
                resource.events.addAll(resource.activities);
                resource.activities = NULL;
            }
            if (resource.jobAllocations != NULL && !resource.jobAllocations.isEmpty()) {
                for (skedModels.jobAllocation jobAllocation : resource.jobAllocations) {
                    resource.events.add(jobAllocation);
                }
                resource.jobAllocations = NULL;
            }
            
            List<sked__Activity_Resource__c> skedActivityResources = [SELECT Id, sked__Activity__c, sked_Start1__c, sked_End__c, sked_Timezone__c
                                                                      FROM sked__Activity_Resource__c
                                                                      WHERE sked__Resource__c IN :recordIds
                                                                      AND sked__Activity__r.sked_Start_Date__c <= :endDate
                                                                      AND sked__Activity__r.sked_End_Date__c >= :startDate];
            List<string> groupActivityIds = new List<string>();
            Map<Id, sked__Activity_Resource__c> map_activityId_activityResource = new Map<Id, sked__Activity_Resource__c>();
            for (sked__Activity_Resource__c skedActivityResource : skedActivityResources) {
                groupActivityIds.add(skedActivityResource.sked__Activity__c);
                map_activityId_activityResource.put(skedActivityResource.sked__Activity__c, skedActivityResource);
            }
            if (!groupActivityIds.isEmpty()) {
                skedActivityService activityService = (skedActivityService)skedServiceFactory.instance.resolve('sked__Activity__c');
                skedActivityService.queryModel groupActivityQuery = new skedActivityService.queryModel();
                groupActivityQuery.recordIds = groupActivityIds;
                List<skedModels.activity> groupActivities = (List<skedModels.activity>)activityService.getList(groupActivityQuery);
                
                //override activity dateTime by activityResource dateTime
                for (skedModels.activity groupActivity : groupActivities) {
                    sked__Activity_Resource__c skedActivityResource = map_activityId_activityResource.get(groupActivity.id);
                    if (skedActivityResource.sked_Start1__c != NULL) {
                        groupActivity.startDate = skedActivityResource.sked_Start1__c.format(skedDateTimeUtils.DATE_ISO_FORMAT, groupActivity.timezoneSidId);
                    	groupActivity.startTime = integer.valueOf(skedActivityResource.sked_Start1__c.format('Hmm', groupActivity.timezoneSidId));
                    }
                    if (skedActivityResource.sked_End__c != NULL) {
                        groupActivity.endDate = skedActivityResource.sked_End__c.format(skedDateTimeUtils.DATE_ISO_FORMAT, groupActivity.timezoneSidId);
                        groupActivity.endTime = integer.valueOf(skedActivityResource.sked_End__c.format('Hmm', groupActivity.timezoneSidId));
                    }
                }
                
                resource.events.addAll(groupActivities);
            }
            
            Datetime startTime = skedDateTimeUtils.newDateTimeInstance(query.startDate, 0, timezoneSidId);
            Datetime endTime = skedDateTimeUtils.newDateTimeInstance(query.endDate, 0, timezoneSidId);
            endTime = endTime.addDays(1);
            resourceService.populateNonWorkingEvents(resources, request.inputDates, startTime, endTime);
            List<skedModels.customAvailability> customAvailabilities = new List<skedModels.customAvailability>();
            for (skedModels.resource item : resources) {
                if (item.customAvailabilities != NULL && !item.customAvailabilities.isEmpty()) {
                    customAvailabilities.addAll(item.customAvailabilities);
                }
            }
            data.customAvailabilities = customAvailabilities;
            data.resources = resources;
            
            DateTime startDateTime = skedDateTimeUtils.newDateTimeInstance(startDate, 700, timezoneSidId);
            data.today = startDateTime.format(skedDateTimeUtils.DATE_ISO_FORMAT, timezoneSidId);
            data.timezone = startDateTime.format('z', timezoneSidId);

            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getEventDetails(getAvailabilityDetailsRequest request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedAvailabilityService.queryModel query = new skedAvailabilityService.queryModel();
            query.recordIds = new List<string>();
            query.recordIds.add(request.event.id);
            
            skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            List<skedModels.availability> models = (List<skedModels.availability>)service.getListAndFormatDateTimeByTimezone(query, 'sked__Timezone__c');
            
            availabilityDetailsModel data = new availabilityDetailsModel();
            skedModels.availability event = models.get(0);
            event.timezone = event.start.format('z', event.timezoneSidId);
            data.event = event;
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getGroupActivities(getGroupActivitiesRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            //Get all activities through normal query
            skedActivityService.queryModel query = new skedActivityService.queryModel();
            query.activityTypes = request.activityTypes;
            query.biomedCollectionOpIds = request.biomedCollectionOpIds;
            query.endDate = request.endDate;
            query.isGroupActivity = true;
            query.orderBy = skedAutoMapper.instance.mapToSObjectFieldPath('activity', request.orderBy);
            query.orderAscending = request.orderDirection == 1 ? 'ASC' : 'DESC';
            query.queryText = request.queryText;
            query.regionIds = request.regionIds;
            query.startDate = request.startDate;
            query.subTypes = request.subTypes;
            query.subQueryIndicator = skedSObjectType.ACTIVITY_RESOURCE | skedSObjectType.ACTIVITY_COLLECTION_OPERATION;
            
            skedActivityService service = (skedActivityService)skedServiceFactory.instance.resolve('sked__Activity__c');
            List<sObject> activityRecords = service.query(query);
            List<String> activityRecordIds = new List<String>();

            for(sked__Activity__c activity : (List<sked__Activity__c>)activityRecords) {
                Boolean hasCorrectTerritoryKey = FALSE;
                if(activity.sked_Territory_Key__c != NULL && request.territoryKeys.contains(activity.sked_Territory_Key__c)) {
                    hasCorrectTerritoryKey = TRUE;
                } else if(activity.sked_Activity_Collection_Operations__r != NULL && !activity.sked_Activity_Collection_Operations__r.isEmpty()) {
                    for(sked_Activity_Collection_Operation__c activityCo : activity.sked_Activity_Collection_Operations__r) {
                        if(activityCo.sked_Territory_Key__c != NULL && request.territoryKeys.contains(activityCo.sked_Territory_Key__c)) {
                            hasCorrectTerritoryKey = TRUE;
                            break;
                        }
                    }
                }
                if(hasCorrectTerritoryKey) {
                    activityRecordIds.add(activity.Id);
                }
            }
            
            // Do Pagination Query to show group activities on RAC
            List<skedModels.activity> activities = new List<skedModels.activity>();
            skedDataService.paginationQueryModel paginationResult;
            
            if(activityRecordIds != NULL && !activityRecordIds.isEmpty()) {
                skedActivityService.queryModel reformedQuery = new skedActivityService.queryModel();
                reformedQuery.recordIds = activityRecordIds;
                reformedQuery.orderBy = skedAutoMapper.instance.mapToSObjectFieldPath('activity', request.orderBy);
                reformedQuery.orderAscending = request.orderDirection == 1 ? 'ASC' : 'DESC';
                reformedQuery.pageNo = request.pageNo;
                reformedQuery.pageSize = request.pageSize;
                reformedQuery.subQueryIndicator = skedSObjectType.ACTIVITY_RESOURCE | skedSObjectType.ACTIVITY_COLLECTION_OPERATION;
                skedActivityService reformedService = (skedActivityService)skedServiceFactory.instance.resolve('sked__Activity__c');
                paginationResult = reformedService.doPaginationQuery(reformedQuery);
                   
                skedAutoMapper autoMapper = skedAutoMapper.instance;
                for (sked__Activity__c record : (List<sked__Activity__c>)paginationResult.records) {
                    system.debug('record '+record);
                    autoMapper.setTimezoneSidId(record.sked__Timezone__c);
                    skedModels.activity activity = (skedModels.activity)skedAutoMapper.instance.mapTo(record, skedModels.activity.class);
                    activity.timezone = record.sked__Start__c.format('z', record.sked__Timezone__c);
                    activities.add(activity);
                } 
                system.debug('activities last '+activities.size());
            }

            groupActivityDataModel data = new groupActivityDataModel();
            data.groupActivities = activities;
            data.totalRecords = paginationResult != NULL ? paginationResult.totalRecords : 0;
            if(data.totalRecords != NULL) {
            	data.totalPages = (integer)Math.ceil(decimal.valueOf(data.totalRecords) / request.pageSize);
            }
            
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getPendingAvailability(getPendingAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedAvailabilityService.queryModel query = new skedAvailabilityService.queryModel();
            query.availabilityStatuses = request.availabilityStatuses;
            query.availabilityTypes = request.availabilityTypes;
            query.biomedCollectionOpIds = request.biomedCollectionOpIds;
            query.endDate = request.endDate;
            query.orderBy = skedAutoMapper.instance.mapToSObjectFieldPath('availability', request.orderBy);
            query.orderAscending = request.orderDirection == 1 ? 'ASC' : 'DESC';
            query.pageNo = request.pageNo;
            query.pageSize = request.pageSize;
            query.queryText = request.queryText;
            query.regionIds = request.regionIds;
            query.resourceCategories = request.resourceCategories;
            query.isException = request.isException;
            query.requestTypes = request.requestTypes;
            query.recurringScheduleIds = request.recurringScheduleIds;
            query.roles = request.roles;

            if (!string.isBlank(request.resourceId)) {
                query.resourceIds = new List<string>();
                query.resourceIds.add(request.resourceId);
            }
            query.searchColumns = new List<string>();
            query.searchColumns.add('sked__Resource__r.Name');
            query.startDate = request.startDate;
            query.submissionEndDate = request.submissionEndDate;
            query.submissionStartDate = request.submissionStartDate;
            query.subQueryIndicator = skedSObjectType.EXCEPTION_LOG | skedSObjectType.STAFFING_BUDGET_AVAILABILITY;
            
            skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            skedDataService.paginationQueryModel paginationResult = service.doPaginationQuery(query);

            Set<string> resourceIds = new Set<string>();
            Set<String> staffingBudgetIds = new Set<String>();
            for (sked__Availability__c record : (List<sked__Availability__c>) paginationResult.records) {
                resourceIds.add(record.sked__Resource__c);
                
                if (record.sked_Staffing_Budget_Availabilities__r != null && !record.sked_Staffing_Budget_Availabilities__r.isEmpty()) {
                    for (sked_Staffing_Budget_Availability__c sba : record.sked_Staffing_Budget_Availabilities__r) {
                        staffingBudgetIds.add(sba.sked_Staffing_Budget__c);
                    }
                }
            }

            Map<String, skedModels.staffingBudget> staffingBudgetById = new Map<String, skedModels.staffingBudget>();
            if (!staffingBudgetIds.isEmpty()) {
                skedStaffingBudgetService staffingBudgetService = (skedStaffingBudgetService) skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
                skedStaffingBudgetService.queryModel staffingBudgetQuery = new skedStaffingBudgetService.queryModel();
                staffingBudgetQuery.recordIds = new List<String>(staffingBudgetIds);
                staffingBudgetQuery.subQueryIndicator = skedSObjectType.STAFFING_BUDGET_COLLECTION_OP;
                List<skedModels.staffingBudget> staffingBudgets = (List<skedModels.staffingBudget>) staffingBudgetService.getList(staffingBudgetQuery);
                for (skedModels.staffingBudget staffingBudget : staffingBudgets) {
                    staffingBudgetById.put(staffingBudget.id, staffingBudget);
                }
            }

            Map<string, skedModels.resource> mapResource = new Map<string, skedModels.resource>();
            if (!resourceIds.isEmpty()) {
                skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
                skedResourceService.queryModel resourceQuery = new skedResourceService.queryModel();
                resourceQuery.recordIds = new List<string>(resourceIds);
                resourceQuery.subQueryIndicator = skedSObjectType.RESOURCE_TAG;
                resourceQuery.activeTagsOnly = true;
                List<skedModels.resource> resources = (List<skedModels.resource>)resourceService.getList(resourceQuery);
                for (skedModels.resource resource : resources) {
                    mapResource.put(resource.id, resource);
                }
            }

            List<skedModels.availability> availabilities = new List<skedModels.availability>();
            for (sked__Availability__c record : (List<sked__Availability__c>)paginationResult.records) {
                skedModels.resource resource = mapResource.get(record.sked__Resource__c);
                skedAutoMapper.instance.setTimezoneSidId(resource.timezoneSidId);
                skedModels.availability availability = (skedModels.availability)skedAutoMapper.instance.mapTo(record, skedModels.availability.class);
                availability.timezone = record.CreatedDate.format('z', resource.timezoneSidId);
                availability.resource = resource;

                if (availability.staffingBudgetAvailabilities != null && !availability.staffingBudgetAvailabilities.isEmpty()) {
                    for (skedModels.staffingBudgetAvailability sba : availability.staffingBudgetAvailabilities) {
                        skedModels.staffingBudget staffingBudget = staffingBudgetById.get(sba.staffingBudgetId);
                        sba.staffingBudget = staffingBudget;
                    }
                }

                availabilities.add(availability);
            }
            
            availabilityDataModel data = new availabilityDataModel();
            data.availabilityData = availabilities;
            data.totalRecords = paginationResult.totalRecords;
            data.totalPages = (integer)Math.ceil(decimal.valueOf(data.totalRecords) / request.pageSize);
            result.data = data;

            skedModels.userFilter filter = getUserFilterByCategory(skedSetting.instance.RAC.filters, 'RAC-ApprovalRequests');
            filter.jsonData = Json.serialize(request);

            skedDataService userFilterService = skedServiceFactory.instance.resolve('sked_User_Filter__c');
            skedDataService.saveResult saveResult = userFilterService.saveRecord(filter);
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getPatternDetails(getDataRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedAvailabilityPatternService.queryModel query = new skedAvailabilityPatternService.queryModel();
            query.recordIds = new List<string>();
            query.recordIds.add(request.recordId);
            //query.subQueryIndicator = skedSObjectType.AVAILABILITY_PATTERN_RESOURCE;
            availabilityPatternModel data = new availabilityPatternModel();
            skedAvailabilityPatternService service = (skedAvailabilityPatternService)skedServiceFactory.instance.resolve('sked__Availability_Pattern__c');
            data.availabilityPattern = service.getList(query).get(0);

            List<AggregateResult> aggregateResourceAvailabilityPattern = [SELECT count(Id) total
                                                                          FROM sked__Availability_Pattern_Resource__c
                                                                          WHERE sked__Availability_Pattern__c = :request.recordId];
            data.numberOfResources = (Integer)(aggregateResourceAvailabilityPattern.get(0)).get('total');

            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction 
    global static skedRemoteResultModel getPatternResources(getDataRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedAvailabilityPatternResourceService.queryModel query = new skedAvailabilityPatternResourceService.queryModel();
            query.availabilityPatternIds = new List<string>();
            query.availabilityPatternIds.add(request.recordId);
            query.pageNo = request.pageNo;
            query.pageSize = request.pageSize;
            query.orderBy = skedAutoMapper.instance.mapToSObjectFieldPath('availabilityPatternResource', request.orderBy);
            query.orderAscending = request.orderDirection == 1 ? 'ASC' : 'DESC';
            skedAvailabilityPatternResourceService service = (skedAvailabilityPatternResourceService)skedServiceFactory.instance.resolve('sked__Availability_Pattern_Resource__c');
            skedDataService.paginationQueryModel paginationResult = service.doPaginationQuery(query);

            Set<string> resourceIds = new Set<string>();
            for (sked__Availability_Pattern_Resource__c record : (List<sked__Availability_Pattern_Resource__c>)paginationResult.records) {
                resourceIds.add(record.sked__Resource__c);
            }

            skedResourceService.queryModel resourceQuery = new skedResourceService.queryModel();
            resourceQuery.subQueryIndicator = skedSObjectType.RESOURCE_TAG | skedSObjectType.AVAILABILITY_PATTERN_RESOURCE;
            resourceQuery.recordIds = new List<String>(resourceIds);
            skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
            List<skedModels.resource> resources = (List<skedModels.resource>)resourceService.getList(resourceQuery);

            Map<Id, skedModels.resource> mapResource = new Map<Id, skedModels.resource>();
            for (skedModels.resource resource : resources) {
                mapResource.put(resource.Id, resource);
            }

            List<skedModels.availabilityPatternResource> availabilityPatternResources = new List<skedModels.availabilityPatternResource>();
            for (sked__Availability_Pattern_Resource__c record : (List<sked__Availability_Pattern_Resource__c>)paginationResult.records) {
                skedModels.resource resource = mapResource.get(record.sked__Resource__c);
                skedAutoMapper.instance.setTimezoneSidId(resource.timezoneSidId);
                
                skedModels.availabilityPatternResource availabilityPatternResource = (skedModels.availabilityPatternResource)skedAutoMapper.instance.mapTo(record, skedModels.availabilityPatternResource.class);
                availabilityPatternResource.resource = resource;
                availabilityPatternResources.add(availabilityPatternResource);
            }

            result.data = availabilityPatternResources;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getTerritories(getTerritoriesRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedTerritoryService.queryModel query = new skedTerritoryService.queryModel();
            query.endDate = request.endDate;
            query.startDate = request.startDate;
            
            skedTerritoryService service = (skedTerritoryService)skedServiceFactory.instance.resolve('sked_Territory__c');
            List<sked_Territory__c> records = (List<sked_Territory__c>)service.query(query);
            
            List<skedModels.territory> territories = new List<skedModels.territory>();
            skedAutoMapper autoMapper = skedAutoMapper.instance;
            for (sked_Territory__c record : records) {
                skedModels.territory territory = (skedModels.territory)skedAutoMapper.instance.mapTo(record, skedModels.territory.class);
                territories.add(territory);
            } 
            result.data = territories;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveAvailability(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = request.event.timezoneSidId;
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            Set<Date> inputDates = new Set<Date>();
            Date startDate = skedDateTimeUtils.getDateFromIsoString(request.event.startDate);
            Date endDate = skedDateTimeUtils.getDateFromIsoString(request.event.endDate);
            Date tempDate = startDate;
            while (tempDate <= endDate) {
                inputDates.add(tempDate);
                tempDate = tempDate.addDays(1);
            }

            skedResourceService.queryModel query = new skedResourceService.queryModel();
            query.recordIds = new List<string>();
            query.recordIds.add(request.event.resourceId);
            query.subQueryIndicator = skedSObjectType.AVAILABILITY;
            query.startDate = request.event.startDate;
            query.endDate = request.event.endDate;
            skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
            List<skedModels.resource> resources = (List<skedModels.resource>)resourceService.getList(query);

            if (string.isBlank(request.event.id)) {
                request.event.status = skedConstants.AVAILABILITY_STATUS_PENDING;
            } else {
                sked__Availability__c avail = [
                    SELECT Id, sked_Integrate_With_Workday__c, sked_Workday_Sync_Status__c
                    FROM sked__Availability__c
                    WHERE Id = :request.event.id
                    LIMIT 1
                ][0];

                if (avail.sked_Workday_Sync_Status__c == skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_MANUAL && !skedTriggerUtils.isUserAPS(UserInfo.getUserId())) {
                    request.event.status = skedConstants.AVAILABILITY_STATUS_PENDING;
                    request.event.approvalReason = skedConstants.AVAILABILITY_APPROVAL_REASON_WORKDAY_ADJUSTMENT_REQUIRED;
                } else if (avail.sked_Integrate_With_Workday__c) {
                    if (avail.sked_Workday_Sync_Status__c == skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_SUCCESS) {
                        request.event.status = skedConstants.AVAILABILITY_STATUS_PROCESSING_ADJUSTMENT;
                    } else {
                        request.event.status = skedConstants.AVAILABILITY_STATUS_PENDING;
                    }
                }
            }

            string key = 'availability:' + request.event.eventType;
            if (skedSetting.instance.RAC.mapShiftTypeSetting.containsKey(key)) {
                skedModels.eventTypeSetting setting = skedSetting.instance.RAC.mapShiftTypeSetting.get(key);
                request.event.isAvailable = setting.isAvailable;
            }
            
            if (resources != NULL && !resources.isEmpty()) {
                skedModels.resource currentResource = resources.get(0);
                if (!string.isBlank(currentResource.userType) && currentResource.userType.contains('Resource')) {
                    if ((request.recurringOptions == NULL && string.isBlank(request.event.id)) || (string.isNotBlank(request.event.id) && string.isBlank(request.event.scheduleId))) {
                        query.startTime = skedDateTimeUtils.getStartOfDate(startDate, skedSetting.instance.App.timezoneSidId);
                        query.endTime = skedDateTimeUtils.getEndOfDate(endDate, skedSetting.instance.App.timezoneSidId);
                        
                        skedAvailabilityPatternService patternService = (skedAvailabilityPatternService)skedServiceFactory.instance.resolve('sked__Availability_Pattern__c');
                        Map<Id, List<skedModels.event>> mapResourceTemplateEvents = patternService.getPatternEvents(new Set<Id> {currentResource.id}, inputDates);
                        
                        Map<string, skedModels.event> mapTempateEvents = new Map<string, skedModels.event>();
                        if (!mapResourceTemplateEvents.isEmpty()) {
                            List<skedModels.event> resourceTemplateEvents = mapResourceTemplateEvents.values().get(0);
                            for (skedModels.event resourceTemplateEvent : resourceTemplateEvents) {
                                mapTempateEvents.put(resourceTemplateEvent.startDate, resourceTemplateEvent);
                            }
                        }
                        boolean hasNonWorking = FALSE;
                        tempDate = startDate;
                        while (tempDate <= endDate) {
                            string dateIso = Json.serialize(tempDate).replace('"', '');
                            if (!mapTempateEvents.containsKey(dateIso)) {
                                hasNonWorking = TRUE;
                                break;
                            }
                            tempDate = tempDate.addDays(1);
                        }
                        
                        if (hasNonWorking && !request.event.isAvailable) {
                            throw new skedException('The availability must be created at working days');
                        }
                    }
                }
            }

            request.sObjectType = 'sked__Availability__c';
            request.objectType = 'availability';
            request.model = request.event;
            if (request.recurringOptions != NULL) {
                request.recurringOptions.regionId = resources.get(0).regionId;
            }
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = saveEvent(request);
            result.data = saveResult.success == FALSE ? saveResult.returnedData : request.model;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveActivity(saveActivityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = request.event.timezoneSidId;
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
            
            skedRegionService regionService = (skedRegionService)skedServiceFactory.instance.resolve('sked__Region__c');
            skedRegionService.queryModel regionQuery = new skedRegionService.queryModel();
            regionQuery.timezoneSidId = timezoneSidId;
			
            if (!string.isBlank(request.event.biomedCollectionOpId)) {
                regionQuery.biomedCollectionOpId = request.event.biomedCollectionOpId;
            } else if(request.event.biomedCollectionOpIds != NULL && !request.event.biomedCollectionOpIds.isEmpty()) {
                regionQuery.biomedCollectionOpIds = request.event.biomedCollectionOpIds;
            }
            List<sObject> queryResults = regionService.query(regionQuery);
            
            // Region check for single-select collection operation
            if (queryResults == NULL || queryResults.isEmpty()) {
                throw new skedException('Cannot find Skedulo region that matches the address timezone.');
            }
            Map<String, String> map_colOpId_regionId = new Map<String, String>();
            for(sked__Region__c region : (List<sked__Region__c>)queryResults) {
                map_colOpId_regionId.put(region.sked_Biomed_Collection_Op_Center__c, region.Id);
            }
            
            // Region check for multi-select collection operation
            if(request.event.biomedCollectionOpIds != NULL && !request.event.biomedCollectionOpIds.isEmpty()) {
                for(String colOpId : request.event.biomedCollectionOpIds) {
                    if(!map_colOpId_regionId.containsKey(colOpId)) {
                        throw new skedException('Cannot find Skedulo region that matches the address timezone.');
                    }
                }
            } else {
                request.event.regionId = map_colOpId_regionId.get(request.event.biomedCollectionOpId); //Populate region for single select co activity
            }
            
            if (!string.isBlank(request.event.biomedCollectionOpId)) {    
                //validate staffing constraint
                if (request.event.reduceFromStaffingConstraint) {
                    Date selectedDate = skedDateTimeUtils.getDateFromIsoString(request.event.startDate);
                    List<sked_Staffing_Constraint__c> staffingConstraints = [SELECT Id, sked_Total_Staff_Constraints__c, sked_Drive_Type__c
                                                                             FROM sked_Staffing_Constraint__c
                                                                             WHERE sked_Collection_Operation__c = :request.event.biomedCollectionOpId
                                                                             AND sked_Date_of_Constraint__c = :selectedDate
                                                                             AND sked_Total_Staff_Constraints__c != NULL];
                    boolean insufficientFixedSiteStaff = false;
                    boolean insufficientMobileStaff = false;
                    if (!staffingConstraints.isEmpty()) {
                        List<sked_Drive__c> sameDateDrives = [SELECT Id, sked_Total_Staff_Requested__c, sked_Type_of_Drive__c
                                                              FROM sked_Drive__c
                                                              WHERE sked_Collection_Operation__c = :request.event.biomedCollectionOpId
                                                              AND sked_Drive_Date__c = :selectedDate
                                                              AND (sked_Status__c = :skedConstants.DRIVE_STATUS_CONFIRMED
                                                                   OR sked_Status__c = :skedConstants.DRIVE_STATUS_HOLD)];
                        List<sked__Activity__c> sameDateNCEs = [SELECT Id, sked__Quantity__c, sked_Fixed_Site_Staff_Quantity__c,
                                                                sked_Mobile_Staff_Quantity__c
                                                                FROM sked__Activity__c
                                                                WHERE sked_Is_Group_Activity__c = TRUE
                                                                AND Id != :request.event.id
                                                                AND DAY_ONLY(sked__Start__c) = :selectedDate
                                                                AND sked_Region__r.sked_Biomed_Collection_Op_Center__c = :request.event.biomedCollectionOpId];
                        decimal totalFixedSiteStaffConstraints = 0;
                        decimal totalMobileStaffConstraints = 0;
                        for (sked_Staffing_Constraint__c  staffingConstraint : staffingConstraints) {
                            if (staffingConstraint.sked_Drive_Type__c == 'Fixed Site') {
                                totalFixedSiteStaffConstraints += staffingConstraint.sked_Total_Staff_Constraints__c;
                            }
                            else if (staffingConstraint.sked_Drive_Type__c == 'Mobile') {
                                totalMobileStaffConstraints += staffingConstraint.sked_Total_Staff_Constraints__c;
                            }
                        }
                        decimal fixedSiteDrivesStaffRequested = 0;
                        decimal mobileDrivesStaffRequested = 0;
                        decimal fixedSiteNCEsStaffRequested = 0;
                        decimal mobileNCEsStaffRequested = 0;
                        if (!sameDateDrives.isEmpty()) {
                            for (sked_Drive__c drive : sameDateDrives) {
                                decimal staffRequested = drive.sked_Total_Staff_Requested__c != NULL ? drive.sked_Total_Staff_Requested__c : 0;
                                if (drive.sked_Type_of_Drive__c == 'Fixed Site') {
                                    fixedSiteDrivesStaffRequested += staffRequested;
                                }
                                else if (drive.sked_Type_of_Drive__c == 'Mobile') {
                                    mobileDrivesStaffRequested += staffRequested;
                                }
                            }
                        }
                        if (!sameDateNCEs.isEmpty()) {
                            for (sked__Activity__c nce : sameDateNCEs) {
                                fixedSiteNCEsStaffRequested += nce.sked_Fixed_Site_Staff_Quantity__c != NULL ? nce.sked_Fixed_Site_Staff_Quantity__c : 0;
                                mobileNCEsStaffRequested += nce.sked_Mobile_Staff_Quantity__c  != NULL ? nce.sked_Mobile_Staff_Quantity__c  : 0;
                            }
                        }
                        if (request.event.fixedSiteStaffQuantity > 0) {
                            if (request.event.fixedSiteStaffQuantity > (totalFixedSiteStaffConstraints - fixedSiteDrivesStaffRequested - fixedSiteNCEsStaffRequested)) {
                                insufficientFixedSiteStaff = true;
                            }
                        }
                        if (request.event.mobileStaffQuantity > 0) {
                            if (request.event.mobileStaffQuantity > (totalMobileStaffConstraints - mobileDrivesStaffRequested - mobileNCEsStaffRequested)) {
                                insufficientMobileStaff = true;
                            }
                        }
                    }
                    if (insufficientFixedSiteStaff || insufficientMobileStaff) {
                        throw new skedException('Specified Staff count exceeds the Staffing Constraint for the day.');
                    }
                }
            }
            
            request.sObjectType = 'sked__Activity__c';
            request.objectType = 'activity';
            request.model = request.event;
            if (request.recurringOptions != NULL) {
                request.recurringOptions.regionIds = map_colOpId_regionId.values();
                if (request.recurringOptions.selectedDates != NULL && !request.recurringOptions.selectedDates.isEmpty()) {
                    request.recurringOptions.dateValues = new Set<Date>();
                    for (string selectedDate : request.recurringOptions.selectedDates) {
                        request.recurringOptions.dateValues.add(skedDateTimeUtils.getDateFromIsoString(selectedDate));
                    }
                }

                if (request.recurringOptions.availabilityTemplate != NULL) { 
                    Date startDate = skedDateTimeUtils.getDateFromIsoString(request.recurringOptions.availabilityTemplate.startDate);
                    Date endDate = skedDateTimeUtils.getDateFromIsoString(request.recurringOptions.availabilityTemplate.endDate);
                    if (endDate > startDate.addYears(skedSetting.instance.RAC.maxActivityRecurringYears)) {
                        throw new skedException('Recurring Pattern exceeds maximum duration');
                    }
                }
            }

            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = saveEvent(request);
            if (saveResult.message != null && saveResult.message == skedConstants.ACTIVITY_INSERT_BATCH_STARTED) {
                result.message = saveResult.message;
            }
            result.data = saveResult.success == false ? saveResult.returnedData : request.model;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveActivityResource(saveActivityResourceRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedActivityResourceService service = (skedActivityResourceService)skedServiceFactory.instance.resolve('sked__Activity_Resource__c');
			skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
            skedDataService.saveResult saveResult = service.saveRecord(request.activityResource);
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveActivityResources(saveActivityResourcesRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedActivityResourceService service = (skedActivityResourceService)skedServiceFactory.instance.resolve('sked__Activity_Resource__c');
            List<sked__Activity_Resource__c> existingActivityResources = [
                SELECT Id, sked__Resource__c
                FROM sked__Activity_Resource__c
                WHERE sked__Activity__c = :request.activityId
            ];
            Set<Id> existingResourceIds = new Set<Id>();
            for (sked__Activity_Resource__c existingActivityResource : existingActivityResources) {
                existingResourceIds.add(existingActivityResource.sked__Resource__c);
            }
            
            Set<Id> activityIds = new Set<Id>();
            Set<Id> resourceIds = new Set<Id>();
            for (skedModels.activityResource activityResource : request.activityResources) {
                activityIds.add(activityResource.activityId);
                resourceIds.add(activityResource.resourceId);
            }
            Map<Id, sked__Activity__c> mapActivity = new Map<Id, sked__Activity__c>([
                SELECT Id, sked__Timezone__c
                FROM sked__Activity__c
                WHERE Id IN :activityIds
            ]);
            
            List<sked__Activity_Resource__c> skedActivityResources = new List<sked__Activity_Resource__c>();
            for (skedModels.activityResource activityResource : request.activityResources) {
                sked__Activity__c skedActivity = mapActivity.get(activityResource.activityId);
                service.setTimezoneSidId(skedActivity.sked__Timezone__c);
                sked__Activity_Resource__c skedActivityResource = (sked__Activity_Resource__c)service.mapTosObject(activityResource);
                skedActivityResources.add(skedActivityResource);
            }
            
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
            upsert skedActivityResources;
            
            List<sked__Activity_Resource__c> recordsToDelete = new List<sked__Activity_Resource__c>();
            for (sked__Activity_Resource__c existingActivityResource : existingActivityResources) {
                if (!resourceIds.contains(existingActivityResource.sked__Resource__c)) {
                    recordsToDelete.add(existingActivityResource);
                }
            }
            if (!recordsToDelete.isEmpty()) {
                skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
                delete recordsToDelete;
            }
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveCallOut(saveCallOutRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = skedResourceUtils.getResourceTimezonesidId(request.resourceId);
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            slwcResourceService.saveCallOutRequestModel lwcRequest = new slwcResourceService.saveCallOutRequestModel();
            lwcRequest.id = request.id;
            lwcRequest.activityId = request.activityId;
            lwcRequest.jobId = request.jobId;
            lwcRequest.resourceId = request.resourceId;
            lwcRequest.callOutReason = request.callOutReason;
            lwcRequest.callOutReceivedDateTime = skedDateTimeUtils.newDateTimeInstance(request.callOutReceivedDate, request.callOutReceivedTime, timezoneSidId);
            lwcRequest.callOutNotes = request.callOutNotes;
            lwcRequest.callOutReported = request.callOutReported;
            lwcRequest.callOutType = request.callOutType;
            lwcRequest.timeOffPlan = request.timeOffPlan;
            lwcRequest.timeOffReasonCode = request.timeOffReasonCode;
            lwcRequest.usePtoForCallOut = request.usePtoForCallOut;
            lwcRequest.hasTimeOffPlans = request.hasTimeOffPlans;
            
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            result.data = slwcResourceService.saveCallOut(lwcRequest);
            result.success = true;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel savePattern(savePatternRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
			skedAvailabilityPatternService service = (skedAvailabilityPatternService)skedServiceFactory.instance.resolve('sked__Availability_Pattern__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
			skedDataService.saveResult saveResult = service.saveAvailabilityPattern(request.availabilityPattern);
            
            result.success = saveResult.success;
            result.errorMessage = saveResult.errorMessage;
            
            if (result.success) {
                SavePoint sp = Database.setSavepoint();
                try {
                    service.savePatternResources(request.availabilityPattern);
                }
                catch (Exception ex2) {
                    Database.rollback(sp);
                    throw ex2;
                }
            }
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel savePatternResource(savePatternResourceRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
			skedAvailabilityPatternService service = (skedAvailabilityPatternService)skedServiceFactory.instance.resolve('sked__Availability_Pattern__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
			service.savePatternResource(request.availabilityPatternResource);
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel deleteAvailability(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedSetting.instance.App.setTimezoneSidId(request.event.timezoneSidId);
            request.event.updateStartFinish(request.event.timezoneSidId);
            request.sObjectType = 'sked__Availability__c';
            request.objectType = 'availability';
            request.model = request.event;
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = deleteEvent(request);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel deleteAvailabilities(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            for (skedModels.event event : request.events) {
                event.updateStartFinish(request.event.timezoneSidId);
            }

            skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = service.deleteRecords(request.events);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel deleteActivity(saveActivityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedSetting.instance.App.setTimezoneSidId(request.event.timezoneSidId);

            request.sObjectType = 'sked__Activity__c';
            request.objectType = 'activity';
            request.model = request.event;
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = deleteEvent(request);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel approveAvailability(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            if (request.event != NULL) {
                if (request.event.id != null) {
                    sked__Availability__c skedAvailability = [SELECT Id, sked_Staffing_Budget__r.sked_Available_Slots__c FROM sked__Availability__c WHERE Id = :request.event.id];
                    Integer availableSlots = (Integer) skedAvailability?.sked_Staffing_Budget__r?.sked_Available_Slots__c;
                    if (availableSlots < 1) {
                        throw new skedException(skedConstants.AVAILABILITY_STAFFING_BUDGET_NO_CAPACITY);
                    }
                }

                request.events = new List<skedModels.availability>();
                request.events.add(request.event);
            }
            skedSetting.instance.App.setTimezoneSidId(request.events.get(0).timezoneSidId);
            
            if (request.events != NULL && !request.events.isEmpty()) {
                Set<Id> availIds = new Set<Id>();
                for (skedModels.availability avail : request.events) {
                    availIds.add(avail.id);
                }
                Map<Id, sked__Availability__c> availById = new Map<Id, sked__Availability__c>([
                    SELECT Id, sked_Time_Off_Reason_Code__c, sked_Integrate_With_Workday__c
                    FROM sked__Availability__c
                    WHERE Id IN :availIds
                ]);
                
                for (skedModels.availability availability : request.events) {
                    sked__Availability__c availRecord = availById.get(availability.id);
                    availability.status = availRecord.sked_Integrate_With_Workday__c ?
                        skedConstants.AVAILABILITY_STATUS_PROCESSING_APPROVAL : skedConstants.AVAILABILITY_STATUS_APPROVED;
                }
            }
            
            skedAvailabilityService availabilityService = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = availabilityService.saveRecords(request.events);
            result.data = saveResult.success == false ? saveResult.returnedData : request.events;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel cancelAvailability(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();

        try {
            String editAction = request?.recurringOptions?.editAction;
            String recurringScheduleId = request?.event?.scheduleId;
            String originalEventId = request?.event?.id;
            Date startDate = Date.valueOf(request.event.startDate);
            if (request.event != NULL) {
                request.events = new List<skedModels.availability>();
                request.events.add(request.event);
            }
            skedSetting.instance.App.setTimezoneSidId(request.events.get(0).timezoneSidId);

            if (originalEventId != null) {
                List<String> bulkActions = new List<String>{'all_events', 'following_events', 'same_weekday'};
                sked__Availability__c availability = [
                    SELECT Id, Name, sked_Start_Date__c, sked_Time_Off_Reason_Code__c, sked_Integrate_With_Workday__c, sked_Workday_Sync_Status__c, sked__Resource__c
                    FROM sked__Availability__c
                    WHERE Id = :originalEventId
                    LIMIT 1
                ][0];

                if (recurringScheduleId != null && bulkActions.contains(editAction)) {
                    Database.executeBatch(new skedCancelAvailabilityPatternBatch(availability, recurringScheduleId, editAction, UserInfo.getUserId()));
                    result.message = 'Successfully started a batch process to cancel availabilities. You will receive an email when this process completes.';

                } else {
                    if (availability.sked_Workday_Sync_Status__c == skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_MANUAL && !skedTriggerUtils.isUserAPS(UserInfo.getUserId())) {
                        availability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PENDING;
                        availability.sked_Approval_Reason__c = skedConstants.AVAILABILITY_APPROVAL_REASON_WORKDAY_CANCELLATION_REQUIRED;
                    } else if (availability.sked_Integrate_With_Workday__c && availability.sked_Workday_Sync_Status__c == skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_SUCCESS) {
                        availability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PROCESSING_CANCELLATION;
                    } else {
                        availability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_CANCELLED;
                    }
                    skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
                    update availability;
                    result.message = 'Availability has been successfully cancelled.';
                }
            }
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel declineAvailability(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            if (request.event != NULL) {
                request.events = new List<skedModels.availability>();
                request.events.add(request.event);
            }
            skedSetting.instance.App.setTimezoneSidId(request.events.get(0).timezoneSidId);
            
            if (request.events != NULL && !request.events.isEmpty()) {
                for (skedModels.availability availability : request.events) {
                    availability.status = skedConstants.AVAILABILITY_STATUS_DECLINED;
                }
            }

            skedAvailabilityService availabilityService = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = availabilityService.saveRecords(request.events);
            result.data = saveResult.success == false ? saveResult.returnedData : request.events;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel waitlistAvailability(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            if (request.event != NULL) {
                request.events = new List<skedModels.availability>();
                request.events.add(request.event);
            }
            skedSetting.instance.App.setTimezoneSidId(request.events.get(0).timezoneSidId);
            
            if (request.events != NULL && !request.events.isEmpty()) {
                for (skedModels.availability availability : request.events) {
                    availability.status = skedConstants.AVAILABILITY_STATUS_WAITLIST;
                }
            }

            skedAvailabilityService availabilityService = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = availabilityService.saveRecords(request.events);
            result.data = saveResult.success == false ? saveResult.returnedData : request.events;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel verifyUnavailabilityBalance(verifyUnavailabilityBalanceRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string resourceId = request.unavailability.get(0).resourceId;
            
            sked__Resource__c skedResource = [SELECT Id, sked_Daily_Time_Off_Hours__c, sked_Employee_ID__c
                                              FROM sked__Resource__c
                                              WHERE Id = :resourceId];
            
            decimal resourceDailyTimeOffHours = 0;
            if (skedResource.sked_Daily_Time_Off_Hours__c != NULL) {
                resourceDailyTimeOffHours = skedResource.sked_Daily_Time_Off_Hours__c * 60;
            }
            
            string timezoneSidId = skedResourceUtils.getResourceTimezonesidId(resourceId);
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
            
            skedResourceService.queryModel query = new skedResourceService.queryModel();
            query.recordIds = new List<string>();
            query.recordIds.add(resourceId);
            skedDataService resourceService = skedServiceFactory.instance.resolve('sked__Resource__c');
            skedModels.resource resource = (skedModels.resource)resourceService.getList(query).get(0);
            List<skedModels.availability> unavailabilityList = request.unavailability;

            Decimal requestedDuration = 0.00;
            Date latestEndDate = System.today();
            String timeOffType = unavailabilityList[0].eventType;
            for (skedModels.availability unavailability : unavailabilityList) {
                unavailability.updateStartFinish(timezoneSidId);
                unavailability.timezone = unavailability.start.format('z', timezoneSidId);
                
                decimal duration = skedDateTimeUtils.getDifferentMinutes(unavailability.start, unavailability.finish);
                if (unavailability.isAllDay == TRUE && duration > resourceDailyTimeOffHours) {
                    duration = resourceDailyTimeOffHours;
                }
                requestedDuration += duration;

                Date endDate = skedDateTimeUtils.getDate(unavailability.finish, timezoneSidId);
                if (endDate > latestEndDate) {
                    latestEndDate = endDate;
                }
            }
            
            skedUnavailabilityBalanceResultModel data = skedWorkdayUtils.verifyUnavailabilityBalance(skedResource, latestEndDate, requestedDuration, timeOffType);
            skedStaffingBudgetService staffingBudgetService = (skedStaffingBudgetService) skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
            staffingBudgetService.verifyStaffingBudget(resourceId, unavailabilityList);
            data.unavailability = unavailabilityList;    

            skedAvailabilityService availabilityService = (skedAvailabilityService) skedServiceFactory.instance.resolve('sked__Availability__c');
            availabilityService.verifyResourceAvailability(resourceId, unavailabilityList);
            data.unavailability = unavailabilityList; 
            result.data = data;

            availabilityService.setDefaultStatusesForUnavailabilities(data.hasEnoughHours, unavailabilityList);
            data.unavailability = unavailabilityList;
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel prepareUnavailabilityRequest(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = request.event.timezoneSidId;
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            Date startDate = skedDateTimeUtils.getDateFromIsoString(request.event.startDate);
            Date endDate = skedDateTimeUtils.getDateFromIsoString(request.event.endDate);
            
            Set<Date> inputDates = new Set<Date>();
            Date tempDate = startDate;
            while (tempDate <= endDate) {
                inputDates.add(tempDate);
                tempDate = tempDate.addDays(1);
            }
            
            sked__Resource__c skedResource = [
                SELECT Id, sked__Primary_Region__c, sked_FCC_Code__c,
                sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                (SELECT Id, sked__Tag__r.Name
                 FROM sked__ResourceTags__r
                 WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                 AND sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE
                 ORDER BY sked__Tag__r.sked_Priority__c ASC NULLS LAST
                LIMIT 1),
                (SELECT Id, sked__Location__c, sked_Location_Resource_Relationship__c
                 FROM sked__Location_Resource_Scores__r
                 WHERE sked_Location_Resource_Relationship__c = 'Preferred'
                 AND sked__Location__r.RecordType.Name = 'Fixed Site')
                FROM sked__Resource__c 
                WHERE Id = :request.event.resourceId
            ];

            Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>{request.event.resourceId => skedResource};
            Map<Id, Set<Date>> datesByResourceId = new Map<Id, Set<Date>>{request.event.resourceId => inputDates};
            
            Map<Date, List<skedStaffingBudgetWrapper>> staffingBudgetWrappersByDate = skedStaffingBudgetUtils.getSkedStaffingBudgetWrappersByDate(datesByResourceId, resourceById);
            
            skedAvailabilityPatternService patternService = (skedAvailabilityPatternService)skedServiceFactory.instance.resolve('sked__Availability_Pattern__c');
            Map<Id, List<skedModels.event>> mapResourceTemplateEvents = patternService.getPatternEvents(resourceById.keySet(), inputDates);
            
            Map<string, skedModels.event> mapTempateEvents = new Map<string, skedModels.event>();
            if (!mapResourceTemplateEvents.isEmpty()) {
                List<skedModels.event> resourceTemplateEvents = mapResourceTemplateEvents.values().get(0);
                for (skedModels.event resourceTemplateEvent : resourceTemplateEvents) {
                    mapTempateEvents.put(resourceTemplateEvent.startDate, resourceTemplateEvent);
                }
            }
            
            //get all holidays
            Map<string, Set<Date>> mapHolidays = skedSetting.instance.App.mapHoliday;
            Set<Date> allHolidays = new Set<Date>();
            if (mapHolidays.containsKey(skedConstants.HOLIDAY_GLOBAL)) {
                Set<Date> globalHolidays = mapHolidays.get(skedConstants.HOLIDAY_GLOBAL);
                allHolidays.addAll(globalHolidays);
            }
            if (!string.isBlank(skedResource.sked__Primary_Region__c)) {
                if (mapHolidays.containsKey(skedResource.sked__Primary_Region__c)) {
                    Set<Date> globalHolidays = mapHolidays.get(skedResource.sked__Primary_Region__c);
                    allHolidays.addAll(globalHolidays);
                }
            }
            //get existing unavailability
            List<sked__Availability__c> existingUnavailabilityList = [SELECT Id, sked_Start_Date__c, sked_Finish_Date__c
                                                                      FROM sked__Availability__c
                                                                      WHERE sked__Resource__c = :request.event.resourceId
                                                                      AND sked__Is_Available__c = FALSE
                                                                      AND sked_Start_Date__c <= :endDate
                                                                      AND sked_Finish_Date__c >= :startDate
                                                                      AND sked__Status__c != :skedConstants.AVAILABILITY_STATUS_DECLINED];
            Set<Date> existingAvailabilityDates = new Set<Date>();
            for (sked__Availability__c unavailability : existingUnavailabilityList) {
                tempDate = unavailability.sked_Start_Date__c;
                while (tempDate <= unavailability.sked_Finish_Date__c) {
                    existingAvailabilityDates.add(tempDate);
                    tempDate = tempDate.addDays(1);
                }
            }
            
            prepareUnavailabilityResultModel data = new prepareUnavailabilityResultModel();
            data.unavailability = new List<unavailabilityModel>();
            data.staffingBudgets = new List<skedModels.staffingBudget>();
            
            tempDate = startDate;
            while (tempDate <= endDate) {
                string dateIso = Json.serialize(tempDate).replace('"', '');
                unavailabilityModel unavailability = new unavailabilityModel();
                unavailability.unavailabilityDate = dateIso;
                List<skedStaffingBudgetWrapper> skedStaffingBudgetWrappers = staffingBudgetWrappersByDate.get(tempDate);
                
                if (allHolidays.contains(tempDate)) {
                    unavailability.unavailabilityType = 'holiday';
                }
                else if (!mapTempateEvents.containsKey(dateIso)) {
                    unavailability.unavailabilityType = 'non-working';
                }
                else if (skedStaffingBudgetWrappers != NULL && !skedStaffingBudgetWrappers.isEmpty()) {
                    for (skedStaffingBudgetWrapper staffingBudgetWrapper : skedStaffingBudgetWrappers) {
                        if (staffingBudgetWrapper.staffingBudget.sked_Request_Type__c == 'Unavailability Day') {
                            unavailability.unavailabilityType = 'unavailability-day';
                        }
                    }
                }
                else if (request.event.eventType == skedConstants.AVAILABILITY_TYPE_PTO || request.event.eventType == skedConstants.AVAILABILITY_TYPE_FLOATING_HOLIDAY) {
                    if (skedStaffingBudgetWrappers == NULL || skedStaffingBudgetWrappers.isEmpty()) {
                        unavailability.unavailabilityType = 'no-slots-defined';
                    }
                }
                if (string.isBlank(unavailability.unavailabilityType)) {
                    if (existingAvailabilityDates.contains(tempDate)) {
                        unavailability.unavailabilityType = 'existing-unavailability';
                    }
                }
                if (string.isBlank(unavailability.unavailabilityType)) {
                    skedModels.event templateEvent = mapTempateEvents.get(dateIso);
                    unavailability.workingStartTime = templateEvent.startTime;
                    unavailability.workingEndTime = templateEvent.endTime;
                    if (skedStaffingBudgetWrappers != NULL && !skedStaffingBudgetWrappers.isEmpty()) {
                        for (skedStaffingBudgetWrapper skedStaffingBudgetWrapper : skedStaffingBudgetWrappers) {
                            skedModels.staffingBudget staffingBudget = (skedModels.staffingBudget) skedAutoMapper.instance.mapTo(skedStaffingBudgetWrapper.staffingBudget, skedModels.staffingBudget.class);
                            data.staffingBudgets.add(staffingBudget);
                        }
                    }
                }
                
                data.unavailability.add(unavailability);
                tempDate = tempDate.addDays(1);
            }
            
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveUnavailability(saveUnavailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;

            skedSetting.instance.App.setTimezoneSidId(request.availability.get(0).timezoneSidId);

            skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            skedDataService.saveResult saveResult = service.saveUnavailability(request.availability);
            result.data = saveResult.success == FALSE ? saveResult.returnedData : request.model;

            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = false;
        }
        catch (Exception ex) {
            result.getError(ex, sp);

            if (result.errorMessage.contains(skedConstants.AVAILABILITY_STAFFING_BUDGET_NO_CAPACITY)) {
                result.errorMessage = skedConstants.AVAILABILITY_STAFFING_BUDGET_NO_CAPACITY;
            }
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveAvailabilityRecords(saveUnavailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;

            skedSetting.instance.App.setTimezoneSidId(request.availability.get(0).timezoneSidId);

            skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            skedDataService.saveResult saveResult = service.saveRecords(request.availability);
            result.data = saveResult.success == FALSE ? saveResult.returnedData : request.model;

            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = false;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @AuraEnabled @remoteAction
    global static skedRemoteResultModel getUnavailabilityStatistic(getUnavailabilityStatisticRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = skedResourceUtils.getResourceTimezonesidId(request.resourceId);
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
			
            Date selectedDate = System.today();
            if (request.selectedDate != null) {
                selectedDate = skedDateTimeUtils.getDateFromIsoString(request.selectedDate);
            }

            if (request.isCallOut == null) {
                request.isCallOut = false;
            }
            skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            result.data = service.getUnavailabilityStatistics(request.resourceId, selectedDate, request.isCallOut);
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getResourceOverride(getDataRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedResourceOverrideService.queryModel query = new skedResourceOverrideService.queryModel();
            query.recordIds = new List<string>();
            query.recordIds.add(request.recordId);
            
            skedResourceOverrideService service = (skedResourceOverrideService)skedServiceFactory.instance.resolve('sked__Resource_Override__c');
            sked__Resource_Override__c skedResourceOverride = (sked__Resource_Override__c)service.query(query).get(0);
            string timezonesidId = skedResourceOverride.sked_Timezone__c;
            skedSetting.instance.App.setTimezoneSidId(timezonesidId);
            skedAutoMapper.instance.setTimezoneSidId(timezonesidId);
            skedModels.resourceOverride model = (skedModels.resourceOverride)skedAutoMapper.instance.mapTo(skedResourceOverride, skedModels.resourceOverride.class);
            
            DateTime resourceOverrideStart = skedDateTimeUtils.newDateTimeInstance(model.startDate, model.startTime, timezonesidId);
            model.startDate = resourceOverrideStart.format(skedDateTimeUtils.DATE_ISO_FORMAT, model.timezoneSidId);
            model.startTime = integer.valueOf(resourceOverrideStart.format('Hmm', model.timezoneSidId));
            
            DateTime resourceOverrideEnd = skedDateTimeUtils.newDateTimeInstance(model.endDate, model.endTime, timezonesidId);
            model.endDate = resourceOverrideEnd.format(skedDateTimeUtils.DATE_ISO_FORMAT, model.timezoneSidId);
            model.endTime = integer.valueOf(resourceOverrideEnd.format('Hmm', model.timezoneSidId));
            
            if (model.isTravelRequired) {
                DateTime resourceOverrideTravelToStart = skedDateTimeUtils.newDateTimeInstance(model.travelToStartDate, model.travelToStartTime, timezonesidId);
                model.travelToStartDate = resourceOverrideTravelToStart.format(skedDateTimeUtils.DATE_ISO_FORMAT, model.timezoneSidId);
                model.travelToStartTime = integer.valueOf(resourceOverrideTravelToStart.format('Hmm', model.timezoneSidId));
                
                DateTime resourceOverrideTravelToEnd = skedDateTimeUtils.newDateTimeInstance(model.travelToEndDate, model.travelToEndTime, timezonesidId);
                model.travelToEndDate = resourceOverrideTravelToEnd.format(skedDateTimeUtils.DATE_ISO_FORMAT, model.timezoneSidId);
                model.travelToEndTime = integer.valueOf(resourceOverrideTravelToEnd.format('Hmm', model.timezoneSidId));
                
                DateTime resourceOverrideTravelBackStart = skedDateTimeUtils.newDateTimeInstance(model.travelBackStartDate, model.travelBackStartTime, timezonesidId);
                model.travelBackStartDate = resourceOverrideTravelBackStart.format(skedDateTimeUtils.DATE_ISO_FORMAT, model.timezoneSidId);
                model.travelBackStartTime = integer.valueOf(resourceOverrideTravelBackStart.format('Hmm', model.timezoneSidId));
                
                DateTime resourceOverrideTravelBackEnd = skedDateTimeUtils.newDateTimeInstance(model.travelBackEndDate, model.travelBackEndTime, timezonesidId);
                model.travelBackEndDate = resourceOverrideTravelBackEnd.format(skedDateTimeUtils.DATE_ISO_FORMAT, model.timezoneSidId);
                model.travelBackEndTime = integer.valueOf(resourceOverrideTravelBackEnd.format('Hmm', model.timezoneSidId));
            }

            model.timezone = skedResourceOverride.CreatedDate.format('z', timezonesidId);
            
            result.data = model;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveResourceOverride(saveResourceOverrideRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = skedResourceUtils.getResourceTimezonesidId(request.resourceOverride.resourceId);
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
            
            DateTime startTime = skedDateTimeUtils.newDateTimeInstance(request.resourceOverride.startDate, request.resourceOverride.startTime, timezoneSidId);
            DateTime endTime = skedDateTimeUtils.newDateTimeInstance(request.resourceOverride.endDate, request.resourceOverride.endTime, timezoneSidId);
            List<sked__Resource_Override__c> existingOverrideRegion = [SELECT Id, sked__Start__c, sked__End__c 
                                                                        FROM sked__Resource_Override__c 
                                                                        WHERE sked__Start__c < :endTime 
                                                                        AND sked__End__c > :startTime
                                                                        AND sked__Resource__c = :request.resourceOverride.resourceId
                                                                        AND Id != :request.resourceOverride.Id];
            if (existingOverrideRegion != NULL && !existingOverrideRegion.isEmpty()) {
                result.success = FALSE;
                result.message = 'Overlap with other Override Region';
                result.errorMessage = 'Overlap with other Override Region';
            }
            else {
                skedResourceOverrideService service = (skedResourceOverrideService)skedServiceFactory.instance.resolve('sked__Resource_Override__c');
                skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
                result.data = service.saveRecord(request.resourceOverride);
            }
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel deleteResourceOverride(saveResourceOverrideRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedResourceOverrideService service = (skedResourceOverrideService)skedServiceFactory.instance.resolve('sked__Resource_Override__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = service.deleteRecord(request.resourceOverride);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel searchBiomedCollectionOps(getDataRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedBiomedCollectionOpService.queryModel query = new skedBiomedCollectionOpService.queryModel();
            if (!string.isBlank(request.recordId)) {
                query.recordIds = new List<string>();
                query.recordIds.add(request.recordId);
            }
            query.queryText = request.queryText;
            query.searchColumns = new List<string>();
            query.searchColumns.add('Name');
            query.subQueryIndicator = skedSObjectType.REGION;
            
            skedBiomedCollectionOpService service = new skedBiomedCollectionOpService();
            List<skedModels.biomedCollectionOp> biomedCollectionOps = (List<skedModels.biomedCollectionOp>)service.getList(query);
            
            result.data = biomedCollectionOps;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel searchDrives(searchDrivesRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            Date startDate = skedDateTimeUtils.getDateFromIsoString(request.startDate);
            Date endDate = skedDateTimeUtils.getDateFromIsoString(request.endDate);
            
            Biomed_Collection_Op_Center__c collectionOperation = [SELECT Id,
                                                                  (SELECT Id, sked_Territory__r.sked_Parent__c
                                                                   FROM sked_Territory_Collection_Operations__r
                                                                   WHERE (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :startDate)
                                                                   AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :startDate))
                                                                  FROM Biomed_Collection_Op_Center__c
                                                                  WHERE Id = :request.collectionOperationId];
            Id arcRegionId;
            if (collectionOperation.sked_Territory_Collection_Operations__r != NULL && !collectionOperation.sked_Territory_Collection_Operations__r.isEmpty()) {
                arcRegionId = collectionOperation.sked_Territory_Collection_Operations__r.get(0).sked_Territory__r.sked_Parent__c;
            }
            
            if (arcRegionId != NULL) {
                Date lowerThresholdDate = startDate.addDays(-1);
                Date higherThresholdDate = endDate.addDays(1);
                
                List<sked_Territory_Collection_Operation__c> territoryCOs = [SELECT Id, sked_Collection_Operation__c
                                                                             FROM sked_Territory_Collection_Operation__c
                                                                             WHERE sked_Territory__r.sked_Parent__c = :arcRegionId
                                                                             AND (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :startDate)
                                                                             AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :startDate)];
                Set<Id> collectionOperationIds = new Set<Id>();
                for (sked_Territory_Collection_Operation__c territoryCO : territoryCOs) {
                    collectionOperationIds.add(territoryCO.sked_Collection_Operation__c);
                }
                skedDataService driveService = (skedDataService)skedServiceFactory.instance.resolve('sked_Drive__c');
                skedDataService.queryModelBase driveQuery = new skedDataService.queryModelBase();
                skedQueryBuilder driveQueryBuilder = driveQuery.getQueryBuilder('sked_Drive__c');
                string queryTextCondition = '(Name LIKE \'%{0}%\' OR sked_UFID__c = \'{0}\')';
                queryTextCondition = queryTextCondition.replace('{0}', request.queryText);
                driveQueryBuilder.addCondition(queryTextCondition);
                driveQueryBuilder.addCondition('sked_Drive_Date__c >= {0}', lowerThresholdDate);
                driveQueryBuilder.addCondition('sked_Drive_Date__c <= {0}', higherThresholdDate);
                driveQueryBuilder.addCondition('sked_Collection_Operation__c IN {0}', collectionOperationIds);
                
                List<skedModels.drive> drives = (List<skedModels.drive>)driveService.getList(driveQuery);
                result.data = drives;
            }
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    /*********************************************************** Unavailability Console methods ***********************************************/
    @remoteAction
    global static skedRemoteResultModel getStaffingBudgetData(getStaffingBudgetModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = UserInfo.getTimeZone().getID();

            Boolean isBiddingPeriodRequest = request.requestTypes != null && request.requestTypes.contains(skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT);
            
            //get staffing budget COs
            skedStaffingBudgetCollectionOpService.queryModel sbCoQuery = new skedStaffingBudgetCollectionOpService.queryModel();
            sbCoQuery.collectionOpIds = request.biomedCollectionOpIds;
            sbCoQuery.requestTypes = request.requestTypes;
            sbCoQuery.endDate = request.endDate;
            sbCoQuery.startDate = request.startDate;
            sbCoQuery.isBiddingPeriodRequest = isBiddingPeriodRequest;

            skedStaffingBudgetCollectionOpService sbCoService = (skedStaffingBudgetCollectionOpService) skedServiceFactory.instance.resolve('sked_Staffing_Budget_Collection_Op__c');
            List<sObject> sbCoQueryResult = sbCoService.query(sbCoQuery);
            
            //get staffing budget sites
            skedStaffingBudgetSiteService.queryModel sbSiteQuery = new skedStaffingBudgetSiteService.queryModel();
            sbSiteQuery.siteCoIds = request.biomedCollectionOpIds;
            sbSiteQuery.requestTypes = request.requestTypes;
            sbSiteQuery.endDate = request.endDate;
            sbSiteQuery.startDate = request.startDate;
            sbSiteQuery.isBiddingPeriodRequest = isBiddingPeriodRequest;

            skedStaffingBudgetSiteService sbSiteService = (skedStaffingBudgetSiteService) skedServiceFactory.instance.resolve('sked_Staffing_Budget_Site__c');
            List<sObject> sbSiteQueryResult = sbSiteService.query(sbSiteQuery);

            List<sObject> relatedListResult = new List<sObject>();
            relatedListResult.addAll(sbCoQueryResult);
            relatedListResult.addAll(sbSiteQueryResult);

            Set<String> staffingBudgetIds = new Set<String>();
            for (sObject sbRelated : relatedListResult) {
                staffingBudgetIds.add((String) sbRelated.get('sked_Staffing_Budget__c'));
            }

            List<String> staffingBudgetIdsList = new List<String>();
            staffingBudgetIdsList.addAll(staffingBudgetIds);
            
            List<skedModels.staffingBudget> staffingBudgets = new List<skedModels.staffingBudget>();
            staffingBudgetDataModel data = new staffingBudgetDataModel();
            data.staffingBudgets = staffingBudgets;
            data.totalRecords = 0;
            
            if (!staffingBudgetIdsList.isEmpty()) {
                skedStaffingBudgetService.queryModel query = new skedStaffingBudgetService.queryModel();
                query.recordIds = staffingBudgetIdsList;
                query.pageNo = request.pageNo;
                query.pageSize = request.pageSize;
                query.orderBy = skedAutoMapper.instance.mapToSObjectFieldPath('staffingBudget', request.orderBy);
                query.orderAscending = request.orderDirection == 1 ? 'ASC' : 'DESC';
                query.subQueryIndicator = skedSObjectType.STAFFING_BUDGET_COLLECTION_OP | skedSObjectType.STAFFING_BUDGET_SITE;

                if (isBiddingPeriodRequest) {
                    query.subQueryIndicator = skedSObjectType.STAFFING_BUDGET_SITE | skedSObjectType.STAFFING_BUDGET_COLLECTION_OP | skedSObjectType.STAFFING_BUDGET_AVAILABILITY;
                }
                
                skedStaffingBudgetService service = (skedStaffingBudgetService)skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
                skedDataService.paginationQueryModel paginationResult = service.doPaginationQuery(query);
                
                
                for (sked_Staffing_Budget__c record : (List<sked_Staffing_Budget__c>)paginationResult.records) {
                    //skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
                    skedModels.staffingBudget staffingBudget = (skedModels.staffingBudget)skedAutoMapper.instance.mapTo(record, skedModels.staffingBudget.class);
                    //TODO: verify timezone
                    staffingBudget.timezone = record.CreatedDate.format('z', timezoneSidId); 
                    staffingBudgets.add(staffingBudget);
                }
                data.totalRecords = staffingBudgets.size();
            }
            
            data.totalPages = (integer)Math.ceil(decimal.valueOf(data.totalRecords) / request.pageSize);
            
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getStaffingBudgetDetails(getDataRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedStaffingBudgetService.queryModel query = new skedStaffingBudgetService.queryModel();
            query.recordIds = new List<string>();
            query.recordIds.add(request.recordId);
            query.subQueryIndicator = skedSObjectType.STAFFING_BUDGET_SITE | skedSObjectType.STAFFING_BUDGET_COLLECTION_OP | skedSObjectType.STAFFING_BUDGET_AVAILABILITY;
            
            skedStaffingBudgetService service = (skedStaffingBudgetService)skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
            sked_Staffing_Budget__c skedStaffingBudget = (sked_Staffing_Budget__c)service.query(query).get(0);
            
            skedAutoMapper autoMapper = skedAutoMapper.instance;
            skedModels.staffingBudget staffingBudget = (skedModels.staffingBudget)autoMapper.mapTo(skedStaffingBudget, skedModels.staffingBudget.class);
            if (skedStaffingBudget.sked_Staffing_Budget_Availabilities__r != NULL) {
                staffingBudget.staffingBudgetAvailabilities = new List<skedModels.staffingBudgetAvailability>();
                for (sked_Staffing_Budget_Availability__c skedSba : skedStaffingBudget.sked_Staffing_Budget_Availabilities__r) {
                    autoMapper.setTimezoneSidId(skedSba.sked_Availability__r.sked__Timezone__c);
                    skedModels.staffingBudgetAvailability sba = (skedModels.staffingBudgetAvailability) autoMapper.mapTo(skedSba, skedModels.staffingBudgetAvailability.class);
                    staffingBudget.staffingBudgetAvailabilities.add(sba);
                }
            }

            result.data = staffingBudget;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getRecurringSchedule(getDataRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedStaffingBudgetService.queryModel query = new skedStaffingBudgetService.queryModel();
            query.recurringScheduleIds = new List<string>();
            query.recurringScheduleIds.add(request.recordId);
            query.subQueryIndicator = skedSObjectType.AVAILABILITY | skedSObjectType.STAFFING_BUDGET_COLLECTION_OP | skedSObjectType.STAFFING_BUDGET_SITE;
            
            skedStaffingBudgetService service = (skedStaffingBudgetService)skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
            List<sked_Staffing_Budget__c> skedStaffingBudgets = (List<sked_Staffing_Budget__c>)service.query(query);

            List<skedModels.staffingBudget> staffingBudgets = new List<skedModels.staffingBudget>();
            for (sked_Staffing_Budget__c skedStaffingBudget : skedStaffingBudgets) {
                skedModels.staffingBudget staffingBudget = (skedModels.staffingBudget)skedAutoMapper.instance.mapTo(skedStaffingBudget, skedModels.staffingBudget.class);
                if (skedStaffingBudget.sked_Availabilities__r != NULL && !skedStaffingBudget.sked_Availabilities__r.isEmpty()) {
                    staffingBudget.availabilities = new List<skedModels.availability>();
                    for (sked__Availability__c skedAvailability : skedStaffingBudget.sked_Availabilities__r) {
                        skedAutoMapper.instance.setTimezoneSidId(skedAvailability.sked__Timezone__c);
                        skedModels.availability availability = (skedModels.availability)skedAutoMapper.instance.mapTo(skedAvailability, skedModels.availability.class);
                        staffingBudget.availabilities.add(availability);
                    }
                }
                staffingBudgets.add(staffingBudget);
            }
            result.data = staffingBudgets;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveStaffingBudget(saveStaffingBudgetRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = UserInfo.getTimeZone().getID();
            
            request.event.startDate = request.event.staffingBudgetDate;
            request.event.startTime = 0;
            request.event.endDate = request.event.staffingBudgetDate;
            request.event.endTime = 0;
            request.event.updateStartFinish(timezoneSidId);
            
            request.sObjectType = 'sked_Staffing_Budget__c';
            request.objectType = 'staffingBudget';
            request.model = request.event;
            
            skedModels.staffingBudget staffingBudget = (skedModels.staffingBudget)request.model;
            request.model = staffingBudget;

            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = saveEvent(request);
            result.data = saveResult.success == FALSE ? saveResult.returnedData : request.model;
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel deleteStaffingBudget(saveStaffingBudgetRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = UserInfo.getTimeZone().getID();
            
            request.event.startDate = request.event.staffingBudgetDate;
            request.event.startTime = 0;
            request.event.endDate = request.event.staffingBudgetDate;
            request.event.endTime = 0;
            request.event.updateStartFinish(timezoneSidId);
            
            request.sObjectType = 'sked_Staffing_Budget__c';
            request.objectType = 'staffingBudget';
            request.model = request.event;
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = deleteEvent(request);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel deleteStaffingBudgets(saveBulkStaffingBudgetRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedStaffingBudgetService service = (skedStaffingBudgetService) skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = service.deleteRecords(request.staffingBudgets);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveBulkStaffingBudget(saveBulkStaffingBudgetRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = UserInfo.getTimeZone().getID();
            
            skedStaffingBudgetService service = (skedStaffingBudgetService)skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            service.saveRecurrence(request.staffingBudgets);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getFixedSitesRelatedToCo(getSitesRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedDataService siteCoService = (skedDataService)skedServiceFactory.instance.resolve('sked_Site_Collection_Operation__c');
            skedDataService.queryModelBase siteCoQuery = new skedDataService.queryModelBase();
            skedQueryBuilder siteCoQueryBuilder = siteCoQuery.getQueryBuilder('sked_Site_Collection_Operation__c');
            siteCoQueryBuilder.addCondition('sked_Site__r.sked_Active__c = TRUE');
            siteCoQueryBuilder.addCondition('sked_Site__r.RecordType.Name = \'Fixed Site\'');
            siteCoQueryBuilder.addCondition('sked_Collection_Operation__c IN {0}', request.biomedCollectionOpIds);
            if(request.staffingBudgetDate != NULL) {
                Date startDate = skedDateTimeUtils.getDateFromIsoString(request.staffingBudgetDate);
                siteCoQueryBuilder.addCondition('sked_Start_Date__c <= {0}', startDate);
                siteCoQueryBuilder.addCondition('sked_End_Date__c >= {0}', startDate);
            }
                
            List<skedModels.siteCollectionOperation> siteCos = (List<skedModels.siteCollectionOperation>) siteCoService.getList(siteCoQuery);
            Map<Id, object> map_siteId_siteInfo = new Map<Id, object>();
            for(skedModels.siteCollectionOperation siteCo : siteCos) {
                if(!map_siteId_siteInfo.containsKey((Id) siteCo.siteId)) {
                    skedModels.serviceLocation site = siteCo.site;
                    map_siteId_siteInfo.put((Id) siteCo.siteId, (object) site);
                }
            }
            result.data = map_siteId_siteInfo.values();
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel validateBulkStaffingBudgetsAgainstSiteCos(validateBulkStaffingBudget request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        if(request.siteIds != NULL && !request.siteIds.isEmpty()) {
            try {
                skedDataService siteCoService = (skedDataService)skedServiceFactory.instance.resolve('sked_Site_Collection_Operation__c');
                skedDataService.queryModelBase siteCoQuery = new skedDataService.queryModelBase();
                skedQueryBuilder siteCoQueryBuilder = siteCoQuery.getQueryBuilder('sked_Site_Collection_Operation__c');
                siteCoQueryBuilder.addCondition('sked_Site__c IN {0}', request.siteIds);
                siteCoQuery.orderBy = skedAutoMapper.instance.mapToSObjectFieldPath('siteCollectionOperation', 'startDate');
                siteCoQuery.orderAscending = 'ASC';
    
                List<skedModels.siteCollectionOperation> siteCoList = (List<skedModels.siteCollectionOperation>) siteCoService.getList(siteCoQuery);
                Map<String, List<skedModels.siteCollectionOperation>> map_siteId_siteInfo = new Map<String, List<skedModels.siteCollectionOperation>>();
                for(skedModels.siteCollectionOperation siteCo : siteCoList) {
                    if(!map_siteId_siteInfo.containsKey(siteCo.siteId)) {
                        map_siteId_siteInfo.put(siteCo.siteId, new List<skedModels.siteCollectionOperation>());
                    }
                    map_siteId_siteInfo.get(siteCo.siteId).add(siteCo);
                }
    
                for(String siteId : map_siteId_siteInfo.keySet()) {
                    Integer count = 0;
                    List<skedModels.siteCollectionOperation> siteCos = map_siteId_siteInfo.get(siteId);
                    for(skedModels.siteCollectionOperation siteCo : siteCos) {
                        count++;
                        Date siteCoStartDate = skedDateTimeUtils.getDateFromIsoString(siteCo.startDate);
                        Date siteCoEndDate = skedDateTimeUtils.getDateFromIsoString(siteCo.endDate);
                        skedModels.siteCollectionOperation nextSiteCo = siteCos.size() != count ? siteCos[count] : NULL;
                        for(String staffingBudgetDateString : request.staffingBudgetDates) {
                            Date staffingBudgetDate = skedDateTimeUtils.getDateFromIsoString(staffingBudgetDateString);
                            if(siteCoStartDate <= staffingBudgetDate && siteCoEndDate >= staffingBudgetDate) {
                                if(!request.biomedCollectionOpIds.contains(siteCo.biomedCollectionOpId)) {
                                    result.success = FALSE;
                                    if(siteCo.site.biomedCollectionOpName.equalsIgnoreCase(siteCo.biomedCollectionOpName)) {
                                        result.errorMessage = siteCo.site.name +' is currently associated with '+siteCo.site.biomedCollectionOpName+' till '+siteCo.endDate+'. Please adjust your selection.';
                                    } else {
                                        result.errorMessage = siteCo.site.name +' is no longer associated with '+siteCo.site.biomedCollectionOpName+' as of '+siteCo.startDate+'. Please adjust your selection.';
                                    }
                                }
                            } else if(siteCoEndDate < staffingBudgetDate && nextSiteCo == NULL) {
                                DateTime newStartDate = DateTime.newInstance(siteCoEndDate.year(), siteCoEndDate.month(), siteCoEndDate.day() + 1, 0, 0, 0);
                                String dateIsoString = newStartDate.format('yyyy-MM-dd');
                                result.success = FALSE;
                                result.errorMessage = siteCo.site.name +' is no longer associated with any collection operation as of '+dateIsoString+'. Please adjust your selection.';
                            }
                        }
                    }
                }
    
            } catch (Exception ex) {
                result.getError(ex, sp);
            }
        }
        return result;
    }

    /*********************************************************** Custom Availability methods ***********************************************/
    @remoteAction
    global static skedRemoteResultModel saveCustomAvailability(saveCustomAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = request.event.timezoneSidId;
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            if (string.isBlank(request.event.id)) {
                request.event.status = skedConstants.AVAILABILITY_STATUS_APPROVED;
            }

            Set<Date> inputDates = new Set<Date>();
            Date startDate = skedDateTimeUtils.getDateFromIsoString(request.event.startDate);
            Date endDate = skedDateTimeUtils.getDateFromIsoString(request.event.endDate);
            Date tempDate = startDate;
            while (tempDate <= endDate) {
                inputDates.add(tempDate);
                tempDate = tempDate.addDays(1);
            }
            
            skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
            skedResourceService.queryModel resourceQuery = new skedResourceService.queryModel();
            resourceQuery.recordIds = new List<string>{request.event.resourceId};
            resourceQuery.subQueryIndicator = skedSObjectType.AVAILABILITY;
            resourceQuery.startTime = skedDateTimeUtils.getStartOfDate(startDate, timezoneSidId);
            resourceQuery.endTime = skedDateTimeUtils.getEndOfDate(endDate, timezoneSidId);
            List<skedModels.resource> resources = (List<skedModels.resource>)resourceService.getList(resourceQuery);
            
            resourceService.populateNonWorkingEvents(resources, inputDates, resourceQuery.startTime, resourceQuery.endTime);
            skedModels.resource currentResource = resources.get(0);
            Boolean hasWorking = FALSE;
            
            if (currentResource.templateEvents != NULL) {
                for (skedModels.event event : currentResource.templateEvents) {
                    Date templateDate = skedDateTimeUtils.getDateFromIsoString(event.startDate);
                    if (inputDates.contains(templateDate)) {
                        hasWorking = TRUE;
                        break;
                    }
                }
                if (hasWorking) {
                    throw new skedException('The Volunteer availability must be created at non-working days');
                }
            }

            skedDataService service = (skedDataService)skedServiceFactory.instance.resolve('sked_Custom_Availability__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = service.saveRecord(request.event);
            result.data = saveResult.success == FALSE ? saveResult.returnedData : request.model;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getCustomAvailabilityDetails(getCustomAvailabilityDetailsRequest request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedDataService.queryModelBase query = new skedDataService.queryModelBase();
            query.recordIds = new List<string>();
            query.recordIds.add(request.event.id);
            
            skedDataService service = (skedDataService)skedServiceFactory.instance.resolve('sked_Custom_Availability__c');
            List<sked_Custom_Availability__c> models = (List<sked_Custom_Availability__c>)service.query(query);
            sked_Custom_Availability__c skedCustomAvailability = models.get(0);
            string timezonesidId = skedCustomAvailability.sked_Timezone__c;
            skedSetting.instance.App.setTimezoneSidId(timezonesidId);
            skedAutoMapper.instance.setTimezoneSidId(timezonesidId);
            
            availabilityDetailsModel data = new availabilityDetailsModel();
            data.event = (skedModels.customAvailability)skedAutoMapper.instance.mapTo(skedCustomAvailability, skedModels.customAvailability.class);
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel cancelCustomAvailability(saveCustomAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = request.event.timezoneSidId;
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
            
            request.event.status = skedConstants.AVAILABILITY_STATUS_CANCELLED;

            skedDataService service = (skedDataService)skedServiceFactory.instance.resolve('sked_Custom_Availability__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = service.saveRecord(request.event);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel deleteCustomAvailability(saveCustomAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            skedDataService service = (skedDataService)skedServiceFactory.instance.resolve('sked_Custom_Availability__c');
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            skedDataService.saveResult saveResult = service.deleteRecord(request.event);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getStaffingBudgetsAvailabilities(getStaffingBudgetsAvailabilitiesRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            skedStaffingBudgetAvailabilityService.queryModel query = new skedStaffingBudgetAvailabilityService.queryModel();
            query.staffingBudgetIds = request.staffingBudgetIds;
            query.queryText = request.queryText;
            query.availabilityStatuses = request.availabilityStatuses;
            query.recurringScheduleIds = request.recurringScheduleIds;
            query.hideRecordsOutsideBiddingPeriod = request.hideRecordsOutsideBiddingPeriod;
            query.searchColumns = new List<string>();
            query.searchColumns.add('sked_Availability__r.sked__Resource__r.Name');
            query.searchColumns.add('CreatedBy.Name');
            query.searchColumns.add('sked_Staffing_Budget__r.sked_Biomed_Collection_Op_Center__r.Name');
            query.subQueryIndicator = skedSObjectType.AVAILABILITY | skedSObjectType.STAFFING_BUDGET;
            query.orderBy = skedAutoMapper.instance.mapToSObjectFieldPath('staffingBudgetAvailability', request.orderBy);
            query.orderAscending = request.orderDirection == 1 ? 'ASC' : 'DESC';
            
            skedStaffingBudgetAvailabilityService service = (skedStaffingBudgetAvailabilityService) skedServiceFactory.instance.resolve('sked_Staffing_Budget_Availability__c');
            List<sked_Staffing_Budget_Availability__c> records = (List<sked_Staffing_Budget_Availability__c>) service.query(query);

            Set<string> resourceIds = new Set<string>();
            for (sked_Staffing_Budget_Availability__c record : (List<sked_Staffing_Budget_Availability__c>) records) {
                resourceIds.add(record.sked_Availability__r.sked__Resource__c);
            }
            Map<string, skedModels.resource> mapResource = new Map<string, skedModels.resource>();
            if (!resourceIds.isEmpty()) {
                skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
                skedResourceService.queryModel resourceQuery = new skedResourceService.queryModel();
                resourceQuery.recordIds = new List<string>(resourceIds);
                resourceQuery.subQueryIndicator = skedSObjectType.RESOURCE_TAG;
                resourceQuery.activeTagsOnly = true;
                List<skedModels.resource> resources = (List<skedModels.resource>)resourceService.getList(resourceQuery);
                for (skedModels.resource resource : resources) {
                    mapResource.put(resource.id, resource);
                }
            }

            skedAutoMapper autoMapper = skedAutoMapper.instance;
            List<skedModels.staffingBudgetAvailability> staffingBudgetAvailabilities = new List<skedModels.staffingBudgetAvailability>();
            for (sked_Staffing_Budget_Availability__c record : records) {
                autoMapper.setTimezoneSidId(record.sked_Availability__r.sked__Timezone__c);
                skedModels.staffingBudgetAvailability staffingBudgetAvailability = (skedModels.staffingBudgetAvailability) autoMapper.mapTo(record, skedModels.staffingBudgetAvailability.class);
                skedModels.resource availabilityResource = mapResource.get(staffingBudgetAvailability.availability.resourceId);
                staffingBudgetAvailability.availability.resource = availabilityResource;
                staffingBudgetAvailabilities.add(staffingBudgetAvailability);
            }
            
            staffingBudgetAvailabilityDataModel data = new staffingBudgetAvailabilityDataModel();
            data.staffingBudgetAvailabilityData = staffingBudgetAvailabilities;
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getAvailatorData(getAvailatorDataRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            slwcAllocationService.getResourceDataRequestModel model = new slwcAllocationService.getResourceDataRequestModel();
            model.accountIds = request.accountIds;
            model.collectionOperationIds = request.collectionOperationIds;
            model.excludedActivityIds = request.excludedActivityIds;
            model.excludedDriveIds = request.excludedDriveIds;
            model.locationIds = request.locationIds;
            model.inputDates = request.inputDates;
            model.jobIds = request.jobIds;
            model.recordIds = request.recordIds;
            model.pageSize = request.pageSize;
            model.pageNo = request.pageNo;
            model.timezoneSidId = request.timezoneSidId;
            model.getAssetsOnly = request.getAssetsOnly;
            
            slwcAuraResult availatorData = slwcAllocationService.getResourceData(model);
            
            result.data = availatorData.returnedData;
        } 
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
  
    /*********************************************************** Private methods ***********************************************************/
    private static List<sked__Availability_Pattern__c> getAvailabilityPatterns(List<sked__Resource__c> skedResources) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Resource__c skedResource : skedResources) {
            resourceIds.add(skedResource.Id);
        }
        List<sked__Availability_Pattern_Resource__c> patternResourceList = [SELECT sked__Resource__c, sked__Availability_Pattern__c
                                                                            FROM sked__Availability_Pattern_Resource__c
                                                                            WHERE sked__Resource__c IN :resourceIds]; 
        Set<Id> patternIds = new Set<Id>();
        for (sked__Availability_Pattern_Resource__c patternResource : patternResourceList) {
            patternIds.add(patternResource.sked__Availability_Pattern__c);
        }
        return [SELECT Id, Name, sked__Description__c, sked__Pattern__c, sked_Validate_2CDO_Rule__c
                FROM sked__Availability_Pattern__c
                WHERE Id IN :patternIds];
    }

    private static skedModels.userFilter getUserFilterByCategory(List<skedModels.userFilter> filters, string category) {
        skedModels.userFilter result;

        for (skedModels.userFilter filter : filters) {
            if (filter.category == category) {
                result = filter;
                break;
            }
        }
        if (result == null) {
            result = new skedModels.userFilter();
            result.category = category;
            result.userId = UserInfo.getUserId();
        }
        return result;
    }
    
    /*********************************************************** Sked APIs ***********************************************************/
	@remoteAction
    global static skedRemoteResultModel getAddressPredictions(getgetAddressPredictionsModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            String sessionId = sked.SkeduloAPI.getSessionId();
            sked.ApiResult.AutoComplete apiResult = sked.SkeduloAPI.autocomplete(request.queryText, 'US', sessionId);
            result.data = apiResult.response;
            
            result.success = true;
        } 
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getPlaceDetails(getPlaceDetailsModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            String sessionId = sked.SkeduloAPI.getSessionId();
            sked.ApiResult.Place apiResult = sked.SkeduloAPI.place(request.placeId, sessionId);
            result.data = apiResult.response;
            
            result.success = true;
        } 
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    global class getgetAddressPredictionsModel extends getDataRequestModel {
        public string queryText;
    }
    
    global class getPlaceDetailsModel extends getDataRequestModel {
        public string placeId;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    global class getAvailatorDataRequestModel extends getDataRequestModel {
        public List<string> accountIds;
        public List<string> collectionOperationIds;
        public List<string> excludedActivityIds;
        public List<string> excludedDriveIds;
        public List<string> locationIds;
        public List<string> inputDates;
        public List<string> jobIds;
        public List<string> recordIds;
        public string timezoneSidId;
        public boolean getAssetsOnly;
    }   
    
    global class getResourceRequestModel extends getDataRequestModel {
        public List<string> arcRegionIds;
        public List<string> availabilityStatuses;
        public List<string> biomedCollectionOpIds;
        public List<string> districtIds;
        public List<string> divisionIds;
        public List<string> territoryKeys;
        public string endDate;
        public DateTime endTime;
        public List<string> jobAllocationStatuses;
        public List<string> locationIds;
        public List<string> regionIds;
        public List<string> resourceCategories;
        public List<string> resourceEmploymentTypes;
        public List<string> resourceTypes;
        public string resourceId;
        public DateTime startTime;
        public string startDate;
        public Boolean matchAllSelectedTags;
        public List<string> tagIds;
        public List<string> patternIds;
        public string timezoneSidId;
        public Set<Date> inputDates;
        public List<String> availabilityTypes;
        public List<String> activityTypes;
        public boolean hasNoAssignment;
        public boolean hasTemporaryRelocation;
        public string additionalFilterOnDate;
    }

    global class getAvailabilityDetailsRequest extends skedRemoteRequestModel {
        public skedModels.availability event;
    }

    global class getCustomAvailabilityDetailsRequest extends skedRemoteRequestModel {
        public skedModels.customAvailability event;
    }
    
    global class getGroupActivitiesRequestModel extends getDataRequestModel {
        public List<string> activityTypes;
        public List<string> biomedCollectionOpIds;
        public string endDate;
        public List<string> regionIds;
        public string startDate;
        public List<string> subTypes;
        public List<string> territoryKeys;
        public string timezoneSidId;
    }
    
    global class getPendingAvailabilityRequestModel extends getDataRequestModel {
        public List<string> availabilityStatuses;
        public List<string> availabilityTypes;
        public List<string> biomedCollectionOpIds;
        public string endDate;
        public string timezoneSidId;
        public List<string> regionIds;
        public List<string> resourceCategories;
        public string resourceId;
        public List<string> roles;
        public string startDate;
        public Boolean isException;
        public List<string> requestTypes;
        public List<string> staffingBudgetIds;
        public string submissionEndDate;
        public string submissionStartDate;
        public List<string> recurringScheduleIds;
    }

    global class getStaffingBudgetModel extends getDataRequestModel {
        public List<string> biomedCollectionOpIds;
        public List<string> roleIds;
        public List<string> requestTypes;
        public string startDate;
        public string endDate;
    }

    global class getStaffingBudgetsAvailabilitiesRequestModel extends getDataRequestModel {
        public List<string> availabilityStatuses;
        public List<string> recurringScheduleIds;
        public List<String> staffingBudgetIds;
        public Boolean hideRecordsOutsideBiddingPeriod = false;
    }
    
    global class getTerritoriesRequestModel extends getDataRequestModel {
        public string startDate;
        public string endDate;
    }
    
    global class getUnavailabilityStatisticRequestModel extends getDataRequestModel {
        public string resourceId;
        public string selectedDate;
        public boolean isCallOut;
    }

    global class saveAvailabilityRequestModel extends saveRequestModel {
        public skedModels.availability event;
        public List<skedModels.availability> events;
        public string deleteAction;// allMember, outTeam;
    }

    global class saveCustomAvailabilityRequestModel extends saveRequestModel {
        public skedModels.customAvailability event;
    }
    
    global class saveUnavailabilityRequestModel extends saveRequestModel {
        public List<skedModels.availability> availability;
    }

    global class saveActivityRequestModel extends saveRequestModel {
        public skedModels.activity event;
        public string deleteAction;
    }
    
    global class saveActivityResourceRequestModel extends saveRequestModel {
        public skedModels.activityResource activityResource;
    }
    
    global class saveActivityResourcesRequestModel extends saveRequestModel {
        public string activityId;
        public List<skedModels.activityResource> activityResources;
    }
    
    global class saveRecurringEventsRequestModel extends saveRequestModel {
        public List<skedModels.availability> events;
    }

    global class saveCallOutRequestModel extends saveRequestModel {
        public string id;
        public string activityId;
        public string jobId; 
        public string resourceId; 
        public string callOutReason;
        public string callOutReceivedDate;
        public integer callOutReceivedTime; 
        public string callOutNotes;
        public boolean callOutReported;
        public string callOutType;
        public string timeOffPlan {get;set;}
        public string timeOffReasonCode {get;set;}
        public boolean usePtoForCallOut {get;set;}
        public boolean hasTimeOffPlans {get;set;}
    }
    
    global class savePatternRequestModel extends saveRequestModel {
        public skedModels.availabilityPattern availabilityPattern;
    }
    
    global class savePatternResourceRequestModel extends saveRequestModel {
        public skedModels.availabilityPatternResource availabilityPatternResource;
    }
    
    global class saveResourceOverrideRequestModel extends saveRequestModel {
        public skedModels.resourceOverride resourceOverride;
    }

    global class saveUserFilterRequestModel extends saveRequestModel {
        public skedModels.userFilter event;
    }

    global class searchDrivesRequestModel extends getDataRequestModel {
        public string collectionOperationId;
        public string endDate;
        public string startDate;
    }

    global class availabilityDetailsModel {
        public object event;
    }

    global class resourceDataModel {
        public object resources;
        public object groupActivities;
        public object customAvailabilities;
        public object patterns;
        public string today;
        public string timezone;
        
        public integer totalPages;
        public integer totalRecords;
    }
    
    global class availabilityDataModel {
        public object availabilityData;
        public integer totalPages;
        public integer totalRecords;
    }

    global class availabilityPatternModel {
        public object availabilityPattern;
        public integer numberOfResources;
    }
    
    global class groupActivityDataModel {
        public object groupActivities;
        public integer totalPages;
        public integer totalRecords;
    }

    global class staffingBudgetAvailabilityDataModel {
        public object staffingBudgetAvailabilityData;
    }
    
    global class prepareUnavailabilityResultModel {
        public List<unavailabilityModel> unavailability;
        public List<skedModels.staffingBudget> staffingBudgets;
    }
    
    global class unavailabilityModel {
        public string unavailabilityType; //working-time;2cdo;holiday
        public integer workingStartTime;
        public integer workingEndTime;
        public string unavailabilityDate;
    }
    
    global class verifyUnavailabilityBalanceRequestModel extends saveRequestModel {
        public List<skedModels.availability> unavailability;
    }

    global class getStaffingBudgetRequestModel extends getDataRequestModel {
        public List<string> biomedCollectionOpIds;
        public string endDate;
        public string startDate;
    }
    
    global class saveStaffingBudgetRequestModel extends saveRequestModel {
        public skedModels.staffingBudget event;
        public string deleteAction;
    }
    
    global class saveBulkStaffingBudgetRequestModel extends saveRequestModel {
        public List<skedModels.staffingBudget> staffingBudgets;
    }

    global class saveBulkActivityRequestModel extends saveRequestModel {
        public List<skedModels.activity> activities;
    }
    
    global class staffingBudgetDataModel {
        public object staffingBudgets;
        public integer totalPages;
        public integer totalRecords;
    }

    global class getSitesRequestModel extends getDataRequestModel {
        public List<string> biomedCollectionOpIds;
        public string staffingBudgetDate;
    }

    global class validateBulkStaffingBudget extends getDataRequestModel {
        public List<string> biomedCollectionOpIds;
        public List<string> siteIds;
        public List<String> staffingBudgetDates;
    }
}