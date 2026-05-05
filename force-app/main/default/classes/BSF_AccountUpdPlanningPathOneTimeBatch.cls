public class BSF_AccountUpdPlanningPathOneTimeBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Set<Id> allUpdatedAccountIds = new Set<Id>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Planning_Path__c, RecordTypeId, Account_Status__c
            FROM Account 
            WHERE Planning_Path__c = null 
            AND RecordType.Name = 'Mobile Account'
            AND Account_Status__c = 'Active'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Bypass your Apex Trigger
        // TriggerHandler.bypass('handleTaskPlanningPathChange'); // <-- Use your org's bypass

        Set<Id> chunkAccountIds = new Set<Id>();
        for (Account acc : scope) {
            acc.Planning_Path__c = 'Standard';
            chunkAccountIds.add(acc.Id);
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