public class skedWorkdayUtils implements Callable {
    private static final Set<String> NON_SYNC_WORKDAY_STATUSES = new Set<String>{
        skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_NA,
        skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_MANUAL
    };

    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'handleWorkdayApprovals' {
                    handleWorkdayApprovals(
                        (Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class)
                    );
                }
                when 'handleWorkdayAdjustments' {
                    handleWorkdayAdjustments(
                        (List<Id>) JSON.deserialize((String) params.get('param1'), List<Id>.class),
                        (Map<Id, Decimal>) JSON.deserialize((String) params.get('param2'), Map<Id, Decimal>.class),
                        (Map<Id, Id>) JSON.deserialize((String) params.get('param3'), Map<Id, Id>.class),
                        (Map<Id, String>) JSON.deserialize((String) params.get('param4'), Map<Id, String>.class),
                        false
                    );
                }
                when 'handleWorkdayCancellations' {
                    handleWorkdayAdjustments(
                        (List<Id>) JSON.deserialize((String) params.get('param1'), List<Id>.class),
                        (Map<Id, Decimal>) JSON.deserialize((String) params.get('param2'), Map<Id, Decimal>.class),
                        (Map<Id, Id>) JSON.deserialize((String) params.get('param3'), Map<Id, Id>.class),
                        (Map<Id, String>) JSON.deserialize((String) params.get('param4'), Map<Id, String>.class),
                        true
                    );
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedWorkdayUtils.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }
        return result;
    }

    public static void publishWorkdayApprovalsEvent(Set<Id> approvedRecordIds) {
        skedFutureCallEventHandler.publishFutureCallEvent(
            skedWorkdayUtils.class.getName(),
            'handleWorkdayApprovals',
            approvedRecordIds
        );
    }

    public static void publishWorkdayAdjustmentsEvent(workdayAdjustmentsContainer adjustments) {
        skedFutureCallEventHandler.publishFutureCallEvent(
            skedWorkdayUtils.class.getName(),
            'handleWorkdayAdjustments',
            adjustments.recordIds,
            adjustments.adjustmentValById,
            adjustments.resourceIdByAvailId,
            adjustments.employeeIdByResourceId
        );
    }

    public static void publishWorkdayCancellationsEvent(workdayAdjustmentsContainer adjustments) {
        skedFutureCallEventHandler.publishFutureCallEvent(
            skedWorkdayUtils.class.getName(),
            'handleWorkdayCancellations',
            adjustments.recordIds,
            adjustments.adjustmentValById,
            adjustments.resourceIdByAvailId,
            adjustments.employeeIdByResourceId
        );
    }

    public static skedUnavailabilityBalanceResultModel verifyUnavailabilityBalance(sked__Resource__c res, Date availDate, Decimal duration, String timeOffType) {
        List<String> balanceTypesToCheck = new List<String>{
            skedConstants.UNAVAILABILITY_TYPE_PTO,
            skedConstants.UNAVAILABILITY_TYPE_FLOATING_HOLIDAY,
            skedConstants.UNAVAILABILITY_TYPE_SICK
        };
        skedUnavailabilityBalanceResultModel result = new skedUnavailabilityBalanceResultModel();
        result.noOfRequestedHours = duration / 60;
        result.hasEnoughHours = true;

        skedWorkdayGetPlanBalanceResponse availableHoursResponse;
        if (skedSetting.instance.Admin.workdayIntegration) {
            skedWorkdayGetPlanBalanceRequest availableHoursRequest = new skedWorkdayGetPlanBalanceRequest();
            availableHoursRequest.employeeId = res.sked_Employee_Id__c;
            availableHoursRequest.selectedDate = availDate;
            availableHoursRequest.resourceId = res.Id;
            availableHoursResponse = skedWorkdayApiManager.getTimeOffPlanBalances(availableHoursRequest);
            
            if (balanceTypesToCheck.contains(timeOffType)) {
                result.noOfAvailableHours = 0;
                result.hasEnoughHours = false;
                if (availableHoursResponse.timeOffPlansByLabel.containsKey(timeOffType)) {
                    Decimal totalBalance = availableHoursResponse.timeOffPlansByLabel.get(timeOffType).balance + getApprovedTimeOffHours(res, availDate, timeOffType);
                    result.hasEnoughHours = totalBalance >= result.noOfRequestedHours;
                    result.noOfAvailableHours = totalBalance;
                }
            }
        }
        
        return result;
    } 

    public static void initiateFullWorkdaySync(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Availability__c record : newRecords) {
            resourceIds.add(record.sked__Resource__c);
        }

        Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>([
            SELECT Id, sked_Daily_Time_Off_Hours__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);

        publishWorkdayApprovalsEvent(getApprovedRecordIds(newRecords, oldMap));
        publishWorkdayAdjustmentsEvent(getAdjustmentsContainer(newRecords, oldMap, resourceById));
        publishWorkdayCancellationsEvent(getCancellationsContainer(newRecords, oldMap, resourceById));
    }

    public static Set<Id> getApprovedRecordIds(List<sked__Availability__c> records) {
        Set<Id> approvedRecordIds = new Set<Id>();
        Set<string> unavailabilityTypesToSync = getUnavailabilityTypesToSync();
        
        for (sked__Availability__c record : records) {
            if (record.sked_Integrate_With_Workday__c && unavailabilityTypesToSync.contains(record.sked__Type__c)) {
                if (record.sked__Type__c == skedConstants.AVAILABILITY_TYPE_CALL_OUT && record.sked_Time_Off_Plan__c == null) { continue; }
                    
                if (record.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_PROCESSING_APPROVAL) {
                    approvedRecordIds.add(record.Id);
                }
            }
        }

        return approvedRecordIds;
    }

	private static Set<Id> getApprovedRecordIds(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<Id> approvedRecordIds = new Set<Id>();
        Set<string> unavailabilityTypesToSync = getUnavailabilityTypesToSync();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Integrate_With_Workday__c && unavailabilityTypesToSync.contains(newRecord.sked__Type__c)) {
                if (oldData.sked_Custom_Status__c != newRecord.sked_Custom_Status__c && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_PROCESSING_APPROVAL) {
                    approvedRecordIds.add(newRecord.Id);
                }
            }
        }

        return approvedRecordIds;
    }

    private static workdayAdjustmentsContainer getAdjustmentsContainer(List<sked__Availability__c> newRecords, 
            Map<Id, sked__Availability__c> oldMap, Map<Id, sked__Resource__c> resourceById) {

        workdayAdjustmentsContainer adjustedRecordDetails = new workdayAdjustmentsContainer();
        Set<String> unavailabilityTypesToSync = getUnavailabilityTypesToSync();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Resource__c availablityResource = resourceById.get(newRecord.sked__Resource__c);
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Integrate_With_Workday__c && unavailabilityTypesToSync.contains(newRecord.sked__Type__c)) {
                if (skedConstants.AVAILABILITY_APPROVED_STATUSES.contains(oldData.sked_Custom_Status__c) && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_PROCESSING_ADJUSTMENT) {
                    if (oldData.sked_Duration__c != newRecord.sked_Duration__c) {
                        adjustedRecordDetails.recordIds.add(newRecord.Id);
                        adjustedRecordDetails.adjustmentValById.put(newRecord.Id, getAdjustmentValue(newRecord, oldData, availablityResource));
                        adjustedRecordDetails.resourceIdByAvailId.put(newRecord.Id, newRecord.sked__Resource__c);
                        adjustedRecordDetails.employeeIdByResourceId.put(newRecord.sked__Resource__c, newRecord.sked_Employee_Id__c);
                    }
                }
            }
        }

        return adjustedRecordDetails;
    }

    public static workdayAdjustmentsContainer getCancellationsContainer(List<sked__Availability__c> deletedRecords) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Availability__c record : deletedRecords) {
            resourceIds.add(record.sked__Resource__c);
        }

        Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>([
            SELECT Id, sked_Daily_Time_Off_Hours__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);

        workdayAdjustmentsContainer cancelledRecordDetails = new workdayAdjustmentsContainer();
        for (sked__Availability__c deletedRecord : deletedRecords) {
            if (!deletedRecord.sked_Integrate_With_Workday__c) continue;
            sked__Resource__c availabilityResource = resourceById.get(deletedRecord.sked__Resource__c);
            cancelledRecordDetails.recordIds.add(deletedRecord.Id);
            cancelledRecordDetails.adjustmentValById.put(deletedRecord.Id, getWorkdayPtoHours(deletedRecord, availabilityResource)*-1);
            cancelledRecordDetails.resourceIdByAvailId.put(deletedRecord.Id, deletedRecord.sked__Resource__c);
            cancelledRecordDetails.employeeIdByResourceId.put(deletedRecord.sked__resource__c, deletedRecord.sked_Employee_Id__c);
        }
        return cancelledRecordDetails;
    }

    public static workdayAdjustmentsContainer getCancellationsContainer(List<sked__Availability__c> newRecords, 
            Map<Id, sked__Availability__c> oldMap, Map<Id, sked__Resource__c> resourceById) {
        workdayAdjustmentsContainer cancelledRecordDetails = new workdayAdjustmentsContainer();
        Set<string> unavailabilityTypesToSync = getUnavailabilityTypesToSync();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Integrate_With_Workday__c && unavailabilityTypesToSync.contains(newRecord.sked__Type__c)) {
                if (skedConstants.AVAILABILITY_APPROVED_STATUSES.contains(oldData.sked_Custom_Status__c) && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_PROCESSING_CANCELLATION) {
                    sked__Resource__c availabilityResource = resourceById.get(newRecord.sked__Resource__c);
                    cancelledRecordDetails.recordIds.add(newRecord.Id);
                    cancelledRecordDetails.adjustmentValById.put(newRecord.Id, getWorkdayPtoHours(newRecord, availabilityResource)*-1);
                    cancelledRecordDetails.resourceIdByAvailId.put(newRecord.Id, newRecord.sked__Resource__c);
                    cancelledRecordDetails.employeeIdByResourceId.put(newRecord.sked__Resource__c, newRecord.sked_Employee_Id__c);
                }
            }
        }
        return cancelledRecordDetails;
    }
    
    public static Set<string> getUnavailabilityTypesToSync() {
        Map<string, skedModels.eventTypeSetting> eventTypeSettings = skedSetting.instance.RAC.mapShiftTypeSetting;
        Set<string> unavailabilityTypesToSync = new Set<String>();
        for (String key : eventTypeSettings.keySet()) {
            skedmodels.eventTypeSetting setting = eventTypeSettings.get(key);
            if (setting.integratedWithWorkday) {
                unavailabilityTypesToSync.add(setting.eventType);
            }
        }

        return unavailabilityTypesToSync;
    }

    @future(Callout=true)
    public static void handleWorkdayApprovals(Set<Id> recordIds) {
        if (skedSetting.instance.admin.workdayIntegration && !recordIds.isEmpty()) {
            List<sked__Availability__c> timeOffRequests = [
                SELECT Id, sked_Start_Date__c, sked_Finish_Date__c, sked__Notes__c,
                    sked__Resource__c, sked__Is_Available__c, sked_Is_All_Day__c, sked_Duration__c,
                    sked__Type__c, sked__Resource__r.sked_Employee_Id__c, sked__Resource__r.Name,
                    sked__Resource__r.sked_Daily_Time_Off_Hours__c, sked__Finish__c, sked__Start__c,
                    sked_Time_Off_Reason_Code__c, sked_Time_Off_Plan__c
                FROM sked__Availability__c
                WHERE Id IN :recordIds
                AND sked_Workday_Sync_Status__c NOT IN :NON_SYNC_WORKDAY_STATUSES
            ];

            Map<Id, skedWorkdayEnterTimeOffResponse> resultById = new Map<Id, skedWorkdayEnterTimeOffResponse>();
            for (sked__Availability__c timeOffRequest : timeOffRequests) {
                skedWorkdayEnterTimeOffRequest enterTimeOffRequest = new skedWorkdayEnterTimeOffRequest();
                enterTimeOffRequest.employeeId = timeOffRequest.sked__Resource__r.sked_Employee_Id__c;
                enterTimeOffRequest.resourceId = timeOffRequest.sked__Resource__c;
                skedWorkdayEnterTimeOffRequest.skedWorkdayTimeOffEntry timeOffEntry = new skedWorkdayEnterTimeOffRequest.skedWorkdayTimeOffEntry();
                timeOffEntry.comment = timeOffRequest.sked__Notes__c;
                timeOffEntry.ptoDate = timeOffRequest.sked_Start_Date__c;
                timeOffEntry.hoursRequested = getWorkdayPtoHours(timeOffRequest, timeOffRequest.sked__Resource__r); 
                timeOffEntry.ptoEntryId = timeOffRequest.Id;
                timeOffEntry.timeOffType = getWorkdayTimeOffType(timeOffRequest);
                timeOffEntry.ptoReason = timeOffRequest.sked_Time_Off_Reason_Code__c;
                enterTimeOffRequest.timeOffEntries.add(timeOffEntry);
                
                resultById.put(timeOffRequest.Id, skedWorkdayApiManager.EnterTimeOff(enterTimeOffRequest));
            }

            List<sked__Availability__c> failedApprovals = new List<sked__Availability__c>();

            List<SObject> recordsToUpsert = new List<SObject>();
            for (sked__Availability__c timeOffRequest : timeOffRequests) {
                skedWorkdayEnterTimeOffResponse result = resultById.get(timeOffRequest.Id);
                
                if (!result.isSuccess) {
                    timeOffRequest.sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WD_SYNC_STATUS_FAILED;
                    timeOffRequest.sked_Workday_Sync_Message__c = result.message;
                    timeOffRequest.sked_Approval_Reason__c = skedConstants.AVAILABILITY_APPROVAL_REASON_WORKDAY_SYNC_FAILURE;
                    timeOffRequest.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PENDING;
                    failedApprovals.add(timeOffRequest);
                } else {
                    timeOffRequest.sked_Approved_Via_Automation__c = true;
                    timeOffRequest.sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WD_SYNC_STATUS_SUCCESS;
                    timeOffRequest.sked_Workday_Sync_Message__c = null;
                    timeOffRequest.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                }

                recordsToUpsert.add(timeOffRequest);

                if (skedSetting.instance.admin.enableWorkdayLogging) {
                    sked__Debug_Log__c debugLog = getDebugLogFromResponse('Enter Time Off', timeOffRequest, result);
                    recordsToUpsert.add(debugLog);
                }
            }

            upsert recordsToUpsert;
            
            if (!failedApprovals.isEmpty()) {
                new skedCustomNotificationService(new List<String>{
                    'sked_Workday_Approval_Failed_Resource'
                }).generateNotifications(failedApprovals);
            }
        }
    }

    @future(Callout=true)
    public static void handleWorkdayAdjustments(List<Id> availabilityIds, Map<Id, Decimal> adjustmentById, Map<Id, Id> resourceIdByAvailId,
            Map<Id, String> employeeIdByResourceId, Boolean isCancellation) {
        if (skedSetting.instance.admin.workdayIntegration && !availabilityIds.isEmpty()) {

            Map<Id, skedWorkdayAdjustTimeOffResponse> resultById = new Map<Id, skedWorkdayAdjustTimeOffResponse>();
            for (Id availabilityId : availabilityIds) {
                Id resourceId = resourceIdByAvailId.get(availabilityId);
                skedWorkdayAdjustTimeOffRequest adjustTimeOffRequest = new skedWorkdayAdjustTimeOffRequest();
                adjustTimeOffRequest.employeeId = employeeIdByResourceId.get(resourceId);
                adjustTimeOffRequest.resourceId = resourceId;
                
                skedWorkdayAdjustTimeOffRequest.skedWorkdayAdjustTimeOffEntry adjustTimeOffEntry = new skedWorkdayAdjustTimeOffRequest.skedWorkdayAdjustTimeOffEntry();
                adjustTimeOffEntry.ptoEntryId = availabilityId;
                adjustTimeOffEntry.adjustment = adjustmentById.get(availabilityId);
                adjustTimeOffRequest.adjustTimeOffEntries.add(adjustTimeOffEntry);
                resultById.put(availabilityId, skedWorkdayApiManager.AdjustTimeOff(adjustTimeOffRequest));
            }

            Map<Id, sked__Availability__c> availabilityById = new Map<Id, sked__Availability__c>([
                SELECT Id, sked__Resource__c FROM sked__Availability__c WHERE Id IN :availabilityIds
            ]);

            List<sked__Availability__c> failedAdjustments = new List<sked__Availability__c>();

            List<SObject> recordsToUpsert = new List<SObject>();
            for (Id availabilityId : resultById.keySet()) {
                if (!availabilityById.containsKey(availabilityId)) continue;
                skedWorkdayAdjustTimeOffResponse result = resultById.get(availabilityId);
                sked__Availability__c availabilityRecord = availabilityById.get(availabilityId);
                if (!result.isSuccess) {
                    availabilityRecord.sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WD_SYNC_STATUS_FAILED;
                    availabilityRecord.sked_Workday_Sync_Message__c = result.message;
                    availabilityRecord.sked_Approval_Reason__c = skedConstants.AVAILABILITY_APPROVAL_REASON_WORKDAY_SYNC_FAILURE;
                    availabilityRecord.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                    failedAdjustments.add(availabilityRecord);
                } else {
                    availabilityRecord.sked_Approved_Via_Automation__c = true;
                    availabilityRecord.sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WD_SYNC_STATUS_SUCCESS;
                    availabilityRecord.sked_Workday_Sync_Message__c = null;
                    availabilityRecord.sked_Custom_Status__c = isCancellation ? 
                        skedConstants.AVAILABILITY_STATUS_CANCELLED : skedConstants.AVAILABILITY_STATUS_APPROVED;
                }

                recordsToUpsert.add(availabilityRecord);
                
                if (skedSetting.instance.admin.enableWorkdayLogging) {
                    sked__Debug_Log__c debugLog = getDebugLogFromResponse('Adjust Time Off', availabilityRecord, result);
                    recordsToUpsert.add(debugLog);
                }
            }

            upsert recordsToUpsert;

            if (!failedAdjustments.isEmpty()) {
                String failedTemplateResource = isCancellation ? 'sked_Workday_Cancel_Failed_Resource' : 'sked_Workday_Adjustment_Failed_Resource';
                new skedCustomNotificationService(new List<String>{
                    failedTemplateResource
                }).generateNotifications(failedAdjustments);
            }
        }
    }

    public static Decimal getWorkdayPtoHours(sked__Availability__c record, sked__Resource__c availabilityResource) {
        Decimal availDurationHours = skedDateTimeUtils.getDifferenceInHoursAndMinutes(record.sked__Start__c, record.sked__Finish__c);
        // This rounds our result up to the next .25 hours, 6.3 => 6.5, 7.05 => 7.25, 8.95 => 9
        availDurationHours = availDurationHours.divide(25, 2, System.RoundingMode.UP) * 25;
        Decimal ptoDurationHours = availabilityResource.sked_Daily_Time_Off_Hours__c;
        if (!record.sked_Is_All_Day__c && availDurationHours < ptoDurationHours) {
            ptoDurationHours = availDurationHours;
        }
        return ptoDurationHours;
    }

    private static Decimal getAdjustmentValue(sked__Availability__c newRecord, sked__Availability__c oldRecord, sked__Resource__c availabilityResource) {
        Decimal oldDuration = getWorkdayPtoHours(oldRecord, availabilityResource);
        Decimal newDuration = getWorkdayPtoHours(newRecord, availabilityResource);
        return newDuration-oldDuration;
    }

    public static String getWorkdayTimeOffType(sked__Availability__c record) {
        return record.sked__Type__c == skedConstants.AVAILABILITY_TYPE_CALL_OUT ?
            record.sked_Time_Off_Plan__c : record.sked__Type__c;
    }

    public static Decimal getApprovedTimeOffHours(sked__Resource__c resource, Date availDate, String timeOffType) {
        Decimal approvedTimeOff = 0;
        sked__Availability__c[] approvedAvailability = [SELECT Id, sked__Start__c, sked__Finish__c, sked_Is_All_Day__c 
                                                      FROM sked__Availability__c
                                                      WHERE sked__Resource__c = :resource.Id
                                                      AND sked_Start_Date__c = :availDate
                                                      AND sked__Type__c = :timeOffType
                                                      AND sked_Custom_Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
                                                      LIMIT 1];
        if (approvedAvailability.size() > 0) {
            approvedTimeOff = getWorkdayPtoHours(approvedAvailability[0], resource);
        }
        return approvedTimeOff;
    }

    public static sked__Debug_Log__c getDebugLogFromResponse(String operation, sked__Availability__c availabilityRecord, skedWorkdayApiResponse result) {
        sked__Debug_Log__c debugLog = new sked__Debug_Log__c();
        debugLog.sked__Type__c = skedConstants.DEBUG_LOG_TYPE_WORKDAY_API;
        debugLog.sked__Summary__c = operation;
        debugLog.sked_Request__c = result.request;
        debugLog.sked_Response__c = result.response;
        debugLog.sked__Message__c = result.message;
        debugLog.sked_Resource__c = availabilityRecord.sked__Resource__c;

        if (!result.isSuccess) {
            debugLog.sked_Category__c = result.statusCode == 500 ? skedConstants.DEBUG_LOG_CATEGORY_VALIDATION_ERROR : skedConstants.DEBUG_LOG_CATEGORY_SYSTEM_ERROR;
        }
        
        return debugLog;
    }

    public class workdayAdjustmentsContainer {
        public List<Id> recordIds;
        public Map<Id, String> employeeIdByResourceId;
        public Map<Id, Decimal> adjustmentValById;
        public Map<Id, Id> resourceIdByAvailId;

        public workdayAdjustmentsContainer() {
            this.recordIds = new List<Id>();
            this.employeeIdByResourceId = new Map<Id, String>();
            this.adjustmentValById = new Map<Id, Decimal>();
            this.resourceIdByAvailId = new Map<Id, Id>();
        }
    }
}