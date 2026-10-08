@isTest
private class skedFixedSiteRoleQuantityCalculator_Test {

    // See reference_fixed_site_test_fixture_gotchas.md - testDrive2/testLocation2 default to WB.
    private static sked_Drive__c setOperationTypeAndQuery(sked_Drive__c drive, sked__Location__c site, String operationType) {
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
        update drive;
        site.Operation_Type__c = operationType;
        update site;
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        update drive;

        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Operation_Type__c, sked_Drive_Site__c,
                sked_Collection_Operation__c, sked_Account__c, sked_Number_of_Vehicles__c, sked_Number_of_2RBC_Assets__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c
            FROM sked_Drive__c
            WHERE Id = :drive.Id
        ];
    }

    // setupCommonTestData already links testCollectionOperation1 to a generic Fixed Site SDM covering
    // the whole test date range - loadMasterData's LIMIT 1 query has no ORDER BY, so a second matching
    // junction is a collision, not an addition. Remove the existing one first so tests that need a
    // specific capacity get a deterministic result.
    private static void replaceFixedSiteSdmLink(Id collectionOperationId, Id staffingDecisionMatrixId) {
        delete [
            SELECT Id FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c = :collectionOperationId
                AND sked_Staffing_Decision_Matrix__r.RecordType.Name = :skedConstants.DRIVE_TYPE_FIXED_SITE
        ];
        insert new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collectionOperationId,
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrixId
        );
    }

    // setupCommonTestData already seeds one generic Fixed Site Procedure Projection per procedure type
    // (WB/Platelet/2RBC/Plasma) for testAccount1 covering the whole test date range. Unlike the SDM lookup
    // (LIMIT 1), calculateApheresisStaffQuantity sums every matching projection, so a leftover generic
    // setting for the same procedure type silently adds to a test's own inserted one. Remove it first.
    private static void replaceFixedSiteProcedureProjection(Id accountId, String procedureType, Decimal qns, Decimal deferral) {
        delete [
            SELECT Id FROM sked_Fixed_Site_Procedure_Projection__c
            WHERE sked_Account__c = :accountId AND sked_Procedure_Type__c = :procedureType
        ];
        insert new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = accountId,
            sked_Procedure_Type__c = procedureType,
            sked_QNS__c = qns,
            sked_Deferral__c = deferral
        );
    }

    // Apex has no varargs - callers always pass a List<Integer> literal.
    private static skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata buildShiftsMetadata(List<Integer> numberOfRoundsPerShift) {
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = new skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata();
        for (Integer i = 0; i < numberOfRoundsPerShift.size(); i++) {
            skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = new skedFixedSiteDriveShiftCalculator.DriveShiftMetadata();
            shift.key = 'drive_shift_' + i;
            shift.numberOfRounds = numberOfRoundsPerShift[i];
            shiftsMetadata.driveShifts.add(shift);
        }
        return shiftsMetadata;
    }

    @isTest
    static void testCalculateAssetQuantity_integratedOperationType_includes2rbcEquipment() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);
        drive.sked_Number_of_Vehicles__c = 2;
        drive.sked_Number_of_2RBC_Assets__c = 4;

        Test.startTest();
        Map<String, Decimal> assetQuantity = skedFixedSiteRoleQuantityCalculator.calculateAssetQuantity(drive);
        Test.stopTest();

        System.assertEquals(2, assetQuantity.get('Vehicle'), 'Vehicle quantity must be a flat passthrough of the drive field, no gate');
        System.assertEquals(4, assetQuantity.get('Equipment - 2RBC Asset'), 'Integrated must include 2RBC equipment quantity');
    }

    @isTest
    static void testCalculateAssetQuantity_nonIntegratedAph_excludes2rbcEquipment() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_APH);
        drive.sked_Number_of_2RBC_Assets__c = 4;

        Test.startTest();
        Map<String, Decimal> assetQuantity = skedFixedSiteRoleQuantityCalculator.calculateAssetQuantity(drive);
        Test.stopTest();

        System.assert(!assetQuantity.containsKey('Equipment - 2RBC Asset'), 'Non Integrated APH must never include 2RBC equipment quantity');
    }

    @isTest
    static void testCalculateRoleQuantities_appliesSameApheresisQuantityToEveryShift() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_APH);
        drive.sked_Platelet_Projected_Procedures__c = 20;

        sked_Staffing_Decision_Matrix__c sdm = new sked_Staffing_Decision_Matrix__c(
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get(skedConstants.DRIVE_TYPE_FIXED_SITE).getRecordTypeId(),
            sked_Platelet_Round_Capacity__c = 2
        );
        insert sdm;
        replaceFixedSiteSdmLink(drive.sked_Collection_Operation__c, sdm.Id);

        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<Integer>{ 2, 2 });

        Test.startTest();
        skedFixedSiteRoleQuantityCalculator.MasterData masterData = skedFixedSiteRoleQuantityCalculator.loadMasterData(drive);
        Map<String, Map<String, skedFixedSiteRoleQuantityCalculator.RoleQuantity>> result =
            skedFixedSiteRoleQuantityCalculator.calculateRoleQuantities(drive, shiftsMetadata, masterData);
        Test.stopTest();

        // 20 platelet procedures / 4 total rounds / 2 capacity = 2.5, rounds half-up to 3 (Math.round, not Decimal.round's half-even).
        System.assertEquals(3, result.get('drive_shift_0').get('Apheresis').quantity, 'Apheresis quantity must be identical on every shift, rounded half-up');
        System.assertEquals(3, result.get('drive_shift_1').get('Apheresis').quantity, 'Apheresis quantity must be identical on every shift, rounded half-up');
        System.assertEquals(1, result.get('drive_shift_0').get('Apheresis Charge').quantity, 'Apheresis Charge is always exactly 1');
        System.assertEquals(1, result.get('drive_shift_1').get('Apheresis Charge').quantity, 'Apheresis Charge is always exactly 1');
    }

    @isTest
    static void testCalculateRoleQuantities_zeroPlateletRoundCapacity_guardsDivideByZero() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_APH);
        drive.sked_Platelet_Projected_Procedures__c = 20;

        skedFixedSiteRoleQuantityCalculator.MasterData masterData = new skedFixedSiteRoleQuantityCalculator.MasterData();
        masterData.timezoneSidId = UserInfo.getTimeZone().getID();
        // staffingDecisionMatrix left null - plateletRoundCapacity resolves to 0, must not throw.
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<Integer>{ 2, 2 });

        Test.startTest();
        Map<String, Map<String, skedFixedSiteRoleQuantityCalculator.RoleQuantity>> result =
            skedFixedSiteRoleQuantityCalculator.calculateRoleQuantities(drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(0, result.get('drive_shift_0').get('Apheresis').quantity, 'A zero SDM capacity must resolve Apheresis quantity to 0 instead of throwing a divide-by-zero error');
    }

    @isTest
    static void testCalculateRoleQuantities_nonIntegratedAph_excludesWbAnd2rbcFromStaffCount() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_APH);
        drive.sked_WB_Projected_Procedures__c = 999;
        drive.sked_2RBC_Projected_Procedures__c = 999;

        sked_Staffing_Decision_Matrix__c sdm = new sked_Staffing_Decision_Matrix__c(
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get(skedConstants.DRIVE_TYPE_FIXED_SITE).getRecordTypeId(),
            sked_WB_Hourly_Capacity__c = 1,
            sked_2RBC_Hourly_Capacity__c = 1
        );
        insert sdm;
        replaceFixedSiteSdmLink(drive.sked_Collection_Operation__c, sdm.Id);
        insert new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = drive.sked_Account__c,
            sked_Procedure_Type__c = skedConstants.PROCEDURE_TYPE_WB,
            sked_QNS__c = 0,
            sked_Deferral__c = 0
        );

        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<Integer>{ 1 });

        Test.startTest();
        skedFixedSiteRoleQuantityCalculator.MasterData masterData = skedFixedSiteRoleQuantityCalculator.loadMasterData(drive);
        Map<String, Map<String, skedFixedSiteRoleQuantityCalculator.RoleQuantity>> result =
            skedFixedSiteRoleQuantityCalculator.calculateRoleQuantities(drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(0, result.get('drive_shift_0').get('Apheresis').quantity,
            'Non Integrated APH must never count WB toward Apheresis staff, even with a huge projected-procedures value and a configured WB capacity');
    }

    @isTest
    static void testCalculateRoleQuantities_missingStartTime_apheresisStaysZeroButChargeStillSet() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        drive.sked_Start_Time__c = null;

        skedFixedSiteRoleQuantityCalculator.MasterData masterData = new skedFixedSiteRoleQuantityCalculator.MasterData();
        masterData.timezoneSidId = UserInfo.getTimeZone().getID();
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<Integer>{ 2 });

        Test.startTest();
        Map<String, Map<String, skedFixedSiteRoleQuantityCalculator.RoleQuantity>> result =
            skedFixedSiteRoleQuantityCalculator.calculateRoleQuantities(drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(0, result.get('drive_shift_0').get('Apheresis').quantity,
            'A drive missing its start time must resolve Apheresis staff to 0, not throw');
        System.assertEquals(1, result.get('drive_shift_0').get('Apheresis Charge').quantity,
            'Apheresis Charge has no date-window guard in the JS and must still be set even when the date window is missing');
    }

    @isTest
    static void testCalculateRoleQuantities_integratedWbSetting_computesNonzeroApheresisStaff() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);
        drive.sked_Start_Time__c = Time.newInstance(8, 0, 0, 0);
        drive.sked_End_Time__c = Time.newInstance(18, 0, 0, 0);
        drive.sked_WB_Projected_Procedures__c = 27;

        // sked_2RBC_Hourly_Capacity__c/sked_Plasma_Hourly_Capacity__c default to 1/0.67 at the field level when
        // left unset (not null/0) - zero them explicitly so testDrive2's base 2RBC procedure count doesn't
        // silently add its own Apheresis contribution and break this test's exact-value assertion.
        sked_Staffing_Decision_Matrix__c sdm = new sked_Staffing_Decision_Matrix__c(
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get(skedConstants.DRIVE_TYPE_FIXED_SITE).getRecordTypeId(),
            sked_WB_Hourly_Capacity__c = 1,
            sked_2RBC_Hourly_Capacity__c = 0,
            sked_Plasma_Hourly_Capacity__c = 0
        );
        insert sdm;
        replaceFixedSiteSdmLink(drive.sked_Collection_Operation__c, sdm.Id);
        replaceFixedSiteProcedureProjection(drive.sked_Account__c, skedConstants.PROCEDURE_TYPE_WB, 0, 0);

        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<Integer>{ 1 });

        Test.startTest();
        skedFixedSiteRoleQuantityCalculator.MasterData masterData = skedFixedSiteRoleQuantityCalculator.loadMasterData(drive);
        Map<String, Map<String, skedFixedSiteRoleQuantityCalculator.RoleQuantity>> result =
            skedFixedSiteRoleQuantityCalculator.calculateRoleQuantities(drive, shiftsMetadata, masterData);
        Test.stopTest();

        // 08:00-18:00 is 600 draw minutes; WB's +60 start offset only (skip-last-appointment unset) leaves a
        // 540-minute (9h) draw window. 27 procedures / 9h / 1 capacity = 3 - pins offsets, capacity mapping, and
        // QNS/deferral factors together for the first time (every other test asserts a 0 through this branch).
        System.assertEquals(3, result.get('drive_shift_0').get('Apheresis').quantity,
            'Integrated WB projection with a 9-hour draw window and capacity 1 must compute exactly 27/9/1 = 3 Apheresis staff');
    }
}
