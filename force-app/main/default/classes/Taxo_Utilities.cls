/*@Description:  This utility class contains several reusable methods which can be used across many taxonomy classes.

 * ***************************************************************************************************************************************************************/

 /* Modification Log 
 * Date					     Developer Name			     Comments
  ********************************************************************************************************************************************************************
* 27/02/2025				 Harika Bolisetti				   Logic for Taxo Run Chaining

**********************************************************************************************************************************************************************************/
public class Taxo_Utilities {
    //for save results update, insert
    public static void logErrors(Database.SaveResult[] saveResults, 
                                String processName, 
                                String className, 
                                String methodName, 
                                String typeValue, 
                                String functionality,
                                String recordType,
                                Decimal TaxoVer) {
        try {
            List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLogWithObjectId(
                saveResults, processName, className, methodName, typeValue, functionality
            );
            if (errorLogs != NULL && !errorLogs.isEmpty()) {
                //insert errorLogs;
                Database.SaveResult[] insertResults = Database.insert(errorLogs, false);
                Taxo_Utilities.logErrors(insertResults, 
                                         'Taxonomy Run', 
                                         'Taxo_Utilities', 
                                         'logErrors', 
                                         'Error', 
                                         'Error occurred while inserting the error log',
                                         null,
                                         null);
            }
            //insert the taxo  run record
            if (!errorLogs.isEmpty()) {
                List<Taxonomy_Run_Error_Log__c> junctionRecords = new List<Taxonomy_Run_Error_Log__c>();
                List<Taxonomy_Run__c> taxonomyRuns = [SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c, Status__c, 
                                                        Processing_Start__c
                                                        FROM Taxonomy_Run__c 
                                                        WHERE Taxo_Record_Type__c =:recordType and 
                                                        Future_Version_Number__c =:TaxoVer LIMIT 1];
                // Check if a record is found before proceeding
                Taxonomy_Run__c taxonomyRun;
                if (!taxonomyRuns.isEmpty()) {
                    taxonomyRun = taxonomyRuns[0];
                } else {
                    taxonomyRun = null;  
                }
                for (BSF_Error_Log__c errorLog : errorLogs) {
                    if (errorLog.Object_RecordId__c != null) { // Assuming this stores Taxonomy_Run__c ID
                        Taxonomy_Run_Error_Log__c txr = new Taxonomy_Run_Error_Log__c();
                        txr.BSF_Error_Log_Id__c = errorLog.Id;
                        txr.Taxonomy_Run_Id__c = taxonomyRun.Id;
                        junctionRecords.add(txr);
                    }
                }
                // Perform DML outside the loop
                if (!junctionRecords.isEmpty()) {
                    //  insert junctionRecords;
                    Database.SaveResult[] insertResults = Database.insert(junctionRecords, false);
                    Taxo_Utilities.logErrors(insertResults, 
                                             'Taxonomy Run', 
                                             'Taxo_Utilities', 
                                             'logErrors', 
                                             'Error', 
                                             'Error occurred while inserting the error log',
                                             null,
                                             null);
                }
            }   
        } catch (Exception e) {
            Taxo_Utilities.logErrorForException(e, 'Taxo_Utilities', 'logErrors', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',null,null);
        }
        }
    //for save results deletion, insert
    public static void logErrorsDeletion(Database.DeleteResult[] deleteResults, String processName, String className, String methodName, String typeValue, String functionality) {
        try {
            List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLog(
                deleteResults, processName, className, methodName, typeValue, functionality
            );
            if (errorLogs != NULL && !errorLogs.isEmpty()) {
                //insert errorLogs;
                Database.SaveResult[] insertResults = Database.insert(errorLogs, false);
                Taxo_Utilities.logErrors(insertResults, 
                                         'Taxonomy Run', 
                                         'Taxo_Utilities', 
                                         'logErrors', 
                                         'Error', 
                                         'Error occurred while inserting the error log',
                                         null,
                                         null);
            } 
        } catch (Exception e) {
         Taxo_Utilities.logErrorForException(e, 'Taxo_Utilities', 'logErrors', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',null,null);
        }
    }
    public static void logErrorForException(Exception ex, 
                                            String className, 
                                            String methodName, 
                                            String processName,
                                            String functionality,
                                            String objectName,
                                            //String objectRecordId,
                                            String recordType,
                                            Decimal TaxoVer) {
        try {
            // Create the error log record
            List<BSF_Error_Log__c> errorLogs = new List<BSF_Error_Log__c>();
            List<Taxonomy_Run_Error_Log__c> TaxerrorLogs = new List<Taxonomy_Run_Error_Log__c>();
            BSF_Error_Log__c errorLog = BSF_Utilities.createBsfErrorLogForExceptions(
                ex, className, methodName, processName, functionality, objectName, null
            );
            
            if (errorLog != null) {
                //insert errorLog; // Insert the error log record
                errorLogs.add(errorLog);
                Database.SaveResult[] insertResults = Database.insert(errorLogs, false);
                 Taxo_Utilities.logErrors(insertResults, 
                                         'Taxonomy Run', 
                                         'Taxo_Utilities', 
                                         'logErrors', 
                                         'Error', 
                                         'Error occurred while inserting the error log',
                                         null,
                                         null);
            }
            List<Taxonomy_Run__c> taxonomyRuns = [
                    SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c, Status__c, Processing_Start__c
                    FROM Taxonomy_Run__c WHERE (Taxo_Record_Type__c =:recordType and Future_Version_Number__c =:TaxoVer) OR Future_Version_Number__c =:TaxoVer LIMIT 1];
            // Check if a record is found before proceeding
            Taxonomy_Run__c taxonomyRun;
            if (!taxonomyRuns.isEmpty()) {
                taxonomyRun = taxonomyRuns[0];
            } else {
                taxonomyRun = null;
            }
            // Create the junction record only if errorLog has been inserted successfully
            if (errorLog != null && errorLog.Id != null && taxonomyRun.Id != null) {
                Taxonomy_Run_Error_Log__c txr = new Taxonomy_Run_Error_Log__c();
                txr.BSF_Error_Log_Id__c = errorLog.Id;
                txr.Taxonomy_Run_Id__c = taxonomyRun.Id ;
                TaxerrorLogs.add(txr);
                Database.SaveResult[] insertResults = Database.insert(TaxerrorLogs, false);
                Taxo_Utilities.logErrors(insertResults, 
                                         'Taxonomy Run', 
                                         'Taxo_Utilities', 
                                         'logErrors', 
                                         'Error', 
                                         'Error occurred while inserting the error log',
                                         null,
                                         null);
                // insert txr; // Insert the junction record
            }
            
        } catch (Exception e) { 
            Taxo_Utilities.logErrorForException(e, 'Taxo_Utilities', 'logErrors', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',null,null);
            
        }
    }
    //Fetch batch size
    public static Integer getBatchSize(String recordTypeName, String batchName) {
        Integer defaultBatchSize = 50; // Default batch size if no match is found
        // Query Custom Metadata or Custom Object where batch sizes are stored
        Taxonomy_Run_Config__mdt config = [
            SELECT Batch_Size__c FROM Taxonomy_Run_Config__mdt	
            WHERE Taxo_Record_Type_Name__c = :recordTypeName
            AND Batch_Name__c = :batchName
            LIMIT 1
        ];
        // Return the batch size if found; otherwise, return the default value
        return (config != null && config.Batch_Size__c !=null) ? Integer.valueOf(config.Batch_Size__c) : defaultBatchSize;
    }
    // Read per-record-type delay; fall back to 5 minutes if not set/found.
    public static Integer getScheduleDelayMinutes(String recordTypeName) {
        try {
            Taxonomy_Run_Config__mdt cfg = [
                SELECT Schedule_Delay_Minutes__c
                FROM Taxonomy_Run_Config__mdt
                WHERE Is_Active__c = true
                  AND Category__c = 'Taxo Run Sequence'
                  AND Taxo_Record_Type_Name__c = :recordTypeName
                LIMIT 1
            ];
            return (cfg.Schedule_Delay_Minutes__c == null) ? 5 : Integer.valueOf(cfg.Schedule_Delay_Minutes__c);  // falls back to 5
        } catch (Exception e) {
            System.debug('Exception at getScheduleDelayMinutes :'+e.getMessage());
            return 5;
        }
    }
    
    public static void scheduleAfterDelay(
        Schedulable job,
        String recordTypeName,
        String jobNamePrefix
    ){
        Integer delay = getScheduleDelayMinutes(recordTypeName);
        Datetime dt = Datetime.now().addMinutes(delay);
        String cron = String.format('{0} {1} {2} {3} {4} ? {5}',
            new String[]{
                String.valueOf(dt.second()),
                String.valueOf(dt.minute()),
                String.valueOf(dt.hour()),
                String.valueOf(dt.day()),
                String.valueOf(dt.month()),
                String.valueOf(dt.year())
            }
        );
        System.schedule(jobNamePrefix + '-' + recordTypeName + '-' + Datetime.now().getTime(), cron, job);
    }
    
    // --------- Get Org Default Row of Custom Setting ---------
    private static Taxonomy_Automation_Runtime_Check__c getRuntimeCfg() {
        Taxonomy_Automation_Runtime_Check__c cfg =
            Taxonomy_Automation_Runtime_Check__c.getOrgDefaults();
        System.debug('getRuntimeCfg cfg==>>'+cfg);
        if (cfg == null) {
            cfg = new Taxonomy_Automation_Runtime_Check__c();
        }
        return cfg;
    }
    // --------- Utility Method to Check Flag ---------
    public static Boolean isTaxonomyRunning() {
        try {
            Taxonomy_Automation_Runtime_Check__c cfg = getRuntimeCfg();
            return cfg.Is_Taxonomy_Running__c;
        } catch (Exception e) {
            System.debug('isTaxonomyRunning ERROR: ' + e.getMessage());
            return false;  // fail-open
        }
    }
    // --------- Mark START of Taxonomy Automation ---------
    public static void markTaxonomyStarted() {
        try {
            Taxonomy_Automation_Runtime_Check__c cfg = getRuntimeCfg();

            if (!cfg.Is_Taxonomy_Running__c) {
                cfg.Is_Taxonomy_Running__c = true;
                cfg.Taxonomy_Automation_Start_DateTime__c = System.now();
                cfg.Taxonomy_Automation_End_DateTime__c = null;

                upsert cfg;
                System.debug('START: Taxonomy set to RUNNING.');
            } else {
                System.debug('START: Taxonomy already running, no update performed.');
            }
        } catch (Exception e) {
            System.debug('markTaxonomyStarted ERROR: ' + e.getMessage());
        }
    }
    public static void markTaxonomyEnded() {
        try {
            Taxonomy_Automation_Runtime_Check__c cfg =
                Taxonomy_Automation_Runtime_Check__c.getOrgDefaults();

            if (cfg == null) {
                cfg = new Taxonomy_Automation_Runtime_Check__c();
            }

            // Always mark as false and set end datetime
            cfg.Is_Taxonomy_Running__c = false;
            cfg.Taxonomy_Automation_End_DateTime__c = System.now();

            upsert cfg;

            System.debug('Taxonomy Automation marked as FINISHED.');
        }
        catch (Exception e) {
            System.debug('markTaxonomyFinished ERROR: ' + e.getMessage());
        }
    }
    
}