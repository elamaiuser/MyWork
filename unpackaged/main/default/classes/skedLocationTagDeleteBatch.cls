global class skedLocationTagDeleteBatch implements Database.Batchable<sked_Location_Tag__c>, Database.Stateful {
    Set<Id> jobIds;
    Set<Id> driveShiftIds;

    List<sked_Location_Tag__c> siteTags;
    global skedLocationTagDeleteBatch(List<sked_Location_Tag__c> siteTags) {
        this.siteTags = siteTags;
    }

    global List<sked_Location_Tag__c> start(Database.BatchableContext BC) {
        this.jobIds = new Set<Id>();
        this.driveShiftIds = new Set<Id>();

        return siteTags;
    }

    global void execute(Database.BatchableContext BC, List<sked_Location_Tag__c> siteTags) {
        Map<Id, Set<Id>> deletedTagsByLocation = new Map<Id, Set<Id>>();
        Set<Id> allDeletedTagIds = new Set<Id>();
        for (sked_Location_Tag__c siteTag : siteTags) {
            Set<Id> deletedTags = deletedTagsByLocation.get(siteTag.sked_Location__c);

            if (deletedTags == null) {
                deletedTags = new Set<Id>();
            }
            
            deletedTags.add(siteTag.sked_Tag__c);
            deletedTagsByLocation.put(siteTag.sked_Location__c, deletedTags);
            allDeletedTagIds.add(siteTag.sked_Tag__c);
        }

        if (!deletedTagsByLocation.keySet().isEmpty()) {
            Set<Id> affectedJobIds = new Set<Id>();
            Set<Id> affectedDriveShiftIds = new Set<Id>();
            List<SObject> recordsToDelete = new List<SObject>();

            List<sked_Drive_Shift_Tag__c> potentialDriveShiftTagsToDelete = [
                SELECT Id, sked_Drive_Shift__c, sked_Drive_Shift__r.sked_Drive_Site__c, sked_Tag__c
                FROM sked_Drive_Shift_Tag__c
                WHERE sked_Tag__c IN :allDeletedTagIds
                AND sked_Drive_Shift__r.sked_Drive_Site__c IN :deletedTagsByLocation.keySet()
                AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_COMPLETE
            ];

            for (sked_Drive_Shift_Tag__c driveShiftTag : potentialDriveShiftTagsToDelete) {
                Set<Id> deletableTagIdsForLocation = deletedTagsByLocation.get(driveShiftTag.sked_Drive_Shift__r.sked_Drive_Site__c);
                
                if (deletableTagIdsForLocation != null) {
                    if (deletableTagIdsForLocation.contains(driveShiftTag.sked_Tag__c)) {
                        affectedDriveShiftIds.add(driveShiftTag.sked_Drive_Shift__c);
                        recordsToDelete.add(driveShiftTag);
                    }
                }

                this.driveShiftIds.add(driveShiftTag.sked_Drive_Shift__c);
            }

            List<sked__Job_Tag__c> potentialJobTagsToDelete = [
                SELECT Id, sked__Job__c, sked__Job__r.sked_Drive__r.sked_Drive_Site__c, sked__Tag__c
                FROM sked__Job_Tag__c
                WHERE sked__Tag__c IN :allDeletedTagIds
                AND sked__Job__r.sked_Drive__r.sked_Drive_Site__c IN :deletedTagsByLocation.keySet()
                AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_COMPLETE
            ];

            for (sked__Job_Tag__c jobTag : potentialJobTagsToDelete) {
                Set<Id> deletableTagIdsForLocation = deletedTagsByLocation.get(jobTag.sked__Job__r.sked_Drive__r.sked_Drive_Site__c);
                
                if (deletableTagIdsForLocation != null) {
                    if (deletableTagIdsForLocation.contains(jobTag.sked__Tag__c)) {
                        affectedJobIds.add(jobTag.sked__Job__c);
                        recordsToDelete.add(jobTag);
                    }
                }

                this.jobIds.add(jobTag.sked__Job__c);
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