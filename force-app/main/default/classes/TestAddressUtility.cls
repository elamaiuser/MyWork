/**
 * This Class contains testMethods for AddressUtility
 * 
 * */
@isTest
public class TestAddressUtility {

    
        
    @testSetup static void setUpData() {
        
        
    }
    
    public static List<User> populateUserFields(String firstName,String lastName,Id profileId,String streetAddress,Integer count){
        List<User> users = new List<User>();
        for(Integer index=1;index<=count;index++){
            User user1 = new User(Alias = firstName+index, FirstName = firstName+index, Email=firstName+index+'.'+lastName+index+'@test.com',EmailEncodingKey='UTF-8', LastName=lastName+index, LanguageLocaleKey='en_US', 
            	LocaleSidKey='en_US', ProfileId = profileId, TimeZoneSidKey='America/Los_Angeles', UserName=firstName+index+'.'+lastName+index+'@test.com.tst1',Street=streetAddress);
        	users.add(user1);
        }
        return users;
    }
    
     @isTest static void testCleanAccountBillingAddress(){
                     Test.startTest();
         Test.setMock(WebServiceMock.class, new USPSWebServiceMock());

         Account acc = new Account(name='Test Account');

         acc.BillingStreet = '2204 Westcrt ln, Apt 213'; //misspell street
         acc.BillingCity = 'Herndon';
         acc.BillingStateCode = 'VA';
         acc.BillingPostalCode = '20170';
       
		 insert acc;
 
         upsert acc; //this will call clean address from USPS
         Test.stopTest();
         Account updatedAcc = [select id,BillingStreet from Account where name='Test Account' limit 1];
         System.debug('updatedAcc.BillingStreet->'+updatedAcc.BillingStreet);
		 System.assert(updatedAcc.BillingStreet == '2204 Westcourt Ln,Apt 218');
         updatedAcc.BillingCity = 'Mclean';
         upsert acc;
         Account updatedAcc2 = [select id,BillingCity from Account where name='Test Account' limit 1];
		 System.assert(updatedAcc2.BillingCity == 'Herndon'); //since our test mock should always return Herndon
         
         
         
     }
    
    @isTest static void testCleanAccountShippingAddress(){
                     Test.startTest();
         Test.setMock(WebServiceMock.class, new USPSWebServiceMock());

         Account acc = new Account(name='Test Account');

         acc.ShippingStreet = '2204 Westcrt ln, Apt 213'; //misspell street
         acc.ShippingCity = 'Herndon';
         acc.ShippingStateCode = 'VA';
         acc.ShippingPostalCode = '20170';
         acc.ShippingStreet = '2204 Westcourt Ln,Apt 218'; 
         acc.ShippingCity = 'Hedon';//misspell city
         acc.ShippingStateCode = 'VA';
         acc.ShippingPostalCode = '20170';
		 insert acc;
         Test.stopTest();
         Account updatedAcc = [select id,ShippingStreet from Account where name='Test Account' limit 1];
         System.debug('updatedAcc.ShippingStreet->'+updatedAcc.ShippingStreet);
		 System.assert(updatedAcc.ShippingStreet == '2204 Westcourt Ln,Apt 218');
     }
    
    
     @isTest static void testCleanLeadShippingAddress(){
                 
        String testZipCode = '27560';

         Lead lead = new Lead();
		 lead.FirstName = 'testFirst';
         lead.LastName ='lastName';
         lead.Email= 'test@test.com';
         lead.Street = '2204 Westcrt ln, Apt 213'; //misspell street
         lead.City = 'Herndon';
         lead.StateCode = 'VA';
          lead.Company='TestComany';
         lead.Parent_Campaign__c = null;
         lead.Campaign_member_status__c = null;
         lead.PostalCode = testZipCode;
		 insert lead;
             Test.startTest();
         Test.setMock(WebServiceMock.class, new USPSWebServiceMock());
         Test.stopTest();
         Lead updatedLead = [select id,Street from Lead  limit 1];
         System.debug('updatedLead.Street->'+updatedLead.Street);
		 System.assert(updatedLead.Street == '2204 Westcourt Ln,Apt 218');
     }
    
    
     @isTest static void testCleanContactMailingAddress(){
                     Test.startTest();
         Test.setMock(WebServiceMock.class, new USPSWebServiceMock());

         Account acc = new Account(name='Test Account');
         insert acc;

        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
         contact.AccountId = acc.id;
         contact.MailingStreet = '2204 Westcrt ln, Apt 213'; //misspell street
         contact.MailingCity = 'Herndon';
         contact.MailingStateCode = 'VA';
         contact.MailingPostalCode = '20170';
         contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
         contact.Primary_Phone__c = 'Mobile Phone';
         contact.MobilePhone = '222-222-2222';
         contact.Email = 'testtest@test.com';
         contact.Original_Service_Date__c = Date.today();
         insert contact;
         Test.stopTest();
         AddressUtility.cleanContactMailingAddress(new List<Id>{contact.Id});
         Contact updatedContact = [select id,MailingStreet from Contact  limit 1];
         System.assert(updatedContact.MailingStreet == '2204 Westcourt Ln,Apt 218');
         
     }
    
    
    @isTest static void testCleanContactSecondaryAddress(){
                     Test.startTest();
         Test.setMock(WebServiceMock.class, new USPSWebServiceMock());
  		Account acc = new Account(name='Test Account');
         insert acc;

        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.AccountId = acc.id;
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; //misspell street
         contact.MailingCity = 'Herndon';
         contact.MailingStateCode = 'VA';
         contact.MailingPostalCode = '20170';
         contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
         contact.OtherStreet = '2204 Westcrt ln, Apt 213'; //misspell street
         contact.OtherCity = 'Herndon';
         contact.OtherStateCode = 'VA';
         contact.OtherPostalCode = '20170';
         contact.OtherStreet = '2204 Westcourt Ln,Apt 218'; 
         contact.Primary_Phone__c = 'Mobile Phone';
         contact.MobilePhone = '222-222-2222';
         contact.Email = 'testtest@test.com';
         contact.Original_Service_Date__c = Date.today();
         insert contact;
         Test.stopTest();
         AddressUtility.cleanContactSecondaryAddress(new List<Id>{contact.Id});
         Contact updatedContact = [select id,OtherStreet from Contact  limit 1];
         System.assert(updatedContact.OtherStreet == '2204 Westcourt Ln,Apt 218');
     }
    
    @isTest static void testSplitUserStreet(){
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile'];
        List<User> userList = populateUserFields('DRD_1','User_1',drdProfile.Id,'176 S Bridge St',2);
        insert userList;
        userList = populateUserFields('DRD_11','User_11',drdProfile.Id,'176 S Bridge St \r\n FLat no-2',2);
        insert userList;
        
        
        Test.startTest();
        System.debug(' testSplitUserStreet '+[Select Id,Name,Street FROM User Where FirstName like '%DRD%']);
        AddressUtility.splitUserStreet([Select Id,Name,Street FROM User Where FirstName like '%DRD%']);
        
        Test.stopTest();
    }
    
    @isTest static void testPopulateAddress(){
        Test.startTest();
        Account acc = new Account(name='Test Account');
         insert acc;
        
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last',AccountId = acc.id,
                                       MailingCity = 'Herndon',MailingStateCode = 'VA',
                                       MailingPostalCode = '20170',MailingStreet = '2204 Westcourt Ln,Apt 218',
                                       OtherCity = 'Herndon',OtherStateCode = 'VA',
                                       OtherPostalCode = '20170',OtherStreet = '2204 Westcourt Ln,Apt 218'); 
         contact.Primary_Phone__c = 'Mobile Phone';
         contact.MobilePhone = '222-222-2222';
         contact.Email = 'testtest@test.com';
         contact.Original_Service_Date__c = Date.today();
         insert contact;
        
    	
        AddressUtility.populateAddress(contact,null,null);
        Test.stopTest();
    }
   
}