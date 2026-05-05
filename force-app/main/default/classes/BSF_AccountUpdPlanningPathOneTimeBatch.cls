public class BSF_AccountUpdPlanningPathOneTimeBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Set<Id> allUpdatedAccountIds = new Set<Id>();
    private String accountStatus;

    public BSF_AccountUpdPlanningPathOneTimeBatch(String accountStatus) {
        this.accountStatus = accountStatus;
    }

    public BSF_AccountUpdPlanningPathOneTimeBatch() {
        this.accountStatus = null;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Planning_Path__c, RecordTypeId, Account_Status__c ' +
                       'FROM Account ' +
                       'WHERE Planning_Path__c = null ' +
                       'AND RecordType.Name = \'Mobile Account\'';

        if (String.isNotBlank(accountStatus)) {
            query += ' AND Account_Status__c = :accountStatus';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {        
        
        for (Account acc : scope) {
            acc.Planning_Path__c = 'Standard';            
            allUpdatedAccountIds.add(acc.Id); 
        }
        
        // This updates 200 at a time, keeping the Flow happy!
        update scope;

        BSF_TaskPlanningService.initializeAccountTaskConfigs(scope);
    }

    public void finish(Database.BatchableContext bc) {
        if (!allUpdatedAccountIds.isEmpty()) {
            Database.executeBatch(new BSF_AccountTaskPlanningCascadeBatch(allUpdatedAccountIds), 50);
        }
    }
}