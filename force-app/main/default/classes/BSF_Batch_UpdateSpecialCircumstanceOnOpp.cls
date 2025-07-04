public class BSF_Batch_UpdateSpecialCircumstanceOnOpp implements Database.Batchable<sObject>, Database.Stateful {

    private String operation;
    private List<Opportunity> oppListToBeUpdated;
    private Set<Id> accIdsToProcess;

    public BSF_Batch_UpdateSpecialCircumstanceOnOpp(String operation, List<Opportunity> oppListToBeUpdated) {
        this.operation = operation;
        this.oppListToBeUpdated = new List<Opportunity>(oppListToBeUpdated);
    }

    public BSF_Batch_UpdateSpecialCircumstanceOnOpp(String operation, Set<Id> accountIds) {
        this.operation = operation;
        this.accIdsToProcess = new Set<Id>(accountIds);
        String firstTimeDriveFlag = String.join(new List<String>{BSF_Constants.SSBS_BADGE_FIRST_TIME_DRIVE}, '\',\'');
        String query = 'SELECT Id, AccountId, Special_Circumstances__c FROM Opportunity WHERE AccountId IN :accIdsToProcess AND ';
        query += 'Special_Circumstances__c ' + (this.operation == 'Addition' ? 'EXCLUDES' : 'INCLUDES') + ' (\'' + firstTimeDriveFlag + '\') ';
        query += 'AND Is_Template__c = FALSE AND Type_of_Drive__c = \'Mobile\' ';
        this.oppListToBeUpdated = (List<Opportunity>)(Database.query(query));
    }

    public Iterable<sObject> start(Database.BatchableContext BC) {
        return this.oppListToBeUpdated;
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;

        if(this.operation.equalsIgnoreCase('Removal')) {
            removeFirstTimeDriveFlag(scope);
        } else if(this.operation.equalsIgnoreCase('Addition')) {
            addFirstTimeDriveFlag(scope);
        }

        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        skedHubBase.BypassUpdateTriggers = false;
    }

    public void finish(Database.BatchableContext BC) {}

    /*************************************************************** Private Methods ************************************************************/
    private void removeFirstTimeDriveFlag(List<Opportunity> oppList) {
        oppList = BSF_Utilities.getOpportunitiesWithFirstTimeFlagRemoved(oppList);
        Database.SaveResult[] updateResults = Database.Update(oppList, false);
        insertBsfErrorLogEntries(updateResults);
    }

    private void addFirstTimeDriveFlag(List<Opportunity> oppList) {
        oppList = BSF_Utilities.getOpportunitiesWithFirstTimeFlagAdded(oppList);
        Database.SaveResult[] updateResults = Database.Update(oppList, false);
        insertBsfErrorLogEntries(updateResults);
    } 

    private void insertBsfErrorLogEntries(Database.SaveResult[] updateResults) {
         List<BSF_Error_Log__c> errorlogEntries = BSF_Utilities.createErrorLogWithObjectId(
            updateResults,
            this.operation + ' of First Time Flag from Opportunities',
            'BSF_Batch_UpdateSpecialCircumstanceOnOpp',
            'execute',
            'Error',
            'First Time Drive Flag' + operation
        );
        insert errorlogEntries;
    }
    
}