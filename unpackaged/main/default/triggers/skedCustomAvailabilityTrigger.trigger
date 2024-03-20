trigger skedCustomAvailabilityTrigger on sked_Custom_Availability__c (before insert, before update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedCustomAvailabilityHandler.class);
}