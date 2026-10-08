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

    static testmethod void testCreatesVehicleRequirementChangeDCRAndClearsFlag() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        testDataFactory.setupCommonTestData();
        Map<string, sObject> mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_Vehicle_Req_Change_DCR_Required__c = true;
        update testDrive;

        Test.startTest();
        Database.executeBatch(new skedCreateNonUserChangeDCRBatch(), 200);
        Test.stopTest();

        List<sked_Drive_Change_Request__c> dcrs = [
            SELECT Id, sked_Type__c
            FROM sked_Drive_Change_Request__c
            WHERE sked_Drive__c = :testDrive.Id
        ];
        System.assertEquals(1, dcrs.size(), 'Exactly one DCR should be created for the flagged drive');
        System.assertEquals(true, dcrs[0].sked_Type__c.contains(skedConstants.DRIVE_CHANGE_REQUEST_TYPE_VEHICLE_REQUIREMENT_CHANGE),
            'The DCR type should include Vehicle Requirement Change');
    }

    static testmethod void testClearsVehicleRequirementFlagAfterDCRCreation() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        testDataFactory.setupCommonTestData();
        Map<string, sObject> mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_Vehicle_Req_Change_DCR_Required__c = true;
        update testDrive;

        Test.startTest();
        Database.executeBatch(new skedCreateNonUserChangeDCRBatch(), 200);
        Test.stopTest();

        sked_Drive__c updatedDrive = [
            SELECT Id, sked_Vehicle_Req_Change_DCR_Required__c
            FROM sked_Drive__c
            WHERE Id = :testDrive.Id
        ];
        System.assertEquals(false, updatedDrive.sked_Vehicle_Req_Change_DCR_Required__c,
            'The pipeline flag should be cleared once the DCR has been created');
    }

    static testmethod void testCreatesNoVehicleRequirementDCRWhenFlagIsNotSet() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        testDataFactory.setupCommonTestData();
        Map<string, sObject> mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_RTD_Change_DCR_Required__c = true;
        update testDrive;

        Test.startTest();
        Database.executeBatch(new skedCreateNonUserChangeDCRBatch(), 200);
        Test.stopTest();

        List<sked_Drive_Change_Request__c> dcrs = [
            SELECT Id, sked_Type__c
            FROM sked_Drive_Change_Request__c
            WHERE sked_Drive__c = :testDrive.Id
        ];
        System.assertEquals(false, dcrs[0].sked_Type__c.contains(skedConstants.DRIVE_CHANGE_REQUEST_TYPE_VEHICLE_REQUIREMENT_CHANGE),
            'A drive flagged only for an RTD change must not pick up a Vehicle Requirement Change type');
    }

    static testmethod void testCreatesSdmChangeDCRAndClearsFlag() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        testDataFactory.setupCommonTestData();
        Map<string, sObject> mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_SDM_Change_DCR_Required__c = true;
        update testDrive;

        Test.startTest();
        Database.executeBatch(new skedCreateNonUserChangeDCRBatch(), 200);
        Test.stopTest();

        List<sked_Drive_Change_Request__c> dcrs = [
            SELECT Id, sked_Type__c
            FROM sked_Drive_Change_Request__c
            WHERE sked_Drive__c = :testDrive.Id
        ];
        System.assertEquals(true, dcrs[0].sked_Type__c.contains(skedConstants.DRIVE_CHANGE_REQUEST_TYPE_SDM_CHANGE),
            'The DCR type should include SDM Change');
    }

    static testmethod void testClearsSdmChangeFlagAfterDCRCreation() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        testDataFactory.setupCommonTestData();
        Map<string, sObject> mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_SDM_Change_DCR_Required__c = true;
        update testDrive;

        Test.startTest();
        Database.executeBatch(new skedCreateNonUserChangeDCRBatch(), 200);
        Test.stopTest();

        sked_Drive__c updatedDrive = [
            SELECT Id, sked_SDM_Change_DCR_Required__c
            FROM sked_Drive__c
            WHERE Id = :testDrive.Id
        ];
        System.assertEquals(false, updatedDrive.sked_SDM_Change_DCR_Required__c,
            'The pipeline flag should be cleared once the DCR has been created');
    }

    static testmethod void testCreatesSdmChangeDCRItemWithMarkerFieldApiName() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        testDataFactory.setupCommonTestData();
        Map<string, sObject> mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_SDM_Change_DCR_Required__c = true;
        update testDrive;

        Test.startTest();
        Database.executeBatch(new skedCreateNonUserChangeDCRBatch(), 200);
        Test.stopTest();

        List<sked_Drive_Change_Request_Item__c> items = [
            SELECT sked_Field_API_Name__c
            FROM sked_Drive_Change_Request_Item__c
            WHERE sked_Drive_Change_Request__r.sked_Drive__c = :testDrive.Id
        ];
        System.assertEquals('sked_SDM_Changed__c', items[0].sked_Field_API_Name__c,
            'The DCR item must carry the marker api name the drive generator keys its sdmChanged token off');
    }
}