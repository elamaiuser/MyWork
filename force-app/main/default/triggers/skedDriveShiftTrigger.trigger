trigger skedDriveShiftTrigger on sked_Drive_Shift__c (before insert, after insert, before update, after update, before delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedDriveShiftHandler.class);
}