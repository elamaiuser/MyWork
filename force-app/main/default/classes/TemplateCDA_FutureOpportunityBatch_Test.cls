@isTest(SeeAllData = false)
private class TemplateCDA_FutureOpportunityBatch_Test {

    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, sObject> mapTestData = testDataSetup.createAndInsertCommonObjects();
        
        //insert mobile account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c = 'TEST INTERNAL NAME 1';
        insert testMobileAccount;
        
        //insert mobile site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        //insert template
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert mobile opp
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
        
        TriggerHandler.clearAllBypasses();
    }
    
    static testMethod void batchWithParametersTest1() {
        Test.startTest();
        
        BSF_TemplateCDA_FutureOpportunity_Batch testBatchInstance = new BSF_TemplateCDA_FutureOpportunity_Batch(true);
        Database.executeBatch(testBatchInstance);
        
        Test.stopTest();
        
        Opportunity testMobileOpp = [SELECT Parent_Template_Id__r.Anticipated_Registered_Donors__c, Anticipated_Registered_Donors_Template__c FROM Opportunity LIMIT 1];
        Assert.isTrue(testMobileOpp.Anticipated_Registered_Donors_Template__c == testMobileOpp.Parent_Template_Id__r.Anticipated_Registered_Donors__c);
    }
    
    static testMethod void batchWithParametersTest2() {
        Test.startTest();
        
        BSF_TemplateCDA_FutureOpportunity_Batch testBatchInstance = new BSF_TemplateCDA_FutureOpportunity_Batch('Test', false);
        Database.executeBatch(testBatchInstance);
        
        Test.stopTest();
        Opportunity testMobileOpp = [SELECT Parent_Template_Id__r.X2RBC_Projected_Procedures__c, Double_Red_Procedures_Projected_Template__c FROM Opportunity LIMIT 1];
        Assert.isTrue(testMobileOpp.Double_Red_Procedures_Projected_Template__c == testMobileOpp.Parent_Template_Id__r.X2RBC_Projected_Procedures__c);
    }
    
    static testMethod void batchScheduleTest() {
        Test.startTest();
        system.schedule('Test Template CDA Batch', '0 0 0 * * ?', new BSF_TemplateCDA_FutureOpportunity_Batch(false));
        Test.stopTest();
    }
}