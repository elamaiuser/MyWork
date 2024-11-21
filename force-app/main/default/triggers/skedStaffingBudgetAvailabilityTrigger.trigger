trigger skedStaffingBudgetAvailabilityTrigger on sked_Staffing_Budget_Availability__c (after insert, after update, after delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedStaffingBudgetAvailabilityHandler.class);
}