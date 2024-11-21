trigger skedStagingLocationTrigger on sked_Staging_Location__c (before insert, before update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedStagingLocationHandler.class);
}