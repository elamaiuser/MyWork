/* 
 * @description: This class is called from Resource Tag trigger.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 1/8/2025			         Satyendra Vishwakarma	     Logic for HRP-8802
 ************************************************************************************************************************************************
*/
public class skedResourceHandler extends skedTriggerHub {
    
    public static boolean canUpdateResourceRole = false;
    
    public override void onBeforeInsert() {
        validate(this.context.newRecords, null);
        populateData(this.context.newRecords);
        populateSupervisor(this.context.newRecords);
        populateTaxonomyData(this.context.newRecords);
        populateResourceActivation(this.context.newRecords);
        updateAddress(this.context.newRecords);
        updatePrimaryPhone(this.context.newRecords);
        onUpsertResourceRoles(this.context.newRecords);
        updateResourceSeniorityRankings(this.context.newRecords, null); 
    }
    
    public override void onAfterInsert() {
        addAssetTypeTags(this.context.newRecords);
        addMobileTypeTags(this.context.newRecords);
        addEquipmentDriveTypeTags(this.context.newRecords);
        addPersonDriveTypeTags(this.context.newRecords);
        addRealIdTypeTags(this.context.newRecords);
        assignDefaultPatterns(this.context.newRecords);
        
        if (!skedSetting.instance.Admin.migrationMode) {
            populateGeoLocation(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        validate(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        if (!skedSetting.instance.Admin.migrationMode) {
            revertAccidientallyChangedGeolocation(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        }
        populateData(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        clearAnticipatedLeaveReturnDate(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);//HRP-12869
        populateSupervisor(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        populateTaxonomyData(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        populateResourceActivation(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        updateAddress(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        updatePrimaryPhone(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        onUpsertResourceRoles(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        updateResourceSeniorityRankings(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap); 
    }
    
    public override void onAfterUpdate() {
        updateMobileTypeTags(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        updateEquipmentDriveTypeTags(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        updatePersonDriveTypeTags(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        updateRealIdTypeTags(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        
        if (!skedSetting.instance.Admin.migrationMode) {
            captureFieldChangeExceptionLog(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
            captureResourceIsInactiveExceptionLog(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
            cancelTimeOffOnResourceTerminationOrLeave(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
            populateGeoLocation(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
            captureWorkDaysPerWeekException(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
            onDeactivateResources(this.context.newRecords, (Map<Id, sked__Resource__c>)this.context.oldMap);
        }
    }

    public override void onBeforeDelete() {
        validate(this.context.oldRecords, null);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void validate(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        for (sked__Resource__c newRecord : newRecords) {
            if (newRecord.sked__Geolocation__Longitude__s != NULL || newRecord.sked__GeoLocation__Latitude__s != NULL) {
                if (newRecord.sked__Geolocation__Longitude__s < -180 || newRecord.sked__Geolocation__Longitude__s >= -30  || newRecord.sked__GeoLocation__Latitude__s > 71 || newRecord.sked__GeoLocation__Latitude__s < 25) {
                    newRecord.addError('Geolocation must be in North America ');
                }
            }

            if (newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_ASSET && !skedUserProfileObjectAccessUtils.hasPermission('Asset CRUD', this.context)) {
                newRecord.addError(skedConstants.RESOURCE_ASSET_CRUD_REQUIRES_SYSADMIN);
            }

            if (String.isBlank(newRecord.sked_Asset_Type__c) || newRecord.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                sked__Resource__c oldRecord;
                if(oldMap != null) {
                    oldRecord = oldMap.get(newRecord.Id);
                }

                if((newRecord.sked_Dedicated_to_Site__c != null || String.isNotBlank(newRecord.sked_Dedicated_to_Site__c)) 
                && (oldRecord == null || (oldRecord != null && newRecord.sked_Dedicated_to_Site__c != oldRecord.sked_Dedicated_to_Site__c))) {
                    system.debug('getting inside validation oldRecord '+oldRecord.sked_Dedicated_to_Site__c+' newRecord '+newRecord.sked_Dedicated_to_Site__c);
                    newRecord.sked_Dedicated_to_Site__c.addError(Custom_Messages__mdt.getInstance('Asset_Validation_for_Dedicated_to_Site').Value__c);
                }
            }
        }
    }
    
    private void addAssetTypeTags(List<sked__Resource__c> newRecords) {
        List<sked__Resource__c> assetResources = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            if (newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_ASSET) {
                assetResources.add(newRecord);
            }
        }
        if (!assetResources.isEmpty()) {
            List<sked__Tag__c> assetTypeTagQuery = [SELECT Id, Name
                                                    FROM sked__Tag__c 
                                                    WHERE sked__Type__c = :skedConstants.TAG_TYPE_ASSET_TYPE];
            if (!assetTypeTagQuery.isEmpty()) {
                Date startDate = system.today();
                
                Map<string, sked__Tag__c> mapAssetTypeTag = new Map<string, sked__Tag__c>();
                for (sked__Tag__c assetTypeTag : assetTypeTagQuery) {
                    mapAssetTypeTag.put(assetTypeTag.Name, assetTypeTag);
                }
                List<sked__Resource_Tag__c> newResourceTags = new List<sked__Resource_Tag__c>();
                for (sked__Resource__c assetResource : assetResources) {
                    if (mapAssetTypeTag.containsKey(assetResource.sked_Asset_Type__c)) {
                        sked__Tag__c assetTypeTag = mapAssetTypeTag.get(assetResource.sked_Asset_Type__c);
                        sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                            sked__Resource__c = assetResource.Id,
                            sked__Tag__c = assetTypeTag.Id,
                            sked_Start_Date__c = startDate,
                            sked_Role_Status__c = 'Active'
                        );
                        newResourceTags.add(newResourceTag);
                    }
                    if (mapAssetTypeTag.containsKey(assetResource.sked_Equipment_Subtype__c)) {
                        sked__Tag__c equipmentSubTypeTag = mapAssetTypeTag.get(assetResource.sked_Equipment_Subtype__c);
                        sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                            sked__Resource__c = assetResource.Id,
                            sked__Tag__c = equipmentSubTypeTag.Id,
                            sked_Start_Date__c = startDate,
                            sked_Role_Status__c = 'Active'
                        );
                        newResourceTags.add(newResourceTag);
                    }
                }
                insert newResourceTags;
            }
        }
    }
    
    private void addMobileTypeTags(List<sked__Resource__c> newRecords) {
        List<sked__Resource__c> recordsToPopulate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked_Mobile_Type__c)) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            Date startDate = system.today();
            
            List<sked__Tag__c> skedTags = [SELECT Id, Name
                                           FROM sked__Tag__c
                                           WHERE sked__Type__c = :skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE];
            Map<string, sked__Tag__c> mapTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedTag : skedTags) {
                mapTag.put(skedTag.Name, skedTag);
            }
            List<sked__Resource_Tag__c> newResourceTags = new List<sked__Resource_Tag__c>();
            for (sked__Resource__c newRecord : recordsToPopulate) {
                List<string> mobileTypes = newRecord.sked_Mobile_Type__c.split(';');
                for (string mobileType : mobileTypes) {
                    sked__Tag__c skedTag = mapTag.get(mobileType);
                    sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                        sked__Resource__c = newRecord.Id,
                        sked__Tag__c = skedTag.Id,
                        sked_Start_Date__c = startDate,
                        sked_Role_Status__c = 'Active'
                    );
                    newResourceTags.add(newResourceTag);
                }
            }
            insert newResourceTags;
        }
    }

    private void addRealIdTypeTags(List<sked__Resource__c> newRecords) {
        List<sked__Resource__c> recordsToPopulate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            if (newRecord.sked_REAL_ID_Compliant_indicator__c) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            Date startDate = system.today();
            
            List<sked__Tag__c> skedTags = [SELECT Id, Name
                                           FROM sked__Tag__c
                                           WHERE sked__Type__c = :skedConstants.TAG_TYPE_CERTIFICATION];
            Map<string, sked__Tag__c> mapTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedTag : skedTags) {
                mapTag.put(skedTag.Name, skedTag);
            }
            List<sked__Resource_Tag__c> newResourceTags = new List<sked__Resource_Tag__c>();
            for (sked__Resource__c newRecord : recordsToPopulate) {                
                sked__Tag__c skedTag = mapTag.get('REAL ID');
                sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                    sked__Resource__c = newRecord.Id,
                    sked__Tag__c = skedTag.Id,
                    sked_Start_Date__c = startDate,
                    sked_Role_Status__c = 'Active'
                );
                newResourceTags.add(newResourceTag);                
            }
            insert newResourceTags;
        }
    }
    
    private void addEquipmentDriveTypeTags(List<sked__Resource__c> newRecords) {
        List<sked__Resource__c> recordsToPopulate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked_Site_Type__c)) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            Date startDate = system.today();
            
            List<sked__Tag__c> skedTags = [SELECT Id, Name
                                           FROM sked__Tag__c
                                           WHERE sked__Type__c = :skedConstants.TAG_TYPE_DRIVE_TYPE];
            Map<string, sked__Tag__c> mapTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedTag : skedTags) {
                mapTag.put(skedTag.Name, skedTag);
            }
            List<sked__Resource_Tag__c> newResourceTags = new List<sked__Resource_Tag__c>();
            for (sked__Resource__c newRecord : recordsToPopulate) {
                List<string> driveTypes = newRecord.sked_Site_Type__c.split(';');
                for (string driveType : driveTypes) {
                    sked__Tag__c skedTag = mapTag.get(driveType);
                    sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                        sked__Resource__c = newRecord.Id,
                        sked__Tag__c = skedTag.Id,
                        sked_Start_Date__c = startDate,
                        sked_Role_Status__c = 'Active'
                    );
                    newResourceTags.add(newResourceTag);
                }
            }
            insert newResourceTags;
        }
    }
    
    private void addPersonDriveTypeTags(List<sked__Resource__c> newRecords) {
        string fccCodesFixedSite = skedSetting.instance.Admin.fccCodeFixedSite;
        string fccCodesMobile = skedSetting.instance.Admin.fccCodeMobile;
        
        List<sked__Resource__c> recordsToPopulate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked_FCC_Code__c)) {
                if (newRecord.sked_FCC_Code__c != NULL) {
                    recordsToPopulate.add(newRecord);
                }
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            Date startDate = system.today();
            
            List<sked__Tag__c> driveTypeTags = [SELECT Id, Name
                                                FROM sked__Tag__c
                                                WHERE sked__Type__c = :skedConstants.TAG_TYPE_DRIVE_TYPE];
            Map<string, sked__Tag__c> mapDriveTypeTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c driveTypeTag : driveTypeTags) {
                mapDriveTypeTag.put(driveTypeTag.Name, driveTypeTag);
            }
            List<sked__Resource_Tag__c> newResourceTags = new List<sked__Resource_Tag__c>();
            for (sked__Resource__c skedResource : recordsToPopulate) {
                Set<Id> driveTypeTagIds = new Set<Id>();
                List<string> resourceFccCodes = new List<string>();
                if (skedResource.sked_FCC_Code__c != NULL) {
                    resourceFccCodes = skedResource.sked_FCC_Code__c.split(';');
                }
                for (string resourceFccCode : resourceFccCodes) {
                    if (fccCodesFixedSite.contains(resourceFccCode)) {
                        sked__Tag__c driveTypeTag = mapDriveTypeTag.get('Fixed Site');
                        driveTypeTagIds.add(driveTypeTag.Id);
                    }
                    if (fccCodesMobile.contains(resourceFccCode)) {
                        sked__Tag__c driveTypeTag = mapDriveTypeTag.get('Mobile');
                        driveTypeTagIds.add(driveTypeTag.Id);
                    }
                }
                if (!driveTypeTagIds.isEmpty()) {
                    for (Id driveTypeTagId : driveTypeTagIds) {
                        sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                            sked__Resource__c = skedResource.Id,
                            sked__Tag__c = driveTypeTagId,
                            sked_Start_Date__c = startDate,
                            sked_Role_Status__c = 'Active'
                        );
                        newResourceTags.add(newResourceTag);
                    }
                }
            }
            if (!newResourceTags.isEmpty()) {
                insert newResourceTags;
            }
        }
    }
    
    private void assignDefaultPatterns(List<sked__Resource__c> newRecords) {
        List<sked__Availability_Pattern__c> defaultPatterns = [SELECT Id, sked_Default_for_Resource_Type__c
                                                               FROM sked__Availability_Pattern__c
                                                               WHERE sked_Default_for_Resource_Type__c != NULL];
        if (!defaultPatterns.isEmpty()) {
            DateTime startTime = system.now();
            DateTime endTime = startTime.addYears(50);
            
            List<sked__Availability_Pattern_Resource__c> patternResources = new List<sked__Availability_Pattern_Resource__c>();
            for (sked__Resource__c newRecord : newRecords) {
                string resourceType = newRecord.sked__Resource_Type__c;
                if (resourceType == skedConstants.RESOURCE_TYPE_ASSET) {
                    resourceType = newRecord.sked_Asset_Type__c;
                }
                if (!string.isBlank(resourceType)) {
                    for (sked__Availability_Pattern__c defaultPattern : defaultPatterns) {
                        if (defaultPattern.sked_Default_for_Resource_Type__c.contains(resourceType)) {
                            sked__Availability_Pattern_Resource__c patternResource = new sked__Availability_Pattern_Resource__c(
                            	sked__Availability_Pattern__c = defaultPattern.Id,
                                sked__Resource__c = newRecord.Id,
                                sked__Start__c = startTime,
                                sked__End__c = endTime
                            );
                            patternResources.add(patternResource);
                        }
                    }
                }
            }
            if (!patternResources.isEmpty()) {
                insert patternResources;
            }
        }
    }
    
    private void captureFieldChangeExceptionLog(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        Map<string, string> mapTrackingFields = new Map<string, string>();
        mapTrackingFields.put('sked__Home_Address__c', 'Home Address');
        mapTrackingFields.put('sked_Satellite_Address__c', 'Satellite Address');
        mapTrackingFields.put('sked__Employment_Type__c', 'Employment Type');
        mapTrackingFields.put('sked_Employment_Status__c', 'Employment Status');
        mapTrackingFields.put('sked_Union_Affiliation__c', 'Union Code');
        mapTrackingFields.put('sked__Primary_Region__c', 'Primary Region');

        Set<Id> affectedRegions = new Set<Id>();
        for (sked__Resource__c newRecord : newRecords) { 
            sked__Resource__c oldRecord = oldMap.get(newRecord.Id);
            affectedRegions.add(newRecord.sked__Primary_Region__c);
            affectedRegions.add(oldRecord.sked__Primary_Region__c);
        }
        
        Map<Id, sked__Region__c> regionsById = new Map<Id, sked__Region__c>([
            SELECT Id, Name
            FROM sked__Region__c
            WHERE Id IN :affectedRegions
        ]);
        
        string exceptionCodeTemplate = '{{resourceName}} has {{fieldLabel}} changed from {{oldValue}} to {{newValue}}';
        Map<Id, string> mapResourceIdExceptionCode = new Map<Id, string>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            string exceptionCode;
            for (string trackingField : mapTrackingFields.keySet()) {
                string newValue = '';
                if (newRecord.get(trackingField) != NULL) {
                    newValue = string.valueOf(newRecord.get(trackingField));
                }
                string oldValue = '';
                if (oldData.get(trackingField) != NULL) {
                    oldValue = string.valueOf(oldData.get(trackingField));
                }
                if (newValue != oldValue) {
                    if (trackingField == 'sked__Primary_Region__c') {
                        newValue = regionsById.get(newValue).Name;
                        oldValue = regionsById.get(oldValue).Name;
                    }

                    string fieldLabel = mapTrackingFields.get(trackingField);
                    string resourceName = newRecord.Name;
                    exceptionCode = exceptionCodeTemplate.replace('{{resourceName}}', resourceName)
                        .replace('{{fieldLabel}}', fieldLabel)
                        .replace('{{oldValue}}', oldValue)
                        .replace('{{newValue}}', newValue);
                    mapResourceIdExceptionCode.put(newRecord.Id, exceptionCode);
                    break;
                }
            }
        }
        
        List<sked__Job_Allocation__c> impactedAllocations = [SELECT Id, sked__Job__c, sked__Job__r.sked_Drive__c, sked__Resource__c
                                                             FROM sked__Job_Allocation__c
                                                             WHERE sked__Resource__c IN :mapResourceIdExceptionCode.keySet()
                                                             AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c > TODAY
                                                             AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                                             AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                             AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED];
        if (!impactedAllocations.isEmpty()) {
            List<skedHC__Exception__c> newExceptionLog = new List<skedHC__Exception__c>();
            for (sked__Job_Allocation__c impactedAllocation : impactedAllocations) {
                string exceptionMessage = mapResourceIdExceptionCode.get(impactedAllocation.sked__Resource__c);
                skedHC__Exception__c newException = new skedHC__Exception__c(
                    sked_Drive__c = impactedAllocation.sked__Job__r.sked_Drive__c,
                    skedHC__Job__c = impactedAllocation.sked__Job__c,
                    skedHC__Job_Allocation__c = impactedAllocation.Id,
                    skedHC__Resource__c = impactedAllocation.sked__Resource__c,
                    sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_DATA_CHANGED,
                    skedHC__Exception__c = exceptionMessage,
                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                );
                newExceptionLog.add(newException);
            }
            if (!newExceptionLog.isEmpty()) {
                insert newExceptionLog;
            }
        }
    }
    
    private void captureResourceIsInactiveExceptionLog(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
        for (sked__Resource__c newRecord : newRecords) {
            if (newRecord.sked_Timezone__c != null) {
                sked__Resource__c oldData = oldMap.get(newRecord.Id);

                Boolean isOnLeaveChanged = isResourceOnLeaveChanged(newRecord, oldData);
                Boolean isTerminationChanged = isResourceTerminationChanged(newRecord, oldData);
                Boolean isInactiveChanged = newRecord.sked__Is_Active__c != oldData.sked__Is_Active__c;
                if (isInactiveChanged) {
                    unavailabilityList.add(getInactiveUnavailability(newRecord));
                }
                if (isOnLeaveChanged) {
                    unavailabilityList.add(getLeaveUnavailability(newRecord));
                }
                if (isTerminationChanged) {
                    unavailabilityList.add(getTerminationUnavailability(newRecord));
                }

                if (newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_ASSET
                    && newRecord.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE
                    && newRecord.sked_Future_Inactive_Date__c != oldData.sked_Future_Inactive_Date__c) {
                    unavailabilityList.add(getFutureInactiveUnavailability(newRecord));
                }
            }
        }
        if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
            service.captureResourceExceptionLogs(unavailabilityList);
        }
    }

    private skedExceptionLogService.resourceUnavailabilityModel getInactiveUnavailability(sked__Resource__c resource) {
        skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
        unavailability.resourceId = resource.Id;
        unavailability.startTime = resource.sked__Is_Active__c == TRUE ? skedDateTimeUtils.MIN_DATETIME : skedDateTimeUtils.getStartOfDate(System.today(), resource.sked_Timezone__c);
        unavailability.endTime = resource.sked__Is_Active__c == TRUE ? skedDateTimeUtils.MIN_DATETIME : skedDateTimeUtils.MAX_DATETIME;
        unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_IS_INACTIVE;
        return unavailability;
    }

    private skedExceptionLogService.resourceUnavailabilityModel getLeaveUnavailability(sked__Resource__c resource) {
        skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
        unavailability.resourceId = resource.Id;
        if (resource.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE) {
            unavailability.startTime = skedDateTimeUtils.getStartOfDate(System.today(), resource.sked_Timezone__c);
            unavailability.endTime = resource.sked_Anticipated_Leave_Return_Date__c != NULL ? skedDateTimeUtils.getStartOfDate(resource.sked_Anticipated_Leave_Return_Date__c, resource.sked_Timezone__c) : skedDateTimeUtils.MAX_DATETIME;
        } else {
            unavailability.startTime = skedDateTimeUtils.MIN_DATETIME;
            unavailability.endTime = skedDateTimeUtils.MIN_DATETIME;
        }
        unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_IS_INACTIVE;
        return unavailability;
    }

    private skedExceptionLogService.resourceUnavailabilityModel getTerminationUnavailability(sked__Resource__c resource) {
        skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
        unavailability.resourceId = resource.Id;
        Date terminationDate = skedUtils.getMinFromDates(new List<Date>{resource.sked_Planned_Termination_Date__c, resource.sked_Termination_Date__c});
        unavailability.startTime = terminationDate == NULL ? skedDateTimeUtils.MIN_DATETIME : skedDateTimeUtils.getStartOfDate(terminationDate, resource.sked_Timezone__c);
        unavailability.endTime = terminationDate == NULL ? skedDateTimeUtils.MIN_DATETIME : skedDateTimeUtils.MAX_DATETIME;
        unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_PENDING_TERMINATION;
        return unavailability;
    }

    private skedExceptionLogService.resourceUnavailabilityModel getFutureInactiveUnavailability(sked__Resource__c resource) {
        skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
        unavailability.resourceId = resource.Id;
        unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_IS_INACTIVE;
        if (resource.sked_Future_Inactive_Date__c == null) {
            unavailability.startTime = skedDateTimeUtils.MIN_DATETIME;
            unavailability.endTime = skedDateTimeUtils.MIN_DATETIME;
        } else {
            unavailability.startTime = skedDateTimeUtils.getStartOfDate(resource.sked_Future_Inactive_Date__c, resource.sked_Timezone__c);
            unavailability.endTime = skedDateTimeUtils.MAX_DATETIME;
        }
        return unavailability;
    }

    private void captureWorkDaysPerWeekException(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<sked__Resource__c> resourcesNeedToCaptureException = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON && 
                (newRecord.sked_Min_Working_Days_Per_Week__c != oldData.sked_Min_Working_Days_Per_Week__c || 
                 newRecord.sked_Max_Working_Days_Per_Week__c != oldData.sked_Max_Working_Days_Per_Week__c)
            ) {
                resourcesNeedToCaptureException.add(newRecord);
            }
        }

        if (resourcesNeedToCaptureException.size() > 0) {
            List<Id> resourceHoursRecordIdsToCheck = new List<Id>();
            for (sked_Resource_Hours_Record__c resourceHoursRecord : [
                SELECT Id
                FROM sked_Resource_Hours_Record__c
                WHERE sked_Resource__c IN :resourcesNeedToCaptureException
                AND sked_End_Date__c > TODAY
            ]) {
                resourceHoursRecordIdsToCheck.add(resourceHoursRecord.Id);
            }

            if (resourceHoursRecordIdsToCheck.size() > 0) {
                skedResourceHoursRecordUtils.captureWorkDaysException(resourceHoursRecordIdsToCheck);
            }
        }
    }

    private Boolean isResourceTerminationChanged(sked__Resource__c newRecord, sked__Resource__c oldData) {
        return (oldData.sked_Planned_Termination_Date__c != newRecord.sked_Planned_Termination_Date__c) ||
               (oldData.sked_Termination_Date__c != newRecord.sked_Termination_Date__c);
    }

    private Boolean isResourceOnLeaveChanged(sked__Resource__c newRecord, sked__Resource__c oldData) {
        return (newRecord.sked_Employment_Status__c != oldData.sked_Employment_Status__c && 
               (newRecord.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE || 
               oldData.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE)) || 
               newRecord.sked_Anticipated_Leave_Return_Date__c != oldData.sked_Anticipated_Leave_Return_Date__c;
    }

    private Boolean isResourceTerminatedOrLeave(sked__Resource__c resource) {
        return resource.sked_Planned_Termination_Date__c != NULL
               || resource.sked_Termination_Date__c != NULL;
               //|| resource.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE;
    }

    private Boolean isResourceTerminatedLeaveDataChanged(sked__Resource__c newRecord, sked__Resource__c oldRecord) {
        return newRecord.sked_Planned_Termination_Date__c != oldRecord.sked_Planned_Termination_Date__c
               || newRecord.sked_Termination_Date__c != oldRecord.sked_Termination_Date__c;
               //|| newRecord.sked_Anticipated_Leave_Return_Date__c != oldRecord.sked_Anticipated_Leave_Return_Date__c;
    }
    
    private void cancelTimeOffOnResourceTerminationOrLeave(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<Id> resourceIdsNeedCancellingTimeOff = new List<Id>();
        for (sked__Resource__c newRecord : newRecords) {
            if (newRecord.sked_Timezone__c != null && newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON) {
                sked__Resource__c oldData = oldMap.get(newRecord.Id);
                if (isResourceTerminatedOrLeave(newRecord) && isResourceTerminatedLeaveDataChanged(newRecord, oldData)) {
                    resourceIdsNeedCancellingTimeOff.add(newRecord.Id);
                }
            }
        }

        if (resourceIdsNeedCancellingTimeOff.size() > 0) {
            cancelTimeOffForResourceOnLeaveOrTerminated(resourceIdsNeedCancellingTimeOff);
        }
    }

    public void cancelTimeOffForResourceOnLeaveOrTerminated(List<Id> resourceIdsOnLeaveOrTerminated) {
        Map<Id, List<periodModel>> map_resource_timeOffCancellingPeriods = new Map<Id, List<periodModel>>();
        for (sked__Resource__c resource : [
            SELECT Id, sked_Planned_Termination_Date__c, sked_Termination_Date__c,
                    sked_Anticipated_Leave_Return_Date__c, sked_Timezone__c, sked_Employment_Status__C
            FROM sked__Resource__c
            WHERE Id IN :resourceIdsOnLeaveOrTerminated
        ]) {
            List<periodModel> timeOffCancellingPeriods = getTimeOffCancellingPeriodsForResource(resource);
            map_resource_timeOffCancellingPeriods.put(resource.Id, timeOffCancellingPeriods);
        }

        periodModel minMaxTimeOffCancellingPeriod = findMinMaxTimeOffCancellingPeriod(map_resource_timeOffCancellingPeriods);
        if (minMaxTimeOffCancellingPeriod != null) {
            List<sked__Availability__c> timeOffsNeedCancelling = getTimeOffsOverlappingWithResourceLeaveOrTerminatedPeriod(map_resource_timeOffCancellingPeriods, minMaxTimeOffCancellingPeriod);
            if (timeOffsNeedCancelling.size() > 0) {
                skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
                update timeOffsNeedCancelling;
                skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = false;
            }
        }
    }

    private List<periodModel> getTimeOffCancellingPeriodsForResource(sked__Resource__c resource) {
        List<periodModel> timeOffCancellingPeriods = new List<periodModel>();
        Date terminationDate = skedUtils.getMinFromDates(new List<Date>{resource.sked_Planned_Termination_Date__c, resource.sked_Termination_Date__c});
        Datetime currentResourceDateTime = skedDateTimeUtils.getStartOfDate(Datetime.now(), resource.sked_Timezone__c);
        timeOffCancellingPeriods.add(new periodModel(skedDateTimeUtils.getStartOfDate(terminationDate, resource.sked_Timezone__c), skedDateTimeUtils.MAX_DATETIME));

        // if (resource.sked_Anticipated_Leave_Return_Date__c != null && terminationDate != null) {
        //     if (resource.sked_Anticipated_Leave_Return_Date__c >= terminationDate) {
        //         timeOffCancellingPeriods.add(new periodModel(currentResourceDateTime, skedDateTimeUtils.MAX_DATETIME));
        //     } else {
        //         timeOffCancellingPeriods.add(new periodModel(currentResourceDateTime, skedDateTimeUtils.getEndOfDate(resource.sked_Anticipated_Leave_Return_Date__c.addDays(-1), resource.sked_Timezone__c)));
        //         timeOffCancellingPeriods.add(new periodModel(skedDateTimeUtils.getStartOfDate(terminationDate, resource.sked_Timezone__c), skedDateTimeUtils.MAX_DATETIME));
        //     }
        // } else if (resource.sked_Anticipated_Leave_Return_Date__c != null) {
        //     timeOffCancellingPeriods.add(new periodModel(currentResourceDateTime, skedDateTimeUtils.getEndOfDate(resource.sked_Anticipated_Leave_Return_Date__c.addDays(-1), resource.sked_Timezone__c)));
        // } else if (terminationDate != null) {
        //     timeOffCancellingPeriods.add(new periodModel(skedDateTimeUtils.getStartOfDate(terminationDate, resource.sked_Timezone__c), skedDateTimeUtils.MAX_DATETIME));
        // } else if (resource.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE) {
        //     timeOffCancellingPeriods.add(new periodModel(currentResourceDateTime, skedDateTimeUtils.MAX_DATETIME));
        // }

        return timeOffCancellingPeriods;
    }

    private periodModel findMinMaxTimeOffCancellingPeriod(Map<Id, List<periodModel>> map_resource_timeOffCancellingPeriods) {
        Datetime minTimeOffCancellingStart;
        Datetime maxTimeOffCancellingEnd;
        for (List<periodModel> timeOffCancellingPeriods : map_resource_timeOffCancellingPeriods.values()) {
            for (periodModel timeOffCencellingPeriod : timeOffCancellingPeriods) {
                Datetime timeOffCancellingStart = timeOffCencellingPeriod.start;
                Datetime timeOffCancellingEnd = timeOffCencellingPeriod.finish;
                if (minTimeOffCancellingStart == null || timeOffCancellingStart < minTimeOffCancellingStart) {
                    minTimeOffCancellingStart = timeOffCancellingStart;
                }
                if (maxTimeOffCancellingEnd == null || timeOffCancellingEnd > maxTimeOffCancellingEnd) {
                    maxTimeOffCancellingEnd = timeOffCancellingEnd;
                }
            }
        }

        return minTimeOffCancellingStart == null && maxTimeOffCancellingEnd == null ? null : new periodModel(minTimeOffCancellingStart, maxTimeOffCancellingEnd);
    }

    private List<sked__Availability__c> getTimeOffsOverlappingWithResourceLeaveOrTerminatedPeriod(
        Map<Id, List<periodModel>> map_resource_timeOffCancellingPeriods,
        periodModel minMaxTimeOffCancellingPeriod
    ) {
        List<sked__Availability__c> timeOffsNeedCancelling = new List<sked__Availability__c>();
        Datetime minTimeOffCancellingStart = minMaxTimeOffCancellingPeriod.start;
        Datetime maxTimeOffCancellingEnd = minMaxTimeOffCancellingPeriod.finish;
        List<String> availabilityIncludedTypes = new List<String>{skedConstants.AVAILABILITY_TYPE_PTO, skedConstants.AVAILABILITY_TYPE_FLOATING_HOLIDAY};
        for (sked__Availability__c unavailability : [
            SELECT Id, sked__Start__c, sked__Finish__c, sked__Resource__c
            FROM sked__Availability__c
            WHERE sked__Status__c != :skedConstants.AVAILABILITY_STATUS_DECLINED
            AND sked__Start__c <= :maxTimeOffCancellingEnd
            AND sked__Finish__c >= :minTimeOffCancellingStart
            AND sked__Type__c IN :availabilityIncludedTypes
            AND sked__Resource__c IN :map_resource_timeOffCancellingPeriods.keySet()
        ]) {
            List<periodModel> timeOffCancellingPeriods = map_resource_timeOffCancellingPeriods.get(unavailability.sked__Resource__c);
            if (timeOffCancellingPeriods != null) {
                for (periodModel timeOffCancellingPeriod : timeOffCancellingPeriods) {
                    Datetime timeOffCancellingStart = timeOffCancellingPeriod.start;
                    Datetime timeOffCancellingEnd = timeOffCancellingPeriod.finish;
                    if (unavailability.sked__Start__c >= timeOffCancellingStart && unavailability.sked__Finish__c <= timeOffCancellingEnd) {
                        unavailability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_CANCELLED;
                        timeOffsNeedCancelling.add(unavailability);
                        break;
                    }
                }
            }
        }

        return timeOffsNeedCancelling;
    }

    private void populateData(List<sked__Resource__c> newRecords) {
        List<sked__Resource__c> resourceTimezonesToSet = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            if (string.isBlank(newRecord.Name)) {
                if (newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON) {
                    newRecord.Name = '';
                    string firstName = !string.isBlank(newRecord.sked_Preferred_First_Name__c) 
                        ? newRecord.sked_Preferred_First_Name__c : newRecord.sked_First_Name__c;
                    if (!string.isBlank(firstName) || !string.isBlank(newRecord.sked_Last_Name__c)) {
                        newRecord.Name = firstName + ' ' + newRecord.sked_Last_Name__c;
                    }
                    if (!string.isBlank(newRecord.sked_Employee_ID__c)) {
                        newRecord.Name = newRecord.Name + ' ' + newRecord.sked_Employee_ID__c;
                    }
                }
                else {
                    newRecord.Name = newRecord.sked_Long_Desc__c;
                }
            }

            if (newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON) {
                if (newRecord.sked_Mobile_Type__c == NULL) {
                    newRecord.sked_Mobile_Type__c = 'Inside;Outside';
                }
                if (newRecord.sked_Max_Hours_Per_Week__c == NULL) {
                    newRecord.sked_Max_Hours_Per_Week__c = 40;
                }
                newRecord.CO_AP_Status__c = skedConstants.CO_AP_STATUS_YET_TO_PROCESS_CO;
            }
            else if (newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_ASSET) {
                if (newRecord.sked_Site_Type__c == NULL) {
                    newRecord.sked_Site_Type__c = 'Fixed Site;Mobile';
                }
                newRecord.sked_Turnaround_Time__c = 0;
                if (newRecord.sked__Primary_Region__c != null) {
                    resourceTimezonesToSet.add(newRecord);
                }
            }
        }

        if (!resourceTimezonesToSet.isEmpty()) {
            populateTimezones(resourceTimezonesToSet);
        }
    }
    
    private void populateData(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<sked__Resource__c> resourceTimezonesToUpdate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON) {
                newRecord.Name = '';
                string firstName = !string.isBlank(newRecord.sked_Preferred_First_Name__c) 
                        ? newRecord.sked_Preferred_First_Name__c : newRecord.sked_First_Name__c;
                if (!string.isBlank(firstName) || !string.isBlank(newRecord.sked_Last_Name__c)) {
                    newRecord.Name = firstName + ' ' + newRecord.sked_Last_Name__c;
                }
                if (!string.isBlank(newRecord.sked_Employee_ID__c)) {
                    newRecord.Name = newRecord.Name + ' ' + newRecord.sked_Employee_ID__c;
                }
                if (newRecord.sked_Max_Hours_Per_Week__c != oldData.sked_Max_Hours_Per_Week__c && newRecord.sked_Max_Hours_Per_Week__c == NULL) {
                    newRecord.sked_Max_Hours_Per_Week__c = 40;
                }
                if(newRecord.sked__Primary_Region__c != oldData.sked__Primary_Region__c) {
                    newRecord.CO_AP_Status__c = skedConstants.CO_AP_STATUS_YET_TO_PROCESS_CO;
                }
            }
            else if (newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_ASSET) {
                if (newRecord.sked__Primary_Region__c != oldData.sked__Primary_Region__c) {
                    resourceTimezonesToUpdate.add(newRecord);
                }
            }
        }

        if (!resourceTimezonesToUpdate.isEmpty()) {
            populateTimezones(resourceTimezonesToUpdate);
        }
    }
    
    private void populateSupervisor(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<sked__Resource__c> recordsToPopulate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Supervisor_Email__c != oldData.sked_Supervisor_Email__c) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            populateSupervisor(recordsToPopulate);
        }
    }
    
    private void populateSupervisor(List<sked__Resource__c> newRecords) {
        Set<string> supervisorEmails = new Set<string>();
        for (sked__Resource__c newRecord : newRecords) {
            newRecord.sked_Supervisor__c = null;
            if (newRecord.sked_Supervisor_Email__c != null) {
                supervisorEmails.add(newRecord.sked_Supervisor_Email__c);
            }
        }
        if (!supervisorEmails.isEmpty()) {
            List<User> supervisorUsers = [SELECT Id, Email
                                          FROM User
                                          WHERE Email IN :supervisorEmails];
            Map<string, User> map_Email_User = new Map<string, User>();
            for (User supervisorUser : supervisorUsers) {
                map_Email_User.put(supervisorUser.Email, supervisorUser);
            }
            for (sked__Resource__c newRecord : newRecords) {
                if (map_Email_User.containsKey(newRecord.sked_Supervisor_Email__c)) {
                    User supervisorUser = map_Email_User.get(newRecord.sked_Supervisor_Email__c);
                    newRecord.sked_Supervisor__c = supervisorUser.Id;
                }
            }
        }
    }
    
    private void populateResourceActivation(List<sked__Resource__c> newRecords) {
        for (sked__Resource__c newRecord : newRecords) {
            newRecord.sked__Is_Active__c = newRecord.sked_Employment_Status__c != 'Inactive';
        }
    }
    
    private void populateResourceActivation(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Employment_Status__c != oldData.sked_Employment_Status__c) {
                newRecord.sked__Is_Active__c = newRecord.sked_Employment_Status__c != 'Inactive';
            }
        }
    }
    
    private void populateGeoLocation(List<sked__Resource__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Resource__c newRecord : newRecords) {
            resourceIds.add(newRecord.Id);
        }
        if (!System.isBatch() && !Test.isRunningTest()) {
            Database.executeBatch(new skedResourceGeoLocationBatch(resourceIds), 20);
        }
    }
    
    private void populateGeoLocation(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<string> fieldsToCheck = new List<string>();
        fieldsToCheck.add('sked_Home_Address_1__c');
        fieldsToCheck.add('sked_Home_Address_2__c');
        fieldsToCheck.add('sked_Home_City__c');
        fieldsToCheck.add('sked_Home_State__c');
        fieldsToCheck.add('sked_Home_Zip_Code__c');
        fieldsToCheck.add('sked_Work_Address_1__c');
        fieldsToCheck.add('sked_Work_Address_2__c');
        fieldsToCheck.add('sked_Work_City__c');
        fieldsToCheck.add('sked_Work_State__c');
        fieldsToCheck.add('sked_Work_Zip_Code__c');
        
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            for (string field : fieldsToCheck) {
                object oldValue = oldData.get(field);
                object newValue = newRecord.get(field);
                if (newValue != oldValue) {
                    resourceIds.add(newRecord.Id);
                    break;
                }
            }
        }
        if (!resourceIds.isEmpty()) {
            if (!System.isBatch() && !Test.isRunningTest()) {
                Database.executeBatch(new skedResourceGeoLocationBatch(resourceIds), 20);
            }
        }
    }
    
    private void populateTaxonomyData(List<sked__Resource__c> newRecords) {
        Set<string> zipcodes = new Set<string>();
        for (sked__Resource__c newRecord : newRecords) {
            if (newRecord.sked_Work_Zip_Code__c != NULL) {
                zipcodes.add(newRecord.sked_Work_Zip_Code__c);
            }
            if(newRecord.sked_Work_Zip_Code__c == NULL && newRecord.sked_Satellite_Zip_Code__c != NULL) {
                zipcodes.add(newRecord.sked_Satellite_Zip_Code__c);
            }
        }
        
        List<Taxonomy__c> taxonomyRecords = [SELECT Id, Collection_Operation_Name__c,Collection_Operation_Code__c, Zip_Code__c, Time_Zone__c 
            FROM Taxonomy__c
            WHERE Zip_Code__c IN :zipcodes
            AND Start_Date__c <= TODAY
            AND End_Date__c >= TODAY
                                             AND Time_Zone__c != NULL];
        Set<String> collectionOpCodes = new Set<String>();
        Map<string, Taxonomy__c> taxonomyByZipcode = new Map<string, Taxonomy__c>();
        for (Taxonomy__c taxonomy : taxonomyRecords) {
         	collectionOpCodes.add('Bio_Collection_BSF_'+taxonomy.Collection_Operation_Code__c);
            taxonomyByZipcode.put(taxonomy.Zip_Code__c, taxonomy);
        }
        
        List<sked__Region__c> skedRegions = [SELECT Id, sked_Biomed_Collection_Op_Center__r.Name,sked_Biomed_Collection_Op_Center__r.External_Id__c, sked__Timezone__c
            FROM sked__Region__c
                                             WHERE sked_Biomed_Collection_Op_Center__r.External_Id__c IN :collectionOpCodes];
        Map<string, sked__Region__c> mapRegion = new Map<string, sked__Region__c>();
        for (sked__Region__c region : skedRegions) {
            string key = region.sked_Biomed_Collection_Op_Center__r.External_Id__c + ':' + region.sked__Timezone__c;
            mapRegion.put(key, region);
        }
        
        for (sked__Resource__c newRecord : newRecords) {
         	string resourceZipcode = newRecord.sked_Work_Zip_Code__c != NULL ? newRecord.sked_Work_Zip_Code__c : newRecord.sked_Satellite_Zip_Code__c;
            if (!string.isBlank(resourceZipcode)) {
                if (taxonomyByZipcode.containsKey(resourceZipcode)) {
                    Taxonomy__c taxonomy = taxonomyByZipcode.get(resourceZipcode);
                    newRecord.sked_Timezone__c = taxonomy.Time_Zone__c;
                            
                    string regionKey = 'Bio_Collection_BSF_' + taxonomy.Collection_Operation_Code__c + ':' + taxonomy.Time_Zone__c;
                    if (mapRegion.containsKey(regionKey)) {
                        sked__Region__c skedRegion = mapRegion.get(regionKey);
                        newRecord.sked__Primary_Region__c = skedRegion.Id;
                    }
                }
            }
        }
    }
    
    private void populateTaxonomyData(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<sked__Resource__c> recordsToPopulate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Work_Zip_Code__c != oldData.sked_Work_Zip_Code__c || newRecord.sked_Satellite_Zip_Code__c != oldData.sked_Satellite_Zip_Code__c ) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            populateTaxonomyData(recordsToPopulate);
        }
    }

    private void populateTimezones(List<sked__Resource__c> resources) {
        Set<Id> regionIds = new Set<Id>();
        for (sked__Resource__c res : resources) {
            regionIds.add(res.sked__Primary_Region__c);
        }

        Map<Id, sked__Region__c> regionById = new Map<Id, sked__Region__c>([
            SELECT Id, sked__Timezone__c
            FROM sked__Region__c
            WHERE Id IN :regionIds
        ]);

        for (sked__Resource__c resource : resources) {
            sked__Region__c primaryRegion = regionById.get(resource.sked__Primary_Region__c);
            if (primaryRegion != null) {
                resource.sked_Timezone__c = primaryRegion.sked__Timezone__c;
            }
        }
    }
    
    private void onUpsertResourceRoles(List<sked__Resource__c> newRecords) {
        for (sked__Resource__c newRecord : newRecords) {
            if (newRecord.sked_Roles__c != NULL && !skedResourceHandler.canUpdateResourceRole) {
                newRecord.addError('User Resource Tag to maintain roles.');
            }
        }
    }
    
    private void onUpsertResourceRoles(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Roles__c != oldData.sked_Roles__c && !skedResourceHandler.canUpdateResourceRole) {
                newRecord.addError('User Resource Tag to maintain roles.');
            }
        }
    }
    
    private void updateAddress(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<string> fieldsToCheck = new List<string>();
        fieldsToCheck.add('sked_Address_Referenced_for_Scheduling__c');
        fieldsToCheck.add('sked_Home_Address_1__c');
        fieldsToCheck.add('sked_Home_Address_2__c');
        fieldsToCheck.add('sked_Home_Address_3__c');
        fieldsToCheck.add('sked_Home_City__c');
        fieldsToCheck.add('sked_Home_State__c');
        fieldsToCheck.add('sked_Home_Zip_Code__c');
        fieldsToCheck.add('sked_Home_Country__c');
        fieldsToCheck.add('sked_Home_Address_GeoLocation__Latitude__s');
        fieldsToCheck.add('sked_Home_Address_GeoLocation__Longitude__s');
        fieldsToCheck.add('sked_Work_Address_1__c');
        fieldsToCheck.add('sked_Work_Address_2__c');
        fieldsToCheck.add('sked_Work_Address_3__c');
        fieldsToCheck.add('sked_Work_City__c');
        fieldsToCheck.add('sked_Work_State__c');
        fieldsToCheck.add('sked_Work_Zip_Code__c');
        fieldsToCheck.add('sked_Work_Country__c');
        fieldsToCheck.add('sked_Work_Address_GeoLocation__Latitude__s');
        fieldsToCheck.add('sked_Work_Address_GeoLocation__Longitude__s');
        fieldsToCheck.add('sked_Satellite_Address__c');
        fieldsToCheck.add('sked_Satellite_Address_GeoLocation__Latitude__s');
        fieldsToCheck.add('sked_Satellite_Address_GeoLocation__Longitude__s');
        
        List<sked__Resource__c> resourcesToUpdate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            for (string field : fieldsToCheck) {
                object oldValue = oldData.get(field);
                object newValue = newRecord.get(field);
                if (newValue != oldValue) {
                    resourcesToUpdate.add(newRecord);
                    break;
                }
            }
        }
        if (!resourcesToUpdate.isEmpty()) {
            updateAddress(resourcesToUpdate);
        }
    }
    
    private void updateAddress(List<sked__Resource__c> resources) {
        for (sked__Resource__c resource : resources) {
            if (resource.sked_Address_Referenced_for_Scheduling__c == skedConstants.ADDRESS_REFERECENED_FOR_SCHEDULING_HOME) {
                resource.sked__Home_Address__c = skedUtils.combineAddress(resource.sked_Home_Address_1__c,
                                                                         resource.sked_Home_Address_2__c,
                                                                         resource.sked_Home_Address_3__c,
                                                                         resource.sked_Home_City__c,
                                                                         resource.sked_Home_State__c,
                                                                         resource.sked_Home_Zip_Code__c,
                                                                         resource.sked_Home_Country__c);
                resource.sked__GeoLocation__Latitude__s = resource.sked_Home_Address_GeoLocation__Latitude__s;
                resource.sked__GeoLocation__Longitude__s = resource.sked_Home_Address_GeoLocation__Longitude__s;
            }
            else if (resource.sked_Address_Referenced_for_Scheduling__c == skedConstants.ADDRESS_REFERECENED_FOR_SCHEDULING_WORK) {
                resource.sked__Home_Address__c = skedUtils.combineAddress(resource.sked_Work_Address_1__c,
                                                                         resource.sked_Work_Address_2__c,
                                                                         resource.sked_Work_Address_3__c,
                                                                         resource.sked_Work_City__c,
                                                                         resource.sked_Work_State__c,
                                                                         resource.sked_Work_Zip_Code__c,
                                                                         resource.sked_Work_Country__c);
                resource.sked__GeoLocation__Latitude__s = resource.sked_Work_Address_GeoLocation__Latitude__s;
                resource.sked__GeoLocation__Longitude__s = resource.sked_Work_Address_GeoLocation__Longitude__s;
            }
            else if (resource.sked_Address_Referenced_for_Scheduling__c == skedConstants.ADDRESS_REFERECENED_FOR_SCHEDULING_SATELLITE) {
                resource.sked__Home_Address__c = resource.sked_Satellite_Address__c;
                resource.sked__GeoLocation__Latitude__s = resource.sked_Satellite_Address_GeoLocation__Latitude__s;
                resource.sked__GeoLocation__Longitude__s = resource.sked_Satellite_Address_GeoLocation__Longitude__s;
            }
        }
    }
    
    private void updatePrimaryPhone(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<string> fieldsToCheck = new List<string>();
        fieldsToCheck.add('sked_Primary_Phone_Type__c');
        fieldsToCheck.add('sked__Mobile_Phone__c');
        fieldsToCheck.add('sked_Home_Phone__c');
        fieldsToCheck.add('sked_Work_Phone__c');
        
        List<sked__Resource__c> resourcesToUpdate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            for (string field : fieldsToCheck) {
                object oldValue = oldData.get(field);
                object newValue = newRecord.get(field);
                if (newValue != oldValue) {
                    resourcesToUpdate.add(newRecord);
                    break;
                }
            }
        }
        if (!resourcesToUpdate.isEmpty()) {
            updatePrimaryPhone(resourcesToUpdate);
        }
    }
    
    private void updatePrimaryPhone(List<sked__Resource__c> resources) {
        for (sked__Resource__c resource : resources) {
            if (resource.sked_Primary_Phone_Type__c == 'Home Phone') {
                resource.sked__Primary_Phone__c = resource.sked_Home_Phone__c;
            }
            else if (resource.sked_Primary_Phone_Type__c == 'Work Phone') {
                resource.sked__Primary_Phone__c = resource.sked_Work_Phone__c;
            }
            else if (resource.sked_Primary_Phone_Type__c == 'Mobile Phone') {
                resource.sked__Primary_Phone__c = resource.sked__Mobile_Phone__c;
            }
        }
    }
    
    private void updateEquipmentDriveTypeTags(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        Set<Id> recordIdsToUpdate = new Set<Id>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Site_Type__c != oldData.sked_Site_Type__c) {
                recordIdsToUpdate.add(newRecord.Id);
            }
        }
        if (!recordIdsToUpdate.isEmpty()) {
            Date startDate = system.today();
            
            List<sked__Resource__c> skedResources = [SELECT Id, sked_Site_Type__c,
                                                     (SELECT Id, sked__Tag__r.Name
                                                      FROM sked__ResourceTags__r
                                                      WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_DRIVE_TYPE)
                                                     FROM sked__Resource__c
                                                     WHERE Id IN :recordIdsToUpdate];
            List<sked__Resource_Tag__c> recordsToDelete = new List<sked__Resource_Tag__c>();
            List<sked__Resource_Tag__c> recordsToInsert = new List<sked__Resource_Tag__c>();
            
            List<sked__Tag__c> skedTags = [SELECT Id, Name
                                           FROM sked__Tag__c
                                           WHERE sked__Type__c = :skedConstants.TAG_TYPE_DRIVE_TYPE];
            Map<string, sked__Tag__c> mapTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedTag : skedTags) {
                mapTag.put(skedTag.Name, skedTag);
            }
            
            for (sked__Resource__c skedResource : skedResources) {
                if (skedResource.sked_Site_Type__c == NULL) {
                    if (skedResource.sked__ResourceTags__r != NULL) {
                        recordsToDelete.addAll(skedResource.sked__ResourceTags__r);
                    }
                }
                else {
                    List<string> driveTypes = skedResource.sked_Site_Type__c.split(';');
                    Set<string> requiredTagNames = new Set<string>();
                    requiredTagNames.addAll(driveTypes);
                    
                    Set<string> existingTagNames = new Set<string>();
                    for (sked__Resource_Tag__c resourceTag : skedResource.sked__ResourceTags__r) {
                        if (!requiredTagNames.contains(resourceTag.sked__Tag__r.Name)) {
                            recordsToDelete.add(resourceTag);
                        }
                        else {
                            existingTagNames.add(resourceTag.sked__Tag__r.Name);
                        }
                    }
                    
                    for (string requiredTagName : requiredTagNames) {
                        if (!existingTagNames.contains(requiredTagName)) {
                            sked__Tag__c skedTag = mapTag.get(requiredTagName);
                            sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                                sked__Resource__c = skedResource.Id,
                                sked__Tag__c = skedTag.Id,
                                sked_Start_Date__c = startDate,
                                sked_Role_Status__c = 'Active'
                            );
                            recordsToInsert.add(newResourceTag);
                        }
                    }
                }
            }
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
        }
    }
    
    private void updatePersonDriveTypeTags(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        string fccCodesFixedSite = skedSetting.instance.Admin.fccCodeFixedSite;
        string fccCodesMobile = skedSetting.instance.Admin.fccCodeMobile;
        
        Set<Id> recordIdsToUpdate = new Set<Id>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_FCC_Code__c != oldData.sked_FCC_Code__c) {
                recordIdsToUpdate.add(newRecord.Id);
            }
        }
        if (!recordIdsToUpdate.isEmpty()) {
            Date startDate = system.today();
            
            List<sked__Resource__c> skedResources = [SELECT Id, sked_FCC_Code__c,
                                                     (SELECT Id, sked__Tag__c
                                                      FROM sked__ResourceTags__r
                                                      WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_DRIVE_TYPE)
                                                     FROM sked__Resource__c
                                                     WHERE Id IN :recordIdsToUpdate];
            List<sked__Resource_Tag__c> recordsToDelete = new List<sked__Resource_Tag__c>();
            List<sked__Resource_Tag__c> recordsToInsert = new List<sked__Resource_Tag__c>();
            
            List<sked__Tag__c> driveTypeTags = [SELECT Id, Name
                                                FROM sked__Tag__c
                                                WHERE sked__Type__c = :skedConstants.TAG_TYPE_DRIVE_TYPE];
            Map<string, sked__Tag__c> mapDriveTypeTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c driveTypeTag : driveTypeTags) {
                mapDriveTypeTag.put(driveTypeTag.Name, driveTypeTag);
            }
            
            for (sked__Resource__c skedResource : skedResources) {
                Set<Id> driveTypeTagIds = new Set<Id>();
                List<string> resourceFccCodes = new List<string>();
                if (skedResource.sked_FCC_Code__c != NULL) {
                    resourceFccCodes = skedResource.sked_FCC_Code__c.split(';');
                }
                for (string resourceFccCode : resourceFccCodes) {
                    if (fccCodesFixedSite.contains(resourceFccCode)) {
                        sked__Tag__c driveTypeTag = mapDriveTypeTag.get('Fixed Site');
                        driveTypeTagIds.add(driveTypeTag.Id);
                    }
                    if (fccCodesMobile.contains(resourceFccCode)) {
                        sked__Tag__c driveTypeTag = mapDriveTypeTag.get('Mobile');
                        driveTypeTagIds.add(driveTypeTag.Id);
                    }
                }
                if (driveTypeTagIds.isEmpty()) {
                    if (skedResource.sked__ResourceTags__r != NULL) {
                        recordsToDelete.addAll(skedResource.sked__ResourceTags__r);
                    }
                }
                else {
                    Set<Id> existingDriveTypeTagIds = new Set<Id>();
                    for (sked__Resource_Tag__c resourceTag : skedResource.sked__ResourceTags__r) {
                        if (!driveTypeTagIds.contains(resourceTag.sked__Tag__c)) {
                            recordsToDelete.add(resourceTag);
                        }
                        existingDriveTypeTagIds.add(resourceTag.sked__Tag__c);
                    }
                    for (Id driveTypeTagId : driveTypeTagIds) {
                        if (!existingDriveTypeTagIds.contains(driveTypeTagId)) {
                            sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                                sked__Resource__c = skedResource.Id,
                                sked__Tag__c = driveTypeTagId,
                                sked_Start_Date__c = startDate,
                                sked_Role_Status__c = 'Active'
                            );
                            recordsToInsert.add(newResourceTag);
                        }
                    }
                }
            }
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
        }
    }
    
    private void updateMobileTypeTags(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        Set<Id> recordIdsToUpdate = new Set<Id>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Mobile_Type__c != oldData.sked_Mobile_Type__c) {
                recordIdsToUpdate.add(newRecord.Id);
            }
        }
        if (!recordIdsToUpdate.isEmpty()) {
            Date startDate = system.today();
            
            List<sked__Resource__c> skedResources = [SELECT Id, sked_Mobile_Type__c,
                                                     (SELECT Id, sked__Tag__r.Name
                                                      FROM sked__ResourceTags__r
                                                      WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE)
                                                     FROM sked__Resource__c
                                                     WHERE Id IN :recordIdsToUpdate];
            List<sked__Resource_Tag__c> recordsToDelete = new List<sked__Resource_Tag__c>();
            List<sked__Resource_Tag__c> recordsToInsert = new List<sked__Resource_Tag__c>();
            
            List<sked__Tag__c> skedTags = [SELECT Id, Name
                                           FROM sked__Tag__c
                                           WHERE sked__Type__c = :skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE];
            Map<string, sked__Tag__c> mapTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedTag : skedTags) {
                mapTag.put(skedTag.Name, skedTag);
            }
            
            for (sked__Resource__c skedResource : skedResources) {
                if (skedResource.sked_Mobile_Type__c == NULL) {
                    if (skedResource.sked__ResourceTags__r != NULL) {
                        recordsToDelete.addAll(skedResource.sked__ResourceTags__r);
                    }
                }
                else {
                    List<string> physicalLocationTypes = skedResource.sked_Mobile_Type__c.split(';');
                    Set<string> requiredTagNames = new Set<string>();
                    requiredTagNames.addAll(physicalLocationTypes);
                    
                    Set<string> existingTagNames = new Set<string>();
                    for (sked__Resource_Tag__c resourceTag : skedResource.sked__ResourceTags__r) {
                        if (!requiredTagNames.contains(resourceTag.sked__Tag__r.Name)) {
                            recordsToDelete.add(resourceTag);
                        }
                        else {
                            existingTagNames.add(resourceTag.sked__Tag__r.Name);
                        }
                    }
                    
                    for (string requiredTagName : requiredTagNames) {
                        if (!existingTagNames.contains(requiredTagName)) {
                            sked__Tag__c skedTag = mapTag.get(requiredTagName);
                            sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                                sked__Resource__c = skedResource.Id,
                                sked__Tag__c = skedTag.Id,
                                sked_Start_Date__c = startDate,
                                sked_Role_Status__c = 'Active'
                            );
                            recordsToInsert.add(newResourceTag);
                        }
                    }
                }
            }
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
        }
    }

    private void updateRealIdTypeTags(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        Set<Id> recordIdsToUpdate = new Set<Id>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_REAL_ID_Compliant_indicator__c != oldData.sked_REAL_ID_Compliant_indicator__c) {
                recordIdsToUpdate.add(newRecord.Id);
            }
        }
        if (!recordIdsToUpdate.isEmpty()) {
            Date startDate = system.today();
            
            List<sked__Resource__c> skedResources = [SELECT Id, sked_REAL_ID_Compliant_indicator__c,
                                                     (SELECT Id, sked__Tag__r.Name
                                                      FROM sked__ResourceTags__r
                                                      WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_CERTIFICATION
                                                      AND sked__Tag__r.Name = 'REAL ID')
                                                     FROM sked__Resource__c
                                                     WHERE Id IN :recordIdsToUpdate];
            List<sked__Resource_Tag__c> recordsToDelete = new List<sked__Resource_Tag__c>();
            List<sked__Resource_Tag__c> recordsToInsert = new List<sked__Resource_Tag__c>();
            
            List<sked__Tag__c> skedTags = [SELECT Id, Name
                                           FROM sked__Tag__c
                                           WHERE sked__Type__c = :skedConstants.TAG_TYPE_CERTIFICATION];
            Map<string, sked__Tag__c> mapTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedTag : skedTags) {
                mapTag.put(skedTag.Name, skedTag);
            }
            
            for (sked__Resource__c skedResource : skedResources) {
                if (!skedResource.sked_REAL_ID_Compliant_indicator__c) {
                    if (skedResource.sked__ResourceTags__r != NULL) {
                        recordsToDelete.addAll(skedResource.sked__ResourceTags__r);
                    }
                }
                else {
                    sked__Tag__c skedTag = mapTag.get('REAL ID');
                    sked__Resource_Tag__c newResourceTag = new sked__Resource_Tag__c(
                        sked__Resource__c = skedResource.Id,
                        sked__Tag__c = skedTag.Id,
                        sked_Start_Date__c = startDate,
                        sked_Role_Status__c = 'Active'
                    );
                    recordsToInsert.add(newResourceTag);                       
                }
            }
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
        }
    }

    private void updateResourceSeniorityRankings(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        List<sked__Resource__c> resourcesToUpdate = new List<sked__Resource__c>();
        for (sked__Resource__c newRecord : newRecords) {
            if (oldMap==null && newRecord.sked__Resource_Type__c==skedConstants.RESOURCE_TYPE_PERSON) {
                newRecord.IsChangedEmploymentStatus__c=true;
            } else if(oldMap!=null && newRecord.sked__Resource_Type__c==skedConstants.RESOURCE_TYPE_PERSON) {
                sked__Resource__c oldRecord = oldMap.get(newRecord.Id);
                if (newRecord.sked_Employment_Status__c != oldRecord.sked_Employment_Status__c) {
                        newRecord.IsChangedEmploymentStatus__c=true;
                }
        	}
        }
    }
   
    public static Set<Id> getAffectedArcRegions(List<sked__Resource__c> newRecords) {
        Set<Id> collectionOperationIds = new Set<Id>();
        
        newRecords = [
            SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
            FROM sked__Resource__c
            WHERE Id IN :newRecords
        ];

        Set<Id> affectedArcRegions = new Set<Id>();
        if (newRecords != null && !newRecords.isEmpty()) {
            Set<Id> collectionOpIds = new Set<Id>();
            for (sked__Resource__c resource : newRecords) {
                collectionOpIds.add(resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c);
            }

            List<Biomed_Collection_Op_Center__c> collectionOps = [
                SELECT Id, sked_Territory__r.sked_Parent__c
                FROM Biomed_Collection_Op_Center__c
                WHERE Id IN :collectionOpIds
            ];

            if (collectionOps != null && !collectionOps.isEmpty()) {
                for (Biomed_Collection_Op_Center__c collectionOp : collectionOps) {
                    if (collectionOp.sked_Territory__r.sked_Parent__c != null) {
                        affectedArcRegions.add(collectionOp.sked_Territory__r.sked_Parent__c);
                    }
                }
            }
        }

        
        return affectedArcRegions;
    }
    
    private void revertAccidientallyChangedGeolocation(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.revertAccidientallyChangedGeolocation(newRecord, oldData, 'sked__Home_Address__c', 'sked__GeoLocation__Latitude__s', 'sked__GeoLocation__Longitude__s');
            
            List<string> homeAddressFieldApiNames = new List<string>();
            homeAddressFieldApiNames.add('sked_Home_Address_1__c');
            homeAddressFieldApiNames.add('sked_Home_Address_2__c');
            homeAddressFieldApiNames.add('sked_Home_Address_3__c');
            homeAddressFieldApiNames.add('sked_Home_City__c');
            homeAddressFieldApiNames.add('sked_Home_Country__c');
            homeAddressFieldApiNames.add('sked_Home_State__c');
            homeAddressFieldApiNames.add('sked_Home_Zip_Code__c');
            skedTriggerUtils.revertAccidientallyChangedGeolocation(newRecord, oldData, homeAddressFieldApiNames, 'sked_Home_Address_GeoLocation__Latitude__s', 'sked_Home_Address_GeoLocation__Longitude__s');
            
            List<string> workAddressFieldApiNames = new List<string>();
            workAddressFieldApiNames.add('sked_Work_Address_1__c');
            workAddressFieldApiNames.add('sked_Work_Address_2__c');
            workAddressFieldApiNames.add('sked_Work_Address_3__c');
            workAddressFieldApiNames.add('sked_Work_City__c');
            workAddressFieldApiNames.add('sked_Work_Country__c');
            workAddressFieldApiNames.add('sked_Work_State__c');
            workAddressFieldApiNames.add('sked_Work_Zip_Code__c');
            skedTriggerUtils.revertAccidientallyChangedGeolocation(newRecord, oldData, workAddressFieldApiNames, 'sked_Work_Address_GeoLocation__Latitude__s', 'sked_Work_Address_GeoLocation__Longitude__s');
            
            List<string> satelliteAddressFieldApiNames = new List<string>();
            satelliteAddressFieldApiNames.add('sked_Satellite_Address__c');
            satelliteAddressFieldApiNames.add('sked_Satellite_Address_1__c');
            satelliteAddressFieldApiNames.add('sked_Satellite_City__c');
            satelliteAddressFieldApiNames.add('sked_Satellite_Country__c');
            satelliteAddressFieldApiNames.add('sked_Satellite_State__c');
            satelliteAddressFieldApiNames.add('sked_Satellite_Zip_Code__c');
            skedTriggerUtils.revertAccidientallyChangedGeolocation(newRecord, oldData, satelliteAddressFieldApiNames, 'sked_Satellite_Address_Geolocation__Latitude__s', 'sked_Satellite_Address_Geolocation__Longitude__s');
        }
    }

    /**
     * Clears the Anticipated Leave Return Date, when Employment Status changes from Leave to Active
     * HRP-12869
     */
    private void clearAnticipatedLeaveReturnDate(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            
            // Check whether Employment Status changed from Leave to Active and resource is a person
            if (oldData != null && 
                newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON &&
                oldData.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE &&
                newRecord.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_ACTIVE) {
                
                // Clear the Anticipated Leave Return Date if it has a value
                if (newRecord.sked_Anticipated_Leave_Return_Date__c != null) {
                    newRecord.sked_Anticipated_Leave_Return_Date__c = null;
                }
            }
        }
    }

    private void onDeactivateResources(List<sked__Resource__c> newRecords, Map<Id, sked__Resource__c> oldMap) {
        Set<Id> deactivatedResourceIds = new Set<Id>();
        for (sked__Resource__c newRecord : newRecords) {
            sked__Resource__c oldData = oldMap.get(newRecord.Id);
            boolean isPersonResourceDeactivated = newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON  
                && newRecord.sked_Employment_Status__c != oldData.sked_Employment_Status__c
                && newRecord.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE;
            boolean isAssetResourceDeactivated = newRecord.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_ASSET
                && newRecord.sked__Is_Active__c != oldData.sked__Is_Active__c 
                && newRecord.sked__Is_Active__c == FALSE;
            if (isPersonResourceDeactivated || isAssetResourceDeactivated) {
                deactivatedResourceIds.add(newRecord.Id);
            }
        }
        if (!deactivatedResourceIds.isEmpty()) {
            DateTime currentTime = system.now();
            List<sked__Availability_Pattern_Resource__c> patternResources = [
                SELECT Id, sked__End__c
                FROM sked__Availability_Pattern_Resource__c
                WHERE sked__Resource__c IN :deactivatedResourceIds
                AND (sked__End__c = NULL OR sked__End__c >= :currentTime)
            ];

            if (!patternResources.isEmpty()) {
                for (sked__Availability_Pattern_Resource__c patternResource : patternResources) {
                    patternResource.sked__End__c = currentTime;
                }
                update patternResources;
            }
        }
    }

    //========= Nested class ======//
    public class periodModel {
        public Datetime start;
        public Datetime finish;
        public periodModel(Datetime start, Datetime finish) {
            this.start = start;
            this.finish = finish;
        }
    }
}