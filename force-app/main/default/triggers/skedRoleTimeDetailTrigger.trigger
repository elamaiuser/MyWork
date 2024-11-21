trigger skedRoleTimeDetailTrigger on sked_Role_Time_Detail__c (after insert, before update, after update, after delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedRoleTimeDetailHandler.class);
}