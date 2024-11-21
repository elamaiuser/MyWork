global class skedLinkDrivesBatch implements Database.Batchable<sked_Drive__c> {
    
    Set<Id> driveIds;
    global skedLinkDrivesBatch(Set<Id> inputDriveIds) {
        this.driveIds = inputDriveIds;
    }
    
    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Account__c, sked_Drive_Date__c, sked_Next_Drive__c, sked_Previous_Drive__c
                FROM sked_Drive__c
                WHERE Id IN :this.driveIds];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> records) {
        //NOTE: the below function uses 2 SOQL 1 DML per record. So the max chunk size is 50
        slwcDriveService.populateNextPreviousDrive(records);
    }
    
    global void finish(Database.BatchableContext BC) {}
    
}