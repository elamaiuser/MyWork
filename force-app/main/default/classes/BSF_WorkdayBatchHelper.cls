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

        HttpRequest httpRequest = skedWorkdayApiManager.getHttpRequest(endpoint, 'GET');
        httpRequest.setHeader('Content-Type', 'application/json; charset=UTF-8');
        httpRequest.setHeader('Accept', 'application/json');

        Http         httpClient   = new Http();
        HttpResponse httpResponse = httpClient.send(httpRequest);

        String responseBody = httpResponse.getBody();

        if (httpResponse.getStatusCode() >= 200 && httpResponse.getStatusCode() <= 299) {
            //System.debug(jobLabel + ': Workday API call successful — HTTP ' + httpResponse.getStatusCode());
        } else {
            String errorMessage = 'Workday API call failed — HTTP ' + httpResponse.getStatusCode() + ' — ' + responseBody;
            System.debug(jobLabel + ': ' + errorMessage);
            throw new CalloutException(errorMessage);
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

        Map<String, Object> rootNode = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

        if (!rootNode.containsKey('Report_Entry')) {
            System.debug(jobLabel + ': No Report_Entry key found in Workday response — nothing to process');
            return result;
        }

        List<Object> reportEntries = (List<Object>) rootNode.get('Report_Entry');

        for (Object rawEntryObject : reportEntries) {
            Map<String, Object> entryFieldMap = (Map<String, Object>) rawEntryObject;

            WorkdayEmployeeWrapper employeeWrapper = new WorkdayEmployeeWrapper();
            employeeWrapper.employeeId = (String) entryFieldMap.get('Employee_ID');

            // Skip records with no Employee_ID — they cannot be matched to a Resource
            if (String.isBlank(employeeWrapper.employeeId)) {
                continue;
            }

            // Store all fields except Employee_ID in extraFields.
            // Null values are omitted — extraFields only contains fields that
            // Workday actually returned with a value in this response.
            for (String fieldName : entryFieldMap.keySet()) {
                if (fieldName == 'Employee_ID') {
                    continue;
                }
                Object fieldValue = entryFieldMap.get(fieldName);
                if (fieldValue != null) {
                    employeeWrapper.extraFields.put(fieldName, String.valueOf(fieldValue));
                }
            }

            result.add(employeeWrapper);
        }

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
    // @param rawValue   Raw datetime string from the Workday JSON field
    // @param fieldName  Workday JSON field name — used in the debug log on failure
    // @param empId      Employee ID — used in the debug log on failure
    // @param jobLabel   Calling batch class name for debug log prefixing
    public static DateTime parseWorkdayDatetime(String rawValue, String fieldName, String empId, String jobLabel) {
        if (String.isBlank(rawValue)) {
            return null;
        }
        try {
            return DateTime.valueOf(rawValue.replace('T', ' ').substring(0, 19));
        } catch (Exception caughtException) {
            System.debug(jobLabel + ': Could not parse ' + fieldName + ' for employee ' + empId + ' — ' + caughtException.getMessage());
            return null;
        }
    }

    // Parses a Workday date string in YYYY-MM-DD format into a Salesforce Date.
    // Returns null if the input is blank or unparseable.
    //
    // @param rawValue   Raw date string from the Workday JSON field
    // @param fieldName  Workday JSON field name — used in the debug log on failure
    // @param empId      Employee ID — used in the debug log on failure
    // @param jobLabel   Calling batch class name for debug log prefixing
    public static Date parseWorkdayDate(String rawValue, String fieldName, String empId, String jobLabel) {
        if (String.isBlank(rawValue)) {
            return null;
        }
        try {
            return Date.valueOf(rawValue);
        } catch (Exception caughtException) {
            System.debug(jobLabel + ': Could not parse ' + fieldName + ' for employee ' + empId + ' — ' + caughtException.getMessage());
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
    // @param employeeWrapper  Wrapper containing the extraFields map
    // @param key              Workday JSON field name e.g. 'Expiration_Date'
    // @param jobLabel         Calling batch class name for debug log prefixing
    public static Date getExtraDate(WorkdayEmployeeWrapper employeeWrapper, String key, String jobLabel) {
        if (!employeeWrapper.extraFields.containsKey(key) || String.isBlank(employeeWrapper.extraFields.get(key))) {
            return null;
        }
        return parseWorkdayDate(employeeWrapper.extraFields.get(key), key, employeeWrapper.employeeId, jobLabel);
    }

    // Returns a parsed DateTime from extraFields for the given Workday JSON field name.
    // Returns null if the key is missing, the value is blank, or parsing fails.
    //
    // @param employeeWrapper  Wrapper containing the extraFields map
    // @param key              Workday JSON field name e.g. 'Last_Functionally_Updated'
    // @param jobLabel         Calling batch class name for debug log prefixing
    public static DateTime getExtraDateTime(WorkdayEmployeeWrapper employeeWrapper, String key, String jobLabel) {
        if (!employeeWrapper.extraFields.containsKey(key) || String.isBlank(employeeWrapper.extraFields.get(key))) {
            return null;
        }
        return parseWorkdayDatetime(employeeWrapper.extraFields.get(key), key, employeeWrapper.employeeId, jobLabel);
    }

    // Returns the raw String value from extraFields for the given key,
    // or null if the key is not present in the map.
    //
    // @param employeeWrapper  Wrapper containing the extraFields map
    // @param key              Workday JSON field name
    public static String getExtraString(WorkdayEmployeeWrapper employeeWrapper, String key) {
        return employeeWrapper.extraFields.containsKey(key) ? employeeWrapper.extraFields.get(key) : null;
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
        List<String> selectedFields = new List<String>{
            'Id',
            'Employee_ID__c',
            'Resource__c',
            'Sync_Comment__c'
        };
        if (additionalFields != null) {
            selectedFields.addAll(additionalFields);
        }

        String soqlQuery = 'SELECT ' + String.join(selectedFields, ', ')
            + ' FROM BSF_Workday_Staging__c'
            + ' WHERE Employee_ID__c IN :employeeIds'
            + ' AND RecordType.DeveloperName = \'' + String.escapeSingleQuotes(recordTypeDeveloperName) + '\'';

        Map<String, BSF_Workday_Staging__c> stagingByEmployeeId = new Map<String, BSF_Workday_Staging__c>();
        for (BSF_Workday_Staging__c stagingRecord : Database.query(soqlQuery)) {
            stagingByEmployeeId.put(stagingRecord.Employee_ID__c, stagingRecord);
        }
        return stagingByEmployeeId;
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
        List<String> selectedFields = new List<String>{
            'Id',
            'sked_Employee_ID__c',
            'sked_Employment_Status__c'
        };
        if (additionalFields != null) {
            selectedFields.addAll(additionalFields);
        }

        String soqlQuery = 'SELECT ' + String.join(selectedFields, ', ')
            + ' FROM sked__Resource__c'
            + ' WHERE sked_Employee_ID__c IN :employeeIds'
            + ' AND sked_Employment_Status__c !=: INACTIVE_STATUS';

        Map<String, sked__Resource__c> resourceByEmployeeId = new Map<String, sked__Resource__c>();
        for (sked__Resource__c resourceRecord : Database.query(soqlQuery)) {
            resourceByEmployeeId.put(resourceRecord.sked_Employee_ID__c, resourceRecord);
        }
        return resourceByEmployeeId;
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
    // @param employeeWrapper  Parsed Workday employee wrapper for this record
    // @param resourceId       Salesforce Id of the matched sked__Resource__c record
    // @param recordTypeId     Record type Id for this job's staging record type
    // @param firstSyncComment Short description appended to Sync_Comment__c on creation
    //                         e.g. '1st time certification synced from Workday'
    public static BSF_Workday_Staging__c buildNewStagingRecord(
        WorkdayEmployeeWrapper employeeWrapper,
        Id                     resourceId,
        Id                     recordTypeId,
        String                 firstSyncComment
    ) {
        BSF_Workday_Staging__c newStagingRecord = new BSF_Workday_Staging__c();
        newStagingRecord.RecordTypeId    = recordTypeId;
        newStagingRecord.Employee_ID__c  = employeeWrapper.employeeId;
        newStagingRecord.Resource__c     = resourceId;
        newStagingRecord.Sync_Comment__c = String.valueOf(System.today()) + ': ' + firstSyncComment;
        return newStagingRecord;
    }

    // Appends a dated change log entry to Sync_Comment__c on an existing
    // staging record. Called by each batch class after building the fieldChanges
    // diff string and before setting domain-specific fields.
    //
    // Note: Sync_Comment__c is appended on every update. The field is a Long
    // Text Area with a maximum of 32,768 characters. Monitor its growth over
    // time — consider switching to overwrite-only if audit history grows too large.
    //
    // @param stagingRecord    Existing staging record mutated in place
    // @param employeeWrapper  Parsed Workday employee wrapper (not used directly here
    //                         but passed for consistency with buildNewStagingRecord)
    // @param fieldChanges     Human-readable diff string built by the caller before
    //                         any fields are overwritten, e.g.
    //                         'Compliant: true → false; Expiration_Date: 2026-01-01 → 2025-12-01; '
    public static void applyCommonStagingUpdate(
        BSF_Workday_Staging__c stagingRecord,
        WorkdayEmployeeWrapper employeeWrapper,
        String                 fieldChanges
    ) {
        stagingRecord.Sync_Comment__c = stagingRecord.Sync_Comment__c
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
        List<sked__Debug_Log__c> debugLogsToInsert = new List<sked__Debug_Log__c>();
        for (Database.UpsertResult upsertResult : results) {
            if (!upsertResult.isSuccess()) {
                for (Database.Error dmlError : upsertResult.getErrors()) {
                    String errorDetail = 'Status Code: ' + dmlError.getStatusCode() + ' — ' + dmlError.getMessage();
                    System.debug(jobLabel + ': DML error [' + context + '] — ' + errorDetail);
                    debugLogsToInsert.add(buildDebugLog(context, errorDetail, jobLabel));
                }
            }
        }
        if (!debugLogsToInsert.isEmpty()) {
            Database.insert(debugLogsToInsert, false);
        }
    }

    // Iterates a list of save results and logs any failures.
    //
    // @param results   Result list returned by Database.update() or Database.insert()
    // @param context   Short label for the DML operation e.g. 'resource update'
    //                  Included in both the debug log and sked__Debug_Log__c summary
    // @param jobLabel  Calling batch class name for debug log prefixing
    public static void logSaveErrors(List<Database.SaveResult> results, String context, String jobLabel) {
        List<sked__Debug_Log__c> debugLogsToInsert = new List<sked__Debug_Log__c>();
        for (Database.SaveResult saveResult : results) {
            if (!saveResult.isSuccess()) {
                for (Database.Error dmlError : saveResult.getErrors()) {
                    String errorDetail = 'Status Code: ' + dmlError.getStatusCode() + ' — ' + dmlError.getMessage();
                    System.debug(jobLabel + ': DML error [' + context + '] — ' + errorDetail);
                    debugLogsToInsert.add(buildDebugLog(context, errorDetail, jobLabel));
                }
            }
        }
        if (!debugLogsToInsert.isEmpty()) {
            Database.insert(debugLogsToInsert, false);
        }
    }

    // Constructs a sked__Debug_Log__c error record with a consistent structure.
    // Called by both logUpsertErrors and logSaveErrors so all batch jobs produce
    // identical log entries regardless of which DML operation failed.
    private static sked__Debug_Log__c buildDebugLog(String context, String errorDetail, String jobLabel) {
        sked__Debug_Log__c debugLogRecord  = new sked__Debug_Log__c();
        debugLogRecord.sked__Type__c       = 'Error Log';
        debugLogRecord.sked_Category__c    = 'System Error';
        debugLogRecord.sked__Summary__c    = jobLabel + ' DML error [' + context + ']';
        debugLogRecord.sked__Message__c    = errorDetail;
        debugLogRecord.sked_Request__c     = 'Batch context: ' + context;
        return debugLogRecord;
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
        Integer activeJobCount = [
            SELECT COUNT()
            FROM   AsyncApexJob
            WHERE  ApexClass.Name = :batchClassName
            AND    JobType        = 'BatchApex'
            AND    Status         IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];
        return activeJobCount > 0;
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
        String separator    = endpoint.contains('?') ? '&' : '?';
        String encodedValue = EncodingUtil.urlEncode(paramValue, 'UTF-8');
        return endpoint + separator + paramName + '=' + encodedValue;
    }
}