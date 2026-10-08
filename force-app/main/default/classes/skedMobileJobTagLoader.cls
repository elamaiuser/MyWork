/**
 * Loads existing sked__Job_Tag__c records for a set of Job Ids, flat and keyed by Job Id - same
 * "not a nested subquery" reasoning as skedMobileJobAllocationLoader (a drive shift -> job -> job tag
 * chain needs two levels of relationship subquery, which SOQL doesn't support). Used by
 * skedMobileDriveJobBuilder's jobTag carry-forward merge.
 */
public with sharing class skedMobileJobTagLoader {

    public static Map<Id, List<sked__Job_Tag__c>> loadForJobs(List<Id> jobIds) {
        Map<Id, List<sked__Job_Tag__c>> tagsByJobId = new Map<Id, List<sked__Job_Tag__c>>();
        if (jobIds == null || jobIds.isEmpty()) {
            return tagsByJobId;
        }

        for (sked__Job_Tag__c jobTag : [
            SELECT Id, sked__Job__c, sked__Tag__c, sked__Tag__r.Name, sked__Tag__r.sked__Type__c, sked_SystemCreated__c
            FROM sked__Job_Tag__c
            WHERE sked__Job__c IN :jobIds
        ]) {
            if (!tagsByJobId.containsKey(jobTag.sked__Job__c)) {
                tagsByJobId.put(jobTag.sked__Job__c, new List<sked__Job_Tag__c>());
            }
            tagsByJobId.get(jobTag.sked__Job__c).add(jobTag);
        }
        return tagsByJobId;
    }
}
