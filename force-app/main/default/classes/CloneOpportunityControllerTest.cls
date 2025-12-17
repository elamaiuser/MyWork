@isTest
private class CloneOpportunityControllerTest {
   	@testSetup
    static void prepareTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
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
    
    @isTest
    static void getOpportunityLineItems_test() {
        Test.startTest();
        
        Opportunity opp = [SELECT StageName, Is_Template__c, CloseDate, AccountId FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        try{
        	String clonedOppRes = CloneOpportunityController.cloneOpportunityFields(opp.Id, JSON.serialize(opp), true);
            Assert.isTrue(!String.isBlank(clonedOppRes));
        } catch(Exception e) {
            CloneOpportunityController.throwException('Error Occured During Execution');
        }
        
        Opportunity activeOppRes = CloneOpportunityController.activeOpportunity(opp.Id); 
        Assert.isTrue(activeOppRes != null);
      
        Test.stopTest();
    }
}