global class skedJobNonDeclinable_batch implements Database.Batchable<sked__Job__c> {
    
    global List<sked__Job__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked__Can_Be_Declined__c
            FROM sked__Job__c
            WHERE sked__Can_Be_Declined__c = true
        ];        
    }

    global void execute(Database.BatchableContext BC, List<sked__Job__c> jobs) {
        for (sked__Job__c job : jobs) {
            job.sked__Can_Be_Declined__c = false;
        }

        skedTriggerHub.BypassUpdateTriggers = true;
        update jobs;
        skedTriggerHub.BypassUpdateTriggers = false;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('finished!');
    }
}