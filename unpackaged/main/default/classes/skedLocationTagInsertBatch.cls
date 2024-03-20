global class skedLocationTagInsertBatch implements Database.Batchable<sked_Location_Tag__c>, Database.Stateful {
    
    Set<Id> jobIds;
    Set<Id> driveShiftIds;

    Boolean autoProcessDeleteTrigger;

    List<sked_Location_Tag__c> siteTags;
    List<sked_Location_Tag__c> deletedSiteTags;

    global skedLocationTagInsertBatch(List<sked_Location_Tag__c> insertedSiteTags, List<sked_Location_Tag__c> deletedSiteTags) {
        this.siteTags = insertedSiteTags;
        this.deletedSiteTags = deletedSiteTags;
        this.autoProcessDeleteTrigger = true;
        this.jobIds = new Set<Id>();
        this.driveShiftIds = new Set<Id>();
    }

    global skedLocationTagInsertBatch(List<sked_Location_Tag__c> siteTags) {
        this.autoProcessDeleteTrigger = false;
        this.siteTags = siteTags;
        this.jobIds = new Set<Id>();
        this.driveShiftIds = new Set<Id>();
    }

    global List<sked_Location_Tag__c> start(Database.BatchableContext BC) {
        return siteTags;
    }

    global void execute(Database.BatchableContext BC, List<sked_Location_Tag__c> siteTags) {
        List<sked_Location_Tag__c> requiredTags = new List<sked_Location_Tag__c>();
        List<sked_Location_Tag__c> nonRequiredTags = new List<sked_Location_Tag__c>();
        Set<Id> locationIds = new Set<Id>();
        Set<Id> tagIds = new Set<Id>();
        Set<Id> driveShiftIds = new Set<Id>();
        Set<Id> driveIds = new Set<Id>();
        Date currentDate = System.today();
        
        Map<Id, Set<Id>> map_locationId_exceptionDriveIds = new Map<Id, Set<Id>>();

        for (sked_Location_Tag__c siteTag : siteTags) {
            locationIds.add(siteTag.sked_Location__c);
            tagIds.add(siteTag.sked_Tag__c);

            if (siteTag.sked_Required__c) {
                requiredTags.add(siteTag);
            } 
            else {
                nonRequiredTags.add(siteTag);
            }
        }

        Map<Id, sked__Tag__c> tagById = new Map<Id, sked__Tag__c>([
            SELECT Id, Name, sked_Resource_Type__c, sked__Type__c
            FROM sked__Tag__c
            WHERE Id IN :tagIds
        ]);

        List<sked_Drive_Shift__c> driveShifts = [
            SELECT Id, Name, sked_Drive_Site__c, sked_Drive__c, sked_Drive__r.sked_Drive_Date__c,
            (SELECT Id, Name, sked_Tag__c 
             FROM sked_Drive_Shift_Tags__r)
            FROM sked_Drive_Shift__c
            WHERE sked_Drive_Site__c IN :locationIds
            AND sked_Drive__r.sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
            AND sked_Drive__r.sked_Drive_Date__c >= TODAY
        ];
        
        for (sked_Drive_Shift__c driveShift : driveShifts) {
            driveShiftIds.add(driveShift.Id);
            driveIds.add(driveShift.sked_Drive__c);
            
            integer daysBetween = currentDate.daysBetween(driveShift.sked_Drive__r.sked_Drive_Date__c);
            if (daysBetween <= 42) {
                Set<Id> exceptionDriveIds = map_locationId_exceptionDriveIds.get(driveShift.sked_Drive_Site__c);
                if (exceptionDriveIds == NULL) {
                    exceptionDriveIds = new Set<Id>();
                }
                exceptionDriveIds.add(driveShift.sked_Drive__c);
                map_locationId_exceptionDriveIds.put(driveShift.sked_Drive_Site__c, exceptionDriveIds);
            }
        }

        if (!nonRequiredTags.isEmpty()) {
            List<sked_Drive_Shift_Tag__c> driveShiftTagsToInsert = new List<sked_Drive_Shift_Tag__c>();
            
            for (sked_Location_Tag__c locationTag : nonRequiredTags) {
                sked__Tag__c tag = tagById.get(locationTag.sked_Tag__c);

                for (sked_Drive_Shift__c driveShift : driveShifts) {
                    if (driveShift.sked_Drive_Site__c == locationTag.sked_Location__c) {
                        driveShiftTagsToInsert.add(new sked_Drive_Shift_Tag__c(
                            sked_Tag__c = locationTag.sked_Tag__c,
                            sked_Drive_Shift__c = driveShift.Id,
                            sked_Minimum_Quantity__c = locationTag.sked_Minimum_Quantity__c
                        ));
                    }
                }
            }

            if (!driveShiftTagsToInsert.isEmpty()) {
                insert driveShiftTagsToInsert;
            }
        }

        Set<Id> jobIds = new Set<Id>();
        if (!requiredTags.isEmpty()) {
            List<sked__Job__c> jobs = [
                SELECT Id, Name, sked_Resource_Role__c, sked_Asset_Type__c, sked__Job_Status__c, sked_Volunteer_Role__c,
                (SELECT Id, Name, sked__Tag__c FROM sked__jobTags__r)
                FROM sked__Job__c
                WHERE sked_Drive_Shift__c IN :driveShiftIds
                AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                AND sked__Job_Status__c != :skedConstants.JOB_STATUS_COMPLETE
            ];

            if (!jobs.isEmpty()) {
                List<sked__Job_Tag__c> jobTagsToInsert = new List<sked__Job_Tag__c>();
                for (sked_Location_Tag__c locationTag : requiredTags) {
                    sked__Tag__c tag = tagById.get(locationTag.sked_Tag__c);

                    for (sked__Job__c job : jobs) {
                        jobIds.add(job.Id);
                        Boolean matchingJobTag = false;
                        for (sked__Job_Tag__c jobTag : job.sked__jobTags__r) {
                            // If the job already has this job tag associated with it, we don't need to do anything
                            if (jobTag.sked__Tag__c == tag.Id) {
                                matchingJobTag = true;
                            }
                        }

                        if (matchingJobTag) continue;

                        sked__Job_Tag__c jobTag = new sked__Job_Tag__c();
                        jobTag.sked__Tag__c = locationTag.sked_Tag__c;
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
                    }
                }

                if (!jobTagsToInsert.isEmpty()) {
                    insert jobTagsToInsert;
                }
            }
        }
        
        this.processCertAddedException(siteTags, tagById, map_locationId_exceptionDriveIds);
        
        this.jobIds.addAll(jobIds);
        this.driveShiftIds.addAll(driveShiftIds);
    }
    
    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            if (!this.autoProcessDeleteTrigger) {
                skedTriggerUtils.updateJobAllocations(this.jobIds, this.driveShiftIds);
            } else {
                Database.executeBatch(new skedLocationTagDeleteBatch(deletedSiteTags), 1);
            }
        }
    }
    
    private void processCertAddedException(List<sked_Location_Tag__c> locationTags, Map<Id, sked__Tag__c> tagById, Map<Id, Set<Id>> map_locationId_exceptionDriveIds) {
        string template = '{{tagName}} Certification added - 42 days';
        List<sked_Exception_Setting__c> exceptionSettings = [
            SELECT Id, sked_Exception_Code__c, sked_Exception__c, sked_Priority__c
            FROM sked_Exception_Setting__c
            WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_CERT_ADDED_42DAYS
        ];
        if (!exceptionSettings.isEmpty()) {
            template = exceptionSettings.get(0).sked_Exception__c;
        }
        
        List<skedHC__Exception__c> certAddedExceptions = new List<skedHC__Exception__c>();
        for (sked_Location_Tag__c locationTag : locationTags) {
            if (locationTag.sked_Required__c == TRUE) {
                sked__Tag__c tag = tagById.get(locationTag.sked_Tag__c);
                if (tag.sked__Type__c == skedConstants.TAG_TYPE_CERTIFICATION) {
                    if (map_locationId_exceptionDriveIds.containsKey(locationTag.sked_Location__c)) {
                        Set<Id> exceptionDriveIds = map_locationId_exceptionDriveIds.get(locationTag.sked_Location__c);
                        
                        string exceptionText = template.replace('{{tagName}}', tag.Name);
                        for (Id driveId : exceptionDriveIds) {
                            skedHC__Exception__c newException = new skedHC__Exception__c(
                                sked_Drive__c = driveId,
                                skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN,
                                sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_CERT_ADDED_42DAYS,
                                skedHC__Exception__c = exceptionText
                            );
                            certAddedExceptions.add(newException);
                        }
                    }
                }
            }
        }
        if (!certAddedExceptions.isEmpty()) {
            insert certAddedExceptions;
        }
    }
    
}