trigger skedBiomedCollectionOpTrigger on Biomed_Collection_Op_Center__c (before update, after update, after insert, after delete) {
    skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedBiomedCollectionOpHandler.class);    
}