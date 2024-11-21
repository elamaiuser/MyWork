//@Description: This Batch class is used for correction of Owner,AM,DM Lookup on opportunity on demand manually
/* 
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 03/28/2024                  Balaji N               Logic for HRP-12390 (created this Batch class)
**
*************************************************************************************************************************************************
*/
global class BSF_Batch_OppLookupCorrection implements database.batchable<Sobject>
{
    Public Date driveStartDate;
    Public Date driveEndDate;
    Public Set<Id> oppIdSet;
    global BSF_Batch_OppLookupCorrection(Date driveStartDate,Date driveEndDate)
    {
        this.driveStartDate=driveStartDate;
        this.driveEndDate=driveEndDate;
    }
    
    global BSF_Batch_OppLookupCorrection(Set<Id> oppIdSet)
    {
        system.debug('Constructor 2');
        this.oppIdSet=oppIdSet;
    }
    
    global BSF_Batch_OppLookupCorrection()
    {}
    
    global database.querylocator start(Database.Batchablecontext bc)
    {
        String query = 'Select Id,AccountId from opportunity where is_Template__c=false AND Drive_date__c>=Today';
        
        if(driveStartDate!=null && driveEndDate!=null)
        {
            query += ' AND Drive_date__c>=:driveStartDate AND Drive_date__c<=:driveEndDate';
        }
        else if(oppIdSet!=null)
        {
            query += ' AND Id IN:oppIdSet';
        }
        system.debug(query);
        return Database.getQueryLocator(query);      
    }
    global void execute(Database.Batchablecontext bc,List<Opportunity> scope)
    {
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> oppIdExeSet = new Set<Id>();
        for(Opportunity Opp:scope)
        {
            accIdSet.add(Opp.accountId);
            oppIdExeSet.add(Opp.Id);
            system.debug(oppIdSet);
        }
        map<id,list<accountTeamMember>> accIdFutureAccTeamMap = new map<id,list<accountTeamMember>>();
        map<id,list<accountTeamMember>> accIdExstngAccTeamMap = new map<id,list<accountTeamMember>>();
        accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(new list<id>(accIdSet),bsf_constants.ONE_TIME_BATCH,oppIdExeSet,accIdFutureAccTeamMap,accIdExstngAccTeamMap);
    }
    
    global void finish(Database.BatchableContext bc)
    {
        
    }
}