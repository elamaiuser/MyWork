/* The following test class covers below two apex classes:
 * 1. skedFutureCallPostCommitEventHandler
 * 2. skedFutureCallEventHandler
 */ 

@isTest
private class skedFutureCallEventHandler_Test {
    @isTest
    static void publishFutureCallEvent_Test() {
        skedFutureCallEventHandler.publishFutureCallEvent('test', 'test', new Account());
    }
    
    @isTest
    static void publishFutureCallPostCommitEvent_Test() {
        skedFutureCallPostCommitEventHandler.publishFutureCallEvent('test', 'test', new Account());
    }
}