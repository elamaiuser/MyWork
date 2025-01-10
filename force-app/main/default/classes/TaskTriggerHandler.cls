/**
* Modification Log 
* 
* Date					Developer Name			Comments
* ***************************************************************************************************************************************************************************
* 09/06/2024			Apurba Bhattacharjee	HRP-12459 Lead Research Fields on the Record
* 10/07/2024			Balaji N				HRP-12583 new method call stopPublicityOrderTaskCompletionWithoutOrder
* 11/07/2024			Barnojit Sharma		    Update Task: 72 Hour Check in - System Generated/Details/Checklist. (Logic for HRP-12627)
* ***************************************************************************************************************************************************************************
**/
public with sharing class TaskTriggerHandler extends TriggerHandler {
    
    public static String skedDrivePrefix = Schema.SObjectType.sked_Drive__c.getKeyPrefix();  
    
    public override void beforeUpdate(){
        // Using this method to populate Account Name , Account Id, Relatd Record Name, Related Record link to use them on My Assigned Task and My Delegated Task widget
        if(super.getTriggerMethodsToBypass().indexOf('populateAccountNameOnTask') == -1) { 
            populateAccountNameOnTask((List<Task>)Trigger.new,(Map<Id,Task>)Trigger.newMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('populateDriveDateOnTask') == -1) { 
            populateDriveDateOnTask((List<Task>)Trigger.new,(Map<Id,Task>)Trigger.newMap); //HRP-12459
        }
        if(super.getTriggerMethodsToBypass().indexOf('validateTaskRecordTypeForFixSite') == -1) { 
            TaskService.validateTaskRecordTypeForFixSite((List<Task>)Trigger.new);
        }
        //HRP-12583 start
        if(super.getTriggerMethodsToBypass().indexOf('stopPublicityOrderTaskCompletionWithoutOrder') == -1) {
        	TaskService.stopPublicityOrderTaskCompletionWithoutOrder((List<Task>)Trigger.new,(Map<Id,Task>)Trigger.OldMap);
        }
        //HRP-12583 end
        //HRP-12627 start
        if(super.getTriggerMethodsToBypass().indexOf('check72hourCheckInTaskCompletion') == -1) {
        	TaskService.check72hourCheckInTaskCompletion((List<Task>)Trigger.new,(Map<Id,Task>)Trigger.OldMap);
        }
        //HRP-12627 end
    }
    //HRP-12142 --> end 
    public override void beforeInsert(){
        // Using this method to populate Account Name , Account Id, Relatd Record Name, Related Record link to use them on My Assigned Task and My Delegated Task widget
        if(super.getTriggerMethodsToBypass().indexOf('populateAccountNameOnTask') == -1) { 
            populateAccountNameOnTask((List<Task>)Trigger.new,(Map<Id,Task>)Trigger.newMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('populateDriveDateOnTask') == -1) { 
            populateDriveDateOnTask((List<Task>)Trigger.new,(Map<Id,Task>)Trigger.newMap); //HRP-12459
        }
        if(super.getTriggerMethodsToBypass().indexOf('validateTaskRecordTypeForFixSite') == -1) { 
            TaskService.validateTaskRecordTypeForFixSite((List<Task>)Trigger.new);
        }
    }
    //HRP-12459 --> start
    public void populateDriveDateOnTask(List<Task> taskList,Map<Id,Task> taskMap){
        try{
            Set<ID> oppId = new Set<ID>();
            Set<ID> orderId = new Set<ID>();
            Set<ID> driveId = new Set<ID>();
            List<String> driveRelatedObjList = new List<String>{'Opportunity','Order','sked_Drive__c'};
            for(Task task : taskList){
                String relatedObjectType = String.valueOf((task.WhatId).getSObjectType());
                if(task.WhatId != null && (driveRelatedObjList.contains(relatedObjectType)) && task.Drive_Date__c == null){
                    Boolean isOpportunity = (String.valueOf((task.WhatId).getSObjectType())).equalsIgnoreCase('Opportunity');
                    Boolean isOrder = (String.valueOf((task.WhatId).getSObjectType())).equalsIgnoreCase('Opportunity');
                    Boolean isDrive = (String.valueOf((task.WhatId).getSObjectType())).equalsIgnoreCase('sked_Drive__c');
                    if (isOpportunity) {
                        oppId.add(task.WhatId);
                    } else if (isOrder) {
                        orderId.add(task.WhatId);
                    } else if (isDrive) {
                        driveId.add(task.WhatId);
                    }
                }
            }

            Map<ID, Opportunity> getOppDate = new Map<ID, Opportunity>([Select ID, Drive_Date__c From Opportunity Where ID IN :oppId]);
            Map<ID, Order> getOrderDate = new Map<ID, Order>([Select ID, Drive_Date__c From Order Where ID IN :orderId AND Drive_Date__c != NULL]);
            Map<ID, sked_Drive__c> getDriveDate = new Map<ID, sked_Drive__c>([Select ID, sked_Drive_Date__c From sked_Drive__c Where ID IN :driveId]);
            System.debug('getOppDate=> '+getOppDate);
            for (Task task : taskList) {
                if (task.whatId != null) {
                    Boolean isOpportunity = (String.valueOf((task.WhatId).getSObjectType())).equalsIgnoreCase('Opportunity');
                    Boolean isOrder = (String.valueOf((task.WhatId).getSObjectType())).equalsIgnoreCase('Opportunity');
                    Boolean isDrive = (String.valueOf((task.WhatId).getSObjectType())).equalsIgnoreCase('sked_Drive__c');
                    if (isOpportunity) {
                        task.Drive_Date__c = getOppDate.get(task.WhatId).Drive_Date__c;
                    } else if (isOrder) {
                        task.Drive_Date__c = getOrderDate.get(task.WhatId).Drive_Date__c;
                    } else if (isDrive) {
                        task.Drive_Date__c = getDriveDate.get(task.WhatId).sked_Drive_Date__c;
                    }
                }
            }
            System.debug('taskList=> '+taskList);
        } catch( Exception ex){
            String taskIds = '';
            for (Task task : taskList) {
                taskIds+= task.Id;
            }
            List<BSF_Error_Log__c> errorLogToInsert = new List<BSF_Error_Log__c>{
                BSF_Utilities.createBsfErrorLogForExceptions( ex, 'TaskTriggerHandler', 'populateDriveDateOnTask', 'Error', 'Drive Date update on Task failed', 'Task', taskIds )};

            Database.SaveResult[] logInsertResult = Database.insert(errorLogToInsert, FALSE);
        }
    } //HRP-12459 --> end
    
    // This is used to populate the fields being used on My Assigned Task and My Delegated Task widget on Home page
    public void populateAccountNameOnTask(List<Task> taskList,Map<Id,Task> taskMap){
        try{
            Set<Id> driveIds = new Set<id>();
            Set<Id> taskIds = new Set<Id>();
            for(Task t : taskList){
                if(t.WhatId != null && (String.valueOf(t.WhatId).contains(skedDrivePrefix)) && t.Related_Account_Name__c == null){
                    driveIds.add(t.whatId);
                }
                if(t.whatId != null){
                    taskIds.add(t.Id);    
                }
            }
            if(!driveIds.isEmpty()){
                Map<Id,sked_Drive__c>  driveMap = new Map<Id,sked_Drive__c>([select id,Name,sked_Account__c,sked_Account__r.Name from sked_Drive__c where Id IN :driveIds]);
                for(Task t : taskList){
                    if(t.WhatId != null && String.valueOf(t.WhatId).contains(skedDrivePrefix) && driveMap.containsKey(t.WhatId)){
                        t.Related_Account_Name__c = driveMap.get(t.WhatId).sked_Account__r.Name;
                        t.Related_Account_Id__c = driveMap.get(t.WhatId).sked_Account__c;
                        t.Related_Record_Name__c = driveMap.get(t.WhatId).Name;
                    }
                }
            }
            if(taskIds != null && !taskIds.isEmpty()){
                Map<id,task> taskCustomMap = new Map<Id,Task>([select id,What.Name,Related_Record_Name__c from Task where Id IN :taskIds]);
                for(Task tr : taskList){
                    if(taskCustomMap.containsKey(tr.Id) && taskCustomMap.get(tr.Id) != null)
                        tr.Related_Record_Name__c = taskCustomMap.get(tr.Id).What.Name;
                }
            }
        }
        catch( Exception ex){
            String taskIds = '';
            for (Task task : taskList) {
                taskIds+= task.Id;
            }
            List<BSF_Error_Log__c> errorLogToInsert = new List<BSF_Error_Log__c>{
                BSF_Utilities.createBsfErrorLogForExceptions( ex, 'TaskTriggerHandler', 'populateAccountNameOnTask', 'Error', 'Account Name update on Task failed', 'Task', taskIds )};

            Database.SaveResult[] logInsertResult = Database.insert(errorLogToInsert, FALSE);
        }
    }
}