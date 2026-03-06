/**
 * @description Consumer trigger for Task Platform Events.
 * Handles Task creation with hardcoded defaults and updates the source Planned Task.
 */
trigger TaskPlatformEvent on Task_Platform_Event__e (after insert) {
    List<Task> taskList = new List<Task>();
    List<Planned_Task__c> ptsToUpdate = new List<Planned_Task__c>();
    
    for (Task_Platform_Event__e tp : Trigger.new) {
        Task t = new Task();
        
        if (String.isNotBlank(tp.Subject__c)){       
            t.Subject = tp.Subject__c;
        }
        if (tp.ActivityDate__c != null){             
            t.ActivityDate = tp.ActivityDate__c;
        }
        if (String.isNotBlank(tp.OwnerId__c)){       
            t.OwnerId = tp.OwnerId__c;
        }
        if (String.isNotBlank(tp.WhatId__c)){        
            t.WhatId = tp.WhatId__c;
        }
        if (tp.Drive_Date__c != null){               
            t.Drive_Date__c = tp.Drive_Date__c;
        }
        if (String.isNotBlank(tp.Type__c)){          
            t.Type = tp.Type__c;
        }
        if (String.isNotBlank(tp.Task_Sub_Type__c)){ 
            t.TaskSubtype = tp.Task_Sub_Type__c;
        }
        if (String.isNotBlank(tp.RecordTypeId__c)){  
            t.RecordTypeId = tp.RecordTypeId__c;
        }

        t.Status = BSF_Constants.STATUS_NOT_STARTED; 
        t.Priority = BSF_Constants.NORMAL_PRIORITY_TASK;
        
        taskList.add(t);
    }
    
    if (!taskList.isEmpty()) {
        Database.SaveResult[] srList = Database.insert(taskList, false);
        
        for (Integer i = 0; i < srList.size(); i++) {
            Task_Platform_Event__e originalEvent = Trigger.new[i];
            
            if (srList[i].isSuccess()) {
                if (String.isNotBlank(originalEvent.Planned_Task_Id__c)) {
                    ptsToUpdate.add(new Planned_Task__c(
                        Id = originalEvent.Planned_Task_Id__c,
                        Status__c = BSF_Constants.PLANNED_TASK_STATUS_PROCESSED
                    ));
                }
            } else {
                System.debug(LoggingLevel.ERROR, 'Task Insert Failed for ' + originalEvent.WhatId__c + ': ' + srList[i].getErrors()[0].getMessage());
            }
        }
    }

    if (!ptsToUpdate.isEmpty()) {
        Database.update(ptsToUpdate, false);
    }
}