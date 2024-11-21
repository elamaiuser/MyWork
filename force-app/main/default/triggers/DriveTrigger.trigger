trigger DriveTrigger on sked_Drive__c (before insert, after insert, before update, after update, before delete) {
	new DriveTriggerHandler().run();
}