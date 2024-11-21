trigger skedAsyncJobTrigger on sked__Async_Job__c (after insert) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedAsyncJobHandler.class); 

}