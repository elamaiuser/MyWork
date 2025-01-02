public class skedStaffingBudgetSiteService extends skedDataService {
    
    protected override void initialize() {
        this.sObjectApiName = 'sked_Staffing_Budget_Site__c';
        this.objectType = 'staffingBudgetSite';
        this.domainType = Type.forName('skedModels.staffingBudgetSite');
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
        if (query.siteIds != NULL && !query.siteIds.isEmpty()) {
            queryBuilder.addCondition('sked_Location__c IN {0}', query.siteIds);
        }
        if (query.staffingBudgetIds != NULL && !query.staffingBudgetIds.isEmpty()) {
            queryBuilder.addCondition('sked_Staffing_Budget__c IN {0}', query.staffingBudgetIds);
        }
        if (query.siteCoIds != NULL && !query.siteCoIds.isEmpty()) {
            queryBuilder.addCondition('sked_Specific_Collection_Operation__c IN {0}', query.siteCoIds);
        }
        if (query.requestTypes != NULL && !query.requestTypes.isEmpty()) {
            queryBuilder.addCondition('sked_Staffing_Budget__r.sked_Request_Type__c IN {0}', query.requestTypes);
        }
        if (query.isBiddingPeriodRequest) {
            queryBuilder.addCondition('(sked_Staffing_Budget__r.sked_Pending_Slots_Rollup__c > 0 OR sked_Staffing_Budget__r.sked_Approved_Slots_Rollup__c > 0 OR sked_Staffing_Budget__r.sked_Wait_List_Slots_Rollup__c > 0)');
        }
        if (startDate != NULL) {
            queryBuilder.addCondition('sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c >= {0}', startDate);
        }
        if (endDate != NULL) {
            queryBuilder.addCondition('sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c <= {0}', endDate);
        }
    }

    public class queryModel extends skedEventService.queryModel {
        public List<String> siteIds;
        public List<String> staffingBudgetIds;
        public List<String> siteCoIds;
        public List<string> requestTypes;
        public string endDate;
        public string startDate;
        public boolean isBiddingPeriodRequest = false;
    }
}