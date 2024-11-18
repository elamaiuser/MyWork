trigger JobAllocationTrigger on sked__Job_Allocation__c (before insert, after insert, before update, after update, after delete) {
    if (Trigger.isAfter && Trigger.isInsert) {
        System.debug('after insert');
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        System.debug('after update');
    }
	new JobAllocationTriggerHandler().run();
}