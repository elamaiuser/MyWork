@isTest
private class skedFixedSiteDriveRegenEngine_Test {
    // Carried over from the walking-skeleton plan's original no-op test, renamed and re-justified now
    // that the engine does real work: this drive has no sked_Start_Time__c/sked_End_Time__c, so the
    // entry gate returns before any calculator or DB query runs - it no longer passes because "no
    // calculators exist yet" (they do), but because this specific input never reaches them.
    @isTest
    static void testOnDriveDataChanged_driveWithNoDates_entryGateShortCircuitsBeforeAnyCalculatorRuns() {
        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = new sked_Drive__c(sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_FIXED_SITE);
        ctx.driveShifts.add(new sked_Drive_Shift__c());

        Test.startTest();
        new skedFixedSiteDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        System.assertEquals(skedConstants.DRIVE_TYPE_FIXED_SITE, ctx.drive.sked_Type_of_Drive__c,
            'A drive missing sked_Start_Time__c/sked_End_Time__c must hit the entry gate and leave ctx.drive untouched');
        System.assertEquals(1, ctx.driveShifts.size(),
            'A drive missing sked_Start_Time__c/sked_End_Time__c must hit the entry gate and leave ctx.driveShifts untouched');
    }

    @isTest
    static void testClass_implementsSkedDriveRegenEngine_soFactoryOverrideAssignmentCompiles() {
        skedDriveRegenEngine engine = new skedFixedSiteDriveRegenEngine();
        System.assertNotEquals(null, engine, 'skedFixedSiteDriveRegenEngine must implement skedDriveRegenEngine');
    }

    // ===== Capstone orchestration tests =====
    //
    // Rely on skedTestDataFactory's default lunch-break-off Collection Operation (testCollectionOperation1
    // never sets sked_Lunch_Break__c, defaulting false) so populateLunchBreakTime's positive path -
    // which deliberately NPEs when no matching Lunch Break Setting/Definition covers the computed
    // staff count - is never exercised here. Also rely on setupCommonTestData's already-seeded WB/
    // Platelet/2RBC/Plasma sked_Fixed_Site_Procedure_Projection__c rows (all Account-scoped, QNS/
    // Deferral well under 100%) and the Fixed Site Staffing Decision Matrix already linked to
    // testCollectionOperation1 - neither needs to be built fresh in these tests.

    private static skedDriveRegenContext buildContext(sked_Drive__c drive) {
        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = new sked_Drive__c(
            Id = drive.Id,
            sked_Drive_Date__c = drive.sked_Drive_Date__c,
            sked_Start_Time__c = drive.sked_Start_Time__c,
            sked_End_Time__c = drive.sked_End_Time__c,
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c,
            sked_Site_Collection_Operation__c = drive.sked_Site_Collection_Operation__c
        );
        ctx.snapshot = ctx.deepClone();
        return ctx;
    }

    private static sked_Drive__c queryDriveForContext(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Collection_Operation__c, sked_Site_Collection_Operation__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    // sked_Operation_Type__c is a formula field on Drive derived from its Site's Operation_Type__c -
    // see reference_fixed_site_test_fixture_gotchas.md - so it can only change by updating the Site,
    // and the Drive must be off Draft status while that happens.
    private static void setOperationType(sked_Drive__c drive, sked__Location__c site, String operationType) {
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
        update drive;
        site.Operation_Type__c = operationType;
        update site;
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        update drive;
    }

    private static sked_Drive_Shift__c insertExistingShift(Id driveId, Time startTime) {
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = driveId, sked_Start_Time__c = startTime);
        insert shift;
        return shift;
    }

    private static sked__Job__c findJobByRole(List<sked__Job__c> jobs, String role) {
        for (sked__Job__c job : jobs) {
            if (job.sked_Resource_Role__c == role) {
                return job;
            }
        }
        return null;
    }

    private static sked__Job__c findAssetJob(List<sked__Job__c> jobs, String assetType) {
        for (sked__Job__c job : jobs) {
            if (job.sked_Asset_Type__c == assetType) {
                return job;
            }
        }
        return null;
    }

    private static Set<String> collectSlotTypes(List<sked__Slot__c> slots) {
        Set<String> types = new Set<String>();
        for (sked__Slot__c slot : slots) {
            types.add(slot.sked_Type__c);
        }
        return types;
    }

    @isTest
    static void testOnDriveDataChanged_integratedDrive_buildsJobsAndAllFourSlotTypesStampedWithRealShiftId() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        setOperationType(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);

        update new sked_Drive__c(
            Id = rawDrive.Id,
            sked_Platelet_Projected_Procedures__c = 20,
            sked_Number_of_Vehicles__c = 3,
            sked_Number_of_2RBC_Assets__c = 2,
            sked_Number_of_Platelet_Assets__c = 2,
            sked_Number_of_Plasma_Assets__c = 2
        );

        // Neither testOpportunity3 (linked to testDrive2) nor the org defaults set a WB slot padding
        // percentage - without one, generateWbSlots' totalSlots collapses to 0 regardless of demand.
        sked_Admin_Setting__c adminSetting = sked_Admin_Setting__c.getOrgDefaults();
        adminSetting.Admin_Call_List_Recipient_None_FS__c = 100;
        upsert adminSetting;

        // testDrive2's default 10-hour window (07:00-17:00) splits into 2 drive shifts - pre-insert 2
        // existing shifts (ordered by start time) so applyExistingRecordIds has real Ids to pair
        // against; Fixed Site pairs shifts by array position only, never by time-range matching.
        insertExistingShift(rawDrive.Id, Time.newInstance(7, 0, 0, 0));
        insertExistingShift(rawDrive.Id, Time.newInstance(13, 0, 0, 0));

        skedDriveRegenContext ctx = buildContext(queryDriveForContext(rawDrive.Id));

        Test.startTest();
        new skedFixedSiteDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        System.assertEquals(2, ctx.driveShifts.size(), 'The 10-hour window must still produce 2 drive shifts');
        sked_Drive_Shift__c firstShift = ctx.driveShifts[0];
        System.assertNotEquals(null, firstShift.Id, 'The first proposed shift must be paired with a real existing shift Id');

        List<sked__Job__c> firstShiftJobs = ctx.jobsByShiftId.get(firstShift.Id);
        System.assertNotEquals(null, findJobByRole(firstShiftJobs, 'Apheresis'), 'A positive Platelet-driven Apheresis quantity must produce a role job on the first shift');
        System.assertNotEquals(null, findJobByRole(firstShiftJobs, 'Apheresis Charge'), 'Apheresis Charge is always exactly 1 and must be built');
        System.assertNotEquals(null, findAssetJob(firstShiftJobs, skedConstants.ASSET_TYPE_VEHICLE), 'The first shift must get a Vehicle job');
        System.assertNotEquals(null, findAssetJob(firstShiftJobs, skedConstants.ASSET_TYPE_EQUIPMENT), 'The first shift must get an Equipment job when Integrated');

        List<sked__Slot__c> firstShiftSlots = ctx.slotsByShiftId.get(firstShift.Id);
        for (sked__Slot__c slot : firstShiftSlots) {
            System.assertEquals(firstShift.Id, slot.sked_Drive_Shift__c, 'Every slot must be stamped with the real shift Id once it is resolved');
        }
        Set<String> slotTypes = collectSlotTypes(firstShiftSlots);
        System.assert(slotTypes.contains(skedConstants.PROCEDURE_TYPE_PLATELET), 'An Integrated drive must generate Platelet slots');
        System.assert(slotTypes.contains('Whole Blood'), 'An Integrated drive must generate Whole Blood slots');
        System.assert(slotTypes.contains(skedConstants.PROCEDURE_TYPE_2RBC), 'An Integrated drive must generate 2RBC slots');
        System.assert(slotTypes.contains(skedConstants.PROCEDURE_TYPE_PLASMA), 'An Integrated drive must generate Plasma slots');

        // applyToContext's drive-level totals - a deliberate addition beyond the task brief's own
        // draft (see task-1-report.md) - must reflect the freshly computed shift/slot data, not be
        // left at their prior (here, unset/null) value.
        Integer totalSlotsAcrossBothShifts = 0;
        for (List<sked__Slot__c> slots : ctx.slotsByShiftId.values()) {
            totalSlotsAcrossBothShifts += slots.size();
        }
        System.assertEquals(totalSlotsAcrossBothShifts, ctx.drive.sked_Total_Slots__c, 'sked_Total_Slots__c must equal the summed slot count across every shift');
        System.assert(ctx.drive.sked_Total_Slots__c > 0, 'sked_Total_Slots__c must be positive given this drive\'s slot-generating setup');
        System.assertNotEquals(null, ctx.drive.sked_Total_Procedures_Projected__c, 'sked_Total_Procedures_Projected__c must be written from shiftsMetadata, not left null');
        System.assert(ctx.drive.sked_Total_Procedures_Projected__c > 0, 'sked_Total_Procedures_Projected__c must be positive given this drive\'s positive projected-procedure inputs');
        System.assertNotEquals(null, ctx.drive.sked_Total_Products_Projected__c, 'sked_Total_Products_Projected__c must be written from shiftsMetadata, not left null');
    }

    @isTest
    static void testOnDriveDataChanged_nonIntegratedAphDrive_producesOnlyPlateletAndPlasmaSlots() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        setOperationType(rawDrive, site, skedConstants.OPERATION_TYPE_APH);

        // Number_of_2RBC_Assets and the WB slot-padding percentage are ALSO set here, matching test
        // (a)'s Integrated setup exactly - if either were missing, zero WB/2RBC slots would prove
        // nothing about the isIntegrated gate (they'd be zero anyway, for an unrelated reason: no
        // assets, or zero padding). Setting both makes the two negative assertions below actually
        // discriminate on operation type, not on absent inputs.
        update new sked_Drive__c(
            Id = rawDrive.Id,
            sked_Number_of_Platelet_Assets__c = 2,
            sked_Number_of_Plasma_Assets__c = 2,
            sked_Number_of_2RBC_Assets__c = 2
        );
        sked_Admin_Setting__c adminSetting = sked_Admin_Setting__c.getOrgDefaults();
        adminSetting.Admin_Call_List_Recipient_None_FS__c = 100;
        upsert adminSetting;

        insertExistingShift(rawDrive.Id, Time.newInstance(7, 0, 0, 0));
        insertExistingShift(rawDrive.Id, Time.newInstance(13, 0, 0, 0));

        skedDriveRegenContext ctx = buildContext(queryDriveForContext(rawDrive.Id));

        Test.startTest();
        new skedFixedSiteDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        Set<String> allSlotTypes = new Set<String>();
        for (List<sked__Slot__c> slots : ctx.slotsByShiftId.values()) {
            allSlotTypes.addAll(collectSlotTypes(slots));
        }
        System.assert(allSlotTypes.contains(skedConstants.PROCEDURE_TYPE_PLATELET), 'A Non-Integrated-APH drive must still generate Platelet slots');
        System.assert(allSlotTypes.contains(skedConstants.PROCEDURE_TYPE_PLASMA), 'A Non-Integrated-APH drive must still generate Plasma slots');
        System.assert(!allSlotTypes.contains('Whole Blood'), 'A Non-Integrated-APH drive must generate zero Whole Blood slots');
        System.assert(!allSlotTypes.contains(skedConstants.PROCEDURE_TYPE_2RBC), 'A Non-Integrated-APH drive must generate zero 2RBC slots');
    }

    @isTest
    static void testOnDriveDataChanged_missingStartOrEndTime_leavesContextCompletelyUntouched() {
        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = new sked_Drive__c(sked_Drive_Date__c = Date.today(), sked_Start_Time__c = null, sked_End_Time__c = Time.newInstance(17, 0, 0, 0));
        ctx.driveShifts.add(new sked_Drive_Shift__c());
        ctx.jobsByShiftId.put(UserInfo.getUserId(), new List<sked__Job__c>{ new sked__Job__c() });

        Test.startTest();
        new skedFixedSiteDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(1, ctx.driveShifts.size(), 'A drive missing sked_Start_Time__c must leave ctx.driveShifts completely untouched');
        System.assertEquals(1, ctx.jobsByShiftId.size(), 'A drive missing sked_Start_Time__c must leave ctx.jobsByShiftId completely untouched');
        System.assertEquals(null, ctx.drive.sked_Contention_Resolution__c, 'The entry gate must return before resetElectContentions ever runs');
    }

    @isTest
    static void testOnDriveDataChanged_existingManuallyCreatedJobOutsideSystemRoles_survivesRegen() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        // A 3-hour window is exactly 1 Platelet round, producing exactly 1 drive shift - avoids any
        // ambiguity in array-position pairing for this single-shift assertion.
        update new sked_Drive__c(Id = rawDrive.Id, sked_Start_Time__c = Time.newInstance(7, 0, 0, 0), sked_End_Time__c = Time.newInstance(10, 0, 0, 0));

        sked_Drive_Shift__c existingShift = insertExistingShift(rawDrive.Id, Time.newInstance(7, 0, 0, 0));
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        insert new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id,
            // 'Translator' is a real sked_Resource_Roles value outside skedFixedSiteDriveJobBuilder's
            // FIXED_SITE_SYSTEM_ROLES set ({'Apheresis','Apheresis Charge'}), so isManuallyCreatedJob
            // detects it as manually-created even without the flag - this test sets the flag anyway
            // for realism, matching how a real Drive Scheduling edit would look.
            sked_Resource_Role__c = 'Translator',
            sked__Quantity__c = 1,
            sked_System_Quantity__c = 1,
            sked_Is_Manually_Created__c = true,
            sked_Manually_Created_From__c = 'Drive Scheduling',
            sked__Region__c = regionId,
            sked__Duration__c = 60
        );

        skedDriveRegenContext ctx = buildContext(queryDriveForContext(rawDrive.Id));

        Test.startTest();
        new skedFixedSiteDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        System.assertEquals(1, ctx.driveShifts.size(), 'A 3-hour window (1 round) must produce exactly 1 drive shift');
        System.assertEquals(existingShift.Id, ctx.driveShifts[0].Id, 'The single existing shift must be paired by position with the single proposed shift');
        sked__Job__c translatorJob = findJobByRole(ctx.jobsByShiftId.get(existingShift.Id), 'Translator');
        System.assertNotEquals(null, translatorJob, 'A manually-created job whose role is outside the Fixed Site system role set must survive the regen');
        System.assertEquals(true, translatorJob.sked_Is_Manually_Created__c, 'The carried-forward job must still be flagged manually created');
    }

    // Direct negative test for the isIntegrated/isNonIntegratedAph gate: testDrive2/testLocation2
    // default to Site.Operation_Type__c = 'Non Integrated WB' (skedConstants.OPERATION_TYPE_WB), which
    // is neither OPERATION_TYPE_INTEGRATED nor OPERATION_TYPE_APH - the JS's own empty if/else-if
    // fallthrough. Assets and padding are set exactly as in the Integrated/APH tests so a zero result
    // proves the gate, not an absent-input coincidence.
    @isTest
    static void testOnDriveDataChanged_blankOperationType_producesZeroSlotsOfEveryType() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');

        update new sked_Drive__c(
            Id = rawDrive.Id,
            sked_Number_of_Platelet_Assets__c = 2,
            sked_Number_of_Plasma_Assets__c = 2,
            sked_Number_of_2RBC_Assets__c = 2
        );
        sked_Admin_Setting__c adminSetting = sked_Admin_Setting__c.getOrgDefaults();
        adminSetting.Admin_Call_List_Recipient_None_FS__c = 100;
        upsert adminSetting;

        insertExistingShift(rawDrive.Id, Time.newInstance(7, 0, 0, 0));
        insertExistingShift(rawDrive.Id, Time.newInstance(13, 0, 0, 0));

        skedDriveRegenContext ctx = buildContext(queryDriveForContext(rawDrive.Id));

        Test.startTest();
        new skedFixedSiteDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        Integer totalSlotCount = 0;
        for (List<sked__Slot__c> slots : ctx.slotsByShiftId.values()) {
            totalSlotCount += slots.size();
        }
        System.assertEquals(0, totalSlotCount,
            'A drive whose operation type is neither Integrated nor Non-Integrated-APH must produce zero slots of every type');
    }

    private static Integer countWbSlots(skedDriveRegenContext ctx, Id shiftId) {
        Integer wbCount = 0;
        for (sked__Slot__c slot : ctx.slotsByShiftId.get(shiftId)) {
            if (slot.sked_Type__c == 'Whole Blood') {
                wbCount++;
            }
        }
        return wbCount;
    }

    // Regression guard for the Critical fix: reduceWbSlotsForLunchBreak mutates its list argument in
    // place, so the WB slots that reach ctx must actually shrink when a real lunch break with a
    // matching Setting/Definition applies - not merely leave sked_Sign_Up_Reduction__c looking correct
    // while every slot still books straight through. Runs the same drive through the engine twice
    // (lunch break off, then on) in one Test.startTest/stopTest pair - onDriveDataChanged does no DML
    // of its own, so the second call safely re-reads the freshly toggled Collection Operation.
    @isTest
    static void testOnDriveDataChanged_lunchBreakOn_reducesWbSlotCountBelowLunchBreakOffBaseline() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        setOperationType(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);

        // A single 6-hour shift (2 Platelet rounds, still only 1 drive shift) keeps the lunch-break
        // math and existing-shift pairing simple.
        update new sked_Drive__c(
            Id = rawDrive.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(13, 0, 0, 0),
            sked_Number_of_2RBC_Assets__c = 2
        );
        sked_Admin_Setting__c adminSetting = sked_Admin_Setting__c.getOrgDefaults();
        adminSetting.Admin_Call_List_Recipient_None_FS__c = 100;
        upsert adminSetting;
        sked_Drive_Shift__c existingShift = insertExistingShift(rawDrive.Id, Time.newInstance(7, 0, 0, 0));
        sked_Drive__c drive = queryDriveForContext(rawDrive.Id);

        Test.startTest();
        Integer wbSlotCountLunchBreakOff = countWbSlots(buildContextAndRunEngine(drive), existingShift.Id);

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        update new Biomed_Collection_Op_Center__c(Id = collectionOperation.Id, sked_Lunch_Break__c = true, sked_Lunch_Break_Before_Draw_Hours__c = false);
        // sked_Maximum_Lunch_Break_Duration__c ('30') only has to match the CO's own
        // sked_Lunch_Break_Duration_Fixed_Site__c picklist default ('30') for findLunchBreakSetting's
        // lookup - the actual window width used to compute lunchStart/lunchEnd comes from this
        // Definition's own sked_Lunch_Break_Duration__c, set here to 180 (the validation rule's own
        // cap) so the window covers several generated WB slots unambiguously, regardless of exactly
        // where they land relative to the Platelet-round excluded time ranges.
        sked_Lunch_Break_Setting__c lunchBreakSetting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = '30');
        insert lunchBreakSetting;
        insert new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Setting__c = lunchBreakSetting.Id,
            sked_Min_Number_of_Staff__c = 0,
            sked_Max_Number_of_Staff__c = 10,
            sked_Lunch_Break_Duration__c = 180,
            sked_Slot_Reduction__c = 50
        );

        Integer wbSlotCountLunchBreakOn = countWbSlots(buildContextAndRunEngine(drive), existingShift.Id);
        Test.stopTest();

        System.assert(wbSlotCountLunchBreakOn < wbSlotCountLunchBreakOff,
            'A lunch break with a real matching Setting/Definition must shrink the WB slot count that reaches ctx, not just claim a reduction via sked_Sign_Up_Reduction__c: off='
            + wbSlotCountLunchBreakOff + ', on=' + wbSlotCountLunchBreakOn);
        System.assert(wbSlotCountLunchBreakOn > 0, 'The reduction must not wipe out every WB slot - some must remain');
    }

    private static skedDriveRegenContext buildContextAndRunEngine(sked_Drive__c drive) {
        skedDriveRegenContext ctx = buildContext(drive);
        new skedFixedSiteDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        return ctx;
    }
}
