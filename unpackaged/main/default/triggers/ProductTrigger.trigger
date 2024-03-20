trigger ProductTrigger on Product2 (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
new ProductTriggerHandler().run();

}