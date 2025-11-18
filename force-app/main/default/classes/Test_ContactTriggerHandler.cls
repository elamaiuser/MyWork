/** (Depricated) Contact Trigger related classes will be covered by contactService_Test
 * This Class contains testMethods for ContactTriggerHandler and Contact Service
 * 
 * */
@isTest
public class Test_ContactTriggerHandler {
    
   /* @testSetup static void setUpData() {
        
        Account acc = new Account(name='Test Account');
        insert acc;
    }
    
    @isTest static void testContactInsertAndUpdates(){
        Account acc = new Account(name='Test Account');
        insert acc;
        //test do not contact field with new insert
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.Email = 'testContact@gmail.com';
        contact.Original_Service_Date__c = system.today().addDays(3);
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
        contact.Do_Not_Contact__c = true;
        contact.Do_Not_Contact_Reason__c = 'ARC Decision';
        contact.AccountId = acc.id;
        insert contact;
        
        //should have auto populated do not contact date
        Contact contactUpdated = [select id,Do_Not_Contact_Date__c from contact  limit 1];
        System.debug('contactUpdated->'+contactUpdated);
       // System.assert(contactUpdated.Do_Not_Contact_Date__c != null);
        contactUpdated.Do_Not_Contact__c = false;//changing to false should revert do not contact date back to null
        update contactUpdated;
        Contact contactUpdated2 = [select id,Do_Not_Contact_Date__c from contact  limit 1];
        System.assert(contactUpdated2.Do_Not_Contact_Date__c == null);
        contactUpdated2.Do_Not_Contact__c = true;//revert it back to true
        contactUpdated2.Do_Not_Contact_Reason__c = 'ARC Decision';
        update contactUpdated2;
        Contact contactUpdated3 = [select id,Do_Not_Contact_Date__c from contact  limit 1];
        System.assert(contactUpdated3.Do_Not_Contact_Date__c != null);        
    }
    
    @isTest static void testContactService(){
        Account account = new Account(name='Test Account');
        insert account;
       
	  Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.Email = 'testContact@gmail.com';
        contact.Original_Service_Date__c = system.today().addDays(3);
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
        contact.Do_Not_Contact__c = true;
        contact.Do_Not_Contact_Reason__c = 'ARC Decision';
        contact.AccountId = account.id;
        insert contact;
        contact.AccountId =account.id;
        update contact;
        Account_Service_Role__c accSvcRole = new Account_Service_Role__c();
        accSvcRole.Account__c =account.id;
        accSvcRole.Contact__c = contact.Id;
        accSvcRole.Account_Service_Role__c = 'Blood Program Leader';
        Date myDate = Date.newInstance(2020, 2, 17);
        accSvcRole.Start_Date__c = myDate;
        insert accSvcRole;
        //now setting contact to do not contact should end the account service role relation
        contact.Do_Not_Contact__c = true;
        contact.Do_Not_Contact_Reason__c = 'ARC Decision';      
              
    }*/
}