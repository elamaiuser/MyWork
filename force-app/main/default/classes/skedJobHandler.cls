public class skedJobHandler extends skedTriggerHub {  
    private static final List<String> PERMITTED_INSERT_EDIT_PROFILES = new List<String>{
        'Global Admin', 'System Administrator', 'Integration User', 'APS Admin', 'Collections', 'Collection Management'
    };

    private static final List<String> PERMITTED_DELETE_PROFILES = new List<String>{
        'Global Admin', 'System Administrator', 'Integration User', 'APS Admin'
    };
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.RECORD_CHANGES_INVALID_FROM_LIST_VIEW, PERMITTED_INSERT_EDIT_PROFILES);
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
        autoCorrectDuration(this.context.newRecords);
        populateScheduler(this.context.newRecords);
        updateVARLastModifiedBy(this.context.newRecords,null);
    }
    
    public override void onAfterInsert() {
        populateJobTags(this.context.newRecords);
        updateDriveShiftVolunteerSetup(this.context.newRecords, null);
    }
    
    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.RECORD_CHANGES_INVALID_FROM_LIST_VIEW, PERMITTED_INSERT_EDIT_PROFILES);
        populateData(this.context.newRecords, (Map<Id, sked__Job__c>)this.context.oldMap);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Job__c>)this.context.oldMap);
        }
        autoCorrectDuration(this.context.newRecords, (Map<Id, sked__Job__c>)this.context.oldMap);
        updateVARLastModifiedBy(this.context.newRecords,(Map<Id, sked__Job__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        addDualRole(this.context.newRecords, (Map<Id, sked__Job__c>)this.context.oldMap);
        rescheduleJob(this.context.newRecords, (Map<Id, sked__Job__c>)this.context.oldMap);
        if (!skedSetting.instance.Admin.migrationMode) {
            onJobStatusChanged(this.context.newRecords, (Map<Id, sked__Job__c>)this.context.oldMap);
        }
        updateDriveShiftResourceAllocated(this.context.newRecords, (Map<Id, sked__Job__c>)this.context.oldMap);
        updateDriveShiftVolunteerSetup(this.context.newRecords, (Map<Id, sked__Job__c>)this.context.oldMap);
        if (!skedSetting.instance.Admin.migrationMode) {
            sendNotification(this.context.newRecords, (Map<Id, sked__Job__c>)this.context.oldMap);
        }
    }

    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.oldRecords, skedConstants.RECORD_CHANGES_INVALID_FROM_LIST_VIEW, PERMITTED_DELETE_PROFILES);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void addDualRole(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        Set<Id> jobIds = new Set<Id>();
        for (sked__Job__c newRecord : newRecords) {
            sked__Job__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Dual_Role__c != oldData.sked_Dual_Role__c) {
                jobIds.add(newRecord.Id);
            }
        }
        if (!jobIds.isEmpty()) {
            List<sked__Tag__c> skedRoleTags = [SELECT Id, Name
                                               FROM sked__Tag__c
                                               WHERE sked__Type__c = :skedConstants.TAG_TYPE_ROLE]; 
            Map<string, sked__Tag__c> mapRole = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedRoleTag : skedRoleTags) {
                mapRole.put(skedRoleTag.Name, skedRoleTag);
            }
            
            List<sked__Job__c> skedJobs = [SELECT Id, sked_Resource_Role__c, sked_Dual_Role__c, 
                                           (SELECT Id, sked__Tag__r.Name, sked_SystemCreated__c
                                            FROM sked__JobTags__r
                                            WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE)
                                           FROM sked__Job__c
                                           WHERE Id IN :jobIds];
            List<sked__Job_Tag__c> jobTagsToInsert = new List<sked__Job_Tag__c>();
            List<sked__Job_Tag__c> jobTagsToDelete = new List<sked__Job_Tag__c>();
            for (sked__Job__c skedJob : skedJobs) {
                Set<string> jobRoles = new Set<string>();
                jobRoles.add(skedJob.sked_Resource_Role__c);
                jobRoles.add(skedJob.sked_Dual_Role__c);
                
                Set<string> existingTagRoles = new Set<string>();
                for (sked__Job_Tag__c skedJobTag : skedJob.sked__JobTags__r) {
                    existingTagRoles.add(skedJobTag.sked__Tag__r.Name);
                    
                    if (skedJobTag.sked_SystemCreated__c == TRUE && !jobRoles.contains(skedJobTag.sked__Tag__r.Name)) {
                        jobTagsToDelete.add(skedJobTag);
                    }
                }
                if (skedJob.sked_Dual_Role__c != NULL) {
                    if (!existingTagRoles.contains(skedJob.sked_Dual_Role__c)) {
                        sked__Tag__c skedTag = mapRole.get(skedJob.sked_Dual_Role__c);
                        sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
                            sked__Job__c = skedJob.Id,
                            sked__Tag__c = skedTag.Id
                            //sked_SystemCreated__c = TRUE
                            //TODO: commented above line due to the conflict between lwc and apex - 
                            //when job is updated, dualRoleTag is deleted, then lwc tries to update dualRoleTag, caused Entity is Deleted
                        );
                        jobTagsToInsert.add(skedJobTag);
                    }
                }
            }
            if (!jobTagsToInsert.isEmpty()) {
                insert jobTagsToInsert;
            }
            if (!jobTagsToDelete.isEmpty()) {
                delete jobTagsToDelete;
            }
         }
    }
    
    private void autoCorrectDuration(List<sked__Job__c> newRecords) {
        for (sked__Job__c newRecord : newRecords) {
            if (newRecord.sked__Start__c != NULL && newRecord.sked__Finish__c != NULL) {
                integer duration = skedDateTimeUtils.getDifferentMinutes(newRecord.sked__Start__c, newRecord.sked__Finish__c);
                if (newRecord.sked__Duration__c != duration) {
                    newRecord.sked__Duration__c = duration;
                }
            }
        }
    }
    
    private void autoCorrectDuration(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        for (sked__Job__c newRecord : newRecords) {
            sked__Job__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Start__c != oldData.sked__Start__c || newRecord.sked__Finish__c != oldData.sked__Finish__c) {
                if (newRecord.sked__Start__c != NULL && newRecord.sked__Finish__c != NULL) {
                    integer duration = skedDateTimeUtils.getDifferentMinutes(newRecord.sked__Start__c, newRecord.sked__Finish__c);
                    if (newRecord.sked__Duration__c != duration) {
                        newRecord.sked__Duration__c = duration;
                    }
                }
            }
        }
    }
    
    private void onJobStatusChanged(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        Set<Id> cancelledJobIds = new Set<Id>();
        Set<Id> jobIdsToConfirmAllocations = new Set<Id>();
        for (sked__Job__c newData : newRecords) {
            sked__Job__c oldData = oldMap.get(newData.Id);
            if (newData.sked__Job_Status__c != oldData.sked__Job_Status__c) {
                if (newData.sked__Job_Status__c == skedConstants.JOB_STATUS_CANCELLED) {
                    cancelledJobIds.add(newData.Id);
                }
                else if (newData.sked__Job_Status__c == skedConstants.JOB_STATUS_READY) {
                    jobIdsToConfirmAllocations.add(newData.Id);
                }
            }
        }
        if (!cancelledJobIds.isEmpty()) {
            List<sked__Job_Allocation__c> allocationsToDelete = [SELECT Id, sked__Status__c, sked_Time_Cancelled__c
                                                                 FROM sked__Job_Allocation__c
                                                                 WHERE sked__Job__c IN :cancelledJobIds
                                                                 AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                                 AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED];
            if (!allocationsToDelete.isEmpty()) {
                DateTime timeCancelled = system.now();
                for (sked__Job_Allocation__c skedAllocation : allocationsToDelete) {
                    skedAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
                    skedAllocation.sked_Time_Cancelled__c = timeCancelled;
                }
                update allocationsToDelete;
            }
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
            service.removeExceptionLogsWhenCancellingJobs(cancelledJobIds);
        }
        if (!jobIdsToConfirmAllocations.isEmpty()) {
            List<sked__Job_Allocation__c> allocationsToConfirm = [SELECT Id
                                                                  FROM sked__Job_Allocation__c
                                                                  WHERE sked__Job__c IN :jobIdsToConfirmAllocations
                                                                  AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED
                                                                  AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                                  AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED];
            if (!allocationsToConfirm.isEmpty()) {
                for (sked__Job_Allocation__c skedAllocation : allocationsToConfirm) {
                    skedAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED;
                }
                update allocationsToConfirm;
            }
        }
    }
    
    private Map<Id, sked__Region__c> getMapRegionFromJobs(List<sked__Job__c> newRecords) {
        Set<Id> regionIds = new Set<Id>();
        for (sked__Job__c newRecord : newRecords) {
            if (newRecord.sked__Region__c != NULL) {
                regionIds.add(newRecord.sked__Region__c);
            }
        }
        return new Map<Id, sked__Region__c>([
            SELECT Id, sked__Timezone__c
            FROM sked__Region__c
            WHERE Id IN :regionIds
        ]);
    }

    private void doDateTimeConversion(List<sked__Job__c> newRecords) {
        Map<Id, sked__Region__c> mapRegion = getMapRegionFromJobs(newRecords);
        
        for (sked__Job__c newRecord : newRecords) {
            string timezoneSidId;
            if (mapRegion.containsKey(newRecord.sked__Region__c)) {
                sked__Region__c region = mapRegion.get(newRecord.sked__Region__c);
                timezoneSidId = region.sked__Timezone__c;
            }
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Finish__c', 'sked_Finish_Date__c', 'sked_Finish_Time__c', 'sked__Timezone__c', timezoneSidId);
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked__Timezone__c', timezoneSidId);
        }
    }

    private void doDateTimeConversion(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        Map<Id, sked__Region__c> mapRegion = getMapRegionFromJobs(newRecords);
        
        for (sked__Job__c newRecord : newRecords) {
            string timezoneSidId;
            if (mapRegion.containsKey(newRecord.sked__Region__c)) {
                sked__Region__c region = mapRegion.get(newRecord.sked__Region__c);
                timezoneSidId = region.sked__Timezone__c;
            }
            
            sked__Job__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Finish__c', 'sked_Finish_Date__c', 'sked_Finish_Time__c', 'sked__Timezone__c', timezoneSidId);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked__Timezone__c', timezoneSidId);
        }
    }

    private void populateData(List<sked__Job__c> newRecords) {
        Set<Id> locationIds = new Set<Id>();
        Set<Id> driveShiftIds = new Set<Id>();
        for (sked__Job__c newRecord : newRecords) {
            if (newRecord.sked__Start__c != NULL && newRecord.sked__Finish__c != NULL) {
                newRecord.sked__Duration__c = skedDateTimeUtils.getDifferentMinutes(newRecord.sked__Start__c, newRecord.sked__Finish__c);
            }
            if (newRecord.sked__Location__c != NULL) {
                locationIds.add(newRecord.sked__Location__c);
            }
            if (newRecord.sked_Drive_Shift__c != NULL) {
                driveShiftIds.add(newRecord.sked_Drive_Shift__c);
            }
            newRecord.sked__Can_Be_Declined__c = false;
            newRecord.sked__Type__c = newRecord.sked_Resource_Role__c != NULL ? newRecord.sked_Resource_Role__c 
                : newRecord.sked_Asset_Type__c != NULL ? newRecord.sked_Asset_Type__c : newRecord.sked_Volunteer_Role__c;
        }
        if (!driveShiftIds.isEmpty()) {
            Map<Id, sked_Drive_Shift__c> mapDriveShift = new Map<Id, sked_Drive_Shift__c>([SELECT Id, sked_Drive__c, sked_Drive__r.sked_Account__c
                                                                                           FROM sked_Drive_Shift__c
                                                                                           WHERE Id IN :driveShiftIds]);
            for (sked__Job__c newRecord : newRecords) {
                if (newRecord.sked_Drive_Shift__c != NULL) {
                    sked_Drive_Shift__c skedDriveShift = mapDriveShift.get(newRecord.sked_Drive_Shift__c);
                    newRecord.sked_Drive__c = skedDriveShift.sked_Drive__c;
                    newRecord.sked__Account__c = skedDriveShift.sked_Drive__r.sked_Account__c;
                }
            }
        }
        if (!locationIds.isEmpty()) {
            populateLocationData(locationIds, newRecords);
        }
    }
    
    private void populateData(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        Set<Id> locationIds = new Set<Id>();
        List<sked__Job__c> recordsToPopulate = new List<sked__Job__c>();
        for (sked__Job__c newRecord : newRecords) {
            sked__Job__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Start__c != oldData.sked__Start__c || newRecord.sked__Finish__c != oldData.sked__Finish__c) {
                newRecord.sked__Duration__c = skedDateTimeUtils.getDifferentMinutes(newRecord.sked__Start__c, newRecord.sked__Finish__c);
            }
            if (newRecord.sked_Volunteer_Role__c != oldData.sked_Volunteer_Role__c) {
                newRecord.sked__Type__c = newRecord.sked_Volunteer_Role__c;
            }
            if (newRecord.sked_Is_Geolocation_Mismatched__c == TRUE || newRecord.sked__Location__c != oldData.sked__Location__c) {
                locationIds.add(newRecord.sked__Location__c);
                recordsToPopulate.add(newRecord);
            }
        }
        if (!locationIds.isEmpty()) {
            populateLocationData(locationIds, recordsToPopulate);
        }
    }
    
    private void populateLocationData(Set<Id> locationIds, List<sked__Job__c> newRecords) {
        Map<Id, sked__Location__c> mapLocation = new Map<Id, sked__Location__c>([SELECT Id, sked__Region__c, sked__Address__c,
                                                                                 sked__GeoLocation__Latitude__s,
                                                                                 sked__GeoLocation__Longitude__s,
                                                                                 (SELECT Id, sked_Start_Date__c, sked_End_Date__c,
                                                                                  sked_Region__c
                                                                                  FROM sked_Site_Collection_Operations__r)
                                                                                 FROM sked__Location__c
                                                                                 WHERE Id IN :locationIds]);
        Set<Id> driveIds = new Set<Id>();
        for (sked__Job__c newRecord : newRecords) {
            if (newRecord.sked_Drive__c != NULL) {
                driveIds.add(newRecord.sked_Drive__c);
            }
        }
        Map<Id, sked_Drive__c> mapDrive = new Map<Id, sked_Drive__c>([SELECT Id, sked_Drive_Date__c
                                                                      FROM sked_Drive__c
                                                                      WHERE ID IN :driveIds]);
        
        for (sked__Job__c newRecord : newRecords) {
            if (newRecord.sked__Location__c != NULL && newRecord.sked__Region__c == NULL) {
                sked__Location__c skedLocation = mapLocation.get(newRecord.sked__Location__c);
                newRecord.sked__Address__c = skedLocation.sked__Address__c;
                newRecord.sked__GeoLocation__Latitude__s = skedLocation.sked__GeoLocation__Latitude__s;
                newRecord.sked__GeoLocation__Longitude__s = skedLocation.sked__GeoLocation__Longitude__s;
                if (skedLocation.sked_Site_Collection_Operations__r != NULL) {
                    sked_Drive__c drive = mapDrive.get(newRecord.sked_Drive__c);
                    if (drive != NULL) {
                        for (sked_Site_Collection_Operation__c siteCO : skedLocation.sked_Site_Collection_Operations__r) {
                            if (siteCO.sked_Start_Date__c <= drive.sked_Drive_Date__c && drive.sked_Drive_Date__c <= siteCO.sked_End_Date__c) {
                                newRecord.sked__Region__c = siteCO.sked_Region__c;
                            }
                        }
                    }
                }
            }
        }
    }

    private void populateJobTags(List<sked__Job__c> newRecords) {
        List<sked__Job_Tag__c> allJobTags = new List<sked__Job_Tag__c>();

        List<sked__Job_Tag__c> resourceRoleTags = generateResourceRoleTag(newRecords);
        if (resourceRoleTags != NULL && !resourceRoleTags.isEmpty()) {
            allJobTags.addAll(resourceRoleTags);
        }

        List<sked__Job_Tag__c> driveTypeTags = generateDriveTypeTag(newRecords);
        if (driveTypeTags != NULL && !driveTypeTags.isEmpty()) {
            allJobTags.addAll(driveTypeTags);
        }

        if (!allJobTags.isEmpty()) {
            insert allJobTags;
        }
    }
    
    private List<sked__Job_Tag__c> generateResourceRoleTag(List<sked__Job__c> newRecords) {
        List<sked__Job_Tag__c> skedJobTags = new List<sked__Job_Tag__c>();

        Set<string> tagNames = new Set<string>();
        for (sked__Job__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked_Resource_Role__c)) {
                tagNames.add(newRecord.sked_Resource_Role__c);
            }
            if (!string.isBlank(newRecord.sked_Asset_Type__c)) {
                tagNames.add(newRecord.sked_Asset_Type__c);
            }
            if (!string.isBlank(newRecord.sked_Dual_Role__c)) {
                tagNames.add(newRecord.sked_Dual_Role__c);
            }
        }
        if (!tagNames.isEmpty()) {
            List<sked__Tag__c> skedRoleTags = [SELECT Id, Name
                                               FROM sked__Tag__c
                                               WHERE Name IN :tagNames
                                               AND (sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                                                   OR sked__Type__c = :skedConstants.TAG_TYPE_ASSET_TYPE)]; 
            Map<string, sked__Tag__c> mapRole = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedRoleTag : skedRoleTags) {
                mapRole.put(skedRoleTag.Name, skedRoleTag);
            }
            
            for (sked__Job__c newRecord : newRecords) {
                if (!string.isBlank(newRecord.sked_Resource_Role__c)) {
                    List<sked__Tag__c> skedTags = new List<sked__Tag__c>();
                    if(mapRole.containsKey(newRecord.sked_Resource_Role__c)) {
                        skedTags.add(mapRole.get(newRecord.sked_Resource_Role__c));
                    }
                    if(mapRole.containsKey(newRecord.sked_Dual_Role__c)) {
                        skedTags.add(mapRole.get(newRecord.sked_Dual_Role__c));
                    }
                    
                    if (!skedTags.isEmpty()) {
                        for(sked__Tag__c skedTag : skedTags) {
                            sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
                                sked__Job__c = newRecord.Id,
                                sked__Tag__c = skedTag.Id,
                                sked_SystemCreated__c = TRUE
                            );
                            skedJobTags.add(skedJobTag);
                        }
                    }
                }
                if (!string.isBlank(newRecord.sked_Asset_Type__c)) {
                    sked__Tag__c skedTag = mapRole.get(newRecord.sked_Asset_Type__c);
                    if (skedTag != NULL) {
                        sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
                        	sked__Job__c = newRecord.Id,
                            sked__Tag__c = skedTag.Id,
                            sked_SystemCreated__c = TRUE
                        );
                        skedJobTags.add(skedJobTag);
                    }
                }
                if (!string.isBlank(newRecord.sked_Equipment_Subtype__c) && mapRole.containsKey(newRecord.sked_Equipment_Subtype__c)) {
                    sked__Tag__c skedTag = mapRole.get(newRecord.sked_Equipment_Subtype__c);
                    if (skedTag != NULL) {
                        sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
                        	sked__Job__c = newRecord.Id,
                            sked__Tag__c = skedTag.Id,
                            sked_SystemCreated__c = TRUE
                        );
                        skedJobTags.add(skedJobTag);
                    }
                }
            }
        }
        return skedJobTags;
    }
    
    private List<sked__Job_Tag__c> generateDriveTypeTag(List<sked__Job__c> newRecords) {
        List<sked__Job_Tag__c> newJobTags = new List<sked__Job_Tag__c>();
        
        Set<Id> driveIds = new Set<Id>();
        for (sked__Job__c newRecord : newRecords) {
            if (newRecord.sked_Drive__c != NULL) {
                driveIds.add(newRecord.sked_Drive__c);
            }
        }
        if (!driveIds.isEmpty()) {
            List<sked__Tag__c> driveTypeTags = [SELECT Id, Name
                                                FROM sked__Tag__c
                                                WHERE sked__Type__c = :skedConstants.TAG_TYPE_DRIVE_TYPE]; 
            Map<string, sked__Tag__c> mapDriveTypeTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c driveTypeTag : driveTypeTags) {
                mapDriveTypeTag.put(driveTypeTag.Name, driveTypeTag);
            }
            
            Map<Id, sked_Drive__c> mapDrive = new Map<Id, sked_Drive__c>([
                SELECT Id, sked_Type_of_Drive__c, sked_Operation_Type__c
                FROM sked_Drive__c
                WHERE Id IN :driveIds
            ]);

            for (sked__Job__c newRecord : newRecords) {
                if (newRecord.sked_Drive__c != NULL) {
                    sked_Drive__c skedDrive = mapDrive.get(newRecord.sked_Drive__c);
                    sked__Tag__c skedTag;
                    if (
                        skedDrive.sked_Type_of_Drive__c == skedConstants.DRIVE_TYPE_MOBILE ||
                        (skedDrive.sked_Type_of_Drive__c == skedConstants.DRIVE_TYPE_FIXED_SITE && 
                        skedDrive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_WB)
                    ) {
                        skedTag = mapDriveTypeTag.get(skedConstants.DRIVE_TYPE_MOBILE);
                    } else if (
                        skedDrive.sked_Type_of_Drive__c == skedConstants.DRIVE_TYPE_FIXED_SITE && 
                        skedDrive.sked_Operation_Type__c != skedConstants.OPERATION_TYPE_WB
                    ) {
                        skedTag = mapDriveTypeTag.get(skedConstants.DRIVE_TYPE_FIXED_SITE);
                    }

                    if (skedTag != NULL) {
                        sked__Job_Tag__c newJobTag = new sked__Job_Tag__c(
                            sked__Job__c = newRecord.Id,
                            sked__Tag__c = skedTag.Id,
                            sked_SystemCreated__c = TRUE
                        );
                        newJobTags.add(newJobTag);
                    }
                }
            }
        }
        return newJobTags;
    }

    private void populateScheduler(List<sked__Job__c> newRecords) {
        Set<Id> driveIds = new Set<Id>();
        for (sked__Job__c newRecord : newRecords) {
            if (newRecord.sked_Drive__c != NULL) {
                driveIds.add(newRecord.sked_Drive__c);
            }
        }
        
        if (!driveIds.isEmpty()) {
            List<sked_Drive__c> drives = [SELECT Id, Name, sked_Collection_Operation__r.sked_Collections_Manager__c, sked_Collection_Operation__r.sked_Primary_Scheduler__c
                                          FROM sked_Drive__c
                                          WHERE Id IN :driveIds]; 
            Map<string, sked_Drive__c> mapDrive = new Map<string, sked_Drive__c>(drives);
            for (sked__Job__c newRecord : newRecords) {
                if (newRecord.sked_Drive__c != NULL) {
                    sked_Drive__c drive = mapDrive.get(newRecord.sked_Drive__c);
                    newRecord.sked_Collections_Manager__c = drive.sked_Collection_Operation__r.sked_Collections_Manager__c;
                    newRecord.sked_Primary_Scheduler__c = drive.sked_Collection_Operation__r.sked_Primary_Scheduler__c;
                }
            }
        }
    }
    
    public void updateDriveShiftResourceAllocated(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        Set<Id> driveShiftIds = new Set<Id>();
        for (sked__Job__c newRecord : newRecords) {
            sked__Job__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Job_Allocation_Count__c != oldData.sked__Job_Allocation_Count__c) {
                driveShiftIds.add(newRecord.sked_Drive_Shift__c);
            }
        }
        if (!driveShiftIds.isEmpty()) {
            List<sked_Drive_Shift__c> driveShifts = [SELECT Id, sked_Drive__c, sked_Drive__r.sked_Account__c, sked_Vehicles_Allocated__c,
                                                     sked_Equipment_Allocated__c, sked_Staff_Allocated__c, sked_Assigned_Staff_Count__c,
                                                     (SELECT Id, sked__Job_Allocation_Count__c, sked_Asset_Type__c, sked_Resource_Role__c
                                                      FROM sked_Jobs__r
                                                      WHERE sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED)
                                                     FROM sked_Drive_Shift__c
                                                     WHERE Id IN :driveShiftIds];
            Set<String> staffAllocatedExcludedRoles = new Set<String>();
            Set<String> assignedStaffCountExcludedRoles = new Set<String>();
            for (sked_Staff_Setup_Excluded_Role__c staffSetupExcludedRole : [
                SELECT sked_Resource_Role__c, sked_Excluded_For_Staff_Allocated__c, sked_Excluded_for_Assigned_Staff_Count__c
                FROM sked_Staff_Setup_Excluded_Role__c
            ]) {
                if (staffSetupExcludedRole.sked_Excluded_For_Staff_Allocated__c == true) {
                    staffAllocatedExcludedRoles.add(staffSetupExcludedRole.sked_Resource_Role__c);
                }
                if (staffSetupExcludedRole.sked_Excluded_for_Assigned_Staff_Count__c == true) {
                    assignedStaffCountExcludedRoles.add(staffSetupExcludedRole.sked_Resource_Role__c);
                }
            }

            for (sked_Drive_Shift__c driveShift : driveShifts) {
                driveShift.sked_Assigned_Staff_Count__c = 0;
                driveShift.sked_Staff_Allocated__c = 0;
                driveShift.sked_Equipment_Allocated__c = 0;
                driveShift.sked_Vehicles_Allocated__c = 0;

                if (driveShift.sked_Jobs__r != NULL) {
                    for (sked__Job__c skedJob : driveShift.sked_Jobs__r) {
                        if (skedJob.sked_Resource_Role__c != NULL) {
                            if (!staffAllocatedExcludedRoles.contains(skedJob.sked_Resource_Role__c)) {
                                driveShift.sked_Staff_Allocated__c += skedJob.sked__Job_Allocation_Count__c;
                            }
                            if (!assignedStaffCountExcludedRoles.contains(skedJob.sked_Resource_Role__c)) {
                                driveShift.sked_Assigned_Staff_Count__c += skedJob.sked__Job_Allocation_Count__c;
                            }
                        }
                        else if (skedJob.sked_Asset_Type__c != NULL) {
                            if (skedJob.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                                driveShift.sked_Vehicles_Allocated__c += skedJob.sked__Job_Allocation_Count__c;
                            }
                            else if (skedJob.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                                driveShift.sked_Equipment_Allocated__c += skedJob.sked__Job_Allocation_Count__c;
                            }
                        }
                    }
                }
            }
            update driveShifts;
        }
    }

    private void updateDriveShiftVolunteerSetup(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        Set<Id> driveShiftIds = new Set<Id>();
        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();

        for (sked__Job__c newRecord : newRecords) {
            if (newRecord.sked_Volunteer_Role__c == null || newRecord.sked_Drive_Shift__c == null) {
                continue;
            }

            if (oldMap == null) {
                driveShiftIds.add(newRecord.sked_Drive_Shift__c);                
            } else {
                sked__Job__c oldData = oldMap.get(newRecord.Id);
                Boolean isRedcrossVolunteerQuantityChanged = newRecord.sked_Redcross_Volunteer_Quantity__c != oldData.sked_Redcross_Volunteer_Quantity__c;
                Boolean isQuantityChanged = newRecord.sked__Quantity__c != oldData.sked__Quantity__c;                
                
                if(isRedcrossVolunteerQuantityChanged || isQuantityChanged) {
                    driveShiftIds.add(newRecord.sked_Drive_Shift__c);
                }
            }            
        }
        if (!driveShiftIds.isEmpty()) {
            List<AggregateResult> sumOfVolunteerJobs = [SELECT sked_Drive_Shift__c shiftId, SUM(sked__Quantity__c) jobQuantity
                                                        FROM sked__Job__c
                                                        WHERE sked_Drive_Shift__c IN :driveShiftIds
                                                        AND sked_Volunteer_Role__c != null
                                                        AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                                        GROUP BY sked_Drive_Shift__c];

            Map<Id, Decimal> sumOfVolunteerJobsByShift = new Map<Id, Decimal>();

            for (AggregateResult sumOfVolunteerJob : sumOfVolunteerJobs) {
                sumOfVolunteerJobsByShift.put((Id) sumOfVolunteerJob.get('shiftId'), (Decimal) sumOfVolunteerJob.get('jobQuantity'));
            }

            for (Id driveShiftId : driveShiftIds) {
                Decimal total = sumOfVolunteerJobsByShift.get(driveShiftId);
                driveShifts.add(new sked_Drive_Shift__c (Id = driveShiftId, sked_Volunteer_Setup__c = (total == null ? 0 : total)));
            }
            update driveShifts;
        }
    }
    
    private void rescheduleJob(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        Set<Id> rescheduledJobIds = new Set<Id>();
        for (sked__Job__c newRecord : newRecords) {
            sked__Job__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Start__c != oldData.sked__Start__c || newRecord.sked__Finish__c != oldData.sked__Finish__c) {
                rescheduledJobIds.add(newRecord.Id);
            }
        }
        if (!rescheduledJobIds.isEmpty()) {
            List<sked__Job__c> rescheduledJobs = [SELECT Id, sked__Start__c, sked__Finish__c,
                                                  (SELECT Id, sked__Start__c, sked__Set_End__c
                                                   FROM sked__Job_Allocations__r
                                                   WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED)
                                                  FROM sked__Job__c
                                                  WHERE Id IN :rescheduledJobIds];
            List<sked__Job_Allocation__c> allocationsToUpdate = new List<sked__Job_Allocation__c>();
            for (sked__Job__c rescheduledJob : rescheduledJobs) {
                if (rescheduledJob.sked__Job_Allocations__r != NULL && !rescheduledJob.sked__Job_Allocations__r.isEmpty()) {
                    sked__Job__c oldData = oldMap.get(rescheduledJob.Id);
                    for (sked__Job_Allocation__c allocation : rescheduledJob.sked__Job_Allocations__r) {
                        if (rescheduledJob.sked__Start__c != oldData.sked__Start__c) {
                            integer difference = skedDateTimeUtils.getDifferentMinutes(oldData.sked__Start__c, rescheduledJob.sked__Start__c);
                            allocation.sked__Start__c = allocation.sked__Start__c.addMinutes(difference);
                        }
                        if (rescheduledJob.sked__Finish__c != oldData.sked__Finish__c) {
                            integer difference = skedDateTimeUtils.getDifferentMinutes(oldData.sked__Finish__c, rescheduledJob.sked__Finish__c);
                            allocation.sked__Set_End__c = allocation.sked__Set_End__c.addMinutes(difference);
                        }
                        integer duration = skedDateTimeUtils.getDifferentMinutes(allocation.sked__Start__c, allocation.sked__Set_End__c);
                        allocation.sked__Duration__c = duration;
                        allocationsToUpdate.add(allocation);
                    }
                }
            }
            if (!allocationsToUpdate.isEmpty()) {
                update allocationsToUpdate;
            }
        }
    }

    private void sendNotification(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        List<sked__Job__c> impactedJobs = new List<sked__Job__c>();
        Map<Id, sked__Job__c> oldImpactedJobMap = new Map<Id, sked__Job__c>();

        Set<Id> newRecordIds = new Set<Id>();
        for (sked__Job__c job : newRecords) {
            newRecordIds.add(job.Id);
        }
        Map<Id, sked__Job__c> mapJobs = new Map<Id, sked__Job__c>([SELECT Id, sked_Drive__r.sked_Linked_Drives__c, sked_Drive__r.sked_Opportunity__c,
                                                                   (SELECT Id 
                                                                    FROM sked__Job_Allocations__r 
                                                                    WHERE sked__Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
                                                                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
                                                                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED)
                                                                   FROM sked__Job__c
                                                                   WHERE Id IN :newRecordIds]);

        for (sked__Job__c newRecord : newRecords) {
			sked__Job__c oldData = oldMap.get(newRecord.Id);
            sked__Job__c skedJob = mapJobs.get(newRecord.Id);
            if (skedJob.sked__Job_Allocations__r != NULL && !skedJob.sked__Job_Allocations__r.isEmpty()) {
                if (newRecord.sked__Address__c != oldData.sked__Address__c) {
                    impactedJobs.add(newRecord);
                    oldImpactedJobMap.put(newRecord.Id, oldData);
                }
            }
        }
        if (!impactedJobs.isEmpty()) {
            new skedCustomNotificationService(
                new List<string> {
                    'sked_Job_Info_Changed_OneOff',
                    'sked_Job_Info_Changed_Email',
                    'sked_Job_Info_Changed_SFPush'
                }
            ).generateNotifications(impactedJobs, oldImpactedJobMap);
        }
    }
    private void updateVARLastModifiedBy(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        for (sked__Job__c newRecord : newRecords) {
            if((newRecord.Id == null || oldMap == null || !oldMap.containsKey(newRecord.Id)) 
                        && String.isNotBlank(newRecord.sked_Volunteer_Adjustment_Reason__c)) {
                            newRecord.sked_VAR_Last_Modified_By__c = UserInfo.getUserId();
            }else if(newRecord.Id != null && oldMap != null && oldMap.containsKey(newRecord.Id) 
                    && oldMap.get(newRecord.Id).sked_Volunteer_Adjustment_Reason__c 
                    != newRecord.sked_Volunteer_Adjustment_Reason__c) {
                        newRecord.sked_VAR_Last_Modified_By__c = UserInfo.getUserId();
            }
        }
    }
}