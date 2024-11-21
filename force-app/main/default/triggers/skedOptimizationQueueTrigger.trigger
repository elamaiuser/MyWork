trigger skedOptimizationQueueTrigger on sked_Optimization_Queue__c (before insert, after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedOptimizationQueueHandler.class);
}