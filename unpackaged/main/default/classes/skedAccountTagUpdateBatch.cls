global class skedAccountTagUpdateBatch implements Database.Batchable<sked__Account_Tag__c>, Database.Stateful {
    private Set<Id> jobIds;
    private Set<Id> driveShiftIds;
    
    List<sked__Account_Tag__c> accountTags;
    Map<Id, sked__Account_Tag__c> oldAccountTags;
    global skedAccountTagUpdateBatch(List<sked__Account_Tag__c> accountTags, Map<Id, sked__Account_Tag__c> oldAccountTags) {
        this.accountTags = accountTags;
        this.oldAccountTags = oldAccountTags;
    }

    global List<sked__Account_Tag__c> start(Database.BatchableContext BC) {
        this.jobIds = new Set<Id>();
        this.driveShiftIds = new Set<Id>();
        return this.accountTags;
    }

    global void execute(Database.BatchableContext BC, List<sked__Account_Tag__c> accountTags) {
        List<sked__Account_Tag__c> minimumQuantityChangedAccountTags = new List<sked__Account_Tag__c>();
        Map<Id, Set<Id>> minimumQuantityChangedTagsByAccountId = new Map<Id, Set<Id>>();
        Set<Id> minimumQuantityChangedTagIds = new Set<Id>();

        List<sked__Account_Tag__c> noLongerRequiredAccountTags = new List<sked__Account_Tag__c>();
        Map<Id, Set<Id>> noLongerRequiredTagsByAccountId = new Map<Id, Set<Id>>();
        Set<Id> noLongerRequiredTagIds = new Set<Id>();

        List<sked__Account_Tag__c> nowRequiredAccountTags = new List<sked__Account_Tag__c>();
        Map<Id, Set<Id>> nowRequiredTagsByAccountId = new Map<Id, Set<Id>>();
        Set<Id> nowRequiredTagIds = new Set<Id>();

        for (sked__Account_Tag__c newRecord : accountTags) {
            sked__Account_Tag__c oldRecord = this.oldAccountTags.get(newRecord.Id);
            Boolean minimumQuantityChanged = oldRecord.sked_Minimum_Quantity__c != newRecord.sked_Minimum_Quantity__c;
            Boolean noLongerRequired = oldRecord.sked__Required__c && !newRecord.sked__Required__c;
            Boolean nowRequired = !oldRecord.sked__Required__c && newRecord.sked__Required__c;

            if (noLongerRequired) {
                Set<Id> noLongerRequiredTagsForAccount = noLongerRequiredTagsByAccountId.get(newRecord.sked__Account__c);
                if (noLongerRequiredTagsForAccount == null) {
                    noLongerRequiredTagsForAccount = new Set<Id>();
                }
                noLongerRequiredTagsForAccount.add(newRecord.sked__Tag__c);
                noLongerRequiredTagsByAccountId.put(newRecord.sked__Account__c, noLongerRequiredTagsForAccount);
                noLongerRequiredTagIds.add(newRecord.sked__Tag__c);
                noLongerRequiredAccountTags.add(newRecord);
            } else if (nowRequired) {
                Set<Id> nowRequiredTagsForAccount = nowRequiredTagsByAccountId.get(newRecord.sked__Account__c);
                if (nowRequiredTagsForAccount == null) {
                    nowRequiredTagsForAccount = new Set<Id>();
                }
                nowRequiredTagsForAccount.add(newRecord.sked__Tag__c);
                nowRequiredTagsByAccountId.put(newRecord.sked__Account__c, nowRequiredTagsForAccount);
                nowRequiredTagIds.add(newRecord.sked__Tag__c);
                nowRequiredAccountTags.add(newRecord);
            } else if (minimumQuantityChanged) {
                Set<Id> minQuantityChangedTagsForAccount = minimumQuantityChangedTagsByAccountId.get(newRecord.sked__Account__c);
                if (minQuantityChangedTagsForAccount == null) {
                    minQuantityChangedTagsForAccount = new Set<Id>();
                }
                minQuantityChangedTagsForAccount.add(newRecord.sked__Tag__c);
                minimumQuantityChangedTagsByAccountId.put(newRecord.sked__Account__c, minQuantityChangedTagsForAccount);
                minimumQuantityChangedTagIds.add(newRecord.sked__Tag__c);
                minimumQuantityChangedAccountTags.add(newRecord);
            }
        }

        if (!minimumQuantityChangedAccountTags.isEmpty()) {
            updateMinimumQuantityOnDriveShiftTags(minimumQuantityChangedAccountTags, minimumQuantityChangedTagsByAccountId, minimumQuantityChangedTagIds);
        }

        if (!noLongerRequiredAccountTags.isEmpty()) {
            convertJobTagsToDriveShiftTags(noLongerRequiredAccountTags, noLongerRequiredTagsByAccountId, noLongerRequiredTagIds);
        }

        if (!nowRequiredAccountTags.isEmpty()) {
            convertDriveShiftTagsToJobTags(nowRequiredAccountTags, nowRequiredTagsByAccountId, nowRequiredTagIds);
        }
    }

    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            skedTriggerUtils.updateJobAllocations(this.jobIds, this.driveShiftIds);
        }
    }

    /* Private Methods */
    private void updateMinimumQuantityOnDriveShiftTags(List<sked__Account_Tag__c> accountTags, Map<Id, Set<Id>> changedTagsByAccountId, Set<Id> tagIds) {
        List<sked_Drive_Shift_Tag__c> driveShiftTags = [
            SELECT Id, Name, sked_Minimum_Quantity__c, sked_Tag__c, sked_Drive_Shift__c,
                sked_Drive_Shift__r.sked_Drive_Account__c
            FROM sked_Drive_Shift_Tag__c
            WHERE sked_Tag__c IN :tagIds
            AND sked_Drive_Shift__r.sked_Drive_Account__c IN :changedTagsByAccountId.keyset()
            AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_COMPLETE
        ];

        List<sked_Drive_Shift_Tag__c> driveShiftTagsToUpdate = new List<sked_Drive_Shift_Tag__c>();
        for (sked__Account_Tag__c accountTag : accountTags) {
            sked_Drive_Shift_Tag__c relatedDriveShiftTag; 
            for (sked_Drive_shift_Tag__c driveShiftTag : driveShiftTags) {
                if (driveShiftTag.sked_Drive_Shift__r.sked_Drive_Account__c == accountTag.sked__Account__c &&
                        driveShiftTag.sked_Tag__c == accountTag.sked__Tag__c) {
                    relatedDriveShiftTag = driveShiftTag;
                }

                if (relatedDriveShiftTag != null) {
                    relatedDriveShiftTag.sked_Minimum_Quantity__c = accountTag.sked_Minimum_Quantity__c;
                    driveShiftTagsToUpdate.add(driveShiftTag);    
                }

                this.driveShiftIds.add(driveShiftTag.sked_Drive_Shift__c);
            }
        }

        if (!driveShiftTagsToUpdate.isEmpty()) {
            update driveShiftTagsToUpdate;
        }
    }

    private void convertJobTagsToDriveShiftTags(List<sked__Account_Tag__c> accountTags, Map<Id, Set<Id>> changedTagsByAccountId, Set<Id> tagIds) {
        List<sked_Drive_Shift__c> driveShifts = [
            SELECT Id, Name, sked_Drive_Account__c,
            (SELECT Id, Name, sked_Tag__c FROM sked_Drive_Shift_Tags__r)
            FROM sked_Drive_Shift__c
            WHERE sked_Drive_Account__c IN :changedTagsByAccountId.keySet()
        ];

        Set<Id> driveShiftIds = new Set<Id>();
        for (sked_Drive_Shift__c driveShift : driveShifts) { 
            driveShiftIds.add(driveShift.Id);
        }
        this.driveShiftIds.addAll(driveShiftIds);

        List<sked__Job_Tag__c> jobTags = [
            SELECT Id, Name, sked__Tag__c, sked__Job__c, sked__Job__r.sked__Account__c, sked__Job__r.sked_Drive_Shift__c
            FROM sked__Job_Tag__c
            WHERE sked__Job__r.sked_Drive_Shift__c IN :driveShiftIds
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_COMPLETE
        ];

        List<sked__Job_Tag__c> jobTagsToDelete = new List<sked__Job_Tag__c>();
        List<sked_Drive_Shift_Tag__c> driveShiftTagsToCreate = new List<sked_Drive_Shift_Tag__c>();

        Set<Id> processedDriveShiftIds = new Set<Id>();
        for (sked__Job_Tag__c jobTag : jobTags) {
            Set<Id> tagIdsToDelete = changedTagsByAccountId.get(jobTag.sked__Job__r.sked__Account__c);
            sked__Account_Tag__c relatedAccountTag;
            for (sked__Account_Tag__c accountTag : accountTags) {
                if (jobTag.sked__Tag__c == accountTag.sked__Tag__c 
                        && jobTag.sked__Job__r.sked__Account__c == accountTag.sked__Account__c) {
                    relatedAccountTag = accountTag;
                }
            }

            if (relatedAccountTag != null) {
                if (!tagIdsToDelete.isEmpty() && tagIdsToDelete.contains(jobTag.sked__Tag__c)) {
                    jobTagsToDelete.add(jobTag);

                    if (!processedDriveShiftIds.contains(jobTag.sked__Job__r.sked_Drive_Shift__c)) {
                        driveShiftTagsToCreate.add(new sked_Drive_Shift_Tag__c(
                            sked_Tag__c = jobTag.sked__Tag__c,
                            sked_Drive_Shift__c = jobTag.sked__Job__r.sked_Drive_Shift__c,
                            sked_Minimum_Quantity__c = relatedAccountTag.sked_Minimum_Quantity__c
                        ));
                        processedDriveShiftIds.add(jobTag.sked__Job__r.sked_Drive_Shift__c);
                    }
                }
            }

            this.jobIds.add(jobTag.sked__Job__c);
        }

        if (!jobTagsToDelete.isEmpty()) {
            delete jobTagsToDelete;
        }

        if (!driveShiftTagsToCreate.isEmpty()) {
            insert driveShiftTagsToCreate;
        }
    }

    private void convertDriveShiftTagsToJobTags(List<sked__Account_Tag__c> accountTags, Map<Id, Set<Id>> changedTagsByAccountId, Set<Id> tagIds) {
        List<sked_Drive_Shift_Tag__c> affectedDriveShiftTags = [
            SELECT Id, Name, sked_Minimum_Quantity__c, sked_Tag__c, sked_Drive_Shift__c,
                sked_Drive_Shift__r.sked_Drive_Account__c
            FROM sked_Drive_Shift_Tag__c
            WHERE sked_Tag__c IN :tagIds
            AND sked_Drive_Shift__r.sked_Drive_Account__c IN :changedTagsByAccountId.keyset()
            AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_COMPLETE
        ];

        Map<Id, sked__Tag__c> tagById = new Map<Id, sked__Tag__c>([
            SELECT Id, Name, sked_Resource_Type__c
            FROM sked__Tag__c
            WHERE Id IN :tagIds
        ]);

        Set<Id> driveShiftIds = new Set<Id>();
        List<sked_Drive_Shift_Tag__c> driveShiftTagsToDelete = new List<sked_Drive_Shift_Tag__c>();
        for (sked_Drive_Shift_Tag__c driveShiftTag : affectedDriveShiftTags) {
            Set<Id> changedTagsForAccount = changedTagsByAccountId.get(driveShiftTag.sked_Drive_Shift__r.sked_Drive_Account__c);
            
            if (changedTagsForAccount != null) {
                if (changedTagsForAccount.contains(driveShiftTag.sked_Tag__c)) {
                    driveShiftTagsToDelete.add(driveShiftTag);
                }
            }
            driveShiftIds.add(driveShiftTag.sked_Drive_Shift__c);
        }
        this.driveShiftIds.addAll(driveShiftIds);

        List<sked__Job_Tag__c> jobTagsToCreate = new List<sked__Job_Tag__c>();
        List<sked__Job__c> jobs = [
            SELECT Id, Name, sked_Resource_Role__c, sked_Asset_Type__c, sked__Job_Status__c, sked_Volunteer_Role__c,
            (SELECT Id, Name, sked__Tag__c FROM sked__jobTags__r)
            FROM sked__Job__c
            WHERE sked_Drive_Shift__c IN :driveShiftIds
            AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked__Job_Status__c != :skedConstants.JOB_STATUS_COMPLETE
        ];

        List<sked__Job_Tag__c> jobTagsToInsert = new List<sked__Job_Tag__c>();
        if (!jobs.isEmpty()) {
            for (sked__Account_Tag__c accountTag : accountTags) {
                sked__Tag__c tag = tagById.get(accountTag.sked__Tag__c);

                for (sked__Job__c job : jobs) {
                    Boolean matchingJobTag = false;
                    for (sked__Job_Tag__c jobTag : job.sked__jobTags__r) {
                        // If the job already has this job tag associated with it, we don't need to do anything
                        if (jobTag.sked__Tag__c == tag.Id) {
                            matchingJobTag = true;
                        }
                    }

                    if (matchingJobTag) continue;

                    sked__Job_Tag__c jobTag = new sked__Job_Tag__c();
                    jobTag.sked__Tag__c = accountTag.sked__Tag__c;
                    jobTag.sked__Job__c = job.Id;
                    jobTag.sked__Required__c = true;

                    if (tag.sked_Resource_Type__c == null) {
                        jobTagsToInsert.add(jobTag);
                    } else if (tag.sked_Resource_Type__c.contains(skedConstants.TAG_RESOURCE_TYPE_PERSON)
                    && (job.sked_Resource_Role__c != null || job.sked_Volunteer_Role__c != null)) {
                        jobTagsToInsert.add(jobTag);
                    } else if (tag.sked_Resource_Type__c.contains(skedConstants.TAG_RESOURCE_TYPE_VEHICLE)
                    && job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                        jobTagsToInsert.add(jobTag);
                    } else if (tag.sked_Resource_Type__c.contains(skedConstants.TAG_RESOURCE_TYPE_EQUIPMENT)
                    && job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                        jobTagsToInsert.add(jobTag);
                    }

                    this.jobIds.add(job.Id);
                }
            }

        }
        if (!driveShiftTagsToDelete.isEmpty()) {
            delete driveShiftTagsToDelete;
        }

        if (!jobTagsToInsert.isEmpty()) {
            insert jobTagsToInsert;
        }
    }
}