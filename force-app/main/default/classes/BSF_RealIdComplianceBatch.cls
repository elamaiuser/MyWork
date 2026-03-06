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
        
        String query = 'SELECT Id, sked_Employee_ID__c, sked_REAL_ID_Compliant_indicator__c, Real_ID_Expiration_Date__c ' +
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
                if (resource.Real_ID_Expiration_Date__c != expirationDate) {
                    resource.Real_ID_Expiration_Date__c = expirationDate;
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