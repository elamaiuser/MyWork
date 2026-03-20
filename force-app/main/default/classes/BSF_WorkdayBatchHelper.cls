// ─────────────────────────────────────────────────────────────────────────────
// BSF_WorkdayBatchHelper
//
// Purpose : Shared static utility class for all Workday RaaS report sync
//           batch jobs. Centralises logic that would otherwise be duplicated
//           across BSF_RealIdComplianceBatch, BSF_LeaveReturnBatch, and any
//           future Workday sync batch.
//
//           Responsibilities:
//             - HTTP callout to the Workday RaaS API
//             - JSON response parsing into WorkdayEmployeeWrapper
//             - Workday datetime / date string parsing helpers
//             - BSF_Workday_Staging__c record construction helpers
//             - DML error logging to System.debug and sked__Debug_Log__c
//             - Duplicate-run prevention utility
//
//           Each batch class remains standalone and calls into this helper
//           for shared work. The helper has no state — all methods are static.
//
// Usage:
//   List<BSF_WorkdayBatchHelper.WorkdayEmployeeWrapper> employees =
//       BSF_WorkdayBatchHelper.fetchWorkdayData(endpoint, 'BSF_LeaveReturnBatch');
// ─────────────────────────────────────────────────────────────────────────────
public class BSF_WorkdayBatchHelper {

    // Employment status value used to exclude Inactive resources from the
    // resource map query. There is no value in syncing Workday data to a
    // resource that is already permanently deactivated in Salesforce.
    // Sourced from skedConstants so the value stays consistent with the
    // rest of the Skedulo package rather than being hardcoded here.
    private static final String INACTIVE_STATUS = skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE;

    // ─────────────────────────────────────────────────────────────────────────
    // WRAPPER CLASS
    // Shared data container for a single Workday Report_Entry record.
    // employeeId is always populated by parseWorkdayResponse().
    // All other JSON fields — including Last_Functionally_Updated, Created_Moment,
    // and any domain-specific fields such as Expiration_Date or
    // Eastimated_Last_Day_Of_Leave — are stored as raw strings in extraFields.
    // Each batch class retrieves the fields it needs using the typed helpers:
    //   getExtraDate()     — for date fields (YYYY-MM-DD)
    //   getExtraDateTime() — for ISO 8601 datetime fields
    //   getExtraString()   — for raw string fields
    // ─────────────────────────────────────────────────────────────────────────
    public class WorkdayEmployeeWrapper {
        public String              employeeId;  // Workday Employee_ID — match key against sked_Employee_ID__c
        // All remaining JSON fields from the Report_Entry record.
        // Key   = Workday JSON field name (e.g. 'Expiration_Date')
        // Value = raw string value as returned by Workday
        public Map<String, String> extraFields = new Map<String, String>();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HTTP CALLOUT
    // Calls the Workday RaaS endpoint and returns a parsed employee list.
    // Throws CalloutException on a non-2xx response so the batch's start()
    // can set errorMessage and prevent Last_Successful_Run_Date__c from
    // being stamped on a failed run.
    //
    // @param endpoint  Fully-qualified URL including all query parameters
    // @param jobLabel  Calling batch class name used as a prefix in all
    //                  System.debug and sked__Debug_Log__c entries
    // ─────────────────────────────────────────────────────────────────────────
    public static List<WorkdayEmployeeWrapper> fetchWorkdayData(String endpoint, String jobLabel) {
        System.debug(jobLabel + ': Calling Workday endpoint — ' + endpoint);

        HttpRequest req = skedWorkdayApiManager.getHttpRequest(endpoint, 'GET');
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setHeader('Accept', 'application/json');

        Http         h   = new Http();
        HttpResponse res = h.send(req);

        String responseBody = res.getBody();

        if (res.getStatusCode() >= 200 && res.getStatusCode() <= 299) {
            System.debug(jobLabel + ': Workday API call successful — HTTP ' + res.getStatusCode());
        } else {
            String msg = 'Workday API call failed — HTTP ' + res.getStatusCode() + ' — ' + responseBody;
            System.debug(jobLabel + ': ' + msg);
            throw new CalloutException(msg);
        }

        return parseWorkdayResponse(responseBody, jobLabel);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // JSON PARSING
    // Deserialises the Workday Report_Entry array into a list of wrappers.
    // Always populates employeeId. All other fields — including
    // Last_Functionally_Updated, Created_Moment, and any domain-specific
    // date fields — are stored as raw strings in extraFields. Each batch
    // class retrieves what it needs using getExtraDate() / getExtraDateTime()
    // / getExtraString() rather than the helper needing to know about them.
    //
    // Records with a blank Employee_ID are skipped since they cannot be
    // matched to a Resource record in Salesforce.
    //
    // @param jsonBody  Raw JSON string from the Workday API response body
    // @param jobLabel  Calling batch class name for debug log prefixing
    // ─────────────────────────────────────────────────────────────────────────
    public static List<WorkdayEmployeeWrapper> parseWorkdayResponse(String jsonBody, String jobLabel) {
        List<WorkdayEmployeeWrapper> result = new List<WorkdayEmployeeWrapper>();

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

        if (!root.containsKey('Report_Entry')) {
            System.debug(jobLabel + ': No Report_Entry key found in Workday response — nothing to process');
            return result;
        }

        List<Object> entries = (List<Object>) root.get('Report_Entry');
        System.debug(jobLabel + ': Parsing ' + entries.size() + ' Report_Entry record(s)');

        for (Object o : entries) {
            Map<String, Object> entry = (Map<String, Object>) o;

            WorkdayEmployeeWrapper w = new WorkdayEmployeeWrapper();
            w.employeeId = (String) entry.get('Employee_ID');

            // Skip records with no Employee_ID — they cannot be matched to a Resource
            if (String.isBlank(w.employeeId)) {
                System.debug(jobLabel + ': Skipping entry with blank Employee_ID');
                continue;
            }

            // Store all fields except Employee_ID in extraFields.
            // Null values are omitted — extraFields only contains fields that
            // Workday actually returned with a value in this response.
            for (String key : entry.keySet()) {
                if (key == 'Employee_ID') {
                    continue;
                }
                Object val = entry.get(key);
                if (val != null) {
                    w.extraFields.put(key, String.valueOf(val));
                }
            }

            result.add(w);
        }

        System.debug(jobLabel + ': Successfully parsed ' + result.size() + ' employee record(s) from response');
        return result;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DATE / DATETIME PARSING HELPERS
    // Each method uses an isolated try/catch so a single malformed value in
    // one record never aborts processing the rest of the response.
    // ─────────────────────────────────────────────────────────────────────────

    // Parses a Workday ISO 8601 datetime string into a Salesforce DateTime.
    // Workday sends values with a timezone offset e.g. 2026-02-13T10:33:54.582-08:00.
    // The string is trimmed to 'YYYY-MM-DD HH:MM:SS' before calling DateTime.valueOf()
    // because Apex's DateTime.valueOf() does not accept the full ISO 8601 format.
    // Returns null if the input is blank or unparseable.
    //
    // @param raw        Raw datetime string from the Workday JSON field
    // @param fieldName  Workday JSON field name — used in the debug log on failure
    // @param empId      Employee ID — used in the debug log on failure
    // @param jobLabel   Calling batch class name for debug log prefixing
    public static DateTime parseWorkdayDatetime(String raw, String fieldName, String empId, String jobLabel) {
        if (String.isBlank(raw)) {
            return null;
        }
        try {
            return DateTime.valueOf(raw.replace('T', ' ').substring(0, 19));
        } catch (Exception e) {
            System.debug(jobLabel + ': Could not parse ' + fieldName + ' for employee ' + empId + ' — ' + e.getMessage());
            return null;
        }
    }

    // Parses a Workday date string in YYYY-MM-DD format into a Salesforce Date.
    // Returns null if the input is blank or unparseable.
    //
    // @param raw        Raw date string from the Workday JSON field
    // @param fieldName  Workday JSON field name — used in the debug log on failure
    // @param empId      Employee ID — used in the debug log on failure
    // @param jobLabel   Calling batch class name for debug log prefixing
    public static Date parseWorkdayDate(String raw, String fieldName, String empId, String jobLabel) {
        if (String.isBlank(raw)) {
            return null;
        }
        try {
            return Date.valueOf(raw);
        } catch (Exception e) {
            System.debug(jobLabel + ': Could not parse ' + fieldName + ' for employee ' + empId + ' — ' + e.getMessage());
            return null;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // EXTRA FIELD HELPERS
    // Convenience methods for batch classes to retrieve typed values from
    // WorkdayEmployeeWrapper.extraFields by Workday JSON field name.
    // All three methods return null rather than throwing if the key is absent
    // or the value cannot be parsed, so the calling batch can decide whether
    // a null value is a skip condition or a valid state (e.g. no expiry date).
    // ─────────────────────────────────────────────────────────────────────────

    // Returns a parsed Date from extraFields for the given Workday JSON field name.
    // Returns null if the key is missing, the value is blank, or parsing fails.
    //
    // @param w         Wrapper containing the extraFields map
    // @param key       Workday JSON field name e.g. 'Expiration_Date'
    // @param jobLabel  Calling batch class name for debug log prefixing
    public static Date getExtraDate(WorkdayEmployeeWrapper w, String key, String jobLabel) {
        if (!w.extraFields.containsKey(key) || String.isBlank(w.extraFields.get(key))) {
            return null;
        }
        return parseWorkdayDate(w.extraFields.get(key), key, w.employeeId, jobLabel);
    }

    // Returns a parsed DateTime from extraFields for the given Workday JSON field name.
    // Returns null if the key is missing, the value is blank, or parsing fails.
    //
    // @param w         Wrapper containing the extraFields map
    // @param key       Workday JSON field name e.g. 'Last_Functionally_Updated'
    // @param jobLabel  Calling batch class name for debug log prefixing
    public static DateTime getExtraDateTime(WorkdayEmployeeWrapper w, String key, String jobLabel) {
        if (!w.extraFields.containsKey(key) || String.isBlank(w.extraFields.get(key))) {
            return null;
        }
        return parseWorkdayDatetime(w.extraFields.get(key), key, w.employeeId, jobLabel);
    }

    // Returns the raw String value from extraFields for the given key,
    // or null if the key is not present in the map.
    //
    // @param w    Wrapper containing the extraFields map
    // @param key  Workday JSON field name
    public static String getExtraString(WorkdayEmployeeWrapper w, String key) {
        return w.extraFields.containsKey(key) ? w.extraFields.get(key) : null;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MAP BUILDERS
    // Both maps are built with explicit for loops rather than using the Map
    // constructor because the Map constructor always keys on the Salesforce
    // record Id, not on external Id or custom lookup fields.
    // ─────────────────────────────────────────────────────────────────────────

    // Builds a Map<employeeId, BSF_Workday_Staging__c> for the given employee
    // IDs, filtered by the staging record type DeveloperName so that REAL ID
    // and Leave staging records are never mixed in the same map.
    //
    // Base fields always selected: Id, Employee_ID__c, Resource__c, Sync_Comment__c.
    // Each batch class passes its own additionalFields list for the domain-specific
    // fields it needs (e.g. Real_ID_Compliant__c for the REAL ID batch).
    //
    // @param employeeIds              Set of Workday employee ID strings for this chunk
    // @param recordTypeDeveloperName  DeveloperName of the staging record type to filter by
    // @param additionalFields         Extra fields to SELECT beyond the base set
    public static Map<String, BSF_Workday_Staging__c> buildStagingMap(
        Set<String>  employeeIds,
        String       recordTypeDeveloperName,
        List<String> additionalFields
    ) {
        List<String> fields = new List<String>{
            'Id',
            'Employee_ID__c',
            'Resource__c',
            'Sync_Comment__c'
        };
        if (additionalFields != null) {
            fields.addAll(additionalFields);
        }

        String soql = 'SELECT ' + String.join(fields, ', ')
            + ' FROM BSF_Workday_Staging__c'
            + ' WHERE Employee_ID__c IN :employeeIds'
            + ' AND RecordType.DeveloperName = \'' + String.escapeSingleQuotes(recordTypeDeveloperName) + '\'';

        Map<String, BSF_Workday_Staging__c> stagingMap = new Map<String, BSF_Workday_Staging__c>();
        for (BSF_Workday_Staging__c s : Database.query(soql)) {
            stagingMap.put(s.Employee_ID__c, s);
        }
        return stagingMap;
    }

    // Builds a Map<employeeId, sked__Resource__c> for the given employee IDs.
    // Inactive resources are excluded — there is no value in syncing Workday
    // data to a resource that is permanently deactivated in Salesforce.
    //
    // Base fields always selected: Id, sked_Employee_ID__c, sked_Employment_Status__c.
    // Each batch class passes its own additionalFields list for the domain-specific
    // fields it needs (e.g. sked_REAL_ID_Compliant_indicator__c for the REAL ID batch).
    //
    // @param employeeIds      Set of Workday employee ID strings for this chunk
    // @param additionalFields Extra fields to SELECT beyond the base set
    public static Map<String, sked__Resource__c> buildResourceMap(
        Set<String>  employeeIds,
        List<String> additionalFields
    ) {
        List<String> fields = new List<String>{
            'Id',
            'sked_Employee_ID__c',
            'sked_Employment_Status__c'
        };
        if (additionalFields != null) {
            fields.addAll(additionalFields);
        }

        String soql = 'SELECT ' + String.join(fields, ', ')
            + ' FROM sked__Resource__c'
            + ' WHERE sked_Employee_ID__c IN :employeeIds'
            + ' AND sked_Employment_Status__c !=: INACTIVE_STATUS';

        Map<String, sked__Resource__c> resourceMap = new Map<String, sked__Resource__c>();
        for (sked__Resource__c r : Database.query(soql)) {
            resourceMap.put(r.sked_Employee_ID__c, r);
        }
        return resourceMap;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // STAGING RECORD CONSTRUCTION HELPERS
    // ─────────────────────────────────────────────────────────────────────────

    // Initialises the common fields on a brand-new BSF_Workday_Staging__c record.
    // Sets RecordTypeId, Employee_ID__c, Resource__c, and the initial Sync_Comment__c.
    // The calling batch class must set all domain-specific fields
    // (e.g. Real_ID_Compliant__c, Workday_Last_Functionally_Updated__c, Sync_Status__c)
    // on the returned record before adding it to the upsert list.
    //
    // @param wd               Parsed Workday employee wrapper for this record
    // @param resourceId       Salesforce Id of the matched sked__Resource__c record
    // @param recordTypeId     Record type Id for this job's staging record type
    // @param firstSyncComment Short description appended to Sync_Comment__c on creation
    //                         e.g. '1st time certification synced from Workday'
    public static BSF_Workday_Staging__c buildNewStagingRecord(
        WorkdayEmployeeWrapper wd,
        Id                     resourceId,
        Id                     recordTypeId,
        String                 firstSyncComment
    ) {
        BSF_Workday_Staging__c s = new BSF_Workday_Staging__c();
        s.RecordTypeId           = recordTypeId;
        s.Employee_ID__c         = wd.employeeId;
        s.Resource__c            = resourceId;
        s.Sync_Comment__c        = String.valueOf(System.today()) + ': ' + firstSyncComment;
        return s;
    }

    // Appends a dated change log entry to Sync_Comment__c on an existing
    // staging record. Called by each batch class after building the fieldChanges
    // diff string and before setting domain-specific fields.
    //
    // Note: Sync_Comment__c is appended on every update. The field is a Long
    // Text Area with a maximum of 32,768 characters. Monitor its growth over
    // time — consider switching to overwrite-only if audit history grows too large.
    //
    // @param staging      Existing staging record mutated in place
    // @param wd           Parsed Workday employee wrapper (not used directly here
    //                     but passed for consistency with buildNewStagingRecord)
    // @param fieldChanges Human-readable diff string built by the caller before
    //                     any fields are overwritten, e.g.
    //                     'Compliant: true → false; Expiration_Date: 2026-01-01 → 2025-12-01; '
    public static void applyCommonStagingUpdate(
        BSF_Workday_Staging__c staging,
        WorkdayEmployeeWrapper wd,
        String                 fieldChanges
    ) {
        staging.Sync_Comment__c = staging.Sync_Comment__c
            + '\n' + String.valueOf(System.today())
            + ': Updated from Workday. Changes: ' + fieldChanges;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ERROR LOGGING
    // Logs DML errors to both System.debug and sked__Debug_Log__c records so
    // that errors are visible in the Skedulo Debug Log UI for support and ops.
    // Uses Database.insert with allOrNone = false so a failure to write the
    // log record itself never causes the batch to abort.
    // ─────────────────────────────────────────────────────────────────────────

    // Iterates a list of upsert results and logs any failures.
    //
    // @param results   Result list returned by Database.upsert()
    // @param context   Short label for the DML operation e.g. 'staging upsert'
    //                  Included in both the debug log and sked__Debug_Log__c summary
    // @param jobLabel  Calling batch class name for debug log prefixing
    public static void logUpsertErrors(List<Database.UpsertResult> results, String context, String jobLabel) {
        List<sked__Debug_Log__c> logsToInsert = new List<sked__Debug_Log__c>();
        for (Database.UpsertResult ur : results) {
            if (!ur.isSuccess()) {
                for (Database.Error err : ur.getErrors()) {
                    String detail = 'Status Code: ' + err.getStatusCode() + ' — ' + err.getMessage();
                    System.debug(jobLabel + ': DML error [' + context + '] — ' + detail);
                    logsToInsert.add(buildDebugLog(context, detail, jobLabel));
                }
            }
        }
        if (!logsToInsert.isEmpty()) {
            Database.insert(logsToInsert, false);
        }
    }

    // Iterates a list of save results and logs any failures.
    //
    // @param results   Result list returned by Database.update() or Database.insert()
    // @param context   Short label for the DML operation e.g. 'resource update'
    //                  Included in both the debug log and sked__Debug_Log__c summary
    // @param jobLabel  Calling batch class name for debug log prefixing
    public static void logSaveErrors(List<Database.SaveResult> results, String context, String jobLabel) {
        List<sked__Debug_Log__c> logsToInsert = new List<sked__Debug_Log__c>();
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    String detail = 'Status Code: ' + err.getStatusCode() + ' — ' + err.getMessage();
                    System.debug(jobLabel + ': DML error [' + context + '] — ' + detail);
                    logsToInsert.add(buildDebugLog(context, detail, jobLabel));
                }
            }
        }
        if (!logsToInsert.isEmpty()) {
            Database.insert(logsToInsert, false);
        }
    }

    // Constructs a sked__Debug_Log__c error record with a consistent structure.
    // Called by both logUpsertErrors and logSaveErrors so all batch jobs produce
    // identical log entries regardless of which DML operation failed.
    private static sked__Debug_Log__c buildDebugLog(String context, String errorDetail, String jobLabel) {
        sked__Debug_Log__c log = new sked__Debug_Log__c();
        log.sked__Type__c      = 'Error Log';
        log.sked_Category__c   = 'System Error';
        log.sked__Summary__c   = jobLabel + ' DML error [' + context + ']';
        log.sked__Message__c   = errorDetail;
        log.sked_Request__c    = 'Batch context: ' + context;
        return log;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DUPLICATE RUN PREVENTION
    // Returns true if a batch job with the given Apex class name is already
    // active so the Schedulable can skip queuing a new run. Checked statuses
    // cover all pre-execution and mid-execution states: Holding, Queued,
    // Preparing, and Processing.
    //
    // @param batchClassName  Apex class name to check e.g. 'BSF_LeaveReturnBatch'
    // ─────────────────────────────────────────────────────────────────────────
    public static Boolean isBatchAlreadyRunning(String batchClassName) {
        Integer count = [
            SELECT COUNT()
            FROM   AsyncApexJob
            WHERE  ApexClass.Name = :batchClassName
            AND    JobType        = 'BatchApex'
            AND    Status         IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];
        return count > 0;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ENDPOINT BUILDER UTILITY
    // Appends a single query parameter to a URL. Automatically uses '?' if
    // the URL has no existing parameters, or '&' if it already has some.
    // The parameter value is URL-encoded before appending.
    //
    // @param endpoint    Base URL, with or without existing query parameters
    // @param paramName   Query parameter name e.g. 'format'
    // @param paramValue  Raw parameter value — URL-encoded by this method
    // ─────────────────────────────────────────────────────────────────────────
    public static String appendQueryParam(String endpoint, String paramName, String paramValue) {
        String separator = endpoint.contains('?') ? '&' : '?';
        String encoded   = EncodingUtil.urlEncode(paramValue, 'UTF-8');
        return endpoint + separator + paramName + '=' + encoded;
    }
}