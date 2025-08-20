/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * **********************************************************************************************************************************************************************************
 * 7/04/2023                  Ankit Kundu            Logic for HRP-10413 (Updating Account-status : 'Inactive' of Accounts that have no opportunities and drives associated with it) 
 * 8/19/2025                  Barnojit Sharma        Logic for HRP-14999 (Account Status not updating to Inactive) 
 ************************************************************************************************************************************************************************************
*/
global without sharing class BSF_Batch_UpdateAccountStatusInactive 
    implements Database.Batchable<sObject>, Schedulable {

    global void execute(SchedulableContext sc) {
        BSF_Batch_UpdateAccountStatusInactive batchJob = new BSF_Batch_UpdateAccountStatusInactive(); 
        Database.executeBatch(batchJob, 50); 
    }

    global Database.QueryLocator start(Database.BatchableContext bc) { 
        Id mobileAccRecTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(BSF_Constants.MOBILE_ACCOUNT_RECORD_TYPE)
            .getRecordTypeId();

        String query = 'SELECT Id FROM Account WHERE RecordTypeId = :mobileAccRecTypeId';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accList) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accList) {
            accountIds.add(acc.Id);
        }

        if (!accountIds.isEmpty()) {
            AccountStatusUpdateHelper.updateAcc(accountIds);
        }
    }   
    
    global void finish(Database.BatchableContext bc) {}
}
