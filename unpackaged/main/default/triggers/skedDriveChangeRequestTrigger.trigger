trigger skedDriveChangeRequestTrigger on sked_Drive_Change_Request__c (before insert, after insert, before update, after update, after delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedDriveChangeRequestHandler.class); 
}