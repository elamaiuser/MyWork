global class skedTerritoryService extends skedDataService {
    
    protected override void initialize() {
        this.sObjectApiName = 'sked_Territory__c';
        this.objectTYpe = 'territory';
        this.domainType = Type.forName('skedModels.territory');
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
        
        List<String> excludedCONames = new List<String>{skedConstants.NON_COLLECTION_AREA_CO};
        skedQueryBuilder territoryCollectionOperationBuilder = query.getQueryBuilder('sked_Territory_Collection_Operation__c');
        if (startDate != NULL && endDate != NULL) {
            territoryCollectionOperationBuilder.addCondition('(sked_Start_Date__c = NULL OR sked_Start_Date__c <= {0})', endDate);
            territoryCollectionOperationBuilder.addCondition('(sked_End_Date__c = NULL OR sked_End_Date__c >= {0})', startDate);
        }
        territoryCollectionOperationBuilder.addCondition('sked_Collection_Operation__r.sked_Is_Deactivated__c = FALSE');
        territoryCollectionOperationBuilder.addCondition('sked_Collection_Operation__r.Name NOT IN {0}', excludedCONames);
        
        queryBuilder.addCondition('Name NOT IN {0}', excludedCONames);
    }
    
    /*********************************************************** Nested class ***********************************************************/
    public class queryModel extends skedDataService.queryModelBase {
        public string endDate;
        public string startDate;
    }

}