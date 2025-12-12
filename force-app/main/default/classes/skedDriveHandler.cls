public class skedDriveHandler extends skedTriggerHub {
    
    public static List<sked_Drive__c> recordsToRank;
    
    public static boolean processConfirmedDriveDCRs;
    public static List<sked_Drive_Change_Request__c> confirmedDriveNewDCR;
    public static List<sked_Drive_Change_Request__c> confirmedDriveExistingDCR;
    public static Map<string, string> mapReasonFields = new Map<string, string>{
        'Anticipated_Registered_Donors__c' => 'AnticipatedRegisterDonorChangeReason__c',
        'WB_Projected_Procedures__c' => 'WholeBloodProcedureProjectedChangeReason__c',
        'X2RBC_Projected_Procedures__c' => 'DoubleRedProceduresProjectedChangeReason__c',
        'Slot_Generator__c' => 'Slot_Generator_Change_Reason__c',
        'APT_Quantity__c' => 'APT_Change_Reason__c'
    };

    private static final Map<String, String> DRIVE_GEN_OPP_FIELD_BY_DRIVE_FIELD = new Map<String, String>{
        'sked_Drive_Date__c' => 'Drive_Date__c',
        'sked_Status__c' => 'Drive_Status__c',
        'sked_Start_Time__c' => 'Start_Time__c',
        'sked_End_Time__c' => 'End_Time__c',
        'sked_Drive_Site__c' => 'Drive_Site__c',
        'sked_Replacement_Drive__c' => 'sked_Replacement_Drive__c',
        'sked_Projected_Registered_Donors__c' => 'Anticipated_Registered_Donors__c',
        'sked_WB_Projected_Procedures__c' => 'WB_Projected_Procedures__c',
        'sked_2RBC_Projected_Procedures__c' => 'X2RBC_Projected_Procedures__c',
        'sked_Platelet_Projected_Procedures__c' => 'Platelet_Projected_Procedures__c',
        'sked_Plasma_Projected_Procedures__c' => 'Plasma_Pheresis_Projected_Procedures__c',
        'sked_Number_of_2RBC_Assets__c' => 'Number_of_2RBC_Assets__c',
        'sked_Number_of_Plasma_Assets__c' => 'Number_of_Plasma_Assets__c',
        'sked_Number_of_Platelet_Assets__c' => 'Number_of_Platelet_Assets__c',
        'sked_Cancellation_Detail__c' => 'Cancellation_Detail__c',
        'sked_Cancellation_Reason__c' => 'sked_Cancellation_Reason__c',
        'sked_Initiated_By__c' => 'Initiated_By__c',
        'sked_APT_Required__c' => 'APT_Required__c',
        'sked_APT_Quantity__c' => 'APT_Quantity__c',
        'sked_Redcross_Volunteer_Required__c' => 'Red_Cross_Volunteer_Required__c',
        'sked_Redcross_Volunteer_Quantity__c' => 'Red_Cross_Volunteer_Quantity__c'
    };
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
        List<sked_Drive__c> newRecords = filterDrives(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
        populateDriveName(newRecords);
        populateCollectionOperationData(newRecords);
        populateData(newRecords);
        calculatePoint(newRecords);
    }
    
    public override void onAfterInsert() {
        List<sked_Drive__c> newRecords = filterDrives(this.context.newRecords);
        populateIdentifier(this.context.newRecords);
        
        if (!skedSetting.instance.Admin.migrationMode) {
            rankDrives();
            syncDriveFieldsToOpportunity(newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
        List<sked_Drive__c> newRecords = filterDrives(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
        }
        onConfirmDrives((Map<Id, sked_Drive__c>) this.context.newMap, (Map<Id, sked_Drive__c>)this.context.oldMap);
        onApprovedRejected(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
        repopulateDistrict(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
        populateDriveName(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
        populateData(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
        calculatePoint(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
        populateHoldExpiration(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            List<sked_Drive__c> newRecords = filterDrives(this.context.newRecords);
            rankDrives();
            submitConfirmDriveRequest(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
            sendNotification(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
            processLinkedDriveRemoval(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
            onUnholdDrives(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
            onCancelDrives(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
            onCancelledRejectedApproval(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
            revalidateAllocations(newRecords, (Map<Id, sked_Drive__c>)this.context.oldMap);
            submitDriveForApproval(newRecords,(Map<Id, sked_Drive__c>)this.context.oldMap);
            submitDriveForCancelApproval(newRecords,(Map<Id, sked_Drive__c>)this.context.oldMap);
            notifyDriveChanges(newRecords,(Map<Id, sked_Drive__c>)this.context.oldMap);
            onStagingLocationChanged(newRecords, (Map<Id, sked_Drive__c>) this.context.oldMap);
            handleLinkedDriveUpdates(newRecords, (Map<Id, sked_Drive__c>) this.context.oldMap);
        }
    }
    
    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
        authorizeDeletePermission(this.context.newRecords);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void authorizeDeletePermission(List<sked_Drive__c> newRecords) {
        User loginUser = [SELECT Id, Name, Profile.Name
                          FROM User
                          WHERE Id = :UserInfo.getUserId()];
        List<string> systemAdminProfiles = new List<string>();
        systemAdminProfiles.add('Global Admin');
        systemAdminProfiles.add('System Administrator');
        boolean canDelete = systemAdminProfiles.contains(loginUser.Profile.Name);
        
        if (!canDelete) {
            for (sked_Drive__c newRecord : newRecords) {
                newRecord.addError('You are not authorized to delete Drive.');
            }
        }
    }
    
    private void calculatePoint(List<sked_Drive__c> newRecords) {
        List<sked_Drive_Rank_Setting__c> driveRankSettings = [SELECT Id, sked_Type__c, sked_Low_End__c, sked_High_End__c, sked_Point__c
                                                              FROM sked_Drive_Rank_Setting__c];
        if (!driveRankSettings.isEmpty()) {
            skedDriveHandler.recordsToRank = new List<sked_Drive__c>();
            
            for (sked_Drive__c newRecord : newRecords) {
                decimal driveProductivityPoints = 0;
                if (newRecord.sked_Drive_Productivity_Planned__c != NULL) {
                    for (sked_Drive_Rank_Setting__c driveRankSetting : driveRankSettings) {
                        if (driveRankSetting.sked_Type__c == 'Planned Productivity') {
                            if (driveRankSetting.sked_Low_End__c <= newRecord.sked_Drive_Productivity_Planned__c && newRecord.sked_Drive_Productivity_Planned__c < driveRankSetting.sked_High_End__c) {
                                driveProductivityPoints = driveRankSetting.sked_Point__c;
                                break;
                            }
                        }
                    }
                }
                
                decimal sizePoints = 0;
                if (newRecord.sked_Projected_Registered_Donors__c != NULL) {
                    for (sked_Drive_Rank_Setting__c driveRankSetting : driveRankSettings) {
                        if (driveRankSetting.sked_Type__c == 'Size') {
                            if (driveRankSetting.sked_Low_End__c <= newRecord.sked_Projected_Registered_Donors__c && newRecord.sked_Projected_Registered_Donors__c < driveRankSetting.sked_High_End__c) {
                                sizePoints = driveRankSetting.sked_Point__c;
                                break;
                            }
                        }
                    }
                }
                decimal currentPoint = newRecord.sked_Point__c;
                newRecord.sked_Point__c = driveProductivityPoints + sizePoints;
                if (newRecord.sked_Status__c == 'Draft' && newRecord.sked_Type_of_Drive__c != 'Fixed Site') {
                    skedDriveHandler.recordsToRank.add(newRecord);
                }
            }
        }
    }
    
    private void calculatePoint(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        List<sked_Drive__c> recordsToCalculate = new List<sked_Drive__c>();
        for (sked_Drive__c newRecord : newRecords) {
            sked_Drive__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Projected_Registered_Donors__c != oldData.sked_Projected_Registered_Donors__c || newRecord.sked_Drive_Productivity_Planned__c != oldData.sked_Drive_Productivity_Planned__c) {
                recordsToCalculate.add(newRecord);
            }
        }
        if (!recordsToCalculate.isEmpty()) {
            calculatePoint(recordsToCalculate);
        }
    }
    
    private void rankDrives() {
        if (skedDriveHandler.recordsToRank != NULL && !skedDriveHandler.recordsToRank.isEmpty()) {
            if (!System.isBatch() && !Test.isRunningTest() && !skedSetting.instance.Admin.migrationMode) {
                Database.executeBatch(new skedDriveRankingBatch(skedDriveHandler.recordsToRank), 1);
                
                skedDriveHandler.recordsToRank = NULL;
            }
        }
    }
    
    private void onCancelDrives(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        Set<Id> cancelledDriveIds = new Set<Id>();
        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        for (sked_Drive__c newRecord : newRecords) {
			sked_Drive__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_CANCEL) {
                    cancelledDriveIds.add(newRecord.Id);
                }
            }
        }
        if (!cancelledDriveIds.isEmpty()) {
            List<sked__Job__c> skedJobsToCancelled = [SELECT Id, sked__Job_Status__c, sked__Job_Allocation_Count__c
                                                      FROM sked__Job__c
                                                      WHERE sked_Drive__c IN :cancelledDriveIds
                                                      AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                                      AND sked__Job_Status__c != :skedConstants.JOB_STATUS_COMPLETE];
            if (!skedJobsToCancelled.isEmpty()) {
                for (sked__Job__c skedJob : skedJobsToCancelled) {
                    skedJob.sked__Job_Status__c = skedConstants.JOB_STATUS_CANCELLED;
                }
                update skedJobsToCancelled;
            }
            
            List<skedHC__Exception__c> exceptionLogToClose = [SELECT Id, skedHC__Status__c
                                                              FROM skedHC__Exception__c
                                                              WHERE sked_Drive__c IN :cancelledDriveIds
                                                              AND skedHC__Status__c != :skedConstants.EXCEPTION_LOG_STATUS_CLOSED];
            if (!exceptionLogToClose.isEmpty()) {
                for (skedHC__Exception__c exceptionItem : exceptionLogToClose) {
                    exceptionItem.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                }
                update exceptionLogToClose;
            }
            
            List<sked_Drive_Change_Request__c> pendingDCRs = [SELECT Id, sked_Status__c
                                                              FROM sked_Drive_Change_Request__c
                                                              WHERE sked_Drive__c IN :cancelledDriveIds
                                                              AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM
                                                              AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED
                                                              AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_REJECTED
                                                              AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED];
            if (!pendingDCRs.isEmpty()) {
                for (sked_Drive_Change_Request__c pendingDCR : pendingDCRs) {
                    pendingDCR.sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED;
                }
                update pendingDCRs;
            }
            
            skedFutureCallEventHandler.publishFutureCallEvent(
                slwcApprovalService.class.getName(),
                'removeWorkItems',
                cancelledDriveIds);
        }
    }
    
    private void onConfirmDrives(Map<Id, sked_Drive__c> newRecordsById, Map<Id, sked_Drive__c> oldMap) {
        User loginUser = [SELECT Id, Name, Profile.Name, alias
                          FROM User
                          WHERE Id = :UserInfo.getUserId()];
        List<string> systemAdminProfiles = new List<string>();
        systemAdminProfiles.add('Global Admin');
        systemAdminProfiles.add('System Administrator');
        boolean isAutomatedProcess = userInfo.getName() == 'Automated Process';
        boolean isAdmin = !isAutomatedProcess && systemAdminProfiles.contains(loginUser.Profile.Name);
        boolean isAPS = !isAutomatedProcess && loginUser.Profile.Name.startsWith('APS');
        boolean canBypass = isAdmin || isAPS || isAutomatedProcess;

        Map<Id, sked_Drive__c> mapConfirmedDrives = new Map<Id, sked_Drive__c>();
        for (Id newRecordId : newRecordsById.keySet()) {
            sked_Drive__c newRecord = newRecordsById.get(newRecordId);
            sked_Drive__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_CONFIRMED) {
                    mapConfirmedDrives.put(newRecord.Id, newRecord);
                }
            }
        }
        
        if (!mapConfirmedDrives.isEmpty()) {
            if (!canBypass) {
                onConfirmDrives_validateDCR(mapConfirmedDrives, newRecordsById, oldMap);
            }
            onConfirmDrives_validateTimeBlock(mapConfirmedDrives, newRecordsById, oldMap);
        }
    }
    
    private void onConfirmDrives_validateDCR(Map<Id, sked_Drive__c> mapConfirmedDrives, Map<Id, sked_Drive__c> newRecordsById, Map<Id, sked_Drive__c> oldMap) {
        List<sked_Drive_Change_request__c> existingDcrs = [
            SELECT Id, sked_Drive__c, sked_Drive_Contention__c,
            (SELECT Id, sked_Field_API_Name__c 
             FROM sked_Drive_Change_Request_Items__r 
             WHERE sked_Field_API_Name__c LIKE '%Drive_Date__c')
            FROM sked_Drive_Change_request__c
            WHERE sked_Drive__c IN :mapConfirmedDrives.keySet()
            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED
            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM
            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_REJECTED
            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED
        ];
        Map<Id, sked_Drive_Change_request__c> map_driveId_DCR = new Map<Id, sked_Drive_Change_request__c>();
        for (sked_Drive_Change_request__c existingDcr : existingDcrs) {
            map_driveId_DCR.put(existingDcr.sked_Drive__c, existingDcr);
        }
        
        skedDriveHandler.confirmedDriveNewDCR = new List<sked_Drive_Change_Request__c>();
        skedDriveHandler.confirmedDriveExistingDCR = new List<sked_Drive_Change_Request__c>();
        
        Date currentDate = system.today();
        
        for (sked_Drive__c confirmedDrive : mapConfirmedDrives.values()) {
            sked_Drive__c newRecordDrive = newRecordsById.get(confirmedDrive.Id);
            sked_Drive_Change_Request__c dcr = map_driveId_DCR.get(confirmedDrive.Id);
            boolean isAlreadyCaptured = dcr != NULL && dcr.sked_Drive_Contention__c != NULL
                && dcr.sked_Drive_Contention__c.contains('Confirmed within 42 days');
            
            integer daysBetween = currentDate.daysBetween(confirmedDrive.sked_Drive_Date__c);
            boolean isResolvedContention = confirmedDrive.sked_Contention_Resolution__c != NULL 
                && confirmedDrive.sked_Contention_Resolution__c.contains('Elect to approve the drive that is confirmed within 42 days');
            
            if (dcr != null && dcr.sked_Drive_Change_Request_Items__r != null && !dcr.sked_Drive_Change_Request_Items__r.isEmpty()) {
                newRecordDrive.addError('Unable to confirm drive with active Drive Change Request for a change in Drive Date. Please Approve or Reject the Request before continuing.');
            }
            
            if (daysBetween <= 42 && !isResolvedContention && !isAlreadyCaptured) {
                sked_Drive__c oldData = oldMap.get(confirmedDrive.Id);
                confirmedDrive.sked_Status__c = oldData.sked_Status__c;
                
                if (dcr == NULL) {
                    dcr = new sked_Drive_Change_Request__c(
                        sked_Drive__c = confirmedDrive.Id
                    );
                    skedDriveHandler.confirmedDriveNewDCR.add(dcr);
                }
                else {
                    skedDriveHandler.confirmedDriveExistingDCR.add(dcr);
                }
            }
        }
        skedDriveHandler.processConfirmedDriveDCRs = !skedDriveHandler.confirmedDriveNewDCR.isEmpty() || !skedDriveHandler.confirmedDriveExistingDCR.isEmpty();
    }
    
    private void onConfirmDrives_validateTimeBlock(Map<Id, sked_Drive__c> mapConfirmedDrives, Map<Id, sked_Drive__c> newRecordsById, Map<Id, sked_Drive__c> oldMap) {
        Set<Id> collectionOperationIds = new Set<Id>();
        Date minDate, maxDate;
        for (sked_Drive__c confirmedDrive : mapConfirmedDrives.values()) {
            collectionOperationIds.add(confirmedDrive.sked_Collection_Operation__c);
            minDate = (minDate == NULL || minDate > confirmedDrive.sked_Drive_Date__c) ? confirmedDrive.sked_Drive_Date__c : minDate;
            maxDate = (maxDate == NULL || maxDate < confirmedDrive.sked_Drive_Date__c) ? confirmedDrive.sked_Drive_Date__c : maxDate;
        }
        
        Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([
            SELECT Id, sked_Minimum_Drive_Start_Time__c, sked_Maximum_Drive_End_Time__c,
            (SELECT Id, Collection_Operation__c, Time_Block__c, Effective_Start_Date__c, Effective_End_Date__c,
             Time_Block__r.Days_of_Week__c, Time_Block__r.Start_Time__c, Time_Block__r.End_Time__c
             FROM Collection_Operation_Time_Blocks__r
             WHERE Effective_Start_Date__c <= :maxDate
             AND Effective_End_Date__c >= :minDate)
            FROM Biomed_Collection_Op_Center__c
            WHERE Id IN :collectionOperationIds
        ]);
        
        List<sked_Drive_Shift__c> driveShifts = [
            SELECT Id, sked_Drive__c, sked_Time_Block__c, sked_Contention__c , sked_Contention_Resolution__c 
            FROM sked_Drive_Shift__c
            WHERE sked_Drive__c IN :mapConfirmedDrives.keySet()
        ];
        
        for (sked_Drive_Shift__c driveShift : driveShifts) {
            if (driveShift.sked_Time_Block__c == NULL || (driveShift.sked_Time_Block__c != NULL && driveShift.sked_Contention__c != NULL && driveShift.sked_Contention_Resolution__c == NULL)) {
                sked_Drive__c drive = mapConfirmedDrives.get(driveShift.sked_Drive__c);
                
                Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(drive.sked_Collection_Operation__c);
                
                List<Collection_Operation_Time_Block__c> usedCOTBs = new List<Collection_Operation_Time_Block__c>();
                
                for (Collection_Operation_Time_Block__c coTB : collectionOperation.Collection_Operation_Time_Blocks__r) {
                    boolean isWeekdayMatched = coTB.Time_Block__r.Days_of_Week__c.contains(drive.sked_Day_of_Week__c);
                    boolean isEffective = coTB.Effective_Start_Date__c <= drive.sked_Drive_Date__c && drive.sked_Drive_Date__c <= coTB.Effective_End_Date__c;
                    
                    if (isEffective && isWeekdayMatched) {
                        usedCOTBs.add(coTB);
                    }
                }
                
                if (!usedCOTBs.isEmpty()) {
                    sked_Drive__c newRecordDrive = newRecordsById.get(driveShift.sked_Drive__c);
                    newRecordDrive.addError('Time block(s) must be assigned to drive shifts and any contentions resolved in order to confirm the drive (go to Opportunity > Drive Scheduling, or DOC > Drive Shifts)');
                }
            }
        }
    }
    
    private void submitConfirmDriveRequest(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        if (skedDriveHandler.processConfirmedDriveDCRs == TRUE) {
            skedDriveHandler.processConfirmedDriveDCRs = FALSE;
            
            List<sked_Drive_Change_Request__c> allDcrs = new List<sked_Drive_Change_Request__c>();
            if (skedDriveHandler.confirmedDriveNewDCR != NULL && !skedDriveHandler.confirmedDriveNewDCR.isEmpty()) {
                insert skedDriveHandler.confirmedDriveNewDCR;
                allDcrs.addAll(skedDriveHandler.confirmedDriveNewDCR);
            }
            if (skedDriveHandler.confirmedDriveExistingDCR != NULL && !skedDriveHandler.confirmedDriveExistingDCR.isEmpty()) {
                allDcrs.addAll(skedDriveHandler.confirmedDriveExistingDCR);
            }
            if (!allDcrs.isEmpty()) {
                List<sked_Drive_Change_Request_Item__c> dcrItemsToInsert = new List<sked_Drive_Change_Request_Item__c>();
                for (sked_Drive_Change_Request__c dcr : allDcrs) {
                    sked_Drive__c oldData = oldMap.get(dcr.sked_Drive__c);
                    sked_Drive_Change_Request_Item__c driveChange = new sked_Drive_Change_Request_Item__c(
                        sked_Drive_Change_Request__c = dcr.Id,
                        sked_Object_API_Name__c = 'sked_Drive__c',
                        sked_Field_API_Name__c = 'sked_Status__c',
                        sked_Field_Label__c = 'Status',
                        sked_Field_Type__c = 'string',
                        sked_Type__c = 'Impact',
                        sked_Old_Value__c = oldData.sked_Status__c,
                        sked_New_Value__c = skedConstants.DRIVE_STATUS_CONFIRMED
                    );
                    dcrItemsToInsert.add(driveChange);
                    
                    sked_Drive_Change_Request_Item__c opportunityChange = new sked_Drive_Change_Request_Item__c(
                        sked_Drive_Change_Request__c = dcr.Id,
                        sked_Object_API_Name__c = 'Opportunity',
                        sked_Field_API_Name__c = 'Drive_Status__c',
                        sked_Field_Label__c = 'Status',
                        sked_Field_Type__c = 'string',
                        sked_Type__c = 'Change',
                        sked_Old_Value__c = oldData.sked_Status__c,
                        sked_New_Value__c = skedConstants.DRIVE_STATUS_CONFIRMED
                    );
                    dcrItemsToInsert.add(opportunityChange);
                }
                
                if (!dcrItemsToInsert.isEmpty()) {
                    insert dcrItemsToInsert;
                }
                
                if (skedDriveHandler.confirmedDriveNewDCR != NULL && !skedDriveHandler.confirmedDriveNewDCR.isEmpty()) {
                    for (sked_Drive_Change_Request__c dcr : skedDriveHandler.confirmedDriveNewDCR) {
                        dcr.sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_SUBMITTED;
                        dcr.sked_Drive_Contention__c = 'Confirmed within 42 days';
                        dcr.sked_Route_Approval_Request_To__c = 'Request APS exception';
                    }
                }
                if (skedDriveHandler.confirmedDriveExistingDCR != NULL && !skedDriveHandler.confirmedDriveExistingDCR.isEmpty()) {
                    for (sked_Drive_Change_Request__c dcr : skedDriveHandler.confirmedDriveExistingDCR) {
                        dcr.sked_Drive_Contention__c = skedUtils.addNewItemToMultiPicklist(dcr.sked_Drive_Contention__c, 'Confirmed within 42 days');
                    }
                }
                update allDcrs;
                
                skedDriveHandler.confirmedDriveNewDCR = NULL;
                skedDriveHandler.confirmedDriveExistingDCR = NULL;
            }
        }
    }
    
    private void onUnholdDrives(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        Set<Id> unholdDriveIds = new Set<Id>();
        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        for (sked_Drive__c newRecord : newRecords) {
			sked_Drive__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_DRAFT && oldData.sked_Status__c == skedConstants.DRIVE_STATUS_HOLD) {
                unholdDriveIds.add(newRecord.Id);
            }
        }
        if (!unholdDriveIds.isEmpty()) {
            List<sked__Job_Allocation__c> skedAllocations = [SELECT Id, sked__Status__c
                                                             FROM sked__Job_Allocation__c
                                                             WHERE sked__Job__r.sked_Drive__c IN :unholdDriveIds
                                                             AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
            if (!skedAllocations.isEmpty()) {
                for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
                    skedAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
                }
                update skedAllocations;
            }
            
            List<skedHC__Exception__c> exceptionLogToClose = [SELECT Id, skedHC__Status__c
                                                              FROM skedHC__Exception__c
                                                              WHERE sked_Drive__c IN :unholdDriveIds
                                                              AND skedHC__Status__c != :skedConstants.EXCEPTION_LOG_STATUS_CLOSED];
            if (!exceptionLogToClose.isEmpty()) {
                for (skedHC__Exception__c exceptionItem : exceptionLogToClose) {
                    exceptionItem.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                }
                update exceptionLogToClose;
            }
        }
    }
    
    private void notifyDriveChanges(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        List<Opportunity> oppList = new List<Opportunity>();
        for (sked_Drive__c newRecord : newRecords) {
            if (newRecord.sked_Opportunity__c != NULL) {
                sked_Drive__c oldData = oldMap.get(newRecord.Id);
                
                Opportunity oppRec = new Opportunity(Id = newRecord.sked_Opportunity__c);
                boolean isOptyRequiredUpdate = FALSE;
                for (string driveField : DRIVE_GEN_OPP_FIELD_BY_DRIVE_FIELD.keySet()) {
                    object newValue = newRecord.get(driveField);
                    object oldValue = oldData.get(driveField);
                    if (newValue != oldValue) {
                        string oppDataField = DRIVE_GEN_OPP_FIELD_BY_DRIVE_FIELD.get(driveField);
                        oppRec.put(oppDataField, newValue);
                        
                        if (mapReasonFields.containsKey(oppDataField)) {
                            string reasonField = mapReasonFields.get(oppDataField);
                            string reason = 'Changed from Drive record. ' + system.now();
                            oppRec.put(reasonField, reason);
                        }
                        isOptyRequiredUpdate = TRUE;
                    }
                }
                if (isOptyRequiredUpdate) {
                    system.debug('#oppRec# ' + oppRec);
                    oppRec.Is_Recursion_On__c = TRUE;
                    oppList.add(oppRec);
                }
            }
        }
        
        if (!oppList.isEmpty() && !Test.isRunningTest()) {
            opportunityService.syncOppsWithDrives(oppList);
        }
    }
    
    private void onCancelledRejectedApproval(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        Set<Id> recordIdsToCancelApproval = new Set<Id>();
        Set<Id> rejectedPendingCancellationDriveIds = new Set<Id>();
        for (sked_Drive__c newRecord : newRecords) {
            if (newRecord.sked_Pending_Action__c != NULL && newRecord.sked_Pending_Action__c != 'Drive Change Request') {
                sked_Drive__c oldData = oldMap.get(newRecord.Id);
                if (newRecord.sked_Approval_Status__c != oldData.sked_Approval_Status__c) {
                    if (newRecord.sked_Approval_Status__c == 'Cancelled') {
                        recordIdsToCancelApproval.add(newRecord.Id);
                    }
                    if ((newRecord.sked_Approval_Status__c == 'Cancelled' || newRecord.sked_Approval_Status__c == 'Rejected') && newRecord.sked_Pending_Action__c.contains('Cancel In Process')) {
                        rejectedPendingCancellationDriveIds.add(newRecord.Id);
                    }
                }
            }
        }
        if (!rejectedPendingCancellationDriveIds.isEmpty()) {
            unlockAppointments(rejectedPendingCancellationDriveIds);
        }
        if (!recordIdsToCancelApproval.isEmpty()) {
            slwcApprovalService.removeWorkItems(recordIdsToCancelApproval);
        }
    }
    
    private void onApprovedRejected(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        Set<String> processedStatuses = new Set<string>();
        processedStatuses.add('Approved');
        processedStatuses.add('Rejected');
        processedStatuses.add('Cancelled');
        
        List<sked_Drive__c> appointmentSlotsToUnlock = new List<sked_Drive__c>();
        List<Opportunity> oppList = new List<Opportunity>();
        for (sked_Drive__c newRecord : newRecords) {
            if (newRecord.sked_Pending_Action__c != NULL && newRecord.sked_Pending_Action__c != 'Drive Change Request') {
                sked_Drive__c oldData = oldMap.get(newRecord.Id);
                if (newRecord.sked_Approval_Status__c != oldData.sked_Approval_Status__c && processedStatuses.contains(newRecord.sked_Approval_Status__c)) {
                    string newDriveStatus = newRecord.sked_Status__c;
                    if (newRecord.sked_Approval_Status__c == 'Approved') {
                        if (newRecord.sked_Pending_Action__c == 'Cancel In Process') {
                            newDriveStatus = skedConstants.DRIVE_STATUS_CANCEL;
                        }
                        if (newRecord.sked_Pending_Action__c == 'Drive Submission') {
                            newDriveStatus = skedConstants.DRIVE_STATUS_TENTATIVE;
                        }
                    }
                    else {
                        if (newRecord.sked_Pending_Action__c == 'Cancel In Process') {
                            Opportunity oppRec = new Opportunity(Id = newRecord.sked_Opportunity__c);
                            oppRec.Drive_Status__c = newRecord.sked_Status__c;
                            oppRec.Is_Recursion_On__c = TRUE;
                            oppList.add(oppRec);

                            appointmentSlotsToUnlock.add(newRecord);
                        }
                    }
                    newRecord.sked_Status__c = newDriveStatus;
                    newRecord.sked_Route_Approval_Request_To__c = NULL;
                }
            }
        }
        
        if (!oppList.isEmpty()) {
            opportunityService.syncOppsWithDrives(oppList);
        }
    }
    
    private void populateHoldExpiration(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        List<sked_Drive__c> holdingDrives = new List<sked_Drive__c>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Drive__c newRecord : newRecords) {
			sked_Drive__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_HOLD) {
                    if (newRecord.sked_Collection_Operation__c != NULL && newRecord.sked_Account__c != NULL) {
                        holdingDrives.add(newRecord);
                        accountIds.add(newRecord.sked_Account__c);
                        collectionOperationIds.add(newRecord.sked_Collection_Operation__c);
                    }
                }
            }
        }
        if (!holdingDrives.isEmpty()) {
            Id loginUserId = UserInfo.getUserId();
            List<AccountTeamMember> accountTeamMembers = [SELECT Id, AccountId, TeamMemberRole 
                                                          FROM AccountTeamMember
                                                          WHERE UserId = :loginUserId
                                                          AND AccountId IN :accountIds];
            Map<Id, Set<string>> map_accountId_roles = new Map<Id, Set<string>>();
            for (AccountTeamMember accountTeamMember : accountTeamMembers) {
                Set<string> roles;
                if (map_accountId_roles.containsKey(accountTeamMember.AccountId)) {
                    roles = map_accountId_roles.get(accountTeamMember.AccountId);
                }
                else {
                    roles = new Set<string>();
                    map_accountId_roles.put(accountTeamMember.AccountId, roles);
                }
                roles.add(accountTeamMember.TeamMemberRole);
            }
            
            DateTime currentTime = system.now();
            Date currentDate = system.today();
            integer daysThreshold = 12 * 7; //12 weeks
            Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperation 
                = new Map<Id, Biomed_Collection_Op_Center__c>([SELECT Id, sked_Hold_Threshold__c
                                                               FROM Biomed_Collection_Op_Center__c
                                                               WHERE Id IN :collectionOperationIds]);
            for (sked_Drive__c holdingDrive : holdingDrives) {
                Biomed_Collection_Op_Center__c collectionOperation = mapCollectionOperation.get(holdingDrive.sked_Collection_Operation__c);
                integer holdThresholdHours = collectionOperation.sked_Hold_Threshold__c != NULL ? integer.valueOf(collectionOperation.sked_Hold_Threshold__c) : 48;
                boolean isPowerBooker = FALSE;
                if (holdingDrive.sked_Account__c != NULL && map_accountId_roles.containsKey(holdingDrive.sked_Account__c)) {
                    Set<string> roles = map_accountId_roles.get(holdingDrive.sked_Account__c);
                    isPowerBooker = roles.contains(skedConstants.ACCCOUNT_TEAM_ROLE_POWER_BOOKER);
                }
                boolean isStandard = TRUE;
                if (isPowerBooker) {
                    integer daysBeforeDriveDate = currentDate.daysBetween(holdingDrive.sked_Drive_Date__c);
                    if (daysBeforeDriveDate >= daysThreshold) {
                        Date dateThreshold = holdingDrive.sked_Drive_Date__c.addDays(-daysThreshold);
                        DateTime dateTimeThreshold = DateTime.newInstance(dateThreshold, Time.newInstance(0, 0, 0, 0));
                        dateTimeThreshold = dateTimeThreshold.addHours(holdThresholdHours);
                        holdingDrive.sked_Hold_Status_expires_on__c = dateTimeThreshold;
                        isStandard = FALSE;
                    }
                }
                if (isStandard) {
                	holdingDrive.sked_Hold_Status_expires_on__c = currentTime.addHours(holdThresholdHours);
                }
            }
        }
    }
    
    private void populateData(List<sked_Drive__c> newRecords) {
        for (sked_Drive__c newRecord : newRecords) {
            if (newRecord.sked_Drive_Date__c != NULL) {
                DateTime driveDateDt = DateTime.newInstance(newRecord.sked_Drive_Date__c, Time.newInstance(0, 0, 0, 0));
                newRecord.sked_Day_of_Week__c = driveDateDt.format('EEEE');
            }
            if (newRecord.sked_Drive_Productivity_Planned__c != NULL) {
                newRecord.sked_Drive_Productivity_Planned__c = newRecord.sked_Drive_Productivity_Planned__c.setScale(2);
            }
        }
    }
    
    private void populateCollectionOperationData(List<sked_Drive__c> newRecords) {
        List<sked_Drive__c> recordsToPopulate = new List<sked_Drive__c>();
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Drive__c newRecord : newRecords) {
            recordsToPopulate.add(newRecord);
            
            if (newRecord.sked_Collection_Operation__c != NULL) {
                collectionOperationIds.add(newRecord.sked_Collection_Operation__c);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>();
            if (!collectionOperationIds.isEmpty()) {
                mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([SELECT Id, sked_Hold_Threshold__c, sked_Travel_Time_Included_Mobile__c,
                                                                     sked_Travel_Time_Included_Fixed_Site__c,
                                                                     (SELECT Id, sked_End_Date__c, sked_Start_Date__c, sked_Territory__c
                                                                      FROM sked_Territory_Collection_Operations__r)
                                                                     FROM Biomed_Collection_Op_Center__c
                                                                     WHERE Id IN :collectionOperationIds]);
            }
            
            for (sked_Drive__c recordToPopulate : recordsToPopulate) {
                if (mapCO.containsKey(recordToPopulate.sked_Collection_Operation__c)) {
                    Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(recordToPopulate.sked_Collection_Operation__c);
                    
                    for (sked_Territory_Collection_Operation__c territoryCO : collectionOperation.sked_Territory_Collection_Operations__r) {
                        boolean isStartDateMatched = territoryCO.sked_Start_Date__c == NULL || territoryCO.sked_Start_Date__c <= recordToPopulate.sked_Drive_Date__c;
                        boolean isEndDateMatched = territoryCO.sked_End_Date__c == NULL || territoryCO.sked_End_Date__c >= recordToPopulate.sked_Drive_Date__c;
                        if (isStartDateMatched && isEndDateMatched) {
                            recordToPopulate.sked_District__c = territoryCO.sked_Territory__c;
                            break;
                        }
                    }
                    if (recordToPopulate.sked_Travel_Time_Included__c == NULL) {
                        recordToPopulate.sked_Travel_Time_Included__c = recordToPopulate.sked_Type_of_Drive__c == 'Mobile' 
                            ? collectionOperation.sked_Travel_Time_Included_Mobile__c 
                            : collectionOperation.sked_Travel_Time_Included_Fixed_Site__c;
                    }
                }
            }
        }
    }
    
    private void repopulateDistrict(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        List<sked_Drive__c> recordsToPopulate = new List<sked_Drive__c>();
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Drive__c newRecord : newRecords) {
            sked_Drive__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Collection_Operation__c != oldData.sked_Collection_Operation__c || newRecord.sked_Drive_Date__c != oldData.sked_Drive_Date__c) {
                recordsToPopulate.add(newRecord);
                
                if (newRecord.sked_Collection_Operation__c != NULL) {
                    collectionOperationIds.add(newRecord.sked_Collection_Operation__c);
                }
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>();
            if (!collectionOperationIds.isEmpty()) {
                mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([SELECT Id, 
                                                                     (SELECT Id, sked_End_Date__c, sked_Start_Date__c, sked_Territory__c
                                                                      FROM sked_Territory_Collection_Operations__r)
                                                                     FROM Biomed_Collection_Op_Center__c
                                                                     WHERE Id IN :collectionOperationIds]);
            }
            
            for (sked_Drive__c recordToPopulate : recordsToPopulate) {
                if (mapCO.containsKey(recordToPopulate.sked_Collection_Operation__c)) {
                    Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(recordToPopulate.sked_Collection_Operation__c);
                    
                    for (sked_Territory_Collection_Operation__c territoryCO : collectionOperation.sked_Territory_Collection_Operations__r) {
                        boolean isStartDateMatched = territoryCO.sked_Start_Date__c == NULL || territoryCO.sked_Start_Date__c <= recordToPopulate.sked_Drive_Date__c;
                        boolean isEndDateMatched = territoryCO.sked_End_Date__c == NULL || territoryCO.sked_End_Date__c >= recordToPopulate.sked_Drive_Date__c;
                        if (isStartDateMatched && isEndDateMatched) {
                            recordToPopulate.sked_District__c = territoryCO.sked_Territory__c;
                            break;
                        }
                    }
                }
            }
        }
    }
    
    private void populateData(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        List<string> pendingApprovalStatuses = skedDriveApprovalUtils.getPendingApprovalStatuses();
        
        Date currentDate = system.today();
        for (sked_Drive__c newRecord : newRecords) {
			sked_Drive__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Status__c != oldData.sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_CANCEL) {
                    newRecord.sked_Cancellation_Date__c = currentDate;
                    
                    if (pendingApprovalStatuses.contains(newRecord.sked_Approval_Status__c)) {
                        newRecord.sked_Approval_Status__c = 'Cancelled';
                    }
                }
            }
            //update drive status based on RTV Approval
            if (newRecord.sked_RTV_Approval_Status__c != oldData.sked_RTV_Approval_Status__c) {
                if (newRecord.sked_RTV_Approval_Status__c == 'Approved') {
                    newRecord.sked_Status__c = newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_CONFIRMED 
                        ? skedConstants.DRIVE_STATUS_TENTATIVE : newRecord.sked_Status__c;
                }
                else if (newRecord.sked_RTV_Approval_Status__c == 'Rejected') {
                    newRecord.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
                }
            }
            
            if (newRecord.sked_Drive_Date__c != oldData.sked_Drive_Date__c && newRecord.sked_Drive_Date__c != NULL) {
                DateTime driveDateDt = DateTime.newInstance(newRecord.sked_Drive_Date__c, Time.newInstance(0, 0, 0, 0));
                newRecord.sked_Day_of_Week__c = driveDateDt.format('EEEE');
            }
            if (newRecord.sked_Status__c != oldData.sked_Status__c 
                && (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_APPROVED || newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_CANCEL)
                && oldData.sked_Is_New_Drive_Confirmation__c) {
                newRecord.sked_Is_New_Drive_Confirmation__c = FALSE;
            }
            if (newRecord.sked_Drive_Productivity_Planned__c != oldData.sked_Drive_Productivity_Planned__c) {
                if (newRecord.sked_Drive_Productivity_Planned__c != NULL) {
                    newRecord.sked_Drive_Productivity_Planned__c = newRecord.sked_Drive_Productivity_Planned__c.setScale(2);
                }
            }
        }
    }
    
    private void populateDriveName(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        List<sked_Drive__c> recordsToPopulate = new List<sked_Drive__c>();
        for (sked_Drive__c newRecord : newRecords) {
            sked_Drive__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Drive_Site__c != oldData.sked_Drive_Site__c || newRecord.sked_Account__c != oldData.sked_Account__c) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            populateDriveName(recordsToPopulate);
        }
    }
    
    private void populateDriveName(List<sked_Drive__c> newRecords) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> locationIds = new Set<Id>();
        
        for (sked_Drive__c newRecord : newRecords) {
            if (newRecord.sked_Account__c != NULL) {
                accountIds.add(newRecord.sked_Account__c);
            }
            if (newRecord.sked_Drive_Site__c != NULL) {
                locationIds.add(newRecord.sked_Drive_Site__c);
            }
        }
        
        Map<Id, sked__Location__c> mapLocation = new Map<Id, sked__Location__c>();
        if (!locationIds.isEmpty()) {
            mapLocation = new Map<Id, sked__Location__c>([SELECT Id, Name, sked_Zip_Code__c
                                                          FROM sked__Location__c
                                                          WHERE Id IN :locationIds]);
        }
        
        Map<Id, Account> mapAccount = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            mapAccount = new Map<Id, Account>([SELECT Id, Name
                                               FROM Account
                                               WHERE Id IN :accountIds]);
        }
        
        for (sked_Drive__c newRecord : newRecords) {
            string driveSiteName = '';
            string accountName = '';
            
            if (mapAccount.containsKey(newRecord.sked_Account__c)) {
                Account acc = mapAccount.get(newRecord.sked_Account__c);
                accountName = acc.Name;
            }
            if (mapLocation.containsKey(newRecord.sked_Drive_Site__c)) {
                sked__Location__c driveSite = mapLocation.get(newRecord.sked_Drive_Site__c);
                newRecord.sked_Zip_Code__c = driveSite.sked_Zip_Code__c;
                driveSiteName = driveSite.Name;
            }
            
            string driveName = accountName + ', ' + driveSiteName;
            driveName = driveName.length() > 80 ? driveName.substring(0, 75) + ' ...' : driveName;
            newRecord.Name = driveName;
        }
    }
    
    private void populateIdentifier(List<sked_Drive__c> newRecords) {
        List<UFIDGenerator.UFIDInfo> ufidInfos = new List<UFIDGenerator.UFIDInfo>();
        for (sked_Drive__c newRecord : newRecords) {
            UFIDGenerator.UFIDInfo ufidInfo = new UFIDGenerator.UFIDInfo();
            ufidInfo.prefix = 'D';
            ufidInfo.maxLength = 6;
            ufidInfo.value = integer.valueOf(newRecord.sked_UFID_AN__c);
            ufidInfo.recordId = newRecord.id;
            ufidInfo.fieldName = 'sked_UFID__c';
            ufidInfos.add(ufidInfo);
        }
        UFIDGenerator.genUFID(ufidInfos);
    }

    private void sendNotification(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        List<string> logisticsFields = new List<string>();
        logisticsFields.add('sked_Drive_Date__c');
        logisticsFields.add('sked_Start_Time__c');
        logisticsFields.add('sked_End_Time__c');
        logisticsFields.add('sked_Drive_Site__c');
        logisticsFields.add('sked_Projected_Registered_Donors__c');
        logisticsFields.add('sked_WB_Projected_Procedures__c');
        logisticsFields.add('sked_2RBC_Projected_Procedures__c');
        logisticsFields.add('sked_Platelet_Projected_Procedures__c');
        logisticsFields.add('sked_Plasma_Projected_Procedures__c');
        logisticsFields.add('sked_Number_of_2RBC_Assets__c');
        logisticsFields.add('sked_Number_of_Plasma_Assets__c');
        logisticsFields.add('sked_Number_of_Platelet_Assets__c');
        Set<Id> driveIdsLogisticChanges = new Set<Id>();
        
        Set<Id> driveIdsLinkedRemoval = new Set<Id>();
        for (sked_Drive__c newRecord : newRecords) {
			sked_Drive__c oldData = oldMap.get(newRecord.Id);
            for (string logisticsField : logisticsFields) {
                if (newRecord.get(logisticsField) != oldData.get(logisticsField)) {
                    driveIdsLogisticChanges.add(newRecord.Id);
                }
            }
        }
        if (!driveIdsLogisticChanges.isEmpty()) {
            sendLogisticChangesNotification(driveIdsLogisticChanges, newRecords, oldMap);
        }
    }

    private void processLinkedDriveRemoval(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        List<sked_Drive__c> drivesLinkedRemoval = new List<sked_Drive__c>();
        Set<Id> driveIdsLinkedRemovalToNotify = new Set<Id>();
        for (sked_Drive__c newRecord : newRecords) {
			sked_Drive__c oldData = oldMap.get(newRecord.Id);
            boolean isCancelled = newRecord.sked_Status__c != oldData.sked_Status__c && newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_CANCEL;
            boolean isChangedDate = newRecord.sked_Drive_Date__c != oldData.sked_Drive_Date__c;
            boolean hasRemoveFromLinkedDriveResolution = !String.isBlank(newRecord.sked_Contention_Resolution__c) && newRecord.sked_Contention_Resolution__c.contains('Remove from Linked Drive');
            if (isCancelled || isChangedDate || hasRemoveFromLinkedDriveResolution) {
                if (newRecord.sked_Linked_Drives__c != NULL) {
                    drivesLinkedRemoval.add(new sked_Drive__c(
                        Id = newRecord.Id,
                        sked_Linked_Drives__c = NULL,
                        sked_Contention_Resolution__c = hasRemoveFromLinkedDriveResolution ?
                            skedUtils.removeItemFromMultiPicklist(newRecord.sked_Contention_Resolution__c, 'Remove from Linked Drive') : newRecord.sked_Contention_Resolution__c
                    ));

                    if (!hasRemoveFromLinkedDriveResolution) {
                        driveIdsLinkedRemovalToNotify.add(newRecord.Id);
                    }
                }
            }
        }

        if (!drivesLinkedRemoval.isEmpty()) {
            update drivesLinkedRemoval;
        }

        if (!driveIdsLinkedRemovalToNotify.isEmpty()) {
            sendLinkedDriveRemovalNotification(driveIdsLinkedRemovalToNotify, newRecords, oldMap);
        }
    }

    public static void sendLogisticChangesNotification(Set<Id> recordIds, List<sObject> newRecords, Map<Id, sObject> oldMap) {
        List<string> settingNames = new List<string>();
        settingNames.add('sked_Logistic_Change_SF_Push');
        settingNames.add('sked_Logistic_Change_SF_Push_7Days');

        new skedCustomNotificationService(settingNames).generateNotifications(newRecords, oldMap);
    }
    
    public static void sendLinkedDriveRemovalNotification(Set<Id> recordIds, List<sObject> newRecords, Map<Id, sObject> oldMap) {
    	List<string> settingNames = new List<string>();
        settingNames.add('sked_Linked_Drive_Removal_Email');
        
        new skedCustomNotificationService(settingNames).generateNotifications(newRecords, oldMap);
	}
    
    private void submitDriveForApproval(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        Set<Id> driveIds = new Set<Id>();
        Map<Id, sked_Drive__c> mapNewRecord = new Map<Id, sked_Drive__c>(newRecords);
        for (sked_Drive__c newRecord : newRecords) {
            if (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_DRAFT) {
                sked_Drive__c oldData = oldMap.get(newRecord.Id);
                if (newRecord.sked_Approval_Status__c != oldData.sked_Approval_Status__c && newRecord.sked_Approval_Status__c == 'Submitted') {
                    if (newRecord.sked_Pending_Action__c != NULL && newRecord.sked_Pending_Action__c.contains('Drive Submission')) {
                        driveIds.add(newRecord.Id);
                    }
                }
            }
        }
        
        if (!driveIds.isEmpty()) {
            List<sked_Drive__c> skedDrives = [
                SELECT Id, sked_Linked_Drives__c, sked_Opportunity__c, sked_Account__c, 
                sked_Collection_Operation__r.Name, sked_Approval_Status__c, sked_Route_Approval_Request_To__c,
                sked_Designated_Approver__c
                FROM sked_Drive__c
                WHERE Id IN :driveIds
            ];
            Set<Id> accountIds = new Set<Id>();
            Set<string> queueNames = new Set<string>();
            
            for (sked_Drive__c skedDrive : skedDrives) {
                accountIds.add(skedDrive.sked_Account__c);
                queueNames.add(skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_PENDING_ACTIONS);
                queueNames.add(skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DM_PENDING_ACTIONS);
            }

            List<Group> approvalQueues = [
                SELECT Id, Name
                FROM Group
                WHERE Name IN :queueNames
                AND Type = :skedConstants.GROUP_TYPE_QUEUE
            ];
            Map<string, Group> mapQueueByName = new Map<string, Group>();
            for (Group approvalQueue : approvalQueues) {
                mapQueueByName.put(approvalQueue.Name, approvalQueue);
            }

            List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
            Map<Id, sked_Drive__c> drivesToUpdateById = new Map<Id, sked_Drive__c>();

            for (sked_Drive__c skedDrive : skedDrives) {
                sked_Drive__c newRecord = mapNewRecord.get(skedDrive.Id);
                Id submitterId = UserInfo.getUserId();
                
                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                request.setComments('Submitting request for Drive approval.');
                request.setObjectId(skedDrive.Id);
                request.setSubmitterId(submitterId);
    
                String approvalQueueName;
                if (newRecord.sked_Route_Approval_Request_To__c == 'Request DM evaluation')  {
                    request.setProcessDefinitionNameOrId('sked_DM_APS_Approval');
                    approvalQueueName = skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DM_PENDING_ACTIONS;

                    skedDrive.sked_Approval_Status__c = 'Waiting for DM Approval';
                }
                else if (newRecord.sked_Route_Approval_Request_To__c == 'Request APS exception') {
                    request.setProcessDefinitionNameOrId('sked_APS_Approval');
                    approvalQueueName = skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_PENDING_ACTIONS;
                    
                    skedDrive.sked_Approval_Status__c = 'Waiting for APS Approval';
                }      
    
                if (mapQueueByName.containsKey(approvalQueueName)) {
                    Group approvalQueue = mapQueueByName.get(approvalQueueName);
                    request.setNextApproverIds(new List<Id>{approvalQueue.Id});
                    requests.add(request);
                    
                    skedDrive.sked_Submitted_By__c = submitterId;
                    drivesToUpdateById.put(skedDrive.Id, skedDrive);
                }
                else {
                    if (!Test.isRunningTest()) {
                        newRecord.addError(approvalQueueName + ' does not exist.');
                    }
                }
            }
            skedDriveApprovalUtils.processDriveApprovals(requests, drivesToUpdateById);
            
            if (!drivesToUpdateById.isEmpty()) {
                update drivesToUpdateById.values();
            }
        }
    }
    
    private void submitDriveForCancelApproval(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        List<String> driveStatusesForApproval = new List<String>{skedConstants.DRIVE_STATUS_CONFIRMED, skedConstants.DRIVE_STATUS_TENTATIVE, skedConstants.DRIVE_STATUS_SYSTEM_GENERATED};
        Set<Id> driveIds = new Set<Id>();
        Map<Id, sked_Drive__c> mapNewRecord = new Map<Id, sked_Drive__c>(newRecords);
        for (sked_Drive__c newRecord : newRecords) {
            if (driveStatusesForApproval.contains(newRecord.sked_Status__c)) {
                sked_Drive__c oldData = oldMap.get(newRecord.Id);
                if (newRecord.sked_Approval_Status__c != oldData.sked_Approval_Status__c && newRecord.sked_Approval_Status__c == 'Submitted') {
                    if (newRecord.sked_Pending_Action__c != NULL && newRecord.sked_Pending_Action__c.contains('Cancel In Process')) {
                        driveIds.add(newRecord.Id);
                    }
                }
            }
        }

        if (!driveIds.isEmpty()) {
            lockAppointments(driveIds);

            //Remove all other pending approval request before submitting for cancellation
            slwcApprovalService.removeWorkItems(driveIds);
            
            List<sked_Drive__c> skedDrives = [
                SELECT Id, sked_Linked_Drives__c, sked_Opportunity__c, sked_Account__c, 
                sked_Collection_Operation__r.Name,
                sked_Approval_Status__c, sked_Route_Approval_Request_To__c
                FROM sked_Drive__c
                WHERE Id IN :driveIds
            ];
            
            Set<string> queueNames = new Set<string>();
            for (sked_Drive__c skedDrive : skedDrives) {
                queueNames.add(skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_PENDING_ACTIONS);
            }
            List<Group> approvalQueues = [
                SELECT Id, Name
                FROM Group
                WHERE Name IN :queueNames
                AND Type = :skedConstants.GROUP_TYPE_QUEUE
            ];
            Map<string, Group> mapQueueByName = new Map<string, Group>();
            for (Group approvalQueue : approvalQueues) {
                mapQueueByName.put(approvalQueue.Name, approvalQueue);
            }
            
            List<Approval.ProcessSubmitRequest> cancellationRequests = new List<Approval.ProcessSubmitRequest>();
            for (sked_Drive__c skedDrive : skedDrives) {
                Id submitterId = UserInfo.getUserId();
                string approvalQueueName = skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_PENDING_ACTIONS;
                if (mapQueueByName.containsKey(approvalQueueName)) {
                    cancellationRequests.add(getCancellationRequest(skedDrive, submitterId, mapQueueByName.get(approvalQueueName)));
                }

                skedDrive.sked_Approval_Status__c = 'Waiting for APS Approval';
                skedDrive.sked_Submitted_By__c = submitterId;
            }
            if (!cancellationRequests.isEmpty()) {
                Approval.process(cancellationRequests);
            }
            if (!skedDrives.isEmpty()) {
                update skedDrives;
            }
        }
    }

    private void lockAppointments(Set<Id> driveIds) {
        List<sked__Slot__c> slots = [SELECT Id, sked_Locked__c, sked_Is_Locked_By_System__c
                                     FROM sked__Slot__c
                                     WHERE sked_Drive__c IN :driveIds];
        if (!slots.isEmpty()) {
            List<sked__Slot__c> slotsToUpdate = new List<sked__Slot__c>();
            for (sked__Slot__c slot : slots) {
                if (slot.sked_Locked__c == FALSE) {
                    slot.sked_Locked__c = TRUE;
                    slot.sked_Is_Locked_By_System__c = TRUE;
                    slotsToUpdate.add(slot);
                }
            }
            if (!slotsToUpdate.isEmpty()) {
                update slotsToUpdate;
            }
        }
    }
    
    private void unlockAppointments(Set<Id> driveIds) {
        List<sked__Slot__c> slots = [SELECT Id, sked_Locked__c, sked_Is_Locked_By_System__c
                                     FROM sked__Slot__c
                                     WHERE sked_Drive__c IN :driveIds];
        if (!slots.isEmpty()) {
            List<sked__Slot__c> slotsToUpdate = new List<sked__Slot__c>();
            for (sked__Slot__c slot : slots) {
                if (slot.sked_Locked__c == TRUE && slot.sked_Is_Locked_By_System__c == TRUE) {
                    slot.sked_Locked__c = FALSE;
                    slot.sked_Is_Locked_By_System__c = FALSE;
                    slotsToUpdate.add(slot);
                }
            }
            if (!slotsToUpdate.isEmpty()) {
                update slotsToUpdate;
            }
        }
    }
    
    public void syncDriveFieldsToOpportunity(List<sked_Drive__c> newRecords) {
        List<Opportunity> oppList = new List<Opportunity>();
        for (sked_Drive__c newRecord : newRecords) {
            Opportunity oppRec = new Opportunity(
                Id = newRecord.sked_Opportunity__c,
                Drive_Status__c = newRecord.sked_Status__c,
                Is_Recursion_On__c = TRUE,
                Number_of_2RBC_Assets__c = newRecord.sked_Number_of_2RBC_Assets__c
            );
            oppList.add(oppRec);
        }
        if (!oppList.isEmpty()) {
            opportunityService.syncOppsWithDrives(oppList);
        }
    }
    
    private void revalidateAllocations(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        Set<Id> driveIdsToRevalidate = new Set<Id>();
        for (sked_Drive__c newRecord : newRecords) {
            sked_Drive__c oldData = oldMap.get(newRecord.Id);
            boolean isDriveDateChanged = newRecord.sked_Drive_Date__c != oldData.sked_Drive_Date__c;
            boolean isCOChanged = newRecord.sked_Collection_Operation__c != oldData.sked_Collection_Operation__c;
            boolean isLinkedDriveChanged = newRecord.sked_Linked_Drives__c != oldData.sked_Linked_Drives__c;
            
            boolean requiresRevalidate = isDriveDateChanged || isCOChanged || isLinkedDriveChanged;
            if (requiresRevalidate) {
                driveIdsToRevalidate.add(newRecord.Id);
            }
        }
        if (!driveIdsToRevalidate.isEmpty()) {
            Map<Id, sked__Job_Allocation__c> mapJobAllocation = new Map<Id, sked__Job_Allocation__c>([
                SELECT Id
                FROM sked__Job_Allocation__c
                WHERE sked__Job__r.sked_Drive__c IN :driveIdsToRevalidate
                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            ]);
            if (!mapJobAllocation.isEmpty()) {
                if (!System.isBatch() && !Test.isRunningTest()) {
                    skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
                    skedJobAllocationPostProcessBatch.schedule(batchSetting, mapJobAllocation.keyset(), 200, 0);
                    //Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, mapJobAllocation.keyset()), 200);
                }
            }
        }
    }
    
    private List<sked_Drive__c> filterDrives(List<sked_Drive__c> newRecords) {
        List<sked_Drive__c> result = new List<sked_Drive__c>();
        for (sked_Drive__c newRecord : newRecords) {
            if (newRecord.sked_Surrogate_Drive_for__c == NULL) {
                result.add(newRecord);
            }
        }
        return result;
    }

    private Approval.ProcessSubmitRequest getCancellationRequest(sked_Drive__c drive, Id submitterId, Group approvalQueue) {
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments('Submitting request for cancellation.');
        request.setObjectId(drive.Id);
        request.setSubmitterId(submitterId); 
        request.setProcessDefinitionNameOrId('sked_Drive_Cancellation_Approval');
        request.setNextApproverIds(new List<Id>{approvalQueue.Id});
        return request;
    }

    private void onStagingLocationChanged(List<sked_Drive__c> drives, Map<Id, sked_Drive__c> oldDrives) {
        Set<String> affectedGeoKeys = new Set<String>();
        List<sked_Drive__c> affectedDrives = new List<sked_Drive__c>();
        for (sked_Drive__c drive : drives) {
            sked_Drive__c oldDrive = oldDrives.get(drive.Id);
            if (drive.sked_Staging_Location__c != oldDrive.sked_Staging_Location__c && drive.sked_Geo_To_From_Key__c != oldDrive.sked_Geo_To_From_Key__c) {
                affectedGeoKeys.add(drive.sked_Geo_To_From_Key__c);
                affectedGeoKeys.add(drive.sked_Geo_From_To_Key__c);
                affectedGeoKeys.add(oldDrive.sked_Geo_To_From_Key__c);
                affectedGeoKeys.add(oldDrive.sked_Geo_From_To_Key__c);
                affectedDrives.add(drive);
            }
        }

        List<sked_Travel_Time_Index_Item__c> ttiis = [
            SELECT Id, sked_Key__c, sked_Average_Travel_Time__c
            FROM sked_Travel_Time_Index_Item__c
            WHERE sked_Key__c IN :affectedGeoKeys
        ];
        
        Map<String, sked_Travel_Time_Index_Item__c> ttiiByKey = new Map<String, sked_Travel_Time_Index_Item__c>();
        for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
            ttiiByKey.put(ttii.sked_Key__c, ttii);
        }

        List<sked_Drive__c> impactedDrives = new List<sked_Drive__c>();
        for (sked_Drive__c drive : affectedDrives) {
            sked_Drive__c oldDrive = oldDrives.get(drive.Id);

            sked_Travel_Time_Index_Item__c ttiiToFrom = ttiiByKey.get(drive.sked_Geo_To_From_Key__c);
            sked_Travel_Time_Index_Item__c oldTtiiToFrom = ttiiByKey.get(oldDrive.sked_Geo_To_From_Key__c);
            sked_Travel_Time_Index_Item__c ttiiFromTo = ttiiByKey.get(drive.sked_Geo_From_To_Key__c);
            sked_Travel_Time_Index_Item__c oldTtiiFromTo = ttiiByKey.get(oldDrive.sked_Geo_From_To_Key__c);

            Boolean isDriveImpacted = false;
            if (oldTtiiToFrom?.sked_Average_Travel_Time__c != null) {
                if (ttiiToFrom?.sked_Average_Travel_Time__c != null) {
                    decimal toFromGap = Math.abs(oldTtiiToFrom.sked_Average_Travel_Time__c - ttiiToFrom.sked_Average_Travel_Time__c);
                    if (toFromGap >= skedSetting.instance.TravelTime.driveImpactThreshold) {
                        isDriveImpacted = true;
                    }
                } else {
                    isDriveImpacted = true;
                }
            }

            if (oldTtiiFromTo?.sked_Average_Travel_Time__c != null) {
                if (ttiiFromTo?.sked_Average_Travel_Time__c != null) {
                    decimal fromToGap = Math.abs(oldTtiiFromTo.sked_Average_Travel_Time__c - ttiiFromTo.sked_Average_Travel_Time__c);
                    if (fromToGap >= skedSetting.instance.TravelTime.driveImpactThreshold) {
                        isDriveImpacted = true;
                    }
                } else {
                    isDriveImpacted = true;
                }
            }

            if (isDriveImpacted) {
                impactedDrives.add(drive);
            }
        }

        if (!impactedDrives.isEmpty()) {
            slwcDriveService.captureNonUserChangeDCRsModel request = new slwcDriveService.captureNonUserChangeDCRsModel();
            request.fieldLabel = 'Travel Time Changed';
            request.fieldApiName = 'sked_Travel_Time_Change__c';
            request.fieldType = 'Boolean';
            request.driveChangeRequestType = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_TRAVEL_TIME_CHANGE;
            request.impactedDrives = impactedDrives;
            
            slwcDriveService.skedCaptureNonUserChangeDCRs(request);
        }
    }

    private void handleLinkedDriveUpdates(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        Set<Id> linkedDrivesToUpdate = new Set<Id>();
        for (sked_Drive__c drive : newRecords) { 
            sked_Drive__c oldDrive = oldMap.get(drive.Id);
            if (drive.sked_Linked_Drives__c != null || oldDrive.sked_Linked_Drives__c != null) {
                Boolean driveDateChanged = drive.sked_Drive_Date__c != oldDrive.sked_Drive_Date__c;
                Boolean linkedDriveChanged = drive.sked_Linked_Drives__c != oldDrive.sked_Linked_Drives__c;

                if (drive.sked_Linked_Drives__c != null && (driveDateChanged || linkedDriveChanged)) {
                    linkedDrivesToUpdate.add(drive.sked_Linked_Drives__c);
                }

                if (oldDrive.sked_Linked_Drives__c != null) {
                    linkedDrivesToUpdate.add(oldDrive.sked_Linked_Drives__c);
                }
            }
        }

        if (!linkedDrivesToUpdate.isEmpty()) {
            skedFutureCallEventHandler.publishFutureCallEvent(
                'skedLinkedDrivesHandler',
                'updateLinkedDriveDetails',
                linkedDrivesToUpdate
            );
        }
    }
    
    private void doDateTimeConversion(List<sked_Drive__c> newRecords) {
        for (sked_Drive__c newRecord : newRecords) {
            skedDateTimeUtils.convertDateTimeToDateAndTime(newRecord, 'sked_Min_Shift_Start__c', 'sked_Min_Shift_Start_Date__c', 'sked_Min_Shift_Start_Time__c', 'sked_Timezone__c', NULL);
            skedDateTimeUtils.convertDateTimeToDateAndTime(newRecord, 'sked_Max_Shift_End__c', 'sked_Max_Shift_End_Date__c', 'sked_Max_Shift_End_Time__c', 'sked_Timezone__c', NULL);
        }
    }
    
    private void doDateTimeConversion(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap) {
        for (sked_Drive__c newRecord : newRecords) {
            sked_Drive__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Min_Shift_Start__c != oldData.sked_Min_Shift_Start__c) {
                skedDateTimeUtils.convertDateTimeToDateAndTime(newRecord, 'sked_Min_Shift_Start__c', 'sked_Min_Shift_Start_Date__c', 'sked_Min_Shift_Start_Time__c', 'sked_Timezone__c', NULL);
            }
            if (newRecord.sked_Max_Shift_End__c != oldData.sked_Max_Shift_End__c) {
                skedDateTimeUtils.convertDateTimeToDateAndTime(newRecord, 'sked_Max_Shift_End__c', 'sked_Max_Shift_End_Date__c', 'sked_Max_Shift_End_Time__c', 'sked_Timezone__c', NULL);
            }
        }
    }
    
    /*********************************************************** Nested Class ***********************************************************/
    public class UpdateEventDataModel {
        public string objectName;
        public List<Map<string, string>> objectFields;
    }
    
}