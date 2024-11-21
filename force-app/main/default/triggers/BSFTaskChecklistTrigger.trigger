trigger BSFTaskChecklistTrigger on BSF_Task_Checklist__c (before insert, after update) {
    new BSFTaskChecklistTriggerHandler().run();
}