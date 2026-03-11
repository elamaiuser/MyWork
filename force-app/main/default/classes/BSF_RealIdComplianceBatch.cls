// ─────────────────────────────────────────────────────────────────────────────
// BSF_RealIdComplianceBatch
//
// Purpose : Nightly batch job that syncs REAL ID compliance data from Workday
//           into Salesforce. For each employee returned by the Workday RaaS
//           report the batch will:
//             1. Create or update a BSF_Workday_Staging__c record.
//             2. Update the linked sked__Resource__c compliance fields.
//           Employees that were previously compliant but are no longer present
//           in the Workday response are detected in finish() and unchecked.
//
// Scheduling:
//   String cronExp = '0 0 2 * * ?'; // 2 AM daily
//   System.schedule('Real ID Sync', cronExp, new BSF_RealIdComplianceBatch());
// ─────────────────────────────────────────────────────────────────────────────
public class BSF_RealIdComplianceBatch implements Database.Batchable<BSF_RealIdComplianceBatch.WorkdayEmployeeWrapper>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final Integer DEFAULT_BATCH_SIZE = 200;

    private Integer batchSize = DEFAULT_BATCH_SIZE;

    // Stores any fatal error message to prevent updating Last_Successful_Run_Date__c
    private String errorMessage;

    // Static backfill date sent to Workday as the Effective_as_of_Date filter
    // Populated from BSF_Workday_RealID_Config__c.Initial_Backfill_Date__c
    private Date filterDate;

    // All employee IDs returned by Workday this run — used in finish() to
    // identify records that have been removed from the Workday report
    private Set<String> workdayEmployeeIds = new Set<String>();

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTORS
    // ─────────────────────────────────────────────────────────────────────────

    public BSF_RealIdComplianceBatch() {
    }

    public BSF_RealIdComplianceBatch(Integer batchSize) {
        if (batchSize != null && batchSize > 0) {
            this.batchSize = batchSize;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCHEDULABLE — called by the Salesforce scheduler
    // Prevents duplicate runs if a previous batch is still in progress
    // ─────────────────────────────────────────────────────────────────────────
    public void execute(SchedulableContext sc) {
        System.debug('BSF_RealIdComplianceBatch: Scheduled trigger fired');

        Integer existingBatchCount = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BSF_RealIdComplianceBatch'
            AND JobType = 'BatchApex'
            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];

        if (existingBatchCount == 0) {
            Integer configuredBatchSize = getConfiguredBatchSize();
            BSF_RealIdComplianceBatch batch = new BSF_RealIdComplianceBatch(configuredBatchSize);
            Database.executeBatch(batch, batch.batchSize);
            System.debug('BSF_RealIdComplianceBatch: Batch queued with batch size ' + configuredBatchSize);
        } else {
            System.debug('BSF_RealIdComplianceBatch: Batch already running — skipping this scheduled trigger');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // START
    // Reads the static backfill date from custom settings, calls Workday,
    // and returns the full employee list as the batch iterable scope
    // ─────────────────────────────────────────────────────────────────────────
    public Iterable<WorkdayEmployeeWrapper> start(Database.BatchableContext bc) {
        System.debug('BSF_RealIdComplianceBatch: start() — batch job ID: ' + bc.getJobId());

        // Load the static backfill date that will be sent to Workday as Effective_as_of_Date
        initializeFilterDate();

        // Fetch all employees from the Workday RaaS report
        List<WorkdayEmployeeWrapper> employees = fetchWorkdayData();

        // Populate the full employee ID set now so finish() can use it
        // to detect removals after all execute() chunks have run
        for (WorkdayEmployeeWrapper w : employees) {
            workdayEmployeeIds.add(w.employeeId);
        }

        System.debug('BSF_RealIdComplianceBatch: Workday returned ' + employees.size() + ' employee record(s)');

        return employees;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // EXECUTE
    // Processes one chunk of Workday employees at a time.
    // For each employee:
    //   - If a staging record already exists and data has changed → update it
    //   - If no staging record exists but a matching Resource exists → create it
    //   - If a matching Resource exists and compliance/expiry has changed → update it
    // ─────────────────────────────────────────────────────────────────────────
    public void execute(Database.BatchableContext bc, List<WorkdayEmployeeWrapper> scope) {
        System.debug('BSF_RealIdComplianceBatch: execute() — processing chunk of ' + scope.size() + ' employee(s)');

        // Collect employee IDs in this chunk for targeted SOQL queries
        Set<String> employeeIds = new Set<String>();
        for (WorkdayEmployeeWrapper w : scope) {
            employeeIds.add(w.employeeId);
        }

        // Query existing staging records for employees in this chunk
        // Keyed on Employee_ID__c using a for loop because the Map constructor
        // always keys on the Salesforce record Id, not an external Id field
        Map<String, BSF_Workday_Staging__c> stagingMap = new Map<String, BSF_Workday_Staging__c>();
        for (BSF_Workday_Staging__c s : [
            SELECT Id,
                   Employee_ID__c,
                   Resource__c,
                   Real_ID_Compliant__c,
                   Expiration_Date__c,
                   Workday_Last_Functionally_Updated__c,
                   Workday_Record_Created_Moment__c,
                   Sync_Comment__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c IN :employeeIds
        ]) {
            stagingMap.put(s.Employee_ID__c, s);
        }

        System.debug('BSF_RealIdComplianceBatch: Found ' + stagingMap.size() + ' existing staging record(s) for this chunk');

        // Query matching Resource records for employees in this chunk
        // Keyed on sked_Employee_ID__c using a for loop for the same reason as above
        Map<String, sked__Resource__c> resourceMap = new Map<String, sked__Resource__c>();
        for (sked__Resource__c r : [
            SELECT Id,
                   sked_Employee_ID__c,
                   sked_REAL_ID_Compliant_indicator__c,
                   sked_Real_ID_Expiration_Date__c
            FROM sked__Resource__c
            WHERE sked_Employee_ID__c IN :employeeIds
        ]) {
            resourceMap.put(r.sked_Employee_ID__c, r);
        }

        System.debug('BSF_RealIdComplianceBatch: Found ' + resourceMap.size() + ' matching Resource record(s) for this chunk');

        List<BSF_Workday_Staging__c> stagingToUpsert = new List<BSF_Workday_Staging__c>();
        List<sked__Resource__c> resourcesToUpdate = new List<sked__Resource__c>();

        Date today = System.today();

        for (WorkdayEmployeeWrapper wd : scope) {

            // An employee is compliant if they have no expiration date (no expiry set)
            // or their expiration date is today or in the future
            Boolean compliant = (wd.expirationDate == null || wd.expirationDate >= today);

            if (stagingMap.containsKey(wd.employeeId)) {

                // ── Existing staging record found ──────────────────────────
                // Only update if something has actually changed to avoid
                // unnecessary DML. We check:
                //   - Last_Functionally_Updated: Workday-side change detection
                //   - Real_ID_Compliant__c: catches expiry flipping since last sync
                //     even when Workday has not changed the record itself
                BSF_Workday_Staging__c staging = stagingMap.get(wd.employeeId);

                if (staging.Workday_Last_Functionally_Updated__c != wd.lastUpdated ||
                    staging.Real_ID_Compliant__c != compliant) {

                    System.debug('BSF_RealIdComplianceBatch: Updating staging record for employee ' + wd.employeeId
                        + ' — compliant: ' + compliant + ', expiration: ' + wd.expirationDate);

                    // Build a change log of what actually changed.
                    String fieldChanges = '';
                    if (staging.Workday_Last_Functionally_Updated__c != wd.lastUpdated) {
                        fieldChanges += 'Last_Functionally_Updated: ' + staging.Workday_Last_Functionally_Updated__c + ' → ' + wd.lastUpdated + '; ';
                    }
                    if (staging.Real_ID_Compliant__c != compliant) {
                        fieldChanges += 'Compliant: ' + staging.Real_ID_Compliant__c + ' → ' + compliant + '; ';
                    }
                    if (staging.Expiration_Date__c != wd.expirationDate) {
                        fieldChanges += 'Expiration_Date: ' + staging.Expiration_Date__c + ' → ' + wd.expirationDate + '; ';
                    }
                    staging.Sync_Comment__c = staging.Sync_Comment__c + '\n' + String.valueOf(System.today()) + ': Updated from Workday. Changes: ' + fieldChanges;

                    staging.Workday_Last_Functionally_Updated__c = wd.lastUpdated;
                    staging.Workday_Record_Created_Moment__c     = wd.createdMoment;
                    staging.Expiration_Date__c                   = wd.expirationDate;
                    staging.Real_ID_Compliant__c                 = compliant;
                    staging.Sync_Status__c                       = skedConstants.STAGING_SYNC_STATUS_UPDATED;

                    stagingToUpsert.add(staging);

                } else {
                    System.debug('BSF_RealIdComplianceBatch: No changes detected for employee ' + wd.employeeId + ' — skipping staging update');
                }

            } else if (resourceMap.containsKey(wd.employeeId)) {

                // ── No staging record yet, but a matching Resource exists ──
                // Staging records are only created when a linked Resource record
                // exists in Salesforce; orphaned Workday entries are skipped
                System.debug('BSF_RealIdComplianceBatch: Creating new staging record for employee ' + wd.employeeId
                    + ' — compliant: ' + compliant + ', expiration: ' + wd.expirationDate);

                BSF_Workday_Staging__c newRec        = new BSF_Workday_Staging__c();
                newRec.Employee_ID__c                    = wd.employeeId;
                newRec.Expiration_Date__c                = wd.expirationDate;
                newRec.Workday_Last_Functionally_Updated__c = wd.lastUpdated;
                newRec.Workday_Record_Created_Moment__c  = wd.createdMoment;
                newRec.Real_ID_Compliant__c              = compliant;
                newRec.Sync_Status__c                    = skedConstants.STAGING_SYNC_STATUS_CREATED;
                newRec.Sync_Comment__c                   = String.valueOf(System.today()) + ': 1st time certification synced from Workday';
                newRec.Resource__c                       = resourceMap.get(wd.employeeId).Id;

                stagingToUpsert.add(newRec);

            } else {
                // No Resource record found in Salesforce for this Workday employee — skip
                System.debug('BSF_RealIdComplianceBatch: No Resource record found for employee ' + wd.employeeId + ' — skipping');
            }

            // ── Resource record sync ───────────────────────────────────────
            // Always keep the Resource record in sync with the derived
            // compliance value, regardless of whether staging was updated
            if (resourceMap.containsKey(wd.employeeId)) {

                sked__Resource__c r = resourceMap.get(wd.employeeId);

                if (r.sked_REAL_ID_Compliant_indicator__c != compliant ||
                    r.sked_Real_ID_Expiration_Date__c != wd.expirationDate) {

                    System.debug('BSF_RealIdComplianceBatch: Updating Resource record for employee ' + wd.employeeId
                        + ' — compliant: ' + compliant + ', expiration: ' + wd.expirationDate);

                    r.sked_REAL_ID_Compliant_indicator__c = compliant;
                    r.sked_Real_ID_Expiration_Date__c          = wd.expirationDate;
                    resourcesToUpdate.add(r);
                }
            }
        }

        // Upsert staging records — uses Employee_ID__c external ID as the match key
        if (!stagingToUpsert.isEmpty()) {
            System.debug('BSF_RealIdComplianceBatch: Upserting ' + stagingToUpsert.size() + ' staging record(s)');
            List<Database.UpsertResult> upsertResults = Database.upsert(stagingToUpsert, BSF_Workday_Staging__c.Employee_ID__c, false);
            logUpsertErrors(upsertResults, 'staging upsert');
        }

        // Update Resource records
        if (!resourcesToUpdate.isEmpty()) {
            System.debug('BSF_RealIdComplianceBatch: Updating ' + resourcesToUpdate.size() + ' Resource record(s)');
            List<Database.SaveResult> resourceResults = Database.update(resourcesToUpdate, false);
            logSaveErrors(resourceResults, 'resource update');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // FINISH
    // Detects employees that were previously compliant in Salesforce but are
    // no longer present in the Workday response. These records are unchecked
    // on both the staging and Resource objects and marked as Removed.
    // Also updates Last_Successful_Run_Date__c if no fatal errors occurred.
    // ─────────────────────────────────────────────────────────────────────────
    public void finish(Database.BatchableContext bc) {
        System.debug('BSF_RealIdComplianceBatch: finish() — begin removal detection');

        // Query staging records that are currently compliant but were NOT
        // returned by Workday in this run — these employees have been removed
        // from the Workday report. Filtering on Real_ID_Compliant__c = true
        // avoids loading the entire history of already-removed records
        List<BSF_Workday_Staging__c> removedStagingRecords = [
            SELECT Id, Employee_ID__c, Real_ID_Compliant__c, Resource__c, Sync_Comment__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c NOT IN :workdayEmployeeIds
            AND Real_ID_Compliant__c = true
        ];

        // Query Resource records directly by employee ID rather than going through
        // the staging lookup. This catches resources that may have no staging record
        // but still have compliance checked or an expiration date set
        List<sked__Resource__c> resourcesToUncheck = [
            SELECT Id, sked_REAL_ID_Compliant_indicator__c, sked_Real_ID_Expiration_Date__c
            FROM sked__Resource__c
            WHERE sked_Employee_ID__c NOT IN :workdayEmployeeIds
            AND (sked_REAL_ID_Compliant_indicator__c = true OR sked_Real_ID_Expiration_Date__c != null)
        ];

        // ── Handle removed staging records ────────────────────────────────────
        if (removedStagingRecords.isEmpty()) {
            System.debug('BSF_RealIdComplianceBatch: No staging records found for removed employees');
        } else {
            System.debug('BSF_RealIdComplianceBatch: Detected ' + removedStagingRecords.size() + ' staging record(s) for employees removed from Workday — marking as Removed');

            for (BSF_Workday_Staging__c s : removedStagingRecords) {
                s.Real_ID_Compliant__c = false;
                s.Sync_Status__c       = skedConstants.STAGING_SYNC_STATUS_REMOVED;
                s.Sync_Comment__c      = s.Sync_Comment__c + '\n' + String.valueOf(System.today()) + ': Real ID compliance removed from Workday';
            }

            List<Database.SaveResult> stagingResults = Database.update(removedStagingRecords, false);
            logSaveErrors(stagingResults, 'finish staging removal');
        }

        // ── Handle removed Resource records ───────────────────────────────────
        if (resourcesToUncheck.isEmpty()) {
            System.debug('BSF_RealIdComplianceBatch: No Resource records require unchecking for removed employees');
        } else {
            System.debug('BSF_RealIdComplianceBatch: Unchecking ' + resourcesToUncheck.size() + ' Resource record(s) for employees removed from Workday');

            for (sked__Resource__c r : resourcesToUncheck) {
                r.sked_REAL_ID_Compliant_indicator__c = false;
                r.sked_Real_ID_Expiration_Date__c          = null;
            }

            List<Database.SaveResult> resourceResults = Database.update(resourcesToUncheck, false);
            logSaveErrors(resourceResults, 'finish resource uncheck');
        }

        // Only update the last successful run date if no fatal error occurred
        // during start() or execute(). If a fatal error aborted the batch,
        // finish() may still run but we do not want to advance the run date
        if (String.isBlank(errorMessage)) {
            updateLastSuccessfulRunDate();
        } else {
            System.debug('BSF_RealIdComplianceBatch: Skipping Last_Successful_Run_Date__c update due to fatal error — ' + errorMessage);
        }

        System.debug('BSF_RealIdComplianceBatch: finish() complete');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // WORKDAY CALLOUT
    // Resolves the endpoint (custom metadata → hardcoded fallback), appends
    // the static date filter and format parameter, then calls the RaaS API
    // ─────────────────────────────────────────────────────────────────────────
    private List<WorkdayEmployeeWrapper> fetchWorkdayData() {

        // Attempt to read the endpoint from custom metadata so it can be
        // changed without a code deployment
        String endpoint;
        try {
            sked_Workday_XML_Template__mdt xml = [
                SELECT sked_Endpoint__c
                FROM sked_Workday_XML_Template__mdt
                WHERE DeveloperName = 'RealID_Compliance_Report'
                LIMIT 1
            ];

            if (xml != null && String.isNotBlank(xml.sked_Endpoint__c)) {
                endpoint = xml.sked_Endpoint__c;
                System.debug('BSF_RealIdComplianceBatch: Using endpoint from custom metadata — ' + endpoint);
            }
        } catch (Exception mdEx) {
            System.debug('BSF_RealIdComplianceBatch: Could not read custom metadata endpoint, falling back to hardcoded default — ' + mdEx.getMessage());
        }

        // Append the static backfill date filter (Effective_as_of_Date) if configured.
        // This is always a fixed date so the full dataset is returned on every run,
        // which is required for accurate removal detection in finish()
        if (filterDate != null) {
            String encodedDate = EncodingUtil.urlEncode(String.valueOf(filterDate), 'UTF-8');
            String separator   = endpoint.contains('?') ? '&' : '?';
            endpoint += separator + 'Effective_as_of_Date=' + encodedDate + '&format=json';
            System.debug('BSF_RealIdComplianceBatch: Calling Workday with date filter — ' + endpoint);
        } else {
            String separator = endpoint.contains('?') ? '&' : '?';
            endpoint += separator + 'format=json';
            System.debug('BSF_RealIdComplianceBatch: Calling Workday without date filter — ' + endpoint);
        }

        HttpRequest req = skedWorkdayApiManager.getHttpRequest(endpoint, 'GET');
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setHeader('Accept', 'application/json');

        Http h = new Http();
        HttpResponse res = h.send(req);

        String responseBody = res.getBody();

        if (res.getStatusCode() >= 200 && res.getStatusCode() <= 299) {
            System.debug('BSF_RealIdComplianceBatch: Workday API call successful — HTTP ' + res.getStatusCode());
            System.debug('BSF_RealIdComplianceBatch: Response body — ' + responseBody);
        } else {
            errorMessage = 'Workday API call failed — HTTP ' + res.getStatusCode() + ' — ' + responseBody;
            System.debug('BSF_RealIdComplianceBatch: ' + errorMessage);
            throw new CalloutException(errorMessage);
        }

        return parseWorkdayResponse(responseBody);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PARSE WORKDAY RESPONSE
    // Deserialises the JSON Report_Entry array into WorkdayEmployeeWrapper list.
    // Each date/datetime field is parsed in its own try/catch so a single
    // malformed value does not abort processing the entire response
    // ─────────────────────────────────────────────────────────────────────────
    private List<WorkdayEmployeeWrapper> parseWorkdayResponse(String jsonBody) {

        List<WorkdayEmployeeWrapper> result = new List<WorkdayEmployeeWrapper>();

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

        if (!root.containsKey('Report_Entry')) {
            System.debug('BSF_RealIdComplianceBatch: No Report_Entry key found in Workday response — nothing to process');
            return result;
        }

        List<Object> entries = (List<Object>) root.get('Report_Entry');

        System.debug('BSF_RealIdComplianceBatch: Parsing ' + entries.size() + ' Report_Entry record(s)');

        for (Object o : entries) {

            Map<String, Object> entry = (Map<String, Object>) o;

            WorkdayEmployeeWrapper w = new WorkdayEmployeeWrapper();
            w.employeeId = (String) entry.get('Employee_ID');

            // Skip records without a valid Employee_ID — they cannot be matched
            if (String.isBlank(w.employeeId)) {
                System.debug('BSF_RealIdComplianceBatch: Skipping entry with blank Employee_ID');
                continue;
            }

            // Expiration_Date — optional; null means no expiry (treated as compliant)
            if (entry.containsKey('Expiration_Date') && entry.get('Expiration_Date') != null) {
                try {
                    w.expirationDate = Date.valueOf((String) entry.get('Expiration_Date'));
                } catch (Exception e) {
                    System.debug('BSF_RealIdComplianceBatch: Could not parse Expiration_Date for employee ' + w.employeeId + ' — ' + e.getMessage());
                }
            }

            // Last_Functionally_Updated — used to detect Workday-side changes
            // between runs without reprocessing unchanged records
            if (entry.containsKey('Last_Functionally_Updated') && entry.get('Last_Functionally_Updated') != null) {
                try {
                    String raw = (String) entry.get('Last_Functionally_Updated');
                    // Workday sends ISO 8601 with timezone offset e.g. 2026-02-13T10:33:54.582-08:00
                    // Trim to 'YYYY-MM-DD HH:MM:SS' which DateTime.valueOf() accepts
                    w.lastUpdated = DateTime.valueOf(raw.replace('T', ' ').substring(0, 19));
                } catch (Exception e) {
                    System.debug('BSF_RealIdComplianceBatch: Could not parse Last_Functionally_Updated for employee ' + w.employeeId + ' — ' + e.getMessage());
                }
            }

            // Created_Moment — stored on the staging record for audit purposes
            if (entry.containsKey('Created_Moment') && entry.get('Created_Moment') != null) {
                try {
                    String raw = (String) entry.get('Created_Moment');
                    w.createdMoment = DateTime.valueOf(raw.replace('T', ' ').substring(0, 19));
                } catch (Exception e) {
                    System.debug('BSF_RealIdComplianceBatch: Could not parse Created_Moment for employee ' + w.employeeId + ' — ' + e.getMessage());
                }
            }

            result.add(w);
        }

        System.debug('BSF_RealIdComplianceBatch: Successfully parsed ' + result.size() + ' employee record(s) from response');

        return result;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZE FILTER DATE
    // Reads the static backfill date from BSF_Workday_RealID_Config__c.
    // This date is always fixed (not incremental) so the full Workday dataset
    // is returned on every run, which is required for removal detection
    // ─────────────────────────────────────────────────────────────────────────
    private void initializeFilterDate() {
        try {
            BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();

            if (config != null && config.Initial_Backfill_Date__c != null) {
                filterDate = config.Initial_Backfill_Date__c;
                System.debug('BSF_RealIdComplianceBatch: Using configured backfill date — ' + String.valueOf(filterDate));
            }

            if (filterDate == null) {
                // Safety fallback: use 5 years back if no date is configured
                filterDate = System.today().addYears(-5);
                System.debug('BSF_RealIdComplianceBatch: No backfill date configured — defaulting to 5 years back: ' + String.valueOf(filterDate));
            }
        } catch (Exception e) {
            // Do not let a config read failure abort the batch — fall back to default
            filterDate = System.today().addYears(-5);
            System.debug('BSF_RealIdComplianceBatch: Error reading config, defaulting to 5 years back — ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET CONFIGURED BATCH SIZE
    // Reads batch size from custom setting; falls back to DEFAULT_BATCH_SIZE
    // ─────────────────────────────────────────────────────────────────────────
    private static Integer getConfiguredBatchSize() {
        Integer configuredBatchSize;

        try {
            BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
            if (config != null && config.Batch_Size__c != null && config.Batch_Size__c > 0) {
                configuredBatchSize = config.Batch_Size__c.intValue();
            }
        } catch (Exception e) {
            System.debug('BSF_RealIdComplianceBatch: Error reading batch size from config — ' + e.getMessage());
        }

        if (configuredBatchSize == null || configuredBatchSize <= 0) {
            configuredBatchSize = DEFAULT_BATCH_SIZE;
        }

        System.debug('BSF_RealIdComplianceBatch: Using batch size ' + configuredBatchSize);

        return configuredBatchSize;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UPDATE LAST SUCCESSFUL RUN DATE
    // Stamps today's date on the custom setting so it can be referenced for
    // reporting. Only called when no fatal error occurred during the run
    // ─────────────────────────────────────────────────────────────────────────
    private void updateLastSuccessfulRunDate() {
        try {
            BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
            config.Last_Successful_Run_Date__c = System.today();
            upsert config;
            System.debug('BSF_RealIdComplianceBatch: Last_Successful_Run_Date__c updated to ' + String.valueOf(config.Last_Successful_Run_Date__c));
        } catch (Exception e) {
            // Config update failure should not cause the batch to fail
            System.debug('BSF_RealIdComplianceBatch: Could not update Last_Successful_Run_Date__c — ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ERROR LOGGING HELPERS
    // Logs DML errors to both System.debug and the sked__Debug_Log__c object
    // so that errors are visible in the Debug Log UI for support and monitoring.
    // Uses Database.insert with allOrNone = false so a failure to write the
    // log record never causes the batch itself to fail.
    // ─────────────────────────────────────────────────────────────────────────

    private void logUpsertErrors(List<Database.UpsertResult> results, String context) {
        List<sked__Debug_Log__c> logsToInsert = new List<sked__Debug_Log__c>();

        for (Database.UpsertResult ur : results) {
            if (!ur.isSuccess()) {
                for (Database.Error err : ur.getErrors()) {
                    String errorDetail = 'Status Code: ' + err.getStatusCode() + ' — ' + err.getMessage();
                    System.debug('BSF_RealIdComplianceBatch: DML error [' + context + '] — ' + errorDetail);

                    logsToInsert.add(buildDebugLog(context, errorDetail));
                }
            }
        }

        if (!logsToInsert.isEmpty()) {
            Database.insert(logsToInsert, false);
        }
    }

    private void logSaveErrors(List<Database.SaveResult> results, String context) {
        List<sked__Debug_Log__c> logsToInsert = new List<sked__Debug_Log__c>();

        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    String errorDetail = 'Status Code: ' + err.getStatusCode() + ' — ' + err.getMessage();
                    System.debug('BSF_RealIdComplianceBatch: DML error [' + context + '] — ' + errorDetail);

                    logsToInsert.add(buildDebugLog(context, errorDetail));
                }
            }
        }

        if (!logsToInsert.isEmpty()) {
            Database.insert(logsToInsert, false);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // BUILD DEBUG LOG
    // Centralises the construction of a sked__Debug_Log__c record so both
    // logUpsertErrors and logSaveErrors produce consistent log entries.
    // ─────────────────────────────────────────────────────────────────────────
    private sked__Debug_Log__c buildDebugLog(String context, String errorDetail) {
        sked__Debug_Log__c log      = new sked__Debug_Log__c();
        log.sked__Type__c           = 'Error Log';
        log.sked_Category__c        = 'System Error';
        log.sked__Summary__c        = 'BSF_RealIdComplianceBatch DML error [' + context + ']';
        log.sked__Message__c        = errorDetail;
        log.sked_Request__c         = 'Batch context: ' + context;
        return log;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // WRAPPER CLASS
    // Holds data parsed from a single Workday Report_Entry record
    // ─────────────────────────────────────────────────────────────────────────
    public class WorkdayEmployeeWrapper {
        public String   employeeId;    // Workday Employee_ID
        public Date     expirationDate; // REAL ID expiration date (null = no expiry)
        public DateTime lastUpdated;   // Workday Last_Functionally_Updated
        public DateTime createdMoment; // Workday Created_Moment
    }
}











/*
// Batch job to sync REAL ID compliance from Workday
// Pulls employee data from Workday API and updates Resource records
// Schedule example: String cronExp = '0 0 2 * * ?'; // runs at 2 AM
// BSF_RealIdComplianceBatch batch = new BSF_RealIdComplianceBatch();
// System.schedule('Real ID Sync', cronExp, batch);
public class BSF_RealIdComplianceBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {
    
    // Base Workday URL for the REAL ID custom report (no query params)
    private static final String WORKDAY_REALID_ENDPOINT = 'https://wd2-impl-services1.workday.com/ccx/service/customreport2/americanredcross1/A1014901/BSF_-_REAL_ID_Tracker';
    private static final Integer DEFAULT_BATCH_SIZE = 200;
    
    private Integer batchSize = DEFAULT_BATCH_SIZE;
    
    // Date filter for Workday API - only get records updated after this date
    private Date filterDate;
    
    // Store employee data from Workday - maps employee ID to expiration date
    private Map<String, Date> workdayEmployeeData;
    
    // Track stats for debugging
    private Integer totalResourcesProcessed = 0;
    private Integer resourcesUpdated = 0;
    private Integer errors = 0;
    private String errorMessage;
    
    public BSF_RealIdComplianceBatch() {
        this.workdayEmployeeData = new Map<String, Date>();
    }
    
    public BSF_RealIdComplianceBatch(Integer batchSize) {
        this.workdayEmployeeData = new Map<String, Date>();
        if (batchSize != null && batchSize > 0) {
            this.batchSize = batchSize;
        }
    }
    
    // Called when the scheduled job runs
    public void execute(SchedulableContext sc) {
        System.debug('Starting scheduled run');
        
        // Check if batch is already running to avoid duplicates
        Integer existingBatchCount = [
            SELECT COUNT() 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'BSF_RealIdComplianceBatch' 
            AND JobType = 'BatchApex' 
            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];
        
        if (existingBatchCount == 0) {
            Integer configuredBatchSize = getConfiguredBatchSize();
            BSF_RealIdComplianceBatch batch = new BSF_RealIdComplianceBatch(configuredBatchSize);
            Database.executeBatch(batch, batch.batchSize);
            System.debug('Batch queued');
        } else {
            System.debug('Batch already running, skipping');
        }
    }
    
    // Start method - fetches Workday data and queries matching resources
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting batch');
        
        // Get the date filter from custom setting
        initializeFilterDate();
        
        // Call Workday API to get employee data
        fetchWorkdayData();
        
        System.debug('Got ' + workdayEmployeeData.size() + ' employee records from Workday');
        
        // Only process resources that are in the Workday report
        if (workdayEmployeeData.isEmpty()) {
            // No data from Workday, return empty query
            return Database.getQueryLocator('SELECT Id FROM sked__Resource__c WHERE Id = null');
        }
        
        // Build the IN clause for employee IDs
        List<String> workdayEmployeeIds = new List<String>(workdayEmployeeData.keySet());
        String employeeIdsStr = '';
        for (String empId : workdayEmployeeIds) {
            if (String.isNotBlank(employeeIdsStr)) {
                employeeIdsStr += ', ';
            }
            employeeIdsStr += '\'' + String.escapeSingleQuotes(empId) + '\'';
        }
        
        String query = 'SELECT Id, sked_Employee_ID__c, sked_REAL_ID_Compliant_indicator__c, sked_Real_ID_Expiration_Date__c ' +
                       'FROM sked__Resource__c ' +
                       'WHERE sked_Employee_ID__c != null ' +
                       'AND sked_Employee_ID__c != \'\' ' +
                       'AND sked_Employee_ID__c IN (' + employeeIdsStr + ')';
        
        return Database.getQueryLocator(query);
    }
    
    // Process each batch of resources
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<sked__Resource__c> resources = (List<sked__Resource__c>) scope;
        System.debug('Processing ' + resources.size() + ' resources');
        
        List<sked__Resource__c> resourcesToUpdate = new List<sked__Resource__c>();
        
        for (sked__Resource__c resource : resources) {
            try {
                // Get expiration date from Workday data
                Date expirationDate = workdayEmployeeData.get(resource.sked_Employee_ID__c);
                
                Boolean needsUpdate = false;
                
                // Set compliance to true since they're in the Workday report
                if (resource.sked_REAL_ID_Compliant_indicator__c != true) {
                    resource.sked_REAL_ID_Compliant_indicator__c = true;
                    needsUpdate = true;
                }
                
                // Update expiration date if changed
                if (resource.sked_Real_ID_Expiration_Date__c != expirationDate) {
                    resource.sked_Real_ID_Expiration_Date__c = expirationDate;
                    needsUpdate = true;
                }
                
                if (needsUpdate) {
                    resourcesToUpdate.add(resource);
                    resourcesUpdated++;
                }
                
                totalResourcesProcessed++;
            } catch (Exception e) {
                errors++;
                System.debug('Error with resource ' + resource.Id + ': ' + e.getMessage());
            }
        }
        
        if (!resourcesToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(resourcesToUpdate, false);
            
            // Check for any update failures
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    errors++;
                    String errorMsg = 'Failed to update resource ' + resourcesToUpdate[i].Id + ': ';
                    for (Database.Error err : results[i].getErrors()) {
                        errorMsg += err.getMessage() + ' ';
                    }
                    System.debug(errorMsg);
                }
            }
        }
    }
    
    // Called when batch finishes
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch finished');
        System.debug('Processed ' + totalResourcesProcessed + ' resources total');
        System.debug('Updated ' + resourcesUpdated + ' resources');
        System.debug('Errors: ' + errors);
        
        if (String.isNotBlank(errorMessage)) {
            System.debug('Error: ' + errorMessage);
        }
        
        // Update the last successful run date only if no errors
        // If there was a fatal error, finish() might not even run
        if (String.isBlank(errorMessage)) {
            updateLastSuccessfulRunDate();
        } else {
            System.debug('Not updating Last_Successful_Run_Date__c due to errors');
        }
    }
    
    // Call Workday API to get REAL ID data
    private void fetchWorkdayData() {
        try {
            // Try to get the REAL ID report endpoint from custom metadata first
            String endpoint;
            try {
                sked_Workday_XML_Template__mdt xml = [
                    SELECT sked_Endpoint__c
                    FROM sked_Workday_XML_Template__mdt
                    WHERE DeveloperName = 'RealID_Compliance_Report'
                    LIMIT 1
                ];
                
                if (xml != null && String.isNotBlank(xml.sked_Endpoint__c)) {
                    endpoint = xml.sked_Endpoint__c;
                    System.debug('Using REAL ID endpoint from sked_Workday_XML_Template__mdt: ' + endpoint);
                }
            } catch (Exception mdEx) {
                System.debug('Could not read sked_Workday_XML_Template__mdt for RealID_Compliance_Report, will fall back to default: ' + mdEx.getMessage());
            }
            
            // If metadata is missing or blank, fall back to the hardcoded base REAL ID report endpoint
            if (String.isBlank(endpoint)) {
                endpoint = WORKDAY_REALID_ENDPOINT;
                System.debug('Using default REAL ID endpoint: ' + endpoint);
            }
            
            // Add date filter if we have one
            if (filterDate != null) {
                // Workday expects an \"Effective_as_of_Date\" parameter in this format:
                // 2018-06-25
                String datePart = String.valueOf(filterDate);
                String effectiveDateTime = datePart;
                
                String paramName = 'Effective_as_of_Date';
                
                String encodedDate = EncodingUtil.urlEncode(effectiveDateTime, 'UTF-8');
                if (endpoint.contains('?')) {
                    endpoint += '&' + paramName + '=' + encodedDate;
                } else {
                    endpoint += '?' + paramName + '=' + encodedDate;
                }
                
                // Always ask for JSON back
                endpoint += '&format=json';
                
                System.debug('Calling Workday REAL ID report with date filter: ' + endpoint);
            } else {
                // No date filter, just add format
                if (endpoint.contains('?')) {
                    endpoint += '&format=json';
                } else {
                    endpoint += '?format=json';
                }
                
                System.debug('Calling Workday REAL ID report without date filter: ' + endpoint);
            }
            
            HttpRequest req = skedWorkdayApiManager.getHttpRequest(endpoint, 'GET');
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setHeader('Accept', 'application/json');
            
            Http h = new Http();
            HttpResponse res = h.send(req);
            
            if (res.getStatusCode() >= 200 && res.getStatusCode() <= 299) {
                String responseBody = res.getBody();
                 System.debug(responseBody);

                System.debug('Got response from Workday');
                
                parseWorkdayResponse(responseBody);
            } else {
                errorMessage = 'Workday API call failed with status code: ' + res.getStatusCode() + ' - ' + res.getBody();
                System.debug(errorMessage);
                throw new CalloutException(errorMessage);
            }
        } catch (Exception e) {
            errorMessage = 'Error calling Workday API: ' + e.getMessage();
            System.debug(errorMessage);
            throw new CalloutException(errorMessage, e);
        }
    }
    
    // Parse the JSON response from Workday
    // Expected format: { "Report_Entry": [ { "Employee_ID": "123", "Real_ID_Expiration_Date": "2025-12-31" }, ... ] }
    private void parseWorkdayResponse(String jsonResponse) {
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            
            if (!root.containsKey('Report_Entry')) {
                System.debug('No Report_Entry found in response');
                return;
            }
            
            Object reportEntryObj = root.get('Report_Entry');
            if (!(reportEntryObj instanceof List<Object>)) {
                System.debug('Report_Entry is not an array');
                return;
            }
            
            List<Object> reportEntries = (List<Object>) reportEntryObj;
            
            if (reportEntries.isEmpty()) {
                System.debug('Report_Entry is empty');
                return;
            }
            
            // Field name might vary - adjust if needed
            String expirationDateFieldName = 'Expiration_Date';
            
            for (Object entry : reportEntries) {
                if (entry instanceof Map<String, Object>) {
                    Map<String, Object> entryMap = (Map<String, Object>) entry;
                    
                    // Get employee ID
                    String employeeId = null;
                    if (entryMap.containsKey('Employee_ID')) {
                        Object empIdObj = entryMap.get('Employee_ID');
                        if (empIdObj != null) {
                            employeeId = String.valueOf(empIdObj).trim();
                        }
                    }
                    
                    if (String.isNotBlank(employeeId)) {
                        // Try to get expiration date
                        Date expirationDate = null;
                        if (entryMap.containsKey(expirationDateFieldName)) {
                            Object expDateObj = entryMap.get(expirationDateFieldName);
                            if (expDateObj != null) {
                                try {
                                    String dateStr = String.valueOf(expDateObj).trim();
                                    if (String.isNotBlank(dateStr)) {
                                        expirationDate = Date.valueOf(dateStr);
                                    }
                                } catch (Exception dateEx) {
                                    System.debug('Error parsing date for employee ' + employeeId + ': ' + dateEx.getMessage());
                                }
                            }
                        }
                        
                        // Store it (expiration date can be null)
                        workdayEmployeeData.put(employeeId, expirationDate);
                    }
                }
            }
            
            System.debug('Parsed ' + workdayEmployeeData.size() + ' employee records');
            
        } catch (Exception e) {
            errorMessage = 'Error parsing Workday response: ' + e.getMessage();
            System.debug(errorMessage);
            System.debug('Response: ' + jsonResponse);
            throw new JSONException(errorMessage, e);
        }
    }
    
    // Set the filter date from custom setting
    // Uses Last_Successful_Run_Date if available, otherwise Initial_Backfill_Date, or defaults to 1 year back
    private void initializeFilterDate() {
        if (filterDate != null) {
            return;
        }
        
        try {
            BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
            
            if (config != null) {
                if (config.Last_Successful_Run_Date__c != null) {
                    filterDate = config.Last_Successful_Run_Date__c;
                } else if (config.Initial_Backfill_Date__c != null) {
                    filterDate = config.Initial_Backfill_Date__c;
                }
            }
            
            if (filterDate == null) {
                // Default to 1 year back if nothing configured
                filterDate = System.today().addYears(-1);
                System.debug('No config found, using default 1 year back: ' + String.valueOf(filterDate));
            } else {
                System.debug('Using filter date: ' + String.valueOf(filterDate));
            }
        } catch (Exception e) {
            // Fallback to default on error
            filterDate = System.today().addYears(-1);
            System.debug('Error reading config, using default: ' + e.getMessage());
        }
    }
    
    // Update the last successful run date in custom setting
    // Only called when batch completes successfully
    private void updateLastSuccessfulRunDate() {
        try {
            BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
            
            config.Last_Successful_Run_Date__c = System.today();
            
            upsert config;
            System.debug('Updated Last_Successful_Run_Date__c to ' + String.valueOf(config.Last_Successful_Run_Date__c));
        } catch (Exception e) {
            // Don't fail the batch if config update fails
            System.debug('Could not update config: ' + e.getMessage());
        }
    }
    
    // Get batch size from custom setting, default to 200 if not set
    private static Integer getConfiguredBatchSize() {
        Integer configuredBatchSize;
        
        try {
            BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults() ;
            if (config != null && config.Batch_Size__c != null && config.Batch_Size__c > 0) {
                configuredBatchSize = config.Batch_Size__c.intValue();
            }
        } catch (Exception e) {
            System.debug('Error getting batch size from config: ' + e.getMessage());
        }
        
        if (configuredBatchSize == null || configuredBatchSize <= 0) {
            configuredBatchSize = DEFAULT_BATCH_SIZE;
        }
        
        return configuredBatchSize;
    }
    
}
*/