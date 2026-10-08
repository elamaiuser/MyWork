@isTest
private class skedFixedSiteWbDriveRegenEngine_Test {

    @isTest
    static void testClass_implementsSkedDriveRegenEngine_soFactoryOverrideAssignmentCompiles() {
        skedDriveRegenEngine engine = new skedFixedSiteWbDriveRegenEngine();
        System.assertNotEquals(null, engine, 'skedFixedSiteWbDriveRegenEngine must implement skedDriveRegenEngine');
    }

    @isTest
    static void testOnDriveDataChanged_noProjectedRegisteredDonors_leavesContextCompletelyUntouched() {
        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = new sked_Drive__c(sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_FIXED_SITE, sked_Projected_Registered_Donors__c = null);
        ctx.driveShifts.add(new sked_Drive_Shift__c());
        ctx.jobsByShiftId.put(UserInfo.getUserId(), new List<sked__Job__c>{ new sked__Job__c() });

        Test.startTest();
        new skedFixedSiteWbDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        System.assertEquals(1, ctx.driveShifts.size(), 'A drive with no projected registered donors must leave ctx.driveShifts untouched');
        System.assertEquals(1, ctx.jobsByShiftId.size(), 'A drive with no projected registered donors must leave ctx.jobsByShiftId untouched');
        System.assertEquals(null, ctx.drive.sked_Contention_Resolution__c, 'The entry gate must return before resetElectContentions ever runs');
    }

    // ===== Capstone orchestration tests =====
    //
    // testDrive2/testLocation2 default to Fixed Site + Non Integrated WB (testLocation2's
    // Operation_Type__c) - see reference_fixed_site_test_fixture_gotchas.md. setupCommonTestData
    // already links testCollectionOperation1 to a Mobile-record-type Staffing Decision Matrix
    // (VP/HH 2.2, Charge 1.1, 2RBC 1.6, Charge Threshold 36) - WB's own Fetch reads Mobile's SDM pool
    // (wb:286-288), so no extra matrix setup is needed to exercise real role-quantity math.

    private static sked_Drive__c setupWbDrive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');

        update new sked_Drive__c(
            Id = rawDrive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(13, 0, 0, 0),
            sked_Number_of_2RBC_Assets__c = 2
        );

        sked_Drive__c drive = [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Collection_Operation__c,
                sked_Site_Collection_Operation__c, sked_Projected_Registered_Donors__c, sked_Operation_Type__c, sked_Type_of_Drive__c
            FROM sked_Drive__c
            WHERE Id = :rawDrive.Id
        ];
        // Fixture check: a factory-data change that stops producing a WB drive must fail this test
        // loudly rather than leave every other assertion below silently non-discriminating.
        System.assertEquals(skedConstants.OPERATION_TYPE_WB, drive.sked_Operation_Type__c,
            'Fixture must be a Fixed Site WB drive - testLocation2 supplies the WB operation type');
        return drive;
    }

    private static skedDriveRegenContext buildContext(sked_Drive__c drive) {
        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = new sked_Drive__c(
            Id = drive.Id,
            sked_Drive_Date__c = drive.sked_Drive_Date__c,
            sked_Start_Time__c = drive.sked_Start_Time__c,
            sked_End_Time__c = drive.sked_End_Time__c,
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c,
            sked_Site_Collection_Operation__c = drive.sked_Site_Collection_Operation__c,
            sked_Projected_Registered_Donors__c = drive.sked_Projected_Registered_Donors__c
        );
        ctx.snapshot = ctx.deepClone();
        return ctx;
    }

    private static void runEngine(skedDriveRegenContext ctx) {
        new skedFixedSiteWbDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
    }

    private static sked_Drive_Shift__c insertExistingShift(Id driveId, Time startTime) {
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = driveId, sked_Start_Time__c = startTime);
        insert shift;
        return shift;
    }

    private static List<sked__Job__c> allJobs(skedDriveRegenContext ctx) {
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        for (List<sked__Job__c> shiftJobs : ctx.jobsByShiftId.values()) {
            jobs.addAll(shiftJobs);
        }
        return jobs;
    }

    private static sked__Job__c findJobByRole(List<sked__Job__c> jobs, String role) {
        for (sked__Job__c job : jobs) {
            if (job.sked_Resource_Role__c == role) {
                return job;
            }
        }
        return null;
    }

    private static sked__Job__c findVolunteerJob(List<sked__Job__c> jobs) {
        for (sked__Job__c job : jobs) {
            if (job.sked_Volunteer_Role__c == skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR) {
                return job;
            }
        }
        return null;
    }

    @isTest
    static void testOnDriveDataChanged_wbDrive_buildsRoleAndVolunteerJobsWithNoVehicleAndNoDualRole() {
        sked_Drive__c drive = setupWbDrive();
        insertExistingShift(drive.Id, Time.newInstance(8, 0, 0, 0));
        skedDriveRegenContext ctx = buildContext(drive);

        Test.startTest();
        runEngine(ctx);
        Test.stopTest();

        List<sked__Job__c> jobs = allJobs(ctx);
        System.assert(!jobs.isEmpty(), 'The regen must produce at least one job');
        System.assertNotEquals(null, findJobByRole(jobs, '2RBC'), 'A positive Number_of_2RBC_Assets__c must produce a 2RBC role job');

        for (sked__Job__c job : jobs) {
            System.assertNotEquals(skedConstants.ASSET_TYPE_VEHICLE, job.sked_Asset_Type__c, 'WB must never produce a vehicle asset job');
            System.assert(String.isBlank(job.sked_Dual_Role__c), 'WB has no dual roles - no job may carry a dualRole value');
        }

        sked__Job__c volunteerJob = findVolunteerJob(jobs);
        System.assertNotEquals(null, volunteerJob,
            'testDrive2\'s 100 projected registered donors must match the deployed 70-Above Volunteer_Staffing_Matrix__mdt band');
        System.assertEquals(2, volunteerJob.sked_Redcross_Volunteer_Quantity__c, 'The 70-Above band deploys Volunteer_Quantity__c = 2');
        System.assertNotEquals(null, ctx.drive.sked_Staff_Capacity__c, 'sked_Staff_Capacity__c must be written, not left null');
    }

    // ===== Critical regression: WB's own capacity role list, not Mobile's =====
    //
    // skedFixedSiteWbDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts deliberately keeps a
    // legacy Driver job alive (WB_SYSTEM_ROLES excludes Driver), and skedMobileDriveJobBuilder.
    // updateDriveStaffCapacity is hardcoded to Mobile's role list, which WOULD count it -
    // skedFixedSiteWbRoleQuantityCalc_Test already proved this discriminates (26 vs 59 on the same
    // jobs). Run the same drive twice, before/after inserting the legacy job, rather than asserting an
    // absolute number - this proves the engine's own capacity write is unaffected without needing to
    // hand-replicate its internal arithmetic.

    private static sked__Job__c insertLegacyDriverJob(Id driveShiftId) {
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        sked__Job__c job = new sked__Job__c(
            sked_Drive_Shift__c = driveShiftId,
            sked_Resource_Role__c = 'Driver',
            sked__Quantity__c = 50,
            sked_System_Quantity__c = 50,
            sked_Is_Manually_Created__c = true,
            sked_Manually_Created_From__c = 'Drive Scheduling',
            sked__Region__c = regionId,
            sked__Duration__c = 60
        );
        insert job;
        return job;
    }

    @isTest
    static void testOnDriveDataChanged_legacyDriverJobSurvivesButDoesNotInflateStaffCapacity() {
        sked_Drive__c drive = setupWbDrive();
        sked_Drive_Shift__c existingShift = insertExistingShift(drive.Id, Time.newInstance(8, 0, 0, 0));

        Test.startTest();
        skedDriveRegenContext baselineCtx = buildContext(drive);
        runEngine(baselineCtx);
        Decimal baselineCapacity = baselineCtx.drive.sked_Staff_Capacity__c;

        insertLegacyDriverJob(existingShift.Id);
        skedDriveRegenContext ctxWithLegacyDriver = buildContext(drive);
        runEngine(ctxWithLegacyDriver);
        Test.stopTest();

        List<sked__Job__c> jobsWithLegacyDriver = allJobs(ctxWithLegacyDriver);
        sked__Job__c driverJob = findJobByRole(jobsWithLegacyDriver, 'Driver');
        System.assertNotEquals(null, driverJob, 'A legacy Driver job must survive the regen (WB_SYSTEM_ROLES excludes Driver, so it is treated as manually created)');
        System.assertEquals(baselineCapacity, ctxWithLegacyDriver.drive.sked_Staff_Capacity__c,
            'sked_Staff_Capacity__c must be computed from WB\'s own role list (2RBC/VP-HH/Charge only) - a surviving legacy Driver job must not inflate it, '
            + 'unlike Mobile\'s shared updateDriveStaffCapacity which would count it: baseline=' + baselineCapacity + ', withDriver=' + ctxWithLegacyDriver.drive.sked_Staff_Capacity__c);
    }

    // ===== WB's lunch-break role list must reach TIMING, not just slot reduction =====
    //
    // skedFixedSiteWbDriveJobBuilder.recalculateLunchBreakForAllShifts threads WB_STAFF_SETUP_ROLES
    // (2RBC/VP-HH/Charge) into the SAME headcount that selects the Lunch_Break_Definition__c bucket
    // for sked_Lunch_Break_Duration__c/Start_Time__c/End_Time__c - not just sked_Slot_Reduction__c.
    // A legacy Driver job (quantity 50) would push Mobile's headcount into the high bucket; WB's own
    // list must keep the shift in the low bucket regardless of that job's survival.

    private static void enableLunchBreak(Id collectionOperationId) {
        update new Biomed_Collection_Op_Center__c(
            Id = collectionOperationId,
            sked_Lunch_Break__c = true,
            sked_Lunch_Break_Before_Draw_Hours__c = false
        );
    }

    private static void insertLunchBreakBuckets() {
        // '30' matches skedTestDataFactory's default sked_Lunch_Break_Duration_Fixed_Site__c picklist
        // value on testCollectionOperation1 - findLunchBreakSetting matches on that string.
        // Bands widened to 0-20/21-1000 (from 0-5/6-100) - WB's own real staff setup (~9, from this
        // fixture's SDM/donor defaults) and a Driver-inflated one (~59) must land on opposite sides,
        // or this test can't discriminate the bug it exists to catch regardless of its own expected value.
        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = '30');
        insert setting;
        insert new List<sked_Lunch_Break_Definition__c>{
            new sked_Lunch_Break_Definition__c(
                sked_Lunch_Break_Setting__c = setting.Id, sked_Min_Number_of_Staff__c = 0, sked_Max_Number_of_Staff__c = 20,
                sked_Lunch_Break_Duration__c = 15, sked_Slot_Reduction__c = 10),
            new sked_Lunch_Break_Definition__c(
                sked_Lunch_Break_Setting__c = setting.Id, sked_Min_Number_of_Staff__c = 21, sked_Max_Number_of_Staff__c = 1000,
                sked_Lunch_Break_Duration__c = 45, sked_Slot_Reduction__c = 50)
        };
    }

    @isTest
    static void testOnDriveDataChanged_legacyDriverJob_doesNotPushLunchBreakIntoMobilesHighStaffBucket() {
        sked_Drive__c drive = setupWbDrive();
        // calculateDriveShiftLunchBreakSettings only turns lunch break on when the shift is at least
        // 360 minutes long (skedRoleTimeCalculator.cls:327) - setupWbDrive's default 8:00-13:00 window
        // is only 300 minutes, so widen it here rather than in the shared helper every other test uses.
        update new sked_Drive__c(Id = drive.Id, sked_Start_Time__c = Time.newInstance(7, 0, 0, 0), sked_End_Time__c = Time.newInstance(14, 0, 0, 0));
        drive.sked_Start_Time__c = Time.newInstance(7, 0, 0, 0);
        drive.sked_End_Time__c = Time.newInstance(14, 0, 0, 0);
        enableLunchBreak(drive.sked_Collection_Operation__c);
        insertLunchBreakBuckets();
        sked_Drive_Shift__c existingShift = insertExistingShift(drive.Id, Time.newInstance(7, 0, 0, 0));
        insertLegacyDriverJob(existingShift.Id);

        skedDriveRegenContext ctx = buildContext(drive);

        Test.startTest();
        runEngine(ctx);
        Test.stopTest();

        sked_Drive_Shift__c resultShift = ctx.driveShifts[0];
        System.assertEquals(existingShift.Id, resultShift.Id, 'The single existing shift must be paired by position with the single proposed shift');
        System.assertEquals(true, resultShift.sked_Lunch_Break__c, 'Lunch break must be on for this shift once the Collection Operation enables it');
        System.assertEquals(15, resultShift.sked_Lunch_Break_Duration__c,
            'A surviving legacy Driver job (quantity 50) must not count toward the lunch-break staff-count bucket - '
            + 'WB_STAFF_SETUP_ROLES (2RBC/VP-HH/Charge) must reach TIMING, not just slot reduction. Got: ' + resultShift.sked_Lunch_Break_Duration__c);
    }
}
