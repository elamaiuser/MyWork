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
    public void execute(SchedulableContext schedulableContext) {
        System.debug(JOB_LABEL + ': Scheduled trigger fired');

        if (!BSF_WorkdayBatchHelper.isBatchAlreadyRunning(JOB_LABEL)) {
            Integer configuredBatchSize = getConfiguredBatchSize();
            BSF_LeaveReturnBatch batch = new BSF_LeaveReturnBatch(configuredBatchSize);
            Database.executeBatch(batch, batch.batchSize);
        } else {
            System.debug(JOB_LABEL + ': Batch already running — skipping this scheduled trigger');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // START
    // Resolves the Workday endpoint, makes the callout via the helper,
    // and returns the full employee list as the batch iterable scope
    // ─────────────────────────────────────────────────────────────────────────
    public Iterable<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper> start(Database.BatchableContext batchableContext) {
        System.debug(JOB_LABEL + ': start() — batch job ID: ' + batchableContext.getJobId());

        List<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper> employees;

        try {
            employees = BSF_WorkdayBatchHelper.fetchWorkdayData(buildEndpoint(), JOB_LABEL);
        } catch (Exception caughtException) {
            errorMessage = caughtException.getMessage();
            System.debug(JOB_LABEL + ': Fatal error in start() — ' + errorMessage);
            throw caughtException;
        }
        return employees;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // EXECUTE
    // Processes one chunk of Workday employees. Builds staging and resource
    // maps via the helper, then applies Leave-specific business logic.
    // ─────────────────────────────────────────────────────────────────────────
    public void execute(Database.BatchableContext batchableContext, List<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper> scope) {

        // Collect employee IDs in this chunk for targeted SOQL
        Set<String> employeeIds = new Set<String>();
        for (BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper employeeWrapper : scope) {
            employeeIds.add(employeeWrapper.employeeId);
        }

        Map<String, BSF_Workday_Staging__c> stagingMap = BSF_WorkdayBatchHelper.buildStagingMap(
            employeeIds,
            STAGING_RT_DEVELOPER_NAME,
            STAGING_FIELDS
        );

        Map<String, sked__Resource__c> resourceMap = BSF_WorkdayBatchHelper.buildResourceMap(
            employeeIds,
            RESOURCE_FIELDS
        );

        List<BSF_Workday_Staging__c> stagingToUpsert  = new List<BSF_Workday_Staging__c>();
        List<sked__Resource__c>      resourcesToUpdate = new List<sked__Resource__c>();

        for (BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper workdayEmployee : scope) {

            String resourceEmploymentStatus;
            Date     returnDate             = BSF_WorkdayBatchHelper.getExtraDate(workdayEmployee, WD_RETURN_DATE_FIELD, JOB_LABEL)?.addDays(1); // Workday returns the last day of leave, but the resource becomes available the following day — add 1 day buffer to calculate the return date
            DateTime lastFunctionallyUpdated = BSF_WorkdayBatchHelper.getExtraDateTime(workdayEmployee, WD_LAST_UPDATED_FIELD, JOB_LABEL);
            Date     firstDayOfLeave        = BSF_WorkdayBatchHelper.getExtraDate(workdayEmployee, WD_FIRST_DAY_OF_LEAVE_FIELD, JOB_LABEL);

            // Set to 'Leave' only when the employee is currently mid-leave
            // (firstDayOfLeave has passed AND returnDate is in the future).
            if (firstDayOfLeave != null && firstDayOfLeave <= System.today() && returnDate != null && returnDate > System.today()) {
                resourceEmploymentStatus = skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE;
            } else {
                resourceEmploymentStatus = skedConstants.RESOURCE_EMPLOYMENT_STATUS_ACTIVE;
            }

            // ── Staging ──────────────────────────────────────────────────────
            if (stagingMap.containsKey(workdayEmployee.employeeId)) {

                BSF_Workday_Staging__c existingStaging = stagingMap.get(workdayEmployee.employeeId);

                // Update only when something has actually changed
                if (existingStaging.Anticipated_Leave_Return_Date__c != returnDate
                    || existingStaging.Workday_Last_Functionally_Updated__c != lastFunctionallyUpdated
                    || existingStaging.First_Day_of_Leave__c != firstDayOfLeave) {


                    // Build change log BEFORE overwriting fields
                    String fieldChanges = '';
                    if (existingStaging.First_Day_of_Leave__c != firstDayOfLeave) {
                        fieldChanges += 'First_Day_of_Leave: '
                            + existingStaging.First_Day_of_Leave__c + ' → ' + firstDayOfLeave + '; ';
                    }
                    if (existingStaging.Anticipated_Leave_Return_Date__c != returnDate) {
                        fieldChanges += 'Anticipated_Leave_Return_Date: '
                            + existingStaging.Anticipated_Leave_Return_Date__c + ' → ' + returnDate + '; ';
                    }
                    if (existingStaging.Workday_Last_Functionally_Updated__c != lastFunctionallyUpdated) {
                        fieldChanges += 'Workday_Last_Functionally_Updated: '
                            + existingStaging.Workday_Last_Functionally_Updated__c + ' → ' + lastFunctionallyUpdated + '; ';
                    }

                    BSF_WorkdayBatchHelper.applyCommonStagingUpdate(existingStaging, workdayEmployee, fieldChanges);
                    existingStaging.Anticipated_Leave_Return_Date__c     = returnDate;
                    existingStaging.Workday_Last_Functionally_Updated__c = lastFunctionallyUpdated;
                    existingStaging.First_Day_of_Leave__c                = firstDayOfLeave;

                    stagingToUpsert.add(existingStaging);

                } else {
                    System.debug(JOB_LABEL + ': No changes for employee ' + workdayEmployee.employeeId + ' — skipping staging');
                }

            } else if (resourceMap.containsKey(workdayEmployee.employeeId)) {

                // No staging yet but a matching Resource exists — create staging.
                // Orphaned Workday employees with no Resource are silently skipped.

                BSF_Workday_Staging__c newStagingRecord = BSF_WorkdayBatchHelper.buildNewStagingRecord(
                    workdayEmployee,
                    resourceMap.get(workdayEmployee.employeeId).Id,
                    getStagingRecordTypeId(),
                    '1st time leave synced from Workday'
                );
                newStagingRecord.Anticipated_Leave_Return_Date__c     = returnDate;
                newStagingRecord.Workday_Last_Functionally_Updated__c = lastFunctionallyUpdated;
                newStagingRecord.First_Day_of_Leave__c                = firstDayOfLeave;

                stagingToUpsert.add(newStagingRecord);

            } else {
                System.debug(JOB_LABEL + ': No Resource found for employee ' + workdayEmployee.employeeId + ' — skipping');
            }

            // ── Resource ─────────────────────────────────────────────────────
            // Always sync the return date on the resource regardless of whether
            // staging changed — resource field is what scheduling reads for availability
            if (resourceMap.containsKey(workdayEmployee.employeeId)) {
                sked__Resource__c resourceRecord = resourceMap.get(workdayEmployee.employeeId);

                if ((resourceRecord.sked_Anticipated_Leave_Return_Date__c != returnDate
                    || (resourceEmploymentStatus != null && resourceRecord.sked_Employment_Status__c != resourceEmploymentStatus))
                    && resourceRecord.sked_Employment_Status__c != skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE) {

                    if (resourceEmploymentStatus == skedConstants.RESOURCE_EMPLOYMENT_STATUS_ACTIVE) {
                        resourceRecord.sked_Anticipated_Leave_Return_Date__c = null; // Clear the return date when reactivating an employee
                    } else {
                        resourceRecord.sked_Anticipated_Leave_Return_Date__c = returnDate;
                    }
                    if (resourceEmploymentStatus != null) {
                        resourceRecord.sked_Employment_Status__c = resourceEmploymentStatus;
                    }

                    resourcesToUpdate.add(resourceRecord);
                }
            }
        }

        if (!stagingToUpsert.isEmpty()) {
            List<Database.UpsertResult> upsertResults = Database.upsert(stagingToUpsert, BSF_Workday_Staging__c.Employee_ID__c, false);
            BSF_WorkdayBatchHelper.logUpsertErrors(upsertResults, 'staging upsert', JOB_LABEL);
        }

        if (!resourcesToUpdate.isEmpty()) {
            List<Database.SaveResult> resourceSaveResults = Database.update(resourcesToUpdate, false);
            BSF_WorkdayBatchHelper.logSaveErrors(resourceSaveResults, 'resource update', JOB_LABEL);
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
    public void finish(Database.BatchableContext batchableContext) {

        // Update any resources that should be on leave. This ensures we don't miss any return dates
        // for employees who are currently on leave but haven't been updated to 'Leave' status yet
        // because their return date is in the future.
        resourceUpdateToLeave();

        // Reactivate resources upon return from leave
        List<sked__Resource__c> resourcesToReactivate = [
            SELECT Id, sked_Employment_Status__c, sked_Anticipated_Leave_Return_Date__c
            FROM   sked__Resource__c
            WHERE  sked_Anticipated_Leave_Return_Date__c <= :System.today()
            AND    sked_Employment_Status__c = 'Leave'
        ];

        if (!resourcesToReactivate.isEmpty()) {

            for (sked__Resource__c resourceRecord : resourcesToReactivate) {
                resourceRecord.sked_Employment_Status__c             = 'Active';
                resourceRecord.sked_Anticipated_Leave_Return_Date__c = null;
            }

            BSF_WorkdayBatchHelper.logSaveErrors(
                Database.update(resourcesToReactivate, false),
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
            sked_Workday_XML_Template__mdt xmlTemplate = [
                SELECT sked_Endpoint__c
                FROM   sked_Workday_XML_Template__mdt
                WHERE  DeveloperName = 'Leave_Report'
                LIMIT  1
            ];

            if (xmlTemplate != null && String.isNotBlank(xmlTemplate.sked_Endpoint__c)) {
                endpoint = xmlTemplate.sked_Endpoint__c;
            }
        } catch (Exception caughtException) {
            System.debug(JOB_LABEL + ': Could not read custom metadata endpoint, falling back to hardcoded default — ' + caughtException.getMessage());
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
            BSF_Workday_Leave_Config__c leaveConfig = BSF_Workday_Leave_Config__c.getOrgDefaults();
            if (leaveConfig != null && leaveConfig.Last_Successful_Run_Date__c != null) {
                return leaveConfig.Last_Successful_Run_Date__c;
            } else if (leaveConfig != null && leaveConfig.Initial_Backfill_Date__c != null) {
                return leaveConfig.Initial_Backfill_Date__c;
            }
        } catch (Exception caughtException) {
            System.debug(JOB_LABEL + ': Error reading filter date from config — ' + caughtException.getMessage());
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
        Integer configuredBatchSize;
        try {
            BSF_Workday_Leave_Config__c leaveConfig = BSF_Workday_Leave_Config__c.getOrgDefaults();
            if (leaveConfig != null && leaveConfig.Batch_Size__c != null && leaveConfig.Batch_Size__c > 0) {
                configuredBatchSize = leaveConfig.Batch_Size__c.intValue();
            }
        } catch (Exception caughtException) {
            System.debug(JOB_LABEL + ': Error reading batch size from config — ' + caughtException.getMessage());
        }
        return (configuredBatchSize != null && configuredBatchSize > 0) ? configuredBatchSize : DEFAULT_BATCH_SIZE;
    }

    private void updateLastSuccessfulRunDate() {
        try {
            BSF_Workday_Leave_Config__c leaveConfig    = BSF_Workday_Leave_Config__c.getOrgDefaults();
            leaveConfig.Last_Successful_Run_Date__c    = System.today();
            upsert leaveConfig;
        } catch (Exception caughtException) {
            System.debug(JOB_LABEL + ': Could not update Last_Successful_Run_Date__c — ' + caughtException.getMessage());
        }
    }

    private void resourceUpdateToLeave() {
        // Query staging records directly to capture the date value
        List<BSF_Workday_Staging__c> leaveStaging = [
            SELECT Resource__c, Anticipated_Leave_Return_Date__c
            FROM   BSF_Workday_Staging__c
            WHERE  RecordType.DeveloperName = :STAGING_RT_DEVELOPER_NAME
            AND    Anticipated_Leave_Return_Date__c != null
            AND    First_Day_of_Leave__c <= :System.today()
            AND    Anticipated_Leave_Return_Date__c > :System.today()
        ];

        // Build a map: Resource Id → Anticipated Leave Return Date
        Map<Id, Date> resourceIdToLeaveDateMap = new Map<Id, Date>();
        for (BSF_Workday_Staging__c stagingRecord : leaveStaging) {
            resourceIdToLeaveDateMap.put(stagingRecord.Resource__c, stagingRecord.Anticipated_Leave_Return_Date__c);
        }

        // Query resources using the collected Ids
        List<sked__Resource__c> resourcesToUpdateToLeave = [
            SELECT Id, sked_Employment_Status__c, sked_Anticipated_Leave_Return_Date__c
            FROM   sked__Resource__c
            WHERE  Id IN :resourceIdToLeaveDateMap.keySet()
            AND    sked_Employment_Status__c = 'Active'
        ];

        if (!resourcesToUpdateToLeave.isEmpty()) {

            for (sked__Resource__c resourceRecord : resourcesToUpdateToLeave) {
                resourceRecord.sked_Employment_Status__c             = 'Leave';
                resourceRecord.sked_Anticipated_Leave_Return_Date__c = resourceIdToLeaveDateMap.get(resourceRecord.Id);
            }

            BSF_WorkdayBatchHelper.logSaveErrors(
                Database.update(resourcesToUpdateToLeave, false),
                'finish resource leave status update',
                JOB_LABEL
            );
        }
    }
}