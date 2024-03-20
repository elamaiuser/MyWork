global class skedPopulateRegionOnSiteCo_Batch implements Database.Batchable<sked_Site_Collection_Operation__c>, Database.Stateful {
    protected string lastId = '';
    global skedPopulateRegionOnSiteCo_Batch() {
        this.lastId = '';
    }

    global skedPopulateRegionOnSiteCo_Batch(String lastId) {
        this.lastId = lastId;
    }

    global List<sked_Site_Collection_Operation__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked_Site__r.sked__Region__c, sked_Collection_Operation__c, sked_Site__r.sked_Timezone__c
            FROM sked_Site_Collection_Operation__c
            WHERE Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 50000
        ];
    }

    global void execute(Database.BatchableContext BC, List<sked_Site_Collection_Operation__c> siteCos) {
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Site_Collection_Operation__c sco : siteCos) {
            collectionOperationIds.add(sco.sked_Collection_Operation__c);
        }
        Map<String, sked__Region__c> mapCollOperToRegion = skedRegionService.getMapOfCollectionOperationToRegion(collectionOperationIds);

        for (sked_Site_Collection_Operation__c sco : siteCos) {
            Id regionId = skedRegionService.getRegionForCollectionOperation(sco.sked_Collection_Operation__c,
                mapCollOperToRegion, sco.sked_Site__r.sked_Timezone__c
            );

            sco.sked_Region__c = regionId;
        }

        update siteCos;

        this.lastId = siteCos.get(siteCos.size()-1).Id;
    }

    global void finish(Database.BatchableContext BC) {
        List<sked_Site_Collection_Operation__c> remainRecordQuery = [
            SELECT Id
            FROM sked_Site_Collection_Operation__c
            WHERE Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 1
        ];
    
        if (!remainRecordQuery.isEmpty()) {
            Database.executeBatch(new skedPopulateRegionOnSiteCo_Batch(this.lastId), 200);
        }
    }
}