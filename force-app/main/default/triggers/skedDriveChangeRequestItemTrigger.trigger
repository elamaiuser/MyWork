trigger skedDriveChangeRequestItemTrigger on sked_Drive_Change_Request_Item__c (before insert, before update, after delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedDriveChangeRequestItemHandler.class); 
}