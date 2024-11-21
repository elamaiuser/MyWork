trigger skedFutureEventTrigger on sked_Future_Call_Event__e (after insert) {
    skedPlatformEventHub handler = new skedPlatformEventHub();
    handler.processTriggerHandler(skedFutureCallEventHandler.class);
}