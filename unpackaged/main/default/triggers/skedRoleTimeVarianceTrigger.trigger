trigger skedRoleTimeVarianceTrigger on sked_Role_Time_Variance__c (before insert, before update, after insert, after update, after delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedRoleTimeVarianceHandler.class);
}