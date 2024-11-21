trigger skedUserTrigger on User (after insert, after update) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedUserHandler.class); 
}