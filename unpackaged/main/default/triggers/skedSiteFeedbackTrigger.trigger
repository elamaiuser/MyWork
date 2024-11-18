trigger skedSiteFeedbackTrigger on sked_Site_Feedback__c (before insert, before update, after insert, after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedSiteFeedbackHandler.class); 
}