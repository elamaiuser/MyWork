global class skedPtoRequestController extends skedBaseController {
    
    public string resourceId {get;set;}
    
    public skedPtoRequestController() {
        List<sked__Resource__c> resourceQuery = [SELECT Id
                                                 FROM sked__Resource__c
                                                 WHERE sked__User__c = :UserInfo.getUserId()
                                                 AND sked__Is_Active__c = TRUE];
        this.resourceId = (resourceQuery != NULL && resourceQuery.size() == 1) ? resourceQuery.get(0).Id : NULL;
    }
    
    @remoteAction
    global static skedRemoteResultModel initialize(initializeRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            Map<string, object> mapConfigData = getConfigData(request.configKeys);
            if (mapConfigData.containsKey('availabilityTypes')) {
                List<string> availabilityTypes = skedUtils.getPickListValues('sked__Availability__c', 'sked__Type__c');
                List<string> results = new List<string>();
                for (string availabilityType : availabilityTypes) {
                    if (availabilityType != skedConstants.AVAILABILITY_TYPE_AVAILABILITY_TEMPLATE_OVERRIDE) {
                        results.add(availabilityType);
                    }
                }
                mapConfigData.put('availabilityTypes', results);
            }
            
            Map<string, List<string>> mapResourceTypeAvailabilityTypes = 
                    skedPicklistFieldUtils.getMapDependentOptions(sked__Availability__c.sked_Resource_Type__c, sked__Availability__c.sked__Type__c);
            mapConfigData.put('mapResourceTypeAvailabilityTypes', mapResourceTypeAvailabilityTypes);
            
            mapConfigData.put('consoleSettings', skedSetting.instance.RAC);
            mapConfigData.put('adminSettings', skedSetting.instance.Admin);
            mapConfigData.put('eventTypeSettings', skedSetting.instance.RAC.mapShiftTypeSetting.values());

            if (!string.isBlank(request.resourceId)) {
                List<string> recordIds = new List<string>();
                recordIds.add(request.resourceId);

                skedResourceService.queryModel query = new skedResourceService.queryModel();
                query.recordIds = recordIds;

                skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
                List<skedModels.resource> resources = (List<skedModels.resource>)resourceService.getList(query);

                mapConfigData.put('resource', resources.get(0));
            }
            
            result.data = mapConfigData;

            result.viewData.put('timezoneSidId', UserInfo.getTimeZone().getID());
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel confirmUnavailability(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            sked__Availability__c availability = new sked__Availability__c(
                Id = request.event.Id,
                sked_Waitlist_Confirmed__c = request.event.waitlistConfirmed,
                sked_Custom_Status__c = request.event.status
            );
            update availability;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getPendingAvailability(getPendingAvailabilityRequest request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = (string) request.viewData.get('timezoneSidId');
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
            
            skedAvailabilityService.queryModel query = new skedAvailabilityService.queryModel();
            if (!string.isBlank(request.endDate)) {
                Date endDate = skedDateTimeUtils.getDateFromIsoString(request.endDate);
                query.endTime = skedDateTimeUtils.getEndOfDate(endDate, timezoneSidId);
            }

            query.resourceIds = new List<string>();
            query.resourceIds.add(request.resourceId);
            if (!string.isBlank(request.startDate)) {
                Date startDate = skedDateTimeUtils.getDateFromIsoString(request.startDate);
                query.startTime = skedDateTimeUtils.getStartOfDate(startDate, timezoneSidId);
            }
            
            skedAvailabilityService service = (skedAvailabilityService) skedServiceFactory.instance.resolve('sked__Availability__c');
            availabilityDataModel availabilityData = new availabilityDataModel();
            availabilityData.availabilityData = service.getList(query);
            result.data = availabilityData;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getStaffingBudget(getStaffingBudgetRequest request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = (string)request.viewData.get('timezoneSidId');
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
            
            List<string> recordIds = new List<string>();
            recordIds.add(request.resourceId);
            skedResourceService.queryModel resourceQuery = new skedResourceService.queryModel();
            resourceQuery.recordIds = recordIds;
            
            skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
            skedModels.resource resource = ((List<skedModels.resource>)resourceService.getList(resourceQuery)).get(0);
            
            skedStaffingBudgetService.queryModel staffingBudgetQuery = new skedStaffingBudgetService.queryModel();
            staffingBudgetQuery.biomedCollectionOpIds = new List<string>();
            staffingBudgetQuery.biomedCollectionOpIds.add(resource.biomedCollectionOpId);
            staffingBudgetQuery.roles = resource.roles.split(';');
            staffingBudgetQuery.startDate = request.startDate;
            
            skedStaffingBudgetService staffingBudgetService = (skedStaffingBudgetService)skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
            List<skedModels.staffingBudget> staffingBudgets = (List<skedModels.staffingBudget>)staffingBudgetService.getList(staffingBudgetQuery);
            
            Map<string, integer> map_type_priority = new Map<string, integer>();
            map_type_priority.put(skedConstants.STAFFING_BUDGET_REQUEST_TYPE_STANDARD, 1);
            map_type_priority.put(skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT, 2);
            map_type_priority.put(skedConstants.STAFFING_BUDGET_REQUEST_TYPE_ALL_HANDS_ON_DECK, 3);
                
            Map<string, skedModels.staffingBudget> mapStaffingBudget = new Map<string, skedModels.staffingBudget>();
            for (skedModels.staffingBudget staffingBudget : staffingBudgets) {
                if (!mapStaffingBudget.containsKey(staffingBudget.staffingBudgetDate)) {
                    mapStaffingBudget.put(staffingBudget.staffingBudgetDate, staffingBudget);
                }
                else {
                    skedModels.staffingBudget existingStaffingBudget = mapStaffingBudget.get(staffingBudget.staffingBudgetDate);
                    integer existingStaffingBudgetPriority = map_type_priority.get(existingStaffingBudget.requestType);
                    integer staffingBudgetPriority = map_type_priority.get(staffingBudget.requestType);
                    if (staffingBudgetPriority > existingStaffingBudgetPriority) {
                        mapStaffingBudget.put(staffingBudget.staffingBudgetDate, staffingBudget);
                    }
                }
            }
            result.data = mapStaffingBudget.values();
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getUnavailabilityStatistic(getUnavailabilityStatisticRequest request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = (string)request.viewData.get('timezoneSidId');
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
			
            Date selectedDate = skedDateTimeUtils.getDateFromIsoString(request.selectedDate);
            skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            result.data = service.getUnavailabilityStatistics(request.resourceId, selectedDate);
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
            string timezoneSidId = (string)request.viewData.get('timezoneSidId');
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            skedDataService.saveResult saveResult = service.saveUnavailability(request.availability);
            result.data = saveResult.success == FALSE ? saveResult.returnedData : request.model;
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel verifyUnavailabilityBalance(verifyUnavailabilityBalanceRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string resourceId = request.unavailability.get(0).resourceId;
            
            sked__Resource__c skedResource = [SELECT Id, sked_Daily_Time_Off_Hours__c, sked_Employee_Id__c
                                              FROM sked__Resource__c
                                              WHERE Id = :resourceId];
            
            decimal resourceDailyTimeOffHours = 0;
            if (skedResource.sked_Daily_Time_Off_Hours__c != NULL) {
                resourceDailyTimeOffHours = skedResource.sked_Daily_Time_Off_Hours__c * 60;
            }
            
            string timezoneSidId = getResourceTimezonesidId(resourceId);
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
            
            skedStaffingBudgetService staffingBudgetService = (skedStaffingBudgetService) skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
            
            verifyUnavailabilityBalanceResultModel data = new verifyUnavailabilityBalanceResultModel();
            data.noOfRequestedHours = requestedDuration / 60;

            skedWorkdayApiManager.getTimeOffPlanBalancesResponse availableHoursResponse;
            if (skedSetting.instance.Admin.workdayIntegration) {
                skedWorkdayApiManager.getTimeOffPlanBalancesRequest availableHoursRequest = new skedWorkdayApiManager.getTimeOffPlanBalancesRequest();
                availableHoursRequest.employeeId = skedResource.sked_Employee_Id__c;
                availableHoursRequest.selectedYear = latestEndDate.year();
                availableHoursResponse = skedWorkdayApiManager.getTimeOffPlanBalances(availableHoursRequest);
                
                if (availableHoursResponse != null) {
                    if (timeOffType == skedConstants.UNAVAILABILITY_TYPE_PTO) {
                        data.noOfAvailableHours = availableHoursResponse.pto.hoursLeft;
                    } else if (timeOffType == skedConstants.UNAVAILABILITY_TYPE_FLOATING_HOLIDAY) {
                        data.noOfAvailableHours = availableHoursResponse.floatingHoliday.hoursLeft;
                    }
                }

                data.hasEnoughHours = data.noOfAvailableHours >= data.noOfRequestedHours;
            } else {
                data.hasEnoughHours = true;
            }

            if (data.hasEnoughHours) {
                staffingBudgetService.verifyStaffingBudget(resourceId, unavailabilityList);
            	data.unavailability = unavailabilityList;    
            }
            
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
            string timezoneSidId = (string)request.viewData.get('timezoneSidId');
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            Date startDate = skedDateTimeUtils.getDateFromIsoString(request.event.startDate);
            Date endDate = skedDateTimeUtils.getDateFromIsoString(request.event.endDate);
            
            Set<Date> inputDates = new Set<Date>();
            Date tempDate = startDate;
            while (tempDate <= endDate) {
                inputDates.add(tempDate);
                tempDate = tempDate.addDays(1);
            }
            
            sked__Resource__c skedResource = [SELECT Id, sked__Primary_Region__c, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                                              (SELECT Id, sked__Tag__r.Name
                                               FROM sked__ResourceTags__r
                                               WHERE sked__Tag__r.sked__Type__c = 'Role'
                                               AND sked_Start_Date__c <= :startDate
                                               AND (sked_Expiry_Date__c >= :endDate OR sked_Expiry_Date__c = NULL)
                                               ORDER BY sked__Tag__r.sked_Priority__c ASC
                                               LIMIT 1)
                                              FROM sked__Resource__c 
                                              WHERE Id = :request.event.resourceId];
            List<string> resourceTags = new List<string>();
            if (!skedResource.sked__ResourceTags__r.isEmpty()) {
                for (sked__Resource_Tag__c resourceTag : skedResource.sked__ResourceTags__r) {
                    resourceTags.add(resourceTag.sked__Tag__r.Name);
                }
            }
            
            Map<Date, sked_Staffing_Budget__c> mapStaffingBudgetDate = new Map<Date, sked_Staffing_Budget__c>();
            if (!resourceTags.isEmpty()) {
                string staffingBudgetQuery = 'SELECT Id, sked_Total_Slots__c, sked_Available_Slots__c, sked_Staffing_Budget_Date__c, sked_Request_Type__c, sked_Roles__c ';
                staffingBudgetQuery += 'FROM sked_Staffing_Budget__c ';
                staffingBudgetQuery += 'WHERE sked_Biomed_Collection_Op_Center__c = \'' +skedResource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c + '\' ';
                
                List<string> resourceTagClauses = new List<string>();
                for (string resourceTag : resourceTags) {
                    resourceTagClauses.add('sked_Roles__c INCLUDES(\'' + resourceTag + '\')');
                }
                staffingBudgetQuery += 'AND ( ' + string.join(resourceTagClauses, ' OR ') + ' ) ';
                List<sked_Staffing_Budget__c> staffingBudgets = (List<sked_Staffing_Budget__c>)Database.query(staffingBudgetQuery);
                
                if (staffingBudgets != NULL && !staffingBudgets.isEmpty()) {
                    for (sked_Staffing_Budget__c staffingBudget : staffingBudgets) {
                        mapStaffingBudgetDate.put(staffingBudget.sked_Staffing_Budget_Date__c, staffingBudget);
                    }
                }
            }
            
            Set<Id> resourceIds = new Set<Id>();
            resourceIds.add(request.event.resourceId);
            
            skedAvailabilityPatternService patternService = (skedAvailabilityPatternService)skedServiceFactory.instance.resolve('sked__Availability_Pattern__c');
            Map<Id, List<skedModels.event>> mapResourceTemplateEvents = patternService.getPatternEvents(resourceIds, inputDates);
            
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
                sked_Staffing_Budget__c skedStaffingBudget = mapStaffingBudgetDate.get(tempDate);
                
                if (allHolidays.contains(tempDate)) {
                    unavailability.unavailabilityType = 'holiday';
                }
                else if (!mapTempateEvents.containsKey(dateIso)) {
                    unavailability.unavailabilityType = 'non-working';
                }
                else if (skedStaffingBudget != NULL && skedStaffingBudget.sked_Request_Type__c == 'Unavailability Day') {
                    unavailability.unavailabilityType = 'unavailability-day';
                }
                else if (request.event.eventType != 'Sick') {
                    if (skedStaffingBudget == NULL) {
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
                    if (skedStaffingBudget != NULL) {
                        skedModels.staffingBudget staffingBudget = (skedModels.staffingBudget)skedAutoMapper.instance.mapTo(skedStaffingBudget, skedModels.staffingBudget.class);
                        data.staffingBudgets.add(staffingBudget);
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
    global static skedRemoteResultModel deleteAvailabilities(saveAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = (string)request.viewData.get('timezoneSidId');
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            for (skedModels.event event : request.events) {
                event.updateStartFinish(timezoneSidId);
            }

            skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            skedDataService.saveResult saveResult = service.deleteRecords(request.events);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
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
            if (request.event != NULL) {
                request.events = new List<skedModels.availability>();
                request.events.add(request.event);
            }
            skedSetting.instance.App.setTimezoneSidId(request.events.get(0).timezoneSidId);
            
            if (request.events != NULL && !request.events.isEmpty()) {
                for (skedModels.availability availability : request.events) {
                    availability.status = skedConstants.AVAILABILITY_STATUS_CANCELLED;
                }
            }

            skedAvailabilityService availabilityService = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
            availabilityService.requireConflictValidation = false;
            skedDataService.saveResult saveResult = availabilityService.saveRecords(request.events);
            result.data = saveResult.success == false ? saveResult.returnedData : request.events;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }

    /*********************************************************** Custom Availability methods ***********************************************/
    @remoteAction
    global static skedRemoteResultModel saveCustomAvailability(saveCustomAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = (string)request.viewData.get('timezoneSidId');
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
            string timezoneSidId = (string)request.viewData.get('timezoneSidId');
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            skedDataService.queryModelBase query = new skedDataService.queryModelBase();
            query.recordIds = new List<string>();
            query.recordIds.add(request.event.id);
            
            skedDataService service = (skedDataService)skedServiceFactory.instance.resolve('sked_Custom_Availability__c');
            List<skedModels.customAvailability> models = (List<skedModels.customAvailability>)service.getList(query);
            
            availabilityDetailsModel data = new availabilityDetailsModel();
            data.event = models.get(0);
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel deleteCustomAvailability(saveCustomAvailabilityRequestModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        SavePoint sp = Database.setSavepoint();
        try {
            string timezoneSidId = (string)request.viewData.get('timezoneSidId');
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            skedDataService service = (skedDataService)skedServiceFactory.instance.resolve('sked_Custom_Availability__c');
            skedDataService.saveResult saveResult = service.deleteRecord(request.event);
            result.data = saveResult.success == false ? saveResult.returnedData : NULL;
        }
        catch (Exception ex) {
            result.getError(ex, sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getResourceCustomAvailabilityData(getResourceCustomAvailabilityModel request) {
        skedRemoteResultModel result = new skedRemoteResultModel(request.viewData);
        try {
            string timezoneSidId = (string)request.viewData.get('timezoneSidId');
            skedSetting.instance.App.setTimezoneSidId(timezoneSidId);

            resourceDataModel data = new resourceDataModel();
            data.today = system.now().format(skedDateTimeUtils.DATE_ISO_FORMAT, timezoneSidId);

            Date startDate = skedDateTimeUtils.getDateFromIsoString(request.startDate);
            Date endDate = skedDateTimeUtils.getDateFromIsoString(request.endDate);
            DateTime startTime = skedDateTimeUtils.getStartOfDate(startDate, timezoneSidId);
            DateTime endTime = skedDateTimeUtils.getEndOfDate(endDate, timezoneSidId);

            skedDataService service = (skedDataService)skedServiceFactory.instance.resolve('sked_Custom_Availability__c');
            skedDataService.queryModelBase query = new skedDataService.queryModelBase();
            skedQueryBuilder customAvailabilityBuilder = query.getQueryBuilder('sked_Custom_Availability__c');
            customAvailabilityBuilder.addCondition('sked_Resource__c = {0}', request.resourceId);
            customAvailabilityBuilder.addCondition('sked_Start__c < {0}', endTime);
            customAvailabilityBuilder.addCondition('sked_Finish__c > {0}', startTime);
            customAvailabilityBuilder.orderClause = 'ORDER BY sked_Start__c ASC';

            List<skedModels.customAvailability> customAvailabilities = (List<skedModels.customAvailability>)service.getList(query);
            data.customAvailabilities = customAvailabilities;
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    /*********************************************************** Private methods ***********************************************************/
    private static string getResourceTimezonesidId(string resourceId) {
        List<sked__Resource__c> resources = [SELECT Id, sked__Primary_Region__r.sked__Timezone__c
                                            FROM sked__Resource__c
                                            WHERE Id = :resourceId];
        if (resources == NULL || resources.isEmpty()) {
            return UserInfo.getTimeZone().getID();
        }
        return resources.get(0).sked__Primary_Region__r.sked__Timezone__c;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    global class initializeRequestModel extends skedRemoteRequestModel {
        public string resourceId;
    }

    global class getPendingAvailabilityRequest extends getDataRequestModel {
        public string endDate;
        public string resourceId;
        public string startDate;
    }
    
    global class getStaffingBudgetRequest extends getDataRequestModel {
        public string endDate;
        public string resourceId;
        public string startDate;
    }
    
    global class getUnavailabilityStatisticRequest extends getDataRequestModel {
        public string resourceId;
        public string selectedDate;
    }
    
    global class saveAvailabilityRequestModel extends saveRequestModel {
        public skedModels.availability event;
        public List<skedModels.availability> events;
        public string deleteAction;// allMember, outTeam;
    }
    
    global class saveUnavailabilityRequestModel extends saveRequestModel {
        public List<skedModels.availability> availability;
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
    
    global class verifyUnavailabilityBalanceResultModel {
        public boolean hasEnoughHours;
        public decimal noOfAvailableHours;
        public decimal noOfRequestedHours;
        public List<skedModels.availability> unavailability;
    }
    
    global class availabilityDataModel {
        public object availabilityData;
    }

    global class saveCustomAvailabilityRequestModel extends saveRequestModel {
        public skedModels.customAvailability event;
    }

    global class getCustomAvailabilityDetailsRequest extends skedRemoteRequestModel {
        public skedModels.customAvailability event;
    }

    global class getResourceCustomAvailabilityModel extends getDataRequestModel {
        public string resourceId;
        public string endDate;
        public string startDate;
    }

    global class availabilityDetailsModel {
        public object event;
    }

    global class resourceDataModel {
        public object customAvailabilities;
        public string today;
    }
    
}