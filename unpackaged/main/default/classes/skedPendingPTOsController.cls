public class skedPendingPTOsController {
    
    public List<UnavailabilityWrapperModel> Unavailabilities {get;set;}
    
    public skedPendingPTOsController() {
        initialize();
    }
    
    private void initialize() {
        List<sked__Availability__c> skedUnavailabilities = [SELECT Id, sked__Start__c, sked__Finish__c, sked__Timezone__c, sked__Type__c,
                                                            sked__Resource__c, sked__Resource__r.Name
                                                            FROM sked__Availability__c
                                                            WHERE sked__Status__c = :skedConstants.AVAILABILITY_STATUS_PENDING
                                                            AND sked__Is_Available__c = FALSE
                                                            ORDER BY sked__Start__c ASC];
        this.Unavailabilities = new List<UnavailabilityWrapperModel>();
        for (sked__Availability__c skedUnavailability : skedUnavailabilities) {
            UnavailabilityWrapperModel wrapper = new UnavailabilityWrapperModel();
            wrapper.Data = skedUnavailability;
            wrapper.StartStr = skedUnavailability.sked__Start__c.format('MM/dd/yyyy hh:mm a z', skedUnavailability.sked__Timezone__c);
            wrapper.FinishStr = skedUnavailability.sked__Finish__c.format('MM/dd/yyyy hh:mm a z', skedUnavailability.sked__Timezone__c);
            this.Unavailabilities.add(wrapper);
        }
    }
    
    public class UnavailabilityWrapperModel {
        public sked__Availability__c Data {get;set;}
        public string StartStr {get;set;}
        public string FinishStr {get;set;}
    }

}