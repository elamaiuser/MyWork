public class skedUpdateJobAddressBatch implements Database.Batchable<sked__Job__c> {

        Set<Id> siteIds; 
        Set<Id> locationIdSet; 
        String query;
        Date toDate; 
        Date fromDate;
        
        public skedUpdateJobAddressBatch() {
            this.query = 'SELECT Id, sked__Location__c, sked__Location__r.sked__Address__c, sked__Location__r.sked__GeoLocation__Latitude__s, sked__Location__r.sked__GeoLocation__Longitude__s, sked__Address__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s FROM sked__Job__c WHERE sked_Address_Mismatched__c != FALSE AND sked_Drive__r.sked_Drive_Date__c >= TODAY AND sked__Job_Status__c != \'skedConstants.JOB_STATUS_CANCELLED\'';
        }
        
        public skedUpdateJobAddressBatch(Set<Id> inputSiteIds) {
            this.siteIds = inputSiteIds;
            system.debug('this.siteIds :: '+this.siteIds);
            system.debug('siteIds :: '+siteIds);
            this.query = 'SELECT Id, sked__Location__c, sked__Location__r.sked__Address__c, sked__Location__r.sked__GeoLocation__Latitude__s, sked__Location__r.sked__GeoLocation__Longitude__s, sked__Address__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s FROM sked__Job__c WHERE sked_Address_Mismatched__c != FALSE AND sked__Location__c IN : siteIds AND sked_Drive__r.sked_Drive_Date__c >= TODAY AND sked__Job_Status__c != \'skedConstants.JOB_STATUS_CANCELLED\'';
        }
        
        public skedUpdateJobAddressBatch(Date toDate, Date fromDate) {
            this.toDate = toDate;
            this.fromDate = fromDate;
            this.query = 'SELECT Id, sked__Location__c, sked__Location__r.sked__Address__c, sked__Location__r.sked__GeoLocation__Latitude__s, sked__Location__r.sked__GeoLocation__Longitude__s, sked__Address__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s FROM sked__Job__c WHERE sked_Address_Mismatched__c != FALSE AND sked_Drive__r.sked_Drive_Date__c >= :toDate AND sked_Drive__r.sked_Drive_Date__c <= :fromDate AND sked__Job_Status__c != \'skedConstants.JOB_STATUS_CANCELLED\'';
        }
    

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);  
    }

    global void execute(SchedulableContext cc) {
        Database.executeBatch(new skedUpdateJobAddressBatch(),200);
    }
    
    public void execute(Database.BatchableContext BC, List<sked__Job__c> impactedJobs) {
        List<sked__Job__c> jobsToUpdate = new List<sked__Job__c>();
        set<Id> locationIdSet = new set<Id>();
        for (sked__Job__c impactedJob : impactedJobs) {
            Boolean hasChange = false;
            if(impactedJob.sked__Address__c != impactedJob.sked__Location__r.sked__Address__c) {

                impactedJob.sked__Address__c = impactedJob.sked__Location__r.sked__Address__c;   
                hasChange = true;
            }
            if (impactedJob.sked__GeoLocation__Latitude__s != impactedJob.sked__Location__r.sked__GeoLocation__Latitude__s || 
                    impactedJob.sked__GeoLocation__Longitude__s != impactedJob.sked__Location__r.sked__GeoLocation__Longitude__s) {
                impactedJob.sked__GeoLocation__Latitude__s = impactedJob.sked__Location__r.sked__GeoLocation__Latitude__s;   
                impactedJob.sked__GeoLocation__Longitude__s = impactedJob.sked__Location__r.sked__GeoLocation__Longitude__s; 
                hasChange = true;
            }
            if (hasChange) {
                jobsToUpdate.add(impactedJob);
            
                locationIdSet.add(impactedJob.sked__Location__c);
                //Database.executeBatch(new skedTTChangeDCROnAddressChangeBatch(mapSiteWithAddressChanged.keySet()));
            } 
        }

        if (jobsToUpdate.size() > 0) {
            skedHubBase.BypassUpdateTriggers = TRUE;
            update jobsToUpdate;
            skedHubBase.BypassUpdateTriggers = FALSE;
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
    
}