trigger AffiliationTrigger on Marketing_Program__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
   new AffiliationTriggerHandler().run();

}