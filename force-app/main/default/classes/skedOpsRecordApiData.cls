global class skedOpsRecordApiData {
    
    public virtual class resultBase extends skedCalloutResultBase {
        public error error;
        public List<error> errors;
    }

    public class error {
        public string errorType;
        public string message;
        public string errorKey;
        public string path;
    }

    /* OP RECORD */
    global class opsRecordRequest {
        public datetime driveDate;
        public string internalDriveId; //sked_Drive__c->UFID
        public integer shiftId; //Drive shift id A drive can have multiple shifts - sked_Drive_Shift__c->sked_UFID_AN__c 
        public string externalDriveId; //sked_Drive__c->UFID
        public decimal donorAmbassadorActual;//sked_Operation_Record__c->sked_Donor_Ambassadors_Actual__c
        public datetime actualDriveStart; //sked_Operation_Record__c->sked_Actual_Drive_Start__c
        public datetime actualDriveEnd;//sked_Operation_Record__c->sked_Actual_Drive_End__c
        public datetime actualLunchStart;//sked__Job__c->sked__Actual_Start__c
        public datetime actualLunchEnd;//sked__Job__c->sked__Actual_End__c
        public integer powerRedMachinesSent; //sked_Operation_Record__c->sked_Power_Red_Machines_Sent__c
        public integer powerRedMachinesUsed; //sked_Operation_Record__c->sked_Power_Red_Machines_Used__c
        public integer scheduled; //sked__Job__c->sked_Donors_Scheduled__c
        public integer donorFlowSignIn1; //
        public integer donorFlowSignIn2; //
        public integer donorFlowSignIn3; //
        public integer donorFlowSignIn4; //
        public integer donorFlowSignIn5; //
        public integer donorFlowSignIn6; //
        public integer donorFlowSignIn7; //
        public integer donorFlowSignIn8; //
        public integer donorFlowSignInTotal; //
        public integer checkedInNotRegistered; //
        public boolean driveIssuesOpenedLate; //sked_Operation_Record__c->sked_Drive_Issues__c
        public boolean driveIssuesCancelled; //sked_Operation_Record__c->sked_Drive_Issues__c
        public boolean driveIssuesClosedEarly; //sked_Operation_Record__c->sked_Drive_Issues__c
        public integer driveIssue; //
        public string driveIssueReason; //
        public integer driveIssueClient; //
        public integer driveIssueHandheld; //
        public string lateEndDriveReason; //sked_Operation_Record__c->sked_Late_End_Reason__c
        public string lateEndDriveApprovedBy; //sked_Operation_Record__c->sked_Late_End_Drive_Approved_By__c
        public string estimatedRoomDimensions; //sked__Location__c->sked_Room_Size__c
        public integer goal; //
        public string roomUsed; //sked__Location__c->sked_Room_Name__c
        public integer numberRadiosUsed; //
        public integer numberWhiteNoiseMachineUsed; //
        public integer numberBedsSetupHH; //
        public integer numberBedsSetupWB; //
        public integer numberBedsSetup2RBC; //
        public integer maximumPossibleHH; //
        public integer maximumPossibleBeds; //sked__Location__c->sked_Maximum_Beds__c
        public integer numberTables; //
        public integer numberChairs; //
        public string notes; //sked_Operation_Record_Staff__c->sked_Notes_Comments__c
        public boolean lockRecord; //
        public string lockedByEmployeeId; //
        public string lockedByEmployeeEmail; //
        
        public List<OpsRecordStaffDetail> StaffDetails;

        public opsRecordRequest() {
            this.checkedInNotRegistered = 0;
            this.donorAmbassadorActual = 0;
            this.donorFlowSignIn1 = 0;
            this.donorFlowSignIn2 = 0;
            this.donorFlowSignIn3 = 0;
            this.donorFlowSignIn4 = 0;
            this.donorFlowSignIn5 = 0;
            this.donorFlowSignIn6 = 0;
            this.donorFlowSignIn7 = 0;
            this.donorFlowSignIn8 = 0;
            this.donorFlowSignInTotal = 0;
            this.driveIssue = 0;
            this.driveIssueClient = 0;
            this.driveIssueHandheld = 0;
            this.driveIssueReason = '';
            this.driveIssuesCancelled = false;
            this.driveIssuesClosedEarly = false;
            this.driveIssuesOpenedLate = false;
            this.estimatedRoomDimensions = '';
            this.externalDriveId = '';
            this.goal = 0;
            this.internalDriveId = '';
            this.lateEndDriveApprovedBy = '';
            this.lateEndDriveReason = '';
            this.lockedByEmployeeEmail = '';
            this.lockedByEmployeeId = '';
            this.internalDriveId = '';
            this.lockRecord = false;
            this.maximumPossibleBeds = 1;  
            this.maximumPossibleHH = 1;  
            this.notes = '';  
            this.numberBedsSetup2RBC = 0;  
            this.numberBedsSetupHH = 0;  
            this.numberBedsSetupWB = 0;  
            this.numberChairs = 0;  
            this.numberRadiosUsed = 0;  
            this.numberTables = 0;  
            this.numberWhiteNoiseMachineUsed = 0;  
            this.powerRedMachinesSent = 0;  
            this.powerRedMachinesUsed = 0;  
            this.roomUsed = '';  
            this.scheduled = 0;
            this.shiftId = 0;
        }
    }
    
    global class opsRecordStaffDetail {
        public integer shiftID;// sked_Drive_Shift__c->sked_UFID__c
        public string email;//sked__Resource__c->sked__Email__c
        public integer personID;//sked__Resource__c->sked_Employee_ID__c
        public string firstName;//sked__Resource__c->sked_First_Name__c
        public string lastName;//sked__Resource__c->sked_Last_Name__c
        public string ebdrid;//sked__Resource__c->sked_eBDR_ID__c
        public string role;//sked_Operation_Record_Staff__c->sked_Role__c
        public string shiftStart;//sked_Operation_Record_Staff__c->sked_Actual_Shift_Start__c
        public string shiftEnd;//sked_Operation_Record_Staff__c->sked_Actual_Shift_End__c
        public boolean noMeal;//sked_Operation_Record_Staff__c->sked_No_Meal__c
        public boolean premiumCharge;//sked_Operation_Record_Staff__c->sked_Premiums_Op_Pay__c
        public boolean premiumDRC;//sked_Operation_Record_Staff__c->sked_Premiums_Op_Pay__c
        public boolean premiumOJI;//sked_Operation_Record_Staff__c->sked_Premiums_Op_Pay__c
        public boolean premiumTranslator;//sked_Operation_Record_Staff__c->sked_Premiums_Op_Pay__c
        public boolean premiumLateEnd;//sked_Operation_Record_Staff__c->sked_Premiums_Op_Pay__c
        public boolean premiumPool;//sked_Operation_Record_Staff__c->sked_Premiums_Op_Pay__c
        public boolean premiumDriver;//sked_Operation_Record_Staff__c->sked_Premiums_Op_Pay__c
        public decimal restBreaksNotTaken;//sked_Operation_Record_Staff__c->sked_Rest_Breaks_Not_Taken__c
        public boolean notWorked;//sked_Operation_Record_Staff__c->sked_Absent__c
        public boolean addedStaff;//

        public opsRecordStaffDetail() {
            this.addedStaff = false;
            this.ebdrid = '';
            this.email = '';
            this.firstName = '';
            this.lastName = '';
            this.noMeal = false;
            this.notWorked = false;
            this.personID = 0;
            this.premiumCharge = false;
            this.premiumDRC = false;
            this.premiumLateEnd = false;
            this.premiumOJI = false;
            this.premiumPool = false;
            this.premiumDriver = false;
            this.premiumTranslator = false;
            this.role = '';
        }
    }
    
    global class opsRecordResult extends resultBase {
        
    }

    /* REFRESH TOKEN */
    global class refreshTokenResult extends resultBase {
        public string access_token;
        public string token_type;
        public string expires_in;
    }
    
}