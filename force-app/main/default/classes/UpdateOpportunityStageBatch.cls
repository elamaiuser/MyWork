global class UpdateOpportunityStageBatch implements Database.Batchable<sObject>, Database.Stateful {

    global List<Opportunity> oppNewList = new List<opportunity>();
    global Map<id, Opportunity> oppOldMap = new Map<id, Opportunity>();
    global List<Opportunity> finalOppList = new List<Opportunity>();

    global UpdateOpportunityStageBatch(list<Opportunity> incomingOppNewList, map<Id, Opportunity> incomingOppOldMap) {
        System.debug('### inside UpdateOpportunityStageBatch Constructor');
         //If after insert
        if(incomingOppOldMap == null) {
            oppNewList = [SELECT Id, Name, Is_Template__c, Initiated_By__c, sked_Cancellation_Reason__c, StageName, DriveStatus__c FROM Opportunity WHERE Id in: incomingOppNewList];
        }
        else {
            oppNewList = incomingOppNewList;
        }
        oppOldMap = incomingOppOldMap;

        //oppNewList = incomingOppNewList;
        //oppOldMap = incomingOppOldMap;
    }
    
    //To be used by migration.  The OpportunityService.UpdateOppStage method will be disabled for migration.  After
    //migration is completed, we can execute this batch manually by passing to it just a list of opportunities
    //UpdateOpportunityStageBatch batchMigratedOppRecs = new UpdateOpportunityStageBatch(List<Opportunity>);
    //Database.executeBatch(batchMigratedOppRecs, 1);
    global UpdateOpportunityStageBatch(list<Opportunity> incomingOppNewList) {
        oppNewList = incomingOppNewList;
        oppOldMap = null;
    }
    
	global List<Opportunity> start(Database.BatchableContext bc) {
    	System.debug('### inside UpdateOpportunityStageBatch Start');
        for (Opportunity opp : oppNewList) {
            if(opp.Is_Template__c == false && opp.Initiated_By__c != null && opp.sked_Cancellation_Reason__c != null && opp.StageName != 'Cancelled') {
                   opp.StageName = 'Cancelled';
            }
            if(opp.Is_Template__c == false && opp.DriveStatus__c == 'Cancel'){
                opp.StageName = 'Cancelled';
            }
			if(oppOldMap != null && !oppOldMap.isEmpty()) {
                if(oppOldMap.containsKey(opp.Id) && oppOldMap.get(opp.Id).DriveStatus__c != null && 
                   (oppOldMap.get(opp.Id).DriveStatus__c == 'Draft' && opp.DriveStatus__c != null && opp.DriveStatus__c == 'Hold') ||
                    (oppOldMap.get(opp.Id).DriveStatus__c == 'Hold' && opp.DriveStatus__c != null && opp.DriveStatus__c == 'Draft')) 
                {
                       opp.StageName = 'Solicitation';
                }
            }
            if(opp.Is_Template__c == false && opp.DriveStatus__c == 'Tentative'){
                opp.StageName = 'Committed';
            }
            if(opp.Is_Template__c == false && opp.DriveStatus__c == 'Confirmed'){
                opp.StageName = 'Closed';
            }
            finalOppList.add(opp);
        }
        return finalOppList;
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> lstOpportunities) {
        System.debug('### inside UpdateOpportunityStageBatch Execute ' + finalOppList.size() + ' ---' + finalOppList);
        Database.saveResult[] updateList = Database.update(finalOppList, FALSE);
        List<BSF_Error_Log__c> errorLogList = BSF_Utilities.createErrorLog(updateList, 'Error in updating opp stage', 'UpdateOpportunityStageBatch', 'execute', 'Error', 'Error during update');
        Insert errorLogList;

    }
    
    public void finish(Database.BatchableContext BC){
           
   	}
}