global class skedResourceCalendarController extends skedRacController {
    
    public string resourceId {get;set;}
    
    public skedResourceCalendarController() {
        List<sked__Resource__c> resourceQuery = [SELECT Id
                                                 FROM sked__Resource__c
                                                 WHERE sked__User__c = :UserInfo.getUserId()
                                                 AND sked__Is_Active__c = TRUE];
        this.resourceId = (resourceQuery != NULL && resourceQuery.size() == 1) ? resourceQuery.get(0).Id : NULL;
    }

}