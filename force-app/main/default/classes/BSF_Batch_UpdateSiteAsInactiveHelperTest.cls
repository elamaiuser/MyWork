@isTest(seeAllData = false)
private class BSF_Batch_UpdateSiteAsInactiveHelperTest {
    
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
         // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_End_Date__c = system.today();
        insert testMobileSite;
    }
    
    static testMethod void testBatchUpdateSiteAsInactive() {
        Test.startTest();
        BSF_Batch_UpdateSiteAsInactiveHelper batchJob = new BSF_Batch_UpdateSiteAsInactiveHelper();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        sked__Location__c updatedSite = [SELECT Id, sked_Active__c FROM sked__Location__c LIMIT 1];
        Assert.isTrue(updatedSite.sked_Active__c == false); // site has been made inactive as the end date is reached
    }
    
    static testMethod void testScheduleBatch() {
        Test.startTest();
        system.schedule('Test Sched Batch', '0 0 0 ? * *', new BSF_Batch_UpdateSiteAsInactiveHelper());
        Test.stopTest();
        Assert.isTrue([SELECT count() FROM CronTrigger WHERE CronJobDetail.Name = 'Test Sched Batch' AND CronJobDetail.JobType = '7'] == 1);
    }
}