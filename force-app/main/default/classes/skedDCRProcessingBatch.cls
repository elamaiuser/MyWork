global class skedDCRProcessingBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    @TestVisible private Set<Id> travelTimeJaIds = new Set<Id>();
    @TestVisible private Integer processedCount = 0;
    @TestVisible private Integer appliedCount = 0;
    @TestVisible private Integer failedCount = 0;
    // Null means the full sweep; set means a caller named one specific DCR - see start().
    @TestVisible private Id targetDcrId;

    public skedDCRProcessingBatch() {
    }

    public skedDCRProcessingBatch(Id dcrId) {
        this.targetDcrId = dcrId;
    }

    /**
     * Starts a full sweep, unless one is already running - only ever one instance at a time. A
     * skipped run is not retried or deferred: this batch is long-running, so the next scheduled or
     * manual start is the right time to pick the work up, not some arbitrary delay from now.
     *
     * No enable/kill-switch check - per-DCR engine availability (checked inside
     * skedDCRApplyService.checkDcr) is the only gate.
     */
    public static void enqueue() {
        if (isBatchAlreadyRunning()) {
            return;
        }
        Database.executeBatch(new skedDCRProcessingBatch(), 1);
    }

    /**
     * Processes one named DCR, whatever its status and whatever its drive's date - unfiltered on
     * purpose, so re-applying an already-applied DCR is possible and is the caller's responsibility.
     * Runs the batch directly rather than deferring: it is called by hand, never from batch or
     * future context.
     */
    public static void enqueue(Id dcrId) {
        if (dcrId == null) {
            return;
        }
        // Only ever one instance of this batch at a time. This entry point is invoked by hand, so
        // it throws rather than returning quietly - a caller who asked for a specific DCR needs to
        // know it did not run.
        if (isBatchAlreadyRunning()) {
            throw new batchAlreadyRunningException(
                'skedDCRProcessingBatch is already running. Wait for it to finish, then retry this DCR.');
        }
        Database.executeBatch(new skedDCRProcessingBatch(dcrId), 1);
    }

    public class batchAlreadyRunningException extends Exception {}

    // Mirrors BSF_WorkdayBatchHelper.isBatchAlreadyRunning
    @TestVisible
    private static Boolean isBatchAlreadyRunning() {
        return [
            SELECT COUNT() FROM AsyncApexJob
            WHERE ApexClass.Name = 'skedDCRProcessingBatch'
            AND JobType = 'BatchApex'
            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ] > 0;
    }

    global void execute(SchedulableContext sc) {
        enqueue();
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (this.targetDcrId != null) {
            // Unfiltered on purpose: naming a DCR means "process this one", including the statuses
            // and past drive dates the sweep below skips. Re-processing an already-applied DCR is
            // therefore possible and is the caller's responsibility.
            Id dcrId = this.targetDcrId;
            return Database.getQueryLocator([
                SELECT Id, sked_Drive__r.sked_Type_of_Drive__c, sked_Drive__r.sked_Operation_Type__c, sked_Status__c
                FROM sked_Drive_Change_Request__c
                WHERE Id = :dcrId
            ]);
        }

        // Every drive type and every DCR type, including User Change. Nothing enqueues this run off
        // the DCR trigger any more - it is started deliberately - so it no longer competes with
        // users editing drives.
        // Pending is the only status collected: every other status is either terminal or waiting
        // on a human. Drives in the past are skipped, and the soonest drive is processed first so
        // the most time-critical work still lands if a run is cut short; CreatedDate keeps the
        // order deterministic within a single drive date. An unshipped engine for a given drive
        // type is discovered per-record inside process().
        return Database.getQueryLocator([
            SELECT Id, sked_Drive__r.sked_Type_of_Drive__c, sked_Drive__r.sked_Operation_Type__c, sked_Status__c
            FROM sked_Drive_Change_Request__c
            WHERE sked_Status__c = :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING
            AND sked_Drive__r.sked_Drive_Date__c >= TODAY
            ORDER BY sked_Drive__r.sked_Drive_Date__c ASC, CreatedDate ASC
        ]);
    }

    global void execute(Database.BatchableContext bc, List<sked_Drive_Change_Request__c> scope) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        sked_Drive_Change_Request__c dcr = scope.get(0);
        Boolean isApprovedDcr = dcr.sked_Status__c == skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED;

        Savepoint sp = Database.setSavepoint();
        // Written after the savepoint so any rollback below reverts it back to Pending/Approved for free.
        update new sked_Drive_Change_Request__c(
            Id = dcr.Id, sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_IN_PROCESS);

        skedDCRApplyService.applyResult result;
        // True once a terminal status (Submitted / Approved by System / Cancelled / restored
        // Approved) has already been written by process()/processApproved() or the catch block
        // below - false means updateBookkeeping must move the DCR to Error itself: this pipeline
        // is end-to-end or nothing, a failure here can't self-heal, so it comes out of the queue
        // rather than being retried forever.
        Boolean statusAlreadyResolved = false;
        Exception caughtException = null;
        try {
            result = isApprovedDcr
                ? new skedDCRApplyService().processApproved(dcr.Id)
                : new skedDCRApplyService().process(dcr.Id);
            this.travelTimeJaIds.addAll(result.travelTimeJobAllocationIds);
            statusAlreadyResolved = result.applied;
            if (isApprovedDcr && result.applied) {
                // processApproved() never touches DCR status itself - restore it from the
                // IN_PROCESS write above now that the apply succeeded, rather than leaving it
                // stuck mid-processing.
                update new sked_Drive_Change_Request__c(
                    Id = dcr.Id, sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED);
            }
        } catch (Exception ex) {
            Database.rollback(sp);
            caughtException = ex;
            // Save-phase failures cancel the DCR AFTER rollback, so the cancellation write
            // survives (the trigger interprets Cancelled as "undo" and reverts the Opportunity).
            if (ex instanceof skedDCRApplyService.saveFailureException) {
                update new sked_Drive_Change_Request__c(
                    Id = dcr.Id, sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED);
                statusAlreadyResolved = true;
            }
            result = new skedDCRApplyService.applyResult();
            result.resultMessage = ex.getMessage();
        }
        this.processedCount++;
        if (result.applied) {
            this.appliedCount++;
        } else {
            this.failedCount++;
        }
        updateBookkeeping(dcr.Id, result, statusAlreadyResolved, caughtException);
    }

    global void finish(Database.BatchableContext bc) {
        // Run summary for monitoring
        insert BSF_Utilities.getErrorLog(null, 'skedDCRProcessingBatch', 'finish', 'Success', null,
            'Processed: ' + this.processedCount
            + ', Applied: ' + this.appliedCount
            + ', Failed: ' + this.failedCount);

        if (!this.travelTimeJaIds.isEmpty()) {
            List<sked__Job_Allocation__c> jasToReset = new List<sked__Job_Allocation__c>();
            for (Id jaId : this.travelTimeJaIds) {
                jasToReset.add(new sked__Job_Allocation__c(
                    Id = jaId, sked_Travel_Time_To__c = null, sked_Travel_Time_Back__c = null));
            }
            // Travel batch's start() only picks allocations with NULL travel times - reset to force recompute
            update jasToReset;
            Database.executeBatch(new skedJobAllocationTravelTimeBatch(this.travelTimeJaIds), 100);
        }
    }

    private void updateBookkeeping(Id dcrId, skedDCRApplyService.applyResult result, Boolean statusAlreadyResolved, Exception caughtException) {
        sked_Drive_Change_Request__c dcrUpdate = new sked_Drive_Change_Request__c(
            Id = dcrId,
            sked_Last_Processing_Result__c = result.resultMessage
        );
        if (!statusAlreadyResolved) {
            dcrUpdate.sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_ERROR;
            if (caughtException != null) {
                insert BSF_Utilities.createBsfErrorLogForExceptions(
                    caughtException, 'skedDCRProcessingBatch', 'execute', 'DCR Batch Processing',
                    'HRP-10153', 'sked_Drive_Change_Request__c', dcrId);
            } else {
                BSF_Error_Log__c errorLog = BSF_Utilities.createBsfErrorLogwithoutExceptions(
                    'skedDCRProcessingBatch', 'execute', 'DCR Batch Processing',
                    'sked_Drive_Change_Request__c', result.resultMessage);
                errorLog.Object_RecordId__c = dcrId;
                insert errorLog;
            }
        }
        update dcrUpdate;
    }
}
