/**
 * AS-012769-SYSTEM: Mapping Converted Lead Fields to the Account
 * */

trigger AccountTrigger on Account (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    List<String> phoneFields = new List<String>{'Military_Authority_Phone__c','Phone'};
List<Account> accs = ((List<Account>)Trigger.new);
    //System.debug(accs[0].type);
    if(!System.isBatch()){
            new AccountTriggerHandler().run();
    }

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        FormatPhoneFieldUtility.formatPhoneFields(phoneFields, Trigger.new);
    }
}