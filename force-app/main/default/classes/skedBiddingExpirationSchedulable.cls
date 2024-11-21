global class skedBiddingExpirationSchedulable implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        Date currentDate = system.today();
        List<sked__Availability__c> availabilityList = [SELECT Id, sked_Custom_Status__c, sked__Status__c
                                                        FROM sked__Availability__c
                                                        WHERE sked_Start_Date__c < :currentDate
                                                        AND sked__Status__c != :skedConstants.AVAILABILITY_STATUS_APPROVED
                                                        AND sked__Status__c != :skedConstants.AVAILABILITY_STATUS_DECLINED];
        if (!availabilityList.isEmpty()) {
            for (sked__Availability__c availability : availabilityList) {
                availability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_EXPIRED;
            }
            update availabilityList;
        }
    }

}