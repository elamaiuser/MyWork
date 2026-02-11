global class slwcResourceService {
    
    @AuraEnabled
    public static slwcAuraResult getResourceData(getResourceDataRequestModel request) {
        slwcAuraResult result = new slwcAuraResult();
        
        string timezoneSidId = !string.isBlank(request.timezoneSidId) ? request.timezoneSidId : UserInfo.getTimeZone().getID();
        
        List<Date> inputDates = new List<Date>();
        for (string inputDate : request.inputDates) {
            inputDates.add(skedDateTimeUtils.getDateFromIsoString(inputDate));
        }
        
        List<Date> allDates = new List<Date>(inputDates);
        allDates.sort();
        Date minDate = allDates[0];
        Date maxDate = allDates[allDates.size() - 1];
        
        DateTime expiryTagDate = skedDateTimeUtils.getStartOfDate(minDate, timezoneSidId);
        
        Set<Id> overrideResourceIds = new Set<Id>();
        if (request.collectionOperationIds != NULL && !request.collectionOperationIds.isEmpty()) {
            List<sked__Resource_Override_Region__c> resourceOverrideRegions = [SELECT Id, sked__Resource_Override__r.sked__Resource__c 
                                                                               FROM sked__Resource_Override_Region__c 
                                                                               WHERE sked__Region__r.sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds
                                                                               AND (DAY_ONLY(sked__Resource_Override__r.sked__Start__c) IN :inputDates 
                                                                                    OR DAY_ONLY(sked__Resource_Override__r.sked__End__c) IN :inputDates)];
            if (resourceOverrideRegions != NULL && !resourceOverrideRegions.isEmpty()) {
                for (sked__Resource_Override_Region__c resourceOverrideRegion : resourceOverrideRegions) {
                    overrideResourceIds.add(resourceOverrideRegion.sked__Resource_Override__r.sked__Resource__c);
                }
            }
        }
        
        Integer offset = (request.pageNo - 1) * request.pageSize;
        List<sked__Resource__c> resources = [SELECT Id, Name, sked__Email__c, sked__User__c, sked__Primary_Region__c, sked__Home_Address__c, 
                                             sked__GeoLocation__Longitude__s, sked__GeoLocation__Latitude__s,
                                             sked__Category__c, sked__User__r.SmallPhotoUrl, 
                                             sked__Primary_Phone__c, sked__Primary_Region__r.sked__Timezone__c,
                                             
                                             (SELECT Id, Name, sked__Description__c, sked__End__c, sked__GeoLocation__c, sked__GeoLocation__Longitude__s, 
                                              sked__GeoLocation__Latitude__s, sked__Home_Address__c, sked__Resource__c, sked__Start__c 
                                              FROM sked__Resource_Overrides__r
                                              WHERE sked__Start__c < :maxDate AND sked__End__c > :minDate),
                                             
                                             (SELECT Id, Name, sked__Tag__c, sked__Tag__r.Name, sked_Start_Date__c, sked_Expiry_Date__c, sked__Tag__r.sked__Type__c
                                              FROM sked__ResourceTags__r
                                              WHERE sked_Start_Date__c <= :maxDate
                                              AND (sked_Expiry_Date__c = NULL OR sked_Expiry_Date__c >= :minDate)
                                              AND (sked_Role_Status__c = NULL OR sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE)),
                                             
                                             (SELECT Id, Name, sked__Job__c, sked__Job__r.Name, sked__Job__r.sked__Start__c, sked__Job__r.sked__Finish__c,
                                              sked__Job__r.sked__GeoLocation__Latitude__s, sked__Job__r.sked__GeoLocation__Longitude__s, 
                                              sked__Job__r.sked__Type__c, sked__Status__c
                                              FROM sked__Job_Allocations__r
                                              WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                              AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                              AND (DAY_ONLY(sked__Job__r.sked__Start__c) IN :inputDates
                                                   OR DAY_ONLY(sked__Job__r.sked__Finish__c) IN :inputDates)
                                              ORDER BY sked__Job__r.sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked__Start__c, sked__End__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,
                                              sked__Type__c, sked_Subtype__c
                                              FROM sked__Activities__r
                                              WHERE DAY_ONLY(sked__Start__c) IN :inputDates
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked__Start__c, sked__Finish__c, sked__Is_Available__c, sked__Type__c
                                              FROM sked__Availabilities1__r
                                              WHERE DAY_ONLY(sked__Start__c) <= :maxDate AND DAY_ONLY(sked__Finish__c) >= :minDate
                                              ORDER BY sked__Start__c ASC),
                                             
                                             (SELECT Id, Name, sked_Start__c, sked_Finish__c, sked_Is_Available__c, sked_Type__c
                                              FROM sked_Custom_Availabilities__r
                                              WHERE DAY_ONLY(sked_Start__c) <= :maxDate AND DAY_ONLY(sked_Finish__c) >= :minDate
                                              ORDER BY sked_Start__c ASC),
                                             
                                             (SELECT Id , sked__Start__c, sked__End__c, sked__Availability_Pattern__r.sked__Pattern__c,sked__Availability_Pattern__r.name
                                              FROM sked__Availability_Pattern_Resources__r
                                              WHERE DAY_ONLY(sked__Start__c) <= :maxDate
                                              AND (sked__End__c = NULL OR DAY_ONLY(sked__End__c) >= :minDate)),
                                             
                                             (SELECT Id, sked__Activity__c
                                              FROM sked__Activity_Resources__r
                                              WHERE DAY_ONLY(sked__Activity__r.sked__Start__c) <= :maxDate
                                              AND DAY_ONLY(sked__Activity__r.sked__End__c) >= :minDate)
                                             
                                             FROM sked__Resource__c
                                             WHERE (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds 
                                                    OR Id IN :overrideResourceIds)
                                             AND sked__Is_Active__c = TRUE
                                             ORDER BY Name
                                             LIMIT :request.pageSize
                                             OFFSET :offset];
        
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
        
        resourceDataModel data = new resourceDataModel();
        data.resources = resources;
        if (!groupActivityIds.isEmpty()) {
            data.groupActivities = [SELECT Id, Name, sked__Start__c, sked__End__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s
                                    FROM sked__Activity__c
                                    WHERE Id IN :groupActivityIds];  
        }
        if (!availabilityPatternIds.isEmpty()) {
            data.availabilityPatterns = [SELECT Id, Name, sked__Pattern__c
                                         FROM sked__Availability_Pattern__c
                                         WHERE Id IN :availabilityPatternIds];  
        }
        if (request.pageNo == 1) {
            AggregateResult aggResult = [SELECT count(Id) numberOfResource
                                         FROM sked__Resource__c
                                         WHERE (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :request.collectionOperationIds 
                                                OR Id IN :overrideResourceIds)
                                         AND sked__Resource_Type__c = :slwcConstants.RESOURCE_TYPE_PERSON
                                         AND sked__Is_Active__c = TRUE];
            data.totalRecords = (integer)aggResult.get('numberOfResource');
        }
        result.returnedData = data;
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult saveCallOut(saveCallOutRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        
        slwcAuraResult result = new slwcAuraResult();
        
        if (string.isBlank(request.id)) {
            createCallOut(request);
        }
        else {
            editCallOut(request);
        }
        
        return result;
    }
    
    private static void createCallOut(saveCallOutRequestModel request) {
        DateTime currentTime = system.now();
        
        DateTime unavailabilityStart;
        DateTime unavailabilityEnd;
        String unavailabilityTimezone;
        List<String> notes = new List<String>();
        
        if (!string.isBlank(request.jobId)) {
            List<sked__Job_Allocation__c> jobAllocationQuery = [
                SELECT Id, sked_Job_Timezone__c, sked__Start__c, sked__Set_End__c,
                    sked__Job__r.sked_Drive__r.sked_UFID__c, sked__Resource__r.sked_Timezone__c, sked__Job__r.sked_Drive__r.sked_Timezone__c,
                    (SELECT Id,  sked_Early_Departure_Date_Received__c, sked_Early_Departure_DateTime_Received__c,
                        sked_Early_Departure_Time_Received__c, sked_Early_Departure_Reasons__c, 
                        sked_Late_Arrival_Date_Received__c, sked_Late_Arrival_DateTime_Received__c, 
                        sked_Late_Arrival_Reasons__c, sked_Late_Arrival_Time_Received__c
                    FROM sked_Operation_Record_Staff__r)
                FROM sked__Job_Allocation__c
                WHERE sked__Job__c = :request.jobId
                AND sked__Resource__c = :request.resourceId
                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            ];
            
            if (!jobAllocationQuery.isEmpty()) {
                sked__Job_Allocation__c jobAllocation = jobAllocationQuery.get(0);
                request.jobAllocationId = jobAllocation.Id;
                
                jobAllocation.sked_Call_Out_Notes__c = request.callOutNotes;
                jobAllocation.sked_Call_Out_Reason_Code__c = request.callOutReason;
                jobAllocation.sked_Call_Out_Reported__c = request.callOutReported;
                jobAllocation.sked_Call_Out_Type__c = request.callOutType;
                jobAllocation.sked_DateTime_Call_Out_Received__c = request.callOutReceivedDateTime;
                if (request.calloutType == skedConstants.AVAILABILITY_CALLOUT_TYPE_CALL_OUT) {
                    jobAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
                }
                update jobAllocation;

                unavailabilityStart = jobAllocation.sked__Start__c;
                unavailabilityEnd = jobAllocation.sked__Set_End__c;
                unavailabilityTimezone = jobAllocation.sked__Resource__r.sked_Timezone__c;
                
                if (!string.isBlank(jobAllocation.sked__Job__r.sked_Drive__r.sked_UFID__c)) {
                    notes.add(jobAllocation.sked__Job__r.sked_Drive__r.sked_UFID__c);
                }
            }
        }
        else if (!string.isBlank(request.activityId)) {
            List<sked__Activity_Resource__c> activityResourceQuery = [
                SELECT Id, sked__Activity__r.sked__Start__c, sked__Activity__r.sked__Timezone__c,
                sked__Activity__r.sked__End__c, sked__Resource__r.sked_Timezone__c
                FROM sked__Activity_Resource__c
                WHERE sked__Activity__c = :request.activityId
                AND sked__Resource__c = :request.resourceId
            ];
            
            if (!activityResourceQuery.isEmpty()) {
                sked__Activity_Resource__c activityResource = activityResourceQuery.get(0);
                unavailabilityStart = activityResource.sked__Activity__r.sked__Start__c;
                unavailabilityEnd = activityResource.sked__Activity__r.sked__End__c;
                unavailabilityTimezone = activityResource.sked__Resource__r.sked_Timezone__c;
                
                if (request.calloutType == skedConstants.AVAILABILITY_CALLOUT_TYPE_CALL_OUT) {
                    delete activityResource;
                }
            }
        }
        
        sked__Availability__c callOutAvailability = new sked__Availability__c(
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_CALL_OUT,
            sked__Is_Available__c = FALSE,
            sked__Finish__c = unavailabilityEnd,
            sked__Start__c = unavailabilityStart,
            sked__Resource__c = request.resourceId,
            sked__Notes__c = request.callOutNotes,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked__Timezone__c = unavailabilityTimezone,
            sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked_Call_Out_For_Activity__c = request.activityId,
            sked_Call_Out_For_Job_Allocation__c = request.jobAllocationId,
            sked_Call_Out_Notes__c = request.callOutNotes,
            sked_Call_Out_Reason_Code__c = request.callOutReason,
            sked_Call_Out_Reported__c = request.callOutReported != NULL ? request.callOutReported : FALSE,
            sked_Call_Out_Type__c = request.callOutType,
            sked_DateTime_Call_Out_Received__c = request.callOutReceivedDateTime,
            sked_DateTime_of_Call_Out__c = currentTime,
            sked_Time_Off_Plan__c = request.timeOffPlan,
            sked_Time_Off_Reason_Code__c = request.timeOffReasonCode            
        );

        if (request.calloutType == skedConstants.AVAILABILITY_CALLOUT_TYPE_CALL_OUT) {
            Date callOutDate = unavailabilityStart.date();
            DateTime callOutFinish = skedDateTimeUtils.getEndOfDate(callOutDate, unavailabilityTimezone);
            callOutAvailability.sked_Is_All_Day__c = true;
            callOutAvailability.sked__Start__c = skedDateTimeUtils.getStartOfDate(callOutDate, unavailabilityTimezone);
            callOutAvailability.sked__Finish__c = callOutFinish.addMinutes(-1);
        }

        if (request.usePtoForCallOut == false || request.usePtoForCallOut == null) {
            callOutAvailability.sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_NA;
            callOutAvailability.sked_Workday_Sync_Message__c = request.hasTimeOffPlans ? 'User chose to not submit time off' : 'No time off plan for workday sync';
            callOutAvailability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
            callOutAvailability.sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
        }

        if (callOutAvailability.sked_DateTime_of_Call_Out__c != NULL && callOutAvailability.sked__Start__c != NULL) {
            callOutAvailability.sked_Call_Out_Notice__c = skedDateTimeUtils.getDifferentMinutesText(callOutAvailability.sked_DateTime_of_Call_Out__c, callOutAvailability.sked__Start__c);
        	skedTriggerUtils.maintainDateTimeField(callOutAvailability, 'sked_DateTime_of_Call_Out__c', 'sked_Date_of_Call_Out__c', 'sked_Time_of_Call_Out__c', 'sked__Timezone__c');
        }
        
        if (!notes.isEmpty()) {
            String driveUFIDNotes = String.join(notes, ' - ');
            if (!string.isBlank(callOutAvailability.sked__Notes__c)) {
                callOutAvailability.sked__Notes__c = driveUFIDNotes + '. ' + callOutAvailability.sked__Notes__c;
            }
        }
        insert callOutAvailability;
        
        sked__Availability__c relatedAvailability = new sked__Availability__c(
            sked__Type__c = request.timeOffPlan,
            sked__Is_Available__c = FALSE,
            sked__Finish__c = unavailabilityEnd,
            sked__Start__c = unavailabilityStart,
            sked__Resource__c = request.resourceId,
            sked__Notes__c = request.callOutNotes,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_PENDING,
            sked__Timezone__c = unavailabilityTimezone,
            sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PROCESSING_APPROVAL,
            sked_Time_Off_Reason_Code__c = request.timeOffReasonCode,
            sked_Related_Call_Out__c = callOutAvailability.Id
        );
        insert relatedAvailability;
    }
    
    private static void editCallOut(saveCallOutRequestModel request) {
        sked__Availability__c skedAvail = [SELECT Id, sked_Call_Out_For_Job_Allocation__c,
                                           sked__Notes__c, sked_Call_Out_Notes__c, sked_Call_Out_Reason_Code__c, sked_Call_Out_Type__c
                                           FROM sked__Availability__c
                                           WHERE Id = :request.id];
        
        skedAvail.sked__Notes__c = request.callOutNotes;
        skedAvail.sked_Call_Out_Notes__c = request.callOutNotes;
        skedAvail.sked_Call_Out_Reason_Code__c = request.callOutReason;
        skedAvail.sked_Call_Out_Type__c = request.callOutType;
        update skedAvail;
        
        if (skedAvail.sked_Call_Out_For_Job_Allocation__c != NULL) {
            update new sked__Job_Allocation__c(
            	Id = skedAvail.sked_Call_Out_For_Job_Allocation__c,
                sked_Call_Out_Notes__c = request.callOutNotes,
                sked_Call_Out_Reason_Code__c = request.callOutReason,
                sked_Call_Out_Type__c = request.callOutType
            );
        }
    }
    
    /*********************************************************** Nested Classes ***********************************************************/
    public class getResourceDataRequestModel {
        @AuraEnabled public List<string> collectionOperationIds {get;set;}
        @AuraEnabled public List<string> inputDates {get;set;}
        @AuraEnabled public integer pageSize {get;set;}
        @AuraEnabled public integer pageNo {get;set;}
        @AuraEnabled public string timezoneSidId {get;set;}
    }
    
    global class saveCallOutRequestModel {
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public string activityId {get;set;}
        @AuraEnabled public string jobId {get;set;}
        @AuraEnabled public string resourceId {get;set;}
        @AuraEnabled public string callOutReason {get;set;}
        @AuraEnabled public DateTime callOutReceivedDateTime {get;set;}
        @AuraEnabled public string callOutNotes {get;set;}
        @AuraEnabled public boolean callOutReported {get;set;}
        @AuraEnabled public string callOutType {get;set;}
        @AuraEnabled public string timeOffPlan {get;set;}
        @AuraEnabled public string timeOffReasonCode {get;set;}
        @AuraEnabled public boolean usePtoForCallOut {get;set;}
        @AuraEnabled public boolean hasTimeOffPlans {get;set;}
        
        @AuraEnabled public string jobAllocationId {get;set;}
    }
    
    public class resourceDataModel {
        @AuraEnabled public object availabilityPatterns {get;set;}
        @AuraEnabled public object groupActivities {get;set;}
        @AuraEnabled public object resources {get;set;}
        @AuraEnabled public object totalRecords {get;set;}
    }

}