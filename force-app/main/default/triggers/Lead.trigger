trigger Lead on Lead (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    new LeadTriggerHandler().run();

    List<String> phoneFields = new List<String>{'MobilePhone','Phone'};

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        FormatPhoneFieldUtility.formatPhoneFields(phoneFields, Trigger.new);
    }
}