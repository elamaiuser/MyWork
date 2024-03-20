trigger skedResourceHoursRecordTrigger on sked_Resource_Hours_Record__c (after update) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedResourceHoursRecordHandler.class); 
}