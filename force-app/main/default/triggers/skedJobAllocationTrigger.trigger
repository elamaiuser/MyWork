trigger skedJobAllocationTrigger on sked__Job_Allocation__c (before insert, before update, before delete, after insert, after update) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedJobAllocationHandler.class);
}