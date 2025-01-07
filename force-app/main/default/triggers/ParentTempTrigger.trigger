trigger ParentTempTrigger on ParentTemp__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    System.Debug('Entered ParentTempTrigger');
}