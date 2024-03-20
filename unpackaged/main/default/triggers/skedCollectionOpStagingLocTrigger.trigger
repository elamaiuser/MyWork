trigger skedCollectionOpStagingLocTrigger on sked_Collection_Op_Staging_Location__c (before insert, after insert, before update, after update, before delete, after delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedCollectionOpStagingLocationHandler.class);
}