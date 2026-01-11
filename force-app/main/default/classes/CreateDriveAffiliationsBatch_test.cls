@isTest
private class CreateDriveAffiliationsBatch_test {
    
   	@testSetup
    static void prepareTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert DRD User
        User testDrdUser = (User)mapTestData.get('DRD_USER');
        User testDrdDmUser = (User)mapTestData.get('DRD_MANAGER_USER');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new List<User>{testDrdUser, testDrdDmUser};
        }
        
 	   	//insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        testMobileAccount.Phone = '1234567890' ;
        testMobileAccount.Type = 'Business';
        testMobileAccount.Account_Manager__c = testDrdUser.Id;
        insert testMobileAccount;
        
        //insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.Id ;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert mobile opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
        
        //insert affiliation
        Marketing_Program__c testAffiliation = (Marketing_Program__c)mapTestData.get('AFFILIATION');
        testAffiliation.Start_Date__c = system.today();
        insert testAffiliation;
        
        //insert drive affiliation
        Drive_Marketing_Programs__c testDriveAffiliation = new Drive_Marketing_Programs__c(
            Migration_ID__c = null, //empty migration Id
            Blood_Drive_Opportunity__c = testTemplate.Id,
            Account__c = testMobileAccount.Id,
            Marketing_Program__c = testAffiliation.Id
        );
        insert testDriveAffiliation;
    }
 
    @isTest static void test_createDriveAffiliation() {
        Test.startTest();
        
        Opportunity testOpp = [SELECT Id, Parent_Template_Id__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        Set<ID> templateIdSet = new Set<Id>{testOpp.Parent_Template_Id__c};
        Map<Id,Opportunity> newOppMap = new Map<Id,Opportunity>{testOpp.Id => testOpp};
        
        Database.executeBatch(new CreateDriveAffiliationsBatch(templateIdSet, newOppMap));  
        Test.stopTest(); 
    }
}