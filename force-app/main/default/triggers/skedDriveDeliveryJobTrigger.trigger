trigger skedDriveDeliveryJobTrigger on sked_Drive_Delivery_Job__c (before insert, before update, after update, before delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedDriveDeliveryJobHandler.class); 
}