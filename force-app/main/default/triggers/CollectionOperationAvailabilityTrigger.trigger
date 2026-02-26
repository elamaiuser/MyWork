trigger CollectionOperationAvailabilityTrigger on Collection_Operation_Availability__c (after update) {
    new CollectionOpAvailabilityTriggerHandler().run();
}