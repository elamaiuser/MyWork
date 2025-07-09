/***********************************************************************************************************
* 
* Description: The Taxo run object will be populated with New Taxo Data for any of the record types become available in Taxonomy__c. The  Taxo Run Control Batch will run daily and Identify if new Taxo data has been received for 
*                      any of the Taxo Record Types and insert in this object.  
* 
* 
* Modification Log:    
* --------------------------------------------------------------------------------------------------------
* Date         Author                 Description
* 04/03/2025   Harika  Bolisetti     The batch implemented based on HRP-14295
**********************************************************************************************************/

global class BSF_Batch_TaxoRunControlBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Boolean stopTaxRunBatch = false;
    public Boolean queryLimitExceed = false;
    public set<string> getRecordTypes = new set<string>(); 
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Batch Fetches Taxo Record Type with Sequence No From Taxo Run Config
        try{
            return Database.getQueryLocator(
                'SELECT Id,Sequence__c, Taxo_Record_Type_Name__c FROM Taxonomy_Run_Config__mdt WHERE Is_Active__c = true AND Category__c = \'Taxo Run Sequence\' ORDER BY Sequence__c ASC'
            );
        } catch (Exception e) {
            System.debug('Error in start method: ' + e.getMessage());
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_TaxoRunControlBatch', 'Start', e.getMessage(), e.getMessage(), 'Taxonomy__c', null,null);
            return null;
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Taxonomy_Run_Config__mdt> scope) {
        
        // Track versions with start/end dates per record type
        Map<String, List<String>> recordTypeVersionMap = new Map<String, List<String>>();
        Map<String, Decimal> getSeq = new Map<String, Decimal>();
        List<Taxonomy_Run__c> taxonomyRunRecords = new List<Taxonomy_Run__c>();
        Set<String> existingKeys = new Set<String>();
        List<BSF_Error_Log__c> errorlogEntry = new List<BSF_Error_Log__c>();
        List<String> tableRows = new List<String>();
        Set<String> loggedRecordTypes = new Set<String>();
        Integer thershold = 49999;    
        
        //Store the sequence
        try {
            for (Taxonomy_Run_Config__mdt tx : scope) {
                if (Test.isRunningTest()) {
                    getSeq.put('Bio Recruitment CD', 7);
                }else{
                getSeq.put(tx.Taxo_Record_Type_Name__c, tx.Sequence__c);
                }
            }
            //Store the external id 
            for (Taxonomy_Run__c rec : [SELECT Id,Taxo_Record_Type__c, Future_Version_Number__c,External_Id__c,Sequence__c
                                        FROM Taxonomy_Run__c where Taxo_Record_Type__c In : getSeq.keySet()]) {
                                            existingKeys.add(rec.External_Id__c );
                                        }
            
            Integer recordCount = [SELECT Count()
                                   FROM Taxonomy__c
                                   WHERE End_Date__c = 4000-12-31 AND RecordType.Name IN :getSeq.keySet()];
            
            If (recordCount > thershold){
                //Send Mail
                getRecordTypes.addAll(getSeq.keySet());
                stopTaxRunBatch = true;
                queryLimitExceed = true;
            }
            else {
                
                //Batch Fetches Taxo Record Grouped by Record Type, Version Number, Start Date, End Date With End Date = 12/31/4000
                // Query Taxonomy data
                List<AggregateResult> results = [
                    SELECT RecordType.Name recordType, Internal_Version_Key__c versionKey, Start_Date__c startDate, End_Date__c endDate
                    FROM Taxonomy__c
                    WHERE End_Date__c = 4000-12-31 AND RecordType.Name IN :getSeq.keySet()
                    GROUP BY RecordType.Name, Internal_Version_Key__c, Start_Date__c, End_Date__c
                ];
            
                // Process results and build version map
                for (AggregateResult aggr : results) {
                    String recordTypeName = (String) aggr.get('recordType');
                    String versionKey = (String) aggr.get('versionKey');
                    
                    if (!recordTypeVersionMap.containsKey(recordTypeName)) {
                        recordTypeVersionMap.put(recordTypeName, new List<String>());
                    }
                    recordTypeVersionMap.get(recordTypeName).add(versionKey);
                }
            
                // Process results for table rows and error logs
                for (AggregateResult aggr : results) {
                    String recordTypeName = (String) aggr.get('recordType');
                    String versionKey = (String) aggr.get('versionKey');
                    Date startDate = (Date) aggr.get('startDate');
                    Date endDate = (Date) aggr.get('endDate');
                    
                    List<String> versions = recordTypeVersionMap.get(recordTypeName);
                    
                    // If multiple versions exist, stop batch and log error
                    if (versions.size() > 1) {
                        
                        stopTaxRunBatch = true;
                        if(!loggedRecordTypes.contains(recordTypeName)) {
                            errorlogEntry.add(
                                BSF_Utilities.createBsfErrorLogwithoutExceptions(
                                    'BSF_Batch_TaxoRunControlBatch',
                                    'Execute',
                                    'Taxo Processing Automation',
                                    'Taxonomy__c',
                                    'Record Type: ' + recordTypeName + ' has multiple future version numbers: ' + versions
                                )
                            );
                        }
                        loggedRecordTypes.add(recordTypeName);   
                        tableRows.add(
                            '<tr>' +
                            '<td>' + recordTypeName + '</td>' +
                            '<td>' + versionKey + '</td>' +
                            '<td>' + startDate.format() + '</td>' +
                            '<td>' + endDate.format() + '</td>' +
                            '</tr>'
                        );
                    }
                }
                if (!stopTaxRunBatch) {
                    
                    for (AggregateResult aggr : results) {
                        String recordTypeName = (String) aggr.get('recordType');
                        String versionKey = (String) aggr.get('versionKey');
                        Date startDate = (Date) aggr.get('startDate');
                        Date endDate = (Date) aggr.get('endDate');   
                        List<String> versions = recordTypeVersionMap.get(recordTypeName);
                        
                        // If only one version exists and batch is still running, add taxonomy run record
                        if (versions.size() == 1 && !existingKeys.contains(recordTypeName + '_' + versionKey)) {
                            taxonomyRunRecords.add(constructTaxonomyRunRecord(recordTypeName, versionKey, getSeq.get(recordTypeName)));
                        }
                    }
                }
                
                tableRows.sort(); 
                // Send custom notification after the loop (not inside)
                if (!tableRows.isEmpty()) {
                    sendCustomNotification(tableRows);
                }
                                
                //log error            
                if (errorlogEntry != NULL && !errorlogEntry.isEmpty()) {
                    //insert errorlogEntry;
                    Database.SaveResult[] insertResults = Database.insert(errorlogEntry, false);
                    Taxo_Utilities.logErrors(insertResults, 
                                             'Error occurred while inserting the error log', 
                                             'BSF_Batch_TaxoRunControlBatch', 
                                             'Taxonomy Run', 
                                             'Error', 
                                             'Error occurred while inserting the error log',
                                             null,
                                             null);
                }
                // Insert taxonomy run records
                //Insert Records  
                if (!taxonomyRunRecords.isEmpty()) {
                    Database.SaveResult[] insertResults = Database.insert(taxonomyRunRecords, false);
                    Taxo_Utilities.logErrors(insertResults, 
                                             'Error occurred while inserting the Taxonomy Run Record', 
                                             'BSF_Batch_TaxoRunControlBatch', 
                                             'Taxonomy Run', 
                                             'Error', 
                                             'Error occurred while inserting the Taxonomy Run Record',
                                             null,
                                             null);
                }
            }
        } catch (Exception e) {
            Taxo_Utilities.logErrorForException(
                e,
                'BSF_Batch_TaxoRunControlBatch',
                'Execute Method',
                e.getMessage(),
                e.getMessage(),
                'Taxonomy__c',
                null,
                null
            );
            System.debug('Error in execute method: ' + e.getMessage());
        } 
    }
    
    global void finish(Database.BatchableContext BC) {
        List<Taxonomy_Run__c> recordsToUpdate = new List<Taxonomy_Run__c>();
        List<String> nightlyBatches = new List<String>();
        Set<Id> cronTriggerSet = new Set<Id>();
        
        try {
            
            if(queryLimitExceed){
                sendNotificationIfQueryLimitNearThreshold(getRecordTypes);
            }

            if (!stopTaxRunBatch) {
                List<Taxonomy_Run__c> taxonomyRuns = [SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c, Status__c, 
                                                      Processing_Start__c
                                                      FROM Taxonomy_Run__c WHERE Run_Date__c = TODAY AND Status__c = 'Pending' 
                                                      ORDER BY Sequence__c ASC  LIMIT 1];
                
                // Check if a record is found before proceeding
                Taxonomy_Run__c taxonomyRun;
                if (!taxonomyRuns.isEmpty()) {
                    taxonomyRun = taxonomyRuns[0];
                } else {
                    taxonomyRun = null; 
                }
                for (Taxonomy_Run_Config__mdt record : Taxonomy_Run_Config__mdt.getAll().values()) {
                    if(record.Category__c == 'Nightly Batch Pause' && record.Is_Active__c == true){
                        nightlyBatches.add(record.Batch_Name__c);    
                    }
                }
                for(AsyncApexJob asyncApex :[Select CronTriggerId from AsyncApexJob  WHERE (ApexClass.Name IN:nightlyBatches)]){
                    cronTriggerSet.add(asyncApex.CronTriggerId);
                }
                
                for(CronTrigger cTrigger :[SELECT Id, CronJobDetail.Name, State, NextFireTime,CronJobDetail.JobType
                                           FROM CronTrigger WHERE Id In : cronTriggerSet ]){
                                               //Pause the job
                                               if (cTrigger.State == 'Waiting' && taxonomyRun != null){
                                                   System.pauseJobById(cTrigger.Id);
                                               }
                                               //Resume the job
                                               else if(cTrigger.State == 'Paused' && taxonomyRun == null ){
                                                   System.resumeJobById(cTrigger.Id);  
                                               }
                                           }
                if (taxonomyRun != null) {
                    if (taxonomyRun.Taxo_Record_Type__c == BSF_Constants.BIO_COLLECTION_RECORD_TYPE) {
                        // Fetch batch size dynamically
                        Integer batchSize = Taxo_Utilities.getBatchSize(taxonomyRun.Taxo_Record_Type__c, 'BSF_Batch_PopulateCORegion');   
                        Database.executeBatch(new BSF_Batch_PopulateCORegion(null,taxonomyRun.Future_Version_Number__c,true),batchSize);
                    }
                    else if(taxonomyRun.Taxo_Record_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE) {
                        Integer batchSize = Taxo_Utilities.getBatchSize(taxonomyRun.Taxo_Record_Type__c, 'BSF_Batch_BSFPortfolio');   
                        Database.executeBatch(new BSF_Batch_BSFPortfolio(taxonomyRun.Taxo_Record_Type__c, taxonomyRun.Future_Version_Number__c, null, null, true,true), batchSize);
                    }
                    else{
                        Integer batchSize = Taxo_Utilities.getBatchSize(taxonomyRun.Taxo_Record_Type__c, 'BSF_Batch_BSFPortfolio');   
                        Database.executeBatch(new BSF_Batch_BSFPortfolio(taxonomyRun.Taxo_Record_Type__c, taxonomyRun.Future_Version_Number__c, null, null, false,true), batchSize);
                    }
                }                    
            }
        } 
        catch (Exception e) {
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_TaxoRunControlBatch', 'Finish Method', e.getMessage(), e.getMessage(), 'Taxonomy__c', null,null);
        }   
    }
    
    //For Inserting Records
    private Taxonomy_Run__c constructTaxonomyRunRecord(String recordType, String version,Decimal sequence) {
        
        //Calculation of Run Date
        Date today = Date.today();
        String todayName = DateTime.newInstance(today.year(), today.month(), today.day()).format('EEEE');
        Date runDate;
        if (!stopTaxRunBatch) { 
            for (Taxonomy_Run_Config__mdt record : Taxonomy_Run_Config__mdt.getAll().values()) {
                if (record.Is_Active__c && record.Category__c == 'Taxo Run Date Override'){
                    if(record.Taxo_Run_Date_Override__c != null && record.Taxo_Run_Date_Override__c >= today) {
                        runDate = record.Taxo_Run_Date_Override__c;
                        break;
                    }
                }
                else if (todayName == 'Saturday') {
                    runDate = today;
                }
                else{
                    // Find the next Saturday
                    Date nextSaturday = today;
                    while (DateTime.newInstance(nextSaturday.year(), nextSaturday.month(), nextSaturday.day()).format('EEEE') != 'Saturday') {
                        nextSaturday = nextSaturday.addDays(1);
                    }
                    runDate =  nextSaturday;
                }
            }
        }
        return new Taxonomy_Run__c(
            Taxo_Record_Type__c = recordType,
            Future_Version_Number__c = Decimal.valueOf(version),
            Status__c = 'Pending',
            External_Id__c = recordType + '_' + version,
            Sequence__c = sequence,
            Run_Date__c = runDate
        );
    } 
    
    
    private void sendCustomNotification(List<String> tableRows) {
        try {
            String subject = 'Multiple Future Versions Detected';
            String body = '<html><body>';
            body += '<p>System detected multiple future versions for the following record types:</p>';
            body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            body += '<tr style="background-color: #f2f2f2; font-weight: bold;">' +
                '<th>Record Type</th><th>Version</th><th>Start Date</th><th>End Date</th></tr>';
            
            // Add all collected rows to the table
            body += String.join(tableRows, '');
            body += '</table></body></html>';
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] emailRecipients = System.Label.Taxonomy_Custom_Notification_Email.split(';');
            email.setToAddresses(emailRecipients);
            email.setSubject(subject);
            email.setHtmlBody(body);
            
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{email};
                if (!messages.isEmpty()) {
                    BSF_EmailNotification.sendEmails(messages, 'Taxonomy_Custom_Notifications', null);
                }
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_TaxoRunControlBatch', 'Execute Method', e.getMessage(), e.getMessage(), 'Taxonomy__c', null,null);
        }
    }
    
    public void sendNotificationIfQueryLimitNearThreshold(Set<String> recordTypes) {
        
        try {
            String subject = 'Multiple Future Versions Detected';
            String body = '<html><body>';
            body += '<p>System detected multiple future versions for the Taxonomy Record Types. Please review and take the necessary action.</p>';
            body += '<ul>';
            for (String rt : recordTypes) {
                body += '<li>' + rt + '</li>';
            }
            body += '</ul>';
            body += '</body></html>';
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] emailRecipients = System.Label.Taxonomy_Custom_Notification_Email.split(';');
            email.setToAddresses(emailRecipients);
            email.setSubject(subject);
            email.setHtmlBody(body);
            
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{email};
                if (!messages.isEmpty()) {
                    BSF_EmailNotification.sendEmails(messages, 'Taxonomy_Custom_Notifications', null);
                }
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_TaxoRunControlBatch', 'Execute Method', e.getMessage(), e.getMessage(), 'Taxonomy__c', null,null);
        }
    }
    
}