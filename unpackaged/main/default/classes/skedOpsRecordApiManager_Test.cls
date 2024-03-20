@isTest
private class skedOpsRecordApiManager_Test {
    @isTest
    static void updateStaffRecord_Test() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        Test.startTest();
        skedOpsRecordApiManager apiManager = new skedOpsRecordApiManager();
        skedOpsRecordApiData.opsRecordRequest req = new skedOpsRecordApiData.opsRecordRequest();
        skedOpsRecordApiData.opsRecordResult res = (skedOpsRecordApiData.opsRecordResult) apiManager.updateStaffRecord(req);
        Test.stopTest();
    }
    
    @isTest
    static void updateStaffRecord_Invalid_Test() {
        skedMockTest mockTest = new skedMockTest();
        mockTest.isErrorMode = true;
        mockTest.statusCode = 400;
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        Test.startTest();
        skedOpsRecordApiManager apiManager = new skedOpsRecordApiManager();
        skedOpsRecordApiData.opsRecordRequest req = new skedOpsRecordApiData.opsRecordRequest();
        skedOpsRecordApiData.opsRecordResult res = (skedOpsRecordApiData.opsRecordResult) apiManager.updateStaffRecord(req);
        Test.stopTest();
    }

    @TestSetup
    static void makeData() {
        insert new sked_Admin_Setting__c(
            sked_Ops_Record_API_URL__c = 'https://opsrecordapidev.redcross.org/api/v1/OpsRecord/SubmitOpsRecord',
            sked_Ops_Record_Client_Scer__c = 'test-secret'
        );
    }
    
}