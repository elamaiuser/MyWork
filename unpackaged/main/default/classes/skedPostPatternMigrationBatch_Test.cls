@isTest
private class skedPostPatternMigrationBatch_Test {
    @isTest
    static void skedPostPatternMigrationBatch_Test() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        sked__Availability_Pattern__c testAvailabilityPattern = [SELECT Id FROM sked__Availability_Pattern__c LIMIT 1][0];
        testAvailabilityPattern.sked_MigrationID__c = 'test-migration-id';
        testAvailabilityPattern.sked_Post_Migration_Processed__c = false;
        testAvailabilityPattern.sked__Hash__c = 'weeklyPatternHash';
        update testAvailabilityPattern;

        Test.startTest();
            Database.executeBatch(new skedPostPatternMigrationBatch());
        Test.stopTest();

        testAvailabilityPattern = [SELECT Id, sked_Post_Migration_Processed__c FROM sked__Availability_Pattern__c WHERE Id = :testAvailabilityPattern.Id];
        System.assert(testAvailabilityPattern.sked_Post_Migration_Processed__c);

    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }
}