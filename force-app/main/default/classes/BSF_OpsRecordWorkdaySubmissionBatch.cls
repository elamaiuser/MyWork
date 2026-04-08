/**
 * Daily batch: picks up  Draft/Partial ops records, calls Employee Report API,
 * builds base + premium time blocks, submits to Workday, updates status and sends emails.
 *  Schedule via Execute Anonymous or Setup at 3 AM EST (Assume running user is set to EST/EDT):
 * // System.schedule('Ops Record Workday Submission', '0 0 3 * * ?', new BSF_OpsRecordWorkdaySubmissionBatch());
 */
public class BSF_OpsRecordWorkdaySubmissionBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {
    private Integer maxRetryAttempts;
    private String employeeReportUrl;
    private String driveStartDateParamName;
    private String driveEndDateParamName;
    private String employeeIdsParamName;
    private String technicalTeamDistributionList;
    private String notificationFromEmail;
    private String businessDistributionList;
    private List<String> errorsForTechEmail = new List<String>();
    /** Number of drives successfully submitted to Workday across all execute() calls (for single success email in finish). */
    private Integer totalDrivesProcessedSuccessfully = 0;
    /** True if any execute() hit Import failure (markOpRecordsFailed). Used in finish() to reschedule only when staff attempts were incremented, so reschedules will stop when all staff reach max attempts for the day. */
    private Boolean hadImportFailure = false;
    // Cache Employee Report results per drive date across execute() calls to avoid duplicate callouts for employees with time in Workday.
    private Map<Date, BSF_WorkdayOpsRecordDirectService.EmployeeReportResult> employeeReportCache = new Map<Date, BSF_WorkdayOpsRecordDirectService.EmployeeReportResult>();

    public BSF_OpsRecordWorkdaySubmissionBatch() {
        BSF_Workday_Direct_Submission_Config__mdt config = BSF_WorkdayDirectSubmissionConfig.getConfig();
        maxRetryAttempts = BSF_WorkdayDirectSubmissionConfig.getMaxRetryAttempts();
        if (config != null) {
            employeeReportUrl = config.sked_WD_Emp_Rpt_URL__c;
            driveStartDateParamName = config.sked_WD_Start_Date_Param__c;
            driveEndDateParamName = config.sked_WD_End_Date_Param__c;
            employeeIdsParamName = config.sked_WD_Worker_Param__c;
            technicalTeamDistributionList = config.sked_Technical_Team_Distribution_List__c;
            notificationFromEmail = config.sked_Notification_From_Email__c;
            businessDistributionList = config.sked_Business_Distribution_List__c;
        }
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BSF_OpsRecordWorkdaySubmissionBatch(), BSF_WorkdayDirectSubmissionConfig.getBatchScopeSize());
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // - Exclude anything created today.
        // - Include any eligible record created before today (i.e., yesterday and earlier).
        Date today = Date.today();
        DateTime todayStart = DateTime.newInstance(today.year(), today.month(), today.day(), 0, 0, 0);

        return Database.getQueryLocator([
            SELECT Id, CreatedDate, sked_Workday_Submission_Status__c, sked_Drive__c,
                sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Type_of_Drive__c,
                sked_Submitted_By__r.sked__Email__c
            FROM sked_Operation_Record__c
            WHERE sked_Workday_Submission_Status__c IN ('Draft', 'Failed')
            AND sked_Drive__c != null
            AND sked_Locked__c = true
            AND CreatedDate < :todayStart
        ]);
    }

    public void execute(Database.BatchableContext bc, List<sked_Operation_Record__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        Set<Id> opRecordIds = new Set<Id>();
        for (sked_Operation_Record__c op : scope) {
            opRecordIds.add(op.Id);
        }
        List<sked_Operation_Record__c> opRecordsWithStaff = skedOperationRecordUtils.getOpsRecords(opRecordIds);
        if (opRecordsWithStaff.isEmpty()) {
            return;
        }
        Date today = Date.today();
        List<sked_Operation_Record__c> toProcess = new List<sked_Operation_Record__c>();
        for (sked_Operation_Record__c op : opRecordsWithStaff) {
            Boolean isRetry = op.sked_Workday_Submission_Status__c == BSF_WorkdayDirectSubmissionConfig.STATUS_FAILED;
            if (!isRetry) {
                // Draft (first-time submissions) – always process
                toProcess.add(op);
                continue;
            }
            // Failed: allow up to maxRetryAttempts attempts per day, resetting count when the date changes.
            Integer attemptsToday = 0;
            if (op.sked_WD_Last_Submission_Date__c == today && op.sked_Workday_Submission_Attempt__c != null) {
                attemptsToday = Integer.valueOf(op.sked_Workday_Submission_Attempt__c);
            }
            if (attemptsToday < maxRetryAttempts) {
                toProcess.add(op);
            }
        }
        if (toProcess.isEmpty()) {
            return;
        }
        Map<Date, List<OpRecordContext>> byDriveDate = groupByDriveDate(toProcess);
        List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> allBlocks = new List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType>();
        List<Map<String, String>> allDateTimeFormats = new List<Map<String, String>>();
        // Track which employees did NOT have time in Workday per drive date (from the first Employee Report call),
        Set<String> employeesWithoutTimeByDrive = new Set<String>();
        // Collect Employee Report request/response per drive date for logging (after all callouts).
        List<BSF_WorkdayOpsRecordDirectService.EmployeeReportResult> employeeReportLogs = new List<BSF_WorkdayOpsRecordDirectService.EmployeeReportResult>();
        Boolean employeeReportError = false;
        String employeeReportErrorSummary;

        for (Date driveDate : byDriveDate.keySet()) {
            List<OpRecordContext> contexts = byDriveDate.get(driveDate);
            Set<String> allEmployeeIds = new Set<String>();
            List<BSF_OpsRecordToTimeBlockMapper.StaffWithTimes> staffWithTimesList = new List<BSF_OpsRecordToTimeBlockMapper.StaffWithTimes>();
            List<skedOpsRecordApiData.opsRecordStaffDetail> allStaffDetails = new List<skedOpsRecordApiData.opsRecordStaffDetail>();
            Map<String, String> staffIdToGuid = new Map<String, String>();
            String approverEmail = '';
            for (OpRecordContext ctx : contexts) {
                approverEmail = ctx.approverEmail;
                skedOpsRecordApiData.opsRecordRequest req = skedOperationRecordUtils.getOpsRecordRequest(ctx.opRecord);
                if (req == null || req.StaffDetails == null) {
                    continue;
                }
                List<sked_Operation_Record_Staff__c> staffList = ctx.staffList;
                for (Integer i = 0; i < req.StaffDetails.size(); i++) {
                    skedOpsRecordApiData.opsRecordStaffDetail sd = req.StaffDetails[i];
                    String empId = String.valueOf(sd.personID);
                    if (empId == null || empId == '0' || sd.notWorked) {
                        continue;
                    }
                    
                    allEmployeeIds.add(empId);
                    
                    sked_Operation_Record_Staff__c staffRec = i < staffList.size() ? staffList[i] : null;
                    if (staffRec == null) {
                        continue;
                    }
                    if (ctx.isRetry && staffRec.sked_Workday_Submission_Status__c == BSF_WorkdayDirectSubmissionConfig.STAFF_STATUS_SUCCESS) {
                        // On retry, skip staff already marked Success.
                        continue;
                    }
                    BSF_OpsRecordToTimeBlockMapper.StaffWithTimes st = new BSF_OpsRecordToTimeBlockMapper.StaffWithTimes();
                    st.detail = sd;
                    st.shiftStartGmt = staffRec.sked_Actual_Shift_Start__c;
                    st.shiftEndGmt = staffRec.sked_Actual_Shift_End__c;
                    st.staffRecordId = staffRec.Id;
                    staffWithTimesList.add(st);
                    allStaffDetails.add(sd);
                    staffIdToGuid.put(empId, staffRec.Id);
                }
            }
            if (allEmployeeIds.isEmpty()) {
                continue;
            }
            // Call Employee Report once per drive date per batch run; reuse cached result across execute() calls.
            BSF_WorkdayOpsRecordDirectService.EmployeeReportResult empResult;
            if (employeeReportCache.containsKey(driveDate)) {
                empResult = employeeReportCache.get(driveDate);
            } else {
                empResult = BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkdayWithLog(
                    employeeReportUrl, driveStartDateParamName, driveEndDateParamName, employeeIdsParamName, new List<String>(allEmployeeIds), driveDate
                );
                employeeReportCache.put(driveDate, empResult);
                employeeReportLogs.add(empResult);
            }
            if (empResult == null || empResult.statusCode != 200) {
                employeeReportError = true;
                employeeReportErrorSummary = 'Employee Report call failed for driveDate=' + driveDate + '; StatusCode=' + (empResult != null ? String.valueOf(empResult.statusCode) : 'null');
                break;
            }
            Map<String, String> employeeIdToTimezone = empResult.employeeIdToTimezone;
            Set<String> needBase = new Set<String>(employeeIdToTimezone.keySet());
            // Remember which employees had no time in Workday for this drive date
            for (String eid : needBase) {
                employeesWithoutTimeByDrive.add(String.valueOf(driveDate) + '_' + eid);
            }
            BSF_OpsRecordToTimeBlockMapper.BaseTimeBlockResult baseResult = BSF_OpsRecordToTimeBlockMapper.buildBaseTimeBlocks(
                staffWithTimesList, needBase, employeeIdToTimezone, approverEmail, driveDate
            );
            // Premium blocks per drive: one staff detail per op record, so e.g. Charge on one shift and Translator on another = 2 blocks.
            List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> premiumBlocks = BSF_OpsRecordToTimeBlockMapper.buildPremiumTimeBlocks(
                allStaffDetails, driveDate, approverEmail, staffIdToGuid
            );
            allBlocks.addAll(baseResult.blocks);
            allBlocks.addAll(premiumBlocks);
            allDateTimeFormats.addAll(baseResult.dateTimeFormats);
        }

        if (employeeReportError) {
            errorsForTechEmail.add(employeeReportErrorSummary);
            // Treat Employee Report failures as technical failures for retry/attempt purposes.
            // We do NOT call Import when Employee Report fails.
            markOpRecordsFailed(toProcess);
            // Log Employee Report request/response even when we skip the Import call.
            logEmployeeReportCalls(employeeReportLogs);
            return;
        }

        if (allBlocks.isEmpty()) {
            // Nothing to send to Workday. At this point, either:
            // - Employee Report indicates staff already have time in Workday, and/or
            // - There are no premiums to submit.
            // Treat these op records as successfully processed to avoid picking them up on future runs.
            markOpRecordsProcessed(toProcess, byDriveDate, employeesWithoutTimeByDrive, null);
            return;
        }

        skedWorkdayImportTimeBlockResponse submitResult = BSF_WorkdayOpsRecordDirectService.submitTimeBlocksToWorkday(allBlocks, allDateTimeFormats);
        // Important: perform all post-submit callouts (Employee Report) BEFORE any DML like debug log insert,
        // to avoid \"You have uncommitted work pending\" errors.
        if (submitResult.isSuccess) {
            markOpRecordsProcessed(toProcess, byDriveDate, employeesWithoutTimeByDrive, submitResult.importProcessId);
        } else {
            hadImportFailure = true;
            markOpRecordsFailed(toProcess);
            errorsForTechEmail.add('Workday Import failed: ' + submitResult.message + '; Status: ' + submitResult.statusCode);
        }
        // Log the submission after all callouts and DML related to status updates
        logEmployeeReportCalls(employeeReportLogs);
        logSubmission(toProcess, submitResult);
    }

    public void finish(Database.BatchableContext bc) {
        Boolean hadErrors = !errorsForTechEmail.isEmpty();
        if (hadErrors) {
            if (String.isNotBlank(technicalTeamDistributionList)) {
                sendTechTeamEmail(String.join(errorsForTechEmail, '\n'));
            }
            // Reschedule on any failure: Employee Report or Import. Import failures increment staff attempts, so retries
            // stop when all staff reach max; Employee Report failures don't increment attempts, so we retry until success
            // (set Reschedule Delay to 0 to disable reschedule).
            Integer delayMinutes = BSF_WorkdayDirectSubmissionConfig.getRescheduleDelayMinutes();
            if (delayMinutes != null && delayMinutes > 0) {
                scheduleReschedule(delayMinutes);
            }
        }
        // Business notification:
        // - If there were no errors, always send success summary.
        // - If there were errors, only send success summary when at least one drive succeeded (partial success).
        if (String.isNotBlank(businessDistributionList)) {
            if (!hadErrors || totalDrivesProcessedSuccessfully > 0) {
                sendSuccessNotification(totalDrivesProcessedSuccessfully);
            }
        }
    }

    private void scheduleReschedule(Integer delayMinutes) {
        try {
            DateTime nextRun = DateTime.now().addMinutes(delayMinutes);
            String cronExp = '' + nextRun.second() + ' ' + nextRun.minute() + ' ' + nextRun.hour() + ' ' + nextRun.day() + ' ' + nextRun.month() + ' ? ' + nextRun.year();
            System.schedule('Workday Op Record Reschedule ' + nextRun.getTime(), cronExp, new BSF_OpsRecordWorkdaySubmissionBatch());
        } catch (Exception e) {
        }
    }

    private class OpRecordContext {
        sked_Operation_Record__c opRecord;
        List<sked_Operation_Record_Staff__c> staffList;
        String approverEmail;
        Boolean isRetry;
    }

    private Map<Date, List<OpRecordContext>> groupByDriveDate(List<sked_Operation_Record__c> opRecords) {
        Map<Date, List<OpRecordContext>> byDate = new Map<Date, List<OpRecordContext>>();
        for (sked_Operation_Record__c op : opRecords) {
            if (op.sked_Drive__r == null || op.sked_Drive__r.sked_Drive_Date__c == null) {
                continue;
            }
            Date d = op.sked_Drive__r.sked_Drive_Date__c;
            OpRecordContext ctx = new OpRecordContext();
            ctx.opRecord = op;
            ctx.staffList = op.sked_Operation_Record_Staff__r != null ? op.sked_Operation_Record_Staff__r : new List<sked_Operation_Record_Staff__c>();
            ctx.approverEmail = op.sked_Submitted_By__r != null ? op.sked_Submitted_By__r.sked__Email__c : '';
            ctx.isRetry = op.sked_Workday_Submission_Status__c == BSF_WorkdayDirectSubmissionConfig.STATUS_FAILED;
            if (!byDate.containsKey(d)) {
                byDate.put(d, new List<OpRecordContext>());
            }
            byDate.get(d).add(ctx);
        }
        return byDate;
    }

    private void markOpRecordsProcessed(
        List<sked_Operation_Record__c> opRecords,
        Map<Date, List<OpRecordContext>> byDriveDate,
        Set<String> employeesWithoutTimeByDrive,
        String importProcessId
    ) {
        List<sked_Operation_Record__c> toUpdate = new List<sked_Operation_Record__c>();
        List<sked_Operation_Record_Staff__c> staffToUpdate = new List<sked_Operation_Record_Staff__c>();
        for (sked_Operation_Record__c op : opRecords) {
            op.sked_Workday_Submission_Status__c = BSF_WorkdayDirectSubmissionConfig.STATUS_PROCESSED;
            if (String.isNotBlank(importProcessId)) {
                op.sked_Workday_Import_Process_Id__c = importProcessId;
            }
            toUpdate.add(op);
            Date d = op.sked_Drive__r != null ? op.sked_Drive__r.sked_Drive_Date__c : null;
            if (op.sked_Operation_Record_Staff__r != null) {
                for (sked_Operation_Record_Staff__c st : op.sked_Operation_Record_Staff__r) {
                    st.sked_Workday_Submission_Status__c = BSF_WorkdayDirectSubmissionConfig.STAFF_STATUS_SUCCESS;
                    if (d != null && st.sked_Resource__r != null && String.isNotBlank(st.sked_Resource__r.sked_Employee_ID__c)) {
                        String key = String.valueOf(d) + '_' + st.sked_Resource__r.sked_Employee_ID__c;
                        st.sked_Time_Already_Existed_In_Workday__c = !employeesWithoutTimeByDrive.contains(key);
                    }
                    staffToUpdate.add(st);
                }
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        if (!staffToUpdate.isEmpty()) {
            update staffToUpdate;
        }
        Set<Id> driveIds = new Set<Id>();
        for (sked_Operation_Record__c op : opRecords) {
            if (op.sked_Drive__c != null) {
                driveIds.add(op.sked_Drive__c);
            }
        }
        totalDrivesProcessedSuccessfully += driveIds.size();
    }

    private void markOpRecordsFailed(List<sked_Operation_Record__c> opRecords) {
        List<sked_Operation_Record_Staff__c> staffToUpdate = new List<sked_Operation_Record_Staff__c>();
        Date today = Date.today();
        for (sked_Operation_Record__c op : opRecords) {
            if (op.sked_Operation_Record_Staff__r != null) {
                for (sked_Operation_Record_Staff__c st : op.sked_Operation_Record_Staff__r) {
                    st.sked_Workday_Submission_Status__c = BSF_WorkdayDirectSubmissionConfig.STAFF_STATUS_FAILED;
                    staffToUpdate.add(st);
                }
            }
            Decimal attempt = 0;
            if (op.sked_WD_Last_Submission_Date__c == today && op.sked_Workday_Submission_Attempt__c != null) {
                attempt = op.sked_Workday_Submission_Attempt__c; //get attempt value from the op record, if it is today
            } else {
                op.sked_WD_Last_Submission_Date__c = today;
            }
            op.sked_Workday_Submission_Attempt__c = attempt + 1;
            op.sked_Workday_Submission_Status__c = BSF_WorkdayDirectSubmissionConfig.STATUS_FAILED;
        }
        update opRecords;
        if (!staffToUpdate.isEmpty()) {
            update staffToUpdate;
        }
    }

    /**
     * Truncates a value to fit within the length of the given Debug Log field (describe length, e.g. 32768 or 131000).
     * Falls back to 131000 for sked__Message__c or 32768 for other long-text fields if describe is unavailable.
     */
    private static String truncateForDebugLog(String value, Schema.SObjectField fieldToken) {
        if (value == null) {
            return null;
        }
        Integer maxLen;
        try {
            Schema.DescribeFieldResult dfr = fieldToken != null ? fieldToken.getDescribe() : null;
            maxLen = dfr != null ? dfr.getLength() : null;
        } catch (Exception e) {
            maxLen = (fieldToken == sked__Debug_Log__c.sked__Message__c) ? 131000 : 32768;
        }
        if (maxLen == null || maxLen <= 0) {
            maxLen = (fieldToken == sked__Debug_Log__c.sked__Message__c) ? 131000 : 32768;
        }
        if (value.length() > maxLen) {
            return value.substring(0, maxLen);
        }
        return value;
    }

    private void logSubmission(List<sked_Operation_Record__c> opRecords, skedWorkdayImportTimeBlockResponse result) {
        try {
            if (skedSetting.instance == null || skedSetting.instance.Admin == null || skedSetting.instance.Admin.enableOperationRecordLog != true) {
                return;
            }
        } catch (Exception e) {
            return;
        }
        String summary = 'Workday Direct Submit: ' + (result.isSuccess ? 'Success' : 'Failed') + '; StatusCode=' + result.statusCode + '; OpRecords=' + opRecords.size();
        String messageBody = String.isNotBlank(result.request)
            ? truncateForDebugLog(result.request, sked__Debug_Log__c.sked__Message__c)
            : truncateForDebugLog(result.message, sked__Debug_Log__c.sked__Message__c);
        sked__Debug_Log__c log = new sked__Debug_Log__c(
            sked__Type__c = 'Operation Record Submission',
            sked__Summary__c = summary,
            sked__Message__c = messageBody,
            sked_Request__c = truncateForDebugLog(result.request, sked__Debug_Log__c.sked_Request__c),
            sked_Response__c = truncateForDebugLog(result.response, sked__Debug_Log__c.sked_Response__c)
        );
        insert log;
    }

    /** Logs each Employee Report (employees without time) request/response to sked__Debug_Log__c when operation record logging is enabled. */
    private void logEmployeeReportCalls(List<BSF_WorkdayOpsRecordDirectService.EmployeeReportResult> employeeReportLogs) {
        if (employeeReportLogs == null || employeeReportLogs.isEmpty()) {
            return;
        }
        try {
            if (skedSetting.instance == null || skedSetting.instance.Admin == null || skedSetting.instance.Admin.enableOperationRecordLog != true) {
                return;
            }
        } catch (Exception e) {
            return;
        }
        List<sked__Debug_Log__c> logs = new List<sked__Debug_Log__c>();
        for (Integer i = 0; i < employeeReportLogs.size(); i++) {
            BSF_WorkdayOpsRecordDirectService.EmployeeReportResult er = employeeReportLogs[i];
            String summary = 'Workday Employee Report (no time): StatusCode=' + er.statusCode + '; employeesWithoutTime=' + (er.employeeIdToTimezone != null ? er.employeeIdToTimezone.size() : 0) + (employeeReportLogs.size() > 1 ? '; call #' + (i + 1) : '');
            String requestToLog = truncateForDebugLog(er.requestUrl, sked__Debug_Log__c.sked_Request__c);
            String responseToLog = truncateForDebugLog(er.responseBody, sked__Debug_Log__c.sked_Response__c);
            String messageBody = String.isNotBlank(er.responseBody)
                ? truncateForDebugLog(er.responseBody, sked__Debug_Log__c.sked__Message__c)
                : (er.statusCode != null ? String.valueOf(er.statusCode) : '');
            logs.add(new sked__Debug_Log__c(
                sked__Type__c = 'Operation Record - Employee Report',
                sked__Summary__c = summary,
                sked__Message__c = messageBody,
                sked_Request__c = requestToLog,
                sked_Response__c = responseToLog
            ));
        }
        if (!logs.isEmpty()) {
            insert logs;
        }
    }

    /** Sends one success email to the business distribution list after all batches complete. */
    private void sendSuccessNotification(Integer driveCount) {
        try {
            List<String> toList = parseCommaSeparatedEmails(businessDistributionList);
            if (toList.isEmpty()) {
                return;
            }
            String bodySuffix = '';
            if (driveCount == 0) {
                bodySuffix = ' (no outstanding eligible operation records to process)';
            }
            List<skedEmailService.emailModel> emails = new List<skedEmailService.emailModel>();
            skedEmailService.emailModel emailItem = new skedEmailService.emailModel();
            emailItem.fromAddress = notificationFromEmail;
            emailItem.subject = 'Op Record Processing Complete';
            emailItem.htmlBody = 'BSF submitted ' + driveCount + ' drive(s) to Workday successfully' + bodySuffix;
            emailItem.toList = toList;
            emails.add(emailItem);
            skedEmailService emailService = new skedEmailService();
            emailService.sendEmails(emails);
        } catch (Exception e) {
        }
    }

    private void sendTechTeamEmail(String errorSummary) {
        try {
            if (String.isBlank(technicalTeamDistributionList)) {
                return;
            }
            List<String> toList = parseCommaSeparatedEmails(technicalTeamDistributionList);
            if (toList.isEmpty()) {
                return;
            }
            List<skedEmailService.emailModel> emails = new List<skedEmailService.emailModel>();
            skedEmailService.emailModel emailItem = new skedEmailService.emailModel();
            emailItem.fromAddress = notificationFromEmail;
            emailItem.subject = 'Op Record Processing Complete – Technical Failures';
            emailItem.htmlBody = 'The batch encountered errors:<br/><pre>' + errorSummary + '</pre>';
            emailItem.toList = toList;
            emails.add(emailItem);
            skedEmailService emailService = new skedEmailService();
            emailService.sendEmails(emails);
        } catch (Exception e) {
        }
    }

    private static List<String> parseCommaSeparatedEmails(String commaSeparated) {
        List<String> toList = new List<String>();
        if (String.isBlank(commaSeparated)) {
            return toList;
        }
        for (String e : commaSeparated.split(',')) {
            String t = e.trim();
            if (String.isNotBlank(t)) {
                toList.add(t);
            }
        }
        return toList;
    }

}