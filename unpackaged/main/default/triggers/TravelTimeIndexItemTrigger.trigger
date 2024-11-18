trigger TravelTimeIndexItemTrigger on sked_Travel_Time_Index_Item__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    new TravelTimeIndexItemTriggerHandler().run();
}