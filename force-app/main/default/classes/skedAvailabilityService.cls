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
        Date startDate, endDate, submissionStartDate, submissionEndDate;
        if (!string.isBlank(query.startDate)) {
            startDate = skedDateTimeUtils.getDateFromIsoString(query.startDate);
        }
        if (!string.isBlank(query.endDate)) {
            endDate = skedDateTimeUtils.getDateFromIsoString(query.endDate);
        }
        if (!string.isBlank(query.submissionStartDate)) {
            submissionStartDate = skedDateTimeUtils.getDateFromIsoString(query.submissionStartDate);
        }
        if (!string.isBlank(query.submissionEndDate)) {
            submissionEndDate = skedDateTimeUtils.getDateFromIsoString(query.submissionEndDate);
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
        if (query.availabilityTypes != NULL && !query.availabilityTypes.isEmpty()) {
            queryBuilder.addCondition('sked__Type__c IN {0}', query.availabilityTypes);
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
        //----------//HRP-16778-----------start
        if (query.isCalloutRelated != null && query.isCalloutRelated) {
            queryBuilder.addCondition('sked_Related_Call_Out__r.sked__Type__c = {0}', query.availabilityTypeCallout);
        }
        else{
            queryBuilder.addCondition('sked_Related_Call_Out__r.sked__Type__c != {0}', query.availabilityTypeCallout);
        }
        //----------//HRP-16778-----------end
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

        if (submissionStartDate != NULL) {
            queryBuilder.addCondition('DAY_ONLY(CreatedDate) >= {0}', submissionStartDate);
        }
        if (submissionEndDate != NULL) {
            queryBuilder.addCondition('DAY_ONLY(CreatedDate) <= {0}', submissionEndDate);
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
        Set<String> workdayIntegratedTypes = skedWorkdayUtils.getUnavailabilityTypesToSync();
        string timezoneSidId = skedSetting.instance.App.timezoneSidId;
        Integer numRecurringSchedules = availabilityList.size() > 1 ? 1 : 0;
        
        if (availabilityList.size() > 1) {
            availabilityList.sort();
            for (Integer i = 0; i < availabilityList.size(); i++) {
                if (i > 0) {
                    skedModels.availability availability = availabilityList[i];
                    skedModels.availability prevAvailability = availabilityList[i-1];

                    Date availabilityStartDate = skedDateTimeUtils.getDateFromIsoString(availability.startDate);
                    Date prevAvailabilityStartDate = skedDateTimeUtils.getDateFromIsoString(prevAvailability.startDate);

                    if (prevAvailabilityStartDate.daysBetween(availabilityStartDate) > 1) {
                        numRecurringSchedules++;
                    }
                }
            }
        }

        List<sked__Recurring_Schedule__c> recurringSchedules = new List<sked__Recurring_Schedule__c>();
        for (Integer i = 0; i < numRecurringSchedules; i++) {
            recurringSchedules.add(new sked__Recurring_Schedule__c());
        }
        
        if (numRecurringSchedules > 0) {
            insert recurringSchedules;
        }

        Integer currentRecurringScheduleIdx = 0;
        for (Integer i = 0; i < availabilityList.size(); i++) {
            skedModels.availability availability = availabilityList[i];
            availability.updateStartFinish(timezoneSidId);
            availability.bypassAutoApprovalProcess = true;
            
            if (availabilityList.size() > 1) {
                if (i > 0) {
                    skedModels.availability prevAvailability = availabilityList[i-1];

                    Date availabilityStartDate = skedDateTimeUtils.getDateFromIsoString(availability.startDate);
                    Date prevAvailabilityStartDate = skedDateTimeUtils.getDateFromIsoString(prevAvailability.startDate);

                    if (prevAvailabilityStartDate.daysBetween(availabilityStartDate) > 1) {
                        currentRecurringScheduleIdx++;
                    }
                }
                sked__Recurring_Schedule__c recurringSchedule = recurringSchedules.get(currentRecurringScheduleIdx);
                availability.scheduleId = recurringSchedule.Id;
            }
            
            if (availability.status == skedConstants.AVAILABILITY_STATUS_APPROVED && workdayIntegratedTypes.contains(availability.eventType)) {
                availability.status = skedConstants.AVAILABILITY_STATUS_PROCESSING_APPROVAL;
            }
        }
        return this.saveRecords(availabilityList);
    }

    public skedWorkdayGetPlanBalanceResponse getUnavailabilityStatistics(String resourceId, Date selectedDate) {
        return getUnavailabilityStatistics(resourceId, selectedDate, false);
    }

    public skedWorkdayGetPlanBalanceResponse getUnavailabilityStatistics(String resourceId, Date selectedDate, Boolean isCallOut) {
        sked__Resource__c skedResource = [
            SELECT Id, sked_Employee_ID__c 
            FROM sked__Resource__c 
            WHERE Id = :resourceId
        ];
        skedWorkdayGetPlanBalanceResponse balanceResponse;
        if (skedSetting.instance.Admin.workdayIntegration) {
            skedWorkdayGetPlanBalanceRequest balanceReq = new skedWorkdayGetPlanBalanceRequest();
            balanceReq.employeeId = skedResource.sked_Employee_ID__c;
            balanceReq.selectedDate = selectedDate;
            balanceReq.resourceId = skedResource.Id;
            balanceReq.isCallOut = isCallOut;
            balanceResponse = skedWorkdayApiManager.getTimeOffPlanBalances(balanceReq);
        } else {
            List<skedWorkdayGetPlanBalanceResponse.timeOffReason> timeOffReasons = new List<skedWorkdayGetPlanBalanceResponse.timeOffReason>();
            timeOffReasons.add(new skedWorkdayGetPlanBalanceResponse.timeOffReason('Unplanned', 'Unplanned', false));
            if (!isCallOut) {
                timeOffReasons.add(new skedWorkdayGetPlanBalanceResponse.timeOffReason('Planned', 'Planned', false));
            }

            Map<String, skedWorkdayGetPlanBalanceResponse.timeOffPlan> timeOffPlansByLabel = new Map<String, skedWorkdayGetPlanBalanceResponse.timeOffPlan>();
            skedWorkdayGetPlanBalanceResponse.timeOffPlan ptoPlan = new skedWorkdayGetPlanBalanceResponse.timeOffPlan('PTO', 200);
            ptoPlan.timeOffReasons.addAll(timeOffReasons);
            skedWorkdayGetPlanBalanceResponse.timeOffPlan fhPlan = new skedWorkdayGetPlanBalanceResponse.timeOffPlan('Floating Holiday', 200);
            fhPlan.timeOffReasons.addAll(timeOffReasons);

            balanceResponse = new skedWorkdayGetPlanBalanceResponse(null);
            balanceResponse.timeOffPlansByLabel.put('PTO', ptoPlan);
            balanceResponse.timeOffPlansByLabel.put('Floating Holiday', fhPlan);
        }

        return balanceResponse;
    }

    public void verifyResourceAvailability(String resourceId, List<skedModels.availability> unavailabilityList) {
        Set<Date> unavailabilityDates = new Set<Date>();
        for (skedModels.availability unavailability : unavailabilityList) {
            Date unavailabilityDate = skedDateTimeUtils.getDateFromIsoString(unavailability.startDate);
            unavailabilityDates.add(unavailabilityDate);
        }

        List<sked__Job_Allocation__c> jobAllocations = [
            SELECT Id
            FROM sked__Job_Allocation__c
            WHERE sked_Start_Date__c IN :unavailabilityDates
            AND sked__Resource__c = :resourceId
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
        ];

        if (!jobAllocations.isEmpty()) {
            for (skedModels.availability unavailability : unavailabilityList) {
                unavailability.status = skedConstants.AVAILABILITY_STATUS_PENDING;
                unavailability.approvalReason = 'Requested Date(s) overlap with scheduled Blood Drive';
            }
        }
    }

    public void setDefaultStatusesForUnavailabilities(Boolean hasEnoughHours, List<skedModels.availability> unavailabilityList) {
        for (skedModels.availability unavailability : unavailabilityList) {
            if (!hasEnoughHours && unavailability.eventType == skedConstants.UNAVAILABILITY_TYPE_SICK) {
                unavailability.status = skedConstants.AVAILABILITY_STATUS_PENDING;
                unavailability.approvalReason = 'Insufficient Sick Balance for this request. Approval Required.';
            } else if (unavailability.eventType == skedConstants.UNAVAILABILITY_TYPE_PERSONAL) {
                unavailability.status = skedConstants.AVAILABILITY_STATUS_PENDING;
            }
        }
    }

    /*********************************************************** Nested classes ***********************************************************/
    public class queryModel extends skedEventService.queryModel {
        public List<string> availabilityStatuses;
        public List<string> availabilityTypes;
        public List<string> biomedCollectionOpIds;
        public boolean isAvailable;
        public boolean isException;
        public List<string> regionIds;
        public List<string> resourceCategories;
        public List<string> roles;
        public List<string> statuses;
        public string submissionEndDate;
        public string submissionStartDate;
        public List<string> requestTypes;
        public Boolean isCalloutRelated;//HRP-16778
        public String availabilityTypeCallout;//HRP-16778
    }

}