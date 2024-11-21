trigger skedActivityTrigger on sked__Activity__c (before insert, after insert, before update, after update, before delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedActivityHandler.class);
}