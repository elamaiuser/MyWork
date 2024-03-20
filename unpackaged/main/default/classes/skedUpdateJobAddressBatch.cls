public class skedUpdateJobAddressBatch implements Database.Batchable<sked__Job__c> {

    protected Set<Id> siteIds; 
    
    public skedUpdateJobAddressBatch(Set<Id> inputSiteIds) {
        this.siteIds = inputSiteIds;
    }
    
    public List<sked__Job__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked__Location__r.sked__Address__c, 
                sked__Location__r.sked__GeoLocation__Latitude__s, sked__Location__r.sked__GeoLocation__Longitude__s, 
                sked__Address__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s
                FROM sked__Job__c
                WHERE sked__Location__c IN :this.siteIds
                AND sked_Drive__r.sked_Drive_Date__c > TODAY
                AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED];   
    }
    
    public void execute(Database.BatchableContext BC, List<sked__Job__c> impactedJobs) {
        for (sked__Job__c impactedJob : impactedJobs) {
            impactedJob.sked__Address__c = impactedJob.sked__Location__r.sked__Address__c;
            impactedJob.sked__GeoLocation__Latitude__s = impactedJob.sked__Location__r.sked__GeoLocation__Latitude__s;
            impactedJob.sked__GeoLocation__Longitude__s = impactedJob.sked__Location__r.sked__GeoLocation__Longitude__s;
        }
        skedHubBase.BypassUpdateTriggers = TRUE;
        update impactedJobs;
        skedHubBase.BypassUpdateTriggers = FALSE;
    }
    
    public void finish(Database.BatchableContext BC) {}
    
}