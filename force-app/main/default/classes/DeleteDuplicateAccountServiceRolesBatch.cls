public class DeleteDuplicateAccountServiceRolesBatch implements Database.Batchable<sObject>{

     Map<Id,String> updateFailedRecords = new Map<Id,String>();
     String query = 'select id,Account__r.Id, contact__r.id, Account_Service_Role__c,start_Date__c,end_date__c from account_Service_role__c ';	
    
      public Database.QueryLocator start(Database.BatchableContext BC){
			return Database.getQueryLocator (query);
       }
    
     public void execute(Database.BatchableContext BC, List<sObject> scope){
		   Set<String> uniqueRoles = new Set<String>();
           List<ID> duplicateIds = new List<Id>();	
           for(sObject obj:scope){
               String uniqueCombination = '';
               account_Service_role__c asr = (account_Service_role__c) obj;
               if(String.isBlank(asr.Account__c) == false){
                   uniqueCombination = uniqueCombination+asr.Account__c;
               }
               if(String.isBlank(asr.Contact__c) == false){
                  uniqueCombination = uniqueCombination+asr.Contact__c;
               }
               if(asr.Start_Date__c != null){
                   uniqueCombination = uniqueCombination+asr.Start_Date__c;
               }
               if(asr.end_date__c != null){
                   uniqueCombination = uniqueCombination+asr.end_date__c;
               }
               if(String.isBlank(asr.Account_Service_Role__c) == false){
                   uniqueCombination = uniqueCombination+asr.Account_Service_Role__c;
               }
              boolean valueAdded =  uniqueRoles.add(uniqueCombination);
               if(valueAdded == false){ //its duplicate
                   duplicateIds.add(asr.id);
               }
           }
         
         
          Database.DeleteResult[] srList =  Database.delete(duplicateIds, false);
           Database.emptyRecycleBin(duplicateIds); 

          for(Integer i=0; i <srList.size();i++){
             Database.DeleteResult sr = srList.get(i); 
              if (sr.isSuccess() == false){ //collect failed records
                   for(Database.Error err : sr.getErrors()) {
                     System.debug('The following error has occurred.');                    
                     System.debug(err.getStatusCode() + ': ' + err.getMessage());
                     System.debug('Opportunity fields that affected this error: ' + err.getFields());
        		}
              }else{
                 System.debug('Succesfully processed ASR Id ->'+sr.getId()); 
              }
          }
          
       }
    
       public void finish(Database.BatchableContext BC){
           
       }
    
    
    
}