/**
 * Created by spring1 on 27-07-2021.
 */

trigger ChapterTrigger on Chapter__c (before insert, before update) {
    List<String> phoneFields = new List<String>{'Phone__c'};

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
         FormatPhoneFieldUtility.formatPhoneFields(phoneFields, Trigger.new);
    }
}