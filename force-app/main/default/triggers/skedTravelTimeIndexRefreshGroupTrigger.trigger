trigger skedTravelTimeIndexRefreshGroupTrigger on sked_Travel_Time_Index_Refresh_Group__c (before insert, after insert) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedTravelTimeIndexRefreshGroupHandler.class); 
}