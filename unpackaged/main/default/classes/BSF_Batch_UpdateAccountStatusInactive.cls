/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * **********************************************************************************************************************************************************************************
 * 7/04/2023                  Ankit Kundu            Logic for HRP-10413 (Updating Account-status : 'Inactive' of Accounts that have no opportunities and drives associated with it) 
 ************************************************************************************************************************************************************************************
*/


global class BSF_Batch_UpdateAccountStatusInactive implements Database.Batchable<sObject>,Schedulable {
    global String opptyDriveStatusDraft =BSF_Constants.driveStatusDraft;
    global String opptyDriveStatusCancel=BSF_Constants.driveStatusCancel;
    global String opptyDriveStatusComplete=BSF_Constants.driveStatusComplete;
    global void execute(SchedulableContext sc) {
        BSF_Batch_UpdateAccountStatusInactive batch1 = new BSF_Batch_UpdateAccountStatusInactive(); 
        Database.executeBatch(batch1,50); 
        
    }
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        String acctStatus=BSF_Constants.acctStatus;
        String query = 'SELECT Id, Account_Status__c FROM Account';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accList) {
        Set<Id> setOfAccts=new Set<Id>();       
        Set<Id> setofpastdriveAccts=new Set<Id>();
        Map<Id,List<Id>> mapOffutureDriveListOppties=new Map<Id,List<Id>>();
        List<Account> listOfAcctsToUpdate=new List<Account>();
        
        for(Account acc:accList){
            setOfAccts.add(acc.id);
        }
        //For Lapsed and Inactive
        AccountStatusUpdateHelper.updateAcc(setOfAccts);
        List<Opportunity> listOfFutureDriveOppties=[select Id,AccountId,Drive_Date__c,DriveStatus__c from opportunity
                                                    where AccountId IN:setOfAccts AND DriveStatus__c NOT IN(:opptyDriveStatusDraft,:opptyDriveStatusCancel) AND Drive_Date__c >=Today];
        if(!listOfFutureDriveOppties.isEmpty()){                
            for(Opportunity opRecord:listOfFutureDriveOppties){
                if(mapOffutureDriveListOppties.containsKey(opRecord.AccountId)){
                    List<Id> listOfexistingOppties=mapOffutureDriveListOppties.get(opRecord.AccountId);
                    listOfexistingOppties.add(opRecord.id);
                    mapOffutureDriveListOppties.put(opRecord.AccountId,listOfexistingOppties);        
                }else {
                    mapOffutureDriveListOppties.put(opRecord.AccountId,new List<Id> {opRecord.Id});  
                }
            }
        }
        
        
        for(Account accRecord:accList){      
            if(!mapOffutureDriveListOppties.containsKey(accRecord.id)){
                setofpastdriveAccts.add(accRecord.id);
            }
        }
        
        
        List<Account> listOfpastDriveAccts=[select Id,Account_Status__c,(select Id,AccountId,CreatedDate,Drive_Date__c,DriveStatus__c from opportunities where DriveStatus__c =:opptyDriveStatusComplete  Order by Drive_Date__c desc limit 1) from Account where ID IN:setofpastdriveAccts];
        for(Account accRecord:listOfpastDriveAccts){
            for(Opportunity opRecord:accRecord.opportunities){         
                Date driveDate=opRecord.Drive_Date__c;               
                if(driveDate!=null){
                    Integer numberOfmonths=driveDate.monthsBetween(System.today());
                    if(numberOfmonths>=13 && numberOfmonths<=24 && accRecord.Account_Status__c !='Inactive'){
                        accRecord.Account_Status__c='Inactive';
                        listOfAcctsToUpdate.add(accRecord);
                    }
                }
            }
        }
        /* HRP-10413 [Start]--> */
       List<Account> listOfAcctsStatus = [select Id,Account_status__c from Account where Id NOT IN (SELECT AccountId FROM opportunity where Is_Template__c = FALSE) AND Account_status__c = 'Active' AND ID IN :setOfAccts];
          for(Account accRecord:listOfAcctsStatus)
          {  
                        accRecord.Account_Status__c='Inactive';
                        listOfAcctsToUpdate.add(accRecord);
              
          }
        
        if(!listOfAcctsToUpdate.isEmpty()){           
            Database.SaveResult[] srList = Database.update (listOfAcctsToUpdate,false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating Account Status to Inactive','BSF_Batch_UpdateAccountStatusInactive','execute','Error','Error in updating Account Status to Inactive');
            InsertBsfErrorLog.insertBsfErrors(logList);
       /* HRP-10413 [End]--> */
            
            /*for (Database.SaveResult sr : srList) 
            {
                if (sr.isSuccess()) 
                {
                    System.debug('Successfully updated Account status Account ID: ' + sr.getId());
                }
                else 
                {        
                    for(Database.Error err : sr.getErrors()) 
                    {System.debug('The Error in updating the Account Status is : '+err.getStatusCode() + ': ' + err.getMessage());}
                }
            }*/
        }
        
    }   
    
    global void finish(Database.BatchableContext BC) {
        
    }
}