global class skedEmailHandlerController {
    private static final String MY_AVAILABILITY_CONSOLE_URL = '/apex/skedMyAvailabilityConsole';
    public skedEmailHandlerController() {}

    public string getAvailabilityUrl() {
        String availabilityId = '?availabilityId=' + ApexPages.currentPage().getParameters().get('availabilityId');
        String startDate = '&startDate=' + ApexPages.currentPage().getParameters().get('startDate');
        return URL.getOrgDomainUrl().toExternalForm() + MY_AVAILABILITY_CONSOLE_URL + availabilityId + startDate;
    }
    
    @RemoteAction
    global static boolean confirmAvailability(Id availabilityId, string action, string token) {
        boolean isProcessed = FALSE;
        if (action == 'View') {
            isProcessed = TRUE;
        }
        else if (availabilityId.getSobjectType().getDescribe().getName() == 'sked__Availability__c') {
            List<sked__Availability__c> availabilities = [SELECT Id, Name, sked_Custom_Status__c, sked_Waitlist_Confirmed__c
                                                          FROM sked__Availability__c
                                                          WHERE Id = :availabilityId
                                                          AND sked_Unique_Key__c = :token
                                                          AND sked__Is_Available__c = FALSE
                                                          AND sked_Waitlist_Confirmed__c = FALSE];
            if (availabilities != NULL && !availabilities.isEmpty()) {
                sked__Availability__c availability = availabilities.get(0);
                if (action == 'Confirm') {
                    availability.sked_Waitlist_Confirmed__c = TRUE;
                    isProcessed = TRUE;
                }
                else if (action == 'Declined') {
                    availability.sked_Custom_Status__c = action;
                    isProcessed = TRUE;
                }
                if (isProcessed) {
                    update availability;
                }
            }
        }
        return isProcessed;
    }
}