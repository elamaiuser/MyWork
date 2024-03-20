public with sharing class TaskTriggerHandler extends TriggerHandler {
    
    public static String skedDrivePrefix = Schema.SObjectType.sked_Drive__c.getKeyPrefix();  
    
    public override void beforeUpdate(){
        // Using this method to populate Account Name , Account Id, Relatd Record Name, Related Record link to use them on My Assigned Task and My Delegated Task widget
        populateAccountNameOnTask((List<Task>)Trigger.new,(Map<Id,Task>)Trigger.newMap);
        TaskService.validateTaskRecordTypeForFixSite((List<Task>)Trigger.new);
    }
    
    public override void beforeInsert(){
        // Using this method to populate Account Name , Account Id, Relatd Record Name, Related Record link to use them on My Assigned Task and My Delegated Task widget
        populateAccountNameOnTask((List<Task>)Trigger.new,(Map<Id,Task>)Trigger.newMap);
        TaskService.validateTaskRecordTypeForFixSite((List<Task>)Trigger.new);
    }
    
    /*public override void afterInsert(){
        
    }
    
    public override void afterUpdate(){
        
    }*/
    
    
    // This is used to populate the fields being used on My Assigned Task and My Delegated Task widget on Home page
    public void populateAccountNameOnTask(List<Task> taskList,Map<Id,Task> taskMap){
        try{
            Set<Id> driveIds = new Set<id>();
            Set<Id> taskIds = new Set<Id>();
            for(Task t : taskList){
                system.debug('whatId is '+t.whatId);
                if(t.WhatId != null && (String.valueOf(t.WhatId).contains(skedDrivePrefix)) && t.Related_Account_Name__c == null){
                    system.debug('its drive');
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
            
        }
    }
}