trigger PopulateVersionKey on Taxonomy__c (before insert,before update) {

    for (Taxonomy__c record : Trigger.new) {
        if (record.Version_Key__c != null) {
            record.Internal_Version_Key__c = String.valueOf(record.Version_Key__c.intValue());
       
        }
            
        
    }
}