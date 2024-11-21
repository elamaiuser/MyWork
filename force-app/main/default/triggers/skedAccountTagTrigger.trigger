trigger skedAccountTagTrigger on sked__Account_Tag__c (after insert, after update, after delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedAccountTagHandler.class);
}