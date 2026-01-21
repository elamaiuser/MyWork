@isTest
private class BSF_BatchUpdateAccountForZipCodeTest {
    
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        Collections_Territory__c testCollectionsTerritory1 = new Collections_Territory__c(
            Zip__c = '40471',
            Name = 'Test Collections',
            sked_Start_Date__c = system.today(),
            sked_End_Date__c = system.today()
        );
        
        Collections_Territory__c testCollectionsTerritory2 = new Collections_Territory__c(
            Zip__c = '40471',
            Name = 'Test Collections 2',
            sked_Start_Date__c = system.today().addDays(-10),
            sked_End_Date__c = system.today().addDays(2)
        );
        insert new List<Collections_Territory__c>{testCollectionsTerritory1, testCollectionsTerritory2};
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        testMobileAccount.BillingPostalCode = '40471';
        testMobileAccount.Collections_Territory__c = testCollectionsTerritory2.Id;
        insert testMobileAccount;
    }
    
    static testMethod void Test_Schedule_Class() {
        Test.StartTest();
		BSF_BatchUpdateAccountSchedule testsche = new BSF_BatchUpdateAccountSchedule(200);
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
		Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class');
    }
    
    static testMethod void testMethod1() {  
        Test.startTest();
        BSF_BatchUpdateAccountForZipCode batchInstance = new BSF_BatchUpdateAccountForZipCode();
        Database.executeBatch(batchInstance);
        Test.stopTest();
        
        Account testUpdatedMobileAccount = [SELECT Id, Collections_Territory__c FROM Account WHERE Internal_Name__c = 'TEST Account 1' LIMIT 1];
        Assert.isTrue(testUpdatedMobileAccount.Collections_Territory__c != null);
    }
    
    static testMethod void testMethod2() {        
        Test.startTest();
        BSF_BatchUpdateAccountForZipCode batchInstance = new BSF_BatchUpdateAccountForZipCode(true);
        Database.executeBatch(batchInstance);
        Test.stopTest();
        
        Account testUpdatedMobileAccount = [SELECT Id, Collections_Territory__c FROM Account WHERE Internal_Name__c = 'TEST Account 1' LIMIT 1];
        Assert.isTrue(testUpdatedMobileAccount.Collections_Territory__c != null);
    }
}