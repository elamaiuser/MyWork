public class skedNightlyTradeProcessBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public Integer successCount;
    public Integer failedCount;
    public Integer maxRecordSubmission;
    public String opRecordTechSupportEmail;

    public skedNightlyTradeProcessBatch() {
        slwcSetting.adminSetting adminSetting = new slwcSetting.adminSetting();
        this.successCount = 0;
        this.failedCount = 0;
        this.maxRecordSubmission = Integer.valueOf(adminSetting.maxRecordSubmissionToWDTimeBlocks);
        this.opRecordTechSupportEmail = adminSetting.opRecordTechSupportEmail;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, sked_Approver_Email__c, sked_Resource__c, sked_Resource__r.sked_Employee_Id__c,
            sked_Event_Date__c, sked_Event_Id__c, sked_Status__c, sked_Time_Entry_Code__c, sked_Quantity__c
            FROM sked_Trade_API_Data__c
            WHERE sked_Event_Date__c <= YESTERDAY
            AND sked_Status__c IN (:skedConstants.TRADE_API_DATA_STATUS_QUEUED, :skedConstants.TRADE_API_DATA_STATUS_FAILED)
            ORDER BY sked_Event_Date__c DESC
            LIMIT :maxRecordSubmission
        ]);
    }

    public void execute(Database.BatchableContext BC, List<sked_Trade_API_Data__c> tradeData) {
        List<skedWorkdayImportTimeBlockRequest> requests = new List<skedWorkdayImportTimeBlockRequest>();
        for (sked_Trade_API_Data__c trade : tradeData) {
            requests.add(new skedWorkdayImportTimeBlockRequest(
                trade.sked_Resource__c, 
                trade.sked_Resource__r.sked_Employee_Id__c, 
                trade.sked_Time_Entry_Code__c,
                trade.sked_Approver_Email__c,
                trade.sked_Quantity__c,
                trade.sked_Event_Date__c
            ));
        }

        skedWorkdayImportTimeBlockResponse response = skedWorkdayApiManager.ImportReportedTimeBlocks(requests);

        sked__Debug_Log__c debugLog = new sked__Debug_Log__c();
        debugLog.sked__Type__c = skedConstants.DEBUG_LOG_TYPE_WORKDAY_API;
        debugLog.sked__Summary__c = 'Import Reported Time Blocks';
        debugLog.sked_Request__c = 'See Attachment for more details';
        debugLog.sked_Response__c = response.response;
        debugLog.sked__Message__c = response.message;
        if (response.statusCode != 200) {
            debugLog.sked_Category__c = response.statusCode >= 500 ? skedConstants.DEBUG_LOG_CATEGORY_SYSTEM_ERROR : skedConstants.DEBUG_LOG_CATEGORY_VALIDATION_ERROR;
        }
        insert debugLog;
        
        Attachment requestAttachment = new Attachment();
        requestAttachment.contentType = 'text/plain';
        requestAttachment.name = 'request.txt';
        requestAttachment.parentId = debugLog.Id;
        requestAttachment.body = Blob.valueOf(response.request);
        insert requestAttachment;
        
        if (!response.isSuccess) {
            failedCount += tradeData.size();
            for (sked_Trade_API_Data__c trade : tradeData) {
                trade.sked_Status__c = skedConstants.TRADE_API_DATA_STATUS_FAILED;
            }
        } else {
            successCount += tradeData.size();
            for (sked_Trade_API_Data__c trade : tradeData) {
                trade.sked_Status__c = skedConstants.TRADE_API_DATA_STATUS_SENT;
            }
        }

        update tradeData;
    }

    public void finish(Database.BatchableContext BC) {
        String subject = 'Nightly Traded Shift/ Breaks Not Taken Submission Batch has Completed' + (failedCount > 0 ? ' with Errors' : '');
        String htmlBody = 'A nightly process submitting traded shifts/ breaks not taken to workday has completed. \n' +
        'Successful Requests: ' + successCount + '\n' +
        'Failed Requests: ' + failedCount + '\n\n' + 
        'In the result of any failures, please check the Debug Logs object for more information.';

        skedEmailService.emailModel emailModel = new skedEmailService.emailModel();
        emailModel.htmlBody = htmlBody;
        emailModel.subject = subject;
        emailModel.toList = new List<String>{opRecordTechSupportEmail};
        skedEmailService service = new skedEmailService();
        if (!Test.isRunningTest()) {
            service.sendEmails(new List<skedEmailService.emailModel>{emailModel});
        }
    }
}