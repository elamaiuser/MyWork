@isTest
private class skedFixedSiteDriveShiftCalculator_Test {

    // testDrive2/testLocation2 default Operation_Type__c to WB (skedTestDataFactory.cls:557) - see
    // reference_fixed_site_test_fixture_gotchas.md. Flips it via the required cancel -> flip -> restore
    // dance, then re-queries the drive (sked_Operation_Type__c is a formula field).
    private static sked_Drive__c setOperationTypeAndQuery(sked_Drive__c drive, sked__Location__c site, String operationType) {
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
        update drive;
        site.Operation_Type__c = operationType;
        update site;
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        update drive;

        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Operation_Type__c, sked_Drive_Site__c,
                sked_Collection_Operation__c, sked_Account__c, sked_Account__r.Accepts_Automation2__c, sked_Travel_Time_Included__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c
            FROM sked_Drive__c
            WHERE Id = :drive.Id
        ];
    }

    private static Map<String, sObject> setupBaseDriveData() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_No_Travel_Time__c = false;
        collectionOperation.sked_Lunch_Break__c = true;
        // Deliberately different from Mobile's duration so a test reading the wrong field fails instead of coincidentally passing.
        collectionOperation.sked_Lunch_Break_Duration_Fixed_Site__c = '45';
        collectionOperation.sked_Lunch_Break_Duration_Mobile__c = '30';
        update collectionOperation;

        return testData;
    }

    @isTest
    static void testCalculatePlateletRounds_returnsCorrectRoundsForEachDrawHourTier() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        String timezoneSidId = UserInfo.getTimeZone().getID();

        Test.startTest();
        drive.sked_Start_Time__c = Time.newInstance(7, 0, 0, 0);
        System.assertEquals(1, skedFixedSiteDriveShiftCalculator.calculatePlateletRounds(setEndTime(drive, 10, 0), timezoneSidId), 'A 3-hour drive must default to 1 round');
        System.assertEquals(2, skedFixedSiteDriveShiftCalculator.calculatePlateletRounds(setEndTime(drive, 13, 0), timezoneSidId), 'A 6-hour drive must default to 2 rounds');
        System.assertEquals(3, skedFixedSiteDriveShiftCalculator.calculatePlateletRounds(setEndTime(drive, 16, 0), timezoneSidId), 'A 9-hour drive must default to 3 rounds');
        System.assertEquals(4, skedFixedSiteDriveShiftCalculator.calculatePlateletRounds(setEndTime(drive, 19, 0), timezoneSidId), 'A 12-hour drive must default to 4 rounds');
        System.assertEquals(5, skedFixedSiteDriveShiftCalculator.calculatePlateletRounds(setEndTime(drive, 20, 0), timezoneSidId), 'Over 12 hours must default to 5 rounds');
        Test.stopTest();
    }

    private static sked_Drive__c setEndTime(sked_Drive__c drive, Integer hour, Integer minute) {
        drive.sked_End_Time__c = Time.newInstance(hour, minute, 0, 0);
        return drive;
    }

    @isTest
    static void testCalculatePlateletRounds_missingStartTime_returnsZero() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        drive.sked_Start_Time__c = null;

        Test.startTest();
        Integer rounds = skedFixedSiteDriveShiftCalculator.calculatePlateletRounds(drive, UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assertEquals(0, rounds, 'A drive missing its start time must return 0 rounds rather than throw');
    }

    @isTest
    static void testGenerateDriveShiftRounds_dropsRoundStartingAtOrAfterShiftEnd() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime shiftStart = DateTime.newInstanceGmt(2026, 1, 5, 7, 0, 0);
        DateTime shiftEnd = skedDateTimeUtils.addMinutes(shiftStart, 5 * 60, timezoneSidId);

        Test.startTest();
        List<skedTimeRange> rounds = skedFixedSiteDriveShiftCalculator.generateDriveShiftRounds(shiftStart, shiftEnd, 3, timezoneSidId);
        Test.stopTest();

        System.assertEquals(2, rounds.size(), 'Requesting 3 rounds over a 5-hour shift must drop the 3rd round (its start at +6h is past shiftEnd)');
        System.assert(rounds[1].rangeEnd > shiftEnd, 'A round\'s end is allowed to overrun shiftEnd - only its start is guarded');
    }

    @isTest
    static void testGenerateExcludedTimeRangesFromPlateletRounds_oneHourWindowPerRound() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        skedTimeRange round = new skedTimeRange();
        round.rangeStart = DateTime.newInstanceGmt(2026, 1, 5, 7, 0, 0);
        round.rangeEnd = skedDateTimeUtils.addMinutes(round.rangeStart, 180, timezoneSidId);

        Test.startTest();
        List<skedTimeRange> excludedTimeRanges = skedFixedSiteDriveShiftCalculator.generateExcludedTimeRangesFromPlateletRounds(
            new List<skedTimeRange>{ round }, timezoneSidId);
        Test.stopTest();

        System.assertEquals(skedDateTimeUtils.addMinutes(round.rangeStart, 60, timezoneSidId), excludedTimeRanges[0].rangeEnd,
            'Each excluded time range must be exactly 1 hour, anchored to the round\'s own start');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_integratedOperationType_splitsAllFourProcedureTypesAcrossTwoShifts() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);
        // calculateDriveShiftsMetadata only reads these fields off the in-memory drive - no DML needed to make them visible to it.
        drive.sked_2RBC_Projected_Procedures__c = 10;
        drive.sked_WB_Projected_Procedures__c = 20;
        drive.sked_Platelet_Projected_Procedures__c = 9;
        drive.sked_Plasma_Projected_Procedures__c = 6;

        Test.startTest();
        skedFixedSiteDriveShiftCalculator.MasterData masterData = skedFixedSiteDriveShiftCalculator.loadMasterData(drive);
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata result = skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        System.assertEquals(2, result.numberOfDriveShifts, 'testDrive2\'s default 10-hour window is 4 platelet rounds, which is 2 drive shifts');

        // testDrive2's 07:00-17:00 window splits into two equal 2-round shifts (07:00-13:00, 13:00-17:00).
        // Platelet is round-weighted (2/4 rounds each); 2RBC is duration-weighted (360 of 600 total minutes
        // for shift 0, 240 for shift 1) - asserting exact per-shift numbers, not just their sum, so a wrong
        // split ratio would actually fail the test.
        System.assertEquals(5, result.driveShifts[0].plateletProjectedProcedures, 'Platelet is round-weighted: shift 0 gets ceil(9 * 2/4) = 5');
        System.assertEquals(4, result.driveShifts[1].plateletProjectedProcedures, 'Platelet is round-weighted: shift 1 gets the remaining 4 (its own ceil(9 * 2/4) = 5 is clamped to what remains)');
        System.assertEquals(6, result.driveShifts[0].x2rbcProjectedProcedures, '2RBC is duration-weighted: shift 0 (360 of 600 minutes) gets ceil(10 * 360/600) = 6');
        System.assertEquals(4, result.driveShifts[1].x2rbcProjectedProcedures, '2RBC is duration-weighted: shift 1 gets the remaining 4');

        Decimal totalPlatelet = 0;
        Decimal totalPlasma = 0;
        Decimal total2rbc = 0;
        Decimal totalWb = 0;
        for (skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift : result.driveShifts) {
            totalPlatelet += shift.plateletProjectedProcedures;
            totalPlasma += shift.plasmaProjectedProcedures;
            total2rbc += shift.x2rbcProjectedProcedures;
            totalWb += shift.wbProjectedProcedures;
        }
        System.assertEquals(9, totalPlatelet, 'Platelet procedures must sum back to the drive-level total across shifts');
        System.assertEquals(6, totalPlasma, 'Plasma procedures must sum back to the drive-level total across shifts');
        System.assertEquals(10, total2rbc, '2RBC must split when Integrated and the account accepts automation');
        System.assertEquals(20, totalWb, 'WB must split when Integrated');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_nonIntegratedAph_2rbcAndWbStayZeroOnEveryShift() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_APH);
        drive.sked_2RBC_Projected_Procedures__c = 10;
        drive.sked_WB_Projected_Procedures__c = 20;
        drive.sked_Platelet_Projected_Procedures__c = 9;
        drive.sked_Plasma_Projected_Procedures__c = 6;

        Test.startTest();
        skedFixedSiteDriveShiftCalculator.MasterData masterData = skedFixedSiteDriveShiftCalculator.loadMasterData(drive);
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata result = skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        Decimal totalPlatelet = 0;
        for (skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift : result.driveShifts) {
            System.assertEquals(0, shift.x2rbcProjectedProcedures, 'Non Integrated APH must never split 2RBC onto any shift');
            System.assertEquals(0, shift.wbProjectedProcedures, 'Non Integrated APH must never split WB onto any shift');
            totalPlatelet += shift.plateletProjectedProcedures;
        }
        System.assertEquals(9, totalPlatelet, 'Platelet must still split for Non Integrated APH');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_lunchBreakSettings_usesFixedSiteDurationField() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_APH);
        drive.sked_Platelet_Projected_Procedures__c = 3;

        Test.startTest();
        skedFixedSiteDriveShiftCalculator.MasterData masterData = skedFixedSiteDriveShiftCalculator.loadMasterData(drive);
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata result = skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        System.assertEquals(45, result.driveShifts[0].lunchBreakSettings.maximumLunchBreakDuration,
            'Fixed Site\'s lunch break duration must come from sked_Lunch_Break_Duration_Fixed_Site__c, not the Mobile field');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_lunchBreak_excludesDrivingRolesAndTravelTime() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_APH);
        // A 250-minute (4h10m) draw window: with Fixed Site's real lunch-break arguments (Driving roles
        // excluded, travel time excluded), shift length is 250 + 20 + 20 = 290 minutes - under the
        // 360-minute threshold. If Mobile's arguments leaked in instead (no role-group filter, travel
        // time included), Driving roles' 250-minute setup/breakdown alone would push the total past
        // 780 minutes - proving the exclusion/gate is actually applied here, not silently dropped.
        drive.sked_Start_Time__c = Time.newInstance(7, 0, 0, 0);
        drive.sked_End_Time__c = Time.newInstance(11, 10, 0, 0);

        sked_Role_Time_Detail__c drivingRolesRtd = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Resource_Role_Group__c = skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES,
            sked_Days_of_Week__c = 'Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday',
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_FIXED_SITE,
            sked_Mobile_Type__c = 'Inside',
            sked_Setup_Time__c = 250,
            sked_Breakdown_Time__c = 250
        );
        sked_Role_Time_Detail__c staffAndSupervisoryRtd = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Resource_Role_Group__c = skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES + ';' + skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES,
            sked_Days_of_Week__c = 'Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday',
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_FIXED_SITE,
            sked_Mobile_Type__c = 'Inside',
            sked_Lead_Time__c = 10,
            sked_Setup_Time__c = 10,
            sked_Breakdown_Time__c = 10,
            sked_Wrap_up_Time__c = 10
        );
        insert new List<sked_Role_Time_Detail__c>{ drivingRolesRtd, staffAndSupervisoryRtd };

        Test.startTest();
        skedFixedSiteDriveShiftCalculator.MasterData masterData = skedFixedSiteDriveShiftCalculator.loadMasterData(drive);
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata result = skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        System.assertEquals(1, result.driveShifts.size(), 'A 250-minute draw window is 2 platelet rounds, which is 1 drive shift');
        System.assertEquals(false, result.driveShifts[0].lunchBreakSettings.lunchBreak,
            'Driving roles\' time and travel time must both be excluded from the Fixed Site lunch-break duration check');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_extendedWindow_splitsRoundsAsymmetrically() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_APH);
        // 07:00-20:00 is a 13-hour draw window (over 12h -> 5 platelet rounds), which does not split
        // evenly: ceil(5/2) = 3 rounds go to shift 0, leaving 2 for shift 1. Every other multi-shift
        // test in this class uses testDrive2's default 10-hour/4-round window, which always splits
        // evenly (2/2) - this is the only test exercising the asymmetric case.
        drive.sked_End_Time__c = Time.newInstance(20, 0, 0, 0);

        Test.startTest();
        skedFixedSiteDriveShiftCalculator.MasterData masterData = skedFixedSiteDriveShiftCalculator.loadMasterData(drive);
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata result = skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        System.assertEquals(2, result.numberOfDriveShifts, 'A 13-hour window is still clamped to 2 drive shifts');
        System.assertEquals(3, result.driveShifts[0].numberOfRounds, 'ceil(5 rounds / 2 shifts) = 3 rounds go to shift 0');
        System.assertEquals(2, result.driveShifts[1].numberOfRounds, 'The remaining 2 rounds go to shift 1');
        System.assertEquals(Time.newInstance(16, 0, 0, 0), result.driveShifts[0].endTime, 'Shift 0 ends exactly 3 rounds (9 hours) after its 07:00 start');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_zeroDrawHours_totalWeightZeroGuardAvoidsDivideByZero() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_APH);
        // Start == End collapses draw hours to 0, which collapses generateDriveShiftRounds to a single
        // shift with 0 rounds (roundStart < shiftEnd is false when they're equal) - totalWeight is then
        // 0, which must short-circuit to 0% per shift (see the class's own totalWeight == 0 comment)
        // rather than divide by zero.
        drive.sked_End_Time__c = drive.sked_Start_Time__c;
        drive.sked_Platelet_Projected_Procedures__c = 5;

        Test.startTest();
        skedFixedSiteDriveShiftCalculator.MasterData masterData = skedFixedSiteDriveShiftCalculator.loadMasterData(drive);
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata result = skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        for (skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift : result.driveShifts) {
            System.assertEquals(0, shift.numberOfRounds, 'A zero-draw-hour drive must produce a shift with 0 rounds');
            System.assertEquals(0, shift.plateletProjectedProcedures, 'A totalWeight of 0 must resolve every shift to 0% instead of throwing a divide-by-zero error');
        }
    }

    @isTest
    static void testLoadMasterData_fixedSiteOperationTypeFilter_blankMatchesAllButMismatchExcludes() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);

        sked_Role_Time_Detail__c blankOperationTypeRtd = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Resource_Role_Group__c = skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES,
            sked_Days_of_Week__c = 'Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday',
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_FIXED_SITE,
            sked_Mobile_Type__c = 'Inside',
            sked_Lead_Time__c = 10
        );
        sked_Role_Time_Detail__c mismatchedOperationTypeRtd = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Resource_Role_Group__c = skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES,
            sked_Days_of_Week__c = 'Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday',
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_FIXED_SITE,
            sked_Mobile_Type__c = 'Inside',
            sked_Fixed_Site_Operation_Type__c = skedConstants.OPERATION_TYPE_APH,
            sked_Lead_Time__c = 999
        );
        insert new List<sked_Role_Time_Detail__c>{ blankOperationTypeRtd, mismatchedOperationTypeRtd };

        Test.startTest();
        skedFixedSiteDriveShiftCalculator.MasterData masterData = skedFixedSiteDriveShiftCalculator.loadMasterData(drive);
        Test.stopTest();

        System.assert(masterData.roleGroupTimeDetailMap.containsKey(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES),
            'An RTD with a blank Fixed_Site_Operation_Type must match every operation type');
        System.assert(!masterData.roleGroupTimeDetailMap.containsKey(skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES),
            'An RTD whose Fixed_Site_Operation_Type mismatches the drive\'s own operation type must be excluded');
    }
}
