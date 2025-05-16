trigger skedFixedSiteProcedureProjectionTrigger on sked_Fixed_Site_Procedure_Projection__c (before insert, before update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedFixedSiteProcedureProjectionHandler.class);
}