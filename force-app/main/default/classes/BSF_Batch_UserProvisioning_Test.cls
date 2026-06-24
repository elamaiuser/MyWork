@isTest
private class BSF_Batch_UserProvisioning_Test {
    
    @testSetup
    static void setupTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Set<String> activeProfileNames = userService.getActiveMdtProfileNames();
        List<String> myList = new List<String>(activeProfileNames);
        Profile p1 = [SELECT Id FROM Profile WHERE Name =:myList.get(0) LIMIT 1];
        User amUser = new User(Alias = 'amusr', 
                                Email='amuser@testtest.com', 
                                EmailEncodingKey='UTF-8', 
                                LastName='TestingAM', 
                                LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', 
                                ProfileId = p1.Id, 
                                TimeZoneSidKey='America/Los_Angeles', 
                                UserName='amuser' + DateTime.now().getTime() + '@testtest.com');
        triggerHandler.bypass('UserTriggerHandler');
        insert amUser;
        triggerHandler.Clearbypass('UserTriggerHandler');
    }
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        BSF_Batch_UserProvisioning batch = new BSF_Batch_UserProvisioning();
        Id batchJobId = Database.executeBatch(batch, 200);
        Test.stopTest(); 
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :batchJobId];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully.');
        System.assertEquals(0, job.NumberOfErrors, 'Batch should have zero errors.');
    }
    
    @isTest
    static void testBatchScheduling() {
        String cronExp = '0 0 2 * * ?'; 
        
        Test.startTest();
        String jobId = System.schedule(
            'Test Nightly Provisioning Sync', 
            cronExp, 
            new BSF_Batch_UserProvisioning()
        );
        Test.stopTest();
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match the schedule.');
        System.assertEquals(0, ct.TimesTriggered, 'Job should be queued but not triggered yet.');
    }
}