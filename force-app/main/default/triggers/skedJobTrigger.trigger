trigger skedJobTrigger on sked__Job__c (before insert, before update, after insert, after update, before delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedJobHandler.class); 
}