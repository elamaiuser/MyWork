trigger skedCollectionOpOptimizerSettingTrigger on sked_CollectionOperationOptimizerSetting__c (before insert, before update) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedCollectionOpOptimizerSettingHandler.class);
}