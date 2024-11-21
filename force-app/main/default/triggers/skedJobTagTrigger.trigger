trigger skedJobTagTrigger on sked__Job_Tag__c (after insert, after delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedJobTagHandler.class);
}