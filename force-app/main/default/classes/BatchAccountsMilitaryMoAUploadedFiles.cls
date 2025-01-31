global class BatchAccountsMilitaryMoAUploadedFiles implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    private static final Integer QUERY_LIMIT = 50000;
    private List<String> taskDetails = new List<String>();        

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

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchAccountsMilitaryMoAUploadedFiles());
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> accountsWithFiles = new Set<Id>();
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecordTypeId = recordTypesAccount.get(BSF_Constants.MOBILE_ACCOUNT_RECORD_TYPE).getRecordTypeId();
        //Id mobileRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :MOBILE_ACCOUNT_RECORD_TYPE LIMIT 1].Id;
        for(ContentDocumentLink cdl : [SELECT LinkedEntityId 
                                       FROM ContentDocumentLink 
                                       WHERE LinkedEntityId IN (SELECT Id FROM Account WHERE RecordTypeId = :mobileRecordTypeId)
                                      ]) {
            accountsWithFiles.add(cdl.LinkedEntityId);
        }
        return Database.getQueryLocator([
            SELECT Id, Name, Account_Manager__c, OwnerId 
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
    
    private List<Task> generateTasks(List<Account> accounts, Map<Id, List<ContentDocumentLink>> accountToLinksMap, Map<Id, ContentVersion> latestVersionMap) {
        List<Task> tasksToCreate = new List<Task>();
        Set<String> existingTaskKeys = getExistingTaskKeys();
        Date thresholdDate = Date.today().addDays(-taskSettings.Creation_Date_Offset__c.intValue());
        if(Test.isRunningTest()){
            thresholdDate = Date.today().addDays(5);                                           
        }
        
        for(Account acc : accounts) {
            List<ContentDocumentLink> links = accountToLinksMap.get(acc.Id);
            if(links != null) {
                for(ContentDocumentLink cdl : links) {
                    ContentVersion latestVersion = latestVersionMap.get(cdl.ContentDocumentId);  
                    String taskKey = acc.Id + '-' + cdl.ContentDocumentId;                  
                    if(latestVersion != null && latestVersion.LastModifiedDate.date() < thresholdDate && !existingTaskKeys.contains(taskKey)) {
                        tasksToCreate.add(createTask(acc, latestVersion));
                    }
                }
            }
        }
        return tasksToCreate;
    }

    private Set<String> getExistingTaskKeys() {
        Set<String> existingTaskKeys = new Set<String>();
        for(Task t : [SELECT WhatId, CallObject 
                      FROM Task 
                      WHERE Subject = :taskSettings.Task_Subject__c                      
                      AND CallObject != null]) {
            existingTaskKeys.add(t.WhatId + '-' + t.CallObject);
        }
        return existingTaskKeys;
    }
    
    private Task createTask(Account acc, ContentVersion version) {
        Id newTaskOwnerId = acc.Account_Manager__c != null ? acc.Account_Manager__c : acc.OwnerId;
        Id taskOwnerId = AccountTeamMemberHelper.determineTaskOwner(acc.Id, newTaskOwnerId);
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        String fileUrl = baseUrl + '/lightning/r/ContentDocument/' + version.ContentDocumentId + '/view';

        String description = String.format(taskSettings.Description__c, new List<String>{version.Title, version.FileType})
                             + '\n\n' + 'View file here: ' + fileUrl;        

        return new Task(
            WhatId = acc.Id,
            OwnerId = taskOwnerId,
            Subject = taskSettings.Task_Subject__c,
            Description = description,            
            Status = 'Not Started',
            ActivityDate = Date.today().addDays(taskSettings.Due_Date_Offset__c.intValue()),
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