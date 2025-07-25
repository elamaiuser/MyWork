trigger skedAvailabilityPatternTrigger on sked__Availability_Pattern__c (before insert, before update, before delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedAvailabilityPatternHandler.class);
}