trigger AvailabilityPatternRoleTrigger on Availability_Pattern_Role__c (after insert, after update) {
    new AvailabilityPatternRoleHandler().run();
}