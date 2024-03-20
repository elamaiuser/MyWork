//Batch for notifying the District manager regarding expiry of the account team member before 3 days
global class DMBellNotificationForATMExpiryBatch implements Database.Batchable<sObject> {
    Date d=date.today()+3;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Account.District_Manager__c,Account.District_Manager__r.Name,User.Name,createdById,End_Date__c FROM AccountTeamMember where Account.District_Manager__c != null and End_Date__c=:d';
        return Database.getQueryLocator(query);        
    }
    global void execute(Database.BatchableContext BC, List<AccountTeamMember>atmList ){
        DMBellNotificationATMExpiryBatchHelper.SendBellNotificationTODM(atmList);        
    }
    global void finish(Database.BatchableContext bc){
        System.debug('Notification has been sent succesfully');
    }

}