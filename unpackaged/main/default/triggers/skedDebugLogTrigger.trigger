trigger skedDebugLogTrigger on sked__Debug_Log__c (before insert, after insert) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedDebugLogHandler.class);
}