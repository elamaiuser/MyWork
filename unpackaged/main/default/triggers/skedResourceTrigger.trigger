trigger skedResourceTrigger on sked__Resource__c (before insert, after insert, before update, after update, before delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedResourceHandler.class);
}