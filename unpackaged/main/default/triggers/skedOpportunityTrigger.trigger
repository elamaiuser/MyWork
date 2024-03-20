trigger skedOpportunityTrigger on Opportunity (before update, after update) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedOpportunityHandler.class); 
}