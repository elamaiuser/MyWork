@isTest
private class skedOperationGeneratorBatch_Test {
    @isTest
    static void skedOperationGeneratorBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
    
        Test.startTest();
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        Database.executeBatch(new skedOperationGeneratorBatch());
        new skedOperationGeneratorBatch().execute(null, new List<sked_Drive__c>{testDrive});
        Test.stopTest();
    }

    static testmethod void testCaptureDebugLog() {
        try {
            throw new skedException('test');
        } catch (Exception e) {
            new skedOperationGeneratorBatch().captureDebugLog(e);
        }
    }
}