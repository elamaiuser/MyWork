trigger skedTravelTimeIndexItemTrigger on sked_Travel_Time_Index_Item__c (before insert, after update) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedTravelTimeIndexItemHandler.class); 
}