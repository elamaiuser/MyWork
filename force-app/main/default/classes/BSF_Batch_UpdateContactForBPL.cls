global class BSF_Batch_UpdateContactForBPL implements Database.Batchable<sObject>, Schedulable {
    global static final String QUERY_STR = 'SELECT Id, Account__c, Contact__c FROM Account_Service_Role__c WHERE Account_Service_Role__c = \'Blood Program Leader\' AND Start_Date__c = TODAY AND (End_Date__c = null OR End_Date__c > TODAY) ORDER BY Account__c, CreatedDate ASC';
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(this, 200);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(QUERY_STR);
    }

    global void execute(Database.BatchableContext bc, List<Account_Service_Role__c> records) {
        Map<Id, Id> accountIdToContactIdMap = new Map<Id, Id>();
        for (Account_Service_Role__c record : records) {
            accountIdToContactIdMap.put(record.Account__c, record.Contact__c);
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountIdToContactIdMap.keySet()) {
            Account account = new Account(Id = accountId, Contact_BPL__c = accountIdToContactIdMap.get(accountId));
            accountsToUpdate.add(account);
        }

        if(!accountsToUpdate.isEmpty()){
        	update accountsToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {}
}