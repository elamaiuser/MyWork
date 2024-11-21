trigger UpdateTaskChecklistEventTrigger on Update_Task_Checklist__e (after insert) {
    UpdateTaskChecklistEventHandler.processEvents(trigger.new);
}