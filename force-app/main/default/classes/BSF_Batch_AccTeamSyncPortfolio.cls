//@Description: This Batch runs everyday quering Portfolio_Assignment__c Starting/Ending/lastmodifiedDate on that day and syncs the Account Team Data(Start and End Dates and BSFPortfolio lookup)
/* 
* created by Balaji N @8/2/2023
* Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 8/2/2023					 Balaji N					 Logic for HRP-8897 (creation of this class)
* 01/09/2024				 Balaji N					 Logic for HRP-10569 (parameter changes on accTeamDateSyncOnAccPortUpdates method call)
* *
*****************************************************************************
*/
global class BSF_Batch_AccTeamSyncPortfolio implements Database.Batchable<sObject>
{
	
   
    global database.QueryLocator start(Database.BatchableContext bc){
        list<string> amNodeList = new list<string>{BSF_Constants.ACCOUNT_MANAGER,BSF_Constants.AREA_BOOKING_MANAGER,BSF_Constants.DISTRICT_MANAGER};
        string query='select Id,Bsf_Portfolio__c,Assignment_type__c,Start_Date__c,End_date__c from Portfolio_Assignment__c where (Start_date__c=Today or End_date__c=Yesterday or (lastmodifiedDate=Yesterday) or (lastmodifiedDate=today)) and Assignment_type__c IN:amNodeList';
        return database.getQueryLocator(query); 
        
    }
    
    global void execute(Database.BatchableContext bc, list<Portfolio_Assignment__c> portfolioList)
    {
        set<id> bsfIdSet = new set<id>();
        for(Portfolio_Assignment__c pa :portfolioList)
        {
            bsfIdSet.add(pa.BSF_Portfolio__c);
        }
        
        //Geting AM node for DM or ABM portfolio 
        List<BSF_Portfolio__c> portfolioLinkedtoAccount1 = [Select Id,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN :bsfIdSet ];
        
        for(BSF_Portfolio__c bsf:portfolioLinkedtoAccount1)
        {
            bsfIdSet.add(bsf.Id);
        }
        
        //Geting AM node for DM portfolio 
        List<BSF_Portfolio__c> portfolioLinkedtoAccount2 = [Select Id,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN :portfolioLinkedtoAccount1 ];
        for(BSF_Portfolio__c bsf:portfolioLinkedtoAccount2)
        {
            bsfIdSet.add(bsf.Id);
        }
        
        //getting accountportfolio assignment 
        List<Account_Portfolio_Assignment__c> accPortfolioList =[SELECT Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c,BSF_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:bsfIdSet ];

        list<id> accIdList = new list<id>();
        for(Account_Portfolio_Assignment__c apa:accPortfolioList)
        {
            accIdList.add(apa.account__c);
        }
        
        accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(accIdList,null,new set<id>(),new map<id,list<accountTeamMember>> (),new map<id,list<accountTeamMember>> ());//HRP-10569 parameter changes
    }
    global void finish(Database.BatchableContext bc){
        system.debug('The BSF_Batch_AccTeamSyncPortfolio batch ran succesfully');
        
    }

}