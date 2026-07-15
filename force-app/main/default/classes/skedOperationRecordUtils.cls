public class skedOperationRecordUtils {
    public static final string DATE_TIME_FORMAT = 'yyyy-MM-dd HH:mm:ss';
    public static final integer THRESHOLD_MINUTES_TO_REDUCE_LUNCH_BREAK = 360;
    
    public static List<sked_Operation_Record__c> getOpsRecords(Set<Id> recordIds) {
        List<sked_Operation_Record__c> result = [
            SELECT Id, Name, sked_Drive__c, sked_Drive__r.sked_UFID__c, sked_Drive__r.sked_Drive_Date__c,
                sked_Drive__r.sked_Type_of_Drive__c, sked_Donor_Ambassadors_Actual__c, sked_Actual_Drive_Start__c, sked_Actual_Drive_End__c,
                sked_Power_Red_Machines_Sent__c, sked_Power_Red_Machines_Used__c, 
                sked_Drive__r.sked_Projected_Registered_Donors__c, sked_Drive_Issues__c,
                sked_Late_End_Reason__c, sked_Late_End_Drive_Approved_By__c,
                sked_Submitted_By__r.sked_Employee_ID__c, sked_Submitted_By__r.sked__Email__c,
                sked_Locked__c, sked_ShiftID_Integer__c, sked_Status__c, sked_Drive__r.sked_Status__c,
                sked_Workday_Submission_Status__c, sked_Workday_Submission_Attempt__c, sked_WD_Last_Submission_Date__c,
                (SELECT Id, sked_Job__r.sked__Actual_Start__c, 
                 sked_Job__r.sked__Actual_End__c,
                 sked_Job__r.sked__Location__r.sked_Room_Size__c,
                 sked_Job__r.sked__Location__r.sked_Room_Name__c,
                 sked_Job__r.sked__Location__r.sked_Maximum_Beds__c,
                 sked_Job__r.sked__Timezone__c,
                 sked_Job__r.sked_Drive_Shift__r.sked_UFID_AN__c,
                 sked_Job__r.sked_Drive_Shift__r.sked_UFID__c,
                 sked_Job__r.sked_Drive_Shift__r.sked_Donors_Scheduled__c,
                 sked_Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Duration__c,
                 sked_Notes_Comments__c, sked_Resource__c, sked_Resource__r.sked__Email__c,
                 sked_Resource__r.sked_Employee_ID__c, sked_Resource__r.sked_Last_Name__c,
                 sked_Resource__r.sked_First_Name__c, sked_Resource__r.sked_eBDR_ID__c,
                 sked_Resource__r.sked__Category__c,
                 sked_Added_Staff__c, sked_Role__c, sked_Actual_Shift_Start__c,
                 sked_Actual_Shift_End__c, sked_No_Meal__c, sked_Premiums_Op_Pay__c, sked_Actual_Roles__c,
                 sked_Rest_Breaks_Not_Taken__c,
                 sked_Absent__c, sked_Timezone__c, sked_Workday_Submission_Status__c,
                 sked_Time_Already_Existed_In_Workday__c
                 FROM sked_Operation_Record_Staff__r)
            FROM sked_Operation_Record__c
            WHERE Id IN :recordIds
        ];
        return result;
    }

    public static List<skedOpsRecordApiData.opsRecordRequest> getOpsRecordRequests(List<sked_Operation_Record__c> opRecords) {
        List<skedOpsRecordApiData.opsRecordRequest> requests = new List<skedOpsRecordApiData.opsRecordRequest>();
        
        Set<Id> driveIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        for (sked_Operation_Record__c opRecord : opRecords) {
            driveIds.add(opRecord.sked_Drive__c);
            if (opRecord.sked_Operation_Record_Staff__r != NULL && !opRecord.sked_Operation_Record_Staff__r.isEmpty()) {
                for (sked_Operation_Record_Staff__c recordStaff : opRecord.sked_Operation_Record_Staff__r) {
                    resourceIds.add(recordStaff.sked_Resource__c);
                }
            }
        }
        
        Map<Id, DriveBridgeAPI__x> mapExternalDrive = new Map<Id, DriveBridgeAPI__x>();
        try {
            //Need to handle external data source before DML as this is considered as callout
            List<DriveBridgeAPI__x> externalDrives = [SELECT guid__c, external_id__c, internal_id__c
                                                      FROM DriveBridgeAPI__x
                                                      WHERE guid__c IN :driveIds];
            for (DriveBridgeAPI__x externalDrive : externalDrives) {
                mapExternalDrive.put(externalDrive.guid__c, externalDrive);
            }
        }
        catch (Exception ex) {
            system.debug('#ex#' + ex.getMessage());
        }

        Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>([
            SELECT Id, Name,
                (SELECT Id, Name, sked_Premium_Pay__c, sked__Tag__r.Name, sked_Start_Date__c FROM sked__ResourceTags__r)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
        
        Map<String, List<String>> premiumPayTagsByRole = skedUtils.getMapPremiumOpPayToRole();
        for (sked_Operation_Record__c opRecord : opRecords) {
            if (opRecord.sked_Operation_Record_Staff__r != NULL && !opRecord.sked_Operation_Record_Staff__r.isEmpty()) {
                skedOpsRecordApiData.opsRecordRequest request = new skedOpsRecordApiData.opsRecordRequest(); 
                
                sked_Operation_Record_Staff__c opRecordStaff = opRecord.sked_Operation_Record_Staff__r.get(0);
                Integer shiftId = 1;
                if (opRecord.sked_ShiftID_Integer__c != null) {
                    shiftId = integer.valueOf(opRecord.sked_ShiftID_Integer__c);
                }
                
                if (mapExternalDrive.containsKey(opRecord.sked_Drive__c)) {
                    DriveBridgeAPI__x externalDrive = mapExternalDrive.get(opRecord.sked_Drive__c);
                    request.internalDriveId = externalDrive.internal_id__c;
                    request.externalDriveId = externalDrive.external_id__c;
                }
                
                request.shiftId = shiftId;
                request.scheduled =  opRecordStaff.sked_Job__r.sked_Drive_Shift__r.sked_Donors_Scheduled__c != null ? Integer.valueOf(opRecordStaff.sked_Job__r.sked_Drive_Shift__r.sked_Donors_Scheduled__c) : 0;
                request.roomUsed = !string.isBlank(opRecordStaff.sked_Job__r.sked__Location__r.sked_Room_Name__c) ? opRecordStaff.sked_Job__r.sked__Location__r.sked_Room_Name__c : ''; 
                request.powerRedMachinesUsed = Integer.valueOf(opRecord.sked_Power_Red_Machines_Used__c);
                request.powerRedMachinesUsed = request.powerRedMachinesUsed != NULL ? request.powerRedMachinesUsed : 1;
                request.powerRedMachinesSent = Integer.valueOf(opRecord.sked_Power_Red_Machines_Sent__c);
                request.powerRedMachinesSent = request.powerRedMachinesSent != NULL ? request.powerRedMachinesSent : 1;
                request.numberWhiteNoiseMachineUsed = 1;
                request.numberTables = 1;
                request.numberRadiosUsed = 1;
                request.numberChairs = 1;
                request.numberBedsSetupWB = 1;
                request.numberBedsSetupHH = 1;
                request.numberBedsSetup2RBC = 1;
                request.notes = !string.isBlank(opRecordStaff.sked_Notes_Comments__c) ? opRecordStaff.sked_Notes_Comments__c : ''; 
                request.maximumPossibleHH = 1;
                request.maximumPossibleBeds = opRecordStaff.sked_Job__r.sked__Location__r.sked_Maximum_Beds__c != NULL ? Integer.valueOf(opRecordStaff.sked_Job__r.sked__Location__r.sked_Maximum_Beds__c) : 1;
                request.lockRecord = true;
                // Use the original submitter's employee id/email when available (as we are doing submission later by system),
                // otherwise fall back to the current user's linked resource.
                if (opRecord.sked_Submitted_By__r != null) {
                    request.lockedByEmployeeId = opRecord.sked_Submitted_By__r.sked_Employee_ID__c;
                    request.lockedByEmployeeEmail = opRecord.sked_Submitted_By__r.sked__Email__c;
                } else {
                    sked__Resource__c currentRes = null;
                    try {
                        currentRes = skedTriggerHub_Cache.getCurrentUserResource();
                    } catch (Exception e) {
                        // If there's no current user resource, leave lockedBy* blank
                    }
                    if (currentRes != null) {
                        request.lockedByEmployeeId = currentRes.sked_Employee_ID__c;
                        request.lockedByEmployeeEmail = currentRes.sked__Email__c;
                    }
                }
                request.lateEndDriveReason = !string.isBlank(opRecord.sked_Late_End_Reason__c) ? opRecord.sked_Late_End_Reason__c : ''; 
                request.lateEndDriveApprovedBy = !string.isBlank(opRecord.sked_Late_End_Drive_Approved_By__c) ? opRecord.sked_Late_End_Drive_Approved_By__c : '';  
                request.goal = 0;
                request.estimatedRoomDimensions = !string.isBlank(opRecordStaff.sked_Job__r.sked__Location__r.sked_Room_Size__c) ? opRecordStaff.sked_Job__r.sked__Location__r.sked_Room_Size__c : ''; 
                request.driveIssue = 0;
                request.driveIssuesOpenedLate = opRecord.sked_Drive_Issues__c == 'Opened Late'; 
                request.driveIssuesClosedEarly = opRecord.sked_Drive_Issues__c == 'Closed Early'; 
                request.driveIssuesCancelled = opRecord.sked_Drive_Issues__c == 'Cancelled'; 
                request.driveIssueReason = string.isBlank(opRecord.sked_Drive_Issues__c) ? '' : opRecord.sked_Drive_Issues__c;
                request.driveIssueHandheld = 0;
                request.driveIssueClient = 0;
                request.driveDate = opRecord.sked_Drive__r.sked_Drive_Date__c;
                request.donorFlowSignInTotal = 0;
                request.donorFlowSignIn8 = 0;
                request.donorFlowSignIn7 = 0;
                request.donorFlowSignIn6 = 0;
                request.donorFlowSignIn5 = 0;
                request.donorFlowSignIn4 = 0;
                request.donorFlowSignIn3 = 0;
                request.donorFlowSignIn2 = 0;
                request.donorFlowSignIn1 = 0;
                request.donorAmbassadorActual = opRecord.sked_Donor_Ambassadors_Actual__c == NULL ? 0 : opRecord.sked_Donor_Ambassadors_Actual__c;
                request.checkedInNotRegistered = 0;
                request.actualLunchStart = opRecordStaff.sked_Job__r.sked__Actual_Start__c;
                request.actualLunchEnd = opRecordStaff.sked_Job__r.sked__Actual_End__c;
                request.actualDriveStart = opRecord.sked_Actual_Drive_Start__c;
                request.actualDriveEnd = opRecord.sked_Actual_Drive_End__c;
                
                request.StaffDetails  = new List<skedOpsRecordApiData.OpsRecordStaffDetail>();
                Date driveDate = opRecord.sked_Drive__r.sked_Drive_Date__c;
                if (opRecord.sked_Operation_Record_Staff__r != NULL && !opRecord.sked_Operation_Record_Staff__r.isEmpty()) {
                    for (sked_Operation_Record_Staff__c recordStaff : opRecord.sked_Operation_Record_Staff__r) {
                        sked__Resource__c skedResource = resourceById.get(recordStaff.sked_Resource__c);
                        skedOpsRecordApiData.OpsRecordStaffDetail opDetail = new skedOpsRecordApiData.OpsRecordStaffDetail();
                        opDetail.shiftStart = convertToWorkdayDateTimeFormat(recordStaff.sked_Actual_Shift_Start__c, recordStaff.sked_Timezone__c);
                        opDetail.shiftEnd = convertToWorkdayDateTimeFormat(recordStaff.sked_Actual_Shift_End__c, recordStaff.sked_Timezone__c);
                        
                        opDetail.role = String.isNotBlank(recordStaff.sked_Actual_Roles__c) ? recordStaff.sked_Actual_Roles__c.replace(';', ', ') : '';//HRP-10778 Changes
                        if (recordStaff.sked_Premiums_Op_Pay__c != NULL) {
                            opDetail.premiumTranslator = hasPremiumTagForRole('Translator', premiumPayTagsByRole.get('Translator'), skedResource, recordStaff, driveDate);
                            opDetail.premiumOJI = hasPremiumTagForRole('OJI', premiumPayTagsByRole.get('OJI'), skedResource, recordStaff, driveDate);
                            opDetail.premiumDRC = hasPremiumTagForRole('2RBC', premiumPayTagsByRole.get('2RBC'), skedResource, recordStaff, driveDate);
                            opDetail.premiumCharge = hasPremiumTagForRole('Charge', premiumPayTagsByRole.get('Charge'), skedResource, recordStaff, driveDate);
                            opDetail.premiumDriver = hasPremiumTagForRole('Driver', premiumPayTagsByRole.get('Driver'), skedResource, recordStaff, driveDate);
                            opDetail.premiumPool = recordStaff.sked_Premiums_Op_Pay__c.contains('Pool'); 
                            opDetail.premiumLateEnd = recordStaff.sked_Premiums_Op_Pay__c.contains('Late End'); 
                        }
                        opDetail.restBreaksNotTaken = recordStaff.sked_Rest_Breaks_Not_Taken__c;
                        
                        opDetail.personID = recordStaff.sked_Resource__r.sked_Employee_ID__c != null ? integer.valueOf(recordStaff.sked_Resource__r.sked_Employee_ID__c) : 0; 
                        opDetail.notWorked = recordStaff.sked_Absent__c;
                        opDetail.noMeal = recordStaff.sked_No_Meal__c;
                        opDetail.firstName = recordStaff.sked_Resource__r.sked_First_Name__c;
                        opDetail.lastName = recordStaff.sked_Resource__r.sked_Last_Name__c;
                        opDetail.email = !string.isBlank(recordStaff.sked_Resource__r.sked__Email__c) ? recordStaff.sked_Resource__r.sked__Email__c : ''; 
                        opDetail.ebdrid = !string.isBlank(recordStaff.sked_Resource__r.sked_eBDR_ID__c) ? recordStaff.sked_Resource__r.sked_eBDR_ID__c : ''; 
                        opDetail.shiftID = shiftId;
                        opDetail.addedStaff = recordStaff.sked_Added_Staff__c;
                        
                        request.StaffDetails.add(opDetail);
                    }
                }
                
                requests.add(request);
            }
        }
        
        return requests;
    }

    public static skedOpsRecordApiData.opsRecordRequest getOpsRecordRequest(sked_Operation_Record__c opRecord) {
        List<sked_Operation_Record__c> opRecords = new List<sked_Operation_Record__c>();
        opRecords.add(opRecord);
        List<skedOpsRecordApiData.opsRecordRequest> requests = getOpsRecordRequests(opRecords);
        return !requests.isEmpty() ? requests.get(0) : NULL;
    }

    private static string convertToWorkdayDateTimeFormat(DateTime input, string timezoneSidId) {
        return input != NULL ? input.format(DATE_TIME_FORMAT, timezoneSidId) : '';
    }

    @testVisible
    private static Boolean hasPremiumTagForRole(String role, List<String> applicableTagsForRole, sked__Resource__c skedResource,
        sked_Operation_Record_Staff__c opRecordStaff, Date driveDate)
    {
        Boolean hasPremiumTagForRole = false;
        List<String> premiumOpPayRoles = new List<string>();
        if (opRecordStaff.sked_Premiums_Op_Pay__c != NULL) {
            premiumOpPayRoles = opRecordStaff.sked_Premiums_Op_Pay__c.split(';');
        }
        List<String> actualRoles = new List<string>();
        if (opRecordStaff.sked_Actual_Roles__c != NULL) {
            actualRoles = opRecordStaff.sked_Actual_Roles__c.split(';');
        }
        if (premiumOpPayRoles != null && !premiumOpPayRoles.isEmpty() && premiumOpPayRoles.contains(role)) {
            for (String applicableRole : applicableTagsForRole) {
                if (actualRoles != null && !actualRoles.isEmpty() && actualRoles.contains(applicableRole)) {
                    if (skedResource.sked__ResourceTags__r != null && !skedResource.sked__ResourceTags__r.isEmpty()) {
                        for (sked__Resource_Tag__c resourceTag : skedResource.sked__ResourceTags__r) {
                            String tagName = resourceTag.sked__Tag__r.Name;
                            Boolean isPremiumPay = resourceTag.sked_Premium_Pay__c;
                            Boolean isTagActiveOnDriveDate = resourceTag.sked_Start_Date__c <= driveDate;
    
                            if (applicableRole == tagName && isPremiumPay && isTagActiveOnDriveDate) {
                                hasPremiumTagForRole = true;
                                break;
                            }
                        }
                    }
                }
            }
        }

        return hasPremiumTagForRole;
    }
}