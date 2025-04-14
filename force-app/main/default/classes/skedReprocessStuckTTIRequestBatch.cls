global with sharing class skedReprocessStuckTTIRequestBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, System.Schedulable {
    
    private List<Id> idsToResubmit;
    private Boolean foundStuckRecords;
    private DateTime thresholdTime;
    private Decimal rescheduleIntervalMins;
    private skedSetting.skedTTIRRStuckJobConfigSetting stuckTTIRRJobSetting;

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedReprocessStuckTTIRequestBatch(), 200);
    }

    global skedReprocessStuckTTIRequestBatch() {
        this.idsToResubmit = new List<Id>();
        this.foundStuckRecords = false;

        this.stuckTTIRRJobSetting = new skedSetting.skedTTIRRStuckJobConfigSetting();
        this.thresholdTime = System.now().addMinutes(- Integer.valueOf(this.stuckTTIRRJobSetting.stuckThresholdMins));
        this.rescheduleIntervalMins = stuckTTIRRJobSetting.rescheduleIntervalMins;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, sked_Run_Id__c, sked_Status__c, sked_Error_Message__c,
            sked_Stuck_Retry_Count__c, sked_Last_Stuck_Detection_Time__c
            FROM sked_Travel_Time_Index_Refresh_Request__c
            WHERE sked_Run_Id__c = NULL
            AND sked_Status__c = :skedConstants.TTIRR_STATUS_IN_PROGRESS
            AND LastModifiedDate <= :this.thresholdTime
        ]);
    }

    global void execute(Database.BatchableContext BC, List<sked_Travel_Time_Index_Refresh_Request__c> stuckTTIRequests) {
        for(sked_Travel_Time_Index_Refresh_Request__c ttirr : stuckTTIRequests) {
            Decimal currentRetry = ttirr.sked_Stuck_Retry_Count__c != NULL ? ttirr.sked_Stuck_Retry_Count__c : 0;
            currentRetry++;
            if (currentRetry > this.stuckTTIRRJobSetting.maxRetries) {
                ttirr.sked_Status__c = skedConstants.TTIRR_STATUS_ERROR;
                ttirr.sked_Error_Message__c = 'Request remained In Progress without RunId for too long. '+
                                              'Process failed after exceeding max retries. Potential invalid data.';
                ttirr.sked_Stuck_Retry_Count__c = this.stuckTTIRRJobSetting.maxRetries;
            }
            else {
                ttirr.sked_Status__c = skedConstants.TTIRR_STATUS_PENDING;
                ttirr.sked_Error_Message__c = '';
                ttirr.sked_Stuck_Retry_Count__c = currentRetry;
                ttirr.sked_Last_Stuck_Detection_Time__c = System.now();
                this.idsToResubmit.add(ttirr.Id);
            }
        }
        if(this.idsToResubmit != NULL && !this.idsToResubmit.isEmpty()) this.foundStuckRecords = true;
        system.debug('stuckTTIRequests '+stuckTTIRequests);
        update stuckTTIRequests;
    }

    global void finish(Database.BatchableContext BC) {
        if(this.idsToResubmit != NULL && !this.idsToResubmit.isEmpty()) {
            if (!Test.isRunningTest()) {
                skedAsyncJobHandler.processTravelTimeRefreshRequest();
            }
        }

        List<AsyncApexJob> batchJobsProcessing = [SELECT Id
                                                  FROM AsyncApexJob 
                                                  WHERE ApexClass.Name = :skedReprocessStuckTTIRequestBatch.class.getName()
                                                  AND Status IN ('Holding','Queued','Preparing','Processing')
                                                  AND JobType IN ('BatchApex', 'ScheduledApex')];

        if((batchJobsProcessing == NULL || batchJobsProcessing.isEmpty()) && 
            this.foundStuckRecords && 
            this.stuckTTIRRJobSetting.enableAutoReschedule && 
            this.stuckTTIRRJobSetting.isActive
        ) {
            System.scheduleBatch(new skedReprocessStuckTTIRequestBatch(), 'Reprocess Stuck TTIRR Records', Integer.valueOf(this.stuckTTIRRJobSetting.rescheduleIntervalMins));
        }
    }
}