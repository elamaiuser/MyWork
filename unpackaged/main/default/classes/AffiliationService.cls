public with sharing class AffiliationService {
    
      
    public static void populateEndDateInAccountAffiliation(list<Marketing_Program__c> AffiliationList,String triggerContext){
        system.debug('entered populateEndDateInAccountAffiliation');
        if(triggerContext=='Update'){
            set<Id> affiliationIds =new set<Id>();
            for(Marketing_Program__c c:AffiliationList){ //
                affiliationIds.add(c.id);
            }
            list<Account_Marketing_Program__c> newListAMP= new List<Account_Marketing_Program__c>();
            for(Account_Marketing_Program__c ac:[select id,name,End_Date__c from Account_Marketing_Program__c where Marketing_Program__c IN:affiliationIds]){
                system.debug('populateEndDateInAccountAffiliation1'+ac);
                
                if(ac.End_Date__c !=null){
                    ac.Date_Removed__c=ac.End_Date__c;
                    system.debug('populateEndDateInAccountAffiliation2'+ac.Date_Removed__c);
                    newListAMP.add(ac);
                }
            }
            database.update(newListAMP);
            
            list<Drive_Marketing_Programs__c> newListDMP= new List<Drive_Marketing_Programs__c>();
            for(Drive_Marketing_Programs__c dc:[select id,name,End_Date__c from Drive_Marketing_Programs__c where Marketing_Program__c IN:affiliationIds]){
                if(dc.End_Date__c !=null){
                    dc.Date_Removed__c=dc.End_Date__c;
                    system.debug('populateEndDateInAccountAffiliation2'+dc.Date_Removed__c);
                    newListDMP.add(dc);
                } 
            } 
            database.update(newListDMP);
        }
    }

}