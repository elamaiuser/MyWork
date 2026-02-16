public with sharing class CollectionOpAvailabilityTriggerHandler extends triggerHandler {

    public override void afterUpdate() {
        if(super.getTriggerMethodsToBypass().indexOf('updateCoApStatusOnResources') == -1) {
            CollectionOpAvailabilityTriggerService.updateCoApStatusOnResources((List<Collection_Operation_Availability__c>)trigger.new,(Map<Id, Collection_Operation_Availability__c>)trigger.oldMap);
        }
    }
}