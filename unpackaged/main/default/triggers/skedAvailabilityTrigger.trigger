trigger skedAvailabilityTrigger on sked__Availability__c (before insert, before update, before delete, after insert, after update, after delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedAvailabilityHandler.class);
}