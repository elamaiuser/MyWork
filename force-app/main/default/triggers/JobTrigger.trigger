trigger JobTrigger on sked__Job__c (before insert, after insert, before update, after update, after delete) {
	new JobTriggerHandler().run();
}