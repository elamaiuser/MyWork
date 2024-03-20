trigger skedOperationRecordTrigger on sked_Operation_Record__c (before insert, before update, after update, before delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedOperationRecordHandler.class);
}