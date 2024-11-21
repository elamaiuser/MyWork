trigger skedDriveTrigger on sked_Drive__c (before insert, after insert, before update, after update, before delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedDriveHandler.class); 
}