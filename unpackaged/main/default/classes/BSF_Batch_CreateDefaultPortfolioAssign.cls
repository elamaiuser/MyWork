//@Description: This Batch runs everyday quering Account Exception created on that day and creates the Default territory assignmnets after exception End in future
/* 
* created by Balaji N @8/2/2023
* Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 8/2/2023					 Balaji N					 Logic for HRP-8897 (creation of this class)
* *
*****************************************************************************
*/
global class BSF_Batch_CreateDefaultPortfolioAssign implements Database.Batchable<sObject>,Schedulable
{
    public Date specificDate;
    
    
    global  BSF_Batch_CreateDefaultPortfolioAssign(){}
    
    global  BSF_Batch_CreateDefaultPortfolioAssign(Date specificDate)
    {
       this.specificDate=specificDate;
    }

    //Schedule execute Method
    global void execute(SchedulableContext sc) 
    {
        Id batchJobId  = Database.executeBatch(new BSF_Batch_CreateDefaultPortfolioAssign());
    } 

    global database.QueryLocator start(Database.BatchableContext bc){
        
        string portfolioType=BSF_Constants.ACCOUNT_MANAGER;
        string query='select Id,Bsf_Portfolio__c,account__c,Start_Date__c,End_date__c from Account_Portfolio_Assignment__c where ';
        
        if(this.specificDate != null)
        {
            Date endDate= this.specificDate.addDays(1);
            query+='CreatedDate>=:specificDate and createdDate <=:endDate and Bsf_Portfolio__r.Account_Based_Portfolio__c=true and Bsf_Portfolio__r.Portfolio_Type__c=:portfolioType';
        }
        else
        {
            query+='createdDate=today and Bsf_Portfolio__r.Account_Based_Portfolio__c=true and Bsf_Portfolio__r.Portfolio_Type__c=:portfolioType';
        }
        
        system.debug(query);
        return database.getQueryLocator(query); 
        
    }
     
    
    
    global void execute(Database.BatchableContext bc, list<account_Portfolio_Assignment__c> accPortfolioList)
    {
        system.debug('accPortfolioList'+accPortfolioList);
        map<id,account_Portfolio_Assignment__c> accIdAccPortMap= new map<id,account_Portfolio_Assignment__c>();
        for(account_Portfolio_Assignment__c apa :accPortfolioList)
        {
            accidAccPortMap.put(apa.account__c,apa);
        }
        
        List<Account> accList = [SELECT Id, Name,BillingPostalCode,Shippingpostalcode FROM Account WHERE Id IN:accIdAccPortMap.keyset()];
        AccountService.createAccountTeamMembers(accList,null,bsf_constants.DEFAULT_TERRITORY,accIdAccPortMap,null);
        
    }
    global void finish(Database.BatchableContext bc){
        system.debug('The BSF_Batch_CreateDefaultPortfolioAssign batch ran succesfully');
        
    }

}