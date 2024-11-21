trigger skedAccountResourceScoreTrigger on sked__Account_Resource_Score__c (before insert, after insert, before update, after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedAccountResourceScoreHandler.class);
}