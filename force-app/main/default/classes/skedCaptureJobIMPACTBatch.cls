global class skedCaptureJobIMPACTBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    List<skedCOImpactChangedModel> coImpactChanges;
    skedCOImpactChangedModel currentImpactChange;
    Set<Id> affectedJobIds;

    public skedCaptureJobIMPACTBatch(List<skedCOImpactChangedModel> coImpactChanges) {
        this.coImpactChanges = coImpactChanges;
        this.currentImpactChange = coImpactChanges[0];
        this.affectedJobIds = new Set<Id>();
    }

    global List<sked__Job__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, Name, sked_Resource_Role__c, sked__Type__c, sked_Drive__r.sked_Drive_Date__c,
                (SELECT Id, sked__Tag__r.Name, sked_SystemCreated__c, 
                    sked__Required__c, sked__Weighting__c 
                FROM sked__JobTags__r
                WHERE (sked__Tag__r.Name = :skedConstants.JOB_RESOURCE_ROLE_DRIVE_LEAD 
                OR sked__Tag__r.Name = :skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR))
            FROM sked__Job__c
            WHERE sked_Drive__r.sked_Collection_Operation__c = :this.currentImpactChange.collectionOpId
            AND (sked_Resource_Role__c = :skedConstants.JOB_RESOURCE_ROLE_DRIVE_LEAD 
                OR sked_Resource_Role__c = :skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR) 
            AND sked_Drive__r.sked_Drive_Date__c >= :this.currentImpactChange.impactStartQueryDate
            AND sked_Drive__r.sked_Drive_Date__c <= :this.currentImpactChange.impactEndQueryDate
            AND (sked_Drive__r.sked_Type_of_Drive__c = :skedConstants.DRIVE_TYPE_MOBILE
                OR sked_Drive__r.sked_Operation_Type__c = :skedConstants.OPERATION_TYPE_WB)
            AND sked_Drive__r.sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
            AND sked_Drive__r.sked_Status__c != :skedConstants.DRIVE_STATUS_COMPLETE
        ];
    }

    global void execute(Database.BatchableContext BC, List<sked__Job__c> jobs) {
        List<sked__Job__c> jobsToUpdate = new List<sked__Job__c>();
        List<sked__Job_Tag__c> jobTagsToDelete = new List<sked__Job_Tag__c>();
        List<sked__Job_Tag__c> jobTagsToCreate = new List<sked__Job_Tag__c>();

        for (sked__Job__c job : jobs) {
            Date driveDate = job.sked_Drive__r.sked_Drive_Date__c;
            Boolean shouldBeDriveLead = false;

            if (driveDate >= this.currentImpactChange.coImpactStartDate && driveDate <= this.currentImpactChange.coImpactEndDate) {
                shouldBeDriveLead = true;
            }

            if (shouldBeDriveLead && job.sked_Resource_Role__c != skedConstants.JOB_RESOURCE_ROLE_DRIVE_LEAD) {
                job.sked_Resource_Role__c = skedConstants.JOB_RESOURCE_ROLE_DRIVE_LEAD;
                job.sked__Type__c = skedConstants.JOB_RESOURCE_ROLE_DRIVE_LEAD;
                jobsToUpdate.add(job);

                for (sked__Job_Tag__c jobTag : job.sked__JobTags__r) {
                    if (jobTag.sked__Tag__r.Name == skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR) {
                        jobTagsToDelete.add(jobTag);
                    }
                }

                jobTagsToCreate.add(new sked__Job_Tag__c(
                    sked__Tag__c = skedResourceTagHandler_Cache.getDriveLeadTag().Id,
                    sked__Job__c = job.Id,
                    sked_SystemCreated__c = true
                ));
            } else if (!shouldBeDriveLead && job.sked_Resource_Role__c != skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR) {
                job.sked_Resource_Role__c = skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR;
                job.sked__Type__c = skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR;
                jobsToUpdate.add(job);

                for (sked__Job_Tag__c jobTag : job.sked__JobTags__r) {
                    if (jobTag.sked__Tag__r.Name == skedConstants.JOB_RESOURCE_ROLE_DRIVE_LEAD) {
                        jobTagsToDelete.add(jobTag);
                    }    
                }

                jobTagsToCreate.add(new sked__Job_Tag__c(
                    sked__Tag__c = skedResourceTagHandler_Cache.getTeamSupervisorTag().Id,
                    sked__Job__c = job.Id,
                    sked_SystemCreated__c = true
                ));
            }
            this.affectedJobIds.add(job.Id);
        }

        if (!jobsToUpdate.isEmpty()) {
            update jobsToUpdate;
        }

        if (!jobTagsToCreate.isEmpty()) {
            insert jobTagsToCreate;
        }

        if (!jobTagsToDelete.isEmpty()) {
            delete jobTagsToDelete;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if (!this.affectedJobIds.isEmpty()) {
            Map<Id, sked__Job_Allocation__c> jobAllocations = new Map<Id, sked__Job_Allocation__c>([
                SELECT Id, Name
                FROM sked__Job_Allocation__c
                WHERE sked__Job__c IN :this.affectedJobIds
                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            ]);

            if (jobAllocations != null && !jobAllocations.keySet().isEmpty()) {
                skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
                skedJobAllocationPostProcessBatch.schedule(batchSetting, jobAllocations.keyset(), 200, 0);
                //Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, jobAllocations.keyset()), 200);
            }
        }
        this.coImpactChanges.remove(0);
        if (!this.coImpactChanges.isEmpty()) {
            Database.executeBatch(new skedCaptureJobIMPACTBatch(this.coImpactChanges), 50);
        }
    }
}