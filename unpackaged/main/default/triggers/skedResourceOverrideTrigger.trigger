trigger skedResourceOverrideTrigger on sked__Resource_Override__c (before insert, after insert, before update, after update, before delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedResourceOverrideHandler.class);
}