public class skedOperationRecordHandler extends skedTriggerHub implements Callable {
    
    public override void onBeforeInsert() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
        populateLastModifiedUser(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked_Operation_Record__c>)this.context.oldMap);
        }
        populateLastModifiedUser(this.context.newRecords);
        lockSubmittedRecord(this.context.newRecords, (Map<Id, sked_Operation_Record__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        onSubmitted((Map<Id, sked_Operation_Record__c>)this.context.newMap, (Map<Id, sked_Operation_Record__c>)this.context.oldMap);
    }

    public override void onBeforeDelete() {
        validateCanDelete(this.context.oldMap.values());
    }

    /**************************************** CALLABLE INTERFACE  ***************************************/
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'createBreaksNotTakenAPIData' {
                    createBreaksNotTakenAPIData((Map<Id, Id>) JSON.deserialize((String) params.get('param1'), Map<Id, Id>.class));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedOperationRecordHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void onSubmitted(Map<Id, sked_Operation_Record__c> newMap, Map<Id, sked_Operation_Record__c> oldMap) {
        Set<Id> driveIdsToComplete = new Set<Id>();
        Set<Id> operationRecordIds = new Set<Id>();
        Map<Id, Id> map_opRecordId_submittedById = new Map<Id, Id>();
        for (sked_Operation_Record__c newRecord : newMap.values()) {
            sked_Operation_Record__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.OPERATION_STATUS_SUBMITTED) {
                    driveIdsToComplete.add(newRecord.sked_Drive__c);
                    operationRecordIds.add(newRecord.Id);
                    map_opRecordId_submittedById.put(newRecord.Id, newRecord.sked_Submitted_By__c);
                }
            }
        }

        captureCallOuts(operationRecordIds);
        if(map_opRecordId_submittedById != NULL && !map_opRecordId_submittedById.isEmpty()) {
            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    skedOperationRecordHandler.class.getName(),
                    'createBreaksNotTakenAPIData',
                    map_opRecordId_submittedById
                );
            } else {
                createBreaksNotTakenAPIData(map_opRecordId_submittedById);
            }
        }
    }

    private void completeDrives(Set<Id> driveIdsToComplete) {
        if (!driveIdsToComplete.isEmpty()) {
            List<sked_Drive__c> drivesWithOpRecords = [SELECT Id, sked_Status__c,
                                                       (SELECT Id, sked_Status__c
                                                        FROM sked_Operations__r)
                                                       FROM sked_Drive__c
                                                       WHERE Id IN :driveIdsToComplete];
            List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
            for (sked_Drive__c drive : drivesWithOpRecords) {
                boolean isAllOpRecordsSubmitted = TRUE;
                for (sked_Operation_Record__c opRecord : drive.sked_Operations__r) {
                    if (opRecord.sked_Status__c != skedConstants.OPERATION_STATUS_SUBMITTED) {
                        isAllOpRecordsSubmitted = FALSE;
                        break;
                    }
                }
                if (isAllOpRecordsSubmitted && drive.sked_Status__c != skedConstants.DRIVE_STATUS_COMPLETE) {
                    drive.sked_Status__c = skedConstants.DRIVE_STATUS_COMPLETE;
                    drivesToUpdate.add(drive);
                }
            }
            if (!drivesToUpdate.isEmpty()) {
                update drivesToUpdate;
            }
        }
    }

    private void captureCallOuts(Set<Id> operationRecordIds) {
        if (operationRecordIds != NULL && !operationRecordIds.isEmpty()) {
            List<sked_Operation_Record_Staff__c> opRecordStaffs = [
                SELECT Id, sked_Resource__c, sked_Timezone__c, 
                sked_Actual_Shift_Start__c, sked_Actual_Shift_End__c,
                Scheduled_Shift_Start__c, Scheduled_Shift_End__c, sked_Job_Allocation__c,
                sked_Early_Departure_Reasons__c, sked_Early_Departure_DateTime_Received__c,
                sked_Late_Arrival_Reasons__c, sked_Late_Arrival_DateTime_Received__c,
                sked_Notes_Comments__c
                FROM sked_Operation_Record_Staff__c
                WHERE sked_Operation_Record__c IN :operationRecordIds
            ];

            List<sked__Availability__c> callOutAvailabilitiesToUpsert = new List<sked__Availability__c>();
            List<sked__Availability__c> existingCallOutAvailabilities = new List<sked__Availability__c>();
            Map<String, sked__Availability__c> mapJobAllocationId_callOut = new Map<String, sked__Availability__c>();
            Map<Id,List<String>> mapOpRecordStaffId_callOutTypes = new Map<Id,List<String>>();
            Set<Id> jobAllocationIds = new Set<Id>();
            
            List<String> existingCallOutTypesToCheck = new List<String>{skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL, skedConstants.AVAILABILITY_CALLOUT_TYPE_EARLY_DEPARTURE};           
            List<String> excludedCallOutReasonCodes = new List<String>{skedConstants.LATE_ARRIVAL_REASON_NOT_LATE, skedConstants.EARLY_DEPARTURE_REASON_NOT_EARLY};
            List<String> includedCallOutStatuses = new List<String>{skedConstants.AVAILABILITY_STATUS_APPROVED};
            
            for (sked_Operation_Record_Staff__c opRecordStaff : opRecordStaffs) {
                Boolean isLateArrival = opRecordStaff.Scheduled_Shift_Start__c < opRecordStaff.sked_Actual_Shift_Start__c && opRecordStaff.sked_Actual_Shift_Start__c!= NULL && !excludedCallOutReasonCodes.contains(opRecordStaff.sked_Late_Arrival_Reasons__c);
                Boolean isEarlyDeparture = opRecordStaff.Scheduled_Shift_End__c > opRecordStaff.sked_Actual_Shift_End__c && opRecordStaff.sked_Actual_Shift_End__c != NULL && !excludedCallOutReasonCodes.contains(opRecordStaff.sked_Early_Departure_Reasons__c);
                Boolean isCallOutNeeded =  isEarlyDeparture || isLateArrival;
                if (isCallOutNeeded) {
                    List<string> callOutTypes = mapOpRecordStaffId_callOutTypes.get(opRecordStaff.Id);
                    if (callOutTypes == NULL) {
                        callOutTypes = new List<string>();
                        mapOpRecordStaffId_callOutTypes.put(opRecordStaff.Id, callOutTypes);
                    }
                    if (isLateArrival){
                        callOutTypes.add(skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL);
                    }
                    if (isEarlyDeparture){
                        callOutTypes.add(skedConstants.AVAILABILITY_CALLOUT_TYPE_EARLY_DEPARTURE);
                    }
                    if(opRecordStaff.sked_Job_Allocation__c!=null){
                    jobAllocationIds.add(opRecordStaff.sked_Job_Allocation__c);
                    }
                }
            }

            if (!jobAllocationIds.isEmpty()) {
                existingCallOutAvailabilities = [SELECT Id, sked_Call_Out_Type__c, sked_Call_Out_for_Job_Allocation__c,
                                                sked_Custom_Status__c, sked__Status__c
                                                FROM sked__Availability__c
                                                WHERE sked_Call_Out_for_Job_Allocation__c IN :jobAllocationIds
                                                AND sked_Call_Out_Type__c IN :existingCallOutTypesToCheck
                                                AND sked_Custom_Status__c IN :includedCallOutStatuses];
                for (sked__Availability__c callOut : existingCallOutAvailabilities) {
                    mapJobAllocationId_callOut.put(callOut.sked_Call_Out_for_Job_Allocation__c + ':' + callOut.sked_Call_Out_Type__c, callOut);
                }
            }

            for (sked_Operation_Record_Staff__c opRecordStaff : opRecordStaffs) {      
                List<string>  callOutTypes = mapOpRecordStaffId_callOutTypes.get(opRecordStaff.Id);
                if (callOutTypes != NULL) {
                    for (String callOutType : callOutTypes) {                   
                        sked__Availability__c  callOutAvailability = new sked__Availability__c();
                        sked__Availability__c  existingCallOutAvailability = mapJobAllocationId_callOut.get(opRecordStaff.sked_Job_Allocation__c + ':' + callOutType);

                        if (existingCallOutAvailability != NULL) {
                            callOutAvailability.Id = existingCallOutAvailability.Id;
                        }
                        else {
                            callOutAvailability.sked__Resource__c = opRecordStaff.sked_Resource__c;
                        }
                        callOutAvailability.sked__Type__c = skedConstants.AVAILABILITY_TYPE_CALL_OUT;
                        callOutAvailability.sked__Is_Available__c = FALSE;
                        callOutAvailability.sked_Call_Out_Type__c = callOutType;                       
                        callOutAvailability.sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                        callOutAvailability.sked__Timezone__c = opRecordStaff.sked_Timezone__c;
                        callOutAvailability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                        callOutAvailability.sked_Call_Out_for_Job_Allocation__c = opRecordStaff.sked_Job_Allocation__c;
                        callOutAvailability.sked_Call_Out_Notes__c = opRecordStaff.sked_Notes_Comments__c != '' ? opRecordStaff.sked_Notes_Comments__c : '';                   
                        callOutAvailability.sked_Call_Out_Reported__c = TRUE;                                                                     
                        
                        if (callOutType == skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL) {
                            callOutAvailability.sked__Start__c = opRecordStaff.Scheduled_Shift_Start__c;
                            callOutAvailability.sked__Finish__c = opRecordStaff.sked_Actual_Shift_Start__c ;
                            callOutAvailability.sked_Call_Out_Reason_Code__c = opRecordStaff.sked_Late_Arrival_Reasons__c;
                            callOutAvailability.sked_DateTime_Call_Out_Received__c = opRecordStaff.sked_Late_Arrival_DateTime_Received__c;
                        }
                        else {
                            callOutAvailability.sked__Start__c =  opRecordStaff.sked_Actual_Shift_End__c;
                            callOutAvailability.sked__Finish__c = opRecordStaff.Scheduled_Shift_End__c;
                            callOutAvailability.sked_Call_Out_Reason_Code__c = opRecordStaff.sked_Early_Departure_Reasons__c;
                            callOutAvailability.sked_DateTime_Call_Out_Received__c = opRecordStaff.sked_Early_Departure_DateTime_Received__c;
                        }    

                        callOutAvailabilitiesToUpsert.add(callOutAvailability);
                    }
                }
            }

            if (!callOutAvailabilitiesToUpsert.isEmpty()) {
                upsert callOutAvailabilitiesToUpsert;
            }
        }
    }

    private void lockSubmittedRecord(List<sked_Operation_Record__c> newRecords, Map<Id, sked_Operation_Record__c> oldMap) {
        List<sked__Resource__c> resourceUsers = [SELECT Id 
                                                FROM sked__Resource__c 
                                                WHERE sked__User__c = :UserInfo.getUserId()
                                                    AND sked__Is_Active__c = TRUE];
        if (resourceUsers != NULL && !resourceUsers.isEmpty()) {
            sked__Resource__c resourceUser = resourceUsers.get(0);
            for (sked_Operation_Record__c newRecord : newRecords) {
                sked_Operation_Record__c oldData = oldMap.get(newRecord.Id);
                if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                    if (newRecord.sked_Status__c == skedConstants.OPERATION_STATUS_SUBMITTED) {
                        newRecord.sked_Submitted_By__c = resourceUser.Id;
                        newRecord.sked_Locked__c = TRUE;
                    }
                }
            }
        }
    }

    private static void createBreaksNotTakenAPIData(Map<Id, Id> map_opRecordId_submittedById) {
        List<sked_Trade_API_Data__c> workdayApiData = new List<sked_Trade_API_Data__c>();
        List<Id> submittedByIds = new List<Id>(map_opRecordId_submittedById.values());
        Map<Id, sked__Resource__c> map_ResourceId_resourceInfo = new Map<Id, sked__Resource__c>([SELECT Id, sked__Email__c 
                                                                                                 FROM sked__Resource__c 
                                                                                                 WHERE Id IN :submittedByIds]);
        
        List<sked_Operation_Record_Staff__c> opRecordStaffs = [SELECT Id, sked_Resource__c, sked_Resource__r.sked_Employee_ID__c,
                                                               sked_Resource__r.sked_Work_State__c, sked_Resource__r.sked_Satellite_State__c,
                                                               sked_Resource__r.sked_Home_State__c, sked_Rest_Breaks_Not_Taken__c, sked_Actual_Roles__c,
                                                               sked_Resource__r.sked__Email__c, sked_Operation_Record__c,
                                                               sked_Operation_Record__r.sked_Drive_Date__c, sked_Operation_Record__r.sked_Drive__c
                                                               FROM sked_Operation_Record_Staff__c
                                                               WHERE sked_Operation_Record__c IN :map_opRecordId_submittedById.keySet()
                                                               AND sked_Absent__c = FALSE
                                                               AND sked_Rest_Breaks_Not_Taken__c != NULL];
 
        for (sked_Operation_Record_Staff__c record : opRecordStaffs) {
            if(isResourceCaliforniaBased(record)) {
                sked_Trade_API_Data__c requestingStaffData = new sked_Trade_API_Data__c();
                requestingStaffData.sked_Event_Id__c = record.Id;
                requestingStaffData.sked_Employee_Id__c = record.sked_Resource__r.sked_Employee_ID__c;
                requestingStaffData.sked_Event_Date__c = record.sked_Operation_Record__r.sked_Drive_Date__c;
                requestingStaffData.sked_Resource__c = record.sked_Resource__c;
                requestingStaffData.sked_Time_Entry_Code__c = skedConstants.WD_REST_BREAKS_NOT_TAKEN_CODE;
                requestingStaffData.sked_Quantity__c = record.sked_Rest_Breaks_Not_Taken__c;
                requestingStaffData.sked_Approver_Email__c = map_ResourceId_resourceInfo.get(map_opRecordId_submittedById.get(record.sked_Operation_Record__c)).sked__Email__c;
                workdayApiData.add(requestingStaffData);
            }
        }

        insert workdayApiData;
    }

    private static Boolean isResourceCaliforniaBased(sked_Operation_Record_Staff__c opRecordStaff) {
        Boolean isCaliforniaBased = FALSE;
        List<String> allowedStateStrings = new List<String>{'CA', 'California'};
        if(opRecordStaff != NULL) {
            String stateField = !String.isEmpty(opRecordStaff.sked_Resource__r.sked_Work_State__c) 
                                ? 'sked_Work_State__c' 
                                : (!String.isEmpty(opRecordStaff.sked_Resource__r.sked_Satellite_State__c) ? 'sked_Satellite_State__c' : 'sked_Home_State__c');
            if(allowedStateStrings.contains(String.valueOf(opRecordStaff.sked_Resource__r.get(stateField)))) {
                isCaliforniaBased = TRUE;
            }
        }
        return isCaliforniaBased;
    }
    
    private void doDateTimeConversion(List<sked_Operation_Record__c> newRecords) {
        for (sked_Operation_Record__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Actual_Drive_Start__c', 'sked_Actual_Drive_Start_Date__c', 'sked_Actual_Drive_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Actual_Drive_End__c', 'sked_Actual_Drive_End_Date__c', 'sked_Actual_Drive_End_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked_Operation_Record__c> newRecords, Map<Id, sked_Operation_Record__c> oldMap) {
        for (sked_Operation_Record__c newRecord : newRecords) {
            sked_Operation_Record__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Actual_Drive_Start__c', 'sked_Actual_Drive_Start_Date__c', 'sked_Actual_Drive_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Actual_Drive_End__c', 'sked_Actual_Drive_End_Date__c', 'sked_Actual_Drive_End_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void populateLastModifiedUser(List<sked_Operation_Record__c> newRecords) {
        for (sked_Operation_Record__c newRecord : newRecords) {
            newRecord.sked_Last_Modified_User__c = UserInfo.getName();
        }
    }

    private void validateCanDelete(List<sked_Operation_Record__c> deletedRecords) {
        for (sked_Operation_Record__c opRecord : deletedRecords) {
            if (skedTriggerUtils.hasPermissionSetAssignment('sked_ARC_Lead_Resource')) {
                opRecord.addError(skedConstants.OP_RECORD_DELETE_INVALID_PERMISSION);
            }
        }
    }
}