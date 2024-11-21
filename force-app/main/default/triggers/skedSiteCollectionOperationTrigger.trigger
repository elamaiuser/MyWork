trigger skedSiteCollectionOperationTrigger on sked_Site_Collection_Operation__c (before insert, after insert) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedSiteCollectionOperationHandler.class); 
}