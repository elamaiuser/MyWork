trigger CollectionOperationAvailabilityTrigger on Collection_Operation_Availability__c (after insert, after update) {
    new CollectionOpAvailabilityTriggerHandler().run();
}