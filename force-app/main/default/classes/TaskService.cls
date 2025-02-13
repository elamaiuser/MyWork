/* @Description: 1. Below service class supports various Task relared functionalities working in different contexts.
* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 08/30/2024			         Barnojit Sharma		  Within the Sponsor Planning Report task, populate the referencing Opp/Drive Sponsor Planning Report. (Logic for HRP-5337)
* 10/07/2024					 Balaji N				  HRP-12583 new method stopPublicityOrderTaskCompletionWithoutOrder
* 10/29/2024			         Barnojit Sharma		  Post Drive Analysis task Enhancements. (Logic for HRP-12142)
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
                Map<Id,Id> oppVsDocMap = new Map<Id,Id>();
                //HRP-12627 changes starts
                if(taskList[0].WhatId != null){
                    List<Sked_Drive__c> docList = [SELECT Id,
                                                            sked_Opportunity__c
                                                    FROM Sked_Drive__c 
                                                    WHERE sked_Opportunity__c = :taskList[0].WhatId
                                                    AND sked_Is_Surrogate__c = false];
                    for(Sked_Drive__c drv : docList){
                        oppVsDocMap.put(drv.sked_Opportunity__c, drv.Id);
                    }
                }
                //HRP-12627 changes ends
                for(Task_Report_Link__mdt metadata : [SELECT Report_Link__c, 
                                                                Report_Name__c,
                                                                DeveloperName
                                                        FROM Task_Report_Link__mdt 
                                                        WHERE Task_Subject__c =:taskList[0].Subject
                                                        AND Active__c = true
                                                        ORDER BY Report_Name__c ASC]){
                
                    Map<String,String> tempMap = new Map<String,String>();
                    tempMap.put('name', metadata.Report_Name__c);
                    //HRP-12627 changes starts
                    String reportLink = metadata.Report_Link__c;
                    reportLink = reportLink.replace('{{opportunityId}}',taskList[0].WhatId);
                    if(!oppVsDocMap.isEmpty() && oppVsDocMap.containsKey(taskList[0].WhatId)){
                        reportLink = reportLink.replace('{{driveId}}',oppVsDocMap.get(taskList[0].WhatId));
                    }
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
    //HRP-12142 Start
    public static void updateRelatedAccountAndOpportunity(List<Task> newList, Map<Id, Task> oldMap){
        System.debug('updateRelatedAccountAndOpportunity entrie');
        Map<String, Map<String,String>> taskVsFieldVsObjectMap = BSFTaskChecklistTriggerHandler.taskVsFieldVsObjectMap;
        Map<String,String> fieldVsObjectMap = new Map<String,String>();
        if(!taskVsFieldVsObjectMap.isEmpty() && taskVsFieldVsObjectMap.containsKey(BSF_Constants.POST_DRIVE_ANALYSIS_TASK)){
            fieldVsObjectMap = taskVsFieldVsObjectMap.get(BSF_Constants.POST_DRIVE_ANALYSIS_TASK);
        }
        if(!taskVsFieldVsObjectMap.isEmpty() && taskVsFieldVsObjectMap.containsKey(BSF_Constants.RECRUITMENT_PLANNING_TASK)){
            fieldVsObjectMap.putAll(taskVsFieldVsObjectMap.get(BSF_Constants.RECRUITMENT_PLANNING_TASK));
        }
        List<BSF_Task_Checklist__c> postDriveAnalysisTaskchecklists = new List<BSF_Task_Checklist__c>();
        List<BSF_Task_Checklist__c> RecruitmentTaskchecklists = new List<BSF_Task_Checklist__c>();
        Map<Id,String> taskVsSubjectMap = new Map<Id,String>();
        
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
                        && String.isNotBlank(tsk.Subject) && (tsk.Subject.equals(BSF_Constants.POST_DRIVE_ANALYSIS_TASK) || tsk.Subject.equals(BSF_Constants.RECRUITMENT_PLANNING_TASK))
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
                            && taskVsSubjectMap.get(taskChecklist.TaskLookup__c).equals(BSF_Constants.POST_DRIVE_ANALYSIS_TASK)){
                                postDriveAnalysisTaskchecklists.add(taskChecklist);
                    }else if(taskVsSubjectMap.containsKey(taskChecklist.TaskLookup__c) 
                            && taskVsSubjectMap.get(taskChecklist.TaskLookup__c).equals(BSF_Constants.RECRUITMENT_PLANNING_TASK)){
                                RecruitmentTaskchecklists.add(taskChecklist);
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
            if(!postDriveAnalysisTaskchecklists.isEmpty()){
                BSFTaskChecklistTriggerHandler.updateAccountAndOpportunity(postDriveAnalysisTaskchecklists,taskVsOpportunityMap,taskVsAccountMap,BSF_Constants.POST_DRIVE_ANALYSIS_TASK);
            }
            if(!RecruitmentTaskchecklists.isEmpty()){
                BSFTaskChecklistTriggerHandler.updateAccountAndOpportunity(RecruitmentTaskchecklists,taskVsOpportunityMap,taskVsAccountMap,BSF_Constants.RECRUITMENT_PLANNING_TASK);
            }
        }
    }
    //HRP-12142 End
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