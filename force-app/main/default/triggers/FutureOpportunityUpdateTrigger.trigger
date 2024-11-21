/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * **********************************************************************************************************************************************************************************
 *  10/02/2024				 Kishore Das		        Logic for HRP-11728(Template Drive Keyword default to Sponsor Keyword on Creation)

 *************************************************************************************************************************************************************************************
*/
trigger FutureOpportunityUpdateTrigger on FutureOpportunityUpdate__e (after insert) {
    for (FutureOpportunityUpdate__e event : Trigger.New) {
        List<String> templateIdStrings = event.TemplateIds__c.split(',');
        
		List<Id> templateIds = new List<Id>();
        for (String idString : templateIdStrings) {
            templateIds.add(Id.valueOf(idString));
        }
        
        Map<Id, Opportunity> templatesWithKeywords = new Map<Id, Opportunity>([
            SELECT Id, Drive_Keyword__c FROM Opportunity WHERE Id IN :templateIds
        ]);
        
        List<opportunity> futureOpportunities = [select Id,name,accountId,Parent_Template_Id__c,Drive_Keyword__c from opportunity 
                                     where stagename != 'Cancelled' AND Drive_date__c > today
                                     AND Parent_Template_Id__c In:templateIds];
		//system.debug('future opportunities '+futureOpportunities.size()+ ' all future opportunities'+futureOpportunities);
        
        for (Opportunity futureOpp : futureOpportunities) {
            if (templatesWithKeywords.containsKey(futureOpp.Parent_Template_Id__c)) {
                futureOpp.Drive_Keyword__c = templatesWithKeywords.get(futureOpp.Parent_Template_Id__c).Drive_Keyword__c;
            }
        }
        Database.SaveResult[] saveResults = Database.Update(futureOpportunities, false);
 
        List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLog(
                saveResults, 
                'UpdateDrivekeyword', 
                'FutureOpportunityUpdateTrigger', 
                'FutureOpportunityUpdateTrigger', 
                'Error', 
                'Error in updating Sponsor keyword for future drives'
            );
            
            if(!errorLogs.isEmpty()) {
                InsertBsfErrorLog.insertBsfErrors(errorLogs);
            }
    }
}