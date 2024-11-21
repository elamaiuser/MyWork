trigger skedStaffingConstraintTrigger on sked_Staffing_Constraint__c (after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedStaffingConstraintHandler.class);
}