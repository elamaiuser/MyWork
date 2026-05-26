/* @Description: 1. Below service class supports various Task relared functionalities working in different contexts.
* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 08/30/2024			         Barnojit Sharma		  Within the Sponsor Planning Report task, populate the referencing Opp/Drive Sponsor Planning Report. (Logic for HRP-5337)
* 10/07/2024					 Balaji N				  HRP-12583 new method stopPublicityOrderTaskCompletionWithoutOrder
* 11/07/2024			         Barnojit Sharma		  Update Task: 72 Hour Check in - System Generated/Details/Checklist. (Logic for HRP-12627)
* 13/02/2025			         Barnojit Sharma		  Checklist for Post Drive Analysis task Enhancements. (Logic for HRP-13426)
************************************************************************************************************************************************
*/ 

public with sharing class TaskService {
    
    /* HRP-5763
     * 	MVP: Custom Tasks do not populate on Fixed Sites records 
     *  
     */
    
    public static void validateTaskRecordTypeForFixSite(List<Task> newTaskList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();

        List<String> RESTRICTED_TASKS_NAMES = new List<String>();

        if(String.isNotBlank(System.Label.FIXSITE_RESTRICTED_TASKS)){

            List<Task_Definition__c> def = [SELECT Name, 
                                                Task_Type__c 
                                            FROM Task_Definition__c
                                            WHERE Task_Type__c IN :System.Label.FIXSITE_RESTRICTED_TASKS.split(',')
                                            AND Name != null];
            if(def != null && !def.isEmpty()) {
                for(Task_Definition__c taskDef : def){
                    RESTRICTED_TASKS_NAMES.add(taskDef.Name);
                }
            }
        }

        if(RESTRICTED_TASKS_NAMES.isEmpty()){
            return;
        }


        for (Task t : newTaskList) {
            if (t.WhatId == null || !RESTRICTED_TASKS_NAMES.contains(t.Subject)){
                continue;
            }
            SObjectType parentType = t.WhatId.getSObjectType();
            if(parentType == Account.sObjectType){
                accountIds.add(t.WhatId);
            } else if(parentType == Opportunity.sObjectType) {
                opportunityIds.add(t.WhatId);
            }
        }

        if (accountIds.isEmpty() && opportunityIds.isEmpty()) return;

        
        Set<Id> fixedSiteIds = new Set<Id>();

        if(!accountIds.isEmpty()) {
            fixedSiteIds.addAll(new Map<Id, Account>([SELECT Id 
                                                        FROM Account
                                                        WHERE Id IN :accountIds
                                                        AND RecordType.Name = 'Fixed Site Account'
                                                    ]).keySet());
        }

        if(!opportunityIds.isEmpty()) {
            fixedSiteIds.addAll(new Map<Id, Opportunity>([SELECT Id 
                                                            FROM Opportunity
                                                            WHERE Id IN :opportunityIds
                                                            AND RecordType.Name = 'Fixed Site Opp'
                                                        ]).keySet());
        }

        if (fixedSiteIds.isEmpty()) return;

        for (Task t : newTaskList) {
            if (t.WhatId != null && RESTRICTED_TASKS_NAMES.contains(t.Subject) 
                    && fixedSiteIds.contains(t.WhatId) && !Test.isRunningTest()) {
                        t.addError('Cannot create '+ String.join(RESTRICTED_TASKS_NAMES, '/')+' Tasks for Fix Site Account/Opportunity.');
            }
        }
    }
    //HRP-5337 changes starts here
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getReportLinks(Id taskId) {
        System.debug('getReportLinks taskId : '+taskId);
        List<Map<String,String>> result = new List<Map<String,String>>();
        String opportunityId = '';
        String driveId = '';
        String driveExternalId = '';
        String driveUFID = '';
        if(taskId != null){
            List<Task> taskList = [SELECT Type,
                                            WhatId
                                        FROM Task 
                                        WHERE Id = :taskId
                                        AND Type != null];
            if(!taskList.isEmpty() && taskList[0].Type != null){
                Map<Id,Sked_Drive__c> oppVsDocMap = new Map<Id,Sked_Drive__c>();
                //HRP-12627 changes starts
                if(taskList[0].WhatId != null){
                    opportunityId = taskList[0].WhatId;
                    List<Sked_Drive__c> docList = [SELECT Id,
                                                            sked_Opportunity__c,
                                                            sked_Drive_External_Id__c,
                                                            sked_UFID__c
                                                    FROM Sked_Drive__c 
                                                    WHERE sked_Opportunity__c = :taskList[0].WhatId
                                                    AND sked_Is_Surrogate__c = false
                                                    ORDER BY createdDate DESC];
                    if(!docList.isEmpty()){
                        driveId = docList[0].Id;
                        driveExternalId = docList[0].sked_Drive_External_Id__c != null ? docList[0].sked_Drive_External_Id__c : '';
                        driveUFID = docList[0].sked_UFID__c != null ? docList[0].sked_UFID__c : '';
                    }
                }
                //HRP-12627 changes ends
                for(Task_Report_Link__mdt metadata : [SELECT Report_Link__c, 
                                                                Report_Name__c,
                                                                DeveloperName
                                                        FROM Task_Report_Link__mdt 
                                                        WHERE Task_Type__c =:taskList[0].Type
                                                        AND Active__c = true
                                                        ORDER BY Report_Name__c ASC]){
                
                    Map<String,String> tempMap = new Map<String,String>();
                    tempMap.put('name', metadata.Report_Name__c);
                    //HRP-12627 changes starts
                    String reportLink = metadata.Report_Link__c;
                    reportLink = reportLink.replace('{{opportunityId}}',opportunityId);
                    reportLink = reportLink.replace('{{driveId}}',driveId);
                    reportLink = reportLink.replace('{{driveExternalId}}',driveExternalId);
                    reportLink = reportLink.replace('{{driveUFID}}',driveUFID);
                    tempMap.put('link', reportLink);
                    //HRP-12627 changes ends
                    tempMap.put('id', metadata.DeveloperName);
                    result.add(tempMap);
                }
            }
        }
        return result;
    }
    //HRP-5337 changes ends here
    //HRP-12142 --> Start
    public static void updateRelatedAccountAndOpportunity(List<Task> taskList){
        
        List<String> taskSubjects = new List<String>{};
        List<Task_Definition__c> def = [SELECT Name, 
                                            Task_Type__c 
                                        FROM Task_Definition__c
                                        WHERE Task_Type__c IN (:BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_SBPM, :BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_AM)
                                        AND Name != null];
        for(Task_Definition__c taskDef : def){
            taskSubjects.add(taskDef.Name);
        }
        if(taskSubjects.isEmpty()){
                return;
        }
        Set<Id> postDriveAnalysisTask = new Set<Id>();
        List<BSF_Task_Checklist__c> taskChecklistRecords = new List<BSF_Task_Checklist__c>();
        try {
            
            for(task newTask: taskList){
                if (newTask.Status.equalsIgnoreCase(BSF_Constants.STATUS_COMPLETED) && taskSubjects.contains(newTask.Subject)) {
                    postDriveAnalysisTask.add(newTask.Id);
                }
            }

            if (!postDriveAnalysisTask.isEmpty()) {
                taskChecklistRecords = [SELECT Id, Unique_Name__c, Input_Long_Text_Area__c, Input_Checkbox__c, Picklist_Input_1__c, Picklist_Input_2__c, TaskLookup__c, OpportunityLookup__c, OpportunityLookup__r.AccountId  FROM BSF_Task_Checklist__c WHERE TaskType__c IN :taskSubjects AND Unique_Name__c IN ('Account_Strategy__c', 'Account_Strategy_Notes__c', 'Gray_Sky_Account__c', 'Rollover_Consideration__c')];
            }
            Map<Id, List<BSF_Task_Checklist__c>> taskVsTaskChecklistRecMap = new Map<Id, List<BSF_Task_Checklist__c>>();
            for (BSF_Task_Checklist__c taskChecklist : taskChecklistRecords) {
                if (!taskVsTaskChecklistRecMap.containsKey(taskChecklist.TaskLookup__c)) {
                    taskVsTaskChecklistRecMap.put(taskChecklist.TaskLookup__c, new List<BSF_Task_Checklist__c>{taskChecklist});
                } else {
                    taskVsTaskChecklistRecMap.get(taskChecklist.TaskLookup__c).add(taskChecklist);
                }
            }

            Map<Id, Map<String,BSF_Task_Checklist__c>> taskVsTaskChecklistMap = new Map<Id, Map<String,BSF_Task_Checklist__c>>();

            for (Id taskId : taskVsTaskChecklistRecMap.keySet()) {
                Map<String,BSF_Task_Checklist__c> checklistMap = new Map<String,BSF_Task_Checklist__c>();
                for (BSF_Task_Checklist__c checklist : taskVsTaskChecklistRecMap.get(taskId)) {
                    checklistMap.put(checklist.Unique_Name__c, checklist);
                }
                taskVsTaskChecklistMap.put(taskId, checklistMap);
            }

            List<Account> accountsToUpdate = new List<Account>();
            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

            for (Id taskId : taskVsTaskChecklistMap.keySet()) {
                Account updateAcc = new Account();
                Opportunity updateOpp = new Opportunity();
                for (String key : taskVsTaskChecklistMap.get(taskId).keySet()) {
                    BSF_Task_Checklist__c taskChecklistRec = taskVsTaskChecklistMap.get(taskId).get(key);
                    if (key.equalsIgnoreCase('Account_Strategy__c')) {
                        updateAcc.Id = taskChecklistRec.OpportunityLookup__r.AccountId;
                        updateAcc.Account_Strategy__c = taskChecklistRec.Picklist_Input_1__c;
                    } 
                    else if(key.equalsIgnoreCase('Account_Strategy_Notes__c')){
                        updateAcc.Id = taskChecklistRec.OpportunityLookup__r.AccountId;
                        updateAcc.Account_Strategy_Notes__c = taskChecklistRec.Input_Long_Text_Area__c;
                    }
                    else if(key.equalsIgnoreCase('Gray_Sky_Account__c')){
                        updateAcc.Id = taskChecklistRec.OpportunityLookup__r.AccountId;
                        updateAcc.Gray_Sky_Account__c = taskChecklistRec.Input_Checkbox__c;
                    }
                    else if(key.equalsIgnoreCase('Rollover_Consideration__c')){
                        updateOpp.Id = taskChecklistRec.OpportunityLookup__c;
                        updateOpp.Rollover_Consideration__c = taskChecklistRec.Picklist_Input_2__c;
                    }
                }
                    accountsToUpdate.add(updateAcc);
                    opportunitiesToUpdate.add(updateOpp);
            }

            if (!opportunitiesToUpdate.isEmpty()) {
                Database.SaveResult[] srList = Database.update(opportunitiesToUpdate , false);
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating Opportunity from Task trigger','TaskService','updateRelatedAccountAndOpportunity','Error','Error in updating Opportunity field');
                InsertBsfErrorLog.insertBsfErrors(logList);
            }

            if (!accountsToUpdate.isEmpty()) {
                Database.SaveResult[] srList = Database.update(accountsToUpdate , false);
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating Account from Task trigger','TaskService','updateRelatedAccountAndOpportunity','Error','Error in updating Account field');
                InsertBsfErrorLog.insertBsfErrors(logList);
            }
        } catch (Exception ex) {
            String taskIds = '';
            for (Task task : taskList) {
                taskIds+= task.Id+'; ';
            }
            List<BSF_Error_Log__c> errorLogToInsert = new List<BSF_Error_Log__c>{
                BSF_Utilities.createBsfErrorLogForExceptions( ex, 'TaskService', 'updateRelatedAccountAndOpportunity', 'Error', 'Error occured while updating related Account and Opportunity', 'Task', taskIds )};

            Database.SaveResult[] logInsertResult = Database.insert(errorLogToInsert, FALSE);
        }

    }
    // HRP-12142 --> end
    
    //HRP-12583 Start
    public static void stopPublicityOrderTaskCompletionWithoutOrder(List<Task> newTasksList,Map<Id,Task> oldMap)
    {
        Task_Definition__c publicityOrder;
        List<Task_Definition__c> def = [SELECT Name, 
                                            Task_Type__c 
                                        FROM Task_Definition__c
                                        WHERE Task_Type__c IN (:BSF_Constants.TASK_TYPE_PUBLICITY_ORDER_NOT_CREATED)
                                        AND Name != null];
        if(def.isEmpty()){
            return;
        }
        for(Task_Definition__c taskDef : def){
            publicityOrder = taskDef;
        }
        
        Set<Id> oppIdSet = new Set<Id>();
        List<Task> pubOrderTaskList = new List<Task>();
		for(Task t :newTasksList)
        {
            if(t.Subject == publicityOrder.Name && OldMap != null && OldMap.get(t.Id).Status != t.Status && t.Status == 'Completed')
            {
                pubOrderTaskList.add(t);
                oppIdSet.add(t.WhatId);
            }
        }
        
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id,No_Publicity_Needed__c,(Select Id from orders) from Opportunity where Id IN:oppIdSet]);
        
        for(Task t :newTasksList)
        {
            if(oppMap.containskey(t.WhatId) && pubOrderTaskList.Contains(t))
            {
                Opportunity relOpp = oppMap.get(t.whatId);
                if(relOpp.orders.isEmpty() && !relOpp.No_Publicity_Needed__c)
                {
                    t.addError('No Publicity Items are ordered. Please create the Publicity Order or check "No Publicity Needed" on the opportunity before completing the task.');
                }
            }
        }
        
    }
    //HRP-12583 End
    public static void updateRelatedAccountAndOpportunity(List<Task> newList, Map<Id, Task> oldMap){
        List<String> subjectList = new List<String>();
        List<Task_Definition__c> def = [SELECT Name, 
                                            Task_Type__c 
                                        FROM Task_Definition__c
                                        WHERE Task_Type__c IN (:BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_SBPM, :BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_AM)
                                        AND Name != null];
        if(def != null && !def.isEmpty()) {
            for(Task_Definition__c taskDef : def){
                subjectList.add(taskDef.Name);
            }
        }
        if(subjectList.isEmpty()){
                return;
        }
        Map<String, Map<String,String>> taskVsFieldVsObjectMap = BSFTaskChecklistTriggerHandler.taskVsFieldVsObjectMap;
        Map<String,String> fieldVsObjectMap = new Map<String,String>();
        if(taskVsFieldVsObjectMap != null){
            for(String subject : subjectList){
                if(taskVsFieldVsObjectMap.containsKey(subject)){
                    fieldVsObjectMap.putAll(taskVsFieldVsObjectMap.get(subject));
                }
            }
        }
        Map<String,List<BSF_Task_Checklist__c>> taskSubjectVsChecklistMap = new Map<String,List<BSF_Task_Checklist__c>>();
        Map<Id,String> taskVsSubjectMap = new Map<Id,String>();
        
        List<BSF_Task_Checklist__c> checklists = new List<BSF_Task_Checklist__c>();
        Map<String,Id> taskVsOppMap = new Map<String,Id>();
        Map<String,Opportunity> taskVsOpportunityMap = new Map<String,Opportunity>();
        Map<String,Account> taskVsAccountMap = new Map<String,Account>();
        if(newList != null && !newList.isEmpty()){
            for(Task tsk : newList){
                if(tsk.Id != null && tsk.WhatId != null //&& String.valueOf(task.WhatId).startsWith(BSFTaskChecklistTriggerHandler.oppPrefix)
                        && String.isNotBlank(tsk.Subject) && subjectList.contains(tsk.Subject)
                        && String.isNotBlank(tsk.Status) && tsk.Status.equals(BSF_Constants.STATUS_COMPLETED)
                        && (oldMap == null || oldMap.isEmpty() || (oldMap.containsKey(tsk.Id) && oldMap.get(tsk.Id).Status != tsk.Status))){
                            taskVsOppMap.put(tsk.Id,tsk.WhatId);
                            taskVsSubjectMap.put(tsk.Id,tsk.Subject);
                }
            }
        }
        System.debug('fieldVsObjectMap : '+fieldVsObjectMap);
        System.debug('taskVsOppMap : '+taskVsOppMap);
        if(!taskVsOppMap.isEmpty() && !fieldVsObjectMap.isEmpty()){
            checklists = [SELECT Id, 
                                Name, 
                                Unique_Name__c, 
                                Input_Long_Text_Area__c, 
                                Input_Short_Text_1__c, 
                                Input_Short_Text_2__c, 
                                Input_Checkbox__c, 
                                Picklist_Input_1__c, 
                                Picklist_Input_2__c, 
                                Input_Number__c, 
                                TaskLookup__c, 
                                TaskType__c, 
                                OpportunityLookup__c 
                            FROM BSF_Task_Checklist__c
                            WHERE TaskLookup__c IN : taskVsOppMap.keySet()
                            AND Unique_Name__c IN : fieldVsObjectMap.keySet()
                            WITH SYSTEM_MODE];
            if(!checklists.isEmpty()){
                for(BSF_Task_Checklist__c taskChecklist : checklists){
                    if(taskVsSubjectMap.containsKey(taskChecklist.TaskLookup__c) 
                            && subjectList.contains(taskVsSubjectMap.get(taskChecklist.TaskLookup__c))){
                                if(taskSubjectVsChecklistMap.isEmpty() || !taskSubjectVsChecklistMap.containsKey(taskVsSubjectMap.get(taskChecklist.TaskLookup__c))){
                                    taskSubjectVsChecklistMap.put(taskVsSubjectMap.get(taskChecklist.TaskLookup__c),new List<BSF_Task_Checklist__c>());
                                }
                                taskSubjectVsChecklistMap.get(taskVsSubjectMap.get(taskChecklist.TaskLookup__c)).add(taskChecklist);
                    }
                }
            }
        }
        System.debug('checklists : '+checklists);
        if(!checklists.isEmpty() && !taskVsOppMap.isEmpty()){
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
            Map<Id,Account> accMap = new Map<Id,Account>();
            List<Id> accIds = new List<Id>();
            List<String> oppFields = new List<String>();
            List<String> accFields = new List<String>();
            for(String field : fieldVsObjectMap.keySet()){
                if(fieldVsObjectMap.get(field).equals('Account')){
                    accFields.add(field);
                }else if(fieldVsObjectMap.get(field).equals('Opportunity')){
                    oppFields.add(field);
                }
            }
            String oppQueryStr = 'SELECT Id, AccountId';
            if(!oppFields.isEmpty()){
                for(String field : oppFields){
                    oppQueryStr += ', '+field;
                }
            }
            oppQueryStr = oppQueryStr + ' FROM Opportunity WHERE Id IN (\''+String.join(taskVsOppMap.values(),'\',\'')+'\') AND AccountId != null';
            System.debug('oppQueryStr : '+oppQueryStr);
            List<Opportunity> oppList = Database.query(oppQueryStr,AccessLevel.SYSTEM_MODE);
            if(!oppList.isEmpty()){
                oppMap = new Map<Id, Opportunity>(oppList);
            }
            System.debug('oppMap : '+oppMap);
            for(String taskId : taskVsOppMap.keySet()){
                if(!oppMap.isEmpty() && oppMap.containsKey(taskVsOppMap.get(taskId))){
                    taskVsOpportunityMap.put(taskId,oppMap.get(taskVsOppMap.get(taskId)));
                    accIds.add(oppMap.get(taskVsOppMap.get(taskId)).AccountId);
                }
            }
            System.debug('accIds : '+accIds);
            if(!accIds.isEmpty()){
                String accQueryStr = 'SELECT Id';
                if(!accFields.isEmpty()){
                    for(String field : accFields){
                        accQueryStr += ', '+field;
                    }
                }
                accQueryStr = accQueryStr + ' FROM Account WHERE Id IN (\''+String.join(accIds,'\',\'')+'\')';
                System.debug('accQueryStr : '+accQueryStr);
                List<Account> accList = Database.query(accQueryStr,AccessLevel.SYSTEM_MODE);
                if(!accList.isEmpty()){
                    accMap = new Map<Id, Account>(accList);
                }
                System.debug('accMap : '+accMap);
                for(String taskId : taskVsOpportunityMap.keySet()){
                    if(!accMap.isEmpty() && accMap.containsKey(taskVsOpportunityMap.get(taskId).AccountId)){
                        taskVsAccountMap.put(taskId,accMap.get(taskVsOpportunityMap.get(taskId).AccountId));
                    }
                }
            }
            System.debug('taskVsOpportunityMap : '+taskVsOpportunityMap);
            System.debug('taskVsAccountMap : '+taskVsAccountMap);
            if(!taskSubjectVsChecklistMap.isEmpty()){
                for(String subject : taskSubjectVsChecklistMap.keySet()){
                    BSFTaskChecklistTriggerHandler.updateAccountAndOpportunity(taskSubjectVsChecklistMap.get(subject),taskVsOpportunityMap,taskVsAccountMap,subject);
                }
            }
        }
    }
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getHighlightAndFeedBacks(Id taskId) {
        System.debug('getReportLinks taskId : '+taskId);
        Map<String,String> result = new Map<String,String>();
        if(taskId != null){
            List<Task> taskList = [SELECT Subject,
                                            Highlights_and_Feedback__c,
                                            Customer_Service_Issues__c
                                        FROM Task 
                                        WHERE Id = :taskId];
            for(Task t : taskList){
                if(String.isNotBlank(t.Subject) && t.Subject.equals(BSF_Constants.POST_DRIVE_ANALYSIS_TASK)){
                    result.put('isVisible', 'true');
                    result.put('highlights', t.Highlights_and_Feedback__c);
                    result.put('serviceIssue', t.Customer_Service_Issues__c);
                }else{
                    result.put('isVisible', 'false');
                    result.put('highlights', '');
                    result.put('serviceIssue', '');
                }
            }
        }
        return result;
    }
    @AuraEnabled
    public static Map<String, String> updateHighlightAndFeedBacks(String taskId, String highlights, String serviceIssue) {
        System.debug('updateHighlightAndFeedBacks taskId : '+taskId);
        Map<String, String> updateStatus = new Map<String, String>();
        try{
            if(taskId != null){
                List<Task> taskList = [SELECT Subject,
                                                Highlights_and_Feedback__c,
                                                Customer_Service_Issues__c
                                            FROM Task 
                                            WHERE Id = :taskId];
                for(Task t : taskList){
                    if(String.isNotBlank(t.Subject) && t.Subject.equals(BSF_Constants.POST_DRIVE_ANALYSIS_TASK)){
                        t.Highlights_and_Feedback__c = highlights;
                        t.Customer_Service_Issues__c = serviceIssue;
                    }
                }
                if(!taskList.isEmpty()){
                    update taskList;
                }
            }
            updateStatus = new Map<String, String>{'isSuccess' => 'true', 'message' => 'Highlights and FeedBack has been successfully saved.' , 'title'=> 'Success', 'variant'=>  'success'};
        } catch (Exception e) {
            updateStatus = new Map<String, String>{'isSuccess' => 'false', 'message' => 'Error occured. '+'Line: '+e.getLineNumber()+' '+e.getMessage(), 'title'=> 'Error saving record', 'variant'=>  'error'};
        }
        return updateStatus;
    }
    //HRP-12627 --> Start
    public static void check72hourCheckInTaskCompletion(List<Task> newList, Map<Id, Task> oldMap){
        System.debug('check72hourCheckInTaskCompletion entrie');
        String taskSubject;
        List<Task_Definition__c> def = [SELECT Name, 
                                            Task_Type__c 
                                        FROM Task_Definition__c
                                        WHERE Task_Type__c = :BSF_Constants.TASK_TYPE_72_HOUR_CHECK_IN
                                        AND Name != null];
        if(!def.isEmpty()){
            taskSubject = def[0].Name;
        }else {
            return;
        }
        Map<String, Task_Checklist_Setting__mdt> metadataMap = BSFTaskChecklistTriggerHandler.getMetaDataMap().get(taskSubject);
        Map<Id, Boolean> taskMap = new Map<Id, Boolean>();
        if(newList != null && !newList.isEmpty() && oldMap != null && !oldMap.isEmpty()){
            for(Task tsk : newList){
                System.debug('tsk.Subject.equals(taskSubject) : '+tsk.Subject.equals(taskSubject));
                System.debug('oldMap.get(tsk.Id).Status != tsk.Status : '+ (oldMap.get(tsk.Id).Status != tsk.Status));
                if(tsk.Id != null
                        && String.isNotBlank(tsk.Subject) && tsk.Subject.equals(taskSubject) 
                        && String.isNotBlank(tsk.Status) && tsk.Status.equals(BSF_Constants.STATUS_COMPLETED)
                        && oldMap.containsKey(tsk.Id) && oldMap.get(tsk.Id).Status != tsk.Status){
                            taskMap.put(tsk.Id,false);
                }
            }
        }
        if(!taskMap.isEmpty() && metadataMap != null && !metadataMap.isEmpty()){
            List<BSF_Task_Checklist__c> checklists = [SELECT Id,
                                                            Input_Checkbox__c,  
                                                            TaskLookup__c, 
                                                            Unique_Name__c
                                                        FROM BSF_Task_Checklist__c
                                                        WHERE TaskLookup__c IN : taskMap.keySet()
                                                        AND Unique_Name__c IN : metadataMap.keySet()
                                                        WITH SYSTEM_MODE];
            for(BSF_Task_Checklist__c ckList : checklists){
                if(metadataMap.get(ckList.Unique_Name__c).Input_API_Name__c.equalsIgnoreCase('Input_Checkbox__c') && !ckList.Input_Checkbox__c){
                    taskMap.put(ckList.TaskLookup__c,true);
                }
            }
        }
        if(newList != null && !newList.isEmpty() && !taskMap.isEmpty()){
            for(Task tsk : newList){
                if(tsk.Id != null && taskMap.containsKey(tsk.Id) && taskMap.get(tsk.Id)){
                    tsk.addError('Please ensure each item is checked before marking task as complete.');
                }
            }
        }
    }
    // HRP-12627 --> end
    /*
    * This is for ticket HRP-13426 to decide who will be the owner of the tasks.
    */
    public static void assignDefaultTaskOwner(List<Task> newList){
        if(newList == null || newList.isEmpty()) return;

        Set<Id> oppIds = new Set<Id>();
        Set<String> subjectList = new Set<String>();
        for(Task tsk : newList){
            if(String.isNotBlank(tsk.Subject) && tsk.WhatId != null && tsk.OwnerId == null
                && tsk.WhatId.getSObjectType() == Schema.Opportunity.SObjectType){
                    oppIds.add(tsk.WhatId);
                    subjectList.add(tsk.Subject);
            }
        }

        if(oppIds.isEmpty()) return;

        Map<Id, Map<String, Id>> roleHierarchyMap = BSF_TaskPlanningService.buildRoleHierarchyMap(oppIds);
        Map<String, List<String>> fallbackHierarchyMap = BSF_TaskPlanningService.getRoleFallbackHierarchyMap();
        Map<String, String> subjectVsAssignedTo = new Map<String, String>();
        List<Task_Definition__c> def = [SELECT Name, 
                                                Assigned_To__c 
                                            FROM Task_Definition__c
                                            WHERE Name IN :subjectList
                                            AND Assigned_To__c != null];
        for(Task_Definition__c taskDef : def){
            subjectVsAssignedTo.put(taskDef.Name, taskDef.Assigned_To__c);
        }

        for(Task tsk : newList){
            if(String.isNotBlank(tsk.Subject) && tsk.WhatId != null && tsk.OwnerId == null
                && tsk.WhatId.getSObjectType() == Schema.Opportunity.SObjectType){
                    String assignedTo;
                    if(subjectVsAssignedTo.isEmpty() || !subjectVsAssignedTo.containsKey(tsk.Subject)){
                        assignedTo = BSF_Constants.ACCOUNT_MANAGER;
                    }else{
                        assignedTo = subjectVsAssignedTo.get(tsk.Subject);
                    }
                    tsk.OwnerId = BSF_TaskPlanningService.determineTaskOwner(assignedTo, roleHierarchyMap.get(tsk.WhatId),fallbackHierarchyMap);
            }
        }
    }
    public static Id getDRDSystemUser(){
        Id drdSystemUserId;
        if(String.isNotBlank(System.label.DRD_System_User_Name)){
            for(User u : [SELECT Id FROM User WHERE Name = :System.label.DRD_System_User_Name LIMIT 1]){
                drdSystemUserId = u.Id;
            }
        }
        return drdSystemUserId;
    }
    // HRP-13426 --> end
    public static void populateTaskTypeFromMetadata(List<Task> newTasks) {

        if(newTasks == null || newTasks.isEmpty()){
            return;
        }

        Set<String> subjectsNeedingType = new Set<String>();

        for(Task t : newTasks){
            if(String.isBlank(t.Type) && String.isNotBlank(t.Subject)){
                subjectsNeedingType.add(t.Subject.trim());
            }
        }

        if(subjectsNeedingType.isEmpty()){
            return;
        }

        Map<String, String> subjectToTypeMap = new Map<String, String>();

        for(Task_Definition__c def :
            [
                SELECT Name, 
                    Task_Type__c 
                FROM Task_Definition__c
                WHERE Name IN :subjectsNeedingType
                AND Task_Type__c != null
            ]
        ){
            subjectToTypeMap.put(def.Name, def.Task_Type__c);
        }

        if(subjectToTypeMap.isEmpty()){
            return;
        }

        for(Task t : newTasks){
            if(String.isBlank(t.Type) && String.isNotBlank(t.Subject)){
                String resolvedType = subjectToTypeMap.get(t.Subject);
                if(resolvedType != null){
                    t.Type = resolvedType;
                }
            }
        }
    }
    /*public static void createOneWeekCheckInTasks(Map<Id, Opportunity> oppMap) {
        if(oppMap == null || oppMap.isEmpty()){
            return;
        }
        Task_Reassignment_Matrix__mdt matrix = Task_Reassignment_Matrix__mdt.getInstance('One_Week_Check_in');

        Map<Id, Task> existingTasksByOpp = new Map<Id, Task>();
        for (Task t : [
            SELECT Id, WhatId
            FROM Task
            WHERE WhatId IN :oppMap.keySet()
            AND Type = :matrix.Task_Type__c
            AND Status != :BSF_Constants.STATUS_CANCELLED
        ]) {
            existingTasksByOpp.put(t.WhatId, t);
        }

        List<Task> tasksToInsert = new List<Task>();

        List<OpportunityTeamMember> allOpportunityTeamMembers = [SELECT Id, OpportunityId, TeamMemberRole, UserId
                                                                 FROM OpportunityTeamMember
                                                                 WHERE TeamMemberRole IN (:BSF_Constants.DISTRICT_MANAGER, :BSF_Constants.ACCOUNT_SPECIALIST, :BSF_Constants.ACCOUNT_SPECIALIST)
                                                                 AND OpportunityId IN :oppMap.keySet()
                                                                ];
        
        
        Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
        for (OpportunityTeamMember oppteamem : allOpportunityTeamMembers) {
            if (!oppTeamMembersMap.containsKey(oppteamem.OpportunityId)) {
                oppTeamMembersMap.put(oppteamem.OpportunityId, new List<OpportunityTeamMember>());
            }
            oppTeamMembersMap.get(oppteamem.OpportunityId).add(oppteamem);
        }

        for (Id oppId : oppMap.keySet()) {
            if (existingTasksByOpp.containsKey(oppId)){
                continue;
            }

            Opportunity opp = oppMap.get(oppId);
            Id distmng, accsp;
            if(oppTeamMembersMap.containsKey(opp.Id)){
                for (OpportunityTeamMember t : oppTeamMembersMap.get(opp.Id)) {
                    if (t.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER){
                        distmng = t.UserId;
                    }
                    if (t.TeamMemberRole == BSF_Constants.ACCOUNT_SPECIALIST){
                        accsp = t.UserId;
                    }
                }
            }

            Task t = new Task();
            t.Subject = matrix.Task_Subject__c;
            t.WhatId = oppId;
            t.Type = matrix.Task_Type__c;
            t.ActivityDate = opp.Drive_Date__c != null
                            ? opp.Drive_Date__c.addDays(0 - Integer.valueOf(matrix.Due_Date_Offset__c))
                            : null;
            t.Status = BSF_Constants.STATUS_NOT_STARTED;
            t.Priority = BSF_Constants.NORMAL_PRIORITY_TASK;
            t.Drive_Date__c = opp.Drive_Date__c;
            if(String.isNotBlank(matrix.Assigned_To__c) && matrix.Assigned_To__c.equalsIgnoreCase(BSF_Constants.ACCOUNT_MANAGER)){
                t.OwnerId = opp.Account_Manager__c != null ? opp.Account_Manager__c :
                            accsp != null ? accsp : distmng != null ? distmng : opp.OwnerId;

            }else if(String.isNotBlank(matrix.Assigned_To__c) && matrix.Assigned_To__c.equalsIgnoreCase(BSF_Constants.ACCOUNT_SPECIALIST)){
                t.OwnerId = accsp != null ? accsp : distmng != null ? distmng : opp.OwnerId;

            }else if(String.isNotBlank(matrix.Assigned_To__c) && matrix.Assigned_To__c.equalsIgnoreCase(BSF_Constants.DISTRICT_MANAGER)){
                t.OwnerId = distmng != null ? distmng : opp.OwnerId;

            }
            tasksToInsert.add(t);
        }

        if (tasksToInsert.size() > 0) {
            Database.SaveResult[] srList = Database.insert(tasksToInsert, false);
            List<BSF_Error_Log__c> errorList = BSF_Utilities.createErrorLog(srList,'Insert task','TaskService','createOneWeekCheckInTasks','Error', 'Error in Inserting Tasks for One Week Check-In');
            if(!errorList.isEmpty()){
                Database.insert(errorList, true);
            }
        } 
    }*/

    public static void cancelOpportunityTasks(Set<Id> oppids) {
        if(oppids == null || oppids.isEmpty()){
            return;
        }
        Map<Id, Task> existingTasksByOpp = new Map<Id, Task>();
        List<Task> tasksToUpdate = new List<Task>();
        for (Task t : [
            SELECT Id, WhatId
            FROM Task
            WHERE WhatId IN :oppids
            AND Status != :BSF_Constants.STATUS_CANCELLED
        ]) {
            t.Status = BSF_Constants.STATUS_CANCELLED;
            tasksToUpdate.add(t);
        }
        if (tasksToUpdate.size() > 0) {
            Database.SaveResult[] srList = Database.update(tasksToUpdate, false);
            List<BSF_Error_Log__c> errorList = BSF_Utilities.createErrorLog(srList,'Update task','TaskService','cancelOpportunityTasks','Error', 'Error in Cancelling Tasks for Opportunity');
            if(!errorList.isEmpty()){
                Database.insert(errorList, true);
            }
        } 
    }
        
     //HRP-16830
    //
    public static void subjectisRequired(List<Task> taskList){
        for(Task t : taskList){
            if(String.isBlank(t.Subject) && (t.TaskSubtype == 'Task' || t.TaskSubtype == 'Call')){
                t.addError('Subject is required.');
            }
        }          
    }
    public static String calculateOpportunityTaskKey(Id oppId, String taskType) {
        if (oppId == null || String.isBlank(taskType)) {
            return null;
        }
        String strOppId = String.valueOf(oppId);
        String sanitizedType = taskType.replaceAll('\\s+', '_');
        sanitizedType = sanitizedType.length() > 236 ? sanitizedType.substring(0, 236) : sanitizedType;
        return (sanitizedType + '_' + strOppId);
    }
    public static void clearKeyIfCancelled(List<Task> newTasks, Map<Id, Task> oldMap) {
        for (Task t : newTasks) {
            if (t.Id != null && String.isNotBlank(t.Status) && t.Status.equalsIgnoreCase(BSF_Constants.STATUS_CANCELLED) 
                    && oldMap != null && oldMap.containsKey(t.Id) && String.isNotBlank(oldMap.get(t.Id).Status) 
                    && !oldMap.get(t.Id).Status.equalsIgnoreCase(BSF_Constants.STATUS_CANCELLED)) {
                        t.Task_Deduplication_Id__c = null;
            }
        }
    }
    public static void populateTaskKey(List<Task> newTasks) {
        for (Task t : newTasks) {
            if (String.isNotBlank(t.Status) && !t.Status.equalsIgnoreCase(BSF_Constants.STATUS_CANCELLED) && t.WhatId != null 
                        && t.WhatId.getSObjectType() == Opportunity.SObjectType && String.isNotBlank(t.Type)) {
                            t.Task_Deduplication_Id__c = calculateOpportunityTaskKey(t.WhatId, t.Type);
            }
        }
    }
}