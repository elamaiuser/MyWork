trigger skedLocationResourceScoreTrigger on sked__Location_Resource_Score__c (before insert, after insert, before update, after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedLocationResourceScoreHandler.class);
}