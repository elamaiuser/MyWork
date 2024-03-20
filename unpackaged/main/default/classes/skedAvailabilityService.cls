global class skedAvailabilityService extends skedEventService {
    
    public Boolean requireConflictValidation;
    
    protected override void initialize() {
        this.sObjectApiName = 'sked__Availability__c';
        this.objectTYpe = 'availability';
        this.domainType = Type.forName('skedModels.availability');
        this.requireConflictValidation = false;
    }
    
    protected override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        Date startDate, endDate;
        if (!string.isBlank(query.startDate)) {
            startDate = skedDateTimeUtils.getDateFromIsoString(query.startDate);
        }
        if (!string.isBlank(query.endDate)) {
            endDate = skedDateTimeUtils.getDateFromIsoString(query.endDate);
        }

        if (query.roles != NULL && !query.roles.isEmpty()) {
            queryBuilder.addCondition('sked__Resource__r.sked_Roles__c INCLUDES {0}', query.roles);
        }
        if (query.biomedCollectionOpIds != NULL && !query.biomedCollectionOpIds.isEmpty()) {
            queryBuilder.addCondition('sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN {0}', query.biomedCollectionOpIds);
        }
        if (query.regionIds != NULL && !query.regionIds.isEmpty()) {
            queryBuilder.addCondition('sked__Resource__r.sked__Primary_Region__c IN {0}', query.regionIds);
        }
        if (query.resourceIds != NULL && !query.resourceIds.isEmpty()) {
            queryBuilder.addCondition('sked__Resource__c IN {0}', query.resourceIds);
        }
        if (query.resourceCategories != NULL && !query.resourceCategories.isEmpty()) {
            queryBuilder.addCondition('sked__Resource__r.sked__Category__c IN {0}', query.resourceCategories);
        }
        if (query.availabilityStatuses != NULL && !query.availabilityStatuses.isEmpty()) {
            queryBuilder.addCondition('sked_Custom_Status__c IN {0}', query.availabilityStatuses);
        }
        if (query.requestTypes != NULL && !query.requestTypes.isEmpty()) {
            queryBuilder.addCondition('sked_Staffing_Budget__r.sked_Request_Type__c IN {0}', query.requestTypes);
        }
        if (query.isAvailable != null) {
            queryBuilder.addCondition('sked__Is_Available__c = {0}', query.isAvailable);
        }
        if (query.isException != null) {
            queryBuilder.addCondition('sked_Is_Exception__c = {0}', query.isException);
        }
        if (query.recurringScheduleIds != NULL && !query.recurringScheduleIds.isEmpty()) {
            queryBuilder.addCondition('sked_Recurring_Schedule__c IN {0}', query.recurringScheduleIds);
        }
        if (query.startTime != NULL && query.endTime != NULL) {
            queryBuilder.addCondition('sked__Start__c < {0}', query.endTime);
            queryBuilder.addCondition('sked__Finish__c > {0}', query.startTime);
        }
        else {
            if (query.startTime != NULL) {
                queryBuilder.addCondition('sked__Start__c >= {0}', query.startTime);
            }
            if (query.endTime != NULL) {
                queryBuilder.addCondition('sked__Finish__c <= {0}', query.endTime);
            }
        }
        if (startDate != NULL && endDate != NULL) {
            queryBuilder.addCondition('sked_Start_Date__c <= {0}', endDate);
            queryBuilder.addCondition('sked_Finish_Date__c >= {0}', startDate);
        }
        else {
            if (startDate != NULL) {
                queryBuilder.addCondition('sked_Start_Date__c >= {0}', startDate);
            }
            if (endDate != NULL) {
                queryBuilder.addCondition('sked_Finish_Date__c <= {0}', endDate);
            }
        }
        queryBuilder = query.getQueryBuilder('sked__Availability__c');
        inputModel.orderBy = string.isBlank(inputModel.orderBy) ? 'sked__Start__c' : inputModel.orderBy;
        inputModel.orderAscending = string.isBlank(inputModel.orderAscending) ? 'ASC' : inputModel.orderAscending;
        queryBuilder.orderClause = 'ORDER BY ' + inputModel.orderBy + ' ' + inputModel.orderAscending;
        
        if (query.includes(skedSObjectType.EXCEPTION_LOG)) {
            skedQueryBuilder exceptionLogBuilder = query.getQueryBuilder('skedHC__Exception__c');
        }

        if (query.includes(skedSObjectType.STAFFING_BUDGET_AVAILABILITY)) {
            skedQueryBuilder staffingBudgetAvailabilityBuilder = query.getQueryBuilder('sked_Staffing_Budget_Availability__c');
        }
    }
    
    public skedDataService.saveResult saveUnavailability(List<skedModels.availability> availabilityList) {
        string timezoneSidId = skedSetting.instance.App.timezoneSidId;
        
        for (skedModels.availability availability : availabilityList) {
            availability.updateStartFinish(timezoneSidId);
            availability.bypassAutoApprovalProcess = true;
            availability.status = availability.action == 'approve' ? skedConstants.AVAILABILITY_STATUS_APPROVED 
                : (availability.action == 'decline' ? skedConstants.AVAILABILITY_STATUS_DECLINED : 
                   (availability.action == 'waitlist' ? skedConstants.AVAILABILITY_STATUS_WAITLIST : skedConstants.AVAILABILITY_STATUS_PENDING));
                
            if (availability.status != skedConstants.AVAILABILITY_STATUS_PENDING) {
                availability.approvedViaAutomation = true;
            }
        }
        return this.saveRecords(availabilityList);
    }

    public List<skedModels.unavailabilityStatistic> getUnavailabilityStatistics(String resourceId, Date selectedDate) {
        List<skedModels.unavailabilityStatistic> stats = new List<skedModels.unavailabilityStatistic>();
        if (skedSetting.instance.Admin.workdayIntegration) {
            sked__Resource__c skedResource = [
                SELECT Id, sked_Employee_ID__c 
                FROM sked__Resource__c 
                WHERE Id = :resourceId
            ];
    
            skedWorkdayApiManager.getTimeOffPlanBalancesRequest balanceReq = new skedWorkdayApiManager.getTimeOffPlanBalancesRequest();
            balanceReq.employeeId = skedResource.sked_Employee_ID__c;
            balanceReq.selectedYear = selectedDate.year();
            skedWorkdayApiManager.getTimeOffPlanBalancesResponse balanceResponse = skedWorkdayApiManager.getTimeOffPlanBalances(balanceReq);
    
            skedWorkdayApiManager.getTimeOffReportRequest timeOffReportReq = new skedWorkdayApiManager.getTimeOffReportRequest();
            timeOffReportReq.employeeId = skedResource.sked_Employee_ID__c;
            timeOffReportReq.selectedYear = selectedDate.year();
            skedWorkdayApiManager.getTimeOffReportResponse timeOffReportResponse = skedWorkdayApiManager.getTimeOffReport(timeOffReportReq);
    
            if (timeOffReportResponse != NULL && timeOffReportResponse.timeOffReports != NULL) {
                for (skedWorkdayApiManager.timeOffReport tor : timeOffReportResponse.timeOffReports) {
                    if (tor.timeOffType.contains(skedConstants.UNAVAILABILITY_TYPE_PTO)) {
                        balanceResponse.pto.hoursLeft -= tor.amount;
                        if (System.today() >= tor.timeOffDate) {
                            balanceResponse.pto.taken += tor.amount;
                        } else {
                            balanceResponse.pto.approved += tor.amount;
                        }
                    } else if (tor.timeOffType.contains(skedConstants.UNAVAILABILITY_TYPE_FLOATING_HOLIDAY)) {
                        balanceResponse.floatingHoliday.hoursLeft -= tor.amount;
                        if (System.today() >= tor.timeOffDate) {
                            balanceResponse.floatingHoliday.taken += tor.amount;
                        } else {
                            balanceResponse.floatingHoliday.approved += tor.amount;
                        }
                    }   
                }
            }
    
            skedModels.unavailabilityStatistic pto = new skedModels.unavailabilityStatistic();
            pto.label = skedConstants.UNAVAILABILITY_TYPE_PTO;
            pto.year = selectedDate.year();
            if (balanceResponse != NULL && balanceResponse.pto != NULL) {
                pto.takenHours = balanceResponse.pto.taken;
                pto.approvedHours = balanceResponse.pto.approved;
                pto.hoursLeft = balanceResponse.pto.hoursLeft;
            }
            stats.add(pto);
    
            skedModels.unavailabilityStatistic floatingHoliday = new skedModels.unavailabilityStatistic();
            floatingHoliday.label = skedConstants.UNAVAILABILITY_TYPE_FLOATING_HOLIDAY;
            floatingHoliday.year = selectedDate.year();
            if (balanceResponse != NULL && balanceResponse.floatingHoliday != NULL) {
                floatingHoliday.takenHours = balanceResponse.floatingHoliday.taken;
                floatingHoliday.approvedHours = balanceResponse.floatingHoliday.approved;
                floatingHoliday.hoursLeft = balanceResponse.floatingHoliday.hoursLeft;
            }
            stats.add(floatingHoliday);
        } else {
            skedModels.unavailabilityStatistic pto = new skedModels.unavailabilityStatistic();
            pto.label = skedConstants.UNAVAILABILITY_TYPE_PTO;
            pto.year = selectedDate.year();
            pto.takenHours = 0;
            pto.approvedHours = 0;
            pto.hoursLeft = 100;
            stats.add(pto);
    
            skedModels.unavailabilityStatistic floatingHoliday = new skedModels.unavailabilityStatistic();
            floatingHoliday.label = skedConstants.UNAVAILABILITY_TYPE_FLOATING_HOLIDAY;
            floatingHoliday.year = selectedDate.year();
            floatingHoliday.takenHours = 0;
            floatingHoliday.approvedHours = 0;
            floatingHoliday.hoursLeft = 100;
            stats.add(floatingHoliday);
        }

        return stats;
    }

    /*********************************************************** Nested classes ***********************************************************/
    public class queryModel extends skedEventService.queryModel {
        public List<string> availabilityStatuses;
        public List<string> biomedCollectionOpIds;
        public boolean isAvailable;
        public boolean isException;
        public List<string> regionIds;
        public List<string> resourceCategories;
        public List<string> roles;
        public List<string> statuses;
        public List<string> requestTypes;
    }

}