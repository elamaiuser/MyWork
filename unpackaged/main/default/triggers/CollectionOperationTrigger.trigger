/**
 * @description: Trigger on collection oparation object
**/
trigger CollectionOperationTrigger on Biomed_Collection_Op_Center__c (before insert, after insert, before update, after update, after delete) {
    new CollectionOperationTriggerHandler().run();
}