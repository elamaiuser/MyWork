/* 
 * @description: This class serves multple contact related functionalities using different methods
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 07/05/2023				 Kishore Das			  Logic for HRP-10208 (Historical drive roles should not be considered in validation to inactivate contact)
 * 03/08/2023				 Kishore Das		      Users other than System Admin should not have any delete record permissions(Logic for HRP-10572)--> This method is deleted as part of HRP-10115
 ************************************************************************************************************************************************
*/
/*
 * AS-013042-ContactAddress Standardization
 * 
 * */
public class ContactService {
    
    //AS-013042-ContactAddress standardization, will be called from before insert and before update
   
    public static void standardizeMailingAddress(List<Contact> newContacts, Map<Id,Contact> oldMap, 
                                       Map<Id,Contact> newMap,String op){
                                           
             System.debug('Entered method standardizeMailingAddress with oldMap and newMap'+oldMap+' : '+newMap);
             if(System.isFuture()){//extremely important,only run for first time otherwise will get exception future cannot be called from future
                 return;
             }                              
             //collects all leads which need to be evaluated for clean address                               
             List<Id> evaluateAddressContactList =  new List<Id>();                             
             for(Contact newContact:newContacts){
                 
                 boolean isEmptyAddress = AddressUtility.isEmptyAddress(newContact,AddressUtility.ContactMailingAddressFieldsMap);
                 if(isEmptyAddress == null){
                   System.debug('Address is null for incoming Contact');
 				   continue;
                 }
                 InformaticaStandardAddress stdAddr = null;
                 if(op.equals('INSERT')){ 
                     System.debug('Coming in for first time insert without empty address for lead object:'+newContact);
					 evaluateAddressContactList.add(newContact.id);//this is called from after insert, so id will be there always
                 }else if(op.equals('UPDATE')){
                     System.debug('Coming in as update');
                     Contact oldContact = oldMap.get(newContact.id);
                     boolean isAddressChanged = AddressUtility.isAddresssChanged(oldContact, newContact,AddressUtility.ContactMailingAddressFieldsMap);
                     System.debug('isAddressChanged:'+isAddressChanged);
                     if(isAddressChanged == true){
                         evaluateAddressContactList.add(newContact.id);//this is called from after insert/after update, so id will be there always
                     }
                 }
                //Call Informatica API and clean addresses
                  
            }
                                           
                                           if(!evaluateAddressContactList.isEmpty())  
                                                     {
                                                         AddressUtility.cleanContactMailingAddress(evaluateAddressContactList);
                                                     }
      }
    
    public static void standardizeSecondaryAddress(List<Contact> newContacts, Map<Id,Contact> oldMap, 
                                       Map<Id,Contact> newMap,String op){
                                           
             System.debug('Entered method standardizeSecondaryAddress with oldMap and newMap'+oldMap+' : '+newMap);
             if(System.isFuture()){//extremely important,only run for first time otherwise will get exception future cannot be called from future
                 return;
             }                              
             //collects all leads which need to be evaluated for clean address                               
             List<Id> evaluateAddressContactList =  new List<Id>();                             
             for(Contact newContact:newContacts){
                 
                 boolean isEmptyAddress = AddressUtility.isEmptyAddress(newContact,AddressUtility.ContactSecondaryAddressFieldsMap);
                 if(isEmptyAddress == null){
                   System.debug('Address is null for incoming Contact');
 				   continue;
                 }
                 InformaticaStandardAddress stdAddr = null;
                 if(op.equals('INSERT')){ 
                     System.debug('Coming in for first time insert without empty address for lead object:'+newContact);
					 evaluateAddressContactList.add(newContact.id);//this is called from after insert, so id will be there always
                 }else if(op.equals('UPDATE')){
                     System.debug('Coming in as update');
                     Contact oldContact = oldMap.get(newContact.id);
                     boolean isAddressChanged = AddressUtility.isAddresssChanged(oldContact, newContact,AddressUtility.ContactSecondaryAddressFieldsMap);
                     System.debug('isAddressChanged:'+isAddressChanged);
                     if(isAddressChanged == true){
                         evaluateAddressContactList.add(newContact.id);//this is called from after insert/after update, so id will be there always
                     }
                 }
                //Call Informatica API and clean addresses
                  
            }
                                           if(!evaluateAddressContactList.isEmpty())  
                                                       {
                                                           AddressUtility.cleanContactSecondaryAddress(evaluateAddressContactList);
                                                       }
      }
    
	public static void updatePhoneNumberFields(list<Contact> contactNewList, map<Id, Contact> contactOldMap) {
        System.debug('### inside updatePhoneNumberFields');
        for (Contact contactRec : contactNewList) {
            if(String.isNotBlank(contactRec.Primary_Phone__c) && contactRec.phone != null){
                if(contactRec.Primary_Phone__c.equalsIgnoreCase('Work Phone') && contactRec.OtherPhone == null) {
                    contactRec.OtherPhone = contactRec.phone;
                }else if(contactRec.Primary_Phone__c.equalsIgnoreCase('Mobile Phone') && contactRec.MobilePhone == null) {
                    contactRec.MobilePhone = contactRec.phone;
                }else if(contactRec.Primary_Phone__c.equalsIgnoreCase('Home Phone') && contactRec.HomePhone == null) {
                    contactRec.HomePhone = contactRec.phone;
                } 
            }
        } 
    }
    
   
    //Logic for HRP-10208(for update trigger call)   
    //@Description: validation to inactivate contact 
    //***starts here***
    public static void preventContactDeactivationIfAssociatedWithOpportunityOrAccount(List<Contact> updatedContacts, Map<Id, Contact> oldContactsMap) {
        Set<Id> contactIdsToCheck = new Set<Id>();
        
        for (Contact contact : updatedContacts) { 
            Contact oldContact = oldContactsMap.get(contact.Id);
            if(oldContact.Active__c != contact.Active__c && !contact.Active__c){
                contactIdsToCheck.add(contact.Id);
            }
        }
        
        if (!contactIdsToCheck.isEmpty()) {
            List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, OpportunityId, Opportunity.Drive_Date__c, Opportunity.Is_Template__c
                                                                    FROM OpportunityContactRole
                                                                    WHERE ContactId IN :contactIdsToCheck
                                                                    AND (Opportunity.Drive_Date__c > TODAY OR Opportunity.Is_Template__c = true)];
    
            List<Account_Service_Role__c> accountServiceRoles = [SELECT Id, Contact__c
                                                                 FROM Account_Service_Role__c
                                                                 WHERE Contact__c IN :contactIdsToCheck
                                                                 AND (End_Date__c >= TODAY OR End_Date__c=null)];
    
            Set<Id> contactsToDisassociate = new Set<Id>();
    
            for (OpportunityContactRole ocr : opportunityContactRoles) {
                contactsToDisassociate.add(ocr.ContactId);
            }
            
            for (Account_Service_Role__c asr : accountServiceRoles) {
                contactsToDisassociate.add(asr.Contact__c);
            }
    
            for (Contact contact : updatedContacts) {
                if (contactsToDisassociate.contains(contact.Id)) {
                    contact.Active__c.addError(System.Label.ContactError);
                }
            }
        }
    }
    
    //***ends here***
	//Logic for HRP-10208(for update)
	
    
}