/**
 * Service for direct Workday submission of Ops Record time blocks.
 * Calls Employee Report API to determine who needs base time, builds base + premium blocks,
 * and submits to workday through the  Import_Reported_Time_Blocks.
 */
public with sharing class BSF_WorkdayOpsRecordDirectService {

    /** Max length for sked__Debug_Log__c.sked_Request__c / sked_Response__c (Long Text 32768). */
    private static final Integer MAX_DEBUG_LOG_RESPONSE_LENGTH = 32768;
    /** Max length for sked__Debug_Log__c.sked__Message__c (Long Text 131000). */
    private static final Integer MAX_DEBUG_LOG_MESSAGE_LENGTH = 131000;

    /** Result of Employee Report call: map of employee ID → timezone, plus request URL and response body for logging. */
    public class EmployeeReportResult {
        public Map<String, String> employeeIdToTimezone;
        public String requestUrl;
        public String responseBody;
        public Integer statusCode;

        public EmployeeReportResult(Map<String, String> employeeIdToTimezone, String requestUrl, String responseBody, Integer statusCode) {
            this.employeeIdToTimezone = employeeIdToTimezone != null ? employeeIdToTimezone : new Map<String, String>();
            this.requestUrl = requestUrl;
            this.responseBody = (responseBody != null && responseBody.length() > MAX_DEBUG_LOG_MESSAGE_LENGTH) ? responseBody.substring(0, MAX_DEBUG_LOG_MESSAGE_LENGTH) : responseBody;
            this.statusCode = statusCode;
        }
    }

    /**
     * Calls the Workday Employee Report API. Employees present in the response do NOT have time
     * in Workday for the given date → we must submit base time for them.
     * Returns result with employeeIdToTimezone map and request/response for logging.
     */
    public static EmployeeReportResult getEmployeesWithoutTimeInWorkdayWithLog(
        String endpointUrl,
        String driveStartDateParamName,
        String driveEndDateParamName,
        String employeeIdsParamName,
        List<String> employeeIds,
        Date driveDate
    ) {
        Map<String, String> employeeIdToTimezone = new Map<String, String>();
        String requestUrl = '';
        String responseBody = '';
        Integer statusCode = 0;
        // For date-only mode we no longer require employeeIds; only endpoint and driveDate are mandatory.
        if (String.isBlank(endpointUrl) || driveDate == null) {
            return new EmployeeReportResult(employeeIdToTimezone, requestUrl, responseBody, 0);
        }
        // API expects YYYY-MM-DD-HH:mm format (e.g. 2026-02-09-08:00)
        String dateStr = formatDriveDateForWorkdayApi(driveDate);
        // When employeeIdsParamName and employeeIds are both provided, we still support
        // the Worker!Employee_ID=id1!id2!id3 filter; otherwise we call the report by date only.
        String workerPromptValue = (employeeIds != null && !employeeIds.isEmpty())
            ? String.join(employeeIds, '!')
            : null;
        String url = endpointUrl;
        if (url.contains('?')) {
            url += '&';
        } else {
            url += '?';
        }
        if (String.isNotBlank(driveStartDateParamName)) {
            url += driveStartDateParamName + '=' + EncodingUtil.urlEncode(dateStr, 'UTF-8') + '&';
        }
        if (String.isNotBlank(driveEndDateParamName)) {
            url += driveEndDateParamName + '=' + EncodingUtil.urlEncode(dateStr, 'UTF-8') + '&';
        }
        if (String.isNotBlank(employeeIdsParamName) && String.isNotBlank(workerPromptValue)) {
            url += employeeIdsParamName + '=' + EncodingUtil.urlEncode(workerPromptValue, 'UTF-8') + '&';
        }
        url += 'format=json';
        requestUrl = (url != null && url.length() > MAX_DEBUG_LOG_RESPONSE_LENGTH) ? url.substring(0, MAX_DEBUG_LOG_RESPONSE_LENGTH) : url;
        try {
            HttpRequest req = skedWorkdayApiManager.getHttpRequest(url, 'GET');
            req.setTimeout(120000);
            Http http = new Http();
            HttpResponse res = http.send(req);
            String body = res.getBody();
            statusCode = res.getStatusCode();
            responseBody = body;

            if (res.getStatusCode() != 200 || String.isBlank(body)) {
                return new EmployeeReportResult(employeeIdToTimezone, requestUrl, responseBody, statusCode);
            }
            // Parse JSON: Workday REAL report returns an object with a "Report_Entry" array
            Object rootObj = JSON.deserializeUntyped(body);
            List<Object> rows = new List<Object>();

            if (rootObj instanceof List<Object>) {
                rows = (List<Object>) rootObj;
            } else if (rootObj instanceof Map<String, Object>) {
                Map<String, Object> root = (Map<String, Object>) rootObj;
                if (!root.containsKey('Report_Entry')) {
                    return new EmployeeReportResult(employeeIdToTimezone, requestUrl, responseBody, statusCode);
                }
                Object reportEntryObj = root.get('Report_Entry');
                if (reportEntryObj instanceof List<Object>) {
                    rows = (List<Object>) reportEntryObj;
                } else if (reportEntryObj instanceof Map<String, Object>) {
                    rows.add(reportEntryObj);
                } else {
                    return new EmployeeReportResult(employeeIdToTimezone, requestUrl, responseBody, statusCode);
                }
            } else {
                return new EmployeeReportResult(employeeIdToTimezone, requestUrl, responseBody, statusCode);
            }

            if (rows == null) {
                return new EmployeeReportResult(employeeIdToTimezone, requestUrl, responseBody, statusCode);
            }
            for (Object rowObj : rows) {
                Map<String, Object> row = (Map<String, Object>) rowObj;
                String empId = getStringFromRow(row, new List<String>{ 'Employee ID', 'Employee_ID', 'EmployeeId' });
                // Workday field for timezone has changed over time; support all known past variants
                String tzRaw = getStringFromRow(
                    row,
                    new List<String>{
                        'TZ_Reference_id',
                        'TZ_Reference_Id',
                        'Time Zone Reference Id',
                        'Time_Zone_Reference_Id',
                        'TimeZone'
                    }
                );
                if (String.isNotBlank(empId)) {
                    String tzNormalized = normalizeWorkdayTimezone(tzRaw);
                    // Default to California / Pacific time if Workday doesn't send a usable timezone
                    employeeIdToTimezone.put(empId, String.isNotBlank(tzNormalized) ? tzNormalized : 'America/Los_Angeles');
                }
            }
            return new EmployeeReportResult(employeeIdToTimezone, requestUrl, responseBody, statusCode);
        } catch (Exception e) {
            // On any exception, catch the error via responseBody
            responseBody = e.getMessage();
            statusCode = null;
            return new EmployeeReportResult(employeeIdToTimezone, requestUrl, responseBody, statusCode);
        }
    }

    /**
     * Calls the Workday Employee Report API. Employees present in the response do NOT have time
     * in Workday for the given date → we must submit base time for them.
     * Passes Start_Date and End_Date (same date in both, format YYYY-MM-DD-HH:mm); both params are required.
     * Returns map of Employee ID (string) → IANA timezone (e.g. US/Eastern).
     * Use getEmployeesWithoutTimeInWorkdayWithLog when you need request/response for logging.
     */
    public static Map<String, String> getEmployeesWithoutTimeInWorkday(
        String endpointUrl,
        String driveStartDateParamName,
        String driveEndDateParamName,
        String employeeIdsParamName,
        List<String> employeeIds,
        Date driveDate
    ) {
        EmployeeReportResult result = getEmployeesWithoutTimeInWorkdayWithLog(
            endpointUrl,
            driveStartDateParamName,
            driveEndDateParamName,
            employeeIdsParamName,
            employeeIds,
            driveDate
        );
        return result != null && result.employeeIdToTimezone != null
            ? result.employeeIdToTimezone
            : new Map<String, String>();
    }

    /** Formats drive date as YYYY-MM-DD-HH:mm for Workday Employee Report API (e.g. 2026-02-09-08:00). */
    private static String formatDriveDateForWorkdayApi(Date driveDate) {
        if (driveDate == null) {
            return '';
        }
        String yyyy = String.valueOf(driveDate.year());
        String mm = String.valueOf(driveDate.month());
        String dd = String.valueOf(driveDate.day());
        if (mm.length() == 1) { mm = '0' + mm; }
        if (dd.length() == 1) { dd = '0' + dd; }
        return yyyy + '-' + mm + '-' + dd + '-08:00';
    }

    /**
     * Normalizes timezone strings received from Workday Employee Report.
     * - If Workday sends a valid IANA-style ID (e.g. US/Pacific, America/Chicago), we keep it as-is.
     * - Otherwise we return null so we can fall back to Pacific.
     */
    private static String normalizeWorkdayTimezone(String tzRaw) {
        if (String.isBlank(tzRaw)) {
            return null;
        }
        String t = tzRaw.trim();
        // Accept common IANA-style IDs that Salesforce supports directly
        if (t.startsWith('US/') || t.startsWith('America/')) {
            return t;
        }
        return null;
    }

    private static String getStringFromRow(Map<String, Object> row, List<String> keys) {
        for (String key : keys) {
            if (row.containsKey(key)) {
                Object val = row.get(key);
                if (val != null) {
                    return String.valueOf(val).trim();
                }
            }
        }
        return null;
    }

    /**
     * Submits base + premium time blocks to Workday Import_Reported_Time_Blocks.
     */
    public static skedWorkdayImportTimeBlockResponse submitTimeBlocksToWorkday(
        List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> allBlocks,
        List<Map<String, String>> dateTimeFormatsForBaseBlocks
    ) {
        if (allBlocks == null || allBlocks.isEmpty()) {
            skedWorkdayImportTimeBlockResponse empty = new skedWorkdayImportTimeBlockResponse('[]');
            empty.isSuccess = false;
            empty.message = 'No time blocks to submit';
            return empty;
        }
        String docBody;
        try {
            skedWorkdayTimeTracking timeTracking = new skedWorkdayTimeTracking();
            String endpoint = timeTracking.endpoint_x;
            BSF_Workday_Direct_Submission_Config__mdt config = BSF_WorkdayDirectSubmissionConfig.getConfig();
            if (config != null && String.isNotBlank(config.sked_WD_Import_Blocks_URL__c)) {
                endpoint = config.sked_WD_Import_Blocks_URL__c;
            }
            String s_ns0 = 'urn:com.workday/bsvc';
            String nsBsvc = 'xmlns:bsvc';
            String version = timeTracking.version;
            DOM.Document doc = new DOM.Document();
            DOM.XmlNode body = skedWorkdayApiManager.populateDoc(doc);
            DOM.XmlNode methodNode = body.addChildElement('Import_Reported_Time_Blocks_Request', s_ns0, 'bsvc');
            methodNode.setAttribute(nsBsvc, s_ns0);
            methodNode.setAttribute('bsvc:version', version);
            skedWorkdayTimeTrackingBsvc.Import_Reported_Time_Blocks_RequestType request_x =
                new skedWorkdayTimeTrackingBsvc.Import_Reported_Time_Blocks_RequestType(allBlocks);
            request_x.populateXmlNode(methodNode);
            List<Dom.XmlNode> reportedTimeBlockNodes = methodNode.getChildElements();
            Integer timeBlockIndex = 0;
            Integer dateTimeFormatsSize = dateTimeFormatsForBaseBlocks != null ? dateTimeFormatsForBaseBlocks.size() : 0;
            for (Dom.XmlNode timeBlockNode : reportedTimeBlockNodes) {
                if (timeBlockNode.getName() == 'Reported_Time_Block_Data' && timeBlockIndex < dateTimeFormatsSize) {
                    Map<String, String> dateTimeFormat = dateTimeFormatsForBaseBlocks[timeBlockIndex];
                    if (dateTimeFormat != null) {
                        if (dateTimeFormat.containsKey('In_Date_Time')) {
                            updateXmlNodeText(timeBlockNode, 'In_Date_Time', dateTimeFormat.get('In_Date_Time'));
                        }
                        if (dateTimeFormat.containsKey('Out_Date_Time')) {
                            updateXmlNodeText(timeBlockNode, 'Out_Date_Time', dateTimeFormat.get('Out_Date_Time'));
                            Boolean outReasonExists = false;
                            for (Dom.XmlNode childNode : timeBlockNode.getChildElements()) {
                                if (childNode.getName() == 'Out_Reason_Reference') {
                                    outReasonExists = true;
                                    break;
                                }
                            }
                            if (!outReasonExists) {
                                Dom.XmlNode outReasonNode = timeBlockNode.addChildElement('Out_Reason_Reference', s_ns0, '');
                                outReasonNode.setAttribute('bsvc:Descriptor', 'Clock Event Type');
                                Dom.XmlNode idNode = outReasonNode.addChildElement('ID', s_ns0, '');
                                idNode.setAttribute('bsvc:type', 'Clock_Event_Type');
                                idNode.addTextNode('Out');
                            }
                        }
                    }
                    timeBlockIndex++;
                }
            }
            docBody = doc.toXmlString();
            HttpRequest req = skedWorkdayApiManager.getHttpRequest(endpoint, 'POST');
            req.setBody(docBody);
            req.setTimeout(120000);
            Http http = new Http();
            HttpResponse res = http.send(req);
            String responseBody = res.getBody();
            // Preserve full SOAP request up to sked__Message__c limit for operation-record debug logs (batch truncates per field).
            String requestForResult = docBody;
            if (requestForResult != null && requestForResult.length() > MAX_DEBUG_LOG_MESSAGE_LENGTH) {
                requestForResult = requestForResult.substring(0, MAX_DEBUG_LOG_MESSAGE_LENGTH);
            }
            skedWorkdayImportTimeBlockResponse result = new skedWorkdayImportTimeBlockResponse(requestForResult != null ? requestForResult : '');
            result.response = responseBody;
            result.statusCode = res.getStatusCode();
            result.isSuccess = (res.getStatusCode() == 200);
            // Parse Workday Import Process WID from successful response, if present.
            if (result.isSuccess && String.isNotBlank(responseBody)) {
                try {
                    Dom.Document respDoc = new Dom.Document();
                    respDoc.load(responseBody);
                    Dom.XmlNode root = respDoc.getRootElement();
                    if (root != null) {
                        Dom.XmlNode bodyNode = null;
                        for (Dom.XmlNode child : root.getChildElements()) {
                            if (child.getName().endsWith('Body')) {
                                bodyNode = child;
                                break;
                            }
                        }
                        if (bodyNode != null) {
                            Dom.XmlNode putImportResp = null;
                            for (Dom.XmlNode child : bodyNode.getChildElements()) {
                                if (child.getName().endsWith('Put_Import_Process_Response')) {
                                    putImportResp = child;
                                    break;
                                }
                            }
                            if (putImportResp != null) {
                                Dom.XmlNode importRef = null;
                                for (Dom.XmlNode child : putImportResp.getChildElements()) {
                                    if (child.getName().endsWith('Import_Process_Reference')) {
                                        importRef = child;
                                        break;
                                    }
                                }
                                if (importRef != null) {
                                    for (Dom.XmlNode idNode : importRef.getChildElements()) {
                                        if (idNode.getName().endsWith('ID')) {
                                            String wid = idNode.getText();
                                            if (String.isNotBlank(wid)) {
                                                result.importProcessId = wid;
                                            }
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch (Exception parseEx) {
                }
            }
            result.message = result.isSuccess ? 'Success' : (res.getStatusCode() + ': ' + res.getStatus());
            return result;
        } catch (Exception e) {
            String requestForResult = docBody;
            if (requestForResult != null && requestForResult.length() > MAX_DEBUG_LOG_MESSAGE_LENGTH) {
                requestForResult = requestForResult.substring(0, MAX_DEBUG_LOG_MESSAGE_LENGTH);
            }
            skedWorkdayImportTimeBlockResponse result = new skedWorkdayImportTimeBlockResponse(requestForResult != null ? requestForResult : '');
            result.response = e.getMessage();
            result.statusCode = null;
            result.isSuccess = false;
            result.message = 'Exception: ' + e.getMessage();
            return result;
        }
    }

    private static void updateXmlNodeText(Dom.XmlNode parentNode, String nodeName, String newTextValue) {
        Dom.XmlNode nodeToUpdate = null;
        for (Dom.XmlNode childNode : parentNode.getChildElements()) {
            if (childNode.getName() == nodeName) {
                nodeToUpdate = childNode;
                break;
            }
        }
        if (nodeToUpdate != null && String.isNotBlank(newTextValue)) {
            String namespace = nodeToUpdate.getNamespace();
            parentNode.removeChild(nodeToUpdate);
            Dom.XmlNode newNode = parentNode.addChildElement(nodeName, namespace, '');
            newNode.addTextNode(newTextValue);
        }
    }
}