/**
 * Created by spring1 on 27-07-2021.
 */

trigger UserTrigger on User (before insert, before update, after insert, after update ) {
    //system.debug('hhhtest');
    List<String> phoneFields = new List<String>{'WorkPhone__c','Phone'};
        
        //if(!System.isBatch()){
            //system.debug('ggg');
            new UserTriggerHandler().run(); 
    //}

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
         FormatPhoneFieldUtility.formatPhoneFields(phoneFields, Trigger.new);
    }
}