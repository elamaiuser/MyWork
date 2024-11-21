global class skedPopulateResourceRegionBatch implements Database.Batchable<sked__Resource__c> {

    protected Set<Id> resourceIds;
    global skedPopulateResourceRegionBatch(Set<Id> inputResourceIds) {
        this.resourceIds = inputResourceIds;
    }
    
    global List<sked__Resource__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Collection_Operation_Name_Staging__c, sked_Timezone__c
                FROM sked__Resource__c
                WHERE Id IN :resourceIds];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Resource__c> resources) {
        List<string> collectionOperationNames = new List<string>();
        for (sked__Resource__c resource : resources) {
            collectionOperationNames.add(resource.sked_Collection_Operation_Name_Staging__c);
        }
        List<Biomed_Collection_Op_Center__c> collectionOperations = [SELECT Id, Name,
                                                                     (SELECT Id, sked__Timezone__c
                                                                      FROM sked_Regions__r
                                                                      WHERE sked__Timezone__c != NULL)
                                                                     FROM Biomed_Collection_Op_Center__c
                                                                     WHERE Name IN :collectionOperationNames];
        if (!collectionOperations.isEmpty()) {
            Map<string, sked__Region__c> mapRegion = new Map<string, sked__Region__c>();
            for (Biomed_Collection_Op_Center__c collectionOperation : collectionOperations) {
                if (collectionOperation.sked_Regions__r != NULL && !collectionOperation.sked_Regions__r.isEmpty()) {
                    for (sked__Region__c region : collectionOperation.sked_Regions__r) {
                        string key = collectionOperation.Name + ':' + region.sked__Timezone__c;
                        mapRegion.put(key, region);
                    }
                }
            }
            List<sked__Resource__c> resourcesToUpdate = new List<sked__Resource__c>();
            for (sked__Resource__c resource : resources) {
                string key = resource.sked_Collection_Operation_Name_Staging__c + ':' + resource.sked_Timezone__c;
                if (mapRegion.containsKey(key)) {
                    sked__Region__c region = mapRegion.get(key);
                    resource.sked__Primary_Region__c = region.Id;
                    resourcesToUpdate.add(resource);
                }
            }
            if (!resourcesToUpdate.isEmpty()) {
                update resourcesToUpdate;
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {}

}