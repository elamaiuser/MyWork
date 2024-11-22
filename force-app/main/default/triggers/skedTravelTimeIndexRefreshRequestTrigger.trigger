trigger skedTravelTimeIndexRefreshRequestTrigger on sked_Travel_Time_Index_Refresh_Request__c (after insert, after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedTravelTimeIndexRefreshRequestHandler.class); 
}