trigger skedResourceBiomedCollectionOpTrigger on sked_Resource_Biomed_Collection_Op__c (after insert, after update, before delete) {
	skedTriggerHub handler = new skedTriggerHub();
    handler.processTriggerHandler(skedResourceBiomedCollectionOpHandler.class);
}