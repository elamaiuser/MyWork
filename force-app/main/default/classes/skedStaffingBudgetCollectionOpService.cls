public class skedStaffingBudgetCollectionOpService extends skedDataService {
    
    protected override void initialize() {
        this.sObjectApiName = 'sked_Staffing_Budget_Collection_Op__c';
        this.objectType = 'staffingBudgetCollectionOp';
        this.domainType = Type.forName('skedModels.staffingBudgetCollectionOp');
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

        if (query.collectionOpIds != NULL && !query.collectionOpIds.isEmpty()) {
            queryBuilder.addCondition('sked_Biomed_Collection_Operation__c IN {0}', query.collectionOpIds);
        }
        if (query.staffingBudgetIds != NULL && !query.staffingBudgetIds.isEmpty()) {
            queryBuilder.addCondition('sked_Staffing_Budget__c IN {0}', query.staffingBudgetIds);
        }
        if (query.requestTypes != NULL && !query.requestTypes.isEmpty()) {
            queryBuilder.addCondition('sked_Staffing_Budget__r.sked_Request_Type__c IN {0}', query.requestTypes);
        }
        if (startDate != NULL) {
            queryBuilder.addCondition('sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c >= {0}', startDate);
        }
        if (endDate != NULL) {
            queryBuilder.addCondition('sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c <= {0}', endDate);
        }
        if (query.isBiddingPeriodRequest) {
            queryBuilder.addCondition('(sked_Staffing_Budget__r.sked_Pending_Slots_Rollup__c > 0 OR sked_Staffing_Budget__r.sked_Approved_Slots_Rollup__c > 0 OR sked_Staffing_Budget__r.sked_Wait_List_Slots_Rollup__c > 0)');
        }
}

    public class queryModel extends skedEventService.queryModel {
        public List<String> collectionOpIds;
        public string endDate;
        public List<string> requestTypes;
        public List<String> staffingBudgetIds;
        public string startDate;
        public boolean isBiddingPeriodRequest = false;
    }
}