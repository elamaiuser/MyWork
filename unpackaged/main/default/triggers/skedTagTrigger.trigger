trigger skedTagTrigger on sked__Tag__c (before insert, before update, before delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedTagHandler.class); 
}