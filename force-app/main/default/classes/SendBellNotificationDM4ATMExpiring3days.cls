global class SendBellNotificationDM4ATMExpiring3days implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Account.District_Manager__c,Account.District_Manager__r.Name,User.Name,createdById,End_Date__c FROM AccountTeamMember where Account.District_Manager__c != null and End_Date__c=NEXT_N_DAYS:3';
        return Database.getQueryLocator(query);        
    }
    global void execute(Database.BatchableContext BC, List<AccountTeamMember>newAtmList ){
        SendBellNotificationDM4ATMExpiringHelper.SendBellNotificationTODM(newAtmList);        
    }
    global void finish(Database.BatchableContext bc){
        System.debug('Notification has been sent succesfully');
    }

}