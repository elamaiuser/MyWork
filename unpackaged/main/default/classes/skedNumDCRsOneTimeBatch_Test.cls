@isTest
private class skedNumDCRsOneTimeBatch_Test {
    @isTest
    static void skedNumDCRsOneTimeBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        skedHubBase.BypassInsertTriggers = true;
        sked_Drive_Change_Request__c testDriveChangeRequest = new sked_Drive_Change_Request__c(
            sked_Drive__c = testDrive.Id,
            sked_Status__c = 'Pending'
        );
        insert testDriveChangeRequest;
        skedHubBase.BypassInsertTriggers = false;

        Test.startTest();
            Database.executeBatch(new skedNumDCRsOneTimeBatch());
        Test.stopTest();

        testDrive = [SELECT Id, sked_Num_Of_Pending_DCRs__c FROM sked_Drive__c WHERE Id = :testDrive.Id];
        System.assertNotEquals(0, testDrive.sked_Num_Of_Pending_DCRs__c);
    }
}