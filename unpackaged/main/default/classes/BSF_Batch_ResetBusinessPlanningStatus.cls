global class BSF_Batch_ResetBusinessPlanningStatus implements Database.Batchable<ResetBusinessPlanningStatusHelper.getValues>
{
    global List<ResetBusinessPlanningStatusHelper.getValues> valuesList;
    
    global BSF_Batch_ResetBusinessPlanningStatus(List<ResetBusinessPlanningStatusHelper.getValues> values)
    {
		this.valuesList = new List<ResetBusinessPlanningStatusHelper.getValues>();
        this.valuesList = values;        
    }
    
    global Iterable<ResetBusinessPlanningStatusHelper.getValues> start(Database.BatchableContext BC)
    {
        // fetching all accounts in the system where Business_Planning_Completed__c is checked
        return this.valuesList;
    }
    
    global void execute(Database.BatchableContext BC, List<object> scope) 
    {
        List<ResetBusinessPlanningStatusHelper.getValues> getValuesList = (List<ResetBusinessPlanningStatusHelper.getValues>)scope;
        List<Account> accountsToBeUpdated = new List<Account>();
        accountsToBeUpdated = getValuesList.get(0).accListToBeUpdated;
        
        if(!accountsToBeUpdated.isEmpty())
        {
            for(Account acc : accountsToBeUpdated)
        	{
                acc.Business_Planning_Completed__c = FALSE;
                acc.Business_Planning_Completed_By__c = NULL;
                acc.Business_Planning_Completed_Date__c = NULL;
       		}
        
            Database.saveResult[] updateAccList = Database.update(accountsToBeUpdated, FALSE);
            List<BSF_Error_Log__c> errorLogList = BSF_Utilities.createErrorLog(updateAccList, 'Error in blanking out Business Planning fields', 'BSF_Batch_ResetBusinessPlanningStatus', 'execute', 'Error', 'Error during update');
            Insert errorLogList;
        }
    }
    
    global void finish(Database.BatchableContext BC) 
    {}

}