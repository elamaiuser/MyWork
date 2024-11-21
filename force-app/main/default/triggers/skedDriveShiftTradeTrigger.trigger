trigger skedDriveShiftTradeTrigger on sked_Drive_Shift_Trade__c (before insert, after insert, before update, after update) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedDriveShiftTradeHandler.class);
}