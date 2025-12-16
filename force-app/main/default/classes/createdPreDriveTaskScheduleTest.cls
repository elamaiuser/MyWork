@isTest
private class createdPreDriveTaskScheduleTest {
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
     
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;
        
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.Id;
        insert testContact;
        
        testMobileAccount.Contact_BPL__c = testContact.Id;
        update testMobileAccount;
        
       	sked__Location__c testLocation = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testLocation.Sponsor_Security_Form_Required__c = 'Pre-Drive';
        testLocation.sked_Pre_Drive_Security_Due_Date__c='14';
        insert testLocation;
        
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testLocation.Id;
        testMobileOpp.Drive_Date__c = System.Today().addDays(4);
        insert testMobileOpp;
    }
    
    static testMethod void testBatch() {
        Test.startTest();
        
        Opportunity testMobileOpp = [SELECT Id, StageName FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        testMobileOpp.StageName = 'Closed';
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;
        update testMobileOpp;
 
        createdPreDriveTaskSchedule b = new createdPreDriveTaskSchedule();
        string sch = '0 0 2 * * ?';
        System.Schedule('TEST',sch,b);
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        Assert.isTrue([SELECT count() FROM CronTrigger WHERE CronJobDetail.Name = 'TEST' AND CronJobDetail.JobType = '7'] == 1);
    }
}