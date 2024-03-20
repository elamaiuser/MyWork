trigger skedOptimizationRunTrigger on sked_Optimization_Run__c (after update, before insert) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedOptimizationRunHandler.class);
}