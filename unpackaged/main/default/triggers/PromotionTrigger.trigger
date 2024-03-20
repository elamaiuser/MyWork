/***
* HRP-1615->User: Managing Promotional Items Available to Drives
* 
* */
trigger PromotionTrigger on Promotion__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
   new PromotionTriggerHandler().run();
}