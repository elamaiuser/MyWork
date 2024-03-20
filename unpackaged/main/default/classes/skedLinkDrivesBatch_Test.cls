@isTest
private class skedLinkDrivesBatch_Test {
    @isTest 
    static void skedLinkDrivesBatch_Test() {
        sked_Drive__c testDrive = [SELECT Id FROM sked_Drive__c LIMIT 1][0];

        Test.startTest();
            Database.executeBatch(new skedLinkDrivesBatch(new Set<Id>{testDrive.Id}));
        Test.stopTest();
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        mapTestData = testDataFactory.setupDriveData();
    }
}