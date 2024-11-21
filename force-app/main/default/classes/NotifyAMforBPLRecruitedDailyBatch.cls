global class NotifyAMforBPLRecruitedDailyBatch implements Database.Batchable<sObject>, Database.Stateful{
    list<OpportunityContactRole> driveContactRoleList = new  list<OpportunityContactRole>();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String recruitedBy = 'BPL Recruited';
        String query = 'SELECT Id,Recruited_By__c,Account_Manager__c FROM Account WHERE Recruited_By__c =: recruitedBy';
        return Database.getQueryLocator(query);        
    }
    global void execute(Database.BatchableContext BC, List<Account> accBplRecruitedList){
        NotifyAMforBPLRecruitedDailyBatchHelper.findDriveWithNoCallRecipientContact(accBplRecruitedList);        
    }
    global void finish(Database.BatchableContext bc){
        System.debug('Notification has been sent succesfully');
    }
}