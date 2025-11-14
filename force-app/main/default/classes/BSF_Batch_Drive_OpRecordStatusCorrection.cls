/*
@Description: 
	1. This batch will first pickup all the op records with drive date equals to (Today - 18 Days --> Configurable)
	2. It then performs few checks to get the list of all non-submitted op records and non-completed/non-cancelled drives
	3. It tries to update status for both of them and captures errors (if any)
	4. It then captures Calendar Build Log and calendar Build Error Log from the finish method
 
@Modification Log 
* Date					     Developer Name			     Comments
***************************************************************************
* 08/13/2024				  Ankit Kundu		     Created for HRP-13126
***************************************************************************/

global class BSF_Batch_Drive_OpRecordStatusCorrection implements Database.Batchable<sked_Operation_Record__c>, Database.Stateful, Schedulable {
    
    private Date targetDriveDate;
    private Integer batchSize;
    private DriveGenerationUtil.CalendarBuildLogWrapper cbLogWrapper;
    private List<sked_Operation_Record__c> nonSubmittedOpRecordList = new List<sked_Operation_Record__c>();
    private String runType = '';
    private Date driveDateToEval;
    private Set<Id> openDriveIds = new Set<Id>();
    private Set<Id> correctedDriveIds = new Set<Id>();
    private Set<Id> totalDriveIds = new Set<Id>();
    private Set<Id> submittedOpRecordIds = new Set<Id>();
    private Set<Id> errorLogIdsCreatedDuringBatchRun = new Set<Id>();

    // define constructor for Scheduled Run
    global BSF_Batch_Drive_OpRecordStatusCorrection() {
        try {
            Calendar_Build_Setting__mdt cbMetadata = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
            Integer numberOfDays = Integer.valueOf(cbMetadata?.No_of_Days_for_Status_Correction_Batch__c);
            batchSize = Integer.valueOf(cbMetadata?.Batch_Size_for_Status_Correction_Batch__c);
            if (numberOfDays != NULL) {
                targetDriveDate = system.today().addDays(-numberOfDays);
            } else {
                targetDriveDate = system.today().addDays(-18);
            }
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(targetDriveDate, BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION, BSF_Constants.RUN_TYPE_SCHEDULED);
            cbLogWrapper = getOpRecordListAndCaptureWrapper(cbLogWrapper); 
            if(Test.isRunningTest() && BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION) {
                throw new customStatusCorrectionException('This is custom exception during scheduled run');
            }
        } catch(Exception ex) {
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                BSF_Constants.CURRENT_DATE.addDays(-21), 
                BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION, 
                BSF_Constants.RUN_TYPE_SCHEDULED
            );
            cbLogWrapper.apexMethodName = 'Constructor Call for Scheduled Run';
            cbLogWrapper.eligibleOpportunityForCbList = new List<Opportunity>();
            DriveGenerationUtil.captureErrorLoggingForException(ex, cbLogWrapper);           
        }
    }

    // define constructor for Manual Run
    global BSF_Batch_Drive_OpRecordStatusCorrection(Date manualRunDate) {
        try {
            this.driveDateToEval = manualRunDate;
            this.runType = BSF_Constants.RUN_TYPE_MANUAL;
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(manualRunDate, BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION, BSF_Constants.RUN_TYPE_MANUAL);
            cbLogWrapper = getOpRecordListAndCaptureWrapper(cbLogWrapper);
            if(Test.isRunningTest() && BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION) {
                throw new customStatusCorrectionException('This is custom exception during manual run');
            }
        } catch(Exception ex) {
            List<BSF_Error_Log__c> errorLogToInsert = new List<BSF_Error_Log__c>{
                BSF_Utilities.createBsfErrorLogForExceptions(
                    ex,
                    'BSF_Batch_Drive_OpRecordStatusCorrection',
                    'Constructor Call',
                    BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION,
                    BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION,
                    'sked_Operation_Record__c',
                    ''
                )
            };
            Database.SaveResult[] logInsertResult = Database.insert(errorLogToInsert, FALSE);
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                manualRunDate, 
                BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION, 
                this.runType
            );
        
            cbLogWrapper.batchException = ex;
            cbLogWrapper.opRecordListToBeProcessed = new List<sked_Operation_Record__c>();
            cbLogWrapper.errorLogIdsCreatedDuringBatchRun = BSF_Utilities.getSuccessfullySavedRecordIds(logInsertResult);
            DriveGenerationUtil.captureCbLogAndCbErrorLog(cbLogWrapper);
        }     
    }
 
    global Iterable<sked_Operation_Record__c> start(Database.BatchableContext bc) {
        return cbLogWrapper.opRecordListToBeProcessed;
    }

    global void execute(SchedulableContext scon) {
        Database.executeBatch(new BSF_Batch_Drive_OpRecordStatusCorrection(), batchSize);
    }

    global void execute(Database.BatchableContext BC, List<sked_Operation_Record__c> opRecordList) { 
    
        Map<Id, sked_Operation_Record__c> map_opRecordId_opRecordFinalListToBeSubmitted = new Map<Id, sked_Operation_Record__c>();
        Map<Id, sked_Drive__c> map_driveId_driveToBeUpdated = new Map<Id, sked_Drive__c>();
        Map<Id, sked_Drive__c> map_driveId_openDrives = new Map<Id, sked_Drive__c>();
        List<BSF_Error_Log__c> bsfErrorLogList = new List<BSF_Error_Log__c>();

        for (sked_Operation_Record__c opRecord : opRecordList) {
            if(opRecord.sked_Status__c != BSF_Constants.OPRECORD_STATUS_SUBMITTED) {
                opRecord.sked_Status__c = BSF_Constants.OPRECORD_STATUS_SUBMITTED;  
                map_opRecordId_opRecordFinalListToBeSubmitted.put(opRecord.Id, opRecord);
            }
            if(opRecord.sked_Drive__r.sked_Status__c != BSF_Constants.DOC_STATUS_COMPLETE && opRecord.sked_Drive__r.sked_Status__c != BSF_Constants.DOC_STATUS_CANCEL) {
                map_driveId_driveToBeUpdated.put(opRecord.sked_Drive__c, new sked_Drive__c(Id = opRecord.sked_Drive__c, sked_Status__c = BSF_Constants.DOC_STATUS_COMPLETE));
            }
            totalDriveIds.add(opRecord.sked_Drive__c);
        }

        nonSubmittedOpRecordList.addAll(map_opRecordId_opRecordFinalListToBeSubmitted.values());
        openDriveIds.addAll(map_driveId_driveToBeUpdated.keySet());
        
        // Update operation Status
        database.saveResult[] opRecordUpdateResultList = Database.update(nonSubmittedOpRecordList, false);       
        submittedOpRecordIds.addAll(BSF_Utilities.getSuccessfullySavedRecordIds(opRecordUpdateResultList));
        
        // Insert error log
        List<BSF_Error_Log__c> logListForOpRecordStatusUpdate = BSF_Utilities.createErrorLogWithObjectId(
            opRecordUpdateResultList, 
            BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION,
            'BSF_Batch_Drive_OpRecordStatusCorrection',
            'execute',
            'Error',
            'OpRecord Status Update Error'
        );
        bsfErrorLogList.addAll(logListForOpRecordStatusUpdate);
        
        // update drive status
        Database.saveResult[] drivesUpdateResultList = Database.update(map_driveId_driveToBeUpdated.values(), false);
        
        correctedDriveIds.addAll(BSF_Utilities.getSuccessfullySavedRecordIds(drivesUpdateResultList));
        
        // Insert error log
        List<BSF_Error_Log__c> logListForDriveStatusUpdate = BSF_Utilities.createErrorLogWithObjectId(
            drivesUpdateResultList, 
            BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION,
            'BSF_Batch_Drive_OpRecordStatusCorrection',
            'execute',
            'Error',
            'Error in Drive Status update to Complete'
        );
        bsfErrorLogList.addAll(logListForDriveStatusUpdate);
        Database.SaveResult[] logResultList = Database.Insert(bsfErrorLogList, false);
        errorLogIdsCreatedDuringBatchRun.addAll(BSF_Utilities.getSuccessfullySavedRecordIds(logResultList));   
    }

    global void finish(Database.BatchableContext BC) {
        try {
            if(cbLogWrapper.batchException == NULL) {
                cbLogWrapper.opRecordCount = (Decimal)cbLogWrapper.opRecordListToBeProcessed.size(); // total op record count 
                cbLogWrapper.driveCount = totalDriveIds != NULL ? (Decimal)totalDriveIds.size() : 0; // total drive count
                cbLogWrapper.openDriveCount = openDriveIds != NULL ? (Decimal)openDriveIds.size() : 0; // total open drive count
                cbLogWrapper.finalStateDriveCount = cbLogWrapper.driveCount - cbLogWrapper.openDriveCount; // total final state drive count
                cbLogWrapper.correctedDriveCount = correctedDriveIds != NULL ? (Decimal)correctedDriveIds.size() : 0; // total corrected drive count via batch
                cbLogWrapper.submittedOpRecordCount = submittedOpRecordIds != NULL ? (Decimal)submittedOpRecordIds.size() : 0; // total submitted ops record count via batch
                cbLogWrapper.notSubmittedOpRecordCount = nonSubmittedOpRecordList.size() > 0 ? ((Decimal)nonSubmittedOpRecordList.size() - cbLogWrapper.submittedOpRecordCount) : 0; // total non submitted ops record after batch completion
                cbLogWrapper.errorLogIdsCreatedDuringBatchRun = errorLogIdsCreatedDuringBatchRun != NULL ? errorLogIdsCreatedDuringBatchRun : new Set<Id>(); // error log ids created via batch
                DriveGenerationUtil.captureCbLogAndCbErrorLog(cbLogWrapper);  
            }
        } catch(Exception ex) {
            List<BSF_Error_Log__c> errorLogToInsert = new List<BSF_Error_Log__c>{
                BSF_Utilities.createBsfErrorLogForExceptions(
                    ex,
                    'BSF_Batch_Drive_OpRecordStatusCorrection',
                    'Constructor Call',
                    BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION,
                    BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION,
                    'sked_Operation_Record__c',
                    ''
                )
            };
            Database.SaveResult[] logInsertResult = Database.insert(errorLogToInsert, FALSE);
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                this.driveDateToEval,
                BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION, 
                this.runType
            );
            
            cbLogWrapper.batchException = ex;
            cbLogWrapper.errorLogIdsCreatedDuringBatchRun = BSF_Utilities.getSuccessfullySavedRecordIds(logInsertResult);
            DriveGenerationUtil.captureCbLogAndCbErrorLog(cbLogWrapper);
        }
        Database.executeBatch(new BSF_Batch_DriveStatusCorrection(),50);
    }

    private static DriveGenerationUtil.CalendarBuildLogWrapper getOpRecordListAndCaptureWrapper(DriveGenerationUtil.CalendarBuildLogWrapper cbLogWrapper ) {

        cbLogWrapper.opRecordListToBeProcessed = new List<sked_Operation_Record__c>([SELECT id,
                                                                                        sked_Drive__c,
                                                                                        sked_Drive__r.sked_Status__c,
                                                                                        sked_Status__c,
                                                                                        sked_Drive_ID__c,
                                                                                        sked_Drive_Date__c
                                                                                        FROM sked_Operation_Record__c
                                                                                        WHERE sked_Drive_Date__c = :cbLogWrapper.driveDateToEval
                                                                                    ]);
        return cbLogWrapper;
    }

    private class customStatusCorrectionException extends Exception {}
}