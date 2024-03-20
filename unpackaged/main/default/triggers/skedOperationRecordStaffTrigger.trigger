trigger skedOperationRecordStaffTrigger on sked_Operation_Record_Staff__c (before insert, before update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedOperationRecordStaffHandler.class);
}