global class BatchAccountsMilitaryMoAUploadedFiles implements Database.Batchable<sObject>, Database.Stateful {
    private static final Integer QUERY_LIMIT = 50000;
    private static final String MOBILE_ACCOUNT_RECORD_TYPE = BSF_Constants.MOBILE_ACCOUNT_RECORD_TYPE;

    private List<String> taskDetails = new List<String>();
    private Integer successCount = 0;
    private Integer failureCount = 0;

    private ARCFileContentTypeMatrix__mdt arcFileSettings {
        get {
            return ARCFileContentTypeMatrix__mdt.getInstance('Military_MoA_Local');            
        }
    }

    private Task_Reassignment_Matrix__mdt taskSettings {
        get {
            return Task_Reassignment_Matrix__mdt.getInstance('Renew_Military_MoA');            
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> accountsWithFiles = new Set<Id>();
        Id mobileRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :MOBILE_ACCOUNT_RECORD_TYPE LIMIT 1].Id;
        for(ContentDocumentLink cdl : [SELECT LinkedEntityId 
                                       FROM ContentDocumentLink 
                                       WHERE LinkedEntityId IN (SELECT Id FROM Account WHERE RecordTypeId = :mobileRecordTypeId)
                                      ]) {
            accountsWithFiles.add(cdl.LinkedEntityId);
        }
        return Database.getQueryLocator([
            SELECT Id, Name, Account_Manager__c 
            FROM Account 
            WHERE Id IN :accountsWithFiles
            LIMIT :QUERY_LIMIT
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        try {
            Set<Id> accountIds = new Set<Id>();
            for(Account acc : scope) {
                accountIds.add(acc.Id);
            }
            
            Map<Id, List<ContentDocumentLink>> accountToLinksMap = getContentDocumentLinks(accountIds);
            Map<Id, ContentVersion> latestVersionMap = getContentVersions(accountIds);
            
            List<Task> tasksToCreate = generateTasks(scope, accountToLinksMap, latestVersionMap);
            
            if(!tasksToCreate.isEmpty()) {
                Database.SaveResult[] results = Database.insert(tasksToCreate, false);
                processResults(results, tasksToCreate);
            }
            
        } catch(Exception e) {
            taskDetails.add('Batch execution error: ' + e.getMessage());
            failureCount++;
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        createDebugLog(bc);
    }
    
    private Map<Id, List<ContentDocumentLink>> getContentDocumentLinks(Set<Id> accountIds) {
        Map<Id, List<ContentDocumentLink>> accountToLinksMap = new Map<Id, List<ContentDocumentLink>>();
        for(ContentDocumentLink cdl : [SELECT LinkedEntityId, ContentDocumentId 
                                     FROM ContentDocumentLink 
                                     WHERE LinkedEntityId IN :accountIds]) {
            if(!accountToLinksMap.containsKey(cdl.LinkedEntityId)) {
                accountToLinksMap.put(cdl.LinkedEntityId, new List<ContentDocumentLink>());
            }
            accountToLinksMap.get(cdl.LinkedEntityId).add(cdl);
        }
        return accountToLinksMap;
    }
    
    private Map<Id, ContentVersion> getContentVersions(Set<Id> accountIds) {
        Map<Id, ContentVersion> latestVersionMap = new Map<Id, ContentVersion>();
        Set<Id> contentDocIds = new Set<Id>();
        for(ContentDocumentLink cdl : [SELECT ContentDocumentId 
                                       FROM ContentDocumentLink 
                                       WHERE LinkedEntityId IN :accountIds]) {
            contentDocIds.add(cdl.ContentDocumentId);
        }
        for(ContentVersion cv : [SELECT ContentDocumentId, LastModifiedDate, Title, FileType
                                FROM ContentVersion 
                                WHERE ContentDocumentId IN :contentDocIds
                                AND IsLatest = true
                                AND Description = :arcFileSettings.Type__c
                                ORDER BY LastModifiedDate DESC]) {
            if(!latestVersionMap.containsKey(cv.ContentDocumentId)) {
                latestVersionMap.put(cv.ContentDocumentId, cv);
            }
        }
        return latestVersionMap;
    }
    
    private List<Task> generateTasks(List<Account> accounts, 
                                   Map<Id, List<ContentDocumentLink>> accountToLinksMap,
                                   Map<Id, ContentVersion> latestVersionMap) {
        List<Task> tasksToCreate = new List<Task>();
        Date thresholdDate = Date.today().addDays(-taskSettings.Creation_Date_Offset__c.intValue());
        
        for(Account acc : accounts) {
            List<ContentDocumentLink> links = accountToLinksMap.get(acc.Id);
            if(links != null) {
                for(ContentDocumentLink cdl : links) {
                    ContentVersion latestVersion = latestVersionMap.get(cdl.ContentDocumentId);
                    if(latestVersion != null && latestVersion.LastModifiedDate.date() < thresholdDate) {
                        tasksToCreate.add(createTask(acc, latestVersion));
                    }
                }
            }
        }
        return tasksToCreate;
    }
    
    private Task createTask(Account acc, ContentVersion version) {
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        String fileUrl = baseUrl + '/lightning/r/ContentDocument/' + version.ContentDocumentId + '/view';

        String description = String.format(taskSettings.Description__c, new List<String>{version.Title, version.FileType, String.valueOf(taskSettings.Creation_Date_Offset__c)})
                             + '\n\n' + 'View file here: ' + fileUrl;
        return new Task(
            WhatId = acc.Id,
            OwnerId = acc.Account_Manager__c,
            Subject = taskSettings.Task_Subject__c,
            Description = description,            
            Status = 'Not Started',
            ActivityDate = Date.today().addDays(taskSettings.Due_Date_Offset__c.intValue())
        );
    }
    
    private void processResults(Database.SaveResult[] results, List<Task> tasks) {
        for(Integer i = 0; i < results.size(); i++) {
            if(results[i].isSuccess()) {
                taskDetails.add('Task: ' + results[i].getId() + ' for Account: ' + tasks[i].WhatId);
                successCount++;
            } else {
                taskDetails.add('Failed to create task for Account: ' + tasks[i].WhatId + 
                              ' Error: ' + results[i].getErrors()[0].getMessage());
                failureCount++;
            }
        }
    }
    
    private void createDebugLog(Database.BatchableContext bc) {
        BSF_Error_Log__c batchLog = new BSF_Error_Log__c(
            ApexClass__c = 'BatchAccountsMilitaryMoAUploadedFiles',
            Object_RecordId__c = bc.getJobId(),
            Error_Description_Long__c = String.join(taskDetails, '\n'),
            Error_Description__c = 'Total Record Counts : ' + successCount + failureCount            
        );        
        insert batchLog;
    }
}