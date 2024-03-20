/**
 * Created by spring1 on 27-07-2021.
 */

trigger BiomedAccountManagerTrigger on Biomed_Account_Manager__c (before insert, before update) {
    List<String> phoneFields = new List<String>{'Mobile_Phone__c','Work_Phone__c'};

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        FormatPhoneFieldUtility.formatPhoneFields(phoneFields, Trigger.new);
    }
}