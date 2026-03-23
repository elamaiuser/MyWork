// ─────────────────────────────────────────────────────────────────────────────
// BSF_LeaveReturnBatch
//
// Purpose : Nightly batch job that syncs anticipated leave return date data
//           from the Workday Leave Report into Salesforce. Uses
//           BSF_WorkdayBatchHelper for all shared infrastructure (HTTP
//           callout, JSON parsing, map builders, DML error logging,
//           duplicate-run prevention).
//
//           For each employee returned by the Workday RaaS report:
//             1. Creates or updates a BSF_Workday_Staging__c record
//                (Record Type: Leave_Report).
//             2. Populates sked_Anticipated_Leave_Return_Date__c on the
//                linked sked__Resource__c.
//
//           finish() queries resources whose anticipated leave return date
//           has already passed and sets sked_Employment_Status__c = 'Active'.
//
// Scheduling:
//   String cronExp = '0 0 3 * * ?'; // 3 AM daily
//   System.schedule('Leave Return Sync', cronExp, new BSF_LeaveReturnBatch());
// ─────────────────────────────────────────────────────────────────────────────
public class BSF_LeaveReturnBatch implements Database.Batchable<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String JOB_LABEL                = 'BSF_LeaveReturnBatch';
    private static final String STAGING_RT_DEVELOPER_NAME = 'Leave_Report';

    // Workday JSON field name for the anticipated leave return date. 
    // TODO: Update this constant once Workday finalises the field name.
    private static final String WD_RETURN_DATE_FIELD = 'Estimated_Last_Day_of_Leave';
    private static final String WD_FIRST_DAY_OF_LEAVE_FIELD = 'First_Day_of_Leave'; // Date field — used to determine if employee is currently mid-leave
    private static final String WD_LAST_UPDATED_FIELD = 'Last_Functionally_Updated'; // DateTime field — Workday change detection key

    private static final Integer DEFAULT_BATCH_SIZE = 200;

    private Integer batchSize = DEFAULT_BATCH_SIZE;

    // Set in start() if the Workday callout fails — prevents finish() from
    // stamping Last_Successful_Run_Date__c on a failed run
    private String errorMessage;

    // staging record type Id
    private Id stagingRecordTypeId;

    // Additional staging fields needed by this batch beyond the base set
    private static final List<String> STAGING_FIELDS = new List<String>{
        'Anticipated_Leave_Return_Date__c',
        'Workday_Last_Functionally_Updated__c',
        'First_Day_of_Leave__c'
    };

    // Additional resource fields needed by this batch beyond Id, sked_Employee_ID__c and sked_Employment_Status__c
    private static final List<String> RESOURCE_FIELDS = new List<String>{
        'sked_Anticipated_Leave_Return_Date__c'
    };

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTORS
    // ─────────────────────────────────────────────────────────────────────────

    public BSF_LeaveReturnBatch() {
    }

    public BSF_LeaveReturnBatch(Integer batchSize) {
        if (batchSize != null && batchSize > 0) {
            this.batchSize = batchSize;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCHEDULABLE — prevents duplicate runs if a previous batch is still active
    // ─────────────────────────────────────────────────────────────────────────
    public void execute(SchedulableContext sc) {
        System.debug(JOB_LABEL + ': Scheduled trigger fired');

        if (!BSF_WorkdayBatchHelper.isBatchAlreadyRunning(JOB_LABEL)) {
            Integer size = getConfiguredBatchSize();
            BSF_LeaveReturnBatch batch = new BSF_LeaveReturnBatch(size);
            Database.executeBatch(batch, batch.batchSize);
            System.debug(JOB_LABEL + ': Batch queued with batch size ' + size);
        } else {
            System.debug(JOB_LABEL + ': Batch already running — skipping this scheduled trigger');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // START
    // Resolves the Workday endpoint, makes the callout via the helper,
    // and returns the full employee list as the batch iterable scope
    // ─────────────────────────────────────────────────────────────────────────
    public Iterable<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper> start(Database.BatchableContext bc) {
        System.debug(JOB_LABEL + ': start() — batch job ID: ' + bc.getJobId());

        List<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper> employees;

        try {
            employees = BSF_WorkdayBatchHelper.fetchWorkdayData(buildEndpoint(), JOB_LABEL);
        } catch (Exception e) {
            errorMessage = e.getMessage();
            System.debug(JOB_LABEL + ': Fatal error in start() — ' + errorMessage);
            throw e;
        }

        System.debug(JOB_LABEL + ': Workday returned ' + employees.size() + ' employee record(s)');
        return employees;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // EXECUTE
    // Processes one chunk of Workday employees. Builds staging and resource
    // maps via the helper, then applies Leave-specific business logic.
    // ─────────────────────────────────────────────────────────────────────────
    public void execute(Database.BatchableContext bc, List<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper> scope) {
        System.debug(JOB_LABEL + ': execute() — processing chunk of ' + scope.size() + ' employee(s)');

        // Collect employee IDs in this chunk for targeted SOQL
        Set<String> employeeIds = new Set<String>();
        for (BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper w : scope) {
            employeeIds.add(w.employeeId);
        }

        Map<String, BSF_Workday_Staging__c> stagingMap = BSF_WorkdayBatchHelper.buildStagingMap(
            employeeIds,
            STAGING_RT_DEVELOPER_NAME,
            STAGING_FIELDS
        );
        System.debug(JOB_LABEL + ': Found ' + stagingMap.size() + ' existing staging record(s) for this chunk');

        Map<String, sked__Resource__c> resourceMap = BSF_WorkdayBatchHelper.buildResourceMap(
            employeeIds,
            RESOURCE_FIELDS
        );
        System.debug(JOB_LABEL + ': Found ' + resourceMap.size() + ' matching Resource record(s) for this chunk');

        List<BSF_Workday_Staging__c> stagingToUpsert  = new List<BSF_Workday_Staging__c>();
        List<sked__Resource__c>      resourcesToUpdate = new List<sked__Resource__c>();

        for (BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper wd : scope) {

            String resourceEmploymentStatus;
            Date returnDate = BSF_WorkdayBatchHelper.getExtraDate(wd, WD_RETURN_DATE_FIELD, JOB_LABEL);
            DateTime lastFunctionallyUpdated = BSF_WorkdayBatchHelper.getExtraDateTime(wd, WD_LAST_UPDATED_FIELD, JOB_LABEL);
            Date firstDayOfLeave = BSF_WorkdayBatchHelper.getExtraDate(wd, WD_FIRST_DAY_OF_LEAVE_FIELD, JOB_LABEL);

            if(returnDate == null || returnDate<System.today()){
                System.debug(JOB_LABEL + ': Employee ' + wd.employeeId + ' has a return date of ' + returnDate + ' which is in the past — skipping');
                continue;
            }

            // Set to 'Leave' only when the employee is currently mid-leave
            // (firstDayOfLeave has passed AND returnDate is in the future).
            // Remains null if the condition is not met — resource status is not changed.
            if (firstDayOfLeave != null && firstDayOfLeave <= System.today() && returnDate > System.today()) {
                resourceEmploymentStatus = skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE;
            }

            // ── Staging ──────────────────────────────────────────────────────
            if (stagingMap.containsKey(wd.employeeId)) {

                BSF_Workday_Staging__c staging = stagingMap.get(wd.employeeId);

                // Update only when something has actually changed
                if (staging.Anticipated_Leave_Return_Date__c != returnDate || staging.Workday_Last_Functionally_Updated__c != lastFunctionallyUpdated || staging.First_Day_of_Leave__c != firstDayOfLeave) {

                    System.debug(JOB_LABEL + ': Updating staging for employee ' + wd.employeeId
                        + ' — return date: ' + returnDate);

                    // Build change log BEFORE overwriting fields
                    String fieldChanges = '';
                    if (staging.First_Day_of_Leave__c != firstDayOfLeave) {
                        fieldChanges += 'First_Day_of_Leave: '
                            + staging.First_Day_of_Leave__c + ' → ' + firstDayOfLeave + '; ';
                    }
                    if (staging.Anticipated_Leave_Return_Date__c != returnDate) {
                        fieldChanges += 'Anticipated_Leave_Return_Date: '
                            + staging.Anticipated_Leave_Return_Date__c + ' → ' + returnDate + '; ';
                    }
                    if (staging.Workday_Last_Functionally_Updated__c != lastFunctionallyUpdated) {
                        fieldChanges += 'Workday_Last_Functionally_Updated: '
                            + staging.Workday_Last_Functionally_Updated__c + ' → ' + lastFunctionallyUpdated + '; ';
                    }

                    BSF_WorkdayBatchHelper.applyCommonStagingUpdate(staging, wd, fieldChanges);
                    staging.Anticipated_Leave_Return_Date__c = returnDate;
                    staging.Workday_Last_Functionally_Updated__c = lastFunctionallyUpdated;
                    staging.First_Day_of_Leave__c = firstDayOfLeave;

                    stagingToUpsert.add(staging);

                } else {
                    System.debug(JOB_LABEL + ': No changes for employee ' + wd.employeeId + ' — skipping staging');
                }

            } else if (resourceMap.containsKey(wd.employeeId)) {

                // No staging yet but a matching Resource exists — create staging.
                // Orphaned Workday employees with no Resource are silently skipped.
                System.debug(JOB_LABEL + ': Creating staging for employee ' + wd.employeeId
                    + ' — return date: ' + returnDate);

                BSF_Workday_Staging__c newRec = BSF_WorkdayBatchHelper.buildNewStagingRecord(
                    wd,
                    resourceMap.get(wd.employeeId).Id,
                    getStagingRecordTypeId(),
                    '1st time leave synced from Workday'
                );
                newRec.Anticipated_Leave_Return_Date__c = returnDate;
                newRec.Workday_Last_Functionally_Updated__c = lastFunctionallyUpdated;
                newRec.First_Day_of_Leave__c = firstDayOfLeave;

                stagingToUpsert.add(newRec);

            } else {
                System.debug(JOB_LABEL + ': No Resource found for employee ' + wd.employeeId + ' — skipping');
            }

            // ── Resource ─────────────────────────────────────────────────────
            // Always sync the return date on the resource regardless of whether
            // staging changed — resource field is what scheduling reads for availability
            if (resourceMap.containsKey(wd.employeeId)) {
                sked__Resource__c r = resourceMap.get(wd.employeeId);

                if (r.sked_Anticipated_Leave_Return_Date__c != returnDate || (resourceEmploymentStatus != null && r.sked_Employment_Status__c != resourceEmploymentStatus)) {
                    System.debug(JOB_LABEL + ': Updating Resource return date for employee '
                        + wd.employeeId + ' — return date: ' + returnDate);

                    r.sked_Anticipated_Leave_Return_Date__c = returnDate;
                    if (resourceEmploymentStatus != null) {
                        r.sked_Employment_Status__c = resourceEmploymentStatus;
                    }
                    resourcesToUpdate.add(r);
                }
            }
        }

        if (!stagingToUpsert.isEmpty()) {
            System.debug(JOB_LABEL + ': Upserting ' + stagingToUpsert.size() + ' staging record(s)');
            List<Database.UpsertResult> upsertResults = Database.upsert(stagingToUpsert, BSF_Workday_Staging__c.Employee_ID__c, false);
            BSF_WorkdayBatchHelper.logUpsertErrors(upsertResults, 'staging upsert', JOB_LABEL);
        }

        if (!resourcesToUpdate.isEmpty()) {
            System.debug(JOB_LABEL + ': Updating ' + resourcesToUpdate.size() + ' Resource record(s)');
            List<Database.SaveResult> resourceResults = Database.update(resourcesToUpdate, false);
            BSF_WorkdayBatchHelper.logSaveErrors(resourceResults, 'resource update', JOB_LABEL);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // FINISH
    // Reactivates employees whose anticipated leave return date has passed.
    // Queries sked__Resource__c where:
    //   - sked_Anticipated_Leave_Return_Date__c < today
    //   - sked_Employment_Status__c = 'Leave'  (not already active)
    // Sets sked_Employment_Status__c = 'Active'.
    // The return date field is intentionally preserved as an audit trail.
    // ─────────────────────────────────────────────────────────────────────────
    public void finish(Database.BatchableContext bc) {
        System.debug(JOB_LABEL + ': finish() — querying resources to reactivate');

        List<sked__Resource__c> toReactivate = [
            SELECT Id, sked_Employment_Status__c, sked_Anticipated_Leave_Return_Date__c
            FROM   sked__Resource__c
            WHERE  sked_Anticipated_Leave_Return_Date__c <= :System.today()
            AND    sked_Employment_Status__c = 'Leave'
        ];

        if (!toReactivate.isEmpty()) {
            System.debug(JOB_LABEL + ': Reactivating ' + toReactivate.size() + ' Resource record(s) whose leave return date has passed');

            for (sked__Resource__c r : toReactivate) {
                r.sked_Employment_Status__c = 'Active';
            }

            BSF_WorkdayBatchHelper.logSaveErrors(
                Database.update(toReactivate, false),
                'finish resource reactivation',
                JOB_LABEL
            );
        } else {
            System.debug(JOB_LABEL + ': No resources require reactivation today');
        }

        if (String.isBlank(errorMessage)) {
            updateLastSuccessfulRunDate();
        } else {
            System.debug(JOB_LABEL + ': Skipping Last_Successful_Run_Date__c update due to fatal error — ' + errorMessage);
        }

        System.debug(JOB_LABEL + ': finish() complete');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────────────────────────────────────

    // Resolves the Workday endpoint from sked_Workday_XML_Template__mdt
    // (DeveloperName = 'Leave_Report'), appends CF_-_Prompt using
    // the last successful run date as an incremental filter, then appends
    // format=json. If the metadata record is missing or blank, endpoint will
    // be null and appendQueryParam() will throw a NullPointerException —
    // the metadata record must be deployed to all environments.
    private String buildEndpoint() {
        String endpoint;
        try {
            sked_Workday_XML_Template__mdt xml = [
                SELECT sked_Endpoint__c
                FROM sked_Workday_XML_Template__mdt
                WHERE DeveloperName = 'Leave_Report'
                LIMIT 1
            ];

            if (xml != null && String.isNotBlank(xml.sked_Endpoint__c)) {
                endpoint = xml.sked_Endpoint__c;
                System.debug(JOB_LABEL + ': Using endpoint from custom metadata — ' + endpoint);
            }
        } catch (Exception mdEx) {
            System.debug(JOB_LABEL + ': Could not read custom metadata endpoint, falling back to hardcoded default — ' + mdEx.getMessage());
        }

        //TODO: The following line to append the CF_-_Prompt filter once Workday confirms the expected format.
        //endpoint = BSF_WorkdayBatchHelper.appendQueryParam(endpoint, 'CF_-_Prompt', '2026-01-01-08:00');
        Date filterDate = resolveFilterDate();
        if (filterDate != null) {
            endpoint = BSF_WorkdayBatchHelper.appendQueryParam(endpoint, 'CF_-_Prompt', String.valueOf(filterDate));
        }
        endpoint = BSF_WorkdayBatchHelper.appendQueryParam(endpoint, 'format', 'json');
        return endpoint;
    }

    // Reads Last_Successful_Run_Date__c from BSF_Workday_Leave_Config__c and
    // uses it as the CF_-_Prompt filter sent to Workday. This makes the
    // report incremental — Workday only returns records changed since the last
    // successful run. Falls back to yesterday if the config is missing or blank,
    // ensuring at least the previous day's changes are captured on first run.
    private Date resolveFilterDate() {
        try {
            BSF_Workday_Leave_Config__c config = BSF_Workday_Leave_Config__c.getOrgDefaults();
            if (config != null && config.Last_Successful_Run_Date__c != null) {
                return config.Last_Successful_Run_Date__c;
            }
            else if(config != null && config.Initial_Backfill_Date__c != null){
                return config.Initial_Backfill_Date__c;
            }
        } catch (Exception e) {
            System.debug(JOB_LABEL + ': Error reading filter date from config — ' + e.getMessage());
        }
        return System.today().addYears(-5);
    }

    private Id getStagingRecordTypeId() {
        if (stagingRecordTypeId == null) {
            stagingRecordTypeId = [
                SELECT Id FROM RecordType
                WHERE  SObjectType   = 'BSF_Workday_Staging__c'
                AND    DeveloperName = :STAGING_RT_DEVELOPER_NAME
                LIMIT  1
            ].Id;
        }
        return stagingRecordTypeId;
    }

    private Integer getConfiguredBatchSize() {
        Integer size;
        try {
            BSF_Workday_Leave_Config__c config = BSF_Workday_Leave_Config__c.getOrgDefaults();
            if (config != null && config.Batch_Size__c != null && config.Batch_Size__c > 0) {
                size = config.Batch_Size__c.intValue();
            }
        } catch (Exception e) {
            System.debug(JOB_LABEL + ': Error reading batch size from config — ' + e.getMessage());
        }
        return (size != null && size > 0) ? size : DEFAULT_BATCH_SIZE;
    }

    private void updateLastSuccessfulRunDate() {
        try {
            BSF_Workday_Leave_Config__c config = BSF_Workday_Leave_Config__c.getOrgDefaults();
            config.Last_Successful_Run_Date__c = System.today();
            upsert config;
            System.debug(JOB_LABEL + ': Last_Successful_Run_Date__c updated to ' + System.today());
        } catch (Exception e) {
            System.debug(JOB_LABEL + ': Could not update Last_Successful_Run_Date__c — ' + e.getMessage());
        }
    }
}