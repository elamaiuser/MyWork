@isTest
private class skedOppDriveSyncBatch_Test {
    @isTest
    static void skedOppDriveSyncBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Opportunity testOpp = (Opportunity) mapTestData.get('testOpportunity');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        Test.startTest();
        List<String> toAddresses = new List<String>{'test@testing.com'};
        Database.executeBatch(new skedOppDriveSyncBatch(toAddresses), 1);
        Test.stopTest();
    }
}