/* The following test class covers below mentioned apex class(es):
 * BSF_Batch_RemoveDriveSpecialAffiliations (100%)
 * DriveMarketingProgramTriggerService (85%)
*/

@isTest(SeeAllData = false)
private class BSF_Batch_RemoveSpecialAffiliations_Test {
    
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        // insert Mobile Opp
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
        
        //insert Affiliations
        Marketing_Program__c testAffiliation = (Marketing_Program__c)mapTestData.get('AFFILIATION');
        insert testAffiliation;
        
        //insert Drive Affiliations
        Drive_Marketing_Programs__c testDriveAffiliation = new Drive_Marketing_Programs__c(
            Blood_Drive_Opportunity__c = testMobileOpp.Id,
            Marketing_Program__c = testAffiliation.Id
        );
        insert testDriveAffiliation;
        
        TriggerHandler.clearAllBypasses();
    }
    
    static testMethod void test_batchLogic() {
        Test.startTest();
        
        TriggerHandler.bypass('DriveMarketingProgramTriggerHandler');
        Drive_Marketing_Programs__c testDriveAffiliation = [SELECT Id, Date_Removed__c FROM Drive_Marketing_Programs__c LIMIT 1];
        testDriveAffiliation.Date_Removed__c = system.today();
        update testDriveAffiliation;
        TriggerHandler.clearAllBypasses();
        
        Database.executeBatch(new BSF_Batch_RemoveDriveSpecialAffiliations(), 200);
        
        Test.stopTest();
        
        Opportunity testOpportunity = [SELECT Id, Special_Affiliations__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        Assert.isTrue(String.isBlank(testOpportunity.Special_Affiliations__c));
    }
	
    static testMethod void test_batchScheduleLogic() {
        Test.startTest();
        
        BSF_Batch_RemoveDriveSpecialAffiliations batchInstance = new BSF_Batch_RemoveDriveSpecialAffiliations();
        String chron = '0 0 0 * * ?';        
        system.schedule('Test Sched', chron, batchInstance);
        
        Test.stopTest();
        
        Assert.isTrue([SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name = 'Test Sched'].size() == 1);
    }
}