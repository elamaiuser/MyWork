trigger DriveMarketingProgramTrigger on Drive_Marketing_Programs__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	new DriveMarketingProgramTriggerHandler().run();
}