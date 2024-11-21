/*
 * AS-013042-ContactAddress Standardization
 * 
 * */
trigger ContactTrigger on Contact (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    new ContactTriggerHandler().run();
    
    //======Pritam : 23/02/2021========
        if(Trigger.isUpdate && Trigger.isBefore) {
            List<Id> ids = new List<Id>();
            for (Contact ct : Trigger.New) {
                if ((ct.FirstName != Trigger.oldMap.get(ct.Id).FirstName) || (ct.LastName != Trigger.oldMap.get(ct.Id).LastName)) {
                    ids.add(ct.Id);
                }
            }
            if (ids.size() > 0) {
                ContactTriggerHandler.updateNameChangeFlag(ids);
            }
        }
    //=================================
    List<String> phoneFields = new List<String>{'AssistantPhone','HomePhone','MobilePhone','OtherPhone','Phone'};

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        FormatPhoneFieldUtility.formatPhoneFields(phoneFields, Trigger.new);
    }
}