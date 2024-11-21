global class skedPostDriveMigrationBatch1 implements Database.Batchable<sked_Drive__c>, Database.AllowsCallouts, Database.Stateful {
    
    protected string lastId = '';
    
    global skedPostDriveMigrationBatch1(string lastId) {
        this.lastId = lastId;
    }
	
    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Travel_Time_Included__c, sked_Collection_Operation__r.sked_Travel_Time_Included_Mobile__c,
                sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c,
                sked_Type_of_Drive__c
                FROM sked_Drive__c
                WHERE Id > :this.lastId
                AND sked_Travel_Time_Included__c = NULL
                AND sked_Collection_Operation__c != NULL
                ORDER BY Id ASC
                LIMIT 40000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> records) {
        for (sked_Drive__c record : records) {
            if (record.sked_Type_of_Drive__c == 'Mobile') {
                record.sked_Travel_Time_Included__c = record.sked_Collection_Operation__r.sked_Travel_Time_Included_Mobile__c;
            }
            else {
                record.sked_Travel_Time_Included__c = record.sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c;
            }
        }
        update records;
        
        this.lastId = records.get(records.size() - 1).Id;
        system.debug('#this.lastId#' + this.lastId);
    }
    
    global void finish(Database.BatchableContext BC) {
        List<sked_Drive__c> remainRecordQuery = [SELECT Id, sked_Travel_Time_Included__c, sked_Collection_Operation__r.sked_Travel_Time_Included_Mobile__c,
                                                 sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c,
                                                 sked_Type_of_Drive__c
                                                 FROM sked_Drive__c
                                                 WHERE Id > :this.lastId
                                                 AND sked_Travel_Time_Included__c = NULL
                                                 AND sked_Collection_Operation__c != NULL
                                                 ORDER BY Id ASC
                                                 LIMIT 1];
        if (!remainRecordQuery.isEmpty()) {
            Database.executeBatch(new skedPostDriveMigrationBatch1(this.lastId), 200);
        }
    }
    
}