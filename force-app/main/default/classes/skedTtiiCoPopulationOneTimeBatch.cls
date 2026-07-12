public class skedTtiiCoPopulationOneTimeBatch implements Database.Batchable<SObject>, Database.Stateful {

    protected String lastId = '';

    public skedTtiiCoPopulationOneTimeBatch() {
        this.lastId = '';
    }

    public skedTtiiCoPopulationOneTimeBatch(String lastId) {
        this.lastId = lastId;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id
            FROM sked_Travel_Time_Index_Item__c
            WHERE sked_Collection_Operation__c = NULL
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 50000
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        Set<Id> ttiiIds = new Set<Id>();
        for (SObject record : scope) {
            ttiiIds.add((Id) record.get('Id'));
        }
        skedTravelTimeIndexItemHandler.populateTTILokkupFieldsOnSiteCO(ttiiIds);
        this.lastId = (Id) scope.get(scope.size() - 1).get('Id');
    }

    public void finish(Database.BatchableContext BC) {
        List<sked_Travel_Time_Index_Item__c> remainRecordQuery = [
            SELECT Id
            FROM sked_Travel_Time_Index_Item__c
            WHERE sked_Collection_Operation__c = NULL
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 1
        ];

        if (!remainRecordQuery.isEmpty()) {
            if (!Test.isRunningTest()) {
                Database.executeBatch(new skedTtiiCoPopulationOneTimeBatch(this.lastId), 200);
            }
        }
    }
}