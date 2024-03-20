global class skedResourceTagService extends skedDataService {

    /*********************************************************** Protected ***********************************************************/
    protected virtual override void initialize() {
        this.sObjectApiName = 'sked__Resource_Tag__c';
        this.objectTYpe = 'resourceTag';
        this.domainType = Type.forName('skedModels.resourceTag');
    }
    
    protected virtual override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        if (query.tagIds != NULL && !query.tagIds.isEmpty()) {
            queryBuilder.addCondition('sked__Tag__c IN {0}', query.tagIds);
        }
    }
    
    /*********************************************************** Public ***********************************************************/
    public List<string> getResourceIdsByTagIds(List<string> tagIds) {
        List<string> results = new List<string>();
        queryModel query = new queryModel();
        query.tagIds = tagIds;
        List<sked__Resource_Tag__c> skedResourceTags = (List<sked__Resource_Tag__c>)query(query);
        
        Set<string> resourceIds = new Set<string>();
        for (sked__Resource_Tag__c skedResourceTag : skedResourceTags) {
            resourceIds.add(skedResourceTag.sked__Resource__c);
        }
        results.addAll(resourceIds);
        
        return results;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    global class queryModel extends skedDataService.queryModelBase {
        public List<string> tagIds;
    }
    
}