/*@Description: 
* This Batch will run on a daily basis and check for the files uploaded for 
* Account & Site whose Expiry is less than 30 days then create Task for the Account Team Member.
* Modification Log 

*   Date					Developer Name			    Comments
* **********************************************************************
* 03/06/2025			     Satyendra Vishwakarma	    Logic for HRP-13605/13351
* **********************************************************************/

global class BatchAccountsMilitaryMoAUploadedFiles implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    private static final Integer QUERY_LIMIT = 50000;
    private List<String> taskDetails = new List<String>();        
    private Set<String> taskSubjects = new Set<String>();
    Set<String> allowedfileTypesForTaskCreation = new Set<String>();
    private String runType; // Determines whether this run is for Account or Site
    public BatchAccountsMilitaryMoAUploadedFiles(String runType) {
        this.runType = runType;
    }
    public BatchAccountsMilitaryMoAUploadedFiles() {
        this.runType ='Account';
    }
    private Task_Reassignment_Matrix__mdt taskSettings {
        get {
            return Task_Reassignment_Matrix__mdt.getInstance('Renew_File');            
        }
    }
    public static Set<String> getValidFileTypes() {
        Set<String> fileTypes = new Set<String>();
        for(ARCFileContentTypeMatrix__mdt arcFile : [
            SELECT IsValid__c, ObjectName__c, SupportedFileFormat__c, Type__c, DeveloperName
            FROM ARCFileContentTypeMatrix__mdt
            WHERE ObjectName__c IN ('sked__Location__c', 'Account')
            AND IsValid__c = true
        ]){
            fileTypes.add(arcFile.Type__c);
        }
        System.debug('fileTypes :'+fileTypes);
        return fileTypes;
    }

    global void execute(SchedulableContext sc) {
        System.debug('Batch execute 1 runType:'+runType);
        Database.executeBatch(new BatchAccountsMilitaryMoAUploadedFiles());
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Batch start runType:'+runType);
        Set<Id> recordsWithFiles = new Set<Id>();
        allowedfileTypesForTaskCreation = getValidFileTypes();
        
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecordTypeId = recordTypesAccount.get(BSF_Constants.MOBILE_ACCOUNT_RECORD_TYPE).getRecordTypeId();

        Map <String,Schema.RecordTypeInfo> recordTypesSite = sked__Location__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id siteMobileRecordTypeId = recordTypesSite.get(BSF_Constants.MOBILE_SITE_RECORD_TYPE).getRecordTypeId();
        String query;
        if (runType == 'Account') {
            query = 'SELECT Id, Name, Account_Manager__c, OwnerId ' +
                    'FROM Account ' +
                    'WHERE RecordTypeId = :mobileRecordTypeId';            

        }
        else if (runType == 'sked__Location__c') {
            query = 'SELECT Id, Name, sked__Account__c, OwnerId ' +
                    'FROM sked__Location__c ' +
                    'WHERE RecordTypeId = :siteMobileRecordTypeId';            
        }
        else {
            query = 'SELECT Id FROM Account WHERE Id = null';
        }        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('Batch execute 2');
        Set<Id> recordIdsInScope = (new Map<Id, sObject>(scope)).keySet();
        Set<Id> idsWithFiles = new Set<Id>();

        for (ContentDocumentLink cdl : [SELECT LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :recordIdsInScope]) {
            idsWithFiles.add(cdl.LinkedEntityId);
        }

        if (idsWithFiles.isEmpty()) {
            System.debug('No records in this chunk have files attached. Exiting execute method.');
            return;
        }

        List<sObject> scopeWithFiles = new List<sObject>();
        for (sObject record : scope) {
            if (idsWithFiles.contains(record.Id)) {
                scopeWithFiles.add(record);
            }
        }        
        
        try {            
            Map<Id, List<ContentDocumentLink>> recordToLinksMap = getContentDocumentLinks(idsWithFiles);
            Map<Id, ContentVersion> expiringFilesMap = getExpiringContentVersions(idsWithFiles);
            Map<Id, Set<Id>> locationToAccountsMap = getLocationToAccountMap(idsWithFiles);

            List<Task> tasksToCreate = generateTasks(scopeWithFiles, recordToLinksMap, expiringFilesMap, locationToAccountsMap);

            if (!tasksToCreate.isEmpty()) {
                Database.SaveResult[] results = Database.insert(tasksToCreate, false);
                processResults(results, tasksToCreate);
            }

        } catch (Exception e) {
            System.debug('Batch execution error: ' + e.getMessage()+' Stack:'+e.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch Finish - Completed: ' + runType);
        createDebugLog(bc);
        // If we completed the "Account" run, schedule the "sked__Location__c" run
        if (runType == 'Account') {
            System.debug('Scheduling next batch for Site Processing...');
            Database.executeBatch(new BatchAccountsMilitaryMoAUploadedFiles('sked__Location__c'));            
        }
    }
    
    private List<Task> generateTasks(List<sObject> records, 
                                 Map<Id, List<ContentDocumentLink>> recordToLinksMap, 
                                 Map<Id, ContentVersion> expiringFilesMap,
                                 Map<Id, Set<Id>> locationToAccountsMap) {  
        System.debug('Batch ==>  generateTasks !!!');
        List<Task> tasksToCreate = new List<Task>();
        Set<String> existingTaskKeys = getExistingTaskKeys();
       
        for (sObject record : records) {
            List<ContentDocumentLink> links = recordToLinksMap.get((Id) record.get('Id'));

            if (links != null) {
                for (ContentDocumentLink cdl : links) {
                    ContentVersion expiringFile = (expiringFilesMap.containsKey(cdl.ContentDocumentId)) ? expiringFilesMap.get(cdl.ContentDocumentId) : null; 
                    if (expiringFile != null ) {
                        if (record.getSObjectType() == Account.SObjectType) {
                            //Standard Account Task Assignment
                            String taskKey = record.get('Id') + '-' + cdl.ContentDocumentId;
                            String taskWhatId = (Id) record.get('Id');
                            if (!existingTaskKeys.contains(taskKey)) {
                                System.debug('Create new task for Account '+taskWhatId+' ===='+taskKey);
                                tasksToCreate.add(createTask((Account)record, expiringFile,taskWhatId));
                            }else{
                                System.debug('For Account '+taskWhatId+' this key is exits ===='+taskKey);  
                            }
                        } else if (record.getSObjectType() == sked__Location__c.SObjectType) {
                            System.debug('Site Task Assignment ::');
                            String taskWhatId = (Id) record.get('Id');
                            System.debug('Look for site :'+taskWhatId);
                            Set<Id> relatedAccounts = locationToAccountsMap.get((Id) record.get('Id'));
                            if (relatedAccounts != null) {
                                System.debug('Found Related account ::');
                                //Ensure one task per unique Account Manager
                                Map<Id, Id> uniqueAccountManagers = new Map<Id, Id>();
                                Map<Id, Account> accIdVsAccMap = new Map<Id, Account>();
                                for(Account acc : [select id,name,Account_Manager__c,OwnerId  from Account where id in :relatedAccounts]){
                                    accIdVsAccMap.put(acc.id,acc);
                                }
                                System.debug('accIdVsAccMap:'+accIdVsAccMap);
                                for (Id accId : accIdVsAccMap.keySet()) {
                                    if (accIdVsAccMap.get(accId).Account_Manager__c != null && !uniqueAccountManagers.containsKey(accId)) {
                                        uniqueAccountManagers.put(accIdVsAccMap.get(accId).Account_Manager__c, accId);
                                    }else{
                                        System.debug('Account Manager not exist');
                                        //when there is no Account manager then either Account Team or Owner will be assigned the task
                                        uniqueAccountManagers.put(accIdVsAccMap.get(accId).OwnerId, accId);
                                    }
                                }
                                System.debug('uniqueAccountManagers ===>'+uniqueAccountManagers);
                                //Create task only for distinct Account Managers
                                for (Id amId : uniqueAccountManagers.keySet()) {
                                    String taskKey = taskWhatId + '-' + cdl.ContentDocumentId;
                                    if (!existingTaskKeys.contains(taskKey)) {
                                        System.debug('Create new task for Site '+taskWhatId+' ===='+taskKey);  
                                        tasksToCreate.add(createTask(accIdVsAccMap.get(uniqueAccountManagers.get(amId)), expiringFile,taskWhatId));
                                    }else{
                                        System.debug('For Site '+taskWhatId+' this key is exits ===='+taskKey);  
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return tasksToCreate;
    }

    
    private Map<Id, List<ContentDocumentLink>> getContentDocumentLinks(Set<Id> recordIds) {
        System.debug('Batch==  getContentDocumentLinks !!!');
        Map<Id, List<ContentDocumentLink>> accountToLinksMap = new Map<Id, List<ContentDocumentLink>>();
        for(ContentDocumentLink cdl : [SELECT LinkedEntityId, ContentDocumentId 
                                     FROM ContentDocumentLink 
                                     WHERE LinkedEntityId IN :recordIds]) {
            if(!accountToLinksMap.containsKey(cdl.LinkedEntityId)) {
                accountToLinksMap.put(cdl.LinkedEntityId, new List<ContentDocumentLink>());
            }
            accountToLinksMap.get(cdl.LinkedEntityId).add(cdl);
        }
        return accountToLinksMap;
    }
    
    private Map<Id, ContentVersion> getExpiringContentVersions(Set<Id> recordIds) {
        System.debug('Batch==  getExpiringContentVersions !!!');
        Map<Id, ContentVersion> latestVersionMap = new Map<Id, ContentVersion>();
        Set<Id> contentDocIds = new Set<Id>();
        for(ContentDocumentLink cdl : [SELECT ContentDocumentId 
                                       FROM ContentDocumentLink 
                                       WHERE LinkedEntityId IN :recordIds]) {
            contentDocIds.add(cdl.ContentDocumentId);            
        }
        System.debug('Batch== :'+contentDocIds);
        Date expirationThreshold = Date.today().addDays(taskSettings.Task_Creation_Threshold_In_Days__c.intValue());
        for(ContentVersion cv : [SELECT ContentDocumentId,Description, LastModifiedDate, Title, FileType,Expiry_Date__c
                                FROM ContentVersion 
                                WHERE ContentDocumentId IN :contentDocIds
                                AND IsLatest = true
                                AND Description = :allowedfileTypesForTaskCreation
                                AND Expiry_Date__c <= :expirationThreshold
                                ORDER BY LastModifiedDate DESC]) {
            if(!latestVersionMap.containsKey(cv.ContentDocumentId)) {
                
                latestVersionMap.put(cv.ContentDocumentId, cv);
            }
        }
        System.debug('Batch== latestVersionMap:'+latestVersionMap);
        return latestVersionMap;
    }

    private Map<Id, Set<Id>> getLocationToAccountMap(Set<Id> locationIds) {
        System.debug('Batch==  getLocationToAccountMap !!!');
        Map<Id, Set<Id>> locationToAccountsMap = new Map<Id, Set<Id>>();
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecordTypeId = recordTypesAccount.get(BSF_Constants.MOBILE_ACCOUNT_RECORD_TYPE).getRecordTypeId();
        for (sked_Location_Account__c locAcc : [
            SELECT sked_Location__c, sked_Account__c 
            FROM sked_Location_Account__c 
            WHERE sked_Location__c IN :locationIds
            AND sked_Account__r.RecordTypeId = :mobileRecordTypeId
        ]) {
            if (!locationToAccountsMap.containsKey(locAcc.sked_Location__c)) {
                locationToAccountsMap.put(locAcc.sked_Location__c, new Set<Id>());
            }
            locationToAccountsMap.get(locAcc.sked_Location__c).add(locAcc.sked_Account__c);
        }
        System.debug('Batch==>  locationToAccountsMap :'+locationToAccountsMap);
        return locationToAccountsMap;
    }
    
    private Set<String> getExistingTaskKeys() {
        System.debug('Batch==>  getExistingTaskKeys :');
        Set<String> existingTaskKeys = new Set<String>();
        for(Task t : [SELECT WhatId, CallObject 
                      FROM Task 
                      WHERE Subject = :taskSettings.Task_Subject__c                     
                      AND CallObject != null]) {
            //System.debug('keys=======>'+t.WhatId + '-' + t.CallObject);
            existingTaskKeys.add(t.WhatId + '-' + t.CallObject);
        }
        return existingTaskKeys;
    }
    
    private Task createTask(Account acc, ContentVersion version, String taskWhatId) {
        System.debug('Batch ==>  createTask record:'+acc.id+' taskWhatId:'+taskWhatId+' version:'+version);
        Id accountId = acc.id;
        Id ownerId = acc.Account_Manager__c != null ? acc.Account_Manager__c : acc.OwnerId;
        Id taskOwnerId = AccountTeamMemberHelper.determineTaskOwner(acc, ownerId);
        Date contentExpiryDate = version.Expiry_Date__c;
        Date taskDueDate = (contentExpiryDate != null) ? contentExpiryDate.addDays(-taskSettings.Due_Date_Offset__c.intValue()) : null; 
        System.debug('contentExpiryDate ::'+contentExpiryDate+' taskDueDate:'+taskDueDate+' offset:'+taskSettings.Due_Date_Offset__c);
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        String fileUrl = baseUrl + '/lightning/r/ContentDocument/' + version.ContentDocumentId + '/view';

        String description = String.format(taskSettings.Description__c, new List<String>{version.Title, version.FileType})
                             + '\n\n' + 'View file here: ' + fileUrl;

        return new Task(
            WhatId = taskWhatId,  
            OwnerId = taskOwnerId,  
            Subject = taskSettings.Task_Subject__c,
            Description = description,
            Status = 'Not Started',
            ActivityDate =  taskDueDate,
            CallObject = version.ContentDocumentId
        );
    }
    private void processResults(Database.SaveResult[] results, List<Task> tasks) {
        for(Integer i = 0; i < results.size(); i++) {
            if(results[i].isSuccess()) {
                taskDetails.add('Task: ' + results[i].getId() + ' for Account: ' + tasks[i].WhatId);                
            } else {
                taskDetails.add('Failed to create task for Account: ' + tasks[i].WhatId + 
                              ' Error: ' + results[i].getErrors()[0].getMessage());                
            }
        }
    }
    
    private void createDebugLog(Database.BatchableContext bc) {
        if(taskDetails.size() > 0) {
            BSF_Error_Log__c batchLog = new BSF_Error_Log__c(
            ApexClass__c = 'BatchAccountsMilitaryMoAUploadedFiles',
            Object_RecordId__c = bc.getJobId(),
            Error_Description_Long__c = String.join(taskDetails, '\n')            
            );        
        insert batchLog;
        }
    }
}