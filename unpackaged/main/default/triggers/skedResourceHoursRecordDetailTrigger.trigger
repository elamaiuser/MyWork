trigger skedResourceHoursRecordDetailTrigger on sked_Resource_Hours_Record_Detail__c (after insert, after delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedResourceHoursRecordDetailHandler.class); 
}