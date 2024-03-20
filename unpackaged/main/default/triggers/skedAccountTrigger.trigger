trigger skedAccountTrigger on Account (after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedAccountHandler.class); 
}