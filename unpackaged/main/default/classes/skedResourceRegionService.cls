global class skedResourceRegionService extends skedDataService {

    /*********************************************************** Protected ***********************************************************/
    protected virtual override void initialize() {
        this.sObjectApiName = 'sked__Resource_Region__c';
        this.objectTYpe = 'resourceRegion';
        this.domainType = Type.forName('skedModels.resourceRegion');
    }
    
    protected virtual override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        if (query.biomedCollectionOpIds != NULL && !query.biomedCollectionOpIds.isEmpty()) {
            queryBuilder.addCondition('sked__Region__r.sked_Biomed_Collection_Op_Center__c IN {0}', query.biomedCollectionOpIds);
        }
        if (query.regionIds != NULL && !query.regionIds.isEmpty()) {
            queryBuilder.addCondition('sked__Region__c IN {0}', query.regionIds);
        }
        if (query.startTime != NULL && query.endTime != NULL) {
            string condition = '( (sked__Start__c = NULL AND sked__End__c = NULL) OR (sked__Start__c != NULL AND sked__End__c = NULL AND sked__Start__c <= {1}) OR (sked__Start__c <= {1} AND sked__End__c >= {0}) )';
            condition = condition.replace('{0}', Json.serialize(query.startTime).replace('"', ''));
            condition = condition.replace('{1}', Json.serialize(query.endTime).replace('"', ''));

            queryBuilder.addCondition(condition);
        }
    }
    
    /*********************************************************** Public ***********************************************************/
    public List<string> getResourceIds(queryModel query) {
        List<string> results = new List<string>();
        
        List<sked__Resource_Region__c> skedResourceRegions = (List<sked__Resource_Region__c>)query(query);
        
        Set<string> resourceIds = new Set<string>();
        for (sked__Resource_Region__c skedResourceRegion : skedResourceRegions) {
            resourceIds.add(skedResourceRegion.sked__Resource__c);
        }
        results.addAll(resourceIds);
        
        return results;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    global class queryModel extends skedDataService.queryModelBase {
        public List<string> biomedCollectionOpIds;
        public DateTime endTime;
        public List<string> regionIds;
        public DateTime startTime;
    }
    
}