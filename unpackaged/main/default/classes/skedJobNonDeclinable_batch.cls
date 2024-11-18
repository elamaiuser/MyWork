global class skedJobNonDeclinable_batch implements Database.Batchable<sked__Job__c> {
    
    global List<sked__Job__c> start(Database.BatchableContext BC) {
        List<sked__Job__c> newList = new List<sked__Job__c>();
        return newList;  
    }

    global void execute(Database.BatchableContext BC, List<sked__Job__c> jobs) {
       
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('finished!');
    }
}