@isTest
private class skedOppDriveSyncBatch_Test {
    @testSetup
    static void prepareTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
    }
    
    @isTest
    static void skedOppDriveSyncBatch_Test() {
        Test.startTest();
        
        Integer testDrivesCount = [SELECT count() FROM sked_Drive__c];
        List<String> toAddresses = new List<String>{'test@testing.com'};
        Id jobId = Database.executeBatch(new skedOppDriveSyncBatch(toAddresses), testDrivesCount);
        
        Test.stopTest();
        Assert.isTrue(jobId != null);
    }
}