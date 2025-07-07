public class BSF_Batch_UpdateSpecialCircumstanceOnOpp implements Database.Batchable<sObject>, Database.Stateful {

    private String operation;
    private List<Opportunity> oppListToBeUpdated;
    private string lastId = '';
    private Boolean massOperation = false;
    private final Integer RECORD_LIMIT = 100;
    private final Id MOBILE_ACCOUNT_RECTYPEID = SObjectType.Account.getRecordTypeInfosByName().get('Mobile Account').getRecordTypeId();

    public BSF_Batch_UpdateSpecialCircumstanceOnOpp(String operation, List<Opportunity> oppListToBeUpdated) {
        this.operation = operation;
        this.oppListToBeUpdated = new List<Opportunity>(oppListToBeUpdated);
    }

    public BSF_Batch_UpdateSpecialCircumstanceOnOpp(String operation, List<Id> accountIds) {
        this.operation = operation;
        this.oppListToBeUpdated = (List<Opportunity>)(Database.query(getQueryString(accountIds, this.operation)));
    }

    // Purpose: Used to mass addition or removal of 'First Time Drive' flag on opportunity
    public BSF_Batch_UpdateSpecialCircumstanceOnOpp(String operation, string lastId) {
        this.operation = operation;
        this.lastId = lastId;
        this.massOperation = true;

        Map<Id, Account> map_accountId_accountWithNoCompletedDrives = new Map<Id, Account>([
            SELECT Id
            FROM Account
            WHERE RecordTypeId = :MOBILE_ACCOUNT_RECTYPEID
            AND Id NOT IN 
                (
                    SELECT sked_Account__c
                    FROM sked_Drive__c
                    WHERE sked_Status__c = :BSF_Constants.DOC_STATUS_COMPLETE
                )
            AND Id > :this.lastId
            ORDER BY Id ASC LIMIT :this.RECORD_LIMIT
        ]);

        if(map_accountId_accountWithNoCompletedDrives.keySet().isEmpty()) {
            this.oppListToBeUpdated = new List<Opportunity>();
        } else {
            this.lastId = map_accountId_accountWithNoCompletedDrives.values().get(map_accountId_accountWithNoCompletedDrives.size() - 1).Id;
            List<Id> accIdList = new List<Id>(map_accountId_accountWithNoCompletedDrives.keySet());
            this.oppListToBeUpdated = (List<Opportunity>)(Database.query(getQueryString(accidList, this.operation)));
        }
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

    public void finish(Database.BatchableContext BC) {
        if(this.massOperation) {
            List<Account> remainingRecordQuery = [
                SELECT Id
                FROM Account
                WHERE RecordTypeId = :MOBILE_ACCOUNT_RECTYPEID
                AND Id NOT IN 
                    (
                        SELECT sked_Account__c
                        FROM sked_Drive__c
                        WHERE sked_Status__c = :BSF_Constants.DOC_STATUS_COMPLETE
                    )
                AND Id > :this.lastId
                ORDER BY Id ASC 
                LIMIT 1
            ];

            if (!remainingRecordQuery.isEmpty()) {
                if (!Test.isRunningTest()) {
                    BSF_Batch_UpdateSpecialCircumstanceOnOpp batch = new BSF_Batch_UpdateSpecialCircumstanceOnOpp(this.operation, this.lastId);
                    Database.executeBatch(batch, 200);
                }
            }
        }
    }

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

    private String getQueryString(List<Id> accIdsToProcess, String operation) {
        String firstTimeDriveFlagStr = String.join(new List<String>{BSF_Constants.SSBS_BADGE_FIRST_TIME_DRIVE}, '\',\'');
        String accIdsStr = String.join(new List<String>((List<String>)accIdsToProcess), '\',\'');

        String query = 'SELECT Id, AccountId, Special_Circumstances__c FROM Opportunity WHERE AccountId IN (\'' + accIdsStr + '\') AND ';
        query += 'Special_Circumstances__c ' + (operation == 'Addition' ? 'EXCLUDES' : 'INCLUDES') + ' (\'' + firstTimeDriveFlagStr + '\') ';
        query += 'AND Is_Template__c = FALSE AND Type_of_Drive__c = \'Mobile\' ';

        return query;
    }
    
}