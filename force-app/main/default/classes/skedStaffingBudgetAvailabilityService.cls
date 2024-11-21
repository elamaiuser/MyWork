public with sharing class skedStaffingBudgetAvailabilityService extends skedDataService {

    protected override void initialize() {
        this.sObjectApiName = 'sked_Staffing_Budget_Availability__c';
        this.objectType = 'staffingBudgetAvailability';
        this.domainType = Type.forName('skedModels.staffingBudgetAvailability');
    }

    protected override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;

        if (query.availabilityStatuses != NULL && !query.availabilityStatuses.isEmpty()) {
            queryBuilder.addCondition('sked_Availability__r.sked_Custom_Status__c IN {0}', query.availabilityStatuses);
        }

        if (query.recurringScheduleIds != NULL && !query.recurringScheduleIds.isEmpty()) {
            queryBuilder.addCondition('sked_Availability__r.sked_Recurring_Schedule__c IN {0}', query.recurringScheduleIds);
        }

        if (query.availabilityIds != NULL && !query.availabilityIds.isEmpty()) {
            queryBuilder.addCondition('sked_Availability__c IN {0}', query.availabilityIds);
        }

        if (query.staffingBudgetIds != NULL && !query.staffingBudgetIds.isEmpty()) {
            queryBuilder.addCondition('sked_Staffing_Budget__c IN {0}', query.staffingBudgetIds);
        }

        if (query.hideRecordsOutsideBiddingPeriod) {
            queryBuilder.addCondition('sked_Created_Inside_Bidding_Period__c = TRUE');
        }
    }

    public class queryModel extends skedEventService.queryModel {
        public List<string> availabilityStatuses;
        public List<String> availabilityIds;
        public List<String> staffingBudgetIds;
        public List<String> recurringScheduleIds;
        public Boolean hideRecordsOutsideBiddingPeriod = false;
    }

}