@isTest
private class skedCreateNonUserChangeDCRBatch_Test {
    static testmethod void testCreateNonUserChangeDCRBatch() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_RTD_Change_DCR_Required__c = true;
        update testDrive;
        skedCreateNonUserChangeDCRBatch.schedule();
        Test.stopTest();
    }
}