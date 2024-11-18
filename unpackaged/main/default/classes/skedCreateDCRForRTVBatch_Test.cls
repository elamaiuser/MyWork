@isTest
private class skedCreateDCRForRTVBatch_Test {
    @isTest
    static void skedCreateDCRForRTVBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        sked__Location__c testSite = (sked__Location__c) mapTestData.get('testLocation1');

        sked_Role_Time_Variance__c testRtv = new sked_Role_Time_Variance__c(
            sked_Variation_Amount__c = 15,
            sked_Variation_Type__c = 'Safety Video',
            sked_Variance_Applies_To__c = 'Lead Time',
            sked_Buffer_Type__c = 'Add',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Effective_End_Date__c = System.today().addDays(10),
            sked_Location__c = testSite.Id,
            sked_Resource_Role_Group__c = 'Driving roles'
        );

        insert testRtv;
        Database.executeBatch(new skedCreateDCRForRTVBatch(new List<sked_Role_Time_Variance__c>{testRtv}), 1);
        Test.stopTest();
    }

    @isTest
    static void skedCreateDCRForRTVBatch_Test_NoDuplicateDCR() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testSite = (sked__Location__c) mapTestData.get('testLocation1');

        sked_Role_Time_Variance__c testRtv = new sked_Role_Time_Variance__c(
            sked_Variation_Amount__c = 15,
            sked_Variation_Type__c = 'Safety Video',
            sked_Variance_Applies_To__c = 'Lead Time',
            sked_Buffer_Type__c = 'Add',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Effective_End_Date__c = System.today().addDays(10),
            sked_Location__c = testSite.Id,
            sked_Resource_Role_Group__c = 'Driving roles'
        );

        insert testRtv;

        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = testDrive.Id,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTV_CHANGE,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING
        );
        insert testDcr;
        sked_Drive_Change_Request_Item__c testDcri = new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = testDcr.Id,
            sked_Object_API_Name__c = 'sked_Drive__c',
            sked_Field_API_Name__c = 'sked_Role_Time_Variance_Changed__c',
            sked_Field_Label__c = 'Role Time Variance Changed',
            sked_Field_Type__c = 'Boolean',
            sked_Type__c = 'Change'
        );
        insert testDcri;
        Database.executeBatch(new skedCreateDCRForRTVBatch(new List<sked_Role_Time_Variance__c>{testRtv}), 1);
        Test.stopTest();
    }
}