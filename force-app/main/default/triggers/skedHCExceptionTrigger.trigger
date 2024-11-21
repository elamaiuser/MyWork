trigger skedHCExceptionTrigger on skedHC__Exception__c (before insert, before update, after insert, after update, after delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedHCExceptionHandler.class);
}