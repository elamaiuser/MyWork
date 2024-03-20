trigger skedTravelTimeIndexRefreshRequestTrigger on sked_Travel_Time_Index_Refresh_Request__c (after insert) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedTravelTimeIndexRefreshRequestHandler.class); 
}