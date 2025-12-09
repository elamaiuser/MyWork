public class skedStaffingBudgetUtils implements Callable {

    public static void publishAutofillEvent(Set<Id> staffingBudgetIds) {
        skedFutureCallEventHandler.publishFutureCallEvent(
            'skedStaffingBudgetUtils',
            'autofillStaffingBudgetSlotsFromWaitlist',
            staffingBudgetIds
        );
    }

    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'autofillStaffingBudgetSlotsFromWaitlist' {
                    autofillStaffingBudgetSlotsFromWaitlistFuture((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedStaffingBudgetUtils.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }
        return result;
    }

    public static Map<Date, List<skedStaffingBudgetWrapper>> getSkedStaffingBudgetWrappersByDate(Map<Id, Set<Date>> datesByResourceId, Map<Id, sked__Resource__c> resourceById) {
        Map<Date, List<skedStaffingBudgetWrapper>> skedStaffingBudgetWrappersByDate = new Map<Date, List<skedStaffingBudgetWrapper>>();
        string fccCodesFixedSite = skedSetting.instance.Admin.fccCodeFixedSite;
        string fccCodesMobile = skedSetting.instance.Admin.fccCodeMobile;

        if (!datesByResourceId.keySet().isEmpty()) {
            skedQueryBuilder queryBuilder = new skedQueryBuilder();
            queryBuilder.addFields(new List<String>{
                'Id', 'sked_Staffing_Budget__c',
                'sked_Staffing_Budget__r.sked_Drive_Types__c', 'sked_Staffing_Budget__r.sked_Roles__c', 'sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c',
                'sked_Staffing_Budget__r.sked_Request_Type__c', 'sked_Staffing_Budget__r.sked_Total_Slots__c',
                'sked_Staffing_Budget__r.sked_Available_Slots__c', 'sked_Staffing_Budget__r.sked_Approved_Slots_Rollup__c',
                'sked_Staffing_Budget__r.sked_Bidding_Start_Date__c', 'sked_Staffing_Budget__r.sked_Bidding_End_Date__c'
            });
            queryBuilder.setIsOrQuery(true);

            List<List<string>> conditionGroups = new List<List<string>>();
            for (Id resourceId : datesByResourceId.keySet()) { 
                Boolean isResourcePreferredToFS = FALSE;
                sked__Resource__c resource = resourceById.get(resourceId);
                if(resource.sked__Location_Resource_Scores__r != NULL && !resource.sked__Location_Resource_Scores__r.isEmpty()) {
                    isResourcePreferredToFS = TRUE;
                    queryBuilder.setFromClause('sked_Staffing_Budget_Site__c');
                    queryBuilder.addFields(new List<String> {'sked_Location__c', 'sked_Location__r.Name'});
                } else {
                    queryBuilder.setFromClause('sked_Staffing_Budget_Collection_Op__c');
                    queryBuilder.addFields(new List<String> {'sked_Biomed_Collection_Operation__c', 'sked_Biomed_Collection_Operation__r.sked_Waitlist_Enabled__c'});
                }
                
                Id resourceCollectionOpId;
                List<String> resourcePrimaryRole = new List<String>();
                List<string> driveTypes = new List<string>();
                List<String> preferredFixedSiteIds = new List<String>();

                if(isResourcePreferredToFS) {
                    for(sked__Location_Resource_Score__c locationResourceScore : resource.sked__Location_Resource_Scores__r) {
                        preferredFixedSiteIds.add(locationResourceScore.sked__Location__c);
                    }
                }
                if (resource.sked__Primary_Region__r != NULL) {
                    resourceCollectionOpId = resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
                }
                if (resource.sked__ResourceTags__r != NULL && !resource.sked__ResourceTags__r.isEmpty()) {
                    Decimal priority =
                            resource.sked__ResourceTags__r.get(0).sked__Tag__r.sked_Priority__c != null ?
                            resource.sked__ResourceTags__r.get(0).sked__Tag__r.sked_Priority__c : 0;

                        for(sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r){
                        if(resourceTag.sked__Tag__r.Name != null && (priority == 0 || resourceTag.sked__Tag__r.sked_Priority__c == priority) ){
                            resourcePrimaryRole.add(resourceTag.sked__Tag__r.Name);
                        }
                    }
                }    
                if (resource.sked_FCC_Code__c != NULL) {
                    List<string> resourceFccCodes = new List<string>();
                    resourceFccCodes = resource.sked_FCC_Code__c.split(';');
                    for (string resourceFccCode : resourceFccCodes) {
                        if (fccCodesFixedSite.contains(resourceFccCode)) {
                            driveTypes.add(skedConstants.DRIVE_TYPE_FIXED_SITE);
                        }
                        if (fccCodesMobile.contains(resourceFccCode)) {
                            driveTypes.add(skedConstants.DRIVE_TYPE_MOBILE);
                        }
                    }
                }
                
                if ((resourceCollectionOpId != NULL || !preferredFixedSiteIds.isEmpty()) && resourcePrimaryRole != NULL) {
                    Set<Date> dates = datesByResourceId.get(resourceId);
                    String siteCondition = queryBuilder.generateCondition('sked_location__c IN {0}', preferredFixedSiteIds);
                    String collectionOpCondition = queryBuilder.generateCondition('sked_Biomed_Collection_Operation__c = {0}', resourceCollectionOpId);
                    String driveTypesCondition = queryBuilder.generateMSPCondition('sked_Staffing_Budget__r.sked_Drive_Types__c INCLUDES {0}', driveTypes);
                    String rolesCondition = queryBuilder.generateMSPCondition('sked_Staffing_Budget__r.sked_Roles__c INCLUDES {0}', resourcePrimaryRole);
                    String datesCondition = queryBuilder.generateCondition('sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c IN {0}', dates);
                    
                    List<string> conditions = new List<String>();
                    conditions.add(isResourcePreferredToFS ? siteCondition : collectionOpCondition);
                    conditions.add(driveTypesCondition);
                    conditions.add(rolesCondition);
                    conditions.add(datesCondition);
                    conditionGroups.add(conditions);
                }
            }

            if (!conditionGroups.isEmpty()) {
                for (List<String> conditionGroup : conditionGroups) {
                    queryBuilder.addConditionGroup(conditionGroup);
                }
                
                string relatedSobjectQueryStr = queryBuilder.toString();
                Map<Id, skedStaffingBudgetWrapper> wrapperById = new Map<Id, skedStaffingBudgetWrapper>();
                for (sObject sbRelatedObj : Database.query(relatedSobjectQueryStr)) {
                    String sobjectType = sbRelatedObj.getSObjectType().getDescribe().getName();
                    skedStaffingBudgetWrapper wrapper = wrapperById.get((Id) sbRelatedObj.get('sked_Staffing_Budget__c'));
                    if (wrapper == null) {
                        wrapper = new skedStaffingBudgetWrapper();
                        wrapper.staffingBudget = (sked_Staffing_Budget__c) sbRelatedObj.getsObject('sked_Staffing_Budget__r');
                        wrapper.approvedSlots = wrapper.staffingBudget.sked_Approved_Slots_Rollup__c;
                        wrapper.totalSlots = wrapper.staffingBudget.sked_Total_Slots__c;
                    }
                    if(sobjectType == 'sked_Staffing_Budget_Collection_Op__c') {
                        wrapper.collectionOpById.put((Id) sbRelatedObj.get('sked_Biomed_Collection_Operation__c'), (Biomed_Collection_Op_Center__c) sbRelatedObj.getsObject('sked_Biomed_Collection_Operation__r'));
                    } else if(sobjectType == 'sked_Staffing_Budget_Site__c') {
                        wrapper.siteById.put((Id) sbRelatedObj.get('sked_Location__c'), (sked__Location__c) sbRelatedObj.getsObject('sked_Location__r'));
                    }
                    
                    wrapperById.put(wrapper.recordId, wrapper);
                }

                for (Id wrapperId : wrapperById.keySet()) {
                    skedStaffingBudgetWrapper wrapper = wrapperById.get(wrapperId);
                    List<skedStaffingBudgetWrapper> wrappersForDate = skedStaffingBudgetWrappersByDate.get(wrapper.staffingBudget.sked_Staffing_Budget_Date__c);
                    if (wrappersForDate == NULL) {
                        wrappersForDate = new List<skedStaffingBudgetWrapper>();
                        skedStaffingBudgetWrappersByDate.put(wrapper.staffingBudget.sked_Staffing_Budget_Date__c, wrappersForDate);
                    }
                    wrappersForDate.add(wrapper);
                }
                
                if (!wrapperById.keySet().isEmpty()) {
                    skedStaffingBudgetService.queryModel query = new skedStaffingBudgetService.queryModel();
                    query.recordIds = new List<Id>(wrapperById.keySet());
                    query.subQueryIndicator = skedSObjectType.STAFFING_BUDGET_COLLECTION_OP | skedSObjectType.STAFFING_BUDGET_SITE;

                    skedStaffingBudgetService service = (skedStaffingBudgetService)skedServiceFactory.instance.resolve('sked_Staffing_Budget__c');
                    List<sked_Staffing_Budget__c> staffingBudgets = service.query(query);

                    for (sked_Staffing_Budget__c sb : staffingBudgets) {
                        if (wrapperById.containsKey(sb.Id)) {
                            skedStaffingBudgetWrapper wrapper = wrapperById.get(sb.Id);
                            wrapper.staffingBudget = sb;

                        }
                    }
                }
            }
        }

        return skedStaffingBudgetWrappersByDate;
    }

    public static void updateAvailabilityBiddingType(Set<Id> availabilityIds) {
        List<sked__Availability__c> availabilityToUpdates = new List<sked__Availability__c>();
        for (sked__Availability__c availability : [
            SELECT Id,
            (
                SELECT Id
                FROM sked_Staffing_Budget_Availabilities__r
                WHERE sked_Staffing_Budget__r.sked_Request_Type__c = :skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT
            )
            FROM sked__Availability__c
            WHERE Id IN :availabilityIds
        ]) {
            availability.sked_Bidding_Type__c = !availability.sked_Staffing_Budget_Availabilities__r.isEmpty() ?
                                                    skedConstants.AVAILABILITY_BIDDING_TYPE_BIDDING : skedConstants.AVAILABILITY_BIDDING_TYPE_STANDARD;
            availabilityToUpdates.add(availability);
        }

        if (!availabilityToUpdates.isEmpty()) {
            skedHubBase.setBypassAllTriggers(true);
            update availabilityToUpdates;
            skedHubBase.setBypassAllTriggers(false);
        }
    }

    public static void updateAvailabilityBiddingTypeByStaffingBudgets(Set<Id> staffingBudgetIds) {
        Set<Id> availabilityIds = new Set<Id>();
        for (sked_Staffing_Budget_Availability__c staffingBudgetAvailability : [
            SELECT sked_Availability__c
            FROM sked_Staffing_Budget_Availability__c
            WHERE sked_Staffing_Budget__c IN :staffingBudgetIds
        ]) {
            availabilityIds.add(staffingBudgetAvailability.sked_Availability__c);
        }

        if (!availabilityIds.isEmpty()) {
            updateAvailabilityBiddingType(availabilityIds);
        }
    }

    public static Map<Id, Set<Date>> getUnavailabilityDatesByResourceId(List<sked_Staffing_Budget_Availability__c> sbas, Map<Id, sked__Resource__c> resourceById) {
        Map<Id, Set<Date>> datesByResourceId = new Map<Id, Set<Date>>();
        for (sked_Staffing_Budget_Availability__c sba : sbas) {
            sked__Availability__c availability = sba.sked_Availability__r;
            sked__Resource__c availabilityResource = resourceById.get(availability.sked__Resource__c);
            Set<Date> datesForResource = datesByResourceId.get(availabilityResource.Id);
            if (datesForResource == null) {
                datesForResource = new Set<Date>();
            }

            Date availabilityDate = skedDateTimeUtils.getDate(availability.sked__Start__c, availabilityResource.sked__Primary_Region__r.sked__Timezone__c);
            datesForResource.add(availabilityDate);
            datesByResourceId.put(availabilityResource.Id, datesForResource);
        } 

        return datesByResourceId;
    }

    public static Map<Id, List<sked_Staffing_Budget_Availability__c>> getStaffingBudgetAvailabilitesByStaffingBudgetId(List<sked_Staffing_Budget_Availability__c> sbas) {
        Map<Id, List<sked_Staffing_Budget_Availability__c>> sbasBySb = new Map<Id, List<sked_Staffing_Budget_Availability__c>>();
        for (sked_Staffing_Budget_Availability__c sba : sbas) {
            List<sked_Staffing_Budget_Availability__c> sbasForSb = sbasBySb.get(sba.sked_Staffing_Budget__c);
            if (sbasForSb == NULL) {
                sbasForSb = new List<sked_Staffing_Budget_Availability__c>();
            }
            sbasForSb.add(sba);
            sbasBySb.put(sba.sked_Staffing_Budget__c, sbasForSb);
        }  

        return sbasBySb;
    }

    @future(Callout=true)
    public static void autoFillStaffingBudgetSlotsFromWaitlistFuture(Set<Id> staffingBudgetIds) {
        autofillStaffingBudgetSlotsFromWaitlist(staffingBudgetIds);
    }

    public static void autofillStaffingBudgetSlotsFromWaitlist(Set<Id> staffingBudgetIds) {
        Set<String> unavailabilityTypes = skedWorkdayUtils.getUnavailabilityTypesToSync();
        List<sked_Staffing_Budget_Availability__c> staffingBudgetAvailabilities = [
            SELECT Id, sked_Staffing_Budget__c, CreatedDate, sked_Availability__r.sked_Custom_Status__c, sked_Availability__r.sked__Start__c,
            sked_Availability__r.sked__Resource__c, sked_Availability__r.sked__Resource__r.sked_Collection_Operation_Id__c,
            sked_Availability__r.sked__Notes__c, sked_Availability__r.sked_Start_Date__c, sked_Availability__r.sked_Time_Off_Reason_Code__c,
            sked_Availability__r.sked__Type__c, sked_Availability__r.sked__Finish__c, sked_Availability__r.sked_Is_All_Day__c
            FROM sked_Staffing_Budget_Availability__c
            WHERE sked_Staffing_Budget__c IN :staffingBudgetIds
            AND sked_Availability__r.sked__Is_Available__c = FALSE
            AND sked_Availability__r.sked__Type__c IN :unavailabilityTypes
            AND sked_Availability__r.sked_Custom_Status__c IN :skedConstants.AVAILABILITY_PENDING_STATUSES
            AND sked_Availability__r.sked_Workday_Sync_Status__c NOT IN (:skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_FAILED, :skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_MANUAL)
            AND sked_Availability__r.sked__Start__c > TODAY
            AND sked_Availability__r.sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c != null
            AND sked_Staffing_Budget__r.sked_Request_Type__c = :skedConstants.STAFFING_BUDGET_REQUEST_TYPE_STANDARD
            ORDER BY sked_Availability__r.sked_Custom_Status__c DESC, CreatedDate ASC
        ];

        Set<Id> resourceIds = new Set<Id>();
        for (sked_Staffing_Budget_Availability__c sba : staffingBudgetAvailabilities) {
            resourceIds.add(sba.sked_Availability__r.sked__Resource__c);
        }

        Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>([
            SELECT Id, sked_Employee_Id__c, sked_Daily_Time_Off_Hours__c, sked__Primary_Region__c, sked_FCC_Code__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Auto_Approval_Cutoff_Days__c,
            sked__Primary_Region__r.sked__Timezone__c, 
            (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Tag__r.sked_Priority__c
             FROM sked__ResourceTags__r
             WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
             AND sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE
             ORDER BY sked__Tag__r.sked_Priority__c ASC NULLS LAST)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);

        Map<Id, Set<Date>> datesByResourceId = skedStaffingBudgetUtils.getUnavailabilityDatesByResourceId(staffingBudgetAvailabilities, resourceById);
        Map<Id, List<sked_Staffing_Budget_Availability__c>> sbasBySb = skedStaffingBudgetUtils.getStaffingBudgetAvailabilitesByStaffingBudgetId(staffingBudgetAvailabilities);
        Map<Date, List<skedStaffingBudgetWrapper>> staffingBudgetWrappersByDate = skedStaffingBudgetUtils.getSkedStaffingBudgetWrappersByDate(datesByResourceId, resourceById);
        Map<Id, Set<Date>> matchingJobAllocationDates = skedStaffingBudgetUtils.getMatchingJobAllocationDates(datesByResourceId);

        List<sked__Availability__c> availabilitiesToUpdate = new List<sked__Availability__c>();
        List<sked__Debug_Log__c> debugLogsToInsert = new List<sked__Debug_Log__c>();
        List<sked__Availability__c> failedApprovals = new List<sked__Availability__c>();
        for (sked_Staffing_Budget_Availability__c sba : staffingBudgetAvailabilities) {
            sked__Availability__c availability = sba.sked_Availability__r;
            sked__Resource__c availabilityResource = resourceById.get(availability.sked__Resource__c);
            Date unavailabilityDate = skedDateTimeUtils.getDate(availability.sked__Start__c, availabilityResource.sked__Primary_Region__r.sked__Timezone__c);
            if(skedStaffingBudgetUtils.isUnavailabilityDateMatchesJobAllocationDate(availabilityResource.Id, unavailabilityDate, matchingJobAllocationDates)){
                continue;
            }
            List<skedStaffingBudgetWrapper> slotsToConsumeIfAutoApproved = new List<skedStaffingBudgetWrapper>();
            Boolean isAutoApprovalCandidate = true;
            if (!skedStaffingBudgetUtils.isWithinCOAutoApprovalCutOffDays(availabilityResource, System.today(), unavailabilityDate)) {
                List<skedStaffingBudgetWrapper> sbwsForDate = staffingBudgetWrappersByDate.get(unavailabilityDate);
                if (sbwsForDate != null && !sbwsForDate.isEmpty()) {
                    for (skedStaffingBudgetWrapper staffingBudgetWrapper : sbwsForDate) {
                        List<String> staffingBudgetRoles = staffingBudgetWrapper.staffingBudget.sked_Roles__c.split(';');
                        if (staffingBudgetWrapper.collectionOpById.keySet().contains(availabilityResource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c)) {
                            Biomed_Collection_Op_Center__c co = staffingBudgetWrapper.collectionOpById.get(availabilityResource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c);
                            string resourcePrimaryRole = availabilityResource.sked__ResourceTags__r.get(0).sked__Tag__r.Name;

                            if (staffingBudgetRoles.contains(resourcePrimaryRole)) {
                                // Every relevant staffing budget must have a slot - if there is one that is full, they cannot have PTO
                                if (staffingBudgetWrapper.availableSlots == 0) {
                                    isAutoApprovalCandidate = false;
                                } else {
                                    slotsToConsumeIfAutoApproved.add(staffingBudgetWrapper);
                                }
                            }
                        }
                    }
                }
            }

            if (isAutoApprovalCandidate && !slotsToConsumeIfAutoApproved.isEmpty()) {
                skedWorkdayEnterTimeOffRequest enterTimeOffRequest = new skedWorkdayEnterTimeOffRequest();
                enterTimeOffRequest.employeeId = availabilityResource.sked_Employee_Id__c;
                enterTimeOffRequest.resourceId = availabilityResource.Id;
                skedWorkdayEnterTimeOffRequest.skedWorkdayTimeOffEntry timeOffEntry = new skedWorkdayEnterTimeOffRequest.skedWorkdayTimeOffEntry();
                timeOffEntry.comment = availability.sked__Notes__c;
                timeOffEntry.ptoDate = availability.sked_Start_Date__c;
                timeOffEntry.hoursRequested = skedWorkdayUtils.getWorkdayPtoHours(availability, availabilityResource); 
                timeOffEntry.ptoEntryId = availability.Id;
                timeOffEntry.timeOffType = availability.sked__Type__c;
                timeOffEntry.ptoReason = availability.sked_Time_Off_Reason_Code__c;
                enterTimeOffRequest.timeOffEntries.add(timeOffEntry);
                
                skedWorkdayEnterTimeOffResponse result = skedWorkdayApiManager.EnterTimeOff(enterTimeOffRequest);

                if (!result.isSuccess) {
                    availability.sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WD_SYNC_STATUS_FAILED;
                    availability.sked_Workday_Sync_Message__c = result.message;
                    availability.sked_Approval_Reason__c = skedConstants.AVAILABILITY_APPROVAL_REASON_WORKDAY_SYNC_FAILURE;
                    failedApprovals.add(availability);
                } else {
                    availability.sked_Approved_Via_Automation__c = true;
                    availability.sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WD_SYNC_STATUS_SUCCESS;
                    availability.sked_Custom_Status__c = availability.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_WAITLIST ?
                        skedConstants.AVAILABILITY_STATUS_APPROVED_FROM_WAITLIST : skedConstants.AVAILABILITY_STATUS_APPROVED_FROM_PENDING;
                    availability.sked_Workday_Sync_Message__c = null;

                    for (skedStaffingBudgetWrapper staffingBudgetWrapper : slotsToConsumeIfAutoApproved) {
                        staffingBudgetWrapper.approvedSlots++;
                    }
                }

                availabilitiesToUpdate.add(availability);
                debugLogsToInsert.add(skedWorkdayUtils.getDebugLogFromResponse('Enter Time Off', availability, result));
            }
        }

        if (!failedApprovals.isEmpty()) {
            new skedCustomNotificationService(new List<String>{
                'sked_Workday_Approval_Failed_Resource'
            }).generateNotifications(failedApprovals);
        }

        // Need to split the DMLs here to avoid chunking limit, cannot do this as a single list upsert
        if (!debugLogsToInsert.isEmpty()) {
            insert debugLogsToInsert;
        }

        if (!availabilitiesToUpdate.isEmpty()) {
            update availabilitiesToUpdate;
        }
    }

    public static Decimal getCOAutoApprovalCutOffDays(sked__Resource__c resource) {
        Decimal autoApprovalCutOffDays = resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Auto_Approval_Cutoff_Days__c;
        autoApprovalCutOffDays = autoApprovalCutOffDays != NULL ? autoApprovalCutOffDays : skedSetting.instance.RAC.autoApprovalCutoffDays;
        return autoApprovalCutOffDays;
    }

    public static boolean isWithinCOAutoApprovalCutOffDays(sked__Resource__c resource, Date currentDate, Date availabilityStartDate) {
        Decimal autoApprovalCutoffDays = getCOAutoApprovalCutOffDays(resource);
        return currentDate.daysBetween(availabilityStartDate) <= autoApprovalCutoffDays;
    }
    
    public static Map<Id, Set<Date>> getMatchingJobAllocationDates(Map<Id, Set<Date>> unavailabilityDatesByResourceIdMap) {
        List<string> excludedJobAllocationStatuses = new List<string> {skedConstants.JOB_ALLOCATION_STATUS_DECLINED, skedConstants.JOB_ALLOCATION_STATUS_DELETED};
        // Query job allocations for the resources
        List<sked__Job_Allocation__c> jobAllocations = [
            SELECT Id, sked_Start_Date__c, sked__Resource__c
            FROM sked__Job_Allocation__c
            WHERE sked__Resource__c IN :unavailabilityDatesByResourceIdMap.keySet()
            AND sked_Start_Date__c > TODAY
            AND sked__Status__c NOT IN :excludedJobAllocationStatuses
        ];

        // Create map to store allocation dates for each resource
        Map<Id, Set<Date>> jobAllocationDatesByResourceIdMap = new Map<Id, Set<Date>>();

        // Populate allocation dates map
        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
            if (!jobAllocationDatesByResourceIdMap.containsKey(jobAllocation.sked__Resource__c)) {
                jobAllocationDatesByResourceIdMap.put(jobAllocation.sked__Resource__c, new Set<Date>());
            }
            jobAllocationDatesByResourceIdMap.get(jobAllocation.sked__Resource__c).add(jobAllocation.sked_Start_Date__c);
        }

        // Find matching dates for each resource
        Map<Id, Set<Date>> matchingDatesMap = new Map<Id, Set<Date>>();
        for (Id resourceId : unavailabilityDatesByResourceIdMap.keySet()) {
            Set<Date> unAvailableDates = unavailabilityDatesByResourceIdMap.get(resourceId);
            Set<Date> jobAllocatedDates = jobAllocationDatesByResourceIdMap.get(resourceId);
            
            if (jobAllocatedDates != null) {
                Set<Date> matchingDates = new Set<Date>(unAvailableDates);
                matchingDates.retainAll(jobAllocatedDates);
                if (!matchingDates.isEmpty()) {
                    matchingDatesMap.put(resourceId, matchingDates);
                }
            }
        }
        return matchingDatesMap; 
    }

    public static boolean isUnavailabilityDateMatchesJobAllocationDate(Id resourceId, Date unAvailabilityDate, Map<Id, Set<Date>> matchingDatesMap) {
        if(matchingDatesMap.containsKey(resourceId)) {
            Set<Date> matchingDates = matchingDatesMap.get(resourceId);
            return matchingDates.contains(unAvailabilityDate);
        }
        return false;
    }
}