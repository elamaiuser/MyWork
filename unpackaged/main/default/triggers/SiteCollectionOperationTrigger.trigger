trigger SiteCollectionOperationTrigger on sked_Site_Collection_Operation__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    new SiteCollectionOperationTriggerHandler().run();
}