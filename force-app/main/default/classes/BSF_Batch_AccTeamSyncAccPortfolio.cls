//@Description: This Batch runs everyday quering Account_Portfolio_Assignment__c Starting on that day and syncs the Account Team Data(Start and End Dates and BSFPortfolio lookup)
/* 
* created by Balaji N @8/2/2023
* Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 08/02/2023				 Balaji N					 Logic for HRP-8897 (creation of this class)
* 01/04/2024                 Balaji N					 Logic for HRP-10569 (parameter changes on accTeamDateSyncOnAccPortUpdates method call)
* *
*****************************************************************************
*/
global class BSF_Batch_AccTeamSyncAccPortfolio implements Database.Batchable<sObject>,Schedulable
{
    public Date specificDate;

    global  BSF_Batch_AccTeamSyncAccPortfolio(){}
    
    global  BSF_Batch_AccTeamSyncAccPortfolio(Date specificDate)
    {
       this.specificDate=specificDate;
    }

    //Schedule execute Method
    global void execute(SchedulableContext sc) 
    {
        Id batchJobId  = Database.executeBatch(new BSF_Batch_AccTeamSyncAccPortfolio());
    }  

    
	global database.QueryLocator start(Database.BatchableContext bc)
    {
        string portfolioType=BSF_Constants.ACCOUNT_MANAGER;
        string query='select Id,Bsf_Portfolio__c,account__c,Start_Date__c,End_date__c from Account_Portfolio_Assignment__c where ';
       
        if(this.specificDate != null)
        {
            Date endDate= this.specificDate + 1;
            query+= 'Start_Date__c>=:specificDate and start_Date__c<=:endDate ';
        }
        else
        {
            query+= 'Start_Date__c=Today ';
        }

            query+='and Bsf_Portfolio__r.Portfolio_Type__c=:portfolioType';

        return database.getQueryLocator(query); 
        
    }
    
    global void execute(Database.BatchableContext bc, list<account_Portfolio_Assignment__c> accPortfolioList)
    {
        
        list<id> accIdList = new list<id>();
        for(Account_Portfolio_Assignment__c apa:accPortfolioList)
        {
            accIdList.add(apa.account__c);
        }
        
        accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(accIdList,null,new set<id>(),new map<id,list<accountTeamMember>> (),new map<id,list<accountTeamMember>> ());//HRP-10569 parameter changes
        
    }
    global void finish(Database.BatchableContext bc)
    {
        system.debug('The BSF_Batch_AccTeamSyncAccPortfolio batch ran succesfully');
        
    }
}