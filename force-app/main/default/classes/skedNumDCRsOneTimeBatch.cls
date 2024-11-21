global class skedNumDCRsOneTimeBatch implements Database.Batchable<SObject> {

    global skedNumDCRsOneTimeBatch() {}
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> nonPendingStatuses = new Set<String>{'Approved', 'Rejected', 'Cancelled', 'Approved by System'};
        return Database.getQueryLocator([
            SELECT Id, sked_Num_Of_Pending_DCRs__c,
                (SELECT Id FROM sked_Drive_Change_Requests__r WHERE sked_Status__c NOT IN :nonPendingStatuses)
            FROM sked_Drive__c
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<sked_Drive__c> drives = (List<sked_Drive__c>) scope;
        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        for (sked_Drive__c drive : drives) {
            if (drive.sked_Drive_Change_Requests__r.size() != drive.sked_Num_Of_Pending_DCRs__c) {
                drive.sked_Num_Of_Pending_DCRs__c = drive.sked_Drive_Change_Requests__r.size();
                drivesToUpdate.add(drive);
            }
        }

        if (!drivesToUpdate.isEmpty()) {
            skedHubBase.setBypassAllTriggers(true);
            update drivesToUpdate;
            skedHubBase.setBypassAllTriggers(false);
        }
    }
    
    global void finish(Database.BatchableContext BC) {}
}