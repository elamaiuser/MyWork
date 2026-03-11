trigger skedAvailabilityPatternResourceTrigger on sked__Availability_Pattern_Resource__c (before insert, after insert, before update, after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedAvailabilityPatternResourceHandler.class);
}