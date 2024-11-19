@isTest
private class skedDebugLogTrigger_Test {
    @isTest
    static void trigger_Test() {
        insert new sked__Debug_Log__c(sked__Type__c = skedConstants.DEBUG_LOG_TYPE_WORKDAY_API);
    }
}