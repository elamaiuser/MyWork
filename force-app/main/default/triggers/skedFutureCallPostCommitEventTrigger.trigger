trigger skedFutureCallPostCommitEventTrigger on sked_Future_Call_Post_Commit_Event__e (after insert) {
    skedPlatformEventHub handler = new skedPlatformEventHub();
    handler.processTriggerHandler(skedFutureCallPostCommitEventHandler.class);
}