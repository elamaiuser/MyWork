global with sharing class skedReprocessStuckTTIRequestBatch implements Database.Batchable<sObject>, Database.Stateful, System.Schedulable {
    
    private List<Id> idsToResubmit;
    private Boolean foundStuckRecords;

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedReprocessStuckTTIRequestBatch(), 200);
    }

    global skedReprocessStuckTTIRequestBatch() {
        this.idsToResubmit = new List<Id>();
        this.foundStuckRecords = false;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        DateTime thresholdTime = System.now().addMinutes(- Integer.valueOf(skedSetting.instance.stuckTTIRR.stuckThresholdMins));

        return Database.getQueryLocator([
            SELECT Id, sked_Run_Id__c, sked_Status__c, sked_Error_Message__c,
            sked_Stuck_Retry_Count__c, sked_Last_Stuck_Detection_Time__c
            FROM sked_Travel_Time_Index_Refresh_Request__c
            WHERE sked_Run_Id__c = NULL
            AND sked_Status__c = :skedConstants.TTIRR_STATUS_IN_PROGRESS
            AND LastModifiedDate <= :thresholdTime
        ]);
    }

    global void execute(Database.BatchableContext BC, List<sked_Travel_Time_Index_Refresh_Request__c> stuckTTIRequests) {
        Decimal maximumRetries = skedSetting.instance.stuckTTIRR.maxRetries;
        for(sked_Travel_Time_Index_Refresh_Request__c ttirr : stuckTTIRequests) {
            Decimal currentRetry = ttirr.sked_Stuck_Retry_Count__c != NULL ? ttirr.sked_Stuck_Retry_Count__c : 0;
            currentRetry++;
            if (currentRetry > maximumRetries) {
                ttirr.sked_Status__c = skedConstants.TTIRR_STATUS_ERROR;
                ttirr.sked_Error_Message__c = 'Request remained In Progress without RunId for too long. '+
                                              'Process failed after exceeding max retries. Potential invalid data.';
                ttirr.sked_Stuck_Retry_Count__c = maximumRetries;
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
        update stuckTTIRequests;
    }

    global void finish(Database.BatchableContext BC) {
        if(this.idsToResubmit != NULL && !this.idsToResubmit.isEmpty()) {
            if (!Test.isRunningTest()) {
                skedAsyncJobHandler.processTravelTimeRefreshRequest();
            }
        }

        List<String> jobPendingStatus = new List<String>{skedConstants.CRON_TRIGGER_WAITING, 
                                                        skedConstants.CRON_TRIGGER_ACQUIRED, 
                                                        skedConstants.CRON_TRIGGER_EXECUTING, 
                                                        skedConstants.CRON_TRIGGER_PAUSED};

        List<CronTrigger> pendingScheduledRun = [SELECT Id, CronJobDetailId, CronJobDetail.Name,
                                                  NextFireTime, CronExpression, State
                                                  FROM CronTrigger 
                                                  WHERE State IN :jobPendingStatus
                                                  AND CronJobDetail.Name = 'Reprocess Stuck TTIRR Records'
                                                  AND CronExpression = 'SimpleTrigger'];

        if((pendingScheduledRun == NULL || pendingScheduledRun.isEmpty()) && 
            this.foundStuckRecords && 
            skedSetting.instance.stuckTTIRR.enableAutoReschedule && 
            skedSetting.instance.stuckTTIRR.isActive
        ) {
            Decimal rescheduleIntervalMins = skedSetting.instance.stuckTTIRR.rescheduleIntervalMins;
            System.scheduleBatch(new skedReprocessStuckTTIRequestBatch(), 'Reprocess Stuck TTIRR Records', Integer.valueOf(rescheduleIntervalMins));
        }
    }
}