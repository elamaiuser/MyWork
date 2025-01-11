global class skedRegionService extends skedEventService {
    
    protected override void initialize() {
        this.sObjectApiName = 'sked__Region__c';
        this.objectTYpe = 'region';
        this.domainType = Type.forName('skedModels.region');
    }
    
    protected override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        if (!string.isBlank(query.biomedCollectionOpId)) {
            queryBuilder.addCondition('sked_Biomed_Collection_Op_Center__c = {0}', query.biomedCollectionOpId);
        }
        if (query.biomedCollectionOpIds != NULL && !query.biomedCollectionOpIds.isEmpty()) {
            queryBuilder.addCondition('sked_Biomed_Collection_Op_Center__c IN {0}', query.biomedCollectionOpIds);
        }
        if (!string.isBlank(query.timezoneSidId)) {
            queryBuilder.addCondition('sked__Timezone__c = {0}', query.timezoneSidId);
        }
    }
    
    /*********************************************************** Public methods ***********************************************************/
    public static Map<String, sked__Region__c> getMapOfCollectionOperationToRegion(Set<Id> collecOperationIds) {
        Map<String, sked__Region__c> mapCollOperToRegion = new Map<String, sked__Region__c>();
        
        List<Biomed_Collection_Op_Center__c> lsColOper = [SELECT Id, 
                                                          (SELECT Id, sked__Timezone__c 
                                                           FROM sked_Regions__r ORDER BY CreatedDate DESC) 
                                                          FROM Biomed_Collection_Op_Center__c
                                                          WHERE Id IN :collecOperationIds];
        
        for (Biomed_Collection_Op_Center__c colOperRec : lsColOper) {
            if (colOperRec.sked_Regions__r.isEmpty()) continue;
            
            if (colOperRec.sked_Regions__r.size() == 1) {
                mapCollOperToRegion.put(colOperRec.Id, colOperRec.sked_Regions__r[0]);
            } else {
                for (sked__Region__c regRec : colOperRec.sked_Regions__r) {
                    String timezoneKey = colOperRec.Id + ':' + regRec.sked__Timezone__c;
                    mapCollOperToRegion.put(timezoneKey, regRec);
                }
                String defaultKey = colOperRec.Id + ':' + 'default';
                mapCollOperToRegion.put(defaultKey, colOperRec.sked_Regions__r[0]);
            }
        }
        
        return mapCollOperToRegion;
    }
    
    public static Id getRegionForCollectionOperation(Id collOperId, Map<String, sked__Region__c> mapCollOperToRegion, String siteTimeZone) {
        Id regionId;
        if (mapCollOperToRegion.containsKey(collOperId)) {
            regionId = mapCollOperToRegion.get(collOperId).Id;
        } 
        else {
            String timezoneKey = collOperId + ':' + siteTimeZone;
            String defaultKey = collOperId + ':' + 'default';
            if (mapCollOperToRegion.containsKey(timezoneKey)) {
                regionId = mapCollOperToRegion.get(timezoneKey).Id;
            } else if (mapCollOperToRegion.containsKey(defaultKey)) {
                regionId = mapCollOperToRegion.get(defaultKey).Id;
            }
        }
        
        return regionId;
    }
    
    /*********************************************************** Nested class ***********************************************************/
    public class queryModel extends skedDataService.queryModelBase {
        public string biomedCollectionOpId;
        public string timezoneSidId;
        public List<string> biomedCollectionOpIds;
    }
    
}