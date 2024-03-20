trigger skedStaffingBudgetTrigger on sked_Staffing_Budget__c (before insert, before update) {
	skedTriggerHub handler = new skedTriggerHub();
    // handler.processTriggerHandler(skedStaffingBudgetHandler.class);
}