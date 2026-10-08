@isTest
private class skedMobileDriveShiftCalculator_Test {

    private static sked_Drive__c queryDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Projected_Registered_Donors__c,
                sked_APT_Quantity__c, sked_Travel_Time_Included__c, sked_Account__r.Type, sked_Account__r.Industry_Code__c,
                sked_Account__r.Accepts_Automation2__c, sked_Type_of_Drive__c, sked_Operation_Type__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    private static Map<String, sObject> setupBaseDriveData() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Maximum_Shift_Length_Threshold__c = 700;
        collectionOperation.sked_No_Travel_Time__c = false;
        collectionOperation.sked_Lunch_Break__c = false;
        update collectionOperation;

        return testData;
    }

    @isTest
    static void testLoadMasterData_nonRequiredAccountTag_includedInDriveShiftTagResults() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);
        sked__Tag__c tag = new sked__Tag__c(Name = 'Cooler');
        insert tag;
        insert new sked__Account_Tag__c(sked__Account__c = drive.sked_Account__c, sked__Tag__c = tag.Id, sked__Required__c = false, sked_Minimum_Quantity__c = 4);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        Test.stopTest();

        System.assertEquals(1, masterData.driveShiftTagResults.size(), 'The non-required account tag must appear in driveShiftTagResults');
        System.assertEquals(4, masterData.driveShiftTagResults[0].minimumQuantity, 'minimumQuantity must be carried through from the account tag');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_belowThreshold_producesSingleShiftWithFullTotals() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        System.assertEquals(1, shiftsMetadata.numberOfDriveShifts, 'A 10-hour drive under a 700-minute shift-length threshold must produce exactly one shift');
        skedMobileDriveShiftCalculator.DriveShiftMetadata onlyShift = shiftsMetadata.driveShifts[0];
        System.assertEquals(drive.sked_2RBC_Projected_Procedures__c, onlyShift.x2rbcProjectedProcedures, 'The single shift must absorb all of the drive-level 2RBC procedures');
        System.assertEquals(drive.sked_WB_Projected_Procedures__c, onlyShift.wbProjectedProcedures, 'The single shift must absorb all of the drive-level WB procedures');
        System.assertEquals(drive.sked_Projected_Registered_Donors__c, onlyShift.donorsScheduled, 'The single shift must absorb all of the projected registered donors');
    }

    // helper.js's show2RBCField gates the 2RBC split on the account accepting automation - WB has
    // no such gate and must still split normally.
    @isTest
    static void testCalculateDriveShiftsMetadata_accountDoesNotAcceptAutomation_skips2RBCSplit() {
        Map<String, sObject> testData = setupBaseDriveData();
        Account account = (Account) testData.get('testAccount1');
        account.Accepts_Automation2__c = 'No';
        update account;
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        skedMobileDriveShiftCalculator.DriveShiftMetadata onlyShift = shiftsMetadata.driveShifts[0];
        System.assertEquals(0, onlyShift.x2rbcProjectedProcedures, 'A non-automation account must skip the 2RBC split entirely, leaving the field at its default');
        System.assertEquals(drive.sked_WB_Projected_Procedures__c, onlyShift.wbProjectedProcedures, 'WB has no automation gate and must still split normally');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_aboveThreshold_splitsProceduresAcrossMultipleShifts() {
        Map<String, sObject> testData = setupBaseDriveData();
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Maximum_Shift_Length_Threshold__c = 400;
        update collectionOperation;

        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        // driveDrawHoursInMinutes(600) + travel-time-fallback before/after (15+15) = 630 minutes; ceil(630/400) = 2 shifts.
        System.assertEquals(2, shiftsMetadata.numberOfDriveShifts, 'A 630-minute drive window under a 400-minute shift-length threshold must split into two shifts');

        Decimal totalX2rbc = 0;
        Decimal totalWb = 0;
        Decimal totalDonors = 0;
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            totalX2rbc += shift.x2rbcProjectedProcedures;
            totalWb += shift.wbProjectedProcedures;
            totalDonors += shift.donorsScheduled;
        }
        System.assertEquals(drive.sked_2RBC_Projected_Procedures__c, totalX2rbc, '2RBC procedures split across shifts must sum back to the drive-level total');
        System.assertEquals(drive.sked_WB_Projected_Procedures__c, totalWb, 'WB procedures split across shifts must sum back to the drive-level total');
        System.assertEquals(drive.sked_Projected_Registered_Donors__c, totalDonors, 'Donors split across shifts must sum back to the drive-level total');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_highSchoolEducationAccountAt40Procedures_recalculatesAptQuantity() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_2RBC_Projected_Procedures__c = 30;
        testDrive1.sked_WB_Projected_Procedures__c = 20;
        update testDrive1;

        sked_Drive__c drive = queryDrive(testDrive1.Id);
        System.assertEquals(skedConstants.ACCOUNT_TYPE_EDUCATION, drive.sked_Account__r.Type, 'Test setup must use an Education account');
        System.assertEquals(skedConstants.ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL, drive.sked_Account__r.Industry_Code__c, 'Test setup must use a High School account (not Middle/Elementary)');

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        System.assertEquals(50, shiftsMetadata.totalProceduresProjected, 'Total procedures projected must be the sum of 2RBC and WB');
        System.assertEquals(1, shiftsMetadata.aptSetup, 'A High School Education account at 50 total procedures (>= 40) must set APT quantity to floor(50/40) = 1');
    }

    // Travel time is recomputed against EACH shift's own start/end window rather than reusing the
    // single drive-level value computed against the drive's overall window - this only shows up for
    // a multi-shift drive, where a shift's own end can fall hours before the drive's own end.
    @isTest
    static void testCalculateDriveShiftsMetadata_multiShiftDrive_recomputesTravelTimeAgainstEachShiftsOwnWindow() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c) testData.get('testStagingLocation1');
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked__Location__c driveSite = [
            SELECT sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s
            FROM sked__Location__c WHERE Id = :testDrive1.sked_Drive_Site__c
        ];

        String siteToCoKey = String.valueOf(driveSite.sked__GeoLocation__Latitude__s) + ' ' + String.valueOf(driveSite.sked__GeoLocation__Longitude__s)
            + ':' + String.valueOf(testStagingLocation1.sked_Geolocation__Latitude__s) + ' ' + String.valueOf(testStagingLocation1.sked_Geolocation__Longitude__s);

        // Shift 1 ends around midday, hours before the drive/shift 2's own end - the exact clock
        // boundary isn't asserted on directly (avoids hardcoding a timezone-dependent UTC offset);
        // what matters is that the two shifts' own end times land in different windows below.
        List<Object> windows = new List<Object>();
        for (String weekday : new List<String>{ 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }) {
            windows.add(new Map<String, Object>{ 'weekday' => weekday, 'startOfWindow' => '00:00:00.000Z', 'endOfWindow' => '18:29:59.999Z', 'travelTime' => 111 });
            windows.add(new Map<String, Object>{ 'weekday' => weekday, 'startOfWindow' => '18:30:00.000Z', 'endOfWindow' => '23:59:59.999Z', 'travelTime' => 222 });
        }
        insert new sked_Travel_Time_Index_Item__c(
            sked_Key__c = siteToCoKey,
            sked_From__Latitude__s = driveSite.sked__GeoLocation__Latitude__s,
            sked_From__Longitude__s = driveSite.sked__GeoLocation__Longitude__s,
            sked_To__Latitude__s = testStagingLocation1.sked_Geolocation__Latitude__s,
            sked_To__Longitude__s = testStagingLocation1.sked_Geolocation__Longitude__s,
            sked_Travel_Time_Breakdown_JSON__c = JSON.serialize(windows)
        );

        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        System.assertEquals(2, shiftsMetadata.numberOfDriveShifts, 'Setup check: this scenario must split into exactly 2 shifts (see the above-threshold test)');

        skedMobileDriveShiftCalculator.RoleTimeData firstShiftData = shiftsMetadata.driveShifts[0].resourceRoleGroupRoleTimeDataMap.get(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES);
        skedMobileDriveShiftCalculator.RoleTimeData secondShiftData = shiftsMetadata.driveShifts[1].resourceRoleGroupRoleTimeDataMap.get(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES);

        // Shift 1 ends at midday (falls in the "111" window); shift 2 ends when the drive itself
        // does (falls in the "222" window, same as the drive-level value) - a reused drive-level
        // value (the pre-fix bug) would show 222 for both.
        System.assertEquals(111, firstShiftData.travelTime2,
            'Shift 1 ends hours before the drive/shift 2\'s own end - its own end time must drive the travel-time-index lookup, not a value reused from the drive-level computation');
        System.assertEquals(222, secondShiftData.travelTime2,
            'Shift 2 ends at the same time as the drive itself, so its recomputed travel time must still match the drive-level value');
    }

    // The shift-level exclusion check must also honor Travel_Time_Included__c = 'Drivers Only', not
    // just No_Travel_Time__c, matching what the drive-level calculateDriveRoleTimeData already does.
    @isTest
    static void testCalculateDriveShiftsMetadata_travelTimeIncludedDriversOnly_excludesNonDrivingRoleShiftTravelTime() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_Travel_Time_Included__c = 'Drivers Only';
        update testDrive1;

        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        Test.stopTest();

        skedMobileDriveShiftCalculator.RoleTimeData shiftStaffRoleTimeData =
            shiftsMetadata.driveShifts[0].resourceRoleGroupRoleTimeDataMap.get(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES);
        System.assertEquals(0, shiftStaffRoleTimeData.travelTime,
            'Drive-level Travel Time Included = Drivers Only must still exclude a non-driving role\'s shift-level travel time after the per-shift recompute');
        System.assertEquals(0, shiftStaffRoleTimeData.travelTime2,
            'Drive-level Travel Time Included = Drivers Only must still exclude a non-driving role\'s shift-level return travel time after the per-shift recompute');
    }

    // ===== WB Fixed Site config =====

    // Driving roles carry a 100-minute setup time no other role group has: counting them the drive
    // window is 600 + (100 + 15 travel) + 15 = 730 minutes, ignoring them it is 600 + 15 + 15 = 630.
    // The 700-minute shift-length threshold sits between the two, so the role-group filter alone
    // decides the shift count.
    private static void insertDrivingRolesSetupTime() {
        insert new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Resource_Role_Group__c = skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES,
            sked_Days_of_Week__c = 'Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday',
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_MOBILE,
            sked_Mobile_Type__c = 'Inside',
            sked_Setup_Time__c = 100
        );
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_drivingRolesSetupTime_mobileConfigCountsItTowardsShiftCount() {
        Map<String, sObject> testData = setupBaseDriveData();
        insertDrivingRolesSetupTime();
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(
            drive, masterData, skedMobileDriveShiftCalculator.mobileConfig());
        Test.stopTest();

        System.assertEquals(2, shiftsMetadata.numberOfDriveShifts,
            'Mobile applies no role-group filter, so the Driving roles setup time pushes the 730-minute window past the 700-minute threshold into two shifts');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_drivingRolesSetupTime_wbConfigExcludesItFromShiftCount() {
        Map<String, sObject> testData = setupBaseDriveData();
        insertDrivingRolesSetupTime();
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        skedMobileDriveShiftCalculator.ShiftMetadataConfig config = skedMobileDriveShiftCalculator.wbFixedSiteConfig();
        // Travel time left on to isolate the role-group filter as the only lever under test.
        config.includeTravelTimeInRoleTimeDuration = true;

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData, config);
        Test.stopTest();

        System.assertEquals(1, shiftsMetadata.numberOfDriveShifts,
            'WB filters the shift-count duration to Supervisory/Staff roles, so the Driving roles setup time is ignored and the 630-minute window stays within the 700-minute threshold as one shift');
    }

    // Drive window 600 minutes plus the site's flat 15-minute travel time each way = 630; the
    // 610-minute threshold sits between 600 and 630, so the travel-time lever alone decides the
    // shift count.
    private static void setShiftLengthThresholdBetweenDrawHoursAndTravelTime(Map<String, sObject> testData) {
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Maximum_Shift_Length_Threshold__c = 610;
        update collectionOperation;
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_mobileConfig_countsTravelTimeTowardsShiftCount() {
        Map<String, sObject> testData = setupBaseDriveData();
        setShiftLengthThresholdBetweenDrawHoursAndTravelTime(testData);
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(
            drive, masterData, skedMobileDriveShiftCalculator.mobileConfig());
        Test.stopTest();

        System.assertEquals(2, shiftsMetadata.numberOfDriveShifts,
            'Mobile includes travel time in the shift-count duration, so the 630-minute window exceeds the 610-minute threshold and splits into two shifts');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_wbConfig_excludesTravelTimeFromShiftCount() {
        Map<String, sObject> testData = setupBaseDriveData();
        setShiftLengthThresholdBetweenDrawHoursAndTravelTime(testData);
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(
            drive, masterData, skedMobileDriveShiftCalculator.wbFixedSiteConfig());
        Test.stopTest();

        System.assertEquals(1, shiftsMetadata.numberOfDriveShifts,
            'WB is a Fixed Site drive, so travel time is excluded from the shift-count duration and the 600-minute window stays within the 610-minute threshold as one shift');
    }

    // Both APT write paths are exercised at once: a pre-existing APT Quantity of 3 on the drive (the
    // drive-level seed) and 50 total procedures on a High School Education account (which the Mobile
    // path recalculates to 1, per the recalculatesAptQuantity test above).
    @isTest
    static void testCalculateDriveShiftsMetadata_wbConfig_leavesAptSetupAtZero() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_2RBC_Projected_Procedures__c = 30;
        testDrive1.sked_WB_Projected_Procedures__c = 20;
        testDrive1.sked_APT_Quantity__c = 3;
        update testDrive1;

        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(
            drive, masterData, skedMobileDriveShiftCalculator.wbFixedSiteConfig());
        Test.stopTest();

        System.assertEquals(0, shiftsMetadata.aptSetup,
            'WB has no APT anywhere, so neither the drive\'s existing APT Quantity of 3 nor the recalculated value of 1 may reach the drive-level APT Setup');
        System.assertEquals(0, shiftsMetadata.driveShifts[0].aptSetup,
            'WB has no APT anywhere, so the shift-level APT Setup must stay at zero too');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_wbConfig_usesFixedSiteLunchBreakDuration() {
        Map<String, sObject> testData = setupBaseDriveData();
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Lunch_Break__c = true;
        collectionOperation.sked_Lunch_Break_Duration_Mobile__c = '30';
        collectionOperation.sked_Lunch_Break_Duration_Fixed_Site__c = '45';
        update collectionOperation;

        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(
            drive, masterData, skedMobileDriveShiftCalculator.wbFixedSiteConfig());
        Test.stopTest();

        System.assertEquals(45, shiftsMetadata.driveShifts[0].lunchBreakSettings.maximumLunchBreakDuration,
            'WB is a Fixed Site drive, so the lunch break duration must come from Lunch Break Duration (Fixed Site) = 45, not the Mobile field\'s 30');
    }

    @isTest
    static void testCalculateDriveShiftsMetadata_mobileConfig_usesMobileLunchBreakDuration() {
        Map<String, sObject> testData = setupBaseDriveData();
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Lunch_Break__c = true;
        collectionOperation.sked_Lunch_Break_Duration_Mobile__c = '30';
        collectionOperation.sked_Lunch_Break_Duration_Fixed_Site__c = '45';
        update collectionOperation;

        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(
            drive, masterData, skedMobileDriveShiftCalculator.mobileConfig());
        Test.stopTest();

        System.assertEquals(30, shiftsMetadata.driveShifts[0].lunchBreakSettings.maximumLunchBreakDuration,
            'The Mobile config must keep reading Lunch Break Duration (Mobile) = 30, unchanged from the shipped 2-argument behavior');
    }

    // ===== WB Fixed Site master data =====

    private static final String ALL_DAYS_OF_WEEK = 'Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday';
    private static final Decimal MOBILE_SETUP_TIME = 41;
    private static final Decimal WB_SETUP_TIME = 72;
    private static final Decimal APH_SETUP_TIME = 93;
    private static final Decimal COLLECTION_OPERATION_SETUP_TIME = 55;

    // testDrive2 sits on testLocation2, whose Operation Type is already Non Integrated WB - the
    // operation type is a formula off the site, so it is asserted rather than assumed.
    private static sked_Drive__c queryWbFixedSiteDrive(Map<String, sObject> testData) {
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive2')).Id);
        System.assertEquals(skedConstants.DRIVE_TYPE_FIXED_SITE, drive.sked_Type_of_Drive__c,
            'Fixture check: testDrive2 must be a Fixed Site drive');
        System.assertEquals(skedConstants.OPERATION_TYPE_WB, drive.sked_Operation_Type__c,
            'Fixture check: testDrive2 must be a Non Integrated WB drive');
        return drive;
    }

    private static sked_Role_Time_Detail__c buildGlobalRoleTimeDetail(String resourceRoleGroup, String driveType,
            String fixedSiteOperationType, Decimal setupTime) {
        return new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Resource_Role_Group__c = resourceRoleGroup,
            sked_Days_of_Week__c = ALL_DAYS_OF_WEEK,
            sked_Drive_Type__c = driveType,
            sked_Mobile_Type__c = 'Inside',
            sked_Fixed_Site_Operation_Type__c = fixedSiteOperationType,
            sked_Setup_Time__c = setupTime
        );
    }

    // Three Staff-roles role-time details competing for the same map key, separated only by drive type
    // and Fixed Site Operation Type - whichever setup time comes back identifies which query ran.
    private static void insertCompetingStaffRoleTimeDetails() {
        insert new List<sked_Role_Time_Detail__c>{
            buildGlobalRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES, skedConstants.DRIVE_TYPE_MOBILE, null, MOBILE_SETUP_TIME),
            buildGlobalRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES, skedConstants.DRIVE_TYPE_FIXED_SITE, skedConstants.OPERATION_TYPE_WB, WB_SETUP_TIME),
            buildGlobalRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES, skedConstants.DRIVE_TYPE_FIXED_SITE, 'Non Integrated APH', APH_SETUP_TIME)
        };
    }

    @isTest
    static void testLoadMasterData_mobileConfig_loadsMobileDriveTypeRoleTimeDetail() {
        Map<String, sObject> testData = setupBaseDriveData();
        insertCompetingStaffRoleTimeDetails();
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        Test.stopTest();

        System.assertEquals(MOBILE_SETUP_TIME,
            masterData.roleGroupTimeDetailMap.get(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES).sked_Setup_Time__c,
            'The shipped 1-argument Mobile path must keep loading the Mobile-drive-type role time detail, not either Fixed Site one');
    }

    // The Global-then-Collection-Operation precedence is the one branch of the role-time merge that no
    // other test in this class reaches - every other fixture inserts Global rows only.
    @isTest
    static void testLoadMasterData_mobileConfig_collectionOperationRoleTimeDetailOverridesGlobal() {
        Map<String, sObject> testData = setupBaseDriveData();
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        insert new List<sked_Role_Time_Detail__c>{
            buildGlobalRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES, skedConstants.DRIVE_TYPE_MOBILE, null, MOBILE_SETUP_TIME),
            new sked_Role_Time_Detail__c(
                sked_Type__c = 'Collection Operation',
                sked_Collection_Operation__c = collectionOperation.Id,
                sked_Resource_Role_Group__c = skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES,
                sked_Days_of_Week__c = ALL_DAYS_OF_WEEK,
                sked_Drive_Type__c = skedConstants.DRIVE_TYPE_MOBILE,
                sked_Mobile_Type__c = 'Inside',
                sked_Setup_Time__c = COLLECTION_OPERATION_SETUP_TIME
            )
        };
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        Test.stopTest();

        System.assertEquals(COLLECTION_OPERATION_SETUP_TIME,
            masterData.roleGroupTimeDetailMap.get(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES).sked_Setup_Time__c,
            'A Collection Operation role time detail must override the Global one for the same role group, not the other way round');
    }

    @isTest
    static void testLoadMasterData_wbConfig_loadsFixedSiteRoleTimeDetailForItsOwnOperationType() {
        Map<String, sObject> testData = setupBaseDriveData();
        insertCompetingStaffRoleTimeDetails();
        sked_Drive__c drive = queryWbFixedSiteDrive(testData);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(
            drive, skedMobileDriveShiftCalculator.wbFixedSiteConfig());
        Test.stopTest();

        System.assertEquals(WB_SETUP_TIME,
            masterData.roleGroupTimeDetailMap.get(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES).sked_Setup_Time__c,
            'A WB drive must load the Fixed Site role time detail matching its own operation type, not the Mobile one (41) and not the Non Integrated APH one (93)');
    }

    // helper.js:696-698 skips a Fixed Site role time detail whose Fixed Site Operation Type is set to
    // anything other than the drive's own, leaving that role group with no entry at all.
    @isTest
    static void testLoadMasterData_wbConfig_excludesRoleTimeDetailForAnotherFixedSiteOperationType() {
        Map<String, sObject> testData = setupBaseDriveData();
        insert buildGlobalRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES,
            skedConstants.DRIVE_TYPE_FIXED_SITE, 'Non Integrated APH', APH_SETUP_TIME);
        sked_Drive__c drive = queryWbFixedSiteDrive(testData);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(
            drive, skedMobileDriveShiftCalculator.wbFixedSiteConfig());
        Test.stopTest();

        System.assert(!masterData.roleGroupTimeDetailMap.containsKey(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES),
            'A Non Integrated APH role time detail must not reach a Non Integrated WB drive at all');
    }

    // The other half of the same filter: a blank Fixed Site Operation Type applies to every Fixed Site
    // operation type, so it must still be loaded for WB.
    @isTest
    static void testLoadMasterData_wbConfig_includesFixedSiteRoleTimeDetailWithBlankOperationType() {
        Map<String, sObject> testData = setupBaseDriveData();
        insert buildGlobalRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES,
            skedConstants.DRIVE_TYPE_FIXED_SITE, null, WB_SETUP_TIME);
        sked_Drive__c drive = queryWbFixedSiteDrive(testData);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(
            drive, skedMobileDriveShiftCalculator.wbFixedSiteConfig());
        Test.stopTest();

        System.assertEquals(WB_SETUP_TIME,
            masterData.roleGroupTimeDetailMap.get(skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES).sked_Setup_Time__c,
            'A Fixed Site role time detail with a blank Fixed Site Operation Type applies to every operation type, WB included');
    }

    // The whole point of the WB master-data variant: the loaded role time detail must actually reach
    // the metadata the engine consumes, not just sit in the master-data map.
    @isTest
    static void testCalculateDriveShiftsMetadata_wbMasterData_usesFixedSiteRoleTimeSetupTime() {
        Map<String, sObject> testData = setupBaseDriveData();
        insertCompetingStaffRoleTimeDetails();
        sked_Drive__c drive = queryWbFixedSiteDrive(testData);
        skedMobileDriveShiftCalculator.ShiftMetadataConfig config = skedMobileDriveShiftCalculator.wbFixedSiteConfig();

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive, config);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(
            drive, masterData, config);
        Test.stopTest();

        System.assertEquals(WB_SETUP_TIME,
            shiftsMetadata.resourceRoleGroupRoleTimeDataMap.get(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES).setupTime,
            'The WB drive\'s Fixed Site setup time of 72 must flow through into the drive-level role time data, not the Mobile role time detail\'s 41');
    }

    @isTest
    static void testLoadMasterData_wbConfig_skipLastAppointmentMatchesFixedSiteDriveType() {
        Map<String, sObject> testData = setupBaseDriveData();
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Skip_Last_Appointment_For__c = skedConstants.DRIVE_TYPE_FIXED_SITE;
        update collectionOperation;
        sked_Drive__c drive = queryWbFixedSiteDrive(testData);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(
            drive, skedMobileDriveShiftCalculator.wbFixedSiteConfig());
        Test.stopTest();

        System.assertEquals(true, masterData.skipLastAppointmentForMobile,
            'A WB drive is a Fixed Site drive, so Skip Last Appointment For = Fixed Site must apply to it (helper.js:86 matches the drive\'s own type)');
    }

    @isTest
    static void testLoadMasterData_mobileConfig_skipLastAppointmentIgnoresFixedSiteDriveType() {
        Map<String, sObject> testData = setupBaseDriveData();
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Skip_Last_Appointment_For__c = skedConstants.DRIVE_TYPE_FIXED_SITE;
        update collectionOperation;
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);

        Test.startTest();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        Test.stopTest();

        System.assertEquals(false, masterData.skipLastAppointmentForMobile,
            'A Mobile drive must not pick up a Fixed-Site-only Skip Last Appointment For setting');
    }
}
