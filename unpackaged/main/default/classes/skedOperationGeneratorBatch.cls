//LIMIT to external data source: THE CHUNK SIZE SHOULD BE 100
global class skedOperationGeneratorBatch implements Database.Batchable<sked_Drive__c> {

    global skedOperationGeneratorBatch() {}
    
    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Account__c, sked_Collection_Operation__c, sked_Drive_Site__c, sked_Primary_Contact__c
                FROM sked_Drive__c
                WHERE sked_Drive_Date__c = TODAY
                AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
                AND sked_Status__c != :skedConstants.DRIVE_STATUS_COMPLETE];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        Map<Id, sked_Drive__c> mapDrive = new Map<Id, sked_Drive__c>(drives);

        skedOperationRecordService.generateOperationRecords(mapDrive.keySet());
    }
    
    global void finish(Database.BatchableContext BC) {}
    
}