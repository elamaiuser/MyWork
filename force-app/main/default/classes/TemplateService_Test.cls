/* This test class is coving the following classes -
 * TemplateService (93%)
 * ***************************************************************************/

@isTest
private class TemplateService_Test {

    @testSetup
    private static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Fixed Site Account
        Account testFixedSiteAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        testFixedSiteAccount.Internal_Name__c =  'TEST ACCOUNT 2';
        insert testFixedSiteAccount;
        
        // insert Contact
        List<Contact> testContacts = new List<Contact>();
        Contact testContact;
        testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.Id;
        testContacts.add(testContact);
        
        testContact = new Contact(
            firstname = 'Contact Test First 2',
            lastname = 'TestContactLast2',
            Email = 'testContact2@gmail.com',
            Original_Service_Date__c = system.today().addDays(3),
        	MailingStreet = '2204 Westcrt ln, Apt 213',
        	MailingCity = 'Herndon',
        	MailingStateCode = 'MI',
        	MailingPostalCode = '48420',
            Primary_Phone__c = 'Mobile Phone',
            MobilePhone = '752-781-0091',
            AccountId = testFixedSiteAccount.Id
        );
        testContacts.add(testContact);
        insert testContacts;
        
        // insert Account Service Roles
        List<Account_Service_Role__c> testServiceRoles = new List<Account_Service_Role__c>();
        
        Account_Service_Role__c testServiceRole;
        testServiceRole = new Account_Service_Role__c();
        testServiceRole.Account_Service_Role__c = 'Blood Program Leader';
        testServiceRole.Account__c = testMobileAccount.Id; 
        testServiceRole.Contact__c = testContacts[0].id;
        testServiceRoles.add(testServiceRole);
        
        testServiceRole = new Account_Service_Role__c();
        testServiceRole.Account_Service_Role__c = 'Account Contact';
        testServiceRole.Account__c = testFixedSiteAccount.Id; 
        testServiceRole.Contact__c = testContacts[0].id;
        testServiceRole.Start_Date__c = system.today();
        testServiceRoles.add(testServiceRole);
        
        testServiceRole = new Account_Service_Role__c();
        testServiceRole.Account_Service_Role__c = 'Account Contact';
        testServiceRole.Account__c = testFixedSiteAccount.Id; 
        testServiceRole.Contact__c = testContacts[1].id;
        testServiceRole.Start_Date__c = system.today();
        testServiceRoles.add(testServiceRole);
        insert testServiceRoles;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
    }
    
    static testMethod void getDefaultPrimaryDriveContactBPL_Test() {
        Test.startTest();
        
        Id testAccountId = [SELECT Id FROM Account WHERE Internal_Name__c = 'TEST ACCOUNT 1' LIMIT 1].Id;
        Id testContactId = [SELECT Id FROM Contact LIMIT 1].Id;
        
        TemplateService.TemplateWrapper wrapper = new TemplateService.TemplateWrapper();
        wrapper.accountId = testAccountId;
        
        List<String> result = TemplateService.getDefaultPrimaryDriveContact(new List<TemplateService.TemplateWrapper>{wrapper});
        Test.stopTest();
        
        Assert.isTrue(result[0] == testContactId);
    }
    
    static testMethod void getDefaultPrimaryDriveContactNoBPL_Test() {
        Test.startTest();
        
        Id testAccountId = [SELECT Id FROM Account WHERE Internal_Name__c = 'TEST ACCOUNT 2' LIMIT 1].Id;
        Id testContactId = [SELECT Id FROM Contact WHERE FirstName = 'Contact Test First 2' LIMIT 1].Id;
        
        TemplateService.TemplateWrapper wrapper = new TemplateService.TemplateWrapper();
        wrapper.accountId = testAccountId;
        
        List<String> result = TemplateService.getDefaultPrimaryDriveContact(new List<TemplateService.TemplateWrapper>{wrapper});
        Test.stopTest();
        
        Assert.isTrue(result[0] == testContactId);
    }
    
    static testMethod void createPrimaryContactDriveServiceRole_Test() {
        Test.startTest();
        
        Id testAccountId = [SELECT Id FROM Account WHERE Internal_Name__c = 'TEST ACCOUNT 1' LIMIT 1].Id;
        Id testContactId = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact First 1' LIMIT 1].Id;
        Id testSiteId = [SELECT Id FROM sked__Location__c LIMIT 1].Id;
        
        // insert Template
        Opportunity mobileTemplateOpp = new Opportunity(
            Name = 'Mobile Template Opp',
            RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
            StageName = 'Discovery', 
            CloseDate = System.today(),
            Is_Template__c = TRUE,
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
            Anticipated_Registered_Donors__c = 10,
            WB_Projected_Procedures__c = 11,
            X2RBC_Projected_Procedures__c = 12,
            Red_Cross_Volunteer_Required__c = true,
            Red_Cross_Volunteer_Quantity__c = 1,
            AccountId = testAccountId,
            Drive_Site__c = testSiteId,
            Primary_Drive_Contact__c = testContactId
        );
        insert mobileTemplateOpp;
        Test.stopTest();
        
        List<OpportunityContactRole> testDriveContacts = [SELECT Id, Role FROM OpportunityContactRole WHERE OpportunityId = :mobileTemplateOpp.Id];
        Assert.isTrue(testDriveContacts != null && testDriveContacts.size() == 1);
        Assert.isTrue(testDriveContacts[0].Role == 'Primary Contact');
    }
    
    static testMethod void wrapperNull_Test() {
        Test.startTest();        
        List<String> result = TemplateService.getDefaultPrimaryDriveContact(null);
        Test.stopTest();
    }
    
    static testMethod void getDefaultPrimaryDriveContactNoBPLDiffStartDate_Test() {
        Test.startTest();
        
        Id testAccountId = [SELECT Id FROM Account WHERE Internal_Name__c = 'TEST ACCOUNT 2' LIMIT 1].Id;
        
        List<Account_Service_Role__c> testServiceRoles = [SELECT Id, Contact__c, Start_Date__c FROM Account_Service_Role__c WHERE Account__c = :testAccountId];
        testServiceRoles[0].Start_Date__c = system.today().addDays(-1);
        update testServiceRoles[0];
        
        TemplateService.TemplateWrapper wrapper = new TemplateService.TemplateWrapper();
        wrapper.accountId = testAccountId;
        
        List<String> result = TemplateService.getDefaultPrimaryDriveContact(new List<TemplateService.TemplateWrapper>{wrapper});
        Test.stopTest();
        
        Assert.isTrue(result[0] == testServiceRoles[0].Contact__c);
    }
}