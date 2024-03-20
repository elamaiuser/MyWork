/***********************************************************************************************************
 * 
 * Description:         This is a batch job for deleting records from account service role. The purpose of it is to
 *                      serve HRP - 7496 - when ending role, once effective date is reached, contact should be removed 
 * 						from Account Service Role and only be displayed in Account Contact History.
 * 						This will be scheduled to run daily after 12:00 am.
 * 
 **********************************************************************************************************/

global class BSF_BatchDeleteFromAccountServiceRole implements Database.Batchable<sObject> , Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
    	String query = 'SELECT Id from Account_Service_Role__c where End_Date__c = YESTERDAY';
        return Database.getQueryLocator(query); 
    }
    
    global void execute(Database.BatchableContext BC, List<Account_Service_Role__c> conList) 
    {
        Database.DeleteResult[] drList = Database.delete(conList,false);
        
        for(Database.DeleteResult dr : drList) {
            if (!dr.isSuccess()) {
                for(Database.Error err : dr.getErrors()) {
                    System.debug('Error Deleting account service role record is -> '+err.getStatusCode() + ': ' + err.getMessage());                    
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) 
    {
		    
    }
    
    global void execute(SchedulableContext scon) {
      Database.executeBatch(new BSF_BatchDeleteFromAccountServiceRole(), 200);
   }
}