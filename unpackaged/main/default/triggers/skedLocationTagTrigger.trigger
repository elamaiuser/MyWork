trigger skedLocationTagTrigger on sked_Location_Tag__c (after insert, after update, after delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedLocationTagHandler.class);
}