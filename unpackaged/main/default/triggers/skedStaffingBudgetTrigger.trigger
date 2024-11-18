trigger skedStaffingBudgetTrigger on sked_Staffing_Budget__c (after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedStaffingBudgetHandler.class);
}