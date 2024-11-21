trigger AccountServiceRoleTrigger on Account_Service_Role__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
 new AccountServiceRoleTriggerHandler().run();
}