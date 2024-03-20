global class skedSiteCOPopulateExternalIDBatch implements Database.Batchable<sked_Site_Collection_Operation__c> {

    global skedSiteCOPopulateExternalIDBatch() {}
    
    global List<sked_Site_Collection_Operation__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_External_ID__c, sked_Collection_Operation__r.External_Id__c, sked_Site__r.sked_MigrationID__c
                FROM sked_Site_Collection_Operation__c
                WHERE sked_External_ID__c = NULL
                AND sked_Collection_Operation__r.External_Id__c != NULL
                AND sked_Site__r.sked_MigrationID__c != NULL
                ORDER BY sked_End_Date__c DESC
                LIMIT 50000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Site_Collection_Operation__c> records) {
        for (sked_Site_Collection_Operation__c record : records) {
            record.sked_External_ID__c = record.sked_Collection_Operation__r.External_Id__c + ':' + record.sked_Site__r.sked_MigrationID__c;
        }
        Database.update(records, false);
    }
    
    global void finish(Database.BatchableContext BC) {}

}