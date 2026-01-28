/* The following test class is covering the below mentioned batch class
 * UpdateOpportunityNameBatch
 * */

@isTest(seeAllData = false)
private class UpdateOpportunityNameBatchTest {
    
    @testSetup
    static void prepareDataSetup() {   
        
    	BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
    	Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
    
    	// insert mobile account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
    
    	// insert mobile site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        //insert template
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.accountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
    }
    
    static testMethod void updateOppNameTest_templates() {
        Account testMobileAccount = [SELECT Id, Name from Account WHERE Internal_Name__c = 'TEST ACCOUNT 1' LIMIT 1];
        
        TriggerHandler.bypass('AccountTriggerHandler');
        testMobileAccount.Internal_Name__c = 'TEST UPDATED ACCOUNT 1';
        update testMobileAccount;
        TriggerHandler.clearBypass('AccountTriggerHandler');
        
        Test.startTest();
        
        List<Opportunity> testOppTemplateList = [
            SELECT Id, Name, Drive_Name__c,
            Is_Template__c, accountId,
            Drive_Site__c, Drive_Site_Name__c,
            Account_Internal_Name__c,
            Site_Building_Name__c,
            Template_Status__c, Additional_Description__c
            FROM Opportunity
            WHERE AccountId = :testMobileAccount.Id
            AND Is_Template__c = true];
                
        UpdateOpportunityNameBatch testBatchInstance = new UpdateOpportunityNameBatch(testOppTemplateList, true, true);
        Database.executeBatch(testBatchInstance);
                        
        Test.stopTest();
        
        Assert.isTrue([SELECT Id, Name FROM Opportunity WHERE Id = :testOppTemplateList[0].Id limit 1].Name.contains('TEST UPDATED ACCOUNT 1'));
    }
}