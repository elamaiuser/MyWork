trigger skedSlotTrigger on sked__Slot__c (before insert, after insert, before update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedSlotHandler.class);
}