global class slwcDriveShiftTradeService implements Callable {
    
    @AuraEnabled
    public static slwcAuraResult validateShiftTrades(validateShiftTradesRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();

        initialize(request);
        populateJATravelDataAfterTrade(request);
        doValidateRequest(request);
        
        List<string> hardViolationContentions = getHardViolationContentions();
        validateResponseModel response = new validateResponseModel();
        for (driveShiftTradeModel shiftTrade : request.shiftTrades) {
            List<contentionModel> contentions = new List<contentionModel>();
            for (string contentionMsg : shiftTrade.reasonApprovalRequired) {
                contentionModel contention = new contentionModel();
                contention.contention = contentionMsg;
                contention.hardViolation = hardViolationContentions.contains(contentionMsg);
                contentions.add(contention);
            }
            
            driveShiftTradeValidationResult shiftTradeValidationResult = new driveShiftTradeValidationResult();
            shiftTradeValidationResult.id = shiftTrade.id;
            shiftTradeValidationResult.requestingStaffTurnaroundViolation = shiftTrade.requestingStaffTurnaroundViolation;
            shiftTradeValidationResult.tradingStaffTurnaroundViolation = shiftTrade.tradingStaffTurnaroundViolation;
            shiftTradeValidationResult.requestingStaffGuaranteedMinHrsForfeited = shiftTrade.requestingStaffGuaranteedMinHrsForfeited;
            shiftTradeValidationResult.tradingStaffGuaranteedMinHrsForfeited = shiftTrade.tradingStaffGuaranteedMinHrsForfeited;
            shiftTradeValidationResult.requestingStaffRelocated = shiftTrade.requestingStaffRelocated;
            shiftTradeValidationResult.tradingStaffRelocated = shiftTrade.tradingStaffRelocated;
            shiftTradeValidationResult.requestingStaffUnavailableForCO = shiftTrade.requestingStaffUnavailableForCO;
            shiftTradeValidationResult.tradingStaffUnavailableForCO = shiftTrade.tradingStaffUnavailableForCO;
            shiftTradeValidationResult.contentions = contentions;
            response.shiftTradeValidationResults.add(shiftTradeValidationResult);
        }
        
        result.returnedData = response;
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult autoProcessRequest(driveShiftTradeModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();

        validateShiftTradesRequestModel validateRequest = new validateShiftTradesRequestModel();
        validateRequest.shiftTrades = new List<driveShiftTradeModel>{request};
        initialize(validateRequest);
        populateJATravelDataAfterTrade(validateRequest);
        doValidateRequest(validateRequest);
        
        sked_Drive_Shift_Trade__c recordToSave = [
            SELECT Id, sked_Status__c, sked_Trading_Staff__c,
            sked_Requesting_Staff_TAT_Acknowledge__c, sked_Requesting_Staff_GMH_Acknowledge__c,
            sked_Trading_Staff_TAT_Acknowledge__c, sked_Trading_Staff_GMH_Acknowledge__c,
            sked_Requester_Unavailable_For_CO_Ack__c, sked_Trader_Unavailable_For_CO_Ack__c,
            sked_Requester_Relocated_Acknowledge__c, sked_Trader_Relocated_Acknowledge__c
            FROM sked_Drive_Shift_Trade__c
            WHERE Id = :request.id
        ];
        
        Map<string, string> map_hardViolationContention_DeniedReason = new Map<string, string>();
        map_hardViolationContention_DeniedReason.put(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DUPLICATE_TRADE, skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_DUPLICATE);
        map_hardViolationContention_DeniedReason.put(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DUPLICATE_TRADE, skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_DUPLICATE);
        map_hardViolationContention_DeniedReason.put(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_IS_ALREADY_ASSIGNED, skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_DOUBLE_BOOKED);
        map_hardViolationContention_DeniedReason.put(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_IS_ALREADY_ASSIGNED, skedConstants.DRIVE_SHIFT_TRADE_DENIED_REASON_DOUBLE_BOOKED);
        
        for (string hardViolationContention : map_hardViolationContention_DeniedReason.keySet()) {
            if (request.reasonApprovalRequired.contains(hardViolationContention)) {
                recordToSave.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED;
                recordToSave.sked_Denied_Reason__c = map_hardViolationContention_DeniedReason.get(hardViolationContention);
                break;
            }
        }
        
        if (recordToSave.sked_Status__c != skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED) {
            if (recordToSave.sked_Trading_Staff__c != NULL) {
                recordToSave.sked_RequestingStaffScheduledHoursBefore__c = request.requestingStaffScheduledHoursBefore;
                recordToSave.sked_RequestingStaffScheduledHoursAfter__c = request.requestingStaffScheduledHoursAfter;
                recordToSave.sked_TradingStaff_Scheduled_Hours_Before__c = request.tradingStaffScheduledHoursBefore;
                recordToSave.sked_Trading_Staff_Scheduled_Hours_After__c = request.tradingStaffScheduledHoursAfter;
                
                recordToSave.sked_RequestingStaffTravelDistanceBefore__c = request.requestingStaffTravelDistanceBefore;
                recordToSave.sked_RequestingStaffTravelDistanceAfter__c = request.requestingStaffTravelDistanceAfter;
                recordToSave.sked_TradingStaffTravelDistanceBefore__c = request.tradingStaffTravelDistanceBefore;
                recordToSave.sked_TradingStaffTravelDistanceAfter__c = request.tradingStaffTravelDistanceAfter;
                recordToSave.sked_Requesting_Staff_TT_To_Before_Trade__c = request.requestingStaffJobAllocation.sked_Travel_Time_To__c;
                recordToSave.sked_Requesting_Staff_TTBack_BeforeTrade__c = request.requestingStaffJobAllocation.sked_Travel_Time_Back__c;
                recordToSave.sked_Trading_Staff_TT_To_Before_Trade__c = request.tradingStaffJobAllocation.sked_Travel_Time_To__c;
                recordToSave.sked_Trading_Staff_TT_Back_Before_Trade__c = request.tradingStaffJobAllocation.sked_Travel_Time_Back__c;

                if (request.requestingStaffJATravelDataAfterTrade != null) {
                    recordToSave.sked_Requesting_Staff_TT_To_After_Trade__c = request.requestingStaffJATravelDataAfterTrade.travelTimeTo;
                    recordToSave.sked_Requesting_Staff_TTBack_AfterTrade__c = request.requestingStaffJATravelDataAfterTrade.travelTimeBack;
                }

                if (request.tradingStaffJATravelDataAfterTrade != null) {
                    recordToSave.sked_Trading_Staff_TT_To_After_Trade__c = request.tradingStaffJATravelDataAfterTrade.travelTimeTo;
                    recordToSave.sked_Trading_Staff_TT_Back_After_Trade__c = request.tradingStaffJATravelDataAfterTrade.travelTimeBack;
                }
                
                recordToSave.sked_TAT_Time_Traded_Into_Requester__c = request.requestingStaffTurnaroundViolation;
                recordToSave.sked_TAT_Time_Traded_Into_Trading__c = request.tradingStaffTurnaroundViolation;
                recordToSave.sked_GuaranteedMinHrsForfeited_Requester__c = request.requestingStaffGuaranteedMinHrsForfeited;
                recordToSave.sked_GuaranteedMinHrsForfeited_Trading__c = request.tradingStaffGuaranteedMinHrsForfeited;
                recordToSave.sked_Requesting_Staff_Relocated__c = request.requestingStaffRelocated;
                recordToSave.sked_Trading_Staff_Relocated__c = request.tradingStaffRelocated;
                recordToSave.sked_Requester_Not_Available_For_CO__c = request.requestingStaffUnavailableForCO;
                recordToSave.sked_Trader_Not_Available_For_CO__c = request.tradingStaffUnavailableForCO;
                
                boolean requireRequestingStaffAckowledge = (recordToSave.sked_TAT_Time_Traded_Into_Requester__c == TRUE && recordToSave.sked_Requesting_Staff_TAT_Acknowledge__c == FALSE)
                    || (recordToSave.sked_GuaranteedMinHrsForfeited_Requester__c == TRUE && recordToSave.sked_Requesting_Staff_GMH_Acknowledge__c == FALSE)
                    || (recordToSave.sked_Requesting_Staff_Relocated__c == TRUE && recordToSave.sked_Requester_Relocated_Acknowledge__c == FALSE)
                    || (recordToSave.sked_Requester_Not_Available_For_CO__c == TRUE && recordToSave.sked_Requester_Unavailable_For_CO_Ack__c == FALSE);

                boolean requireTradingStaffAckowledge = (recordToSave.sked_TAT_Time_Traded_Into_Trading__c == TRUE && recordToSave.sked_Trading_Staff_TAT_Acknowledge__c == FALSE)
                    || (recordToSave.sked_GuaranteedMinHrsForfeited_Trading__c == TRUE && recordToSave.sked_Trading_Staff_GMH_Acknowledge__c == FALSE)
                    || (recordToSave.sked_Trading_Staff_Relocated__c == TRUE && recordToSave.sked_Trader_Relocated_Acknowledge__c == FALSE)
                    || (recordToSave.sked_Trader_Not_Available_For_CO__c == TRUE && recordToSave.sked_Trader_Unavailable_For_CO_Ack__c == FALSE);
                
                if (requireRequestingStaffAckowledge || requireTradingStaffAckowledge) {
                    recordToSave.sked_Status__c = requireRequestingStaffAckowledge ? skedConstants.DRIVE_SHIFT_TRADE_STATUS_WAITING_FOR_REQUESTING_STAFF_ACKNOWLEDGE 
                        : skedConstants.DRIVE_SHIFT_TRADE_STATUS_WAITING_FOR_TRADING_STAFF_ACKNOWLEDGE;
                }
                else {//finalize auto approval
                    recordToSave.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_PENDING_APPROVAL;
                    if (!request.reasonApprovalRequired.isEmpty()) {
                        recordToSave.sked_Reason_Approval_Required__c = string.join(request.reasonApprovalRequired, ';');
                    }
                    else {
                        List<string> autoApprovalActivityTypes = new List<string>();
                        autoApprovalActivityTypes.add(skedConstants.ACTIVITY_TYPE_ON_CALL);
                        
                        boolean isAutoApproval = (request.requestingStaffNCE == null || autoApprovalActivityTypes.contains(request.requestingStaffNCE.sked__Type__c))
                            && (request.tradingStaffNCE == null || autoApprovalActivityTypes.contains(request.tradingStaffNCE.sked__Type__c));
                        if (isAutoApproval) {
                            recordToSave.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED;
                        }
                    }
                }
            }
        }
        
        recordToSave.sked_Auto_process_Complete__c = TRUE;
        update recordToSave;

        result.success = true;
        result.returnedData = recordToSave;
        return result;
    }
    
    public static void performShiftTrades(Set<Id> recordIds) {
        List<sked_Drive_Shift_Trade__c> records = [
            SELECT Id, sked_Requesting_Staff__c, sked_Trading_Staff__c,
            sked_Requesting_Staff_Job_Allocation__c, sked_Trading_Staff_Job_Allocation__c,
            sked_Requesting_Staff_Job_Allocation__r.sked__Job__c, sked_Trading_Staff_Job_Allocation__r.sked__Job__c,
            sked_Requesting_Staff_Job_Allocation__r.sked__Job__r.sked_Drive__c, sked_Trading_Staff_Job_Allocation__r.sked__Job__r.sked_Drive__c,
            sked_Requesting_Staff_Job_Allocation__r.sked__Job__r.sked_Drive__r.sked_Linked_Drives__c,
            sked_Trading_Staff_Job_Allocation__r.sked__Job__r.sked_Drive__r.sked_Linked_Drives__c,
            sked_Requesting_Staff_NCE__c, sked_Trading_Staff_NCE__c,
            sked_Requesting_Staff_Trading_Type__c, sked_Trading_Staff_Trading_Type__c
            FROM sked_Drive_Shift_Trade__c
            WHERE Id IN : recordIds
        ];
        
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> nceIds = new Set<Id>();
        Set<Id> jobAllocationIds = new Set<Id>();
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        for (sked_Drive_Shift_Trade__c record : records) {
            resourceIds.add(record.sked_Requesting_Staff__c);
            resourceIds.add(record.sked_Trading_Staff__c);
            
            if (record.sked_Requesting_Staff_Job_Allocation__c != null) {
                jobAllocationIds.add(record.sked_Requesting_Staff_Job_Allocation__c);
                jobs.add(record.sked_Requesting_Staff_Job_Allocation__r.sked__Job__r);
            }
            if (record.sked_Trading_Staff_Job_Allocation__c != null) {
                jobAllocationIds.add(record.sked_Trading_Staff_Job_Allocation__c);
                jobs.add(record.sked_Trading_Staff_Job_Allocation__r.sked__Job__r);
            }
            if (record.sked_Requesting_Staff_NCE__c != null) {
                nceIds.add(record.sked_Requesting_Staff_NCE__c);
            }
            if (record.sked_Trading_Staff_NCE__c != null) {
                nceIds.add(record.sked_Trading_Staff_NCE__c);
            }
        }
        
        Map<Id, sked__Job_Allocation__c> mapAllocation = new Map<Id, sked__Job_Allocation__c>([SELECT Id, sked__Job__c, sked__Status__c,
                                                                                               sked__Resource__c, sked__Resource__r.sked_Min_Hours_Per_Week__c ,
                                                                                               sked_Dual_Role__c, sked_Resource_Role__c, sked_Guarded__c,
                                                                                               sked_Additional_Roles__c, sked__Job__r.sked_Drive__c, sked__Job__r.sked_Drive__r.sked_Linked_Drives__c
                                                                                               FROM sked__Job_Allocation__c
                                                                                               WHERE Id IN :jobAllocationIds]);   
        Map<Id, sked__Activity__c> mapActivity = new Map<Id, sked__Activity__c>([SELECT Id, 
                                                                                 (SELECT Id, sked__Resource__c
                                                                                  FROM sked__Activity_Resources__r
                                                                                  WHERE sked__Resource__c IN :resourceIds)
                                                                                 FROM sked__Activity__c
                                                                                 WHERE Id IN :nceIds]);
        
        Map<Id, sked_Drive_Shift_Trade__c> mapRecordsToUpdate = new Map<Id, sked_Drive_Shift_Trade__c>();
        List<sked__Job_Allocation__c> jobAllocationInsertList = new List<sked__Job_Allocation__c>();
        List<sked__Job_Allocation__c> jobAllocationUpdateList = new List<sked__Job_Allocation__c>();
        
        List<sked__Activity_Resource__c> activityResourceInsertList = new List<sked__Activity_Resource__c>();
        List<sked__Activity_Resource__c> activityResourceDeleteList = new List<sked__Activity_Resource__c>();

        Map<Id, List<sked__Activity_Resource__c>> mapEventIdToOvernightActivityResources = getMapEventIdToOvernightActivityResources(jobs);

        for (sked_Drive_Shift_Trade__c record : records) {
            if (record.sked_Requesting_Staff_Trading_Type__c == 'Drive Shift') {
                sked__Job_Allocation__c requestingStaffJobAllocation = mapAllocation.get(record.sked_Requesting_Staff_Job_Allocation__c);
                requestingStaffJobAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
                requestingStaffJobAllocation.sked_Drive_Shift_Trade__c = record.Id;
                jobAllocationUpdateList.add(requestingStaffJobAllocation);
                
                sked__Job_Allocation__c newTradingStaffJobAllocation = new sked__Job_Allocation__c(
                    sked__Job__c = requestingStaffJobAllocation.sked__Job__c,
                    sked__Resource__c = record.sked_Trading_Staff__c,
                    sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED,
                    sked_Additional_Roles__c = requestingStaffJobAllocation.sked_Additional_Roles__c,
                    sked_Drive_Shift_Trade__c = record.Id,
                    sked_Locked__c = TRUE
                );
                jobAllocationInsertList.add(newTradingStaffJobAllocation);
                
                if (requestingStaffJobAllocation.sked__Resource__r.sked_Min_Hours_Per_Week__c != null) {
                    sked_Drive_Shift_Trade__c recordToUpdate;
                    if (mapRecordsToUpdate.containsKey(record.Id)) {
                        recordToUpdate = mapRecordsToUpdate.get(record.Id);
                    }
                    else {
                        recordToUpdate = new sked_Drive_Shift_Trade__c(Id = record.Id);
                        mapRecordsToUpdate.put(record.Id, recordToUpdate);
                    }
                    recordToUpdate.sked_GuaranteedMinHrsForfeited_Requester__c = requestingStaffJobAllocation.sked__Resource__r.sked_Min_Hours_Per_Week__c != null;
                } 
                
                List<sked__Activity_Resource__c> allOvernightActivityResources = getOvernightActivityResourcesRelateToJob(requestingStaffJobAllocation.sked__Job__r, mapEventIdToOvernightActivityResources);
                List<sked__Activity_Resource__c> overnightActivityResourcesToDelete = findActivityResourcesByResourceId(record.sked_Requesting_Staff__c, allOvernightActivityResources);
                for (sked__Activity_Resource__c overnightActivityResourceToDelete : overnightActivityResourcesToDelete) {
                    activityResourceInsertList.add(new sked__Activity_Resource__c(
                        sked__Activity__c = overnightActivityResourceToDelete.sked__Activity__c,
                        sked__Resource__c = record.sked_Trading_Staff__c,
                        sked_Drive_Shift_Trade__c = record.Id
                    ));
                }
                activityResourceDeleteList.addAll(overnightActivityResourcesToDelete);
            }
            if (record.sked_Trading_Staff_Trading_Type__c == 'Drive Shift') {
                sked__Job_Allocation__c tradingStaffJobAllocation = mapAllocation.get(record.sked_Trading_Staff_Job_Allocation__c);
                tradingStaffJobAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
                tradingStaffJobAllocation.sked_Drive_Shift_Trade__c = record.Id;
                jobAllocationUpdateList.add(tradingStaffJobAllocation);
                
                sked__Job_Allocation__c newRequestingStaffJobAllocation = new sked__Job_Allocation__c(
                    sked__Job__c = tradingStaffJobAllocation.sked__Job__c,
                    sked__Resource__c = record.sked_Requesting_Staff__c,
                    sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED,
                    sked_Additional_Roles__c = tradingStaffJobAllocation.sked_Additional_Roles__c,
                    sked_Drive_Shift_Trade__c = record.Id,
                    sked_Locked__c = TRUE
                );
                jobAllocationInsertList.add(newRequestingStaffJobAllocation);
                
                if (tradingStaffJobAllocation.sked__Resource__r.sked_Min_Hours_Per_Week__c != null) {
                    sked_Drive_Shift_Trade__c recordToUpdate;
                    if (mapRecordsToUpdate.containsKey(record.Id)) {
                        recordToUpdate = mapRecordsToUpdate.get(record.Id);
                    }
                    else {
                        recordToUpdate = new sked_Drive_Shift_Trade__c(Id = record.Id);
                        mapRecordsToUpdate.put(record.Id, recordToUpdate);
                    }
                    recordToUpdate.sked_GuaranteedMinHrsForfeited_Trading__c = tradingStaffJobAllocation.sked__Resource__r.sked_Min_Hours_Per_Week__c != null;
                }

                List<sked__Activity_Resource__c> allOvernightActivityResources = getOvernightActivityResourcesRelateToJob(tradingStaffJobAllocation.sked__Job__r, mapEventIdToOvernightActivityResources);
                List<sked__Activity_Resource__c> overnightActivityResourcesToDelete = findActivityResourcesByResourceId(record.sked_Trading_Staff__c, allOvernightActivityResources);
                for (sked__Activity_Resource__c overnightActivityResourceToDelete : overnightActivityResourcesToDelete) {
                    activityResourceInsertList.add(new sked__Activity_Resource__c(
                        sked__Activity__c = overnightActivityResourceToDelete.sked__Activity__c,
                        sked__Resource__c = record.sked_Requesting_Staff__c,
                        sked_Drive_Shift_Trade__c = record.Id
                    ));
                }
                activityResourceDeleteList.addAll(overnightActivityResourcesToDelete);
            }
            
            if (record.sked_Requesting_Staff_Trading_Type__c == 'Activity') {
                sked__Activity__c requestingStaffNce = mapActivity.get(record.sked_Requesting_Staff_NCE__c);
                for (sked__Activity_Resource__c activityResource : requestingStaffNce.sked__Activity_Resources__r) {
                    if (activityResource.sked__Resource__c == record.sked_Requesting_Staff__c) {
                        activityResourceDeleteList.add(activityResource);
                        break;
                    }
                }
                sked__Activity_Resource__c newTradingStaffNceResource = new sked__Activity_Resource__c(
                    sked__Activity__c = requestingStaffNce.Id,
                    sked__Resource__c = record.sked_Trading_Staff__c,
                    sked_Drive_Shift_Trade__c = record.Id
                );
                activityResourceInsertList.add(newTradingStaffNceResource);
            }
            if (record.sked_Trading_Staff_Trading_Type__c == 'Activity') {
                sked__Activity__c tradingStaffNce = mapActivity.get(record.sked_Trading_Staff_NCE__c);
                for (sked__Activity_Resource__c activityResource : tradingStaffNce.sked__Activity_Resources__r) {
                    if (activityResource.sked__Resource__c == record.sked_Trading_Staff__c) {
                        activityResourceDeleteList.add(activityResource);
                        break;
                    }
                }
                sked__Activity_Resource__c newRequestingStaffNceResource = new sked__Activity_Resource__c(
                    sked__Activity__c = tradingStaffNce.Id,
                    sked__Resource__c = record.sked_Requesting_Staff__c,
                    sked_Drive_Shift_Trade__c = record.Id
                );
                activityResourceInsertList.add(newRequestingStaffNceResource);
            }
        }
        if (!activityResourceDeleteList.isEmpty()) {
            delete activityResourceDeleteList;
        }
        if (!activityResourceInsertList.isEmpty()) {
            insert activityResourceInsertList;
        }
        if (!jobAllocationUpdateList.isEmpty()) {
            update jobAllocationUpdateList;
        }
        if (!jobAllocationInsertList.isEmpty()) {
            insert jobAllocationInsertList;
        }
        if (!mapRecordsToUpdate.isEmpty()) {
            update mapRecordsToUpdate.values();
        }
    }
    
    /* Private methods */
    private static Map<Id, sked__Job__c> getMapJob(List<sked__Job_Allocation__c> jobAllocations) {
        Set<Id> jobIds = new Set<Id>();
        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
                jobIds.add(jobAllocation.sked__Job__c);
        }

        return new Map<Id, sked__Job__c>([
            SELECT Id, Name, sked__Start__c, sked__Finish__c, sked__Location__c, sked__GeoLocation__c, sked__Duration__c,
            sked_Drive__r.sked_Account__c, sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Linked_Drives__c, sked_Drive__c,
            sked_Drive__r.sked_Collection_Operation__c,
            (SELECT Id, sked__Tag__c, sked__Tag__r.Name
             FROM sked__JobTags__r)
            FROM sked__Job__c
            WHERE Id IN :jobIds
        ]);
    }

    private static Map<Id, sked__Job_Allocation__c> getMapJobAllocation(List<driveShiftTradeModel> shiftTrades) {
        Set<Id> jobAllocationIds = new Set<Id>();
        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            if (!string.isBlank(shiftTrade.requestingStaffJobAllocationId)) {
                jobAllocationIds.add(shiftTrade.requestingStaffJobAllocationId);
            }
            if (!string.isBlank(shiftTrade.tradingStaffJobAllocationId)) {
                jobAllocationIds.add(shiftTrade.tradingStaffJobAllocationId);
            }
        }

        List<string> completedStatuses = getCompletedStatuses();
        Map<Id, sked__Job_Allocation__c> mapJobAllocation = new Map<Id, sked__Job_Allocation__c>([
            SELECT Id, sked__Job__c, sked_Geoservice_Travel_Distance_To__c, sked_Travel_Time_To__c, sked_Travel_Time_Back__c, 
            sked__Duration__c, sked_Roles_Assignment_Str__c,
            sked__Status__c, sked__Resource__c, sked__Resource__r.sked_Min_Hours_Per_Week__c ,
            sked_Dual_Role__c, sked_Resource_Role__c, sked_Guarded__c,
            sked_Additional_Roles__c, sked__Job__r.sked_Drive__c, sked__Job__r.sked_Drive__r.sked_Linked_Drives__c,
            (SELECT Id
             FROM sked_Drive_Shift_Trades__r
             WHERE sked_Status__c NOT IN :completedStatuses),
            (SELECT Id
             FROM sked_Drive_Shift_Trades2__r
             WHERE sked_Status__c NOT IN :completedStatuses)
            FROM sked__Job_Allocation__c
            WHERE Id IN :jobAllocationIds
        ]);
        
        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            sked__Job_Allocation__c requestingStaffJobAllocation = mapJobAllocation.get(shiftTrade.requestingStaffJobAllocationId);
            if (requestingStaffJobAllocation != null) {
                shiftTrade.requestingStaffOtherTrades = filterDriveShiftTradesByExcludedTradeId(requestingStaffJobAllocation.sked_Drive_Shift_Trades__r, shiftTrade.id);
                shiftTrade.requestingStaffOtherTrades2 = filterDriveShiftTradesByExcludedTradeId(requestingStaffJobAllocation.sked_Drive_Shift_Trades2__r, shiftTrade.id);
            }

            sked__Job_Allocation__c tradingStaffJobAllocation = mapJobAllocation.get(shiftTrade.tradingStaffJobAllocationId);
            if (tradingStaffJobAllocation != null) {
                shiftTrade.tradingStaffOtherTrades = filterDriveShiftTradesByExcludedTradeId(tradingStaffJobAllocation.sked_Drive_Shift_Trades__r, shiftTrade.id);
                shiftTrade.tradingStaffOtherTrades2 = filterDriveShiftTradesByExcludedTradeId(tradingStaffJobAllocation.sked_Drive_Shift_Trades2__r, shiftTrade.id);
            }
        }
        return mapJobAllocation;
    }

    private static Map<Id, sked__Activity__c> getMapActivity(List<driveShiftTradeModel> shiftTrades) {
        Set<Id> activityIds = new Set<Id>();
        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            if (!string.isBlank(shiftTrade.requestingStaffNCEId)) {
                activityIds.add(shiftTrade.requestingStaffNCEId);
            }
            if (!string.isBlank(shiftTrade.tradingStaffNCEId)) {
                activityIds.add(shiftTrade.tradingStaffNCEId);
            }
        }

        List<String> completedStatuses = getCompletedStatuses();
        Map<Id, sked__Activity__c> mapActivity = new Map<Id, sked__Activity__c>([
            SELECT Id, sked__Type__c, sked_Start_Date__c, sked_Duration__c, sked_Collection_Operation__c,
            (SELECT Id, Name
                FROM sked_Drive_Shift_Trades__r
                WHERE sked_Status__c NOT IN :completedStatuses),
            (SELECT Id, Name
                FROM sked_Drive_Shift_Trades2__r
                WHERE sked_Status__c NOT IN :completedStatuses)
            FROM sked__Activity__c
            WHERE Id IN :activityIds
        ]);
        
        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            sked__Activity__c requestingStaffNCE = mapActivity.get(shiftTrade.requestingStaffNCEId);
            if (requestingStaffNCE != null) {
                shiftTrade.requestingStaffOtherTrades = filterDriveShiftTradesByExcludedTradeId(requestingStaffNCE.sked_Drive_Shift_Trades__r, shiftTrade.id);
                shiftTrade.requestingStaffOtherTrades2 = filterDriveShiftTradesByExcludedTradeId(requestingStaffNCE.sked_Drive_Shift_Trades2__r, shiftTrade.id);
            }

            sked__Activity__c tradingStaffNCE = mapActivity.get(shiftTrade.tradingStaffNCEId);
            if (tradingStaffNCE != null) {
                shiftTrade.tradingStaffOtherTrades = filterDriveShiftTradesByExcludedTradeId(tradingStaffNCE.sked_Drive_Shift_Trades__r, shiftTrade.id);
                shiftTrade.tradingStaffOtherTrades2 = filterDriveShiftTradesByExcludedTradeId(tradingStaffNCE.sked_Drive_Shift_Trades2__r, shiftTrade.id);
            }
        }

        return mapActivity;
    }

    private static List<sked_Drive_Shift_Trade__c> filterDriveShiftTradesByExcludedTradeId(List<sked_Drive_Shift_Trade__c> skedShiftTrades, Id tradeId) {
        for (Integer i = skedShiftTrades.size() - 1; i >= 0; i--) {
            if (skedShiftTrades[i].Id == tradeId) {
                skedShiftTrades.remove(i);
            }
        }

        return skedShiftTrades;
    }

    private static void loadResourcesData(List<driveShiftTradeModel> shiftTrades) {
        Set<Id> resourceIds = new Set<Id>();
        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            resourceIds.add(shiftTrade.requestingStaffId);
            resourceIds.add(shiftTrade.tradingStaffId);
        }

        Set<Id> accountIds = getAccountIds(shiftTrades);
        Set<Id> siteIds = getSiteIds(shiftTrades);
        period recordDatePeriod = getRecordDatePeriod(shiftTrades);

        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([
            SELECT Id, Name, sked_Max_Hours_Per_Week__c, sked_Min_Hours_Per_Week__c, sked_Turnaround_Time__c, sked__GeoLocation__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Shift_Swap_Cutoff__c, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
            (SELECT Id, sked__Tag__c, sked_Start_Date__c, sked__Tag__r.Name
             FROM sked__ResourceTags__r
             WHERE (sked_Role_Status__c = null OR sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE)),
            (SELECT Id, sked_Start_Date__c, sked_End_Date__c, sked_Total_Working_Time__c
             FROM sked_Resource_Hours_Records__r
             WHERE sked_Start_Date__c <= :recordDatePeriod.endDate
             AND sked_End_Date__c >= :recordDatePeriod.startDate),
            (SELECT Id, sked__Account__c
             FROM sked__Account_Resource_Scores__r
             WHERE sked__Account__c IN :accountIds
             AND sked_Account_Resource_Relationship__c = :skedConstants.ACCCOUNT_RESOURCE_SCORE_DECLINED),
            (SELECT Id, sked__Location__c
             FROM sked__Location_Resource_Scores__r
             WHERE sked__Location__c IN :siteIds
             AND sked_Location_Resource_Relationship__c = :skedConstants.LOCATION_RESOURCE_SCORE_DECLINED),
            (SELECT Id, sked_End_Date__c, sked_Start_Date__c, sked_Collection_Operation__c
             FROM sked__Resource_Overrides__r
             WHERE (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :recordDatePeriod.endDate) 
             AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :recordDatePeriod.startDate)),
            (SELECT Id, sked_Biomed_Collection_Op_Center__c, sked_Start_Date__c, sked_End_Date__c
             FROM sked_Resource_Biomed_Collection_Ops__r
             WHERE (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :recordDatePeriod.endDate) 
             AND (sked_End_Date__c = NULL OR sked_End_Date__c  >= :recordDatePeriod.startDate))
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);

        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            sked__Resource__c requestingStaff = mapResource.get(shiftTrade.requestingStaffId);
            if (requestingStaff != null) {
                shiftTrade.requestingStaffResourceHoursRecords = filterResourceHoursRecordsByRecordDate(requestingStaff.sked_Resource_Hours_Records__r, shiftTrade.tradingRecordDate);
                shiftTrade.requestingStaffAccountResourceScores = filterAccountResourceScoresByJob(requestingStaff.sked__Account_Resource_Scores__r, shiftTrade.tradingStaffJob);
                shiftTrade.requestingStaffLocationResourceScores = filterLocationResourceScoresByJob(requestingStaff.sked__Location_Resource_Scores__r, shiftTrade.tradingStaffJob);
                if (shiftTrade.requestingStaffRecordCOId == null) {
                    shiftTrade.requestingStaffRecordCOId = getRecordCOIdFromResource(requestingStaff, shiftTrade.requestingRecordDate);
                }
            }

            sked__Resource__c tradingStaff = mapResource.get(shiftTrade.tradingStaffId);
            if (tradingStaff != null) {
                shiftTrade.tradingStaffResourceHoursRecords = filterResourceHoursRecordsByRecordDate(tradingStaff.sked_Resource_Hours_Records__r, shiftTrade.requestingRecordDate);
                shiftTrade.tradingStaffAccountResourceScores = filterAccountResourceScoresByJob(tradingStaff.sked__Account_Resource_Scores__r, shiftTrade.requestingStaffJob);
                shiftTrade.tradingStaffLocationResourceScores = filterLocationResourceScoresByJob(tradingStaff.sked__Location_Resource_Scores__r, shiftTrade.requestingStaffJob);
                if (shiftTrade.tradingStaffRecordCOId == null) {
                    shiftTrade.tradingStaffRecordCOId = getRecordCOIdFromResource(tradingStaff, shiftTrade.tradingRecordDate);
                }
            }

            shiftTrade.requestingStaff = requestingStaff;
            shiftTrade.tradingStaff = tradingStaff;
        }
    }

    private static Id getRecordCOIdFromResource(sked__Resource__c resource, Date recordDate) {
        Id result = resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
        if (resource.sked__Resource_Overrides__r != null) {
            for (sked__Resource_Override__c resourceOverride : resource.sked__Resource_Overrides__r) {
                if ((resourceOverride.sked_Start_Date__c == null || resourceOverride.sked_Start_Date__c <= recordDate) && 
                    (resourceOverride.sked_End_Date__c == null || resourceOverride.sked_End_Date__c >= recordDate)) {
                    result = resourceOverride.sked_Collection_Operation__c;
                    break;
                }
            }
        }

        return result;
    }

    private static List<sked_Resource_Hours_Record__c> filterResourceHoursRecordsByRecordDate(List<sked_Resource_Hours_Record__c> resourceHoursRecords, Date recordDate) {
        List<sked_Resource_Hours_Record__c> result = new List<sked_Resource_Hours_Record__c>();
        for (sked_Resource_Hours_Record__c item : resourceHoursRecords) {
            if (item.sked_Start_Date__c <= recordDate && item.sked_End_Date__c >= recordDate) {
                result.add(item);
            }
        }
        return result;
    }
    
    private static List<sked__Account_Resource_Score__c> filterAccountResourceScoresByJob(List<sked__Account_Resource_Score__c> accountResourceScores, sked__Job__c job) {
        List<sked__Account_Resource_Score__c> result = new List<sked__Account_Resource_Score__c>();
        if (job != null) {
            for (sked__Account_Resource_Score__c item : accountResourceScores) {
                if (item.sked__Account__c == job.sked_Drive__r.sked_Account__c) {
                    result.add(item);
                }
            }
        }
        return result;
    }

    private static List<sked__Location_Resource_Score__c> filterLocationResourceScoresByJob(List<sked__Location_Resource_Score__c> locationResourceScores, sked__Job__c job) {
        List<sked__Location_Resource_Score__c> result = new List<sked__Location_Resource_Score__c>();
        if (job != null) {
            for (sked__Location_Resource_Score__c item : locationResourceScores) {
                if (item.sked__Location__c == job.sked__Location__c) {
                    result.add(item);
                }
            }
        }
        return result;
    }

    private static Set<Id> getAccountIds(List<driveShiftTradeModel> shiftTrades) {
        Set<Id> accountIds = new Set<Id>();
        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            if (!string.isBlank(shiftTrade.requestingStaffJobAllocationId)) {
                accountIds.add(shiftTrade.requestingStaffJob.sked_Drive__r.sked_Account__c);
            }
            if (!string.isBlank(shiftTrade.tradingStaffJobAllocationId)) {
                accountIds.add(shiftTrade.tradingStaffJob.sked_Drive__r.sked_Account__c);
            }
        }
        return accountIds;
    }
    
    private static Set<Id> getSiteIds(List<driveShiftTradeModel> shiftTrades) {
        Set<Id> siteIds = new Set<Id>();
        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            if (!string.isBlank(shiftTrade.requestingStaffJobAllocationId)) {
                siteIds.add(shiftTrade.requestingStaffJob.sked__Location__c);
            }
            if (!string.isBlank(shiftTrade.tradingStaffJobAllocationId)) {
                siteIds.add(shiftTrade.tradingStaffJob.sked__Location__c);
            }
        }
        return siteIds;
    }

    private static period getRecordDatePeriod(List<driveShiftTradeModel> shiftTrades) {
        Date startDate;
        Date endDate;
        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            if (shiftTrade.requestingRecordDate != null) {
                if (startDate == null || shiftTrade.requestingRecordDate < startDate) {
                    startDate = shiftTrade.requestingRecordDate;
                }
                if (endDate == null || shiftTrade.requestingRecordDate > endDate) {
                    endDate = shiftTrade.requestingRecordDate;
                }
            }
            if (shiftTrade.tradingRecordDate != null) {
                if (startDate == null || shiftTrade.tradingRecordDate < startDate) {
                    startDate = shiftTrade.tradingRecordDate;
                }
                if (endDate == null || shiftTrade.tradingRecordDate > endDate) {
                    endDate = shiftTrade.tradingRecordDate;
                }
            }
        }
        return new period(startDate, endDate);
    }

    private static void populateEventDataForRequest(
        List<driveShiftTradeModel> shiftTrades, 
        Map<Id, sked__Job__c> mapJob, 
        Map<Id, sked__Job_Allocation__c> mapJobAllocation, 
        Map<Id, sked__Activity__c> mapActivity, 
        Map<Id, Set<Id>> mapAssignedTagIdsByJobId, 
        Map<Id, Set<Id>> mapEventIdToOvernightActResourceIds
    ) {
        for (driveShiftTradeModel shiftTrade : shiftTrades) {
            if (!string.isBlank(shiftTrade.requestingStaffJobAllocationId)) {
                shiftTrade.requestingStaffJobAllocation = mapJobAllocation.get(shiftTrade.requestingStaffJobAllocationId);
                shiftTrade.requestingStaffJob = mapJob.get(shiftTrade.requestingStaffJobAllocation.sked__Job__c);
                shiftTrade.requestingStaffJobAssignedTagIds = mapAssignedTagIdsByJobId.get(shiftTrade.requestingStaffJob.Id);
                if (mapEventIdToOvernightActResourceIds.containsKey(shiftTrade.requestingStaffJob.Id)) {
                    shiftTrade.requestingStaffEventRelateOvernightActivity = mapEventIdToOvernightActResourceIds.get(shiftTrade.requestingStaffJob.Id).contains(shiftTrade.requestingStaffId);
                }
                shiftTrade.requestingStaffRecordCOId = shiftTrade.requestingStaffJob.sked_Drive__r.sked_Collection_Operation__c;
            }
            if (!string.isBlank(shiftTrade.tradingStaffJobAllocationId)) {
                shiftTrade.tradingStaffJobAllocation = mapJobAllocation.get(shiftTrade.tradingStaffJobAllocationId);
                shiftTrade.tradingStaffJob = mapJob.get(shiftTrade.tradingStaffJobAllocation.sked__Job__c);
                shiftTrade.tradingStaffJobAssignedTagIds = mapAssignedTagIdsByJobId.get(shiftTrade.tradingStaffJob.Id);
                if (mapEventIdToOvernightActResourceIds.containsKey(shiftTrade.tradingStaffJob.Id)) {
                    shiftTrade.tradingStaffEventRelateOvernightActivity = mapEventIdToOvernightActResourceIds.get(shiftTrade.tradingStaffJob.Id).contains(shiftTrade.tradingStaffId);
                }
                shiftTrade.tradingStaffRecordCOId = shiftTrade.tradingStaffJob.sked_Drive__r.sked_Collection_Operation__c;
            }
            if (!string.isBlank(shiftTrade.requestingStaffNCEId)) {
                shiftTrade.requestingStaffNCE = mapActivity.get(shiftTrade.requestingStaffNCEId);
                shiftTrade.requestingStaffRecordCOId = shiftTrade.requestingStaffNCE.sked_Collection_Operation__c;
            }
            if (!string.isBlank(shiftTrade.tradingStaffNCEId)) {
                shiftTrade.tradingStaffNCE = mapActivity.get(shiftTrade.tradingStaffNCEId);
                shiftTrade.tradingStaffRecordCOId = shiftTrade.tradingStaffNCE.sked_Collection_Operation__c;
            }

            shiftTrade.requestingStaffRecordId = getRecordId(shiftTrade.requestingStaffJob, shiftTrade.requestingStaffNCE);
            shiftTrade.tradingStaffRecordId = getRecordId(shiftTrade.tradingStaffJob, shiftTrade.tradingStaffNCE);
            shiftTrade.requestingRecordDate = getRecordDate(shiftTrade.requestingStaffJob, shiftTrade.requestingStaffNCE, shiftTrade.requestingStaffTradingAvailableDate);
            shiftTrade.tradingRecordDate = getRecordDate(shiftTrade.tradingStaffJob, shiftTrade.tradingStaffNCE, shiftTrade.tradingStaffTradingAvailableDate);
            if (shiftTrade.tradingRecordDate == null) {
                shiftTrade.tradingRecordDate = shiftTrade.requestingRecordDate;
            }
            shiftTrade.reasonApprovalRequired = new List<string>();
            shiftTrade.requestingStaffRelocated = false;
            shiftTrade.tradingStaffRelocated = false;
        }
    }

    private static void initialize(validateShiftTradesRequestModel request) {
        Map<Id, sked__Job_Allocation__c> mapJobAllocation = getMapJobAllocation(request.shiftTrades);
        Map<Id, sked__Job__c> mapJob = getMapJob(mapJobAllocation.values());
        Map<Id, sked__Activity__c> mapActivity = getMapActivity(request.shiftTrades);
        Map<Id, Set<Id>> mapAssignedTagIdsByJobId = getMapAssignedTagIdsByJobId(mapJob, mapJobAllocation.values());
        Map<Id, List<sked__Activity_Resource__c>> mapEventToOvernightActivityResources = getMapEventIdToOvernightActivityResources(mapJob.values());
        Map<Id, Set<Id>> mapEventIdToOvernightActResourceIds = getMapEventIdToOvernightActResourceIds(mapJob.values(), mapEventToOvernightActivityResources);
        populateEventDataForRequest(request.shiftTrades, mapJob, mapJobAllocation, mapActivity, mapAssignedTagIdsByJobId, mapEventIdToOvernightActResourceIds);
        loadResourcesData(request.shiftTrades);
    }

    private static Map<Id, Set<Id>> getMapAssignedTagIdsByJobId(Map<Id, sked__Job__c> mapJob, List<sked__Job_Allocation__c> jobAllocations) {
        Set<String> allJaAssignedRoles = new Set<String>();
        Map<Id, Set<String>> mapJobIdToAssignedRoles = new Map<Id, Set<String>>();
        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
            if (jobAllocation != null && jobAllocation.sked_Roles_Assignment_Str__c != null) {
                Set<String> assignedRoles = new Set<String>(jobAllocation.sked_Roles_Assignment_Str__c.split(', '));
                allJaAssignedRoles.addAll(assignedRoles);
                mapJobIdToAssignedRoles.put(jobAllocation.sked__Job__c, assignedRoles);
            }
        }

        Map<String, Id> mapRoleNameToTagId = new Map<String, Id>();
        for (sked__Tag__c tag : [
            SELECT Id, Name
            FROM sked__Tag__c
            WHERE Name IN :allJaAssignedRoles
        ]) {
            mapRoleNameToTagId.put(tag.Name, tag.Id);
        }

        Map<Id, Set<Id>> mapAssignedTagIdsByJobId = new Map<Id, Set<Id>>();
        for (sked__Job__c job : mapJob.values()) {
            Set<Id> assignedTagIds = new Set<Id>();
            Set<String> assignedRoles = mapJobIdToAssignedRoles.get(job.Id);
            if (assignedRoles != null) {
                for (String roleName : assignedRoles) {
                    if (mapRoleNameToTagId.containsKey(roleName)) {
                        assignedTagIds.add(mapRoleNameToTagId.get(roleName));
                    }
                }
            }

            for (sked__Job_Tag__c jobTag : job.sked__JobTags__r) {
                assignedTagIds.add(jobTag.sked__Tag__c);
            }

            mapAssignedTagIdsByJobId.put(job.Id, assignedTagIds);
        }

        return mapAssignedTagIdsByJobId;
    }

    private static Map<Id, Set<Id>> getMapEventIdToOvernightActResourceIds(List<sked__Job__c> jobs, Map<Id, List<sked__Activity_Resource__c>> mapEventToOvernightActivityResources) {
        Map<Id, Set<Id>>  mapEventIdToOvernightActResourceIds = new Map<Id, Set<Id>>();
        if (!jobs.isEmpty()) {
            for (sked__Job__c job : jobs) {
                List<sked__Activity_Resource__c> overnightActivityResources = new List<sked__Activity_Resource__c>();
                if (job.sked_Drive__c != null && mapEventToOvernightActivityResources.containsKey(job.sked_Drive__c)) {
                    overnightActivityResources.addAll(mapEventToOvernightActivityResources.get(job.sked_Drive__c));
                }
                if (job.sked_Drive__r.sked_Linked_Drives__c != null && mapEventToOvernightActivityResources.containsKey(job.sked_Drive__r.sked_Linked_Drives__c)) {
                    overnightActivityResources.addAll(mapEventToOvernightActivityResources.get(job.sked_Drive__r.sked_Linked_Drives__c));
                }
                for (sked__Activity_Resource__c activityResource : overnightActivityResources) {
                    if (!mapEventIdToOvernightActResourceIds.containsKey(job.Id)) {
                        mapEventIdToOvernightActResourceIds.put(job.Id, new Set<Id>());
                    }
                    mapEventIdToOvernightActResourceIds.get(job.Id).add(activityResource.sked__Resource__c);
                }
            }
        }
        
        return mapEventIdToOvernightActResourceIds;
    }

    private static Map<Id, List<sked__Activity_Resource__c>> getMapEventIdToOvernightActivityResources(List<sked__Job__c> jobs) {
        Map<Id, List<sked__Activity_Resource__c>> mapEventToOvernightActivityResources = new Map<Id, List<sked__Activity_Resource__c>>();
        if (!jobs.isEmpty()) {
            Set<Id> driveIds = new Set<Id>();
            Set<Id> linkedDriveIds = new Set<Id>();
            for (sked__Job__c job : jobs) {
                if (job.sked_Drive__c != null) {
                    driveIds.add(job.sked_Drive__c);
                }
                if (job.sked_Drive__r.sked_Linked_Drives__c != null) {
                    linkedDriveIds.add(job.sked_Drive__r.sked_Linked_Drives__c);
                }
            }
            skedQueryBuilder queryBuilder = new skedQueryBuilder();
            queryBuilder.setFromClause('sked__Activity_Resource__c');
            queryBuilder.addFields(new List<String>{
                'Id', 'sked__Activity__r.sked_Drive__c', 'sked__Activity__r.sked_Linked_Drives__c', 'sked__Resource__c', 'sked__Activity__c'
            });
            if (!driveIds.isEmpty() || !linkedDriveIds.isEmpty()) {
                queryBuilder.generateCondition('sked__Activity__r.sked__Type__c = {0}', skedConstants.ACTIVITY_TYPE_OVERNIGHT);
                List<String> driveOrLinkedDriveFilterConditions = new List<String>();
                if (!driveIds.isEmpty()) {
                    driveOrLinkedDriveFilterConditions.add('sked__Activity__r.sked_Drive__c IN :driveIds');
                }
                if (!linkedDriveIds.isEmpty()) {
                    driveOrLinkedDriveFilterConditions.add('sked__Activity__r.sked_Linked_Drives__c IN :linkedDriveIds');
                }
                queryBuilder.addCondition(String.join(driveOrLinkedDriveFilterConditions, ' OR '));
            }

            for (sked__Activity_Resource__c activityResource : (List<sked__Activity_Resource__c>)Database.query(queryBuilder.toString())) {
                if (activityResource.sked__Activity__r.sked_Drive__c != null) {
                    if (!mapEventToOvernightActivityResources.containsKey(activityResource.sked__Activity__r.sked_Drive__c)) {
                        mapEventToOvernightActivityResources.put(activityResource.sked__Activity__r.sked_Drive__c, new List<sked__Activity_Resource__c>());
                    }
                    mapEventToOvernightActivityResources.get(activityResource.sked__Activity__r.sked_Drive__c).add(activityResource);
                }
                if (activityResource.sked__Activity__r.sked_Linked_Drives__c != null) {
                    if (!mapEventToOvernightActivityResources.containsKey(activityResource.sked__Activity__r.sked_Linked_Drives__c)) {
                        mapEventToOvernightActivityResources.put(activityResource.sked__Activity__r.sked_Linked_Drives__c, new List<sked__Activity_Resource__c>());
                    }
                    mapEventToOvernightActivityResources.get(activityResource.sked__Activity__r.sked_Linked_Drives__c).add(activityResource);
                }
            }
        }
        
        return mapEventToOvernightActivityResources;
    }

    private static List<sked__Activity_Resource__c> getOvernightActivityResourcesRelateToJob(sked__Job__c job, Map<Id, List<sked__Activity_Resource__c>> mapEventToOvernightActivityResources) {
        List<sked__Activity_Resource__c> result = new List<sked__Activity_Resource__c>();
        if (job != null) {
            if (job.sked_Drive__c != null && mapEventToOvernightActivityResources.containsKey(job.sked_Drive__c)) {
                result.addAll(mapEventToOvernightActivityResources.get(job.sked_Drive__c));
            }
            if (job.sked_Drive__r.sked_Linked_Drives__c != null && mapEventToOvernightActivityResources.containsKey(job.sked_Drive__r.sked_Linked_Drives__c)) {
                result.addAll(mapEventToOvernightActivityResources.get(job.sked_Drive__r.sked_Linked_Drives__c));
            }
        }
        return result;
    }

    private static List<sked__Activity_Resource__c> findActivityResourcesByResourceId(Id resourceId, List<sked__Activity_Resource__c> activityResources) {
        List<sked__Activity_Resource__c> result = new List<sked__Activity_Resource__c>();
        if (activityResources != null) {
            for (sked__Activity_Resource__c activityResource : activityResources) {
                if (activityResource.sked__Resource__c == resourceId) {
                    result.add(activityResource);
                }
            }
        }

        return result;
    }

    private static void populateJATravelDataAfterTrade(validateShiftTradesRequestModel request) {
        skedJobAllocationTravelTimeService.jobAllocationTravelDataRequest travelDataRequest = new skedJobAllocationTravelTimeService.jobAllocationTravelDataRequest();
        for (driveShiftTradeModel shiftTrade: request.shiftTrades) {
            if (shiftTrade.tradingStaffJob != null) {
                travelDataRequest.jobAllocationRequestModels.add(new skedJobAllocationTravelTimeService.jobAllocationRequestModel(shiftTrade.requestingStaff.Id, shiftTrade.tradingStaffJob.Id));
            }
            if (shiftTrade.requestingStaffJob != null && shiftTrade.tradingStaff != null) {
                travelDataRequest.jobAllocationRequestModels.add(new skedJobAllocationTravelTimeService.jobAllocationRequestModel(shiftTrade.tradingStaff.Id, shiftTrade.requestingStaffJob.Id));
            }
        }
        
        skedJobAllocationTravelTimeService.jobAllocationTravelDataResult travelDataResult = skedJobAllocationTravelTimeService.calculateTravelTime(travelDataRequest);

        for (driveShiftTradeModel shiftTrade : request.shiftTrades) {
            if (travelDataResult != null) {
                if (shiftTrade.tradingStaffJob != null) {
                    shiftTrade.requestingStaffJATravelDataAfterTrade = shiftTrade.tradingStaffJob != null ? travelDataResult.getJobAllocationByResourceJobId(shiftTrade.requestingStaff.Id, shiftTrade.tradingStaffJob.Id) : null;
                }
                if (shiftTrade.tradingStaff != null) {
                    shiftTrade.tradingStaffJATravelDataAfterTrade = shiftTrade.requestingStaffJob != null ? travelDataResult.getJobAllocationByResourceJobId(shiftTrade.tradingStaff.Id, shiftTrade.requestingStaffJob.Id) : null;
                }
            }

            if (shiftTrade.requestingStaffJobAllocation != null && shiftTrade.requestingStaffJobAllocation.sked_GeoService_Travel_Distance_To__c != null) {
                shiftTrade.requestingStaffTravelDistanceBefore = shiftTrade.requestingStaffJobAllocation.sked_GeoService_Travel_Distance_To__c.setScale(1);
            }
    
            if (shiftTrade.requestingStaffJATravelDataAfterTrade != null && shiftTrade.requestingStaffJATravelDataAfterTrade.geoServiceTravelDistanceTo != null) {
                shiftTrade.requestingStaffTravelDistanceAfter = shiftTrade.requestingStaffJATravelDataAfterTrade.geoServiceTravelDistanceTo.setScale(1);
            }
    
            if (shiftTrade.tradingStaffJobAllocation != null && shiftTrade.tradingStaffJobAllocation.sked_GeoService_Travel_Distance_To__c != null) {
                shiftTrade.tradingStaffTravelDistanceBefore = shiftTrade.tradingStaffJobAllocation.sked_GeoService_Travel_Distance_To__c.setScale(1);
            }
    
            if (shiftTrade.tradingStaffJATravelDataAfterTrade != null && shiftTrade.tradingStaffJATravelDataAfterTrade.geoServiceTravelDistanceTo != null) {
                shiftTrade.tradingStaffTravelDistanceAfter = shiftTrade.tradingStaffJATravelDataAfterTrade.geoServiceTravelDistanceTo.setScale(1);
            }
        }
    }
    
    private static void doValidateRequest(validateShiftTradesRequestModel request) {
        for (driveShiftTradeModel shiftTrade : request.shiftTrades) {
            validateDuplicate(shiftTrade);
            validateCutoffRule(shiftTrade);
            validateMinMaxHoursRule(shiftTrade);
            validateRequiredTags(shiftTrade);
            validateTurnaroundRule(shiftTrade);
            validateLinkedDriveRule(shiftTrade);
            validateDeclinedAccountRule(shiftTrade);
            validateDeclinedSiteRule(shiftTrade);
            validateDoubleBooked(shiftTrade);
            validateGroupActivityApproval(shiftTrade);
            validateOvernightActivityApproval(shiftTrade);
            validateRelocationAndCOAvailability(shiftTrade);
            validateGuarded(shiftTrade);
        }
    }
    
    private static Id getRecordId(sked__Job__c skedJob, sked__Activity__c skedActivity) {
        return skedJob != null ? skedJob.Id : (skedActivity != null ? skedActivity.Id : null);
    }
    
    private static Date getRecordDate(sked__Job__c skedJob, sked__Activity__c skedActivity, Date availableDate) {
        return skedJob != null ? skedJob.sked_Drive__r.sked_Drive_Date__c : (skedActivity != null ? skedActivity.sked_Start_Date__c : availableDate);
    }
    
    private static void validateDuplicate(driveShiftTradeModel request) {
        request.requestingStaffingDuplicateTrades = new List<sked_Drive_Shift_Trade__c>();
        if (request.requestingStaffOtherTrades != null && !request.requestingStaffOtherTrades.isEmpty()) {
            request.requestingStaffingDuplicateTrades.addAll(request.requestingStaffOtherTrades);
        }
        if (request.requestingStaffOtherTrades2 != null && !request.requestingStaffOtherTrades2.isEmpty()) {
            request.requestingStaffingDuplicateTrades.addAll(request.requestingStaffOtherTrades2);
        }
    
        if (!request.requestingStaffingDuplicateTrades.isEmpty()) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DUPLICATE_TRADE);
        }
        
        request.tradingStaffingDuplicateTrades = new List<sked_Drive_Shift_Trade__c>();
        if (request.tradingStaffOtherTrades != null && !request.tradingStaffOtherTrades.isEmpty()) {
            request.tradingStaffingDuplicateTrades.addAll(request.tradingStaffOtherTrades);
        }
        if (request.tradingStaffOtherTrades2 != null && !request.tradingStaffOtherTrades2.isEmpty()) {
            request.tradingStaffingDuplicateTrades.addAll(request.tradingStaffOtherTrades2);
        }
        if (!request.tradingStaffingDuplicateTrades.isEmpty()) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DUPLICATE_TRADE);
        }
    }
    
    private static void validateCutoffRule(driveShiftTradeModel request) {
        boolean result = FALSE;
        
        decimal requestingShiftSwapCutoff = request.requestingStaff.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Shift_Swap_Cutoff__c;
        requestingShiftSwapCutoff = requestingShiftSwapCutoff != null ? requestingShiftSwapCutoff : 42;
        result = isCutoffRuleViolated(request.requestingRecordDate, requestingShiftSwapCutoff);
        
        if (result == FALSE && request.tradingStaff != NULL && request.tradingRecordDate != null) {
        decimal tradingShiftSwapCutoff = request.tradingStaff.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Shift_Swap_Cutoff__c;
        tradingShiftSwapCutoff = tradingShiftSwapCutoff != null ? tradingShiftSwapCutoff : 42;
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
    
    private static void validateMinMaxHoursRule(driveShiftTradeModel request) {
        request.requestingStaffGuaranteedMinHrsForfeited = FALSE;
        request.tradingStaffGuaranteedMinHrsForfeited = FALSE;
        
        Decimal requestingStaffDuration = 0;
        Boolean requestingStaff_isInSameWeek = false;
        if (request.requestingStaffResourceHoursRecords != NULL && !request.requestingStaffResourceHoursRecords.isEmpty()) {
            sked_Resource_Hours_Record__c resourceHoursRecord = request.requestingStaffResourceHoursRecords.get(0);
            if (resourceHoursRecord.sked_Total_Working_Time__c != null ) {
                requestingStaffDuration = integer.valueOf(resourceHoursRecord.sked_Total_Working_Time__c);
            }
            requestingStaff_isInSameWeek = resourceHoursRecord.sked_Start_Date__c <= request.tradingRecordDate && request.tradingRecordDate <= resourceHoursRecord.sked_End_Date__c
                && resourceHoursRecord.sked_Start_Date__c <= request.requestingRecordDate && request.requestingRecordDate <= resourceHoursRecord.sked_End_Date__c;
        }
        
        Decimal requestingStaffRecordDurationBeforeTrade = getRecordDuration(request.requestingStaffJobAllocation, request.requestingStaffNCE);
        Decimal requestingStaffRecordDurationAfterTrade = getRecordDuration(request.requestingStaffJATravelDataAfterTrade, request.tradingStaffNCE);
        
        Decimal tradingStaffDuration = 0;
        Boolean tradingStaff_isInSameWeek = false;
        if (request.tradingStaffResourceHoursRecords != NULL && !request.tradingStaffResourceHoursRecords.isEmpty()) {
            sked_Resource_Hours_Record__c resourceHoursRecord = request.tradingStaffResourceHoursRecords.get(0);
            if (resourceHoursRecord.sked_Total_Working_Time__c != null ) {
                tradingStaffDuration = integer.valueOf(resourceHoursRecord.sked_Total_Working_Time__c);
            }
            tradingStaff_isInSameWeek = resourceHoursRecord.sked_Start_Date__c <= request.tradingRecordDate && request.tradingRecordDate <= resourceHoursRecord.sked_End_Date__c
                && resourceHoursRecord.sked_Start_Date__c <= request.requestingRecordDate && request.requestingRecordDate <= resourceHoursRecord.sked_End_Date__c;
        }
        Decimal tradingStaffRecordDurationBeforeTrade = getRecordDuration(request.tradingStaffJobAllocation, request.tradingStaffNCE);
        Decimal tradingStaffRecordDurationAfterTrade = getRecordDuration(request.tradingStaffJATravelDataAfterTrade, request.requestingStaffNCE);  
        request.requestingStaffScheduledHoursBefore = requestingStaffDuration / 60;
        request.requestingStaffScheduledHoursBefore = request.requestingStaffScheduledHoursBefore.setScale(1);

        request.requestingStaffScheduledHoursAfter = (requestingStaffDuration - (requestingStaff_isInSameWeek ? requestingStaffRecordDurationBeforeTrade : 0) + requestingStaffRecordDurationAfterTrade) / 60;
        request.requestingStaffScheduledHoursAfter = request.requestingStaffScheduledHoursAfter.setScale(1);
        
        if (request.requestingStaff.sked_Max_Hours_Per_Week__c != null) {
            if (request.requestingStaffScheduledHoursAfter > request.requestingStaff.sked_Max_Hours_Per_Week__c) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_EXCEEDS_MAX_HOUR);
            }
        }
        
        if (request.requestingStaff.sked_Min_Hours_Per_Week__c != null) {
            if (request.requestingStaffScheduledHoursAfter < request.requestingStaffScheduledHoursBefore) {
                request.requestingStaffGuaranteedMinHrsForfeited = TRUE;
            }
        }
        request.tradingStaffScheduledHoursBefore = tradingStaffDuration / 60;
        request.tradingStaffScheduledHoursBefore = request.tradingStaffScheduledHoursBefore.setScale(1);
        request.tradingStaffScheduledHoursAfter = (tradingStaffDuration - (tradingStaff_isInSameWeek ? tradingStaffRecordDurationBeforeTrade : 0) + tradingStaffRecordDurationAfterTrade) / 60;
        request.tradingStaffScheduledHoursAfter = request.tradingStaffScheduledHoursAfter.setScale(1);

        if (request.tradingStaff.sked_Max_Hours_Per_Week__c != null) {
            if (request.tradingStaffScheduledHoursAfter > request.tradingStaff.sked_Max_Hours_Per_Week__c) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_EXCEEDS_MAX_HOUR);
            }
        }
        
        if (request.tradingStaff.sked_Min_Hours_Per_Week__c != null) {
            if (request.tradingStaffScheduledHoursAfter < request.tradingStaffScheduledHoursBefore) {
                request.tradingStaffGuaranteedMinHrsForfeited = TRUE;
            }
        }
    }
    
    private static decimal getRecordDuration(sked__Job_Allocation__c skedJobAllocation, sked__Activity__c skedActivity) {
        List<string> excludedActivityTypes = new List<string>();
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_ON_CALL);
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_AFTER_HOURS_CALL_OUT_MANAGEMENT);

        decimal duration = 0;
        if (skedJobAllocation != null) {
            duration = skedJobAllocation.sked__Duration__c;
        }
        if (skedActivity != null && !excludedActivityTypes.contains(skedActivity.sked__Type__c)) {
            duration = skedActivity.sked_Duration__c;
        }
        return duration;
    }

    private static decimal getRecordDuration(skedJobAllocationTravelTimeService.jobAllocationModel jobAllocation, sked__Activity__c skedActivity) {
        List<string> excludedActivityTypes = new List<string>();
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_ON_CALL);
        excludedActivityTypes.add(skedConstants.ACTIVITY_TYPE_AFTER_HOURS_CALL_OUT_MANAGEMENT);

        decimal duration = 0;
        if (jobAllocation != null) {
            duration = jobAllocation.duration;
        }
        if (skedActivity != null && !excludedActivityTypes.contains(skedActivity.sked__Type__c)) {
            duration = skedActivity.sked_Duration__c;
        }
        return duration;
    }
    
    private static void validateRequiredTags(driveShiftTradeModel request) {
        boolean isRequestingStaffHasRequiredTags = true;
        boolean isTradingStaffQualified = true;
        boolean isTradingStaffHasRequiredTags = true;
        boolean isRequestingStaffQualified = true;        

        if (request.requestingStaffJob != null && request.tradingStaff != null) {    
            isRequestingStaffHasRequiredTags = requiredTagChecking(request.requestingStaffJobAssignedTagIds, request.requestingStaffJob, request.requestingStaff);            
            isTradingStaffQualified = requiredTagChecking(request.requestingStaffJobAssignedTagIds, request.requestingStaffJob, request.tradingStaff);            
        }
        if (request.tradingStaffJob != null) {  
            isTradingStaffHasRequiredTags = requiredTagChecking(request.tradingStaffJobAssignedTagIds, request.tradingStaffJob, request.tradingStaff);            
            isRequestingStaffQualified = requiredTagChecking(request.tradingStaffJobAssignedTagIds, request.tradingStaffJob, request.requestingStaff);            
        }
        if(!isRequestingStaffHasRequiredTags || !isRequestingStaffQualified) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_MISSING_ROLE);
        }
        if(!isTradingStaffQualified || !isTradingStaffHasRequiredTags){
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_MISSING_ROLE); 
        }
    }
    
    private static boolean requiredTagChecking(Set<Id> jobAssignedTagIds, sked__Job__c job, sked__Resource__c resource) {
        boolean isValid = TRUE;
        if (jobAssignedTagIds != null && !jobAssignedTagIds.isEmpty()) {
            Set<Id> tagIds = new Set<Id>();
            for (sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {                
                if (resourceTag.sked_Start_Date__c <= job.sked_Drive__r.sked_Drive_Date__c) {
                    tagIds.add(resourceTag.sked__Tag__c);
                }                
            }            
            
            for (Id jobAssignedTagId : jobAssignedTagIds) {
                if (!tagIds.contains(jobAssignedTagId)) {
                    isValid = FALSE;
                    break;
                }                
            }
        }
        return isValid;
    }
    
    private static void validateTurnaroundRule(driveShiftTradeModel request) {
        request.requestingStaffTurnaroundViolation = FALSE;
        request.tradingStaffTurnaroundViolation = FALSE;
        
        if (request.tradingStaffJob != null) {
            if (request.requestingStaff.sked_Turnaround_Time__c != null) {
                Id requestingStaffJobId = request.requestingStaffJob != null ? request.requestingStaffJob.Id : null;
                Integer turnaroundTimeHours = Integer.valueOf(request.requestingStaff.sked_Turnaround_Time__c);
                boolean requestingStaffTurnaroundTimeValid = turnaroundTimeChecking(request.requestingStaff.Id, turnaroundTimeHours, 
                                                                                    requestingStaffJobId, 
                                                                                    request.requestingStaffJATravelDataAfterTrade);
                if (!requestingStaffTurnaroundTimeValid) {
                    request.requestingStaffTurnaroundViolation = TRUE;
                    request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_TAT_CONTENTION);
                }
            }
        }
        if (request.requestingStaffJob != null && request.tradingStaff != null) {
            if (request.tradingStaff.sked_Turnaround_Time__c != null) {
                Id tradingStaffJobId = request.tradingStaffJob != null ? request.tradingStaffJob.Id : null;
                Integer turnaroundTimeHours = Integer.valueOf(request.tradingStaff.sked_Turnaround_Time__c);
                boolean tradingStaffTurnaroundTimeValid = turnaroundTimeChecking(request.tradingStaffId, turnaroundTimeHours, 
                                                                                 tradingStaffJobId, 
                                                                                 request.tradingStaffJATravelDataAfterTrade);
                if (!tradingStaffTurnaroundTimeValid) {
                    request.tradingStaffTurnaroundViolation = TRUE;
                    request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_TAT_CONTENTION);
                }
            }
        }
    }  
    
    private static boolean turnaroundTimeChecking(Id resourceId, Integer turnaroundTimeHours, Id tradingJobId, skedJobAllocationTravelTimeService.jobAllocationModel jobAllocation) {
        DateTime allowedLatestJobFinishBefore = jobAllocation.start.addHours(-turnaroundTimeHours);
        DateTime allowedSoonestJobStartAfter = jobAllocation.setEnd.addHours(turnaroundTimeHours);
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
        boolean isRequestingStaffDriveLinked = request.requestingStaffJob != null && request.requestingStaffJob.sked_Drive__r.sked_Linked_Drives__c != null;
        if (isRequestingStaffDriveLinked) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DRIVE_PART_OF_LINKED);
        }
        
        boolean istradingStaffDriveLinked = request.tradingStaffJob != null && request.tradingStaffJob.sked_Drive__r.sked_Linked_Drives__c != null;
        if (istradingStaffDriveLinked) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DRIVE_PART_OF_LINKED);
        }
    }
    
    private static void validateDeclinedAccountRule(driveShiftTradeModel request) {
        if (request.tradingStaffJob != null) {
            boolean requestingStaffDeclinedAccountValid = declinedAccountChecking(request.requestingStaffAccountResourceScores, request.tradingStaffJob.sked_Drive__r.sked_Account__c);
            if (!requestingStaffDeclinedAccountValid) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_IS_DECLINED_FROM_ACCOUNT);
            }
        }
        if (request.requestingStaffJob != null) {
            boolean tradingStaffDeclinedAccountValid = declinedAccountChecking(request.tradingStaffAccountResourceScores, request.requestingStaffJob.sked_Drive__r.sked_Account__c);
            if (!tradingStaffDeclinedAccountValid) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_IS_DECLINED_FROM_ACCOUNT);
            }
        }
    }
    
    private static boolean declinedAccountChecking(List<sked__Account_Resource_Score__c> skedAccountResourceScores, Id accountId) {
        boolean result = TRUE;
        if (skedAccountResourceScores != null && !skedAccountResourceScores.isEmpty()) {
            for (sked__Account_Resource_Score__c declinedScore : skedAccountResourceScores) {
                if (declinedScore.sked__Account__c == accountId) {
                    result = FALSE;
                    break;
                }
            }
        }
        return result;
    }
    
    private static void validateDeclinedSiteRule(driveShiftTradeModel request) {
        if (request.tradingStaffJob != null) {
            boolean requestingStaffDeclinedSiteValid = declinedSiteChecking(request.requestingStaffLocationResourceScores, request.tradingStaffJob.sked__Location__c);
            if (!requestingStaffDeclinedSiteValid) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_IS_DECLINED_FROM_SITE);
            }
        }
        if (request.requestingStaffJob != null) {
            boolean tradingStaffDeclinedSiteValid = declinedSiteChecking(request.tradingStaffLocationResourceScores, request.requestingStaffJob.sked__Location__c);
            if (!tradingStaffDeclinedSiteValid) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_IS_DECLINED_FROM_SITE);
            }
        }
    }
    
    private static boolean declinedSiteChecking(List<sked__Location_Resource_Score__c> skedLocationResourceScores, Id siteId) {
        boolean result = TRUE;
        if (skedLocationResourceScores != null && !skedLocationResourceScores.isEmpty()) {
            for (sked__Location_Resource_Score__c declinedScore : skedLocationResourceScores) {
                if (declinedScore.sked__Location__c == siteId) {
                    result = FALSE;
                    break;
                }
            }
        }
        return result;
    }
    
    private static void validateDoubleBooked(driveShiftTradeModel request) {
        if (request.tradingStaffRecordId != null) {
            boolean requestingStaffDoubleBookedValid = doubleBookedChecking(request.requestingStaff, request.tradingStaffRecordId);
            if (!requestingStaffDoubleBookedValid) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_IS_ALREADY_ASSIGNED);
            }
        }
        if (request.requestingStaffRecordId != null && request.tradingStaff != null) {
            boolean tradingStaffDoubleBookedValid = doubleBookedChecking(request.tradingStaff, request.requestingStaffRecordId);
            if (!tradingStaffDoubleBookedValid) {
                request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_IS_ALREADY_ASSIGNED);
            }
        }
    }
    
    private static boolean doubleBookedChecking(sked__Resource__c resource, Id eventId) {
        if (resource.sked__Job_Allocations__r != null && !resource.sked__Job_Allocations__r.isEmpty()) {
            for (sked__Job_Allocation__c allocation : resource.sked__Job_Allocations__r) {
                if (allocation.sked__Job__c == eventId) {
                    return FALSE;
                }
            }
        }
        if (resource.sked__Activity_Resources__r != null && !resource.sked__Activity_Resources__r.isEmpty()) {
            for (sked__Activity_Resource__c allocation : resource.sked__Activity_Resources__r) {
                if (allocation.sked__Activity__c == eventId) {
                    return FALSE;
                }
            }
        }
        return TRUE;
    }

    private static void validateGroupActivityApproval(driveShiftTradeModel request) {
        boolean isGroupActivityNeedsApproval = (request.requestingStaffNCE != null && request.requestingStaffNCE.sked__Type__c != skedConstants.ACTIVITY_TYPE_ON_CALL)
            || (request.tradingStaffNCE != null && request.tradingStaffNCE.sked__Type__c != skedConstants.ACTIVITY_TYPE_ON_CALL);
        if (isGroupActivityNeedsApproval) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_GROUP_ACTIVITY_TRADE_NEEDS_APPROVAL);
        }
    }

    private static void validateOvernightActivityApproval(driveShiftTradeModel request) {
        if (request.requestingStaffEventRelateOvernightActivity == true) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_OVERNIGHT_ACTIVITY);
        }
        
        if (request.tradingStaffEventRelateOvernightActivity == true) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_OVERNIGHT_ACTIVITY);
        }
    }

    private static void validateRelocationAndCOAvailability(driveShiftTradeModel request) {
        validateRelocationStatus(request);
        validateCOAvailabilityStatus(request);
    }

    private static void validateRelocationStatus(driveShiftTradeModel request) {
        request.requestingStaffRelocated = false;
        request.tradingStaffRelocated = false;

        sked__Resource__c requestingStaff = request.requestingStaff;
        if (requestingStaff != null && requestingStaff.sked__Resource_Overrides__r != null) {
            for (sked__Resource_Override__c requestingResourceOverride : requestingStaff.sked__Resource_Overrides__r) {
                if (requestingResourceOverride.sked_Start_Date__c <= request.tradingRecordDate && request.tradingRecordDate <= requestingResourceOverride.sked_End_Date__c) {
                    request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_RELOCATED);
                    request.requestingStaffRelocated = true;
                    break;
                }
            }
        }

        sked__Resource__c tradingStaff = request.tradingStaff;
        if (tradingStaff != null && tradingStaff.sked__Resource_Overrides__r != null) {
            for (sked__Resource_Override__c tradingResourceOverride : tradingStaff.sked__Resource_Overrides__r) {
                if (tradingResourceOverride.sked_Start_Date__c <= request.requestingRecordDate && request.requestingRecordDate <= tradingResourceOverride.sked_End_Date__c) {
                    request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_RELOCATED);
                    request.tradingStaffRelocated = true;
                    break;
                }
            }
        }
    }

    private static void validateCOAvailabilityStatus(driveShiftTradeModel request) {
        request.requestingStaffUnavailableForCO = false;
        request.tradingStaffUnavailableForCO = false;
        List<string> includedTradingTypes = new List<string>{
            skedConstants.DRIVE_SHIFT_TRADE_TRADING_TYPE_DRIVE_SHIFT,
            skedConstants.DRIVE_SHIFT_TRADE_TRADING_TYPE_ACTIVITY
        };
        if (request.requestingStaff != null && !request.requestingStaffRelocated && 
            request.tradingStaffTradingType != null && includedTradingTypes.contains(request.tradingStaffTradingType) && 
            !isCOAvailable(request.requestingStaff, request.tradingRecordDate, request.tradingStaffRecordCOId)
        ) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_UNAVAILABLE_FOR_CO);
            request.requestingStaffUnavailableForCO = true;
        }

        if (request.tradingStaff != null && !request.tradingStaffRelocated && 
            request.requestingStaffTradingType != null && includedTradingTypes.contains(request.requestingStaffTradingType) && 
            !isCOAvailable(request.tradingStaff, request.requestingRecordDate, request.requestingStaffRecordCOId)
        ) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_UNAVAILABLE_FOR_CO);
            request.tradingStaffUnavailableForCO = true;
        }
    }

    private static boolean isCOAvailable(sked__Resource__c resource, Date targetRecordDate, Id targetCOId) {
        List<String> resourceAssignedCOIds = new List<String> { resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c };
        if (resource.sked_Resource_Biomed_Collection_Ops__r != null) {
            for (sked_Resource_Biomed_Collection_Op__c resourceSecondaryCO : resource.sked_Resource_Biomed_Collection_Ops__r) {
                if ((resourceSecondaryCO.sked_Start_Date__c == null || resourceSecondaryCO.sked_Start_Date__c <= targetRecordDate) &&
                    (resourceSecondaryCO.sked_End_Date__c == null || resourceSecondaryCO.sked_End_Date__c >= targetRecordDate)
                ) {
                    resourceAssignedCOIds.add(resourceSecondaryCO.sked_Biomed_Collection_Op_Center__c);
                }
            }
        }

        return resourceAssignedCOIds.contains(targetCOId);
    }

    private static void validateGuarded(driveShiftTradeModel request) {
        boolean isRequestingStaffGuarded = request.requestingStaffJobAllocation != null && request.requestingStaffJobAllocation.sked_Guarded__c == true;
        if (isRequestingStaffGuarded) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_GUARDED);
        }
        
        boolean isTradingStaffGuarded = request.tradingStaffJobAllocation != null && request.tradingStaffJobAllocation.sked_Guarded__c == true;
        if (isTradingStaffGuarded) {
            request.reasonApprovalRequired.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_GUARDED);
        }
    }
    
    public static List<string> getHardViolationContentions() {
        List<string> hardViolationContentions = new List<string>();
        hardViolationContentions.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DUPLICATE_TRADE);
        hardViolationContentions.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DUPLICATE_TRADE);
        hardViolationContentions.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_IS_ALREADY_ASSIGNED);
        hardViolationContentions.add(skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_IS_ALREADY_ASSIGNED);
        return hardViolationContentions;
    }

    public static List<string> getCompletedStatuses() {
        List<String> shiftTradeCompletedStatuses = new List<String>{
            skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED,
            skedConstants.DRIVE_SHIFT_TRADE_STATUS_CANCELLED,
            skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED,
            skedConstants.DRIVE_SHIFT_TRADE_STATUS_EXPIRED
        };
        return shiftTradeCompletedStatuses;
    }

    public static void createShiftTradeAPIData(Set<Id> recordIds, String approverEmail) {
        List<sked_Drive_Shift_Trade__c> records = [
            SELECT Id, sked_Requesting_Staff__c, sked_Requesting_Staff__r.sked_Employee_Id__c, 
            sked_Requesting_Staff_Drive_Date__c, sked_Requesting_Staff_Job_Allocation__c,
            sked_Requesting_Staff_Job_Allocation__r.sked_Job_Timezone__c,
            sked_Requesting_Staff_Job_Allocation__r.sked__Job__r.sked_Drive__c,
            sked_Requesting_Staff_NCE__c, sked_Requesting_Staff_NCE__r.sked_Start_Date__c,
            sked_Requesting_Staff_NCE__r.sked__Timezone__c,
            sked_Requesting_Staff_Trading_Type__c,
            sked_Trading_Staff__c, sked_Trading_Staff__r.sked_Employee_Id__c,
            sked_Trading_Staff_Drive_Date__c, sked_Trading_Staff_Job_Allocation__c,
            sked_Trading_Staff_Job_Allocation__r.sked_Job_Timezone__c,
            sked_Trading_Staff_Job_Allocation__r.sked__Job__r.sked_Drive__c,
            sked_Trading_Staff_NCE__c, sked_Trading_Staff_NCE__r.sked_Start_Date__c,
            sked_Trading_Staff_NCE__r.sked__Timezone__c,
            sked_Trading_Staff_Trading_Type__c
            FROM sked_Drive_Shift_Trade__c
            WHERE Id IN : recordIds
        ];

        Set<String> tradingFromKeys = new Set<String>();
        List<sked_Trade_API_Data__c> tradeApiData = new List<sked_Trade_API_Data__c>();
        for (sked_Drive_Shift_Trade__c record : records) {
            String requestingStaffEventTimezone;
            sked_Trade_API_Data__c requestingStaffData = new sked_Trade_API_Data__c();
            requestingStaffData.sked_Resource__c = record.sked_Requesting_Staff__c;
            requestingStaffData.sked_From_Resource__c = record.sked_Trading_Staff__c;
            requestingStaffData.sked_Approver_Email__c = approverEmail;
            requestingStaffData.sked_Time_Entry_Code__c = 'Traded Shift';
            requestingStaffData.sked_Quantity__c = 1;
            if (record.sked_Trading_Staff_Trading_Type__c == 'Drive Shift') {
                requestingStaffData.sked_Event_Id__c = (String) record.sked_Trading_Staff_Job_Allocation__r.sked__Job__r.sked_Drive__c;
                requestingStaffData.sked_Event_Date__c = record.sked_Trading_Staff_Drive_Date__c;
                requestingStaffEventTimezone = record.sked_Trading_Staff_Job_Allocation__r.sked_Job_Timezone__c;
            } else if (record.sked_Trading_Staff_Trading_Type__c == 'Activity') {
                requestingStaffData.sked_Event_Id__c = (String) record.sked_Trading_Staff_NCE__c;
                requestingStaffData.sked_Event_Date__c = record.sked_Trading_Staff_NCE__r.sked_Start_Date__c;
                requestingStaffEventTimezone = record.sked_Trading_Staff_NCE__r.sked__Timezone__c;
            }

            String tradingStaffEventTimezone;
            sked_Trade_API_Data__c tradingStaffData = new sked_Trade_API_Data__c();
            tradingStaffData.sked_Resource__c = record.sked_Trading_Staff__c;
            tradingStaffData.sked_From_Resource__c = record.sked_Requesting_Staff__c;
            tradingStaffData.sked_Approver_Email__c = approverEmail;
            tradingStaffData.sked_Time_Entry_Code__c = 'Traded Shift';
            tradingStaffData.sked_Quantity__c = 1;
            if (record.sked_Requesting_Staff_Trading_Type__c == 'Drive Shift') {
                tradingStaffData.sked_Event_Id__c = (String) record.sked_Requesting_Staff_Job_Allocation__r.sked__Job__r.sked_Drive__c;
                tradingStaffData.sked_Event_Date__c = record.sked_Requesting_Staff_Drive_Date__c;   
                tradingStaffEventTimezone = record.sked_Requesting_Staff_Job_Allocation__r.sked_Job_Timezone__c;
            } else if (record.sked_Requesting_Staff_Trading_Type__c == 'Activity') {
                tradingStaffData.sked_Event_Id__c = (String) record.sked_Requesting_Staff_NCE__c;
                tradingStaffData.sked_Event_Date__c = record.sked_Requesting_Staff_NCE__r.sked_Start_Date__c;
                tradingStaffEventTimezone = record.sked_Requesting_Staff_NCE__r.sked__Timezone__c;
            }

            if (requestingStaffData.sked_Event_Id__c != null) {
                tradingFromKeys.add(requestingStaffData.sked_Event_Id__c + ':' + requestingStaffData.sked_From_Resource__c + ':' + String.valueOf(requestingStaffData.sked_Event_Date__c));
                tradeApiData.add(requestingStaffData);
            }

            if (tradingStaffData.sked_Event_Id__c != null) {
                tradingFromKeys.add(tradingStaffData.sked_Event_Id__c + ':' + tradingStaffData.sked_From_Resource__c + ':' + String.valueOf(tradingStaffData.sked_Event_Date__c));
                tradeApiData.add(tradingStaffData);
            }
        }

        if (!tradingFromKeys.isEmpty()) {
            List<sked_Trade_API_Data__c> existingTrades = [
                SELECT Id, sked_Status__c
                FROM sked_Trade_API_Data__c
                WHERE sked_Trade_Into_Key__c IN :tradingFromKeys
                AND sked_Status__c = :skedConstants.TRADE_API_DATA_STATUS_QUEUED
            ];
            if (!existingTrades.isEmpty()) {
                for (sked_Trade_API_Data__c trade : existingTrades) {
                    trade.sked_Status__c = skedConstants.TRADE_API_DATA_STATUS_NOT_APPLICABLE;
                }
            }

            update existingTrades;
        }

        insert tradeApiData;
    }
    
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'performShiftTrades' {
                    performShiftTrades((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));
                }
                when 'createShiftTradeAPIData' {
                    createShiftTradeAPIData(
                        (Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class),
                        (String) JSON.deserialize((String) params.get('param2'), String.class)
                    );
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: slwcDriveShiftTradeService');
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        } catch (Exception ex) {
            BSF_Error_Log__c errorLog = BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                'slwcDriveShiftTradeService',
                'call.' + methodName,
                ex.getMessage(),
                ex.getMessage(),
                'sked_Drive_Shift_Trade__c',
                (String) params.get('param1')
            );
            if (errorLog != null) {
                Database.insert(new List<BSF_Error_Log__c>{ errorLog }, false);
            }
            result.addError(ex);
        }

        return result;
    }
    
    /* Nest classes */
    public class driveShiftTradeModel {
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public string requestingStaffId {get;set;}
        @AuraEnabled public string requestingStaffJobAllocationId {get;set;}
        @AuraEnabled public string requestingStaffNCEId {get;set;}
        @AuraEnabled public string requestingStaffTradingType {get;set;}
        @AuraEnabled public string tradingStaffId {get;set;}
        @AuraEnabled public string tradingStaffJobAllocationId {get;set;}
        @AuraEnabled public string tradingStaffNCEId {get;set;}
        @AuraEnabled public string tradingStaffTradingType {get;set;}
        @AuraEnabled public Date requestingStaffTradingAvailableDate {get;set;}
        @AuraEnabled public Date tradingStaffTradingAvailableDate {get;set;}
        
        public sked__Job_Allocation__c requestingStaffJobAllocation;
        public Set<Id> requestingStaffJobAssignedTagIds;
        public List<sked_Drive_Shift_Trade__c> requestingStaffOtherTrades;
        public List<sked_Drive_Shift_Trade__c> requestingStaffOtherTrades2;
        public List<sked_Resource_Hours_Record__c> requestingStaffResourceHoursRecords;
        public List<sked__Account_Resource_Score__c> requestingStaffAccountResourceScores;
        public List<sked__Location_Resource_Score__c> requestingStaffLocationResourceScores;
        public skedJobAllocationTravelTimeService.jobAllocationModel requestingStaffJATravelDataAfterTrade;
        public sked__Job_Allocation__c tradingStaffJobAllocation;
        public Set<Id> tradingStaffJobAssignedTagIds;
        public List<sked_Drive_Shift_Trade__c> tradingStaffOtherTrades;
        public List<sked_Drive_Shift_Trade__c> tradingStaffOtherTrades2;
        public List<sked_Resource_Hours_Record__c> tradingStaffResourceHoursRecords;
        public List<sked__Account_Resource_Score__c> tradingStaffAccountResourceScores;
        public List<sked__Location_Resource_Score__c> tradingStaffLocationResourceScores;
        public skedJobAllocationTravelTimeService.jobAllocationModel tradingStaffJATravelDataAfterTrade;
        public sked__Job__c requestingStaffJob;
        public sked__Job__c tradingStaffJob;
        public sked__Activity__c requestingStaffNCE;
        public sked__Activity__c tradingStaffNCE;
        public sked__Resource__c requestingStaff;
        public sked__Resource__c tradingStaff;
        public Date requestingRecordDate;
        public Date tradingRecordDate;
        
        public Id requestingStaffRecordId;
        public Id tradingStaffRecordId;
        public Id requestingStaffRecordCOId;
        public Id tradingStaffRecordCOId;
        
        public boolean requestingStaffTurnaroundViolation;
        public boolean tradingStaffTurnaroundViolation;
        public boolean requestingStaffGuaranteedMinHrsForfeited;
        public boolean tradingStaffGuaranteedMinHrsForfeited;
        public boolean requestingStaffEventRelateOvernightActivity;
        public boolean tradingStaffEventRelateOvernightActivity;
        public boolean requestingStaffRelocated;
        public boolean tradingStaffRelocated;
        public boolean requestingStaffUnavailableForCO;
        public boolean tradingStaffUnavailableForCO;
        
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
    
    public class validateResponseModel {
        @AuraEnabled public List<driveShiftTradeValidationResult> shiftTradeValidationResults; 

        public validateResponseModel() {
            shiftTradeValidationResults = new List<driveShiftTradeValidationResult>();
        }
    }

    public class driveShiftTradeValidationResult {
        @AuraEnabled public String id;
        @AuraEnabled public boolean requestingStaffTurnaroundViolation;
        @AuraEnabled public boolean tradingStaffTurnaroundViolation;
        @AuraEnabled public boolean requestingStaffGuaranteedMinHrsForfeited;
        @AuraEnabled public boolean tradingStaffGuaranteedMinHrsForfeited;
        @AuraEnabled public boolean requestingStaffRelocated;
        @AuraEnabled public boolean tradingStaffRelocated;
        @AuraEnabled public boolean requestingStaffUnavailableForCO;
        @AuraEnabled public boolean tradingStaffUnavailableForCO;
        @AuraEnabled public List<contentionModel> contentions {get;set;}
    }
    
    public class contentionModel {
        @AuraEnabled public string contention {get;set;}
        @AuraEnabled public boolean hardViolation {get;set;}
    }

    public class validateShiftTradesRequestModel {
        @AuraEnabled public List<driveShiftTradeModel> shiftTrades {get;set;}
    }

    public class period {
        public Date startDate;
        public Date endDate;

        public period(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
}