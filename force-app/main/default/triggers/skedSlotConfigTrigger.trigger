trigger skedSlotConfigTrigger on sked_Collection_Operation_Slot_Config__c (before insert, after insert, before update, after update) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedSlotConfigHandler.class);
}
