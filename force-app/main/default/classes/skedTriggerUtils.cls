public class skedTriggerUtils {
    
    public static Boolean CHANGES_INITIATED_FROM_SERVICE = false;
    
    public static void maintainDateTimeField(sObject newRecord, string dateTimeFieldApiName, string dateFieldApiName, string timeFieldApiName, string timezoneFieldApiName) {
    	maintainDateTimeField(newRecord, dateTimeFieldApiName, dateFieldApiName, timeFieldApiName, timezoneFieldApiName, NULL);
    }
    
    public static void maintainDateTimeField(sObject newRecord, string dateTimeFieldApiName, string dateFieldApiName, string timeFieldApiName, string timezoneFieldApiName, string timezoneSidId) {
        DateTime dtValue = (DateTime)newRecord.get(dateTimeFieldApiName);
        if (dtValue != NULL) {
            skedDateTimeUtils.convertDateTimeToDateAndTime(newRecord, dateTimeFieldApiName, dateFieldApiName, timeFieldApiName, timezoneFieldApiName, timezoneSidId);
        }
        else {
            skedDateTimeUtils.convertDateAndTimeToDateTime(newRecord, dateTimeFieldApiName, dateFieldApiName, timeFieldApiName, timezoneFieldApiName, timezoneSidId);
        }
    }
    
    public static void maintainDateTimeField(sObject newRecord, sObject oldData, string dateTimeFieldApiName, string dateFieldApiName, string timeFieldApiName, string timezoneFieldApiName) {
        maintainDateTimeField(newRecord, oldData, dateTimeFieldApiName, dateFieldApiName, timeFieldApiName, timezoneFieldApiName, NULL);
    }
    
    public static void maintainDateTimeField(sObject newRecord, sObject oldData, string dateTimeFieldApiName, string dateFieldApiName, string timeFieldApiName, string timezoneFieldApiName, string timezoneSidId) {
        DateTime newDtValue = (DateTime)newRecord.get(dateTimeFieldApiName);
        DateTime oldDtValue = (DateTime)oldData.get(dateTimeFieldApiName);
        if (newDtValue != oldDtValue) {
            skedDateTimeUtils.convertDateTimeToDateAndTime(newRecord, dateTimeFieldApiName, dateFieldApiName, timeFieldApiName, timezoneFieldApiName, timezoneSidId);
        }
        else {
            Date newDateValue = (Date)newRecord.get(dateFieldApiName);
            Time newTimeValue = (Time)newRecord.get(timeFieldApiName);
            Date oldDateValue = (Date)oldData.get(dateFieldApiName);
            Time oldTimeValue = (Time)oldData.get(timeFieldApiName);
            
            if (newDateValue != oldDateValue || newTimeValue != oldTimeValue) {
                skedDateTimeUtils.convertDateAndTimeToDateTime(newRecord, dateTimeFieldApiName, dateFieldApiName, timeFieldApiName, timezoneFieldApiName, timezoneSidId);
            }
        }
    }

    public static void revertAccidientallyChangedGeolocation(sObject newRecord, sObject oldData, string addressFieldApiName, string latitudeFieldApiName, string longituideFieldApiName) {
        List<string> addressFieldApiNames = new List<string>();
        addressFieldApiNames.add(addressFieldApiName);
        revertAccidientallyChangedGeolocation(newRecord, oldData, addressFieldApiNames, latitudeFieldApiName, longituideFieldApiName);
    }
    
    public static void revertAccidientallyChangedGeolocation(sObject newRecord, sObject oldData, List<string> addressFieldApiNames, string latitudeFieldApiName, string longituideFieldApiName) {
        boolean isGeolocationChanged = newRecord.get(latitudeFieldApiName) != oldData.get(latitudeFieldApiName) 
            || newRecord.get(longituideFieldApiName) != oldData.get(longituideFieldApiName);
        
        boolean isAddressChanged = FALSE;
        for (string addressFieldApiName : addressFieldApiNames) {
            if (newRecord.get(addressFieldApiName) != oldData.get(addressFieldApiName)) {
                isAddressChanged = TRUE;
                break;
            }
        }
            
        if (isGeolocationChanged && !isAddressChanged) {
            newRecord.put(latitudeFieldApiName, oldData.get(latitudeFieldApiName));
            newRecord.put(longituideFieldApiName, oldData.get(longituideFieldApiName));
        }
    }
    
    public static void updateJobAllocations(Set<Id> jobIds, Set<Id> driveShiftIds) {
        if (!skedSetting.instance.Admin.migrationMode) {
            List<sked__Job_Allocation__c> jobAllocations = [
                SELECT Id, Name
                FROM sked__Job_Allocation__c
                WHERE (sked__Job__c IN :jobIds OR sked__Job__r.sked_Drive_Shift__c IN :driveShiftIds)
                AND sked__Status__c NOT IN :new List<String>{
                    skedConstants.JOB_ALLOCATION_STATUS_DECLINED,
                    skedConstants.JOB_ALLOCATION_STATUS_DELETED
                }
            ];
                
            Set<Id> jobAllocationIds = new Set<Id>();
            for (sked__Job_Allocation__c ja : jobAllocations) {
                jobAllocationIds.add(ja.Id);
            }
    
            if (!Test.isRunningTest()) {
                Database.executeBatch(new skedJobAllocationPostProcessBatch(
                    new skedJobAllocationPostProcessBatch.batchSetting(),
                    jobAllocationIds
                ));
            }
        }
    }

    public static Boolean hasAnyPermissionSetAssignment(List<String> permissionSetNames) {
        Boolean hasPsa = false;

        List<PermissionSetAssignment> psas = skedTriggerHub_Cache.getPermissionSetsForUser(UserInfo.getUserId());
        if(psas != null && !psas.isEmpty()) {
            for (PermissionSetAssignment psa : psas) {
                if (permissionSetNames.contains(psa.PermissionSet.Name)) {
                    hasPsa = true;
                    break;
                }
            }
        }

        return hasPsa;
    }

    public static Boolean hasPermissionSetAssignment(String permissionSetName) {        
        return hasAnyPermissionSetAssignment(new List<String>{permissionSetName});
    }

    public static Boolean userBelongsToAnyProfile(List<String> profileNames) {
        Boolean hasProfile = false;

        Profile usersProfile = skedTriggerHub_Cache.getProfileForId(UserInfo.getProfileId());
        for (String profileName : profileNames) {
            if (usersProfile.Name == profileName) {
                hasProfile = true;
            }
        }
        return hasProfile;
    }

    public static Boolean userBelongsToProfile(String profileName) {
        return userBelongsToAnyProfile(new List<String>{profileName});
    }
    
    public static void populateTimezoneFromTaxonomy(List<sObject> records, String zipcodeField, String timezoneField) {
        Set<string> zipcodes = new Set<string>();
        for (sObject record : records) {
            String zipcode = record.get(zipcodeField) != null ? (String)record.get(zipcodeField) : null;
            if (zipcode != null) {
                zipcodes.add(zipcode);
            }
        }
        
        List<Taxonomy__c> taxonomyRecords = [SELECT Id, Zip_Code__c, Time_Zone__c
                                             FROM Taxonomy__c
                                             WHERE Zip_Code__c IN :zipcodes
                                             AND Time_Zone__c != NULL
                                             ORDER BY Start_Date__c];
        Map<string, Taxonomy__c> taxonomyByZipcode = new Map<string, Taxonomy__c>();
        for (Taxonomy__c taxonomy : taxonomyRecords) {
            taxonomyByZipcode.put(taxonomy.Zip_Code__c, taxonomy);
        }
        
        for (sObject record : records) {
            String zipcode = record.get(zipcodeField) != null ? (String)record.get(zipcodeField) : null;
            if (String.isNotBlank(zipcode)) {
                if (taxonomyByZipcode.containsKey(zipcode)) {
                    Taxonomy__c taxonomy = taxonomyByZipcode.get(zipcode);
                    record.put(timezoneField, taxonomy.Time_Zone__c);
                }
            }
        }
    }

    public static boolean isUserAPS(Id userId) {
        List<String> otherProfiles = new List<String>{'Global Admin', 'System Administrator'};
        if (userId == UserInfo.getUserId()) {
            return skedTriggerHub_Cache.loginUser.Profile.Name.contains('APS') || otherProfiles.contains(skedTriggerHub_Cache.loginUser.Profile.Name);
        }
        
        User u = [SELECT Id, Profile.Name FROM User WHERE Id = :userId];
        return u.Profile.Name.contains('APS') || otherProfiles.contains(u.Profile.Name);
    }

    public static void validateServiceEntry(List<SObject> newRecords, String errorMessage) {
        validateServiceEntry(newRecords, errorMessage, new List<String>{'Global Admin', 'System Administrator'}, true);
    }

    public static void validateServiceEntry(List<SObject> newRecords, String errorMessage, List<String> allowedProfiles) {
        validateServiceEntry(newRecords, errorMessage, allowedProfiles, true);
    }

    public static void validateServiceEntry(List<SObject> newRecords, String errorMessage, List<String> allowedProfiles, Boolean usageAllowedViaService) {
        boolean isAllowedProfile = allowedProfiles.contains(skedTriggerHub_Cache.loginUser.Profile.Name);
        boolean isAutoProcUser = UserInfo.getUserId() == skedTriggerHub_Cache.getAutoProcessUserFromCache().Id;
        boolean isPermittedUsage = usageAllowedViaService ? CHANGES_INITIATED_FROM_SERVICE : usageAllowedViaService;

        if (!System.isBatch() && !isAutoProcUser && !isAllowedProfile && !isPermittedUsage) {
            for (SObject newRecord : newRecords) {
            newRecord.addError(errorMessage);
            }
        }
    }
}