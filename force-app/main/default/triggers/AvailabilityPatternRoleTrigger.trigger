trigger AvailabilityPatternRoleTrigger on Availability_Pattern_Role__c (after update) {
    new AvailabilityPatternRoleHandler().run();
}