/**
 * This Class contains testMethods for AddressUtility
 * 
 * */
@isTest
private class TestAddressUtility {
    @testSetup static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('LeadTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert DRD User
        User testDrdUser = (User)mapTestData.get('DRD_USER');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        Lead lead = new Lead(
            FirstName = 'testFirst',
            LastName ='lastName',
            Email= 'test@test.com',
            Street = '2204 Westcrt ln, Apt 213', //misspell street
            City = 'Herndon',
            StateCode = 'VA',
            Company='TestComany',
            Parent_Campaign__c = null,
            Campaign_member_status__c = null,
            PostalCode = '27560'
        );
        insert lead;
        
        Account acc = new Account(name = 'Test Account');
        acc.BillingStreet = '2204 Westcrt ln, Apt 213'; //misspell street
        acc.BillingCity = 'Herndon';
        acc.BillingStateCode = 'VA';
        acc.BillingPostalCode = '20170';
        insert acc;
        
        Contact contact = new Contact (firstname='Test Contact First', lastname='TestContactLast');
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
    }
    
    private static List<User> populateUserFields(String firstName,String lastName,Id profileId,String streetAddress,Integer count){
        List<User> users = new List<User>();
        for(Integer index=1;index<=count;index++){
            User user1 = new User(Alias = firstName+index, FirstName = firstName+index, Email=firstName+index+'.'+lastName+index+'@test.com',EmailEncodingKey='UTF-8', LastName=lastName+index, LanguageLocaleKey='en_US', 
            	LocaleSidKey='en_US', ProfileId = profileId, TimeZoneSidKey='America/Los_Angeles', UserName=firstName+index+'.'+lastName+index+'@test.com.tst1',Street=streetAddress);
        	users.add(user1);
        }
        return users;
    }
    
     @isTest static void testCleanAccountBillingAddress() {
         Test.startTest();
         
         Test.setMock(WebServiceMock.class, new USPSWebServiceMock());
         Test.stopTest();
         Account testMobileAccount = [SELECT Id, BillingStreet, BillingCity FROM Account LIMIT 1];
         upsert testMobileAccount; //this will call clean address from USPS 
     }
    
    @isTest static void testCleanAccountShippingAddress() {
         Test.startTest();
         Test.setMock(WebServiceMock.class, new USPSWebServiceMock());

         Account acc = [SELECT Id FROM Account LIMIT 1];
         acc.ShippingStreet = '2204 Westcrt ln, Apt 213'; //misspell street
         acc.ShippingCity = 'Herndon';
         acc.ShippingStateCode = 'VA';
         acc.ShippingPostalCode = '20170';
         acc.ShippingStreet = '2204 Westcourt Ln,Apt 218'; 
         acc.ShippingCity = 'Hedon';//misspell city
         acc.ShippingStateCode = 'VA';
         acc.ShippingPostalCode = '20170';
		 upsert acc;
        
         Test.stopTest();
         Account updatedAcc = [select id, ShippingStreet from Account LIMIT 1];
        
		 Assert.isTrue(updatedAcc.ShippingStreet == '2204 Westcourt Ln,Apt 218');
     }
    
     @isTest static void testCleanLeadShippingAddress() {
         Test.startTest();
         
         Test.setMock(WebServiceMock.class, new USPSWebServiceMock());
         Lead testLead = [SELECT Id FROM Lead LIMIT 1];
         upsert testLead;
         
         Test.stopTest();
     }
    
     @isTest static void testCleanContactMailingAddress() {
         Test.startTest();
         
         Test.setMock(WebServiceMock.class, new USPSWebServiceMock());
         AddressUtility.cleanContactMailingAddress(new List<Id>{[SELECT Id FROM Contact LIMIT 1].Id});
         
         Test.stopTest();
         Contact updatedContact = [select id, MailingStreet from Contact limit 1];
         Assert.isTrue(updatedContact.MailingStreet == '2204 Westcourt Ln,Apt 218'); 
     }
    
    
    @isTest static void testCleanContactSecondaryAddress() {
        Test.startTest();
        Test.setMock(WebServiceMock.class, new USPSWebServiceMock());

        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        contact.OtherStreet = '2204 Westcrt ln, Apt 213'; //misspell street
        contact.OtherCity = 'Herndon';
        contact.OtherStateCode = 'VA';
        contact.OtherPostalCode = '20170';
        contact.OtherStreet = '2204 Westcourt Ln,Apt 218'; 
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '222-222-2222';
        update contact;
        
        AddressUtility.cleanContactSecondaryAddress(new List<Id>{contact.Id});
        Test.stopTest();
        Contact updatedContact = [select id, OtherStreet from Contact  limit 1];
        Assert.isTrue(updatedContact.OtherStreet == '2204 Westcourt Ln,Apt 218');
     }
    
    @isTest static void testSplitUserStreet() {
        Test.startTest();
       
        AddressUtility.splitUserStreet([Select Id, Name, Street FROM User]);
        
        Test.stopTest();
    }
    
    @isTest static void testPopulateAddress() {
        Test.startTest();
        
        AddressUtility.populateAddress([SELECT Id, AccountId FROM Contact LIMIT 1], null, null);
        
        Test.stopTest();
    }
   
}