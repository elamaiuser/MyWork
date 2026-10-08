/**
 * Loads existing job allocations for a set of Job Ids, keyed by Job Id, for anything that needs to
 * inspect a job's current allocations before regenerating it. Currently used by allocation
 * carry-forward.
 *
 * A flat query, not a nested relationship subquery - SOQL only supports one level of relationship
 * subquery, and a drive shift -> job -> job allocation query would need two.
 */
public with sharing class skedMobileJobAllocationLoader {

    public static Map<Id, List<sked__Job_Allocation__c>> loadForJobs(List<Id> jobIds) {
        Map<Id, List<sked__Job_Allocation__c>> allocationsByJobId = new Map<Id, List<sked__Job_Allocation__c>>();
        if (jobIds == null || jobIds.isEmpty()) {
            return allocationsByJobId;
        }

        for (sked__Job_Allocation__c allocation : [
            SELECT Id, sked__Job__c, sked__Resource__c, sked__Status__c, sked_Travel_Time_To__c, sked_Travel_Time_Back__c,
                sked_Is_Relocated_Resource__c, sked_Is_Locked__c, sked__Resource__r.sked_Pres_Donor_Capacity__c
            FROM sked__Job_Allocation__c
            WHERE sked__Job__c IN :jobIds AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
        ]) {
            if (!allocationsByJobId.containsKey(allocation.sked__Job__c)) {
                allocationsByJobId.put(allocation.sked__Job__c, new List<sked__Job_Allocation__c>());
            }
            allocationsByJobId.get(allocation.sked__Job__c).add(allocation);
        }
        return allocationsByJobId;
    }

    // Null-safe "does this job (which may not exist, e.g. jobId == null for a brand new job) have any active allocation" check.
    public static Boolean hasAnyAllocation(Map<Id, List<sked__Job_Allocation__c>> allocationsByJobId, Id jobId) {
        return jobId != null && allocationsByJobId.containsKey(jobId) && !allocationsByJobId.get(jobId).isEmpty();
    }
}
