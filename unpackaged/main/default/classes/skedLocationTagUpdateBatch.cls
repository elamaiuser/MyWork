global class skedLocationTagUpdateBatch implements Database.Batchable<sked_Location_Tag__c>, Database.Stateful {
    Set<Id> jobIds;
    Set<Id> driveShiftIds;

    List<sked_Location_Tag__c> siteTags;
    Map<Id, sked_Location_Tag__c> oldSiteTags;
    global skedLocationTagUpdateBatch(List<sked_Location_Tag__c> siteTags, Map<Id, sked_Location_Tag__c> oldSiteTags) {
        this.siteTags = siteTags;
        this.oldSiteTags = oldSiteTags;
    }

    global List<sked_Location_Tag__c> start(Database.BatchableContext BC) {
        this.jobIds = new Set<Id>();
        this.driveShiftIds = new Set<Id>();

        return siteTags;
    }

    global void execute(Database.BatchableContext BC, List<sked_Location_Tag__c> siteTags) {
        List<sked_Location_Tag__c> minimumQuantityChangedLocationTags = new List<sked_Location_Tag__c>();
        Map<Id, Set<Id>> minimumQuantityChangedTagsByLocationId = new Map<Id, Set<Id>>();
        Set<Id> minimumQuantityChangedTagIds = new Set<Id>();

        List<sked_Location_Tag__c> noLongerRequiredLocationTags = new List<sked_Location_Tag__c>();
        Map<Id, Set<Id>> noLongerRequiredTagsByLocationId = new Map<Id, Set<Id>>();
        Set<Id> noLongerRequiredTagIds = new Set<Id>();

        List<sked_Location_Tag__c> nowRequiredLocationTags = new List<sked_Location_Tag__c>();
        Map<Id, Set<Id>> nowRequiredTagsByLocationId = new Map<Id, Set<Id>>();
        Set<Id> nowRequiredTagIds = new Set<Id>();

        for (sked_Location_Tag__c newRecord : siteTags) {
            sked_Location_Tag__c oldRecord = this.oldSiteTags.get(newRecord.Id);
            Boolean minimumQuantityChanged = oldRecord.sked_Minimum_Quantity__c != newRecord.sked_Minimum_Quantity__c;
            Boolean noLongerRequired = oldRecord.sked_Required__c && !newRecord.sked_Required__c;
            Boolean nowRequired = !oldRecord.sked_Required__c && newRecord.sked_Required__c;


            if (noLongerRequired) {
                Set<Id> noLongerRequiredTagsForLocation = noLongerRequiredTagsByLocationId.get(newRecord.sked_Location__c);
                if (noLongerRequiredTagsForLocation == null) {
                    noLongerRequiredTagsForLocation = new Set<Id>();
                }
                noLongerRequiredTagsForLocation.add(newRecord.sked_Tag__c);
                noLongerRequiredTagsByLocationId.put(newRecord.sked_Location__c, noLongerRequiredTagsForLocation);
                noLongerRequiredTagIds.add(newRecord.sked_Tag__c);
                noLongerRequiredLocationTags.add(newRecord);
            } else if (nowRequired) {
                Set<Id> nowRequiredTagsForLocation = nowRequiredTagsByLocationId.get(newRecord.sked_Location__c);
                if (nowRequiredTagsForLocation == null) {
                    nowRequiredTagsForLocation = new Set<Id>();
                }
                nowRequiredTagsForLocation.add(newRecord.sked_Tag__c);
                nowRequiredTagsByLocationId.put(newRecord.sked_Location__c, nowRequiredTagsForLocation);
                nowRequiredTagIds.add(newRecord.sked_Tag__c);
                nowRequiredLocationTags.add(newRecord);
            } else if (minimumQuantityChanged) {
                Set<Id> minQuantityChangedTagsForLocation = minimumQuantityChangedTagsByLocationId.get(newRecord.sked_Location__c);
                if (minQuantityChangedTagsForLocation == null) {
                    minQuantityChangedTagsForLocation = new Set<Id>();
                }
                minQuantityChangedTagsForLocation.add(newRecord.sked_Tag__c);
                minimumQuantityChangedTagsByLocationId.put(newRecord.sked_Location__c, minQuantityChangedTagsForLocation);
                minimumQuantityChangedTagIds.add(newRecord.sked_Tag__c);
                minimumQuantityChangedLocationTags.add(newRecord);
            }
        }

        if (!minimumQuantityChangedLocationTags.isEmpty()) {
            updateMinimumQuantityOnDriveShiftTags(minimumQuantityChangedLocationTags, minimumQuantityChangedTagsByLocationId, minimumQuantityChangedTagIds);
        }

        if (!noLongerRequiredLocationTags.isEmpty()) {
            convertJobTagsToDriveShiftTags(noLongerRequiredLocationTags, noLongerRequiredTagsByLocationId, noLongerRequiredTagIds);
        }

        if (!nowRequiredLocationTags.isEmpty()) {
            convertDriveShiftTagsToJobTags(nowRequiredLocationTags, nowRequiredTagsByLocationId, nowRequiredTagIds);
        }

    }

    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            skedTriggerUtils.updateJobAllocations(this.jobIds, this.driveShiftIds);
        }
    }

    /* Private Methods */
    private void updateMinimumQuantityOnDriveShiftTags(List<sked_Location_Tag__c> LocationTags, Map<Id, Set<Id>> changedTagsByLocationId, Set<Id> tagIds) {
        List<sked_Drive_Shift_Tag__c> driveShiftTags = [
            SELECT Id, Name, sked_Minimum_Quantity__c, sked_Tag__c, sked_Drive_Shift__c,
                sked_Drive_Shift__r.sked_Drive_Site__c
            FROM sked_Drive_Shift_Tag__c
            WHERE sked_Tag__c IN :tagIds
            AND sked_Drive_Shift__r.sked_Drive_Site__c IN :changedTagsByLocationId.keyset()
            AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked_Drive_Shift__r.sked_Drive__r.sked_Status__c != :skedConstants.JOB_STATUS_COMPLETE
        ];

        List<sked_Drive_Shift_Tag__c> driveShiftTagsToUpdate = new List<sked_Drive_Shift_Tag__c>();
        for (sked_Location_Tag__c LocationTag : LocationTags) {
            sked_Drive_Shift_Tag__c relatedDriveShiftTag; 
            for (sked_Drive_shift_Tag__c driveShiftTag : driveShiftTags) {
                if (driveShiftTag.sked_Drive_Shift__r.sked_Drive_Site__c == LocationTag.sked_Location__c &&
                        driveShiftTag.sked_Tag__c == LocationTag.sked_Tag__c) {
                    relatedDriveShiftTag = driveShiftTag;
                }

                if (relatedDriveShiftTag != null) {
                    relatedDriveShiftTag.sked_Minimum_Quantity__c = LocationTag.sked_Minimum_Quantity__c;
                    driveShiftTagsToUpdate.add(driveShiftTag);    
                }

                this.driveShiftIds.add(driveShiftTag.sked_Drive_Shift__c);
            }
        }

        if (!driveShiftTagsToUpdate.isEmpty()) {
            update driveShiftTagsToUpdate;
        }
    }

    private void convertJobTagsToDriveShiftTags(List<sked_Location_Tag__c> LocationTags, Map<Id, Set<Id>> changedTagsByLocationId, Set<Id> tagIds) {
        List<sked_Drive_Shift__c> driveShifts = [
            SELECT Id, Name, sked_Drive_Site__c,
            (SELECT Id, Name, sked_Tag__c FROM sked_Drive_Shift_Tags__r)
            FROM sked_Drive_Shift__c
            WHERE sked_Drive_Site__c IN :changedTagsByLocationId.keySet()
        ];

        Set<Id> driveShiftIds = new Set<Id>();
        for (sked_Drive_Shift__c driveShift : driveShifts) { 
            driveShiftIds.add(driveShift.Id);
        }
        this.driveShiftIds.addAll(driveShiftIds);

        List<sked__Job_Tag__c> jobTags = [
            SELECT Id, Name, sked__Tag__c, sked__Job__c, sked__Job__r.sked__Location__c, sked__Job__r.sked_Drive_Shift__c
            FROM sked__Job_Tag__c
            WHERE sked__Job__r.sked_Drive_Shift__c IN :driveShiftIds
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_COMPLETE
        ];

        List<sked__Job_Tag__c> jobTagsToDelete = new List<sked__Job_Tag__c>();
        List<sked_Drive_Shift_Tag__c> driveShiftTagsToCreate = new List<sked_Drive_Shift_Tag__c>();
        
        Set<Id> processedDriveShiftIds = new Set<Id>();
        for (sked__Job_Tag__c jobTag : jobTags) {
            Set<Id> tagIdsToDelete = changedTagsByLocationId.get(jobTag.sked__Job__r.sked__Location__c);
            sked_Location_Tag__c relatedLocationTag;
            for (sked_Location_Tag__c LocationTag : LocationTags) {
                if (jobTag.sked__Tag__c == LocationTag.sked_Tag__c 
                        && jobTag.sked__Job__r.sked__Location__c == LocationTag.sked_Location__c) {
                    relatedLocationTag = LocationTag;
                }
            }
            

            if (relatedLocationTag != null) {
                if (!tagIdsToDelete.isEmpty() && tagIdsToDelete.contains(jobTag.sked__Tag__c)) {
                    jobTagsToDelete.add(jobTag);

                    if (!processedDriveShiftIds.contains(jobTag.sked__Job__r.sked_Drive_Shift__c)) {
                        driveShiftTagsToCreate.add(new sked_Drive_Shift_Tag__c(
                            sked_Tag__c = jobTag.sked__Tag__c,
                            sked_Drive_Shift__c = jobTag.sked__Job__r.sked_Drive_Shift__c,
                            sked_Minimum_Quantity__c = relatedLocationTag.sked_Minimum_Quantity__c
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

    private void convertDriveShiftTagsToJobTags(List<sked_Location_Tag__c> LocationTags, Map<Id, Set<Id>> changedTagsByLocationId, Set<Id> tagIds) {
        List<sked_Drive_Shift_Tag__c> affectedDriveShiftTags = [
            SELECT Id, Name, sked_Minimum_Quantity__c, sked_Tag__c, sked_Drive_Shift__c,
                sked_Drive_Shift__r.sked_Drive_Site__c
            FROM sked_Drive_Shift_Tag__c
            WHERE sked_Tag__c IN :tagIds
            AND sked_Drive_Shift__r.sked_Drive_Site__c IN :changedTagsByLocationId.keyset()
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
            Set<Id> changedTagsForLocation = changedTagsByLocationId.get(driveShiftTag.sked_Drive_Shift__r.sked_Drive_Site__c);
            
            if (changedTagsForLocation != null) {
                if (changedTagsForLocation.contains(driveShiftTag.sked_Tag__c)) {
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
            for (sked_Location_Tag__c LocationTag : LocationTags) {
                sked__Tag__c tag = tagById.get(LocationTag.sked_Tag__c);

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
                    jobTag.sked__Tag__c = LocationTag.sked_Tag__c;
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