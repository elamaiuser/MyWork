// ─────────────────────────────────────────────────────────────────────────────
// BSF_RealIdComplianceBatch
//
// Purpose : Nightly batch job that syncs REAL ID compliance data from Workday
//           into Salesforce. Uses BSF_WorkdayBatchHelper for all shared
//           infrastructure: HTTP callout, JSON parsing, map builders, DML
//           error logging, and duplicate-run prevention.
//
//           For each employee returned by the Workday RaaS report:
//             1. Creates or updates a BSF_Workday_Staging__c record
//                (Record Type: Real_ID_Compliance).
//             2. Updates the linked sked__Resource__c compliance fields.
//
//           finish() detects employees that were previously compliant in
//           Salesforce but are no longer present in the Workday response.
//           Their staging records are marked Removed and their resource
//           compliance fields are unchecked.
//
// Dependencies:
//   - BSF_WorkdayBatchHelper     — shared HTTP, parsing, logging utilities
//   - BSF_Workday_RealID_Config__c — custom setting for endpoint config,
//                                    backfill date, batch size, run date
//   - sked_Workday_XML_Template__mdt (DeveloperName = 'RealID_Compliance_Report')
//                                  — holds the Workday RaaS endpoint URL
//   - skedConstants              — provides staging sync status picklist values
//                                    and INACTIVE_STATUS
//
// Scheduling:
//   String cronExp = '0 0 2 * * ?'; // 2 AM daily
//   System.schedule('Real ID Sync', cronExp, new BSF_RealIdComplianceBatch());
// ─────────────────────────────────────────────────────────────────────────────
public class BSF_RealIdComplianceBatch implements Database.Batchable<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    // Human-readable label used as a prefix in all System.debug calls and
    // sked__Debug_Log__c entries produced by this batch
    private static final String JOB_LABEL                 = 'BSF_RealIdComplianceBatch';

    // DeveloperName of the BSF_Workday_Staging__c record type for REAL ID records.
    private static final String STAGING_RT_DEVELOPER_NAME = 'Real_ID_Compliance';

    // Workday JSON field names retrieved via getExtraDate() / getExtraDateTime().
    private static final String WD_EXPIRATION_DATE_FIELD  = 'Expiration_Date';           // Date field — REAL ID expiry
    private static final String WD_LAST_UPDATED_FIELD     = 'Last_Functionally_Updated'; // DateTime field — Workday change detection key
    private static final String WD_CREATED_MOMENT_FIELD   = 'Created_Moment';            // DateTime field — stored for audit trail

    // Default batch size used when no value is configured in custom setting
    private static final Integer DEFAULT_BATCH_SIZE = 200;

    // Batch size for this run — set by the constructor
    private Integer batchSize = DEFAULT_BATCH_SIZE;

    // Populated in start() if the Workday callout throws. Checked in finish()
    // to skip stamping Last_Successful_Run_Date__c when the run did not complete
    // successfully
    private String errorMessage;

    // All Workday employee IDs returned in this run, populated in start().
    // Used in finish() to identify employees absent from the current Workday
    // response so their staging and resource records can be marked as Removed
    private Set<String> workdayEmployeeIds = new Set<String>();

    private Id stagingRecordTypeId;

    // Domain-specific staging fields required by this batch, passed to
    // BSF_WorkdayBatchHelper.buildStagingMap() as additionalFields.
    // These extend the helper's base set (Id, Employee_ID__c, Resource__c,
    // Sync_Comment__c) with fields needed for change detection and compliance logic.
    private static final List<String> STAGING_FIELDS = new List<String>{
        'Real_ID_Compliant__c',              // Used for compliance change detection
        'Expiration_Date__c',                // Used for expiry change detection
        'Workday_Last_Functionally_Updated__c', // Primary Workday-side change detection key
        'Workday_Record_Created_Moment__c',  // Stored for audit trail
        'Sync_Status__c'                     // Set to Updated or Removed by this batch
    };

    // Domain-specific resource fields required by this batch, passed to
    // BSF_WorkdayBatchHelper.buildResourceMap() as additionalFields.
    // These extend the helper's base set (Id, sked_Employee_ID__c,
    // sked_Employment_Status__c) with fields needed for compliance sync.
    private static final List<String> RESOURCE_FIELDS = new List<String>{
        'sked_REAL_ID_Compliant_indicator__c', // Read for change detection; written with derived compliant value
        'sked_Real_ID_Expiration_Date__c'      // Read for change detection; written with Workday expiry date
    };

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTORS
    // ─────────────────────────────────────────────────────────────────────────

    public BSF_RealIdComplianceBatch() {
    }

    // @param batchSize  Number of wrapper records per execute() chunk.
    //                   Ignored if null or <= 0 — falls back to DEFAULT_BATCH_SIZE.
    public BSF_RealIdComplianceBatch(Integer batchSize) {
        if (batchSize != null && batchSize > 0) {
            this.batchSize = batchSize;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCHEDULABLE
    // Called by the Salesforce scheduler at the configured cron time.
    // Checks whether a previous run is still active before queuing a new one
    // to prevent overlapping executions if a run takes longer than expected.
    // ─────────────────────────────────────────────────────────────────────────
    public void execute(SchedulableContext sc) {
        System.debug(JOB_LABEL + ': Scheduled trigger fired');

        if (!BSF_WorkdayBatchHelper.isBatchAlreadyRunning(JOB_LABEL)) {
            Integer size = getConfiguredBatchSize();
            BSF_RealIdComplianceBatch batch = new BSF_RealIdComplianceBatch(size);
            Database.executeBatch(batch, batch.batchSize);
            System.debug(JOB_LABEL + ': Batch queued with batch size ' + size);
        } else {
            System.debug(JOB_LABEL + ': Batch already running — skipping this scheduled trigger');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // START
    // Builds the Workday endpoint, calls the RaaS API via BSF_WorkdayBatchHelper,
    // and populates workdayEmployeeIds from the full response so finish() can
    // use the set for removal detection after all execute() chunks have run.
    // Returns the parsed employee list as the batch iterable scope.
    // ─────────────────────────────────────────────────────────────────────────
    public Iterable<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper> start(Database.BatchableContext bc) {
        System.debug(JOB_LABEL + ': start() — batch job ID: ' + bc.getJobId());

        List<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper> employees;

        try {
            employees = BSF_WorkdayBatchHelper.fetchWorkdayData(buildEndpoint(), JOB_LABEL);
        } catch (Exception e) {
            // Store the error so finish() skips stamping Last_Successful_Run_Date__c,
            // then rethrow so the batch framework marks the job as failed
            errorMessage = e.getMessage();
            System.debug(JOB_LABEL + ': Fatal error in start() — ' + errorMessage);
            throw e;
        }

        for (BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper w : employees) {
            workdayEmployeeIds.add(w.employeeId);
        }

        System.debug(JOB_LABEL + ': Workday returned ' + employees.size() + ' employee record(s)');
        return employees;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // EXECUTE
    // Processes one chunk of Workday employees at a time.
    // For each employee in the chunk:
    //   - Existing staging record + data changed  → update staging, set Updated
    //   - Existing staging record + no change     → skip (avoid unnecessary DML)
    //   - No staging record + Resource exists     → create staging, set Created
    //   - No staging record + no Resource         → skip (orphaned Workday entry)
    //   - Resource exists (any of the above)      → sync compliance fields if changed
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

        Date today = System.today();

        for (BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper wd : scope) {

            // Parse domain-specific fields from extraFields for this employee
            Date     expDate      = BSF_WorkdayBatchHelper.getExtraDate(wd, WD_EXPIRATION_DATE_FIELD, JOB_LABEL);
            DateTime lastUpdated  = BSF_WorkdayBatchHelper.getExtraDateTime(wd, WD_LAST_UPDATED_FIELD, JOB_LABEL);
            DateTime createdMoment = BSF_WorkdayBatchHelper.getExtraDateTime(wd, WD_CREATED_MOMENT_FIELD, JOB_LABEL);

            // An employee is compliant if Workday has no expiry date set (open-ended
            // certification) or the expiry date is today or in the future.
            // An expired employee (expiry date in the past) is non-compliant even if
            // Workday has not changed the Last_Functionally_Updated timestamp.
            Boolean compliant = (expDate == null || expDate >= today);

            // ── Staging ──────────────────────────────────────────────────────
            if (stagingMap.containsKey(wd.employeeId)) {

                BSF_Workday_Staging__c staging = stagingMap.get(wd.employeeId);

                // Two change signals trigger a staging update:
                //   1. Last_Functionally_Updated changed — Workday changed the record
                //   2. Compliant flag changed — expiry date crossed midnight since
                //      the last run even though Workday did not change the record
                if (staging.Workday_Last_Functionally_Updated__c != lastUpdated ||
                    staging.Real_ID_Compliant__c != compliant) {

                    System.debug(JOB_LABEL + ': Updating staging for employee ' + wd.employeeId
                        + ' — compliant: ' + compliant + ', expiration: ' + expDate);

                    // Build the change log BEFORE overwriting fields. If this were
                    // done after the assignments below, the old values would already
                    // be overwritten and the diff string would always appear empty.
                    String fieldChanges = '';
                    if (staging.Workday_Last_Functionally_Updated__c != lastUpdated) {
                        fieldChanges += 'Last_Functionally_Updated: '
                            + staging.Workday_Last_Functionally_Updated__c + ' → ' + lastUpdated + '; ';
                    }
                    if (staging.Real_ID_Compliant__c != compliant) {
                        fieldChanges += 'Compliant: ' + staging.Real_ID_Compliant__c + ' → ' + compliant + '; ';
                    }
                    if (staging.Expiration_Date__c != expDate) {
                        fieldChanges += 'Expiration_Date: ' + staging.Expiration_Date__c + ' → ' + expDate + '; ';
                    }

                    // Append change log to Sync_Comment__c
                    BSF_WorkdayBatchHelper.applyCommonStagingUpdate(staging, wd, fieldChanges);
                    staging.Workday_Last_Functionally_Updated__c = lastUpdated;
                    staging.Workday_Record_Created_Moment__c     = createdMoment;
                    staging.Sync_Status__c                       = skedConstants.STAGING_SYNC_STATUS_UPDATED;
                    staging.Expiration_Date__c                   = expDate;
                    staging.Real_ID_Compliant__c                 = compliant;

                    stagingToUpsert.add(staging);

                } else {
                    System.debug(JOB_LABEL + ': No changes for employee ' + wd.employeeId + ' — skipping staging');
                }

            } else if (resourceMap.containsKey(wd.employeeId)) {

                // No staging record yet but a matching Resource exists — create one.
                // Staging is only created when a Resource exists in Salesforce.
                // Workday employees with no Resource match are silently skipped.
                System.debug(JOB_LABEL + ': Creating staging for employee ' + wd.employeeId
                    + ' — compliant: ' + compliant + ', expiration: ' + expDate);

                BSF_Workday_Staging__c newRec = BSF_WorkdayBatchHelper.buildNewStagingRecord(
                    wd,
                    resourceMap.get(wd.employeeId).Id,
                    getStagingRecordTypeId(),
                    '1st time certification synced from Workday'
                );
                newRec.Workday_Last_Functionally_Updated__c = lastUpdated;
                newRec.Workday_Record_Created_Moment__c     = createdMoment;
                newRec.Sync_Status__c                       = skedConstants.STAGING_SYNC_STATUS_CREATED;
                newRec.Expiration_Date__c                   = expDate;
                newRec.Real_ID_Compliant__c                 = compliant;

                stagingToUpsert.add(newRec);

            } else {
                System.debug(JOB_LABEL + ': No Resource found for employee ' + wd.employeeId + ' — skipping');
            }

            // ── Resource ─────────────────────────────────────────────────────
            // Always sync the resource compliance fields regardless of whether
            // staging was updated. The resource fields are what downstream
            // scheduling logic reads for availability decisions.
            if (resourceMap.containsKey(wd.employeeId)) {
                sked__Resource__c r = resourceMap.get(wd.employeeId);

                if (r.sked_REAL_ID_Compliant_indicator__c != compliant ||
                    r.sked_Real_ID_Expiration_Date__c != expDate) {

                    System.debug(JOB_LABEL + ': Updating Resource for employee ' + wd.employeeId
                        + ' — compliant: ' + compliant + ', expiration: ' + expDate);

                    r.sked_REAL_ID_Compliant_indicator__c = compliant;
                    r.sked_Real_ID_Expiration_Date__c     = expDate;
                    resourcesToUpdate.add(r);
                }
            }
        }

        // Upsert staging records — Employee_ID__c is the external ID match key
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
    // Runs after all execute() chunks have completed.
    //
    // Removal detection: employees that were previously compliant in Salesforce
    // but were not present in this run's Workday response are identified using
    // workdayEmployeeIds. Their staging records are marked Removed and their
    // resource compliance fields are cleared.
    //
    // Staging query filters on Real_ID_Compliant__c = true to avoid loading
    // the entire historical set of already-removed records on every run.
    //
    // Resource query is done directly by employee ID rather than going through
    // the staging lookup — this catches resources that have compliance fields
    // set but no staging record.
    //
    // Last_Successful_Run_Date__c is only stamped if no fatal error occurred
    // in start(). If start() threw, errorMessage is populated and the stamp
    // is intentionally skipped.
    // ─────────────────────────────────────────────────────────────────────────
    public void finish(Database.BatchableContext bc) {
        System.debug(JOB_LABEL + ': finish() — begin removal detection');

        List<BSF_Workday_Staging__c> removedStaging = [
            SELECT Id, Employee_ID__c, Real_ID_Compliant__c, Sync_Comment__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c NOT IN :workdayEmployeeIds
            AND    Real_ID_Compliant__c = true
            AND    RecordType.DeveloperName = :STAGING_RT_DEVELOPER_NAME
        ];

        List<sked__Resource__c> resourcesToUncheck = [
            SELECT Id, sked_REAL_ID_Compliant_indicator__c, sked_Real_ID_Expiration_Date__c
            FROM   sked__Resource__c
            WHERE  sked_Employee_ID__c NOT IN :workdayEmployeeIds
            AND   (sked_REAL_ID_Compliant_indicator__c = true OR sked_Real_ID_Expiration_Date__c != null)
        ];

        if (!removedStaging.isEmpty()) {
            System.debug(JOB_LABEL + ': Marking ' + removedStaging.size() + ' staging record(s) as Removed');
            for (BSF_Workday_Staging__c s : removedStaging) {
                s.Real_ID_Compliant__c = false;
                s.Sync_Status__c       = skedConstants.STAGING_SYNC_STATUS_REMOVED;
                s.Sync_Comment__c      = s.Sync_Comment__c
                    + '\n' + String.valueOf(System.today())
                    + ': Real ID compliance removed from Workday';
            }
            BSF_WorkdayBatchHelper.logSaveErrors(
                Database.update(removedStaging, false),
                'finish staging removal',
                JOB_LABEL
            );
        } else {
            System.debug(JOB_LABEL + ': No staging records to mark as Removed');
        }

        if (!resourcesToUncheck.isEmpty()) {
            System.debug(JOB_LABEL + ': Unchecking ' + resourcesToUncheck.size() + ' Resource record(s)');
            for (sked__Resource__c r : resourcesToUncheck) {
                r.sked_REAL_ID_Compliant_indicator__c = false;
                r.sked_Real_ID_Expiration_Date__c     = null;
            }
            BSF_WorkdayBatchHelper.logSaveErrors(
                Database.update(resourcesToUncheck, false),
                'finish resource uncheck',
                JOB_LABEL
            );
        } else {
            System.debug(JOB_LABEL + ': No Resource records to uncheck');
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

    // Resolves the Workday RaaS endpoint from the sked_Workday_XML_Template__mdt
    // custom metadata record (DeveloperName = 'RealID_Compliance_Report'), then
    // appends the static Effective_as_of_Date filter and format=json.
    //
    // The date filter is intentionally fixed (not incremental) so the full
    // Workday dataset is returned on every run. This is required for accurate
    // removal detection in finish() — if an incremental filter were used,
    // employees absent from recent Workday changes would not be detected as removed.
    private String buildEndpoint() {
        String endpoint;

        try {
            sked_Workday_XML_Template__mdt xml = [
                SELECT sked_Endpoint__c
                FROM   sked_Workday_XML_Template__mdt
                WHERE  DeveloperName = 'RealID_Compliance_Report'
                LIMIT  1
            ];
            if (xml != null && String.isNotBlank(xml.sked_Endpoint__c)) {
                endpoint = xml.sked_Endpoint__c;
                System.debug(JOB_LABEL + ': Using endpoint from custom metadata — ' + endpoint);
            }
        } catch (Exception e) {
            System.debug(JOB_LABEL + ': Could not read custom metadata endpoint — ' + e.getMessage());
        }

        Date filterDate = resolveFilterDate();
        if (filterDate != null) {
            endpoint = BSF_WorkdayBatchHelper.appendQueryParam(endpoint, 'Effective_as_of_Date', String.valueOf(filterDate));
        }
        endpoint = BSF_WorkdayBatchHelper.appendQueryParam(endpoint, 'format', 'json');

        return endpoint;
    }

    // Reads the static backfill date from BSF_Workday_RealID_Config__c.
    // Falls back to 5 years ago if the config record is missing or the field
    // is blank — ensures the full Workday dataset is always returned even if
    // the config has not been set up yet in a new environment.
    private Date resolveFilterDate() {
        try {
            BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
            if (config != null && config.Initial_Backfill_Date__c != null) {
                return config.Initial_Backfill_Date__c;
            }
        } catch (Exception e) {
            System.debug(JOB_LABEL + ': Error reading filter date from config — ' + e.getMessage());
        }
        return System.today().addYears(-5);
    }

    // Returns the Real_ID_Compliance record type Id for BSF_Workday_Staging__c.
    // Lazily resolved and cached to avoid a SOQL query on every execute() chunk.
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

    // Reads the configured batch size from BSF_Workday_RealID_Config__c.
    // Falls back to DEFAULT_BATCH_SIZE if the config is missing or the value
    // is zero or negative.
    private Integer getConfiguredBatchSize() {
        Integer size;
        try {
            BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
            if (config != null && config.Batch_Size__c != null && config.Batch_Size__c > 0) {
                size = config.Batch_Size__c.intValue();
            }
        } catch (Exception e) {
            System.debug(JOB_LABEL + ': Error reading batch size from config — ' + e.getMessage());
        }
        return (size != null && size > 0) ? size : DEFAULT_BATCH_SIZE;
    }

    // Stamps today's date on BSF_Workday_RealID_Config__c.Last_Successful_Run_Date__c
    // so that monitoring and reporting tools can verify the batch ran successfully.
    // Only called from finish() when errorMessage is blank.
    // A failure to write the config does not cause the batch to fail.
    private void updateLastSuccessfulRunDate() {
        try {
            BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
            config.Last_Successful_Run_Date__c  = System.today();
            upsert config;
            System.debug(JOB_LABEL + ': Last_Successful_Run_Date__c updated to ' + System.today());
        } catch (Exception e) {
            System.debug(JOB_LABEL + ': Could not update Last_Successful_Run_Date__c — ' + e.getMessage());
        }
    }
}