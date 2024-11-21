global class skedResourceRoleMaintenanceBatch implements System.Schedulable, Database.Batchable<sked__Resource_Tag__c> {

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedResourceRoleMaintenanceBatch(), 200);
    }
    
    global List<sked__Resource_Tag__c> start(Database.BatchableContext BC) {
        Date currentDate = system.today();
        return [SELECT Id, sked_Role_Status__c
                FROM sked__Resource_Tag__c
                WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                AND sked_Expiry_Date__c != NULL
                AND sked_Expiry_Date__c < :currentDate
                AND sked_Role_Status__c != :skedConstants.TAG_ROLE_STATUS_INACTIVE
                LIMIT 50000];
    }

    global void execute(Database.BatchableContext BC, List<sked__Resource_Tag__c> records) {
        for (sked__Resource_Tag__c record : records) {
            record.sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_INACTIVE;
        }
        update records;
    }
    
    global void finish(Database.BatchableContext BC) {}
    
}