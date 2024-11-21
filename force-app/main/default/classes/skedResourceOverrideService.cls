global class skedResourceOverrideService extends skedDataService {

    /*********************************************************** Protected ***********************************************************/
    protected virtual override void initialize() {
        this.sObjectApiName = 'sked__Resource_Override__c';
        this.objectTYpe = 'resourceOverride';
        this.domainType = Type.forName('skedModels.resourceOverride');
    }
    
    protected virtual override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        if (query.biomedCollectionOpIds != NULL && !query.biomedCollectionOpIds.isEmpty()) {
            queryBuilder.addCondition('sked_Collection_Operation__c IN {0}', query.biomedCollectionOpIds);
        }
        if (query.startDate != NULL && query.endDate != NULL) {
            queryBuilder.addCondition('sked_Start_Date__c <= {0}', query.endDate);
            queryBuilder.addCondition('sked_End_Date__c >= {0}', query.startDate);
        }
    }
    
    /*********************************************************** Public ***********************************************************/
    public List<string> getResourceIds(queryModel query) {
        List<string> results = new List<string>();
        
        List<sked__Resource_Override__c> skedResourceOverrides = (List<sked__Resource_Override__c>)query(query);
        
        Set<string> resourceIds = new Set<string>();
        for (sked__Resource_Override__c skedResourceOverride : skedResourceOverrides) {
            resourceIds.add(skedResourceOverride.sked__Resource__c);
        }
        results.addAll(resourceIds);
        
        return results;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    global class queryModel extends skedDataService.queryModelBase {
        public List<string> biomedCollectionOpIds;
        public Date endDate;
        public Date startDate;
    }
    
}