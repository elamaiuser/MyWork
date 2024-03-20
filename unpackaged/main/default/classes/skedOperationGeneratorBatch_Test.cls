@isTest
private class skedOperationGeneratorBatch_Test {
    @isTest
    static void skedOperationGeneratorBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
    
        Test.startTest();
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_Drive_Date__c = System.today().addDays(30);
        update testDrive;
        Database.executeBatch(new skedOperationGeneratorBatch());
        Test.stopTest();
    }
}