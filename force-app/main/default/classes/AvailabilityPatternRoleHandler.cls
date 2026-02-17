public without sharing class AvailabilityPatternRoleHandler extends triggerHandler {

    public override void afterUpdate() {
        if(super.getTriggerMethodsToBypass().indexOf('updateCoApStatusOnResources') == -1) {
            AvailabilityPatternRoleTriggerService.updateCoApStatusOnResources((List<Availability_Pattern_Role__c>)trigger.new,(Map<Id, Availability_Pattern_Role__c>)trigger.oldMap);
        }
    }

}