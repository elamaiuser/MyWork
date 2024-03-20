global class skedConvertBiddingToStandardBatch implements Database.Batchable<sked_Staffing_Budget__c> {
    
    global skedConvertBiddingToStandardBatch() {}
     
    global List<sked_Staffing_Budget__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Request_Type__c
                FROM sked_Staffing_Budget__c
                WHERE sked_Convert_to_Standard_On__c = :system.today()];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Staffing_Budget__c> records) {
        for (sked_Staffing_Budget__c record : records) {
            record.sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_STANDARD;
        }
        update records;
    }
    
    global void finish(Database.BatchableContext BC) {}

}