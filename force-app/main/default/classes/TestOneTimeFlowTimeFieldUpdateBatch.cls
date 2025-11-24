@isTest(SeeAllData = false)
private class TestOneTimeFlowTimeFieldUpdateBatch {

    @testSetup
    static void prepateTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert DRD User
        User testDrdUser = (User)mapTestData.get('DRD_USER');
        testDrdUser.Email = 'DRDUser@test.com.invalid';
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
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
    }
    
    @isTest static void testFlowStartTime() {
        Test.startTest();
        
        Opportunity testOpp = [SELECT Id, Flow_End_Time_Field__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        testOpp.Flow_Start_Time_Field__c = null;
        testOpp.Flow_End_Time_Field__c = null;
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update testOpp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        OneTimeFlowTimeFieldUpdateBatch oneTimeFlowTimeFieldUpdateBatch = new oneTimeFlowTimeFieldUpdateBatch();
        Database.executeBatch(oneTimeFlowTimeFieldUpdateBatch);
        
        Test.stopTest();
        Opportunity testUpdatedOpp = [SELECT Id, Flow_End_Time_Field__c FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1];
        Assert.isTrue(testUpdatedOpp.Flow_End_Time_Field__c != null);
        
    }
    
    @isTest static void testOneTimeEmailBatch() {
        Test.startTest();
        
        OneTimeEmailUpdateBatch OneTimeEmailUpdateBatch = new OneTimeEmailUpdateBatch();
        Database.executeBatch(OneTimeEmailUpdateBatch, 1);

        Test.stopTest();
        
        User testUser = [SELECT Id, Email FROM User WHERE Profile.Name = 'DRD Profile' AND Email LIKE 'DRDUser@test%' LIMIT 1];
        Assert.isTrue(String.valueOf(testUser.email).contains('invalid') == false); 
    }
}