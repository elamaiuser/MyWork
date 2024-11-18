/*@Description:  1. This batch will get triggered whenever user tries to close a FS Account
				 2. It will try to cancel related future non-cancelled opportunities and drives

* Modification Log 

*   Date					Developer Name			    Comments
* **********************************************************************
* 02/20/2024			     Priti Jana			 Logic for HRP-11936
* **********************************************************************/

global class Bsf_BatchCancelBloodDrivePendingOpp implements Database.Batchable<sObject>{
    global Id accId;
    global date selEffectiveDate;
    global String closureReason;
    
    global Bsf_BatchCancelBloodDrivePendingOpp(Id accId,date selEffectiveDate,string closureReason){
        this.accId = accId;
        this.selEffectiveDate = selEffectiveDate;
        this.closureReason = closureReason;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        List<String> excludedOppStageNames = new List<String>{BSF_Constants.STAGE_CANCELLED};
        String query = 'SELECT Id,Start_Time__c,End_Time__c,Online_Scheduling_Enabled__c, '+
            			' AccountId, Name, Description, StageName,Drive_Date__c '+
            			' FROM Opportunity WHERE AccountId =:accId '+
            			' AND StageName NOT IN :excludedOppStageNames '+ 
            			' AND Drive_Date__c >= :selEffectiveDate';
        
        return Database.getQueryLocator(query); 		
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> listOfOpportunity){
       
        for (Opportunity opp : listOfOpportunity){
            
            // HRP-11936 --> Starts Here
            opp.StageName = BSF_Constants.STAGE_CANCELLED;
            opp.Initiated_By__c = BSF_Constants.ARC_INITIATED_FIXED ;
            opp.sked_Cancellation_Reason__c = BSF_Constants.ARC_MANAGEMENT_CANCELLATION_REASON;
            //opp.Start_Time__c = System.now().time();
            //opp.End_Time__c = System.now().addMinutes(5).time();
            opp.Online_Scheduling_Enabled__c = 'No';
        } 
        	closeFixedSiteAccountController.closeFSAccount(accId,selEffectiveDate,closureReason);
            Database.SaveResult[] oppUpdateList = Database.Update(listOfOpportunity,FALSE);
        	List<BSF_Error_Log__c> errorLogsToInsert = BSF_Utilities.createErrorLog(oppUpdateList, 'Opp Cancellation on Account Closure', 'Bsf_BatchCancelBloodDrivePendingOpp', 'execute method', 'error', 'Error during Opp/DOC Update');            
        	if(!errorLogsToInsert.isEmpty() && errorLogsToInsert.size() > 0){
            	Insert errorLogsToInsert;
        	}
            // HRP-11936 --> Starts Here
        
    }
    
    global void finish(Database.BatchableContext BC){}

}