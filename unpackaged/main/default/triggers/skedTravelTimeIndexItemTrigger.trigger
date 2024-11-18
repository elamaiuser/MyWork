trigger skedTravelTimeIndexItemTrigger on sked_Travel_Time_Index_Item__c (before insert, after update, after insert) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedTravelTimeIndexItemHandler.class); 
}