global class slwcAllocationService {
    
    @AuraEnabled
    public static slwcAuraResult getResourceData(getResourceDataRequestModel request) {
        slwcAuraResult result = new slwcAuraResult();
        
        string timezoneSidId = !string.isBlank(request.timezoneSidId) ? request.timezoneSidId : UserInfo.getTimeZone().getID();
        
        List<Date> inputDates = new List<Date>();
        for (string inputDate : request.inputDates) {
            inputDates.add(skedDateTimeUtils.getDateFromIsoString(inputDate));
        }
        
        if (request.excludedDriveIds == NULL) {
            request.excludedDriveIds = new List<string>();
        }
        if (request.excludedActivityIds == NULL) {
            request.excludedActivityIds = new List<string>();
        }
        
        request.allDates = new List<Date>(inputDates);
        request.allDates.sort();
        request.minDate = request.allDates[0];
        request.maxDate = request.allDates[request.allDates.size() - 1];

        Set<string> collectionOperationIds = new Set<string>();
        if (request.collectionOperationIds != NULL && !request.collectionOperationIds.isEmpty()) {
            collectionOperationIds.addAll(request.collectionOperationIds);
        }
        if (request.arcRegionIds != NULL && !request.arcRegionIds.isEmpty()) {
            for (sked_Territory_Collection_Operation__c territoryCollectionOperation : [
                SELECT sked_Collection_Operation__c
                FROM sked_Territory_Collection_Operation__c
                WHERE sked_Territory__r.sked_Parent__c IN :request.arcRegionIds
                AND sked_Start_Date__c <= :request.maxDate
                AND sked_End_Date__c >= :request.minDate
            ]) {
                collectionOperationIds.add(territoryCollectionOperation.sked_Collection_Operation__c);
            }
        }
        request.collectionOperationIds = new List<string>(collectionOperationIds);
        
        request.additionalResourceIds = new List<string>();
        if (request.collectionOperationIds != NULL && !request.collectionOperationIds.isEmpty()) {
            List<sked__Resource_Override__c> resourceOverrides = [SELECT Id, sked__Resource__c 
                                                                  FROM sked__Resource_Override__c 
                                                                  WHERE sked_Collection_Operation__c IN :request.collectionOperationIds
                                                                  AND (sked_Start_Date__c <= :request.maxDate 
                                                                       AND sked_End_Date__c >= :request.minDate)];
            if (resourceOverrides != NULL && !resourceOverrides.isEmpty()) {
                for (sked__Resource_Override__c resourceOverride : resourceOverrides) {
                    request.additionalResourceIds.add(resourceOverride.sked__Resource__c);
                }
            }
            List<sked_Resource_Biomed_Collection_Op__c> resourceCollectionOperations = [SELECT Id, sked_Resource__c
                                                                                        FROM sked_Resource_Biomed_Collection_Op__c
                                                                                        WHERE sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds
                                                                                        AND ((sked_Start_Date__c = NULL OR sked_Start_Date__c <= :request.maxDate) 
                                                                                             AND (sked_End_Date__c = NULL OR sked_End_Date__c  >= :request.minDate))];
            if (resourceCollectionOperations != NULL && !resourceCollectionOperations.isEmpty()) {
                for (sked_Resource_Biomed_Collection_Op__c resourceCollectionOperation : resourceCollectionOperations) {
                    request.additionalResourceIds.add(resourceCollectionOperation.sked_Resource__c);
                }
            }
        }
        List<sked__Job_Allocation__c> existingAllocations = [SELECT Id, sked__Resource__c
                                                             FROM sked__Job_Allocation__c
                                                             WHERE sked__Job__c IN :request.jobIds
                                                             AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
        request.allocatedResourceIds = new List<string>();
        for (sked__Job_Allocation__c existingAllocation : existingAllocations) {
            request.allocatedResourceIds.add(existingAllocation.sked__Resource__c);
        }
        
        AggregateResult turnAroundResult = [SELECT Max(sked_Turnaround_Time__c) maxTurnAroundTime
                                            FROM sked__Resource__c
                                            WHERE (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds 
                                                   OR Id IN :request.additionalResourceIds)
                                            AND sked__Is_Active__c = TRUE];
        Integer maxResourceTurnAroundMinutes = 0;
        if (turnAroundResult != NULL) {                                    
            Decimal maxResourceTurnAroundTime = (Decimal)turnAroundResult.get('maxTurnAroundTime');
            maxResourceTurnAroundMinutes = maxResourceTurnAroundTime != NULL ? (integer)maxResourceTurnAroundTime * 60 : 0;
        }
        
        DateTime expiryTagDate = skedDateTimeUtils.getStartOfDate(request.minDate, timezoneSidId);
        DateTime minDateTime = expiryTagDate;
        DateTime maxDateTime = skedDateTimeUtils.getEndOfDate(request.maxDate, timezoneSidId);
        request.minTurnAroundDateTime = skedDateTimeUtils.getStartOfDate(minDateTime.addMinutes(-maxResourceTurnAroundMinutes), timezoneSidId);
        request.maxTurnAroundDateTime = skedDateTimeUtils.getEndOfDate(maxDateTime.addMinutes(maxResourceTurnAroundMinutes), timezoneSidId);
        
        request.offset = (request.pageNo - 1) * request.pageSize;
        
        List<sked__Resource__c> resources;
        if (request.getAssetsOnly == TRUE) {
            resources = getAssets(request);
        }
        else if (request.recordIds == NULL || request.recordIds.isEmpty()) {
            resources = getResources(request);
        }
        else {
            resources = getResourcesByIds(request);
        }
        
        Set<Id> resourceOverrideIds = new Set<Id>();
        for (sked__Resource__c resource : resources) {
            if (resource.sked__Resource_Overrides__r != NULL && !resource.sked__Resource_Overrides__r.isEmpty()) {
                for (sked__Resource_Override__c resourceOverride : resource.sked__Resource_Overrides__r) {
                    resourceOverrideIds.add(resourceOverride.Id);
                }
            }
        }
        
        Set<Id> groupActivityIds = new Set<Id>();
        Set<Id> availabilityPatternIds = new Set<Id>();
        for (sked__Resource__c resource : resources) {
            if (resource.sked__Activity_Resources__r != NULL && !resource.sked__Activity_Resources__r.isEmpty()) {
                for (sked__Activity_Resource__c activityResource : resource.sked__Activity_Resources__r) {
                    groupActivityIds.add(activityResource.sked__Activity__c);
                }
            }
            if (resource.sked__Availability_Pattern_Resources__r != NULL && !resource.sked__Availability_Pattern_Resources__r.isEmpty()) {
                for (sked__Availability_Pattern_Resource__c availabilityPatternResource : resource.sked__Availability_Pattern_Resources__r) {
                    availabilityPatternIds.add(availabilityPatternResource.sked__Availability_Pattern__c);
                }
            }
        }

        Set<Id> resourceHoursRecordIds = new Set<Id>();
        for (sked__Resource__c resource : resources) {
            if (resource.sked_Resource_Hours_Records__r != NULL && !resource.sked_Resource_Hours_Records__r.isEmpty()) {
                for (sked_Resource_Hours_Record__c resourceHoursRecord : resource.sked_Resource_Hours_Records__r) {
                    resourceHoursRecordIds.add(resourceHoursRecord.Id);
                }
            }
        }
        
        resourceDataModel data = new resourceDataModel();
        data.resources = resources;
        if (!groupActivityIds.isEmpty()) {
            data.groupActivities = [SELECT Id, Name, sked__Start__c, sked__End__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,
                                    sked__Type__c,sked_Activity_Title__c
                                    FROM sked__Activity__c
                                    WHERE Id IN :groupActivityIds];  
        }
        if (!availabilityPatternIds.isEmpty()) {
            data.availabilityPatterns = [SELECT Id, Name, sked__Pattern__c
                                         FROM sked__Availability_Pattern__c
                                         WHERE Id IN :availabilityPatternIds];  
        }
        if (!resourceOverrideIds.isEmpty()) {
            data.resourceOverrides = [SELECT Id, sked__Description__c, sked__End__c, sked_End_Date__c, sked__GeoLocation__c, sked__GeoLocation__Longitude__s, 
                                      sked__GeoLocation__Latitude__s, sked__Home_Address__c, sked__Resource__c, sked__Start__c, sked_Start_Date__c,
                                      sked_Collection_Operation__c, sked_Is_Travel_Required__c,
                                      (SELECT Id, Name, sked__Region__c, sked__Resource_Override__c
                                       FROM sked__Resource_Override_Regions__r)
                                      FROM sked__Resource_Override__c
                                      WHERE Id IN :resourceOverrideIds];
        }
        if (request.jobIds != NULL && !request.jobIds.isEmpty()) {
            data.calloutJobAllocations = [SELECT Id, sked__Job__c, sked__Resource__c
                                          FROM sked__Job_Allocation__c
                                          WHERE sked__Job__c IN :request.jobIds
                                          AND sked_Call_Out_Type__c = :skedConstants.AVAILABILITY_CALLOUT_TYPE_CALL_OUT
                                          AND sked__Status__c = :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
        }
        if (request.jobIds != NULL && !request.jobIds.isEmpty()) {
            data.tradedJobAllocations = [SELECT Id, sked__Job__c, sked__Resource__c
                                         FROM sked__Job_Allocation__c
                                         WHERE sked__Job__c IN :request.jobIds
                                         AND sked_Drive_Shift_Trade__c != NULL
                                         AND sked__Status__c = :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
        }
        if (!resourceHoursRecordIds.isEmpty()) {
            data.resourceHoursRecordDetails = [SELECT Id, sked_Resource_Hours_Record__c, sked_Start_Date__c, sked_End_Date__c
                                              FROM sked_Resource_Hours_Record_Detail__c
                                              WHERE sked_Resource_Hours_Record__c IN :resourceHoursRecordIds];
        }
        if (!request.allDates.isEmpty()) {
            data.prevCancelledJobAllocations = [SELECT Id, sked__Job__c, sked__Resource__c, sked__Job__r.sked_Drive__c, 
                                                sked__Job__r.sked_Drive__r.sked_Drive_Date__c, sked__Job__r.sked_Drive__r.Name,
                                                sked__Job__r.sked_Drive__r.sked_UFID__c
                                                FROM sked__Job_Allocation__c
                                                WHERE sked__Job__r.sked_Drive__r.sked_Drive_Date__c IN :request.allDates
                                                AND sked__Job__r.sked_Drive__r.sked_Status__c = :skedConstants.DRIVE_STATUS_CANCEL];
        }

        if (request.pageNo == 1) {
            data.totalRecords = request.recordIds != NULL ? request.recordIds.size() : (request.getAssetsOnly == TRUE ? numberOfAssets(request) : numberOfResources(request));
        }
        result.returnedData = data;
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult getAssetDataCompact(getResourceDataRequestModel request) {
        slwcAuraResult result = new slwcAuraResult();
        
        string timezoneSidId = !string.isBlank(request.timezoneSidId) ? request.timezoneSidId : UserInfo.getTimeZone().getID();
        
        List<Date> inputDates = new List<Date>();
        for (string inputDate : request.inputDates) {
            inputDates.add(skedDateTimeUtils.getDateFromIsoString(inputDate));
        }
        
        request.allDates = new List<Date>(inputDates);
        request.allDates.sort();
        request.minDate = request.allDates[0];
        request.maxDate = request.allDates[request.allDates.size() - 1];
        
        request.additionalResourceIds = new List<string>();
        request.allocatedResourceIds = new List<string>();
        if (request.collectionOperationIds != NULL && !request.collectionOperationIds.isEmpty()) {
            List<sked_Resource_Biomed_Collection_Op__c> resourceCollectionOperations = [SELECT Id, sked_Resource__c
                                                                                        FROM sked_Resource_Biomed_Collection_Op__c
                                                                                        WHERE sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds
                                                                                        AND ((sked_Start_Date__c = NULL OR sked_Start_Date__c <= :request.maxDate) 
                                                                                             AND (sked_End_Date__c = NULL OR sked_End_Date__c  >= :request.minDate))];
            if (resourceCollectionOperations != NULL && !resourceCollectionOperations.isEmpty()) {
                for (sked_Resource_Biomed_Collection_Op__c resourceCollectionOperation : resourceCollectionOperations) {
                    request.additionalResourceIds.add(resourceCollectionOperation.sked_Resource__c);
                }
            }
        }
        DateTime expiryTagDate = skedDateTimeUtils.getStartOfDate(request.minDate, timezoneSidId);
        DateTime minDateTime = expiryTagDate;
        DateTime maxDateTime = skedDateTimeUtils.getEndOfDate(request.maxDate, timezoneSidId);
        
        request.offset = (request.pageNo - 1) * request.pageSize;
        
        List<sked__Resource__c> resources = [SELECT Id, Name, sked__Email__c, sked__User__c, sked__Resource_Type__c, sked_Asset_Type__c, sked_Mobile_Type__c,
                                             sked_Equipment_Subtype__c, sked__Is_Active__c,
                                             sked__Primary_Region__c, sked__Home_Address__c, sked__GeoLocation__Longitude__s, sked__GeoLocation__Latitude__s, 
                                             sked__Category__c, sked__User__r.SmallPhotoUrl, sked_Pres_Donor_Capacity__c,
                                             sked_Maximum_Travel_Radius__c, sked_Turnaround_Time__c, sked_Max_Hours_Per_Week__c,
                                             sked__Primary_Phone__c, sked__Primary_Region__r.sked__Timezone__c, sked_Dedicated_to_Site__c,
                                             sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, sked_Biomed_Collection_Op_Center_Name__c,
                                             sked_CDL__c, sked_DOT__c, sked_Effective_Date__c, sked_Max_Travel_Time__c,
                                             
                                             (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked_Start_Date__c, sked__Tag__r.sked__Type__c, sked_Restriction_Start_Date__c, sked_Restriction_End_Date__c
                                              FROM sked__ResourceTags__r
                                              WHERE sked_Start_Date__c <= :request.maxDate),
                                             
                                             (SELECT Id, sked_Resource__c, sked_Biomed_Collection_Op_Center__c, sked_Start_Date__c, sked_End_Date__c
                                              FROM sked_Resource_Biomed_Collection_Ops__r
                                              WHERE (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :request.maxDate) 
                                              AND (sked_End_Date__c = NULL OR sked_End_Date__c  >= :request.minDate))
                                             
                                             FROM sked__Resource__c
                                             WHERE (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds 
                                                    OR Id IN :request.additionalResourceIds)
                                             AND sked_Asset_Type__c != NULL
                                             AND sked__Is_Active__c = TRUE
                                             AND (sked_Effective_Date__c = NULL OR sked_Effective_Date__c <= :request.maxDate)
                                             ORDER BY Name
                                             LIMIT :request.pageSize
                                             OFFSET :request.offset];
        
        resourceDataModel data = new resourceDataModel();
        data.resources = resources;
        if (request.pageNo == 1) {
            data.totalRecords = numberOfAssets(request);
        }
        result.returnedData = data;
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult getLinkedDrivesResourceIds(Id driveId) {
        slwcAuraResult result = new slwcAuraResult();
        
        sked_Drive__c skedDrive = [SELECT Id, sked_Linked_Drives__c
                                   FROM sked_Drive__c
                                   WHERE Id = :driveId];
        if (skedDrive.sked_Linked_Drives__c != NULL) {
            Id linkedOpportunityDrivesId = skedDrive.sked_Linked_Drives__c;
            List<sked__Job_Allocation__c> linkedDrivesAllocations = [SELECT Id, sked__Resource__c
                                                                     FROM sked__Job_Allocation__c
                                                                     WHERE sked__Job__r.sked_Drive__r.sked_Linked_Drives__c = :linkedOpportunityDrivesId
                                                                     AND sked__Job__r.sked_Drive__c != :driveId
                                                                     AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                                     AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED];
            Set<Id> resourceIds = new Set<Id>();
            for (sked__Job_Allocation__c linkedDrivesAllocation : linkedDrivesAllocations) {
                resourceIds.add(linkedDrivesAllocation.sked__Resource__c);
            }
            result.returnedData = resourceIds;
        }
        
        return result;
    }
    
    /*********************************************************** Nested Classes ***********************************************************/
    private static List<sked__Resource__c> getResources(getResourceDataRequestModel request) {
        List<string> excludedActivityTypes = new List<string>();
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_AFTER_HOURS_CALL_OUT_MANAGEMENT);
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_ON_CALL);
        
        List<sked__Resource__c> resources = [SELECT Id, Name, sked__Email__c, sked__User__c, sked__Resource_Type__c, sked_Asset_Type__c, sked_Mobile_Type__c,
                                             sked__Primary_Region__c, sked__Home_Address__c, sked__GeoLocation__Longitude__s, sked__GeoLocation__Latitude__s, 
                                             sked__Category__c, sked__User__r.SmallPhotoUrl, sked_Pres_Donor_Capacity__c, sked_Roles__c,
                                             sked_Maximum_Travel_Radius__c, sked_Turnaround_Time__c, sked_Seniority_Rank__c, sked__Employment_Type__c, sked_Max_Hours_Per_Week__c,
                                             sked__Primary_Phone__c, sked__Primary_Region__r.sked__Timezone__c, sked_Dedicated_to_Site__c,
                                             sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c,
                                             sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Staging_Location_Geolocation__Latitude__s, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Staging_Location_Geolocation__Longitude__s,
                                             sked_Biomed_Collection_Op_Center_Name__c, sked_Daily_Time_Off_Hours__c,
                                             sked_CDL__c, sked_DOT__c, sked_Termination_Date__c, sked_Planned_Termination_Date__c, 
                                             sked_Anticipated_Leave_Return_Date__c, sked__Is_Active__c, sked_Effective_Date__c,
                                             sked_Max_Travel_Time__c, sked_Employment_Status__c,
                                             sked_Address_Referenced_for_Scheduling__c, Use_CO_Address_for_Scheduling__c, sked_Max_Working_Days_Per_Week__c,
                                             
                                             (SELECT Id, sked__Account__c, sked__Blacklisted__c, sked__Whitelisted__c
                                              FROM sked__Account_Resource_Scores__r
                                              WHERE sked__Account__c IN :request.accountIds),
                                             
                                             (SELECT Id, sked_Start_Date__c, sked_End_Date__c, sked_Total_Working_Time__c
                                              FROM sked_Resource_Hours_Records__r
                                              WHERE sked_Start_Date__c <= :request.maxDate AND sked_End_Date__c >= :request.minDate),
                                             
                                             (SELECT Id, sked__Location__c, sked__Blacklisted__c, sked__Whitelisted__c
                                              FROM sked__Location_Resource_Scores__r
                                              WHERE sked__Location__c IN :request.locationIds),
                                             
                                             (SELECT Id, sked__Description__c, sked__End__c, sked_End_Date__c, sked__GeoLocation__c, sked__GeoLocation__Longitude__s, 
                                              sked__GeoLocation__Latitude__s, sked__Home_Address__c, sked__Resource__c, sked__Start__c, sked_Start_Date__c,
                                              sked_Is_Travel_Required__c
                                              FROM sked__Resource_Overrides__r
                                              WHERE sked_Start_Date__c <= :request.maxDate AND sked_End_Date__c >= :request.minDate),
                                             
                                             (SELECT Id, sked_Resource__c, sked_Biomed_Collection_Op_Center__c, sked_Start_Date__c, sked_End_Date__c
                                              FROM sked_Resource_Biomed_Collection_Ops__r
                                              WHERE (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :request.maxDate) 
                                              AND (sked_End_Date__c = NULL OR sked_End_Date__c  >= :request.minDate)),
                                             
                                             (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked_Start_Date__c, sked__Tag__r.sked__Type__c, sked_Restriction_Start_Date__c, sked_Restriction_End_Date__c
                                              FROM sked__ResourceTags__r
                                              WHERE sked_Start_Date__c <= :request.maxDate
                                              AND (sked_Role_Status__c = NULL OR sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE)),
                                             
                                             (SELECT Id, Name, sked__Job__c, sked__Job__r.Name,
                                              sked__Job__r.sked__GeoLocation__Latitude__s, sked__Job__r.sked__GeoLocation__Longitude__s, 
                                              sked__Job__r.sked__Type__c, sked__Status__c,
                                              sked__Start__c, sked__Set_End__c, sked_Start_Date__c, sked_Set_End_Date__c, sked_Travel_Time_To__c, sked_Travel_Time_Back__c,
                                              sked__Job__r.sked_Drive__r.Name, sked__Job__r.sked_Drive__r.Id 
                                              FROM sked__Job_Allocations__r
                                              WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                              AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                              AND sked__Start__c <= :request.maxTurnAroundDateTime
                                              AND sked__Set_End__c >= :request.minTurnAroundDateTime
                                              AND sked__Job__c NOT IN :request.jobIds
                                              AND sked__Job__r.sked_Drive__c NOT IN :request.excludedDriveIds
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked__Start__c, sked__End__c, sked_Start_Date__c, sked_End_Date__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,sked_Activity_Title__c,
                                              sked__Type__c
                                              FROM sked__Activities__r
                                              WHERE sked_Start_Date__c IN :request.allDates
                                              AND sked__Type__c != :excludedActivityTypes
                                              AND Id NOT IN :request.excludedActivityIds
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked__Start__c, sked__Finish__c, sked_Start_Date__c, sked_Finish_Date__c, sked__Is_Available__c, sked__Type__c, sked_Call_Out_Type__c
                                              FROM sked__Availabilities1__r
                                              WHERE sked__Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
                                              AND sked_Start_Date__c <= :request.maxDate AND sked_Finish_Date__c >= :request.minDate
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked_Start__c, sked_Finish__c, sked_Start_Date__c, sked_Finish_Date__c, sked_Is_Available__c, sked_Type__c
                                              FROM sked_Custom_Availabilities__r
                                              WHERE sked_Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
                                              AND sked_Start_Date__c <= :request.maxDate AND sked_Finish_Date__c >= :request.minDate
                                              ORDER BY sked_Start__c ASC),
                                             
                                             (SELECT Id , sked__Start__c, sked__End__c, sked_Start_Date__c, sked_End_Date__c, sked__Availability_Pattern__r.sked__Pattern__c,sked__Availability_Pattern__r.Name,sked_Start_Time__c,sked_End_Time__c
                                              FROM sked__Availability_Pattern_Resources__r
                                              WHERE sked_Start_Date__c <= :request.maxDate
                                              AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :request.minDate)),
                                             
                                             (SELECT Id, sked__Activity__c, sked_Start1__c, sked_End__c, sked_Start_Date__c, sked_End_Date__c
                                              FROM sked__Activity_Resources__r
                                              WHERE sked__Activity__r.sked_Start_Date__c <= :request.maxDate
                                              AND sked__Activity__r.sked_End_Date__c >= :request.minDate
                                              AND sked__Activity__r.sked__Type__c NOT IN :excludedActivityTypes
                                              AND sked__Activity__c NOT IN :request.excludedActivityIds)
                                             
                                             FROM sked__Resource__c
                                             WHERE Id IN :request.allocatedResourceIds
                                             OR 
                                             (
                                                 (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds 
                                                  OR Id IN :request.additionalResourceIds)
                                                 AND (
                                                     (sked__Resource_Type__c = 'Person' AND sked_Employment_Status__c = 'Active') 
                                                     OR (
                                                         sked__Resource_Type__c = 'Person' 
                                                         AND sked_Employment_Status__c = 'Leave' 
                                                         AND sked_Anticipated_Leave_Return_Date__c <= :request.maxDate
                                                     )
                                                     OR (
                                                         sked__Resource_Type__c = 'Asset' 
                                                         AND sked__Is_Active__c = TRUE
                                                         AND (sked_Effective_Date__c = NULL OR sked_Effective_Date__c <= :request.maxDate)
                                                     )
                                                 )
                                                 AND (sked_Termination_Date__c = NULL OR sked_Termination_Date__c > :request.minDate)
                                                 AND (sked_Planned_Termination_Date__c = NULL OR sked_Planned_Termination_Date__c > :request.minDate)
                                             )
                                             ORDER BY Name
                                             LIMIT :request.pageSize
                                             OFFSET :request.offset];
        return resources;
    }
    
    private static List<sked__Resource__c> getResourcesByIds(getResourceDataRequestModel request) {
        List<string> excludedActivityTypes = new List<string>();
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_AFTER_HOURS_CALL_OUT_MANAGEMENT);
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_ON_CALL);
        
        List<sked__Resource__c> resources = [SELECT Id, Name, sked__Email__c, sked__User__c, sked__Resource_Type__c, sked_Asset_Type__c, sked_Mobile_Type__c,
                                             sked__Primary_Region__c, sked__Home_Address__c, sked__GeoLocation__Longitude__s, sked__GeoLocation__Latitude__s, 
                                             sked__Category__c, sked__User__r.SmallPhotoUrl, sked_Pres_Donor_Capacity__c, sked_Roles__c,
                                             sked_Maximum_Travel_Radius__c, sked_Turnaround_Time__c, sked_Seniority_Rank__c, sked__Employment_Type__c, sked_Max_Hours_Per_Week__c,
                                             sked__Primary_Phone__c, sked__Primary_Region__r.sked__Timezone__c, sked_Dedicated_to_Site__c,
                                             sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c,
                                             sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Staging_Location_Geolocation__Latitude__s, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Staging_Location_Geolocation__Longitude__s,
                                             sked_Biomed_Collection_Op_Center_Name__c, sked_Daily_Time_Off_Hours__c,
                                             sked_CDL__c, sked_DOT__c, sked_Termination_Date__c, sked_Planned_Termination_Date__c, 
                                             sked_Anticipated_Leave_Return_Date__c, sked__Is_Active__c, sked_Effective_Date__c,
                                             sked_Max_Travel_Time__c, sked_Employment_Status__c,
                                             sked_Address_Referenced_for_Scheduling__c, Use_CO_Address_for_Scheduling__c, sked_Max_Working_Days_Per_Week__c,
                                             
                                             (SELECT Id, sked__Account__c, sked__Blacklisted__c, sked__Whitelisted__c
                                              FROM sked__Account_Resource_Scores__r
                                              WHERE sked__Account__c IN :request.accountIds),
                                             
                                             (SELECT Id, sked_Start_Date__c, sked_End_Date__c, sked_Total_Working_Time__c
                                              FROM sked_Resource_Hours_Records__r
                                              WHERE sked_Start_Date__c <= :request.maxDate AND sked_End_Date__c >= :request.minDate),
                                             
                                             (SELECT Id, sked__Location__c, sked__Blacklisted__c, sked__Whitelisted__c
                                              FROM sked__Location_Resource_Scores__r
                                              WHERE sked__Location__c IN :request.locationIds),
                                             
                                             (SELECT Id, sked__Description__c, sked__End__c, sked_End_Date__c, sked__GeoLocation__c, sked__GeoLocation__Longitude__s, 
                                              sked__GeoLocation__Latitude__s, sked__Home_Address__c, sked__Resource__c, sked__Start__c, sked_Start_Date__c,
                                              sked_Is_Travel_Required__c
                                              FROM sked__Resource_Overrides__r
                                              WHERE sked_Start_Date__c <= :request.maxDate AND sked_End_Date__c >= :request.minDate),
                                             
                                             (SELECT Id, sked_Resource__c, sked_Biomed_Collection_Op_Center__c, sked_Start_Date__c, sked_End_Date__c
                                              FROM sked_Resource_Biomed_Collection_Ops__r
                                              WHERE (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :request.maxDate) 
                                              AND (sked_End_Date__c = NULL OR sked_End_Date__c  >= :request.minDate)),
                                             
                                             (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked_Start_Date__c, sked__Tag__r.sked__Type__c, sked_Restriction_Start_Date__c, sked_Restriction_End_Date__c
                                              FROM sked__ResourceTags__r
                                              WHERE sked_Start_Date__c <= :request.maxDate
                                              AND (sked_Role_Status__c = NULL OR sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE)),
                                             
                                             (SELECT Id, Name, sked__Job__c, sked__Job__r.Name,
                                              sked__Job__r.sked__GeoLocation__Latitude__s, sked__Job__r.sked__GeoLocation__Longitude__s, 
                                              sked__Job__r.sked__Type__c, sked__Status__c,
                                              sked__Start__c, sked__Set_End__c, sked_Start_Date__c, sked_Set_End_Date__c, sked_Travel_Time_To__c, sked_Travel_Time_Back__c
                                              FROM sked__Job_Allocations__r
                                              WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                              AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                              AND sked__Start__c <= :request.maxTurnAroundDateTime
                                              AND sked__Set_End__c >= :request.minTurnAroundDateTime
                                              AND sked__Job__c NOT IN :request.jobIds
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked__Start__c, sked__End__c, sked_Start_Date__c, sked_End_Date__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,
                                              sked__Type__c
                                              FROM sked__Activities__r
                                              WHERE sked_Start_Date__c IN :request.allDates
                                              AND sked__Type__c != :excludedActivityTypes
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked__Start__c, sked__Finish__c, sked_Start_Date__c, sked_Finish_Date__c, sked__Is_Available__c, sked__Type__c, sked_Call_Out_Type__c
                                              FROM sked__Availabilities1__r
                                              WHERE sked__Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
                                              AND sked_Start_Date__c <= :request.maxDate AND sked_Finish_Date__c >= :request.minDate
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked_Start__c, sked_Finish__c, sked_Start_Date__c, sked_Finish_Date__c, sked_Is_Available__c, sked_Type__c
                                              FROM sked_Custom_Availabilities__r
                                              WHERE sked_Start_Date__c <= :request.maxDate AND sked_Finish_Date__c >= :request.minDate
                                              ORDER BY sked_Start__c ASC),
                                             
                                             (SELECT Id , sked__Start__c, sked__End__c, sked_Start_Date__c, sked_End_Date__c, sked__Availability_Pattern__r.sked__Pattern__c,sked__Availability_Pattern__r.Name,sked_Start_Time__c,sked_End_Time__c
                                              FROM sked__Availability_Pattern_Resources__r
                                              WHERE sked_Start_Date__c <= :request.maxDate
                                              AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :request.minDate)),
                                             
                                             (SELECT Id, sked__Activity__c, sked_Start1__c, sked_End__c,sked_Start_Date__c, sked_End_Date__c
                                              FROM sked__Activity_Resources__r
                                              WHERE sked__Activity__r.sked_Start_Date__c <= :request.maxDate
                                              AND sked__Activity__r.sked_End_Date__c >= :request.minDate
                                              AND sked__Activity__r.sked__Type__c NOT IN :excludedActivityTypes)
                                             
                                             FROM sked__Resource__c
                                             WHERE Id IN :request.recordIds];
        return resources;
    }
    
    private static List<sked__Resource__c> getAssets(getResourceDataRequestModel request) {
        List<string> excludedActivityTypes = new List<string>();
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_AFTER_HOURS_CALL_OUT_MANAGEMENT);
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_ON_CALL);
        
        List<sked__Resource__c> resources = [SELECT Id, Name, sked__Email__c, sked__User__c, sked__Resource_Type__c, sked_Asset_Type__c, sked_Mobile_Type__c,
                                             sked_Equipment_Subtype__c, sked__Is_Active__c,
                                             sked__Primary_Region__c, sked__Home_Address__c, sked__GeoLocation__Longitude__s, sked__GeoLocation__Latitude__s, 
                                             sked__Category__c, sked__User__r.SmallPhotoUrl, sked_Pres_Donor_Capacity__c,
                                             sked_Maximum_Travel_Radius__c, sked_Turnaround_Time__c, sked_Max_Hours_Per_Week__c,
                                             sked__Primary_Phone__c, sked__Primary_Region__r.sked__Timezone__c, sked_Dedicated_to_Site__c,
                                             sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, sked_Biomed_Collection_Op_Center_Name__c,
                                             sked_CDL__c, sked_DOT__c, sked_Effective_Date__c, sked_Max_Travel_Time__c,
                                             
                                             (SELECT Id, sked__Account__c, sked__Blacklisted__c, sked__Whitelisted__c
                                              FROM sked__Account_Resource_Scores__r
                                              WHERE sked__Account__c IN :request.accountIds),
                                             
                                             (SELECT Id, sked__Location__c, sked__Blacklisted__c, sked__Whitelisted__c
                                              FROM sked__Location_Resource_Scores__r
                                              WHERE sked__Location__c IN :request.locationIds),
                                             
                                             (SELECT Id, sked__Description__c, sked__End__c, sked_End_Date__c, sked__GeoLocation__c, sked__GeoLocation__Longitude__s, 
                                              sked__GeoLocation__Latitude__s, sked__Home_Address__c, sked__Resource__c, sked__Start__c, sked_Start_Date__c,
                                              sked_Is_Travel_Required__c
                                              FROM sked__Resource_Overrides__r
                                              WHERE sked_Start_Date__c <= :request.maxDate AND sked_End_Date__c >= :request.minDate),
                                             
                                             (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked_Start_Date__c, sked__Tag__r.sked__Type__c, sked_Restriction_Start_Date__c, sked_Restriction_End_Date__c
                                              FROM sked__ResourceTags__r
                                              WHERE sked_Start_Date__c <= :request.maxDate),
                                             
                                             (SELECT Id, Name, sked__Job__c, sked__Job__r.Name, 
                                              sked__Job__r.sked__GeoLocation__Latitude__s, sked__Job__r.sked__GeoLocation__Longitude__s, 
                                              sked__Job__r.sked__Type__c, sked__Status__c,
                                              sked__Start__c, sked__Set_End__c, sked_Start_Date__c, sked_Set_End_Date__c, sked_Travel_Time_To__c, sked_Travel_Time_Back__c
                                              FROM sked__Job_Allocations__r
                                              WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                              AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                              AND sked__Start__c <= :request.maxTurnAroundDateTime
                                              AND sked__Set_End__c >= :request.minTurnAroundDateTime
                                              AND sked__Job__c NOT IN :request.jobIds
                                              AND sked__Job__r.sked_Drive__c NOT IN :request.excludedDriveIds
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked__Start__c, sked__End__c, sked_Start_Date__c, sked_End_Date__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,
                                              sked__Type__c
                                              FROM sked__Activities__r
                                              WHERE sked_Start_Date__c IN :request.allDates
                                              AND sked__Type__c NOT IN :excludedActivityTypes
                                              AND Id NOT IN :request.excludedActivityIds
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked__Start__c, sked__Finish__c, sked_Start_Date__c, sked_Finish_Date__c, sked__Is_Available__c, sked__Type__c
                                              FROM sked__Availabilities1__r
                                              WHERE sked__Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
                                              AND sked_Start_Date__c <= :request.maxDate AND sked_Finish_Date__c >= :request.minDate
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked_Start__c, sked_Finish__c, sked_Start_Date__c, sked_Finish_Date__c, sked_Is_Available__c
                                              FROM sked_Custom_Availabilities__r
                                              WHERE sked_Start_Date__c <= :request.maxDate AND sked_Finish_Date__c >= :request.minDate
                                              ORDER BY sked_Start__c ASC),
                                             
                                             (SELECT Id , sked__Start__c, sked__End__c, sked_Start_Date__c, sked_End_Date__c, sked__Availability_Pattern__r.sked__Pattern__c,sked__Availability_Pattern__r.Name,sked_Start_Time__c,sked_End_Time__c
                                              FROM sked__Availability_Pattern_Resources__r
                                              WHERE sked_Start_Date__c <= :request.maxDate
                                              AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :request.minDate)),
                                             
                                             (SELECT Id, sked__Activity__c, sked_Start1__c, sked_End__c, sked_Start_Date__c, sked_End_Date__c
                                              FROM sked__Activity_Resources__r
                                              WHERE sked__Activity__r.sked_Start_Date__c <= :request.maxDate
                                              AND sked__Activity__r.sked_End_Date__c >= :request.minDate
                                              AND sked__Activity__r.sked__Type__c NOT IN :excludedActivityTypes
                                              AND sked__Activity__c NOT IN :request.excludedActivityIds),
                                             
                                             (SELECT Id, sked_Resource__c, sked_Biomed_Collection_Op_Center__c, sked_Start_Date__c, sked_End_Date__c
                                              FROM sked_Resource_Biomed_Collection_Ops__r
                                              WHERE (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :request.maxDate) 
                                              AND (sked_End_Date__c = NULL OR sked_End_Date__c  >= :request.minDate))
                                             
                                             FROM sked__Resource__c
                                             WHERE sked_Asset_Type__c != NULL
                                             AND (
                                                 Id IN :request.allocatedResourceIds
                                                 OR (
                                                     (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds 
                                                      OR Id IN :request.additionalResourceIds)
                                                     AND (
                                                         sked__Is_Active__c = TRUE
                                                         AND (sked_Effective_Date__c = NULL OR sked_Effective_Date__c <= :request.maxDate)
                                                     )
                                                 )
                                             )
                                             ORDER BY Name
                                             LIMIT :request.pageSize
                                             OFFSET :request.offset];
        return resources;
    }
    
    private static Integer numberOfResources(getResourceDataRequestModel request) {
        AggregateResult aggResult = [SELECT count(Id) numberOfResource
                                     FROM sked__Resource__c
                                     WHERE Id IN :request.allocatedResourceIds
                                     OR 
                                     (
                                         (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds 
                                          OR Id IN :request.additionalResourceIds)
                                         AND (
                                             (sked__Resource_Type__c = 'Person' AND sked_Employment_Status__c = 'Active') 
                                             OR (
                                                 sked__Resource_Type__c = 'Person' 
                                                 AND sked_Employment_Status__c = 'Leave' 
                                                 AND sked_Anticipated_Leave_Return_Date__c <= :request.maxDate
                                             )
                                             OR (
                                                 sked__Resource_Type__c = 'Asset' 
                                                 AND sked__Is_Active__c = TRUE
                                                 AND (sked_Effective_Date__c = NULL OR sked_Effective_Date__c <= :request.maxDate)
                                             )
                                         )
                                         AND (sked_Termination_Date__c = NULL OR sked_Termination_Date__c > :request.minDate)
                                         AND (sked_Planned_Termination_Date__c = NULL OR sked_Planned_Termination_Date__c > :request.minDate)
                                     )];
        return (integer)aggResult.get('numberOfResource');
    }
    
    private static Integer numberOfAssets(getResourceDataRequestModel request) {
        AggregateResult aggResult = [SELECT count(Id) numberOfAssets
                                     FROM sked__Resource__c
                                     WHERE sked_Asset_Type__c != NULL
                                     AND (
                                         Id IN :request.allocatedResourceIds
                                         OR (
                                             (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds 
                                              OR Id IN :request.additionalResourceIds)
                                             AND (
                                                 sked__Is_Active__c = TRUE
                                                 AND (sked_Effective_Date__c = NULL OR sked_Effective_Date__c <= :request.maxDate)
                                             )
                                         )
                                     )];
        return (integer)aggResult.get('numberOfAssets');
    }
    
    /*********************************************************** Nested Classes ***********************************************************/
    public class getResourceDataRequestModel {
        @AuraEnabled public List<string> accountIds {get;set;}
        @AuraEnabled public List<string> collectionOperationIds {get;set;}
        @AuraEnabled public List<string> arcRegionIds {get;set;}
        @AuraEnabled public List<string> excludedActivityIds {get;set;}
        @AuraEnabled public List<string> excludedDriveIds {get;set;}
        @AuraEnabled public List<string> locationIds {get;set;}
        @AuraEnabled public List<string> inputDates {get;set;}
        @AuraEnabled public List<string> jobIds {get;set;}
        @AuraEnabled public List<string> recordIds {get;set;}
        @AuraEnabled public integer pageSize {get;set;}
        @AuraEnabled public integer pageNo {get;set;}
        @AuraEnabled public string timezoneSidId {get;set;}
        @AuraEnabled public boolean getAssetsOnly {get;set;}
        
        public List<Date> allDates;
        public List<string> additionalResourceIds;
        public List<string> allocatedResourceIds;
        public Date maxDate;
        public Date minDate;            
        public DateTime maxTurnAroundDateTime;
        public DateTime minTurnAroundDateTime;
        public integer offset;
    }
    
    public class resourceDataModel {
        @AuraEnabled public object availabilityPatterns {get;set;}
        @AuraEnabled public object calloutJobAllocations {get;set;}
        @AuraEnabled public object groupActivities {get;set;}
        @AuraEnabled public object resources {get;set;}
        @AuraEnabled public object resourceOverrides {get;set;}
        @AuraEnabled public object totalRecords {get;set;}
        @AuraEnabled public object resourceHoursRecordDetails {get;set;}
        @AuraEnabled public object tradedJobAllocations {get;set;}
        @AuraEnabled public object prevCancelledJobAllocations {get;set;}
    }
    
}