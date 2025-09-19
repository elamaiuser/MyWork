global class BSF_Batch_ResetBusinessPlanningStatus implements Database.Batchable<SObject> {
    //global List<ResetBusinessPlanningStatusHelper.getValues> valuesList;
    
    /*global BSF_Batch_ResetBusinessPlanningStatus(List<ResetBusinessPlanningStatusHelper.getValues> values)
    {
		this.valuesList = new List<ResetBusinessPlanningStatusHelper.getValues>();
        this.valuesList = values;        
    }*/
    global final String soql;

    global BSF_Batch_ResetBusinessPlanningStatus(String soql) {
        this.soql = soql;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(soql);
    }
    /*global Iterable<ResetBusinessPlanningStatusHelper.getValues> start(Database.BatchableContext BC)
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
    }*/
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accounts = (List<Account>)scope;

        for (Account acc : accounts) {
            acc.Business_Planning_Completed__c = false;
            acc.Business_Planning_Completed_By__c = null;
            acc.Business_Planning_Completed_Date__c = null;
        }

        Database.SaveResult[] sr = Database.update(accounts, false);

        try {
            List<BSF_Error_Log__c> logs = BSF_Utilities.createErrorLog(
                sr,
                'Error in blanking out Business Planning fields',
                'BSF_Batch_ResetBusinessPlanningStatus',
                'execute',
                'Error',
                'Error during update'
            );
            if (!logs.isEmpty()) insert logs;
        } catch (Exception ignore) {}
    }
    
    global void finish(Database.BatchableContext BC) 
    {}

}