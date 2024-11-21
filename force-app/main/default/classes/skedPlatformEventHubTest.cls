@isTest
private class skedPlatformEventHubTest {
    @isTest
    static void isObjectProcessed_Test() {
        sked_Future_Call_Event__e testEvent = new sked_Future_Call_Event__e(
            sked_Class_Name__c = 'classname',
            sked_Method_Name__c = 'methodname',
            sked_Parameter_Data__c = JSON.serialize(new Account())
        );

        skedPlatformEventHub hub = new skedPlatformEventHub();
        hub.isObjectProcessed(skedFutureCallEventHandler.class, testEvent);
    }
}