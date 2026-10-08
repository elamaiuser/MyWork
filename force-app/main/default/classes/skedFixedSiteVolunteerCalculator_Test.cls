@isTest
private class skedFixedSiteVolunteerCalculator_Test {

    // setupCommonTestData already links testCollectionOperation1 to a generic Fixed Site SDM covering
    // the whole test date range (band 18-70) - loadMasterData's LIMIT 1 query has no ORDER BY, so a
    // second matching junction is a collision, not an addition. Remove the existing one first so tests
    // that need a specific band get a deterministic result.
    private static void replaceFixedSiteSdmLink(Id collectionOperationId, Id staffingDecisionMatrixId) {
        removeFixedSiteSdmLink(collectionOperationId);
        insert new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collectionOperationId,
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrixId
        );
    }

    private static void removeFixedSiteSdmLink(Id collectionOperationId) {
        delete [
            SELECT Id FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c = :collectionOperationId
                AND sked_Staffing_Decision_Matrix__r.RecordType.Name = :skedConstants.DRIVE_TYPE_FIXED_SITE
        ];
    }

    private static skedFixedSiteDriveShiftCalculator.DriveShiftMetadata buildShift(
            String key, Date driveDate, Time startTime, Time endTime, Decimal totalProceduresProjected) {
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = new skedFixedSiteDriveShiftCalculator.DriveShiftMetadata();
        shift.key = key;
        shift.driveDate = driveDate;
        shift.startTime = startTime;
        shift.endTime = endTime;
        shift.totalProceduresProjected = totalProceduresProjected;
        return shift;
    }

    private static skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata buildShiftsMetadata(
            List<skedFixedSiteDriveShiftCalculator.DriveShiftMetadata> shifts) {
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = new skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata();
        shiftsMetadata.driveShifts.addAll(shifts);
        return shiftsMetadata;
    }

    @isTest
    static void testCalculateVolunteerQuantities_belowLowerBand_returnsZero() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');

        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<skedFixedSiteDriveShiftCalculator.DriveShiftMetadata>{
            buildShift('drive_shift_0', drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, 10)
        });

        Test.startTest();
        skedFixedSiteVolunteerCalculator.MasterData masterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> result = skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(
            shiftsMetadata, masterData, UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assertEquals(0, result.get('drive_shift_0'), 'Total procedures below the lower band must resolve to 0 Donor Ambassadors');
    }

    @isTest
    static void testCalculateVolunteerQuantities_atLowerBoundary_returnsOne() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');

        // Default fixedSiteMatrix fixture band is 18-70 - the value equal to the lower bound.
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<skedFixedSiteDriveShiftCalculator.DriveShiftMetadata>{
            buildShift('drive_shift_0', drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, 18)
        });

        Test.startTest();
        skedFixedSiteVolunteerCalculator.MasterData masterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> result = skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(
            shiftsMetadata, masterData, UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assertEquals(1, result.get('drive_shift_0'), 'Total procedures exactly at the lower band boundary must resolve to 1 Donor Ambassador');
    }

    @isTest
    static void testCalculateVolunteerQuantities_atUpperBoundary_returnsOne() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');

        // Default fixedSiteMatrix fixture band is 18-70 - the value equal to the upper bound.
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<skedFixedSiteDriveShiftCalculator.DriveShiftMetadata>{
            buildShift('drive_shift_0', drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, 70)
        });

        Test.startTest();
        skedFixedSiteVolunteerCalculator.MasterData masterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> result = skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(
            shiftsMetadata, masterData, UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assertEquals(1, result.get('drive_shift_0'), 'Total procedures exactly at the upper band boundary must resolve to 1 Donor Ambassador, inclusive');
    }

    @isTest
    static void testCalculateVolunteerQuantities_aboveUpperBand_returnsTwo() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');

        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<skedFixedSiteDriveShiftCalculator.DriveShiftMetadata>{
            buildShift('drive_shift_0', drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, 71)
        });

        Test.startTest();
        skedFixedSiteVolunteerCalculator.MasterData masterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> result = skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(
            shiftsMetadata, masterData, UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assertEquals(2, result.get('drive_shift_0'), 'Total procedures above the upper band must resolve to 2 Donor Ambassadors');
    }

    @isTest
    static void testCalculateVolunteerQuantities_noSdmMatch_returnsEmptyMap() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        removeFixedSiteSdmLink(drive.sked_Collection_Operation__c);

        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<skedFixedSiteDriveShiftCalculator.DriveShiftMetadata>{
            buildShift('drive_shift_0', drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, 50)
        });

        Test.startTest();
        skedFixedSiteVolunteerCalculator.MasterData masterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> result = skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(
            shiftsMetadata, masterData, UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'A drive whose Collection Operation has no matching Fixed Site SDM must return an empty map, not throw');
    }

    @isTest
    static void testCalculateVolunteerQuantities_sdmWithNullUpperBand_returnsZero() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');

        // sked_NR_Volunteer_Fixed_Site_Band_Upper__c has a field-level default of 70 - merely omitting it
        // from the constructor would silently populate 70, not null. Set it explicitly to null so this
        // test actually exercises the plan's divergence from the JS's undefined-comparison fallthrough
        // (which lands on 2).
        sked_Staffing_Decision_Matrix__c sdm = new sked_Staffing_Decision_Matrix__c(
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get(skedConstants.DRIVE_TYPE_FIXED_SITE).getRecordTypeId(),
            sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 18,
            sked_NR_Volunteer_Fixed_Site_Band_Upper__c = null
        );
        insert sdm;
        replaceFixedSiteSdmLink(drive.sked_Collection_Operation__c, sdm.Id);

        // 50 would land mid-band (1) under a complete band - proves the null-band branch wins, not the math.
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<skedFixedSiteDriveShiftCalculator.DriveShiftMetadata>{
            buildShift('drive_shift_0', drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, 50)
        });

        Test.startTest();
        skedFixedSiteVolunteerCalculator.MasterData masterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> result = skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(
            shiftsMetadata, masterData, UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assertEquals(0, result.get('drive_shift_0'), 'A null band field must resolve to 0 Donor Ambassadors, not fall through to 2 like the JS');
    }

    @isTest
    static void testCalculateVolunteerQuantities_sdmWithNullLowerBand_returnsZero() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');

        // sked_NR_Volunteer_Fixed_Site_Band_Lower__c has a field-level default of 18 - merely omitting it
        // from the constructor would silently populate 18, not null. Set it explicitly to null. A null
        // lower band is the bigger JS divergence: JS's `totalProceduresProjected < undefined` is false for
        // every value, so the JS falls through to 2 across the ENTIRE domain, not just above some threshold -
        // a low totalProceduresProjected value proves Apex's 0 isn't reachable by accident.
        sked_Staffing_Decision_Matrix__c sdm = new sked_Staffing_Decision_Matrix__c(
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get(skedConstants.DRIVE_TYPE_FIXED_SITE).getRecordTypeId(),
            sked_NR_Volunteer_Fixed_Site_Band_Lower__c = null,
            sked_NR_Volunteer_Fixed_Site_Band_Upper__c = 70
        );
        insert sdm;
        replaceFixedSiteSdmLink(drive.sked_Collection_Operation__c, sdm.Id);

        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<skedFixedSiteDriveShiftCalculator.DriveShiftMetadata>{
            buildShift('drive_shift_0', drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, 5)
        });

        Test.startTest();
        skedFixedSiteVolunteerCalculator.MasterData masterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> result = skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(
            shiftsMetadata, masterData, UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assertEquals(0, result.get('drive_shift_0'), 'A null lower band field must resolve to 0 Donor Ambassadors, not fall through to 2 like the JS');
    }

    @isTest
    static void testCalculateVolunteerQuantities_zeroDrawHours_shiftSkippedEntirely() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');

        // Two shifts, not one - proves the zero-draw-hours shift is skipped by its OWN key, not by
        // always writing (or skipping) index 0 regardless of which shift is being processed.
        Time sameTime = Time.newInstance(9, 0, 0, 0);
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<skedFixedSiteDriveShiftCalculator.DriveShiftMetadata>{
            buildShift('drive_shift_0', drive.sked_Drive_Date__c, sameTime, sameTime, 50),
            buildShift('drive_shift_1', drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, 50)
        });

        Test.startTest();
        skedFixedSiteVolunteerCalculator.MasterData masterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> result = skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(
            shiftsMetadata, masterData, UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assert(!result.containsKey('drive_shift_0'), 'A shift with zero draw hours must be absent from the result map entirely, not present with quantity 0');
        // Default fixedSiteMatrix fixture band is 18-70 - 50 lands mid-band.
        System.assertEquals(1, result.get('drive_shift_1'), 'A later shift with real draw hours must still resolve to its own correct quantity, keyed by its own shift key');
    }
}
