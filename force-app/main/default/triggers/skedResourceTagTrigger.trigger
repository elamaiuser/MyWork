trigger skedResourceTagTrigger on sked__Resource_Tag__c (before insert, before update, before delete, after insert, after update, after delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedResourceTagHandler.class); 
}