trigger skedResourceRoleGroupTrigger on sked_Resource_Role_Group__c (before insert, before update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedResourceRoleGroupHandler.class);
}