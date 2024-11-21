/* @Description: The controller is being used by 'cmpCloseFixedAccount' Aura Component

* Modification Log 
* 
*   Date					Developer Name			Comments
* ******************************************************************************************************************************
* 02/26/2024		         Priti Jana		     HRP-11936 - Created, Modified existing method names and return types to reuse
********************************************************************************************************************************/
public class closeFixedSiteAccountController {
    
    @AuraEnabled
    public static Integer getTotalNonCancelledFutureOpportunities(String accId,Date selEffectiveDate) {
        List<Opportunity> oppList = [SELECT Id, AccountId, Name, Description, StageName,Drive_Date__c 
                                    FROM Opportunity 
                                    WHERE AccountId =:accId 
                                    AND Drive_Date__c >= :selEffectiveDate 
                                    AND stageName != :BSF_Constants.STAGE_CANCELLED];
        
        return oppList.size() > 0 ? oppList.size() : 0;
    }
    
    @AuraEnabled
    public static String cancelOpportunitiesOnFSAccountClosure(Id accId, Date selEffectiveDate,String closeReason) {
        Integer batchSize = Integer.valueOf(Custom_Messages__mdt.getInstance('Batch_Size_for_Bsf_BatchCancelBloodDrive').value__c);
        Database.executeBatch(new Bsf_BatchCancelBloodDrivePendingOpp(accId,selEffectiveDate,closeReason),batchSize);
        
        return String.valueOf(Custom_Messages__mdt.getInstance('Drive_Cancellation_Req_Submission_Msg').Value__c);
    }
    
    @AuraEnabled
    public static String closeFSAccount(Id accId, Date selEffectiveDate, String closeReason) {  
        List<Account> accListToUpdate = new List<Account>{new Account(Id=accId , Defunct_Effective_Date__c = selEffectiveDate, Closure_Reason__c = closeReason, Account_Status__c =BSF_Constants.ACCOUNT_STATUS_CLOSED)}; 
            
        Database.SaveResult[] resultList = Database.Update(accListToUpdate, FALSE);  
        List<BSF_Error_Log__c> errorLogsToInsert = BSF_Utilities.createErrorLog(resultList, 'FS Account Closure', 'closeFixedSiteAccountController', 'closeFSAccount', 'error', 'Error during Account Update');
        if(!errorLogsToInsert.isEmpty() && errorLogsToInsert.size() > 0){
            Insert errorLogsToInsert;
        }
        
        return String.valueOf(Custom_Messages__mdt.getInstance('FS_Account_Closure_Msg').Value__c);
    }
    
    @AuraEnabled
    public static Account fetchFSAccountDetails(String accId) {
        return [SELECT Id, Name, Closure_Reason__c, Defunct_Effective_Date__c,Account_Status__c FROM Account WHERE Id = :accId];
    }

}