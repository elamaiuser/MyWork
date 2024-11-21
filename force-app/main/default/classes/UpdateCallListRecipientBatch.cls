global class UpdateCallListRecipientBatch implements Database.Batchable<SObject>, Database.Stateful {
    global Integer updateCounter = 0;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [SELECT Id, Drive_Date__c, Call_List_Recipient_Exist__c 
             FROM Opportunity 
             WHERE (Drive_Date__c > :System.today() 
             OR (Is_Template__c =true AND Template_Status__c ='Active'))] 
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Map<Id, Boolean> oppCallListRecipientMap = new Map<Id, Boolean>();
        
        for (Opportunity opp : scope) {
            oppCallListRecipientMap.put(opp.Id, false);
        }
        
        for (OpportunityContactRole ocr : [SELECT Id, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId IN :oppCallListRecipientMap.keyset()]) {
            if (ocr.Role == System.Label.callListRecipient) { 
                oppCallListRecipientMap.put(ocr.OpportunityId, true);
            }
        }
        for (Opportunity opp : scope) {
            if (opp.Call_List_Recipient_Exist__c != oppCallListRecipientMap.get(opp.Id)) {
                opp.Call_List_Recipient_Exist__c = oppCallListRecipientMap.get(opp.Id);
                oppsToUpdate.add(opp);
            }
        }
        updateCounter += oppsToUpdate.size();
        
        
        if(!oppsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(oppsToUpdate, false);
            List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLog(
                updateResults, 
                'CallListRecipientFlagUpdate', 
                'UpdateCallListRecipientBatch', 
                'execute', 
                'Error', 
                'Error in updating Call_List_Recipient_Exist__c'
            );
            
            if(!errorLogs.isEmpty()) {
                InsertBsfErrorLog.insertBsfErrors(errorLogs);
            }
        }
		
    }
    
    
    global void finish(Database.BatchableContext bc) {
    	System.debug('Total Opportunities updated: ' + updateCounter);    
    }
    
    
}