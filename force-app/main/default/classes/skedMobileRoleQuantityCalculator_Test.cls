@isTest
private class skedMobileRoleQuantityCalculator_Test {

    private static sked_Drive__c queryDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Projected_Registered_Donors__c,
                sked_APT_Quantity__c, sked_Travel_Time_Included__c, sked_Account__r.Type, sked_Account__r.Industry_Code__c,
                sked_Account__r.Accepts_Automation2__c,
                sked_Do_Not_Use_Vehicle__c, sked_Number_of_Vehicles__c, sked_Total_Vehicle_Requested__c, sked_Number_of_2RBC_Assets__c, sked_IMPACT__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    private static sked_Drive__c setupSingleShiftDrive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Maximum_Shift_Length_Threshold__c = 700;
        collectionOperation.sked_No_Travel_Time__c = false;
        collectionOperation.sked_Lunch_Break__c = false;
        update collectionOperation;

        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_2RBC_Projected_Procedures__c = 30;
        testDrive1.sked_WB_Projected_Procedures__c = 20;
        testDrive1.sked_Do_Not_Use_Vehicle__c = false;
        testDrive1.sked_Number_of_Vehicles__c = 2;
        testDrive1.sked_Number_of_2RBC_Assets__c = 4;
        update testDrive1;

        return queryDrive(testDrive1.Id);
    }

    private static Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> calculateForSingleShift(sked_Drive__c drive) {
        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);
        System.assertEquals(1, shiftsMetadata.numberOfDriveShifts, 'Test setup must produce exactly one shift so per-shift math is directly verifiable by hand');

        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> byShiftKey = skedMobileRoleQuantityCalculator.calculateRoleQuantities(
            drive, shiftsMetadata, sdm, shiftMasterData.driveSite.sked_Physical_Location_Type__c, shiftMasterData.timezoneSidId);

        return byShiftKey.get(shiftsMetadata.driveShifts[0].key);
    }

    @isTest
    static void testLoadStaffingDecisionMatrix_returnsMobileRecordTypeMatrix() {
        sked_Drive__c drive = setupSingleShiftDrive();

        Test.startTest();
        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        Test.stopTest();

        System.assertNotEquals(null, sdm, 'A Mobile-record-type Staffing Decision Matrix effective on the drive date must be found');
        System.assertEquals(2.2, sdm.sked_Driver_Capacity__c, 'The matched matrix must be the seeded Mobile matrix, not the Fixed Site one');
    }

    @isTest
    static void testCalculateRoleQuantities_singleShift_computesAllRoleQuantitiesConsistentWithHandCalculation() {
        sked_Drive__c drive = setupSingleShiftDrive();

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = calculateForSingleShift(drive);
        Test.stopTest();

        System.assertEquals(2, roleQuantities.get('Driver').quantity, 'Driver quantity must equal the drive\'s configured number of vehicles');
        System.assertEquals(2, roleQuantities.get('Driver Support').quantity, 'Driver Support quantity must mirror Driver quantity when the matrix\'s driverSupportCapacity is positive');
        System.assertEquals(2, roleQuantities.get('2RBC').quantity, '2RBC staff quantity must be ceil(numberOf2rbcAssets / 2) = ceil(4/2) = 2');
        System.assertEquals(1, roleQuantities.get('Team Supervisor').quantity, 'Team Supervisor must be 1: totalProceduresProjected (50) exceeds the 36 threshold on an Inside site');
        System.assertEquals(0, roleQuantities.get('Charge').quantity, 'With staffCapacity (128) exceeding donors (100), no VP/HH and thus no Charge leaders are needed');

        skedMobileRoleQuantityCalculator.RoleQuantity vpHh = roleQuantities.get('VP/HH');
        System.assertEquals(0, vpHh.vphhQuantity, 'Driver/Driver Support/2RBC staff capacity (128) alone already exceeds the 100 scheduled donors, so no additional VP/HH staff are needed');
        System.assertEquals(1, vpHh.aptQuantity, 'APT quantity must be floor(50/40) = 1 for this High School Education account at 50 total procedures');
        System.assertEquals(1, vpHh.quantity, 'VP/HH total quantity must be vphhQuantity (0) + aptQuantity (1)');
    }

    @isTest
    static void testCalculateRoleQuantities_doNotUseVehicle_zerosOutDriverAndDriverSupport() {
        sked_Drive__c testDrive1 = setupSingleShiftDrive();
        testDrive1.sked_Do_Not_Use_Vehicle__c = true;
        update testDrive1;
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = calculateForSingleShift(drive);
        Test.stopTest();

        System.assertEquals(0, roleQuantities.get('Driver').quantity, 'Do Not Use Vehicle must force vehicle (and therefore Driver) quantity to zero');
        System.assertEquals(0, roleQuantities.get('Driver Support').quantity, 'Driver Support must mirror the zeroed Driver quantity, not fall back to the minimum-of-1 rule');
    }

    @isTest
    static void testCalculateRoleQuantities_noVehiclesConfigured_defaultsDriverQuantityToOne() {
        sked_Drive__c testDrive1 = setupSingleShiftDrive();
        testDrive1.sked_Number_of_Vehicles__c = null;
        update testDrive1;
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = calculateForSingleShift(drive);
        Test.stopTest();

        System.assertEquals(1, roleQuantities.get('Driver').quantity, 'With Do Not Use Vehicle false and zero vehicles requested, Driver quantity must default to the minimum of 1');
    }
}
