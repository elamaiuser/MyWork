global class UpdateAccountTeamMemberDailyBatch implements Database.Batchable<sObject>,Database.Stateful{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String AMRole = 'Account Manager';
        String DMRole = 'District Manager';
        Date today = Date.today();
        //  String query = 'SELECT Id,AccountId,TeamMemberRole,Coverage_Reason__c,UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c,Account.Account_Manager__c,Account.District_Manager__c, Account.District_Manager_Portfolio__c, Account.Account_Manager_Portfolio__c,BSF_Portfolio__c FROM AccountTeamMember WHERE Start_Date__c <=:today and End_Date__c>=:today AND TeamMemberRole IN (:AMRole,:DMRole)'; //HRP-10359 //HRP-11777
         String query = 'SELECT Id,AccountId,TeamMemberRole,Coverage_Reason__c,UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c,Account.Account_Manager__c,Account.District_Manager__c, Account.District_Manager_Portfolio__c, Account.Account_Manager_Portfolio__c,BSF_Portfolio__c FROM AccountTeamMember WHERE Start_Date__c <=:today and End_Date__c>=:today AND TeamMemberRole IN (:AMRole,:DMRole) AND ID = \'01M5c000008rXecEAE\''; //HRP-10359 //HRP-11777
        return Database.getQueryLocator(query);
        
    }
    global void execute(Database.BatchableContext BC, List<AccountTeamMember> accTeamMemberList){
        // try {
            UpdateAccountTeamMemberDailyBatchHelper.updateAccountTeamMemberLookUps(accTeamMemberList); 
        // } catch (Exception ex) {
            //System.debug(ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber());
            // List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(null,'UpdateAccountTeamMemberDailyBatch','UpdateAccountTeamMemberDailyBatch','accTeamDateSyncOnAccPortUpdates','Error','sync Future AccTeam opportunity Team Delete');
        //     BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
        //     debugLog.ApexClass__c = 'UpdateAccountTeamMemberDailyBatch';
        //     debugLog.Method__c ='UpdateAccountTeamMemberDailyBatch';
        //     debugLog.Error_Description__c = 'The Exception is covered :: '+ex.getMessage(); //
        //     debugLog.Error_Description_Long__c = ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber();
        //     insert debugLog;
        // }
    }
    global void finish(Database.BatchableContext bc){
        System.debug('UpdateAccountTeamMemberDailyBatch has run succesfully');
    }
}