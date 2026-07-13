global class skedBiddingExpirationBatch implements Database.Batchable<sked__Availability__c> {

    global skedBiddingExpirationBatch() {}
    
    global List<sked__Availability__c> start(Database.BatchableContext bc) {
        Date currentDate = system.today();
        return [SELECT Id, sked_Custom_Status__c, sked__Status__c
                FROM sked__Availability__c
                WHERE sked_Start_Date__c < :currentDate
                AND sked__Status__c != :skedConstants.AVAILABILITY_STATUS_APPROVED
                AND sked__Status__c != :skedConstants.AVAILABILITY_STATUS_DECLINED];
    }

    global void execute(Database.BatchableContext bc, List<sked__Availability__c> scope) {
        List<sked__Availability__c> availabilityList = scope;
        for (sked__Availability__c availability : availabilityList) {
            availability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_EXPIRED;
        }

        Database.SaveResult[] updateResults = Database.update(availabilityList, false);
        insert new List<BSF_Error_Log__c>(BSF_Utilities.createErrorLogWithObjectId(
            updateResults,
            'Expire Past-Dated PTOs',
            'skedBiddingExpirationBatch',
            'execute',
            'Error',
            'Update Past-Dated PTOs to Expired'
        ));
    }

    global void finish(Database.BatchableContext bc) {}

}