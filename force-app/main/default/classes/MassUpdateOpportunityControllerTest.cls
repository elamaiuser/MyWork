@isTest 
private class MassUpdateOpportunityControllerTest {
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        
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
    }
    
    static testMethod void massUpdateOpptyCtrlrTestMethod() {
        Test.startTest();
        
        List<Opportunity> oppList = [SELECT Id FROM Opportunity];
		PageReference testPage = Page.MassUpdateOpportunityPage; 
       	Test.setCurrentPage(testPage);
       	testPage.getParameters().put('accountId', [SELECT Id FROM Account LIMIT 1].Id);
       
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(oppList);
        stdSetController.setSelected(oppList);
        MassUpdateOpportunityController ext = new MassUpdateOpportunityController(stdSetController);
        
        Test.stopTest();
        Assert.isTrue(ext.opps != null && !String.isBlank(ext.opps));
        
    }
}