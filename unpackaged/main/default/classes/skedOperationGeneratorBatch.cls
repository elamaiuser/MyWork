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

        try {
            skedOperationRecordService.generateOperationRecords(mapDrive.keySet());
        } catch (Exception ex) {
            captureDebugLog(ex);
            throw ex;
        }
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    @testVisible
    private void captureDebugLog(Exception ex) {
        insert new sked__Debug_Log__c(
            sked__Type__c = 'Operation Record Generation',
            sked__User__c = UserInfo.getUserId(),
            sked__Summary__c = ex.getMessage(),
            sked__Message__c = ex.getMessage() + ': ' + ex.getStackTraceString()
        );
    }
}