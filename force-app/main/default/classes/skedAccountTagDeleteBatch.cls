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
            List<SObject> recordsToUpdate = new List<SObject>();

            List<sked_Drive_Shift_Tag__c> potentialDriveShiftTagsToDelete = [
                SELECT Id, sked_Drive_Shift__c, sked_Drive_Shift__r.sked_Drive_Account__c, sked_Tag__c,
                    sked_Drive_Shift__r.sked_Drive_Site__c
                FROM sked_Drive_Shift_Tag__c
                WHERE sked_Tag__c IN :allDeletedTagIds
                AND sked_Drive_Shift__r.sked_Drive_Account__c IN :deletedTagsByAccount.keySet()
                AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_COMPLETE
            ];

            Set<Id> siteIds = new Set<Id>();
            for (sked_Drive_Shift_Tag__c driveShiftTag : potentialDriveShiftTagsToDelete) {
                siteIds.add(driveShiftTag.sked_Drive_Shift__r.sked_Drive_Site__c);
            }

            Map<Id, sked__Location__c> siteById = new Map<Id, sked__Location__c>([
                SELECT Id, 
                (SELECT Id, sked_Tag__c, sked_Minimum_Quantity__c FROM sked_Location_Tags__r WHERE sked_Required__c = FALSE)
                FROM sked__Location__c
                WHERE Id IN :siteIds
            ]);

            List<sked_Drive_Shift_Tag__c> affectedDriveShiftTags = new List<sked_Drive_Shift_Tag__c>();
            for (sked__Account_Tag__c deletedTag : accountTags) {
                for (sked_Drive_Shift_Tag__c driveShiftTag : potentialDriveShiftTagsToDelete) {
                    if (driveShiftTag.sked_Drive_Shift__r.sked_Drive_Account__c == deletedTag.sked__Account__c && 
                        driveShiftTag.sked_Tag__c == deletedTag.sked__Tag__c) {
                        affectedDriveShiftTags.add(driveShiftTag);
                    }
                }
            }

            if (!affectedDriveShiftTags.isEmpty()) {
                for (sked_Drive_Shift_Tag__c driveShiftTag : affectedDriveShiftTags) {
                    sked_Location_Tag__c relatedSiteTag;
                    sked__Location__c site = siteById.get(driveShiftTag.sked_Drive_Shift__r.sked_Drive_Site__c);
                    if (site != null && site.sked_Location_Tags__r != null) {
                        for (sked_Location_Tag__c siteTag : site.sked_Location_Tags__r) {
                            if (siteTag.sked_Tag__c == driveShiftTag.sked_Tag__c) {
                                relatedSiteTag = siteTag;
                                break;
                            }
                        }
                    }

                    if (relatedSiteTag == null) {
                        recordsToDelete.add(driveShiftTag);
                    } else {
                        driveShiftTag.sked_Minimum_Quantity__c = relatedSiteTag.sked_Minimum_Quantity__c;
                        recordsToUpdate.add(driveShiftTag);
                    }

                    this.driveShiftIds.add(driveShiftTag.sked_Drive_Shift__c);

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

            System.debug('RECORDS TO DELETE :: ' + recordsToDelete);
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }

            System.debug('RECORDS TO UPDATE :: ' + recordsToUpdate);
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            skedTriggerUtils.updateJobAllocations(this.jobIds, this.driveShiftIds);
        }
    }
}