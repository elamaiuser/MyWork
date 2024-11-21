@isTest
private class skedCreateDCRForRTDBatch_Test {
    @isTest
    static void skedCreateDCRForRTDBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        sked_Role_Time_Detail__c testRtd = new sked_Role_Time_Detail__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Effective_End_Date__c = System.today().addDays(10),
            sked_Breakdown_Time__c = 25,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Drive_Type__c = testDrive.sked_Type_of_Drive__c,
            sked_Lead_Time__c = 15,
            sked_Setup_Time__c = 15,
            sked_Wrap_up_Time__c = 15,
            sked_Mobile_Type__c = 'Inside/Outside',
            sked_Resource_Role_Group__c = 'Driving roles;Supervisory roles;Staff roles'
        );

        insert testRtd;

        Test.startTest();
            Database.executeBatch(new skedCreateDCRForRTDBatch(new List<sked_Role_Time_Detail__c>{testRtd}), 1);
        Test.stopTest();

        Integer testDCRCount = [SELECT COUNT() FROM sked_Drive__c WHERE sked_RTD_Change_DCR_Required__c = TRUE];
        System.assertEquals(1, testDCRCount);
    }

    @isTest
    static void skedCreateDCRForRTDBatch_NoWeekdaysSelected_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        sked_Role_Time_Detail__c testRtd = new sked_Role_Time_Detail__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Effective_End_Date__c = System.today().addDays(10),
            sked_Breakdown_Time__c = 25,
            sked_Days_of_Week__c = '',
            sked_Drive_Type__c = testDrive.sked_Type_of_Drive__c,
            sked_Lead_Time__c = 15,
            sked_Setup_Time__c = 15,
            sked_Wrap_up_Time__c = 15,
            sked_Mobile_Type__c = 'Inside/Outside',
            sked_Resource_Role_Group__c = 'Driving roles;Supervisory roles;Staff roles'
        );

        insert testRtd;

        Test.startTest();
            Database.executeBatch(new skedCreateDCRForRTDBatch(new List<sked_Role_Time_Detail__c>{testRtd}), 1);
        Test.stopTest();

        Integer testDCRCount = [SELECT COUNT() FROM sked_Drive__c WHERE sked_RTD_Change_DCR_Required__c = TRUE];
        System.assertEquals(0, testDCRCount);
    }

    @isTest
    static void skedCreateDCRForRTDBatch_FixedSiteWD_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_Type_Of_Drive__c = 'Fixed Site';
        update testDrive;

        sked_Role_Time_Detail__c testRtd = new sked_Role_Time_Detail__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Effective_End_Date__c = System.today().addDays(10),
            sked_Breakdown_Time__c = 25,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Drive_Type__c = 'Fixed Site',
            sked_Lead_Time__c = 15,
            sked_Setup_Time__c = 15,
            sked_Wrap_up_Time__c = 15,
            sked_Fixed_Site_Operation_Type__c = 'Non Integrated WB',
            sked_Mobile_Type__c = 'Inside',
            sked_Resource_Role_Group__c = 'Driving roles;Supervisory roles;Staff roles'
        );

        insert testRtd;
        Database.executeBatch(new skedCreateDCRForRTDBatch(new List<sked_Role_Time_Detail__c>{testRtd}), 1);
        Test.stopTest();

        Integer testDCRCount = [SELECT COUNT() FROM sked_Drive__c WHERE sked_RTD_Change_DCR_Required__c = TRUE];
        System.assertEquals(0, testDCRCount);
    }

    @isTest
    static void skedCreateDCRForRTDBatch_Test_NoDuplicateDCR() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        sked_Role_Time_Detail__c testRtd = new sked_Role_Time_Detail__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Effective_End_Date__c = System.today().addDays(10),
            sked_Breakdown_Time__c = 25,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Drive_Type__c = testDrive.sked_Type_of_Drive__c,
            sked_Lead_Time__c = 15,
            sked_Setup_Time__c = 15,
            sked_Wrap_up_Time__c = 15,
            sked_Mobile_Type__c = 'Inside/Outside',
            sked_Resource_Role_Group__c = 'Driving roles;Supervisory roles;Staff roles'
        );
        insert testRtd;

        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = testDrive.Id,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTD_CHANGE,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING
        );
        insert testDcr;
        sked_Drive_Change_Request_Item__c testDcri = new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = testDcr.Id,
            sked_Object_API_Name__c = 'sked_Drive__c',
            sked_Field_API_Name__c = 'sked_Role_Time_Detail_Changed__c',
            sked_Field_Label__c = 'Role Time Detail Changed',
            sked_Field_Type__c = 'Boolean',
            sked_Type__c = 'Change'
        );
        insert testDcri;

        Test.startTest();
            Database.executeBatch(new skedCreateDCRForRTDBatch(new List<sked_Role_Time_Detail__c>{testRtd}), 1);
        Test.stopTest();

        Integer testDCRCount = [SELECT COUNT() FROM sked_Drive__c WHERE sked_RTD_Change_DCR_Required__c = TRUE];
        System.assertEquals(1, testDCRCount);
    }
}