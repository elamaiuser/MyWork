public class skedCollectionOpTimeBlockService extends skedDataService {
    
    protected override void initialize() {
        this.sObjectApiName = 'Collection_Operation_Time_Block__c';
        this.objectType = 'collectionOperationTimeBlock';
        this.domainType = Type.forName('skedModels.collectionOperationTimeBlock');
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
        
        if (query.collectionOperationIds != NULL && !query.collectionOperationIds.isEmpty()) {
            queryBuilder.addCondition('Collection_Operation__c IN {0}', query.collectionOperationIds);
        }
        if (startDate != NULL && endDate != NULL) {
            queryBuilder.addCondition('Effective_End_Date__c >= {0}', startDate);
            queryBuilder.addCondition('Effective_Start_Date__c <= {0}', endDate);
        }
    }
    
    public class queryModel extends skedEventService.queryModel {
        public List<String> collectionOperationIds;
        public string endDate;
        public string startDate;
    }
    
}