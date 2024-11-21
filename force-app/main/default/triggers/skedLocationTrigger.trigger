trigger skedLocationTrigger on sked__Location__c (before insert, after insert, before update, after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedLocationHandler.class);
}