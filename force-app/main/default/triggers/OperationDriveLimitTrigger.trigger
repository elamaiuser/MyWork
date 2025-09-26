trigger OperationDriveLimitTrigger on sked_Operation_Drive_Limit__c (before insert, after insert, before update, after update, before delete) {
    new OperationDriveLimitTriggerHandler().run();
}