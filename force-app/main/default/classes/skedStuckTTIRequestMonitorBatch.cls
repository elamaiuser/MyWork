public class skedStuckTTIRequestMonitorBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    private List<Id> idsToResubmit;
    private Boolean foundStuckRecords;
    private Sked_TTIRR_Stuck_Job_Config__mdt config;

    public skedStuckTTIRequestMonitorBatch() {
        this.idsToResubmit = new List<Id>();
        this.foundStuckRecords = false;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('StuckTTIRequestMonitorBatch: Start method initiated.');
        this.config = Sked_TTIRR_Stuck_Job_Config__mdt.getInstance('Sked_TTIRR_Stuck_Job_Config');

        // Validate configuration
        if (config == null || !config.sked_Is_Active__c) {
            System.debug('StuckTTIRequestMonitorBatch: Configuration not found or inactive. Aborting.');
            // Returning null querylocator effectively stops the batch here
             String queryString = 'SELECT Id FROM sked_Travel_Time_Index_Refresh_Request__c WHERE Id = null LIMIT 1';
             return Database.getQueryLocator(queryString);
        }

        if (config.sked_Stuck_Threshold_Minutes__c == null || config.sked_Maximum_Retries__c == null || config.sked_Reschedule_Interval_Minutes__c == null) {
             System.debug('StuckTTIRequestMonitorBatch: Configuration fields (Threshold, Retries, Interval) cannot be null. Aborting.');
             String queryString = 'SELECT Id FROM sked_Travel_Time_Index_Refresh_Request__c WHERE Id = null LIMIT 1';
             return Database.getQueryLocator(queryString);
        }

        // Calculate the time threshold for stuck records
        DateTime thresholdTime = System.now().addMinutes(- (Integer)config.sked_Stuck_Threshold_Minutes__c);
        System.debug('StuckTTIRequestMonitorBatch: Threshold time calculated: ' + thresholdTime);

        // Query for potentially stuck records
        String queryString = 'SELECT Id, sked_Stuck_Retry_Count__c ' +
                             'FROM sked_Travel_Time_Index_Refresh_Request__c ' +
                             'WHERE sked_Status__c = \'In Progress\' ' +
                             'AND sked_Run_Id__c = null ' +
                             'AND LastModifiedDate <= :thresholdTime';

        System.debug('StuckTTIRequestMonitorBatch: Querying for stuck records with query: ' + queryString);
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext bc, List<sked_Travel_Time_Index_Refresh_Request__c> scope) {
        System.debug('StuckTTIRequestMonitorBatch: Execute method processing ' + scope.size() + ' records.');
        List<sked_Travel_Time_Index_Refresh_Request__c> recordsToUpdate = new List<sked_Travel_Time_Index_Refresh_Request__c>();
        List<Id> currentBatchIdsToResubmit = new List<Id>();

        // Ensure config is loaded (needed for Max_Retries__c)
        if (this.config == null) {
             System.debug('StuckTTIRequestMonitorBatch: Config is null in execute. Aborting chunk.');
             // This shouldn't happen if start logic is correct, but good safeguard
             return;
        }
        Integer maxRetries = (Integer)config.sked_Maximum_Retries__c;

        for (sked_Travel_Time_Index_Refresh_Request__c req : scope) {
            sked_Travel_Time_Index_Refresh_Request__c reqToUpdate = new sked_Travel_Time_Index_Refresh_Request__c(Id = req.Id);

            // Safely get and increment retry count
            Integer currentRetries = (req.sked_Stuck_Retry_Count__c == null) ? 0 : (Integer)req.sked_Stuck_Retry_Count__c;
            currentRetries++;

            reqToUpdate.sked_Stuck_Retry_Count__c = currentRetries;
            reqToUpdate.sked_Last_Stuck_Detection_Time__c = System.now(); // Mark when we processed it

            if (currentRetries > maxRetries) {
                // Exceeded max retries - Mark as Error
                System.debug('StuckTTIRequestMonitorBatch: Record ' + req.Id + ' exceeded max retries (' + maxRetries + '). Marking as Error.');
                reqToUpdate.sked_Status__c = 'Error';
                reqToUpdate.sked_Error_Message__c = 'Stuck TTI Request Monitor: Process failed after exceeding max retries (' + maxRetries +
                                              ') on ' + System.now().format() +
                                              '. Request remained in \'In Process\' without Run ID for too long. Potential invalid data or persistent processing issue.';
            } else {
                // Within retry limit - Reset to Pending and add to resubmit list
                 System.debug('StuckTTIRequestMonitorBatch: Record ' + req.Id + ' (Retry ' + currentRetries + ') reset to Pending for resubmission.');
                reqToUpdate.sked_Status__c = 'Pending';
                // Clear any previous error message that might be confusing
                reqToUpdate.sked_Error_Message__c = '';
                reqToUpdate.sked_Stuck_Retry_Count__c = currentRetries;
                reqToUpdate.sked_Last_Stuck_Detection_Time__c = System.now();
                currentBatchIdsToResubmit.add(req.Id);
            }
            recordsToUpdate.add(reqToUpdate);
        }

        if (!recordsToUpdate.isEmpty()) {
            System.debug('StuckTTIRequestMonitorBatch: Updating ' + recordsToUpdate.size() + ' records.');
            List<Database.SaveResult> saveResults = Database.update(recordsToUpdate, false); // Allow partial success

            // Log any update errors (optional but recommended)
            Integer successCount = 0;
            for(Database.SaveResult sr : saveResults) {
                if (sr.isSuccess()) {
                    successCount++;
                } else {
                    // Process errors
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('StuckTTIRequestMonitorBatch: Error updating record ID ' + sr.getId() +
                                     ' - Status Code: ' + err.getStatusCode() +
                                     ' - Message: ' + err.getMessage() +
                                     ' - Fields: ' + String.join(err.getFields(), ','));
                        // Potentially update the record again to log this specific DML error? Or log elsewhere.
                    }
                }
            }
             System.debug('StuckTTIRequestMonitorBatch: Successfully updated ' + successCount + ' records.');


            // Add successfully processed IDs for resubmission
            // Note: We add based on intent (currentBatchIdsToResubmit), assuming update worked or failure is logged.
            // If strictness is needed, only add IDs where sr.isSuccess() was true AND it was meant for resubmission.
            if(!currentBatchIdsToResubmit.isEmpty()){
                this.idsToResubmit.addAll(currentBatchIdsToResubmit);
                this.foundStuckRecords = true; // Mark that we processed records in this run
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('StuckTTIRequestMonitorBatch: Finish method initiated.');
        System.debug('StuckTTIRequestMonitorBatch: Records reset to Pending: ' + this.idsToResubmit.size() + '.');

        // Ensure config is available
         if (this.config == null) {
             System.debug('StuckTTIRequestMonitorBatch: Config is null in finish. Cannot proceed with resubmit or reschedule.');
             // Log this issue - potentially via Platform Event or custom logging framework
             return;
        }

        // 1. Enqueue the Queueable job to call the Skedulo handler
        if (this.idsToResubmit != null && !this.idsToResubmit.isEmpty()) {
            try {
                System.debug('StuckTTIRequestMonitorBatch: Enqueuing TTIRequestReprocessorQueueable for ' + this.idsToResubmit.size() + ' records.');
                System.enqueueJob(new skedTTIRequestReprocessorQueueable());
            } catch (Exception e) {
                System.debug('StuckTTIRequestMonitorBatch: CRITICAL - Failed to enqueue TTIRequestReprocessorQueueable. Error: ' + e.getMessage() + '\nStackTrace: ' + e.getStackTraceString());
                // Add robust logging/notification here (e.g., Platform Event, Email Alert to Admin)
            }
        }

        // 2. Check if self-rescheduling is needed and enabled
        if (this.foundStuckRecords && config.sked_Enable_Auto_Reschedule__c) {
            Integer rescheduleMinutes = (Integer)config.sked_Reschedule_Interval_Minutes__c;
             System.debug('StuckTTIRequestMonitorBatch: Stuck records were found and rescheduling is enabled. Scheduling next run in ' + rescheduleMinutes + ' minutes.');

             // Check if a rescheduled job is already pending (basic check, might need refinement)
             // This prevents rapidly rescheduling if the job finishes extremely quickly.
             List<CronTrigger> pendingJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'skedStuckTTIMonitor_Reschedule_%' AND State = 'WAITING'];
             if(pendingJobs.isEmpty()){
                try {
                    // Schedule the *same batch class* to run again after the interval
                    String jobName = 'skedStuckTTIMonitor_Reschedule_' + System.now().format('yyyyMMdd_HHmmssSSS');
                    System.scheduleBatch(new skedStuckTTIRequestMonitorBatch(), jobName, rescheduleMinutes);
                     System.debug('StuckTTIRequestMonitorBatch: Successfully scheduled next run with Job Name: ' + jobName);
                } catch (Exception e) {
                    System.debug('StuckTTIRequestMonitorBatch: ERROR - Failed to self-reschedule batch. Error: ' + e.getMessage() + '\nStackTrace: ' + e.getStackTraceString());
                    // Add robust logging/notification here
                }
             } else {
                  System.debug('StuckTTIRequestMonitorBatch: Rescheduled job already pending. Skipping duplicate schedule request.');
             }

        } else {
             System.debug('StuckTTIRequestMonitorBatch: No stuck records found or rescheduling disabled. No reschedule action taken.');
        }

        System.debug('StuckTTIRequestMonitorBatch: Finish method completed.');
         // Optional: Send summary email or log completion
    }
}