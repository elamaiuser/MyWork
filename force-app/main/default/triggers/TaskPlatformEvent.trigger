/**
 * @description Consumer trigger for Task Platform Events.
 * Handles Task creation with hardcoded defaults and updates the source Planned Task.
 */
trigger TaskPlatformEvent on Task_Platform_Event__e (after insert) {
    List<Task> taskList = new List<Task>();
    List<Planned_Task__c> ptsToUpdate = new List<Planned_Task__c>();
    Map<String, String> peMapping = BSF_TaskPlanningService.getDynamicPlatformEventFieldMapping();

    for (Task_Platform_Event__e tp : Trigger.new) {
        System.debug(LoggingLevel.DEBUG, 'Event Details: ' + tp);
        taskList.add(BSF_TaskPlanningService.buildTaskFromEvent(tp, peMapping));
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
    System.debug(LoggingLevel.INFO, 'Total Tasks Processed: ' + taskList.size() + ', Planned Tasks to Update: ' + ptsToUpdate.size());
    if (!ptsToUpdate.isEmpty()) {
        BSF_TaskPlanningService.handleDatabaseResults(Database.update(ptsToUpdate, false), 'Planned Task Update from Platform Event');
    }
}