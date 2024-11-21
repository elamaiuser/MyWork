trigger skedActivityResourceTrigger on sked__Activity_Resource__c (before insert, before update, before delete, after insert, after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedActivityResourceHandler.class);
}