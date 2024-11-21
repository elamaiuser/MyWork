trigger BSFCustomNotificationTrigger on BSF_Custom_Notification__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    new BSFCustomNotificationTriggerHandler().run();
}