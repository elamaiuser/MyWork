global class slwcDriveShiftTradeService {
    
    @AuraEnabled
    public static slwcAuraResult validateRequest(driveShiftTradeModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        
        initialize(request);
        doValidateRequest(request);
        
        List<string> hardViolationContentions = getHardViolationContentions();
        
        List<contentionModel> contentions = new List<contentionModel>();
        for (string contentionMsg : request.reasonApprovalRequired) {
            contentionModel contention = new contentionModel();
            contention.contention = contentionMsg;
            contention.hardViolation = hardViolationContentions.contains(contentionMsg);
            contentions.add(contention);
        }
        
        result.returnedData = contentions;
        return result;
    }
    
    public static void autoProcessRequest(sked_Drive_Shift_Trade__c skedTrade) {
        driveShiftTradeModel request = prepareDriveShiftTradeRequest(skedTrade);
        
        initialize(request);
        doValidateRequest(request);
        populateTravelDistance(request);
        
        sked_Drive_Shift_Trade__c recordToSave = new sked_Drive_Shift_Trade__c(
        	Id = skedTrade.Id
        );
        
        Map<string, string> map_hardViolationContention_DeniedReason = new Map<string, string>();
        map_hardViolationContention_DeniedReason.put(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_CUTOFF_REQUIREMENT, skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_CUTOFF_DAYS);
        map_hardViolationContention_DeniedReason.put(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DUPLICATE_TRADE, skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_DUPLICATE);
        map_hardViolationContention_DeniedReason.put(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DUPLICATE_TRADE, skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_DUPLICATE);
        
        for (string hardViolationContention : map_hardViolationContention_DeniedReason.keySet()) {
            if (request.reasonApprovalRequired.contains(hardViolationContention)) {
                recordToSave.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED;
                recordToSave.sked_Denied_Reason__c = map_hardViolationContention_DeniedReason.get(hardViolationContention);
                break;
            }
        }
        
        if (recordToSave.sked_Status__c != skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED) {
            recordToSave.sked_RequestingStaffScheduledHoursBefore__c = request.requestingStaffScheduledHoursBefore;
            recordToSave.sked_RequestingStaffScheduledHoursAfter__c = request.requestingStaffScheduledHoursAfter;
            recordToSave.sked_TradingStaff_Scheduled_Hours_Before__c = request.tradingStaffScheduledHoursBefore;
            recordToSave.sked_Trading_Staff_Scheduled_Hours_After__c = request.tradingStaffScheduledHoursAfter;
            
            recordToSave.sked_RequestingStaffTravelDistanceBefore__c = request.requestingStaffTravelDistanceBefore;
            recordToSave.sked_RequestingStaffTravelDistanceAfter__c = request.requestingStaffTravelDistanceAfter;
            recordToSave.sked_TradingStaffTravelDistanceBefore__c = request.tradingStaffTravelDistanceBefore;
            recordToSave.sked_TradingStaffTravelDistanceAfter__c = request.tradingStaffTravelDistanceAfter;
            
            if (request.reasonApprovalRequired.contains(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_TAT_CONTENTION)) {
                recordToSave.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_WAITING_FOR_TRADING_STAFF_ACKNOWLEDGE;
            }
            else {//finalize auto approval
                recordToSave.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_PENDING_APPROVAL;
                if (!request.reasonApprovalRequired.isEmpty()) {
                    recordToSave.sked_Reason_Approval_Required__c = string.join(request.reasonApprovalRequired, ';');
                }
                else {
                    boolean isAutoApproval = (request.requestingStaffNCE == NULL || request.requestingStaffNCE.sked__Type__c == 'After Hours Call Out Management')
                        && (request.tradingStaffNCE == NULL || request.tradingStaffNCE.sked__Type__c == 'After Hours Call Out Management');
                    if (isAutoApproval) {
                        recordToSave.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED;
                    }
                }
            }
        }
        
        recordToSave.sked_Auto_process_Complete__c = TRUE;
        update recordToSave;
    }
    
    /* Private methods */
    private static void initialize(driveShiftTradeModel request) {
        if (!string.isBlank(request.requestingStaffJobAllocationId)) {
            request.requestingStaffJobAllocation = getJobAllocation(request.requestingStaffJobAllocationId, request.tradeId);
            request.requestingStaffJob = getJob(request.requestingStaffJobAllocation.sked__Job__c);
        }
        if (!string.isBlank(request.tradingStaffJobAllocationId)) {
            request.tradingStaffJobAllocation = getJobAllocation(request.tradingStaffJobAllocationId, request.tradeId);
            request.tradingStaffJob = getJob(request.tradingStaffJobAllocation.sked__Job__c);
        }
        if (!string.isBlank(request.requestingStaffNCEId)) {
            request.requestingStaffNCE = getActivity(request.requestingStaffNCEId, request.tradeId);
        }
        if (!string.isBlank(request.tradingStaffNCEId)) {
            request.tradingStaffNCE = getActivity(request.tradingStaffNCEId, request.tradeId);
        }
        request.requestingRecordDate = getRecordDate(request.requestingStaffJob, request.requestingStaffNCE);
        request.tradingRecordDate = getRecordDate(request.tradingStaffJob, request.tradingStaffNCE);
        
        request.requestingStaff = getResource(request.requestingStaffId, request.requestingRecordDate);
        request.tradingStaff = getResource(request.tradingStaffId, request.tradingRecordDate);
        
        request.reasonApprovalRequired = new List<string>();
    }
    
    private static driveShiftTradeModel prepareDriveShiftTradeRequest(sked_Drive_Shift_Trade__c skedTrade) {
        driveShiftTradeModel request = new driveShiftTradeModel();
        request.tradeId = skedTrade.Id;
        request.requestingStaffId = skedTrade.sked_Requesting_Staff__c;
        request.requestingStaffJobAllocationId = skedTrade.sked_Requesting_Staff_Job_Allocation__c;
        request.requestingStaffNCEId = skedTrade.sked_Requesting_Staff_NCE__c;
        request.requestingStaffTradingType = skedTrade.sked_Requesting_Staff_Trading_Type__c;
        request.tradingStaffId = skedTrade.sked_Trading_Staff__c;
        request.tradingStaffJobAllocationId = skedTrade.sked_Trading_Staff_Job_Allocation__c;
        request.tradingStaffNCEId = skedTrade.sked_Trading_Staff_NCE__c;
        request.tradingStaffTradingType = skedTrade.sked_Trading_Staff_Trading_Type__c;
        return request;
    }
    
    private static void doValidateRequest(driveShiftTradeModel request) {
        validateDuplicate(request);
        validateCutoffRule(request);
        validateOvertimeRule(request);
        validateRequiredTags(request);
        validateTurnaroundRule(request);
        validateLinkedDriveRule(request);
    }
    
    private static sked__Job_Allocation__c getJobAllocation(Id jobAllocationId, Id tradeId) {
        return [SELECT Id, sked__Job__c,
                (SELECT Id
                 FROM sked_Drive_Shift_Trades__r
                 WHERE Id != :tradeId
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_CANCELLED),
                (SELECT Id
                 FROM sked_Drive_Shift_Trades2__r
                 WHERE Id != :tradeId
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_CANCELLED)
                FROM sked__Job_Allocation__c
                WHERE Id = :jobAllocationId];
    }
    
    private static sked__Job__c getJob(Id jobId) {
        return [SELECT Id, Name, sked__Start__c, sked__Finish__c, sked__GeoLocation__c, sked__Duration__c,
                sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Linked_Drives__c,
                (SELECT Id, sked__Tag__c, sked__Tag__r.Name
                 FROM sked__JobTags__r)
                FROM sked__Job__c
                WHERE Id = :jobId];
    }
    
    private static sked__Activity__c getActivity(Id activityId, Id tradeId) {
        return [SELECT Id, sked__Type__c, sked_Start_Date__c, sked_Duration__c,
                (SELECT Id, Name
                 FROM sked_Drive_Shift_Trades__r
                 WHERE Id != :tradeId
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_CANCELLED),
                (SELECT Id, Name
                 FROM sked_Drive_Shift_Trades2__r
                 WHERE Id != :tradeId
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED
                 AND sked_Status__c != :skedConstants.DRIVE_SHIFT_TRADE_STATUS_CANCELLED)
                FROM sked__Activity__c
                WHERE Id = :activityId];
    }
    
    private static sked__Resource__c getResource(Id resourceId, Date selectedDate) {
        return [SELECT Id, Name, sked_Max_Hours_Per_Week__c, sked_Turnaround_Time__c, sked__GeoLocation__c,
                sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Shift_Swap_Cutoff__c,
                (SELECT Id, sked__Tag__c, sked_Expiry_Date__c, sked_Start_Date__c, sked__Tag__r.Name
                 FROM sked__ResourceTags__r
                 WHERE (sked_Role_Status__c = NULL OR sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE)),
                (SELECT Id, sked_Start_Date__c, sked_End_Date__c, sked_Total_Working_Time__c
                 FROM sked_Resource_Hours_Records__r
                 WHERE sked_Start_Date__c <= :selectedDate
                 AND sked_End_Date__c >= :selectedDate)
                FROM sked__Resource__c
                WHERE Id = :resourceId];
    }
    
    private static Date getRecordDate(sked__Job__c skedJob, sked__Activity__c skedActivity) {
        return skedJob != NULL ? skedJob.sked_Drive__r.sked_Drive_Date__c : skedActivity.sked_Start_Date__c;
    }
    
    private static void validateDuplicate(driveShiftTradeModel request) {
        request.requestingStaffingDuplicateTrades = new List<sked_Drive_Shift_Trade__c>();
        if (request.requestingStaffJobAllocation != NULL) {
            if (request.requestingStaffJobAllocation.sked_Drive_Shift_Trades__r != NULL && !request.requestingStaffJobAllocation.sked_Drive_Shift_Trades__r.isEmpty()) {
                request.requestingStaffingDuplicateTrades.addAll(request.requestingStaffJobAllocation.sked_Drive_Shift_Trades__r);
            }
            if (request.requestingStaffJobAllocation.sked_Drive_Shift_Trades2__r != NULL && !request.requestingStaffJobAllocation.sked_Drive_Shift_Trades2__r.isEmpty()) {
                request.requestingStaffingDuplicateTrades.addAll(request.requestingStaffJobAllocation.sked_Drive_Shift_Trades2__r);
            }
        }
        if (request.requestingStaffNCE != NULL) {
            if (request.requestingStaffNCE.sked_Drive_Shift_Trades__r != NULL && !request.requestingStaffNCE.sked_Drive_Shift_Trades__r.isEmpty()) {
                request.requestingStaffingDuplicateTrades.addAll(request.requestingStaffNCE.sked_Drive_Shift_Trades__r);
            }
            if (request.requestingStaffNCE.sked_Drive_Shift_Trades2__r != NULL && !request.requestingStaffNCE.sked_Drive_Shift_Trades2__r.isEmpty()) {
                request.requestingStaffingDuplicateTrades.addAll(request.requestingStaffNCE.sked_Drive_Shift_Trades2__r);
            }
        }
        if (!request.requestingStaffingDuplicateTrades.isEmpty()) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DUPLICATE_TRADE);
        }
        
        request.tradingStaffingDuplicateTrades = new List<sked_Drive_Shift_Trade__c>();
        if (request.tradingStaffJobAllocation != NULL) {
            if (request.tradingStaffJobAllocation.sked_Drive_Shift_Trades__r != NULL && !request.tradingStaffJobAllocation.sked_Drive_Shift_Trades__r.isEmpty()) {
                request.tradingStaffingDuplicateTrades.addAll(request.tradingStaffJobAllocation.sked_Drive_Shift_Trades__r);
            }
            if (request.tradingStaffJobAllocation.sked_Drive_Shift_Trades2__r != NULL && !request.tradingStaffJobAllocation.sked_Drive_Shift_Trades2__r.isEmpty()) {
                request.tradingStaffingDuplicateTrades.addAll(request.tradingStaffJobAllocation.sked_Drive_Shift_Trades2__r);
            }
        }
        if (request.tradingStaffNCE != NULL) {
            if (request.tradingStaffNCE.sked_Drive_Shift_Trades__r != NULL && !request.tradingStaffNCE.sked_Drive_Shift_Trades__r.isEmpty()) {
                request.tradingStaffingDuplicateTrades.addAll(request.tradingStaffNCE.sked_Drive_Shift_Trades__r);
            }
            if (request.tradingStaffNCE.sked_Drive_Shift_Trades2__r != NULL && !request.tradingStaffNCE.sked_Drive_Shift_Trades2__r.isEmpty()) {
                request.tradingStaffingDuplicateTrades.addAll(request.tradingStaffNCE.sked_Drive_Shift_Trades2__r);
            }
        }
        if (!request.tradingStaffingDuplicateTrades.isEmpty()) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DUPLICATE_TRADE);
        }
    }
    
    private static void validateCutoffRule(driveShiftTradeModel request) {
        boolean result = FALSE;
        
        decimal requestingShiftSwapCutoff = request.requestingStaff.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Shift_Swap_Cutoff__c;
        requestingShiftSwapCutoff = requestingShiftSwapCutoff != NULL ? requestingShiftSwapCutoff : 42;
        
        decimal tradingShiftSwapCutoff = request.tradingStaff.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Shift_Swap_Cutoff__c;
        tradingShiftSwapCutoff = tradingShiftSwapCutoff != NULL ? tradingShiftSwapCutoff : 42;
		
        result = isCutoffRuleViolated(request.requestingRecordDate, requestingShiftSwapCutoff);
        if (result == FALSE) {
            result = isCutoffRuleViolated(request.tradingRecordDate, tradingShiftSwapCutoff);
        }
        
        if (result) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_CUTOFF_REQUIREMENT);
        }
    }
    
    private static boolean isCutoffRuleViolated(Date requestDate, decimal shiftSwapCutoff) {
        Date currentDate = system.today();
        integer cutoffDays = currentDate.daysBetween(requestDate);
        return cutoffDays < shiftSwapCutoff;
    }
    
    private static void validateOvertimeRule(driveShiftTradeModel request) {
        Decimal requestingStaffDuration = calculateDuration(request.requestingStaff);
        Decimal requestingStaffRecordDuration = getRecordDuration(request.requestingStaffJob, request.requestingStaffNCE);
        
        Decimal tradingStaffDuration = calculateDuration(request.tradingStaff);
        Decimal tradingStaffRecordDuration = getRecordDuration(request.tradingStaffJob, request.tradingStaffNCE);
        
        if (request.requestingStaffJob != NULL || request.requestingStaffNCE != NULL) {
            request.requestingStaffScheduledHoursBefore = requestingStaffDuration / 60;
            request.requestingStaffScheduledHoursBefore = request.requestingStaffScheduledHoursBefore.setScale(1);

            request.requestingStaffScheduledHoursAfter = (requestingStaffDuration - requestingStaffRecordDuration + tradingStaffRecordDuration) / 60;
            request.requestingStaffScheduledHoursAfter = request.requestingStaffScheduledHoursAfter.setScale(1);
            
            if (request.requestingStaffScheduledHoursAfter > request.requestingStaff.sked_Max_Hours_Per_Week__c) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_EXCEEDS_MAX_HOUR);
            }
        }
        
        if (request.requestingStaffJob != NULL || request.requestingStaffNCE != NULL) {
            request.tradingStaffScheduledHoursBefore = tradingStaffDuration / 60;
            request.tradingStaffScheduledHoursBefore = request.tradingStaffScheduledHoursBefore.setScale(1);

            request.tradingStaffScheduledHoursAfter = (tradingStaffDuration - tradingStaffRecordDuration + requestingStaffRecordDuration) / 60;
            request.tradingStaffScheduledHoursAfter = request.tradingStaffScheduledHoursAfter.setScale(1);

            if (request.tradingStaffScheduledHoursAfter > request.tradingStaff.sked_Max_Hours_Per_Week__c) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_EXCEEDS_MAX_HOUR);
            }
        }
    }  
    
    private static Integer calculateDuration(sked__Resource__c skedResource) {
        Integer totalDuration = 0;
        if (skedResource.sked_Resource_Hours_Records__r != NULL && !skedResource.sked_Resource_Hours_Records__r.isEmpty()) {
            for (sked_Resource_Hours_Record__c resourceHoursRecord : skedResource.sked_Resource_Hours_Records__r) {
                if (resourceHoursRecord.sked_Total_Working_Time__c != NULL ) {
                    totalDuration += integer.valueOf(resourceHoursRecord.sked_Total_Working_Time__c);
                }
            }
        }
        return totalDuration;
    }
    
    private static decimal getRecordDuration(sked__Job__c skedJob, sked__Activity__c skedActivity) {
        return skedJob != NULL ? skedJob.sked__Duration__c : (skedActivity != NULL ? skedActivity.sked_Duration__c : 0);
    }
    
    private static void validateRequiredTags(driveShiftTradeModel request) {
        if (request.requestingStaffJob != NULL) {
            boolean isRequestingStaffQualified = requiredTagChecking(request.requestingStaffJob, request.tradingStaff);
            if (!isRequestingStaffQualified) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_UNQUALIFIED);
            }
        }
        if (request.tradingStaffJob != NULL) {
            boolean isTradingStaffQualified = requiredTagChecking(request.tradingStaffJob, request.requestingStaff);
            if (!isTradingStaffQualified) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_UNQUALIFIED);
            }
        }
    }
    
    private static boolean requiredTagChecking(sked__Job__c job, sked__Resource__c resource) {
        boolean isValid = TRUE;
        if (job.sked__JobTags__r != NULL && !job.sked__JobTags__r.isEmpty()) {
            Set<Id> tagIds = new Set<Id>();
            for (sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {
                if (resourceTag.sked_Start_Date__c <= job.sked_Drive__r.sked_Drive_Date__c && (resourceTag.sked_Expiry_Date__c == NULL || job.sked_Drive__r.sked_Drive_Date__c <= resourceTag.sked_Expiry_Date__c)) {
                    tagIds.add(resourceTag.sked__Tag__c);
                }
            }
            
            for (sked__Job_Tag__c jobTag : job.sked__JobTags__r) {
                if (!tagIds.contains(jobTag.sked__Tag__c)) {
                    isValid = FALSE;
                    break;
                }
            }
        }
        return isValid;
    }
    
    private static void validateTurnaroundRule(driveShiftTradeModel request) {
        if (request.tradingStaffJob != NULL) {
            if (request.requestingStaff.sked_Turnaround_Time__c != NULL) {
                Integer turnaroundTimeHours = Integer.valueOf(request.requestingStaff.sked_Turnaround_Time__c);
                boolean requestingStaffTurnaroundTimeChecking = turnaroundTimeChecking(request.requestingStaff.Id, turnaroundTimeHours, 
                                                                                       request.requestingStaffJob.Id, 
                                                                                       request.tradingStaffJob);
                if (!requestingStaffTurnaroundTimeChecking) {
                   request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_TAT_CONTENTION);
                }
            }
        }
        if (request.requestingStaffJob != NULL) {
            if (request.tradingStaff.sked_Turnaround_Time__c != NULL) {
                Integer turnaroundTimeHours = Integer.valueOf(request.tradingStaff.sked_Turnaround_Time__c);
                boolean tradingStaffTurnaroundTimeChecking = turnaroundTimeChecking(request.tradingStaffId, turnaroundTimeHours, 
                                                                                    request.tradingStaffJob.Id, 
                                                                                    request.requestingStaffJob);
                if (!tradingStaffTurnaroundTimeChecking) {
                    request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_TAT_CONTENTION);
                }
            }
        }
    }  
    
    private static boolean turnaroundTimeChecking(Id resourceId, Integer turnaroundTimeHours, Id tradingJobId, sked__Job__c inputJob) {
        DateTime allowedLatestJobFinishBefore = inputJob.sked__Start__c.addHours(-turnaroundTimeHours);
        DateTime allowedSoonestJobStartAfter = inputJob.sked__Finish__c.addHours(turnaroundTimeHours);
        List<sked__Job_Allocation__c> jobAllocationQueryChecking = [SELECT Id 
                                                                    FROM sked__Job_Allocation__c
                                                                    WHERE sked__Resource__c = :resourceId
                                                                    AND sked__Job__c != :tradingJobId
                                                                    AND sked__Start__c < :allowedSoonestJobStartAfter
                                                                    AND sked__Set_End__c > :allowedLatestJobFinishBefore
                                                                    AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                                                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
        return jobAllocationQueryChecking.isEmpty();
    }
    
    private static void validateLinkedDriveRule(driveShiftTradeModel request) {
        boolean isRequestingStaffDriveLinked = request.requestingStaffJob != NULL && request.requestingStaffJob.sked_Drive__r.sked_Linked_Drives__c != NULL;
        if (isRequestingStaffDriveLinked) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DRIVE_PART_OF_LINKED);
        }
        
        boolean istradingStaffDriveLinked = request.tradingStaffJob != NULL && request.tradingStaffJob.sked_Drive__r.sked_Linked_Drives__c != NULL;
        if (istradingStaffDriveLinked) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DRIVE_PART_OF_LINKED);
        }
    }
    
    private static void populateTravelDistance(driveShiftTradeModel request) {
        if (request.requestingStaff.sked__GeoLocation__c != NULL) {
            if (request.requestingStaffJob != NULL && request.requestingStaffJob.sked__GeoLocation__c != NULL) {
                request.requestingStaffTravelDistanceBefore = request.requestingStaff.sked__GeoLocation__c.getDistance(request.requestingStaffJob.sked__GeoLocation__c, 'mi');
                request.requestingStaffTravelDistanceBefore = request.requestingStaffTravelDistanceBefore.setScale(1);
            }
            if (request.tradingStaffJob != NULL && request.tradingStaffJob.sked__GeoLocation__c != NULL) {                                          
                request.requestingStaffTravelDistanceAfter = request.requestingStaff.sked__GeoLocation__c.getDistance(request.tradingStaffJob.sked__GeoLocation__c, 'mi');
                request.requestingStaffTravelDistanceAfter = request.requestingStaffTravelDistanceAfter.setScale(1);
            }
        }
        if (request.tradingStaff.sked__GeoLocation__c != NULL) {
            if (request.tradingStaffJob != NULL && request.tradingStaffJob.sked__GeoLocation__c != NULL) {
                request.tradingStaffTravelDistanceBefore = request.tradingStaff.sked__GeoLocation__c.getDistance(request.tradingStaffJob.sked__GeoLocation__c, 'mi');
                request.tradingStaffTravelDistanceBefore = request.tradingStaffTravelDistanceBefore.setScale(1);
            }
            if (request.requestingStaffJob != NULL && request.requestingStaffJob.sked__GeoLocation__c != NULL) {
                request.tradingStaffTravelDistanceAfter = request.tradingStaff.sked__GeoLocation__c.getDistance(request.requestingStaffJob.sked__GeoLocation__c, 'mi');
                request.tradingStaffTravelDistanceAfter = request.tradingStaffTravelDistanceAfter.setScale(1);
            }
        }
    }
    
    private static List<string> getHardViolationContentions() {
        List<string> hardViolationContentions = new List<string>();
        hardViolationContentions.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_CUTOFF_REQUIREMENT);
        hardViolationContentions.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DUPLICATE_TRADE);
        hardViolationContentions.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DUPLICATE_TRADE);
        return hardViolationContentions;
    }
    
    /* Nest classes */
    public class driveShiftTradeModel {
        @AuraEnabled public string tradeId {get;set;}
        @AuraEnabled public string requestingStaffId {get;set;}
        @AuraEnabled public string requestingStaffJobAllocationId {get;set;}
        @AuraEnabled public string requestingStaffNCEId {get;set;}
        @AuraEnabled public string requestingStaffTradingType {get;set;}
        @AuraEnabled public string tradingStaffId {get;set;}
        @AuraEnabled public string tradingStaffJobAllocationId {get;set;}
        @AuraEnabled public string tradingStaffNCEId {get;set;}
        @AuraEnabled public string tradingStaffTradingType {get;set;}
        
        public sked__Job_Allocation__c requestingStaffJobAllocation;
        public sked__Job_Allocation__c tradingStaffJobAllocation;
        public sked__Job__c requestingStaffJob;
        public sked__Job__c tradingStaffJob;
        public sked__Activity__c requestingStaffNCE;
        public sked__Activity__c tradingStaffNCE;
        public sked__Resource__c requestingStaff;
        public sked__Resource__c tradingStaff;
        public Date requestingRecordDate;
        public Date tradingRecordDate;
        
        public decimal requestingStaffScheduledHoursBefore;
        public decimal requestingStaffScheduledHoursAfter;
        public decimal tradingStaffScheduledHoursBefore;
        public decimal tradingStaffScheduledHoursAfter;
        
        public decimal requestingStaffTravelDistanceBefore;
        public decimal requestingStaffTravelDistanceAfter;
        public decimal tradingStaffTravelDistanceBefore;
        public decimal tradingStaffTravelDistanceAfter;
        
        public List<sked_Drive_Shift_Trade__c> requestingStaffingDuplicateTrades;
        public List<sked_Drive_Shift_Trade__c> tradingStaffingDuplicateTrades;
        
        public List<string> reasonApprovalRequired;
    }
    
    public class contentionModel {
        @AuraEnabled public string contention {get;set;}
        @AuraEnabled public boolean hardViolation {get;set;}
    }

}