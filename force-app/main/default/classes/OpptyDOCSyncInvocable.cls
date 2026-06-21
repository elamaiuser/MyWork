public without sharing class OpptyDOCSyncInvocable {

    @InvocableMethod(
        label='Opportunity DOC Sync'
        description='Updates Opportunity fields from Flow with bulk-safe DML and error handling'
        category='Opportunity'
    )
    public static List<String> updateOppty(List<InputWrapper> invocableInput) {
        InputWrapper inputFields = invocableInput[0];
        List<String> results = new List<String>();
        List<Opportunity> opptysToUpdate = new List<Opportunity>();
        List<BSF_Error_Log__c> bsfErrorList = new List<BSF_Error_Log__c>();
        
        Opportunity oppty = new Opportunity(Id = inputFields.Id);
        
        try {
            if (inputFields.X2RBCAssets != null) {
                oppty.Number_of_2RBC_Assets__c = Integer.valueOf(inputFields.X2RBCAssets); 
            }
    
            opptysToUpdate.add(oppty);
    
            
            if (!opptysToUpdate.isEmpty()) {
                skedHubBase.BypassUpdateTriggers = true;
                TriggerHandler.bypass('AccountTriggerHandler');
                TriggerHandler.bypass('DriveTriggerHandler');
                TriggerHandler.bypass('SiteTriggerHandler');
                TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
                TriggerHandler.bypass('OpportunityTriggerHandler');
                TriggerHandler.bypass('OpportunitySplitTriggerHandler');
                
                Database.SaveResult[] srList = Database.update(opptysToUpdate, false);
                
                skedHubBase.BypassUpdateTriggers = false;
                triggerHandler.clearAllBypasses();
                
    			List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Sync Opportunity with DOC','OpptyDOCSyncInvocable','updateOppty','Error','Error in syncing Opportunity');
            	InsertBsfErrorLog.insertBsfErrors(logList);
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        results.add('Success');
                    } else {
                        results.add('Error');
                    }
                }
            }
            if(Test.isRunningTest() && BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION) {
                throw new OpptyDOCSyncCustomException('Something went wrong!!!');
            }
        } catch(Exception ex){
            bsfErrorList.add(BSF_Utilities.createBsfErrorLogForExceptions(ex,'OpptyDOCSyncInvocable','updateOppty','Update Opportunity', 'Error in syncing Opportunity','Opportunity',inputFields.Id));
            Database.insert(bsfErrorList, true);
        }

        

        return results;
    }

    
    public class InputWrapper {
        @InvocableVariable(label='Opportunity Id' required=true)
        public String Id;
        @InvocableVariable(label='# of 2RBC Assets')
        public String X2RBCAssets;
    }
    
    private class OpptyDOCSyncCustomException extends Exception {}
}