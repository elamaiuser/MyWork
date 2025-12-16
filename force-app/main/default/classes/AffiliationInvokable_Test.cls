@isTest
private class AffiliationInvokable_Test {
    
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
        
        //insert Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        insert testMobileAccount;
        
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
        Marketing_Program__c aff = new Marketing_Program__c(
        	Name = 'Test',
        	External_Name__c = 'TEST',
        	Scope__c = 'Drive',
        	End_Date__c = system.today().addDays(3)
        );
        insert aff;
        
        //insert drive affiliation
        Drive_Marketing_Programs__c driveAff = new Drive_Marketing_Programs__c(
        	Marketing_Program__c = aff.Id,
        	Blood_Drive_Opportunity__c = testMobileOpp.Id
        );
        insert driveAff;
    }
    
    @isTest static void testAccountInvoke() {
        Test.startTest();
        List<List<Drive_Marketing_Programs__c>> testResults = AffiliationInvokable.deleteDriveAffiliationOnBookingDateChange(new List<Id>{[SELECT Id FROM Marketing_Program__c LIMIT 1].Id});
        Test.stopTest();
        
        Assert.isTrue(!testResults.isEmpty());
    }
}