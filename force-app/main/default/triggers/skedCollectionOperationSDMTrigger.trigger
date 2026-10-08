trigger skedCollectionOperationSDMTrigger on sked_Collection_Operation_SDM__c (before insert, before update, after insert) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedCollectionOperationSDMHandler.class);
}