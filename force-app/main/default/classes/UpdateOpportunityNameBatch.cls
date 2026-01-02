//@Description: This batch updating opportunity name, called from Account Service, Site Service and opportunity service 
/*

* Modification Log 
* 
* Date					Developer Name			Comments
* ***************************************************************************************************************************************************************************
* 09/08/2023			Kishore Das				Added Database method and Error log(For the Story HRP-10549)
* 03/06/2024			Balaji N		  	    logic for HRP-12136 (changes in opp name logic)
*****************************************************************************************************************************************************************************
*/
global class UpdateOpportunityNameBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private List<Opportunity> incomingOppNewList;
    private Boolean isOnlyTemplates;
    
    global UpdateOpportunityNameBatch(list<Opportunity> incomingOppNewList, Boolean isOnlyTemplates) {
        this.incomingOppNewList = incomingOppNewList ?? new List<opportunity>();
        this.isOnlyTemplates = isOnlyTemplates ?? false;
    }
    
    global List<Opportunity> start(Database.BatchableContext bc) {
        return incomingOppNewList;
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> lstOpportunities) {
        if(isOnlyTemplates) {
            OpportunityService.generateTemplateOppName(lstOpportunities, null);
        }

        TriggerHandler.bypass('OpportunityTriggerHandler');//HRP-12136
        Database.SaveResult[] updateResults = Database.update(lstOpportunities, false);
        TriggerHandler.clearBypass('OpportunityTriggerHandler');//HRP-12136
            
        if(!updateResults.isEmpty()) {
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLogWithObjectId(
                updateResults, 
                'UpdateOpportunityName', 
                'UpdateOpportunityNameBatch',
                'execute',
                'Error',
                'Update Opportunity Name'
            );
            InsertBsfErrorLog.insertBsfErrors(logList);
            // added Database method and Error log(HRP-10549):End
        }
    }
    
    public void finish(Database.BatchableContext BC) {}

}