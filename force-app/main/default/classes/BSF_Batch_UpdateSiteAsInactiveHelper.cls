/* This batch will be scheduled to run everyday
 * It will fetch the sites whose end dates are reached <= today
 * It will unmark the active checkbox - inactive site
 * This batch is written as a part of HRP - 9276
-------------------------------------------------------------------------------------------------------------------------------------------------- */

global class BSF_Batch_UpdateSiteAsInactiveHelper implements Database.Batchable<sObject> , Schedulable {
    
    
    // retreiving sites based on end date
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        Date endDate = system.today();
        String query = 'Select Id,sked_Active__c ,sked_Start_Date__c,sked_End_Date__c from sked__Location__c where sked_End_Date__c <=:endDate and sked_Active__c = true';
        return Database.getQueryLocator(query); 
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Location__c> scope) 
    {
       
       List<sked__Location__c> siteListToBeInactive = new List<sked__Location__c>();
        
       if(!scope.isEmpty())
       {
           for(sked__Location__c sites : scope)
           {
               sites.sked_Active__c = false; // unchecking the active checkbox if end date is reached
               siteListToBeInactive.add(sites);
               
           }
       }
       
       Database.SaveResult[] srList = Database.update(siteListToBeInactive , false);
       
       // creating one entry in error log for the errors
       List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'End Dating Site','BSF_Batch_UpdateSiteAsInactiveHelper','execute','Error','Error in deactivating site');
       Database.insert(logList,false);
       
    }
    
    global void finish(Database.BatchableContext BC) 
    {
       
    }
	

	global void execute(SchedulableContext sc) {
        Id batchJobId  = Database.executeBatch(new BSF_Batch_UpdateSiteAsInactiveHelper());
    }    
}