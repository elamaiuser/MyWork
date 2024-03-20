global class skedAccountTagDeleteBatch implements Database.Batchable<sked__Account_Tag__c>, Database.Stateful {
    private Set<Id> jobIds;
    private Set<Id> driveShiftIds;
    
    List<sked__Account_Tag__c> accountTags;
    global skedAccountTagDeleteBatch(List<sked__Account_Tag__c> accountTags) {
        this.accountTags = accountTags;
    }

    global List<sked__Account_Tag__c> start(Database.BatchableContext BC) {
        this.jobIds = new Set<Id>();
        this.driveShiftIds = new Set<Id>();
        return this.accountTags;
    }

    global void execute(Database.BatchableContext BC, List<sked__Account_Tag__c> accountTags) {
        Map<Id, Set<Id>> deletedTagsByAccount = new Map<Id, Set<Id>>();
        Set<Id> allDeletedTagIds = new Set<Id>();
        for (sked__Account_Tag__c accountTag : accountTags) {
            Set<Id> deletedTags = deletedTagsByAccount.get(accountTag.sked__Account__c);

            if (deletedTags == null) {
                deletedTags = new Set<Id>();
            }
            
            deletedTags.add(accountTag.sked__Tag__c);
            deletedTagsByAccount.put(accountTag.sked__Account__c, deletedTags);
            allDeletedTagIds.add(accountTag.sked__Tag__c);
        }

        if (!deletedTagsByAccount.keySet().isEmpty()) {
            List<SObject> recordsToDelete = new List<SObject>();

            List<sked_Drive_Shift_Tag__c> potentialDriveShiftTagsToDelete = [
                SELECT Id, sked_Drive_Shift__c, sked_Drive_Shift__r.sked_Drive_Account__c, sked_Tag__c
                FROM sked_Drive_Shift_Tag__c
                WHERE sked_Tag__c IN :allDeletedTagIds
                AND sked_Drive_Shift__r.sked_Drive_Account__c IN :deletedTagsByAccount.keySet()
                AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_COMPLETE
            ];

            for (sked_Drive_Shift_Tag__c driveShiftTag : potentialDriveShiftTagsToDelete) {
                Set<Id> deletableTagIdsForAccount = deletedTagsByAccount.get(driveShiftTag.sked_Drive_Shift__r.sked_Drive_Account__c);
                
                if (deletableTagIdsForAccount != null) {
                    if (deletableTagIdsForAccount.contains(driveShiftTag.sked_Tag__c)) {
                        this.driveShiftIds.add(driveShiftTag.sked_Drive_Shift__c);
                        recordsToDelete.add(driveShiftTag);
                    }
                }
            }

            List<sked__Job_Tag__c> potentialJobTagsToDelete = [
                SELECT Id, sked__Job__c, sked__Job__r.sked_Drive__r.sked_Account__c, sked__Tag__c
                FROM sked__Job_Tag__c
                WHERE sked__Tag__c IN :allDeletedTagIds
                AND sked__Job__r.sked_Drive__r.sked_Account__c IN :deletedTagsByAccount.keySet()
                AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_COMPLETE
            ];

            for (sked__Job_Tag__c jobTag : potentialJobTagsToDelete) {
                Set<Id> deletableTagIdsForAccount = deletedTagsByAccount.get(jobTag.sked__Job__r.sked_Drive__r.sked_Account__c);
                
                if (deletableTagIdsForAccount != null) {
                    if (deletableTagIdsForAccount.contains(jobTag.sked__Tag__c)) {
                        this.jobIds.add(jobTag.sked__Job__c);
                        recordsToDelete.add(jobTag);
                    }
                }
            }

            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            skedTriggerUtils.updateJobAllocations(this.jobIds, this.driveShiftIds);
        }
    }
}