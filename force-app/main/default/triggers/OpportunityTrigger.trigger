/***
 * AS-012312->DRD User: BPL is Required to Promote Opportunity to Closed-AK
 * 
 * */
trigger OpportunityTrigger on Opportunity (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        System.debug('after insert');
    }
   new OpportunityTriggerHandler().run();

}