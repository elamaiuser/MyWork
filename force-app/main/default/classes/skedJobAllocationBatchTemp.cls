global class skedJobAllocationBatchTemp implements Database.Batchable<sked__Job_Allocation__c>, Database.AllowsCallouts, Database.Stateful {

    global skedJobAllocationBatchTemp() { }
    
    global List<sked__Job_Allocation__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked__Start__c, sked__Set_End__c
                FROM sked__Job_Allocation__c
                WHERE sked__Start__c != NULL
                AND sked_Start_Date__c = NULL];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job_Allocation__c> records) {
        for (sked__Job_Allocation__c record : records) {
            record.sked__Start__c = record.sked__Start__c.addMinutes(1);
            record.sked__Set_End__c = record.sked__Set_End__c.addMinutes(1);
        }
        update records;
        
        for (sked__Job_Allocation__c record : records) {
            record.sked__Start__c = record.sked__Start__c.addMinutes(-1);
            record.sked__Set_End__c = record.sked__Set_End__c.addMinutes(-1);
        }
        update records;
    }
    
    global void finish(Database.BatchableContext BC) { }
    
}