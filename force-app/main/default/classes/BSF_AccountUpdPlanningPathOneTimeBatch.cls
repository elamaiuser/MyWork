global class BSF_AccountUpdPlanningPathOneTimeBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    public Set<Id> allUpdatedAccountIds = new Set<Id>();
    Set<Id> accountIdSet = new set<Id>();
    private Set<String> accountStatus;
    private Boolean isScheduledRun = false;
    private Boolean filterByPlanningPath = false;
    private final Integer batchSize = Integer.valueOf(Label.BSF_AccountUpdPlanningPathOneTimeBatch_BatchSize);

    public BSF_AccountUpdPlanningPathOneTimeBatch() {}

    public BSF_AccountUpdPlanningPathOneTimeBatch(Boolean filterByPlanningPath, Set<String> accountStatus, Set<Id> accountIdSet) {
        this.accountStatus = accountStatus;
        this.accountIdSet = accountIdSet;
        this.filterByPlanningPath = filterByPlanningPath;
    }

    global void execute(SchedulableContext cc) {
        this.isScheduledRun = true;
        Database.executeBatch(this, batchSize);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Planning_Path__c, RecordTypeId, Account_Status__c ' +
                       'FROM Account ' +
                       'WHERE RecordType.Name = \'Mobile Account\'';

        if (filterByPlanningPath) {
            query += ' AND Planning_Path__c = null';
        }

        if (this.isScheduledRun) {
            query += ' AND Id NOT IN ( SELECT Account__c FROM Task_Planning_Default__c WHERE Account__c !=null ) ';
        }

        if (accountStatus != null && !accountStatus.isEmpty()) {
            query += ' AND Account_Status__c IN :accountStatus';
        }

        if (accountIdSet != null && !accountIdSet.isEmpty()) {
            query += ' AND Id IN :accountIdSet';
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
            Database.executeBatch(new BSF_AccountTaskPlanningCascadeBatch(allUpdatedAccountIds), batchSize);
        }
    }
}