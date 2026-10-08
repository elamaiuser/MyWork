trigger skedStaffingDecisionMatrixTrigger on sked_Staffing_Decision_Matrix__c (after update) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedStaffingDecisionMatrixHandler.class);
}