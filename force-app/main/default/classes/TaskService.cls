/* @Description: 1. Below service class supports various Task relared functionalities working in different contexts.
* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 08/30/2024			         Barnojit Sharma		  Within the Sponsor Planning Report task, populate the referencing Opp/Drive Sponsor Planning Report. (Logic for HRP-5337)
* 10/07/2024					 Balaji N				  HRP-12583 new method stopPublicityOrderTaskCompletionWithoutOrder
* 11/07/2024			         Barnojit Sharma		  Update Task: 72 Hour Check in - System Generated/Details/Checklist. (Logic for HRP-12627)
************************************************************************************************************************************************
*/ 

public with sharing class TaskService {
    
    /* HRP-5763
     * 	MVP: Custom Tasks do not populate on Fixed Sites records 
     *  
     */
    
    public static void validateTaskRecordTypeForFixSite(List<Task> newTaskList)
    {
        map<Id,String> mapOfRelatedToIdWithRecordTypeName = new map<Id,String>();
        map<Id, Id> mapOfTaskIdWithAccountId = new map<Id, Id>();
        map<Id, Id> mapOfTaskIdWithOpportunityId = new map<Id, Id>(); 
        system.debug('newTaskList '+ newTaskList);
        for(task t: newTaskList){
            String sobjectType ;
            if(t.WhatId != null)
                sobjectType  = t.WhatId.getSObjectType().getDescribe().getName();
            if( sobjectType  == 'Account'){
                mapOfTaskIdWithAccountId.put(t.Id, t.WhatId); 
            }else if(sobjectType  == 'Opportunity'){
                mapOfTaskIdWithOpportunityId.put(t.Id, t.WhatId);                 
            }           
        }
        for(Account acc: [SELECT Id, RecordType.Name, Name FROM Account Where Id IN:mapOfTaskIdWithAccountId.values()]){
            mapOfRelatedToIdWithRecordTypeName.put(acc.Id, acc.RecordType.Name);
        }
        for(Opportunity opp: [SELECT Id, RecordType.Name, Name FROM Opportunity Where Id IN:mapOfTaskIdWithOpportunityId.values()]){
            mapOfRelatedToIdWithRecordTypeName.put(opp.Id, opp.RecordType.Name);            
        }
        for(task t: newTaskList){
            system.debug('the task '+t);
            String getRelatedToRecordType;
            String sobjectName;
            if(t.WhatId != null)
                sobjectName =  t.WhatId.getSObjectType().getDescribe().getName();
            if(!mapOfRelatedToIdWithRecordTypeName.isEmpty()){
                if(sobjectName  == 'Account'){
                    getRelatedToRecordType =  mapOfRelatedToIdWithRecordTypeName.get(mapOfTaskIdWithAccountId.get(t.Id));
                }else if(sobjectName  == 'Opportunity'){
                    getRelatedToRecordType = mapOfRelatedToIdWithRecordTypeName.get(mapOfTaskIdWithOpportunityId.get(t.Id));
                }
                
                if(getRelatedToRecordType !=null && t.RecordTypeId !=null){
                    string taskRecordTypeName = Schema.SObjectType.Task.getRecordTypeInfosById().get(t.recordtypeid).getname();
                    if((taskRecordTypeName == '72 Hour Check In' || taskRecordTypeName == 'Recruitment Meeting')
                       && (getRelatedToRecordType == 'Fixed Site Account' || getRelatedToRecordType == 'Fixed Site Opp')){
                           t.addError('Cannot create 72 Hour Check In/Recruitment Meeting task for Fix Site Account/Opportunity.');
                    }
                }
           		 
            }
        }
    }
    //HRP-5337 changes starts here
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getReportLinks(Id taskId) {
        System.debug('getReportLinks taskId : '+taskId);
        List<Map<String,String>> result = new List<Map<String,String>>();
        if(taskId != null){
            List<Task> taskList = [SELECT Subject,
                                            WhatId
                                        FROM Task 
                                        WHERE Id = :taskId];
            if(!taskList.isEmpty() && taskList[0].Subject != null){
                for(Task_Report_Link__mdt metadata : [SELECT Report_Link__c, 
                                                                Report_Name__c,
                                                                DeveloperName
                                                        FROM Task_Report_Link__mdt 
                                                        WHERE Task_Subject__c =:taskList[0].Subject
                                                        AND Active__c = true
                                                        ORDER BY Report_Name__c ASC]){
                
                    Map<String,String> tempMap = new Map<String,String>();
                    tempMap.put('name', metadata.Report_Name__c);
                    tempMap.put('link', metadata.Report_Link__c.replace('{{opportunityId}}',taskList[0].WhatId));
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
        
        String taskSubject = BSF_Constants.POST_DRIVE_ANALYSIS_TASK;
        Set<Id> postDriveAnalysisTask = new Set<Id>();
        List<BSF_Task_Checklist__c> taskChecklistRecords = new List<BSF_Task_Checklist__c>();
        try {
            
            for(task newTask: taskList){
                if (newTask.Status.equalsIgnoreCase(BSF_Constants.STATUS_COMPLETED) && newTask.Subject.equalsIgnoreCase(taskSubject)) {
                    postDriveAnalysisTask.add(newTask.Id);
                }
            }

            if (!postDriveAnalysisTask.isEmpty()) {
                taskChecklistRecords = [SELECT Id, Unique_Name__c, Input_Long_Text_Area__c, Input_Checkbox__c, Picklist_Input_1__c, Picklist_Input_2__c, TaskLookup__c, OpportunityLookup__c, OpportunityLookup__r.AccountId  FROM BSF_Task_Checklist__c WHERE TaskType__c = :taskSubject AND Unique_Name__c IN ('Account_Strategy__c', 'Account_Strategy_Notes__c', 'Gray_Sky_Account__c', 'Rollover_Consideration__c')];
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
        Task_Reassignment_Matrix__mdt publicityOrder = Task_Reassignment_Matrix__mdt.getInstance('Publicity_Order_Not_Created');
        
        Set<Id> oppIdSet = new Set<Id>();
        List<Task> pubOrderTaskList = new List<Task>();
		for(Task t :newTasksList)
        {
            if(t.Subject == publicityOrder.Task_Subject__c && OldMap != null && OldMap.get(t.Id).Status != t.Status && t.Status == 'Completed')
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
        System.debug('updateRelatedAccountAndOpportunity entrie');
        Map<String,String> fieldVsObjectMap = BSFTaskChecklistTriggerHandler.fieldVsObjectMap;
        List<BSF_Task_Checklist__c> checklists = new List<BSF_Task_Checklist__c>();
        Map<String,Id> taskVsOppMap = new Map<String,Id>();
        Map<String,Opportunity> taskVsOpportunityMap = new Map<String,Opportunity>();
        Map<String,Account> taskVsAccountMap = new Map<String,Account>();
        if(newList != null && !newList.isEmpty()){
            for(Task tsk : newList){
                //System.debug('String.valueOf(task.WhatId).startsWith(BSFTaskChecklistTriggerHandler.oppPrefix) : '+String.valueOf(task.WhatId).startsWith(BSFTaskChecklistTriggerHandler.oppPrefix));
                System.debug('tsk.Subject.equals(BSF_Constants.POST_DRIVE_ANALYSIS_TASK) : '+tsk.Subject.equals(BSF_Constants.POST_DRIVE_ANALYSIS_TASK));
                 System.debug('oldMap.get(tsk.Id).Status != tsk.Status : '+ (oldMap.get(tsk.Id).Status != tsk.Status));
                if(tsk.Id != null && tsk.WhatId != null //&& String.valueOf(task.WhatId).startsWith(BSFTaskChecklistTriggerHandler.oppPrefix)
                        && String.isNotBlank(tsk.Subject) && tsk.Subject.equals(BSF_Constants.POST_DRIVE_ANALYSIS_TASK) 
                        && String.isNotBlank(tsk.Status) && tsk.Status.equals(BSF_Constants.STATUS_COMPLETED)
                        && (oldMap == null || oldMap.isEmpty() || (oldMap.containsKey(tsk.Id) && oldMap.get(tsk.Id).Status != tsk.Status))){
                            taskVsOppMap.put(tsk.Id,tsk.WhatId);
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
                                TaskLookup__c, 
                                TaskType__c, 
                                OpportunityLookup__c 
                            FROM BSF_Task_Checklist__c
                            WHERE TaskLookup__c IN : taskVsOppMap.keySet()
                            AND Unique_Name__c IN : fieldVsObjectMap.keySet()
                            WITH SYSTEM_MODE];
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
            BSFTaskChecklistTriggerHandler.updateAccountAndOpportunity(checklists,taskVsOpportunityMap,taskVsAccountMap);
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
        String taskSubject = Task_Reassignment_Matrix__mdt.getInstance('X72_Hour').Task_Subject__c;
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
}