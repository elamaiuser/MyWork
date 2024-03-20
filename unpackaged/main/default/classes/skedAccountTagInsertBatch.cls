global class skedAccountTagInsertBatch implements Database.Batchable<sked__Account_Tag__c>, Database.Stateful {
    
    private Set<Id> jobIds;
    private Set<Id> driveShiftIds;
    
    List<sked__Account_Tag__c> records;
    global skedAccountTagInsertBatch(List<sked__Account_Tag__c> records) {
        this.records = records;
        this.jobIds = new Set<Id>();
        this.driveShiftIds = new Set<Id>();
    }

    global List<sked__Account_Tag__c> start(Database.BatchableContext BC) {
        return this.records;
    }

    global void execute(Database.BatchableContext BC, List<sked__Account_Tag__c> accountTags) {
        List<sked__Account_Tag__c> requiredTags = new List<sked__Account_Tag__c>();
        List<sked__Account_Tag__c> nonRequiredTags = new List<sked__Account_Tag__c>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> tagIds = new Set<Id>();
        Set<Id> driveShiftIds = new Set<Id>();
        Set<Id> driveIds = new Set<Id>();
        Date currentDate = System.today();
        
        Map<Id, Set<Id>> map_accountId_exceptionDriveIds = new Map<Id, Set<Id>>();

        for (sked__Account_Tag__c accountTag : accountTags) {
            accountIds.add(accountTag.sked__Account__c);
            tagIds.add(accountTag.sked__Tag__c);

            if (accountTag.sked__Required__c) {
                requiredTags.add(accountTag);
            } 
            else {
                nonRequiredTags.add(accountTag);
            }
        }

        Map<Id, sked__Tag__c> tagById = new Map<Id, sked__Tag__c>([
            SELECT Id, Name, sked_Resource_Type__c, sked__Type__c
            FROM sked__Tag__c
            WHERE Id IN :tagIds
        ]);

        List<sked_Drive_Shift__c> driveShifts = [
            SELECT Id, Name, sked_Drive_Account__c, sked_Drive__c, sked_Drive__r.sked_Drive_Date__c,
            (SELECT Id, Name, sked_Tag__c 
             FROM sked_Drive_Shift_Tags__r)
            FROM sked_Drive_Shift__c
            WHERE sked_Drive_Account__c IN :accountIds
            AND sked_Drive__r.sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
            AND sked_Drive__r.sked_Drive_Date__c >= TODAY
        ];

        for (sked_Drive_Shift__c driveShift : driveShifts) {
            driveShiftIds.add(driveShift.Id);
            driveIds.add(driveShift.sked_Drive__c);
            
            integer daysBetween = currentDate.daysBetween(driveShift.sked_Drive__r.sked_Drive_Date__c);
            if (daysBetween <= 42) {
                Set<Id> exceptionDriveIds = map_accountId_exceptionDriveIds.get(driveShift.sked_Drive_Account__c);
                if (exceptionDriveIds == NULL) {
                    exceptionDriveIds = new Set<Id>();
                }
                exceptionDriveIds.add(driveShift.sked_Drive__c);
                map_accountId_exceptionDriveIds.put(driveShift.sked_Drive_Account__c, exceptionDriveIds);
            }
        }

        if (!nonRequiredTags.isEmpty()) {
            List<sked_Drive_Shift_Tag__c> driveShiftTagsToInsert = new List<sked_Drive_Shift_Tag__c>();
            
            for (sked__Account_Tag__c accountTag : nonRequiredTags) {
                sked__Tag__c tag = tagById.get(accountTag.sked__Tag__c);

                for (sked_Drive_Shift__c driveShift : driveShifts) {
                    if (driveShift.sked_Drive_Account__c == accountTag.sked__Account__c) {
                        driveShiftTagsToInsert.add(new sked_Drive_Shift_Tag__c(
                            sked_Tag__c = accountTag.sked__Tag__c,
                            sked_Drive_Shift__c = driveShift.Id,
                            sked_Minimum_Quantity__c = accountTag.sked_Minimum_Quantity__c
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
                (SELECT Id, Name, sked__Tag__c 
                 FROM sked__JobTags__r)
                FROM sked__Job__c
                WHERE sked_Drive_Shift__c IN :driveShiftIds
                AND sked_Drive__r.sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
                AND sked_Drive__r.sked_Drive_Date__c >= TODAY
                AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                AND sked__Job_Status__c != :skedConstants.JOB_STATUS_COMPLETE
            ];

            if (!jobs.isEmpty()) {
                List<sked__Job_Tag__c> jobTagsToInsert = new List<sked__Job_Tag__c>();
                for (sked__Account_Tag__c accountTag : requiredTags) {
                    sked__Tag__c tag = tagById.get(accountTag.sked__Tag__c);

                    for (sked__Job__c job : jobs) {
                        jobIds.add(job.Id);
                        Boolean matchingJobTag = false;
                        for (sked__Job_Tag__c jobTag : job.sked__jobTags__r) {
                            // If the job already has this job tag associated with it, we don't need to do anything
                            if (jobTag.sked__Tag__c == accountTag.sked__Tag__c) {
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
                    }
                }

                if (!jobTagsToInsert.isEmpty()) {
                    insert jobTagsToInsert;
                }
            }
        }

        this.processCertAddedException(accountTags, tagById, map_accountId_exceptionDriveIds);
        
        this.jobIds.addAll(jobIds);
        this.driveShiftIds.addAll(driveShiftIds);
    }
    
    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            skedTriggerUtils.updateJobAllocations(this.jobIds, this.driveShiftIds);
        }
    }
    
    private void processCertAddedException(List<sked__Account_Tag__c> accountTags, Map<Id, sked__Tag__c> tagById, Map<Id, Set<Id>> map_accountId_exceptionDriveIds) {
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
        for (sked__Account_Tag__c accountTag : accountTags) {
            if (accountTag.sked__Required__c == TRUE) {
                sked__Tag__c tag = tagById.get(accountTag.sked__Tag__c);
                if (tag.sked__Type__c == skedConstants.TAG_TYPE_CERTIFICATION) {
                    if (map_accountId_exceptionDriveIds.containsKey(accountTag.sked__Account__c)) {
                        Set<Id> exceptionDriveIds = map_accountId_exceptionDriveIds.get(accountTag.sked__Account__c);
                        
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