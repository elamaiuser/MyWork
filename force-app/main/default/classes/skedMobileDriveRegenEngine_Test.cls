@isTest
private class skedMobileDriveRegenEngine_Test {

    // Mirrors skedMobileSlotGenerator_Test.setupDrive - the established pattern for a drive that
    // always proposes exactly 1 drive shift (10hr draw hours, 700min max shift length threshold),
    // with padding percentage pinned to a safe, deterministic value.
    private static sked_Drive__c setupDrive() {
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

        setAdminSettingCapacities(115, 130);
        Opportunity opp = new Opportunity(Id = testDrive1.sked_Opportunity__c, Call_List_Recipient_Exist__c = true, Slot_Generator__c = null);
        update opp;

        return testDrive1;
    }

    private static void setAdminSettingCapacities(Decimal callListRecipient, Decimal callListRecipientNone) {
        sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
        setting.sked_Admin_Call_List_Recipient__c = callListRecipient;
        setting.sked_Admin_Call_List_Recipient_None__c = callListRecipientNone;
        upsert setting;
    }

    @isTest
    static void testOnDriveDataChanged_singleExistingShift_buildsJobsAndSlotsKeyedByExistingShiftId() {
        sked_Drive__c testDrive1 = setupDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(testDrive1.Id);

        Test.startTest();
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        System.assertEquals(1, ctx.driveShifts.size(), 'Exactly 1 shift is proposed for this drive setup');
        System.assertEquals(existingShift.Id, ctx.driveShifts[0].Id, 'The proposed shift must carry forward the single existing shift\'s real Id');

        List<sked__Job__c> jobs = ctx.jobsByShiftId.get(existingShift.Id);
        System.assertNotEquals(null, jobs, 'Jobs must be keyed by the existing shift\'s real Id, not left unkeyed/null');
        Boolean hasDriverJob = false;
        for (sked__Job__c job : jobs) {
            System.assertEquals(existingShift.Id, job.sked_Drive_Shift__c, 'Every job must be stamped with its shift\'s real Id before save() runs');
            if (job.sked_Resource_Role__c == 'Driver') {
                hasDriverJob = true;
            }
        }
        System.assert(hasDriverJob, 'A 2-vehicle drive must propose Driver jobs');

        List<sked__Slot__c> slots = ctx.slotsByShiftId.get(existingShift.Id);
        System.assertNotEquals(null, slots, 'Slots must be keyed by the existing shift\'s real Id');
        for (sked__Slot__c slot : slots) {
            System.assertEquals(existingShift.Id, slot.sked_Drive_Shift__c, 'Every slot must be stamped with its shift\'s real Id before save() runs');
        }

        System.assertNotEquals(null, ctx.drive.sked_Staff_Capacity__c, 'Staff capacity must be computed and copied onto ctx.drive');
        System.assertEquals(50, ctx.drive.sked_Total_Procedures_Projected__c, 'Total procedures projected (30 2RBC + 20 WB) must be copied onto ctx.drive');
        System.assertEquals(slots.size(), ctx.drive.sked_Total_Slots__c, 'Total slots must equal the sum of every shift\'s slot count');
    }

    // A drive with zero existing shifts needs a genuinely new one - shiftRecord.Id stays null
    // (applyExistingRecordIds has nothing to match against), so the new shift's jobs/slots must be
    // routed into jobsByNewShiftIndex/slotsByNewShiftIndex, not jobsByShiftId/slotsByShiftId (which
    // require a real Id key).
    @isTest
    static void testOnDriveDataChanged_noExistingShifts_routesNewShiftJobsAndSlotsByIndex() {
        sked_Drive__c testDrive1 = setupDrive();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(testDrive1.Id);

        Test.startTest();
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        System.assertEquals(1, ctx.driveShifts.size(), 'Exactly 1 new shift is proposed for this drive setup');
        System.assertEquals(null, ctx.driveShifts[0].Id, 'A genuinely new shift must not be assigned a fake Id before save()');
        System.assert(ctx.jobsByShiftId.isEmpty(), 'A new shift has no real Id to key jobsByShiftId by');
        System.assert(ctx.slotsByShiftId.isEmpty(), 'A new shift has no real Id to key slotsByShiftId by');

        List<sked__Job__c> jobs = ctx.jobsByNewShiftIndex.get(0);
        System.assertNotEquals(null, jobs, 'A new shift\'s jobs must be routed into jobsByNewShiftIndex, keyed by its position');
        Boolean hasDriverJob = false;
        for (sked__Job__c job : jobs) {
            System.assertEquals(null, job.sked_Drive_Shift__c, 'A new shift\'s job must not be stamped yet - the shift itself has no real Id until save()');
            if (job.sked_Resource_Role__c == 'Driver') {
                hasDriverJob = true;
            }
        }
        System.assert(hasDriverJob, 'A 2-vehicle drive must propose Driver jobs');

        List<sked__Slot__c> slots = ctx.slotsByNewShiftIndex.get(0);
        System.assert(slots != null && !slots.isEmpty(), 'A new shift\'s slots must be routed into slotsByNewShiftIndex, keyed by its position');

        List<skedDriveShiftTagCalculator.TagResult> tagResults = ctx.tagsByNewShiftIndex.get(0);
        System.assertNotEquals(null, tagResults, 'A new shift\'s computed drive shift tags must be routed into tagsByNewShiftIndex, keyed by its position');
    }

    @isTest
    static void testOnDriveDataChanged_noExistingShifts_thenSave_persistsNewShiftJobsAndSlots() {
        sked_Drive__c testDrive1 = setupDrive();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(testDrive1.Id);

        Test.startTest();
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(ctx);
        Test.stopTest();

        List<sked_Drive_Shift__c> persistedShifts = [SELECT Id FROM sked_Drive_Shift__c WHERE sked_Drive__c = :testDrive1.Id];
        System.assertEquals(1, persistedShifts.size(), 'The genuinely new shift must actually be inserted');

        List<sked__Job__c> persistedJobs = [SELECT Id, sked_Resource_Role__c FROM sked__Job__c WHERE sked_Drive_Shift__c = :persistedShifts[0].Id];
        System.assert(!persistedJobs.isEmpty(), 'The new shift\'s jobs must be persisted, stamped with the new shift\'s real Id');
        Boolean hasDriverJob = false;
        for (sked__Job__c job : persistedJobs) {
            if (job.sked_Resource_Role__c == 'Driver') {
                hasDriverJob = true;
            }
        }
        System.assert(hasDriverJob, 'A 2-vehicle drive must propose Driver jobs');

        List<sked__Slot__c> persistedSlots = [SELECT Id FROM sked__Slot__c WHERE sked_Drive_Shift__c = :persistedShifts[0].Id];
        System.assert(!persistedSlots.isEmpty(), 'The new shift\'s slots must be persisted, stamped with the new shift\'s real Id');

        sked_Drive__c persistedDrive = [SELECT sked_Total_Slots__c FROM sked_Drive__c WHERE Id = :testDrive1.Id];
        System.assertEquals(persistedSlots.size(), persistedDrive.sked_Total_Slots__c,
            'sked_Total_Slots__c must reflect the new shift\'s slot count too');
    }

    @isTest
    static void testOnDriveDataChanged_noExistingShifts_thenSave_persistsNewShiftDriveShiftTags() {
        sked_Drive__c testDrive1 = setupDrive();
        sked__Tag__c tag = new sked__Tag__c(Name = 'Cooler');
        insert tag;
        insert new sked__Account_Tag__c(sked__Account__c = testDrive1.sked_Account__c, sked__Tag__c = tag.Id, sked__Required__c = false, sked_Minimum_Quantity__c = 2);
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(testDrive1.Id);

        Test.startTest();
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(ctx);
        Test.stopTest();

        List<sked_Drive_Shift__c> persistedShifts = [SELECT Id FROM sked_Drive_Shift__c WHERE sked_Drive__c = :testDrive1.Id];
        List<sked_Drive_Shift_Tag__c> persistedTags = [SELECT sked_Tag__c, sked_Minimum_Quantity__c FROM sked_Drive_Shift_Tag__c WHERE sked_Drive_Shift__c = :persistedShifts[0].Id];
        System.assertEquals(1, persistedTags.size(), 'The new shift\'s non-required account tag must be persisted as exactly one sked_Drive_Shift_Tag__c');
        System.assertEquals(tag.Id, persistedTags[0].sked_Tag__c, 'The persisted tag must reference the correct sked__Tag__c');
        System.assertEquals(2, persistedTags[0].sked_Minimum_Quantity__c, 'The persisted tag must carry the account tag\'s minimumQuantity');
    }

    // A CO-change DCR mutates ctx.drive.sked_Collection_Operation__c in memory BEFORE the engine
    // runs (skedDCRApplyService.applyCollectionOperationChange) - nothing is persisted yet, so a
    // fresh re-query by Id (loadDrive) would silently read the OLD, still-persisted CO. This
    // simulates that exact mutation directly on ctx (bypassing the full DCR/apply-service flow, to
    // isolate the engine's own bug) and proves the engine's calculations use the NEW CO - here via
    // its distinct shift-length threshold (400min forces 2 shifts, vs the original CO's 700min/1
    // shift), a direct, observable signal that doesn't depend on inspecting engine-internal state.
    @isTest
    static void testOnDriveDataChanged_ctxDriveCollectionOperationMutatedBeforeCall_usesNewCollectionOperationNotStaleReQuery() {
        sked_Drive__c testDrive1 = setupDrive();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(testDrive1.Id);

        Biomed_Collection_Op_Center__c newCollectionOperation = [
            SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Id != :ctx.drive.sked_Collection_Operation__c LIMIT 1
        ];
        newCollectionOperation.sked_Maximum_Shift_Length_Threshold__c = 400;
        newCollectionOperation.sked_No_Travel_Time__c = false;
        newCollectionOperation.sked_Lunch_Break__c = false;
        update newCollectionOperation;
        ctx.drive.sked_Collection_Operation__c = newCollectionOperation.Id;

        Test.startTest();
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        System.assertEquals(2, ctx.driveShifts.size(),
            'The engine must use the mutated ctx.drive Collection Operation\'s threshold (400min, 2 shifts) - 1 shift would mean it silently re-queried the stale, still-persisted original CO (700min) instead');
    }

    // A falsy projected-donors value must short-circuit before any shift/job/slot generation runs
    // at all. This drive has zero existing shifts on purpose: if the no-op guard didn't fire first,
    // the engine would go on to build a genuinely new shift instead of leaving ctx untouched.
    @isTest
    static void testOnDriveDataChanged_projectedRegisteredDonorsNull_noOpsEntirely() {
        sked_Drive__c testDrive1 = setupDrive();
        testDrive1.sked_Projected_Registered_Donors__c = null;
        update testDrive1;
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(testDrive1.Id);

        Test.startTest();
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        System.assertEquals(0, ctx.driveShifts.size(),
            'A null projectedRegisteredDonors must skip regeneration entirely, leaving ctx exactly as loaded');
    }

    @isTest
    static void testOnDriveDataChanged_projectedRegisteredDonorsZero_noOpsEntirely() {
        sked_Drive__c testDrive1 = setupDrive();
        testDrive1.sked_Projected_Registered_Donors__c = 0;
        update testDrive1;
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(testDrive1.Id);

        Test.startTest();
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        Test.stopTest();

        System.assertEquals(0, ctx.driveShifts.size(),
            'A zero projectedRegisteredDonors must skip regeneration entirely, leaving ctx exactly as loaded');
    }

    @isTest
    static void testOnDriveDataChanged_thenSave_reusesExistingSystemJobAndPersistsSlots() {
        sked_Drive__c testDrive1 = setupDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        sked__Job__c existingDriverJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1,
            sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingDriverJob;

        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(testDrive1.Id);

        Test.startTest();
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(ctx);
        Test.stopTest();

        List<sked__Job__c> persistedJobs = [SELECT Id, sked_Resource_Role__c FROM sked__Job__c WHERE sked_Drive_Shift__c = :existingShift.Id];
        System.assert(!persistedJobs.isEmpty(), 'The regenerated jobs must actually be persisted under the existing shift');
        Boolean existingDriverJobIdReused = false;
        for (sked__Job__c job : persistedJobs) {
            if (job.Id == existingDriverJob.Id) {
                existingDriverJobIdReused = true;
            }
        }
        System.assert(existingDriverJobIdReused,
            'A still-needed system-generated Driver job must be updated in place via applyExistingRecordIds, not deleted and recreated under a new Id');

        // Slots have no carry-forward slice (skedMobileSlotGenerator always builds fresh, by design -
        // see its class header) - every regen fully replaces a shift's slots. Confirming they persist
        // is the point here, not confirming any particular slot Id survives.
        List<sked__Slot__c> persistedSlots = [SELECT Id FROM sked__Slot__c WHERE sked_Drive_Shift__c = :existingShift.Id];
        System.assert(!persistedSlots.isEmpty(), 'The regenerated slots must actually be persisted under the existing shift');

        sked_Drive__c persistedDrive = [SELECT sked_Total_Slots__c FROM sked_Drive__c WHERE Id = :testDrive1.Id];
        System.assertEquals(persistedSlots.size(), persistedDrive.sked_Total_Slots__c,
            'sked_Total_Slots__c is a plain Number field (not a rollup) - it must actually survive save(), not just be set on ctx.drive pre-save');
    }

    // skipVolunteerRecalculation is always true for this pipeline (see the engine's own header), so
    // the quantity here is exactly whatever's already on sked_Redcross_Volunteer_Quantity__c - this
    // test's real point is that a volunteer job now gets BUILT and PERSISTED at all, and that the
    // Volunteer_Setup__c rollup reflects it exactly once (not double-counted alongside anything else).
    @isTest
    static void testOnDriveDataChanged_thenSave_volunteerRequired_buildsAndPersistsVolunteerJobWithSetupRollup() {
        sked_Drive__c testDrive1 = setupDrive();
        testDrive1.sked_Redcross_Volunteer_Required__c = true;
        testDrive1.sked_Redcross_Volunteer_Quantity__c = 5;
        update testDrive1;
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(testDrive1.Id);

        Test.startTest();
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(ctx);
        Test.stopTest();

        List<sked__Job__c> persistedVolunteerJobs = [SELECT Id, sked__Quantity__c FROM sked__Job__c
            WHERE sked_Drive_Shift__c = :existingShift.Id AND sked_Volunteer_Role__c = :skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR];
        System.assertEquals(1, persistedVolunteerJobs.size(), 'Exactly one volunteer job must be persisted, not zero (unwired) or more than one (duplicated)');
        System.assertEquals(5, persistedVolunteerJobs[0].sked__Quantity__c, 'The persisted volunteer job must carry the drive\'s redcross quantity');

        sked_Drive_Shift__c persistedShift = [SELECT sked_Volunteer_Setup__c FROM sked_Drive_Shift__c WHERE Id = :existingShift.Id];
        System.assertEquals(5, persistedShift.sked_Volunteer_Setup__c,
            'Volunteer_Setup__c must equal exactly the one volunteer job\'s quantity - not zero, and not double-counted');
    }

    // Regen+save twice - the second regen's freshly-built volunteer job (Id == null) must match onto
    // the first regen's persisted volunteer job via findMatchingExistingJob's volunteer branch, not
    // duplicate it.
    @isTest
    static void testOnDriveDataChanged_thenSave_secondRegen_volunteerJobNotDuplicated() {
        sked_Drive__c testDrive1 = setupDrive();
        testDrive1.sked_Redcross_Volunteer_Required__c = true;
        testDrive1.sked_Redcross_Volunteer_Quantity__c = 5;
        update testDrive1;
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        skedDriveRegenContext firstCtx = skedDriveRegenContextLoader.load(testDrive1.Id);
        new skedMobileDriveRegenEngine().onDriveDataChanged(firstCtx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(firstCtx);

        List<sked__Job__c> firstVolunteerJobs = [SELECT Id FROM sked__Job__c
            WHERE sked_Drive_Shift__c = :existingShift.Id AND sked_Volunteer_Role__c = :skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR];
        System.assertEquals(1, firstVolunteerJobs.size(), 'Setup check: the first regen must persist exactly one volunteer job');

        Test.startTest();
        skedDriveRegenContext secondCtx = skedDriveRegenContextLoader.load(testDrive1.Id);
        new skedMobileDriveRegenEngine().onDriveDataChanged(secondCtx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(secondCtx);
        Test.stopTest();

        List<sked__Job__c> secondVolunteerJobs = [SELECT Id FROM sked__Job__c
            WHERE sked_Drive_Shift__c = :existingShift.Id AND sked_Volunteer_Role__c = :skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR];
        System.assertEquals(1, secondVolunteerJobs.size(), 'The second regen must still persist exactly one volunteer job, not a duplicate');
        System.assertEquals(firstVolunteerJobs[0].Id, secondVolunteerJobs[0].Id, 'The second regen must update the SAME volunteer job record, not insert a new one');
    }

    // The first regen's slots start with real Ids (post-save); the second regen's freshly-built
    // slots always have Id == null (a 'regenerateDrive' token is not in the skip-slots set, so slots
    // are always rebuilt from scratch for this token). This exercises the path every already-generated
    // Mobile drive actually takes: skedDriveGraphSaver.deleteRemovedRecords() deletes the old slot Ids
    // before the new ones are inserted - proving that delete doesn't throw (e.g. via some downstream
    // reference to the slot) is the point of this test.
    @isTest
    static void testOnDriveDataChanged_thenSave_secondRegenReplacesSlotsWithoutError() {
        sked_Drive__c testDrive1 = setupDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        skedDriveRegenContext firstCtx = skedDriveRegenContextLoader.load(testDrive1.Id);
        new skedMobileDriveRegenEngine().onDriveDataChanged(firstCtx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(firstCtx);
        Set<Id> firstSlotIds = new Map<Id, sked__Slot__c>([SELECT Id FROM sked__Slot__c WHERE sked_Drive_Shift__c = :existingShift.Id]).keySet();
        System.assert(!firstSlotIds.isEmpty(), 'Setup check: the first regen must have produced at least one slot');

        // The second load is deliberately taken INSIDE Test.startTest() - it's a fresh governor-limit
        // scope, mirroring a separate batch/queueable invocation in production rather than sharing
        // the first regen cycle's SOQL budget.
        Test.startTest();
        skedDriveRegenContext secondCtx = skedDriveRegenContextLoader.load(testDrive1.Id);
        new skedMobileDriveRegenEngine().onDriveDataChanged(secondCtx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(secondCtx);
        Test.stopTest();

        List<sked__Slot__c> secondSlots = [SELECT Id FROM sked__Slot__c WHERE sked_Drive_Shift__c = :existingShift.Id];
        System.assert(!secondSlots.isEmpty(), 'The second regen must still produce slots');
        for (sked__Slot__c slot : secondSlots) {
            System.assert(!firstSlotIds.contains(slot.Id), 'Every slot from the first regen must have been deleted, not left behind alongside the new ones');
        }
    }

    // Slot generation is skipped entirely when the ONLY applied token(s) are
    // roleTimeDetailChanged/travelTimeChanged, carrying the shift's pre-regen slots forward
    // untouched instead of rebuilding them.
    private static Set<Id> regenerateAndSaveThenGetSlotIds(Id driveId, Id existingShiftId, Map<String, Object> tokens) {
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(driveId);
        new skedMobileDriveRegenEngine().onDriveDataChanged(ctx, tokens);
        skedDriveGraphSaver.save(ctx);
        return new Map<Id, sked__Slot__c>([SELECT Id FROM sked__Slot__c WHERE sked_Drive_Shift__c = :existingShiftId]).keySet();
    }

    @isTest
    static void testOnDriveDataChanged_roleTimeDetailChangedOnly_preservesExactSlotIds() {
        sked_Drive__c testDrive1 = setupDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        Set<Id> originalSlotIds = regenerateAndSaveThenGetSlotIds(testDrive1.Id, existingShift.Id, new Map<String, Object>{ 'regenerateDrive' => null });
        System.assert(!originalSlotIds.isEmpty(), 'Setup check: the first regen must have produced at least one slot');

        Test.startTest();
        Set<Id> slotIdsAfterRtdChange = regenerateAndSaveThenGetSlotIds(testDrive1.Id, existingShift.Id, new Map<String, Object>{ 'roleTimeDetailChanged' => null });
        Test.stopTest();

        System.assertEquals(originalSlotIds.size(), slotIdsAfterRtdChange.size(), 'An RTD-only DCR must not change the slot count');
        System.assert(originalSlotIds.containsAll(slotIdsAfterRtdChange) && slotIdsAfterRtdChange.containsAll(originalSlotIds),
            'An RTD-only DCR must preserve the EXACT slot Ids untouched, not just some slots');

        sked_Drive__c persistedDrive = [SELECT sked_Total_Slots__c FROM sked_Drive__c WHERE Id = :testDrive1.Id];
        System.assertEquals(originalSlotIds.size(), persistedDrive.sked_Total_Slots__c,
            'Total slots must still reflect the (unchanged) carried-forward slot count');
    }

    @isTest
    static void testOnDriveDataChanged_travelTimeChangedOnly_preservesExactSlotIds() {
        sked_Drive__c testDrive1 = setupDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        Set<Id> originalSlotIds = regenerateAndSaveThenGetSlotIds(testDrive1.Id, existingShift.Id, new Map<String, Object>{ 'regenerateDrive' => null });
        System.assert(!originalSlotIds.isEmpty(), 'Setup check: the first regen must have produced at least one slot');

        Test.startTest();
        Set<Id> slotIdsAfterTravelTimeChange = regenerateAndSaveThenGetSlotIds(testDrive1.Id, existingShift.Id, new Map<String, Object>{ 'travelTimeChanged' => null });
        Test.stopTest();

        System.assertEquals(originalSlotIds.size(), slotIdsAfterTravelTimeChange.size(), 'A travel-time-only DCR must not change the slot count');
        System.assert(originalSlotIds.containsAll(slotIdsAfterTravelTimeChange) && slotIdsAfterTravelTimeChange.containsAll(originalSlotIds),
            'A travel-time-only DCR must preserve the EXACT slot Ids untouched, not just some slots');
    }

    // Proves the gate uses `.every()` semantics (ALL applied tokens must be in the skip set), not
    // `.some()` - a token set that also contains 'regenerateDrive' must still fully regenerate slots.
    @isTest
    static void testOnDriveDataChanged_roleTimeDetailChangedWithRegenerateDrive_stillRegeneratesSlots() {
        sked_Drive__c testDrive1 = setupDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        Set<Id> originalSlotIds = regenerateAndSaveThenGetSlotIds(testDrive1.Id, existingShift.Id, new Map<String, Object>{ 'regenerateDrive' => null });
        System.assert(!originalSlotIds.isEmpty(), 'Setup check: the first regen must have produced at least one slot');

        Test.startTest();
        Set<Id> slotIdsAfterMixedTokens = regenerateAndSaveThenGetSlotIds(testDrive1.Id, existingShift.Id,
            new Map<String, Object>{ 'roleTimeDetailChanged' => null, 'regenerateDrive' => null });
        Test.stopTest();

        System.assert(!slotIdsAfterMixedTokens.isEmpty(), 'The regen must still produce slots');
        for (Id slotId : slotIdsAfterMixedTokens) {
            System.assert(!originalSlotIds.contains(slotId),
                'A token set that is not PURELY roleTimeDetailChanged/travelTimeChanged must fully regenerate slots, not carry any forward');
        }
    }

    // When no system-role job's computed quantity actually changed anywhere on the drive, a
    // manually-bumped persisted quantity must survive a regen untouched rather than being
    // overwritten by the freshly computed (lower) value.
    private static sked__Job__c findPersistedJobByRole(Id existingShiftId, String role) {
        List<sked__Job__c> jobs = [SELECT Id, sked__Quantity__c, sked_System_Quantity__c FROM sked__Job__c
            WHERE sked_Drive_Shift__c = :existingShiftId AND sked_Resource_Role__c = :role];
        return jobs.isEmpty() ? null : jobs[0];
    }

    @isTest
    static void testOnDriveDataChanged_roleTimeDetailChangedOnly_restoresManuallyBumpedSystemRoleQuantity() {
        sked_Drive__c testDrive1 = setupDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        skedDriveRegenContext firstCtx = skedDriveRegenContextLoader.load(testDrive1.Id);
        new skedMobileDriveRegenEngine().onDriveDataChanged(firstCtx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(firstCtx);

        sked__Job__c twoRbcJob = findPersistedJobByRole(existingShift.Id, '2RBC');
        System.assertNotEquals(null, twoRbcJob, 'Setup check: this drive must system-generate a 2RBC role job');
        System.assert(twoRbcJob.sked__Quantity__c > 0, 'Setup check: the 2RBC role must be system-generated with a positive quantity');
        Decimal originalQuantity = twoRbcJob.sked__Quantity__c;
        Decimal bumpedQuantity = originalQuantity + 5;
        twoRbcJob.sked__Quantity__c = bumpedQuantity;
        update twoRbcJob;

        // The second load is deliberately taken INSIDE Test.startTest() - it's a fresh governor-limit
        // scope, mirroring a separate batch/queueable invocation in production rather than sharing
        // the first regen cycle's SOQL budget.
        Test.startTest();
        skedDriveRegenContext secondCtx = skedDriveRegenContextLoader.load(testDrive1.Id);
        new skedMobileDriveRegenEngine().onDriveDataChanged(secondCtx, new Map<String, Object>{ 'roleTimeDetailChanged' => null });
        skedDriveGraphSaver.save(secondCtx);
        Test.stopTest();

        sked__Job__c persistedJob = [SELECT sked__Quantity__c FROM sked__Job__c WHERE Id = :twoRbcJob.Id];
        System.assertEquals(bumpedQuantity, persistedJob.sked__Quantity__c,
            'An RTD-only DCR with no system-quantity change anywhere must restore the persisted (manually-bumped) quantity, not overwrite it with the freshly computed value');
    }

    @isTest
    static void testOnDriveDataChanged_regenerateDrive_overwritesManuallyBumpedSystemRoleQuantity() {
        sked_Drive__c testDrive1 = setupDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;

        skedDriveRegenContext firstCtx = skedDriveRegenContextLoader.load(testDrive1.Id);
        new skedMobileDriveRegenEngine().onDriveDataChanged(firstCtx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(firstCtx);

        sked__Job__c twoRbcJob = findPersistedJobByRole(existingShift.Id, '2RBC');
        System.assertNotEquals(null, twoRbcJob, 'Setup check: this drive must system-generate a 2RBC role job');
        Decimal originalQuantity = twoRbcJob.sked__Quantity__c;
        twoRbcJob.sked__Quantity__c = originalQuantity + 5;
        update twoRbcJob;

        // The second load is deliberately taken INSIDE Test.startTest() - it's a fresh governor-limit
        // scope, mirroring a separate batch/queueable invocation in production rather than sharing
        // the first regen cycle's SOQL budget.
        Test.startTest();
        skedDriveRegenContext secondCtx = skedDriveRegenContextLoader.load(testDrive1.Id);
        new skedMobileDriveRegenEngine().onDriveDataChanged(secondCtx, new Map<String, Object>{ 'regenerateDrive' => null });
        skedDriveGraphSaver.save(secondCtx);
        Test.stopTest();

        sked__Job__c persistedJob = [SELECT sked__Quantity__c FROM sked__Job__c WHERE Id = :twoRbcJob.Id];
        System.assertEquals(originalQuantity, persistedJob.sked__Quantity__c,
            'A regenerateDrive token must force the gate to treat every matched role as changed, so the freshly computed quantity always wins over a manually-bumped one');
    }

    // resetElectContentions reads/writes ctx.drive and ctx.driveShifts purely in-memory - no DML or
    // SOQL needed to test it, unlike onDriveDataChanged's other tests above. ctx.snapshot must be
    // taken (deepClone) BEFORE any test-specific mutation to ctx.drive, matching how
    // skedDriveRegenContextLoader.load() takes it before an engine runs - see
    // skedDriveContentionValidator_Test.buildContext for the same established pattern.
    // Defaults sked_Start_Time__c/sked_End_Time__c to a fixed, matching value when a test doesn't
    // set them itself - keeps every test but the operational-hours one off the null-vs-null Time
    // comparison entirely, rather than relying on it evaluating false.
    private static skedDriveRegenContext buildContextForResetElectContentions(sked_Drive__c drive) {
        if (drive.sked_Start_Time__c == null) {
            drive.sked_Start_Time__c = Time.newInstance(9, 0, 0, 0);
        }
        if (drive.sked_End_Time__c == null) {
            drive.sked_End_Time__c = Time.newInstance(17, 0, 0, 0);
        }
        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = drive;
        ctx.snapshot = ctx.deepClone();
        return ctx;
    }

    private static sked_Drive_Shift__c buildShift(Decimal staffSetup, Decimal vehiclesNeeded, Decimal equipment) {
        return new sked_Drive_Shift__c(
            sked_Staff_Setup__c = staffSetup,
            sked_Vehicles_Needed__c = vehiclesNeeded,
            sked_Equipment__c = equipment
        );
    }

    // The "current" side of resetElectContentions's staff/vehicle/equipment comparisons sums
    // ctx.jobsByShiftId's jobs directly (matching baseGenerator.js's updateDriveRequestedResources),
    // not the shift-level rollup-shadow fields buildShift sets - any Id works as the map key here,
    // since sumStaffRequested/sumVehicleRequested/sumEquipmentRequested iterate jobsByShiftId.values()
    // regardless of key.
    private static void addJobToShift(skedDriveRegenContext ctx, Id shiftId, sked__Job__c job) {
        if (!ctx.jobsByShiftId.containsKey(shiftId)) {
            ctx.jobsByShiftId.put(shiftId, new List<sked__Job__c>());
        }
        ctx.jobsByShiftId.get(shiftId).add(job);
    }

    private static sked__Job__c buildStaffJob(Decimal quantity) {
        return new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = quantity);
    }

    private static sked__Job__c buildAssetJob(String assetType, Decimal quantity) {
        return new sked__Job__c(sked_Asset_Type__c = assetType, sked__Quantity__c = quantity);
    }

    @isTest
    static void testResetElectContentions_nothingChanged_removesOnlyTheFourUnconditionalTokensLeavesOthersIntact() {
        sked_Drive__c drive = new sked_Drive__c(
            sked_Contention_Resolution__c = String.join(new List<String>{
                skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_DUAL_ROLE_REMOVAL,
                skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_WITHIN_42_DAYS,
                skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_STAFFING_COMPLEMENT_CHANGED_ACCEPT_NEW_CHANGE,
                skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_STAFFING_COMPLEMENT_CHANGED_KEEP_CURRENT,
                skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LOCKED_RESOURCE_UNAVAILABLE
            }, ';')
        );
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        ctx.driveShifts.add(buildShift(0, 0, 0));

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        List<String> remaining = ctx.drive.sked_Contention_Resolution__c.split(';');
        System.assertEquals(1, remaining.size(), 'Only the unrelated, already-set token must survive when nothing else changed');
        System.assertEquals(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LOCKED_RESOURCE_UNAVAILABLE, remaining[0],
            'An elect token unrelated to any reset clause must never be touched');
    }

    @isTest
    static void testResetElectContentions_driveDateChanged_clearsAllResolutionsIncludingPerShift() {
        sked_Drive__c drive = new sked_Drive__c(
            sked_Drive_Date__c = Date.today(),
            sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LOCKED_RESOURCE_UNAVAILABLE
        );
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        sked_Drive_Shift__c shift = buildShift(0, 0, 0);
        shift.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LOCKED_RESOURCE_UNAVAILABLE;
        ctx.driveShifts.add(shift);
        ctx.drive.sked_Drive_Date__c = Date.today().addDays(7);

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals('', ctx.drive.sked_Contention_Resolution__c, 'A Drive Date change must clear every elect resolution, not just the 4 unconditional ones');
        System.assertEquals('', ctx.driveShifts[0].sked_Contention_Resolution__c, 'A Drive Date change must also clear every shift\'s own resolution');
    }

    @isTest
    static void testResetElectContentions_collectionOperationChanged_clearsAllResolutions() {
        // Assigning UserInfo.getUserId() to a lookup field is safe for an in-memory, never-DML'd
        // sObject - Apex only validates a lookup's referenced SObjectType at DML time, and this test
        // never inserts/updates `drive`. It's a stand-in for "any non-null Id", nothing more.
        sked_Drive__c drive = new sked_Drive__c(
            sked_Collection_Operation__c = UserInfo.getUserId(),
            sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LOCKED_RESOURCE_UNAVAILABLE
        );
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        ctx.driveShifts.add(buildShift(0, 0, 0));
        ctx.drive.sked_Collection_Operation__c = null;

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals('', ctx.drive.sked_Contention_Resolution__c, 'A Collection Operation change must clear every elect resolution');
    }

    @isTest
    static void testResetElectContentions_startTimeMovedEarlier_removesOutOfOperationalHoursToken() {
        sked_Drive__c drive = new sked_Drive__c(
            sked_Start_Time__c = Time.newInstance(9, 0, 0, 0),
            sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_OUT_OF_OPERATIONAL_HOURS
        );
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        ctx.drive.sked_Start_Time__c = Time.newInstance(8, 0, 0, 0);

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals('', ctx.drive.sked_Contention_Resolution__c, 'A shift start moved earlier than before must remove ELECT_OUT_OF_OPERATIONAL_HOURS');
    }

    // sked_Total_Staff/Vehicle/Equipment_Requested__c are Roll-Up Summary fields (Master-Detail
    // child sked_Drive_Shift__c) - not writable via constructor/assignment even on an unsaved
    // sObject (the compiler rejects it), so a real backup total can only come from actually
    // inserting a shift and requerying the drive. Master-Detail rollups recalculate synchronously,
    // so the requery immediately reflects it in the same transaction.
    private static sked_Drive__c setupDriveWithShiftRollups(Decimal staffSetup, Decimal vehiclesNeeded, Decimal equipment) {
        sked_Drive__c testDrive1 = setupDrive();
        insert new sked_Drive_Shift__c(
            sked_Drive__c = testDrive1.Id,
            sked_Staff_Setup__c = staffSetup,
            sked_Vehicles_Needed__c = vehiclesNeeded,
            sked_Equipment__c = equipment
        );
        return [
            SELECT Id, sked_Drive_Date__c, sked_Collection_Operation__c, sked_Start_Time__c, sked_End_Time__c,
                sked_Projected_Registered_Donors__c, sked_Staff_Capacity__c, Max_Role_Capacity_With_Draw_Hours__c,
                Excess_Staff_Capacity__c, sked_Total_Staff_Requested__c, sked_Total_Vehicle_Requested__c,
                sked_Total_Equipment_Requested__c, sked_Contention_Resolution__c
            FROM sked_Drive__c
            WHERE Id = :testDrive1.Id
        ];
    }

    // A staffing-modal-manual job must never count toward the current total - matches
    // updateDriveRequestedResources's own excludeManuallyCreatedFromStaffingModal filter
    // (baseGenerator.js:582-584). Without the exclusion, this job's oversized quantity would spike
    // the current total past the backup and wrongly clear ELECT_INSUFFICIENT_RESOURCES.
    @isTest
    static void testResetElectContentions_staffingModalManualJobExcluded_notCountedTowardStaffRequested() {
        sked_Drive__c drive = setupDriveWithShiftRollups(5, 0, 0);
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_INSUFFICIENT_RESOURCES;
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        addJobToShift(ctx, drive.Id, buildStaffJob(5));
        sked__Job__c staffingModalJob = buildStaffJob(100);
        staffingModalJob.sked_Is_Manually_Created__c = true;
        staffingModalJob.sked_Manually_Created_From__c = 'Staffing Modal';
        addJobToShift(ctx, drive.Id, staffingModalJob);

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_INSUFFICIENT_RESOURCES, ctx.drive.sked_Contention_Resolution__c,
            'A staffing-modal-manual job\'s quantity must be excluded from the current total, leaving it unchanged from the backup');
    }

    @isTest
    static void testResetElectContentions_staffRequestedIncreased_removesInsufficientResourcesToken() {
        sked_Drive__c drive = setupDriveWithShiftRollups(5, 0, 0);
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_INSUFFICIENT_RESOURCES;
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        addJobToShift(ctx, drive.Id, buildStaffJob(6));

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals('', ctx.drive.sked_Contention_Resolution__c, 'A total staff requested increase must remove ELECT_INSUFFICIENT_RESOURCES');
    }

    @isTest
    static void testResetElectContentions_staffRequestedUnchanged_keepsInsufficientResourcesToken() {
        sked_Drive__c drive = setupDriveWithShiftRollups(5, 0, 0);
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_INSUFFICIENT_RESOURCES;
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        addJobToShift(ctx, drive.Id, buildStaffJob(5));

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_INSUFFICIENT_RESOURCES, ctx.drive.sked_Contention_Resolution__c,
            'An unchanged (not increased) total staff requested must keep ELECT_INSUFFICIENT_RESOURCES - the source only clears on an INCREASE, not any change');
    }

    @isTest
    static void testResetElectContentions_excessStaffCapacityFieldChanged_removesExcessStaffCapacityToken() {
        sked_Drive__c drive = new sked_Drive__c(
            Excess_Staff_Capacity__c = 1,
            sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_EXCESS_STAFF_CAPACITY
        );
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        ctx.drive.Excess_Staff_Capacity__c = 2;

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals('', ctx.drive.sked_Contention_Resolution__c, 'A changed Excess_Staff_Capacity__c must remove ELECT_EXCESS_STAFF_CAPACITY');
    }

    @isTest
    static void testResetElectContentions_vehicleRequestedIncreased_removesBothLackingVehicleTokens() {
        sked_Drive__c drive = setupDriveWithShiftRollups(0, 1, 0);
        drive.sked_Contention_Resolution__c = String.join(new List<String>{
            skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LACKING_VEHICLE_INSUFFICIENT_CAPACITY,
            skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LACKING_VEHICLE_USE_RENTAL
        }, ';');
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        addJobToShift(ctx, drive.Id, buildAssetJob(skedConstants.ASSET_TYPE_VEHICLE, 2));

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals('', ctx.drive.sked_Contention_Resolution__c, 'A total vehicle requested increase must remove both LACKING_VEHICLE elect tokens');
    }

    @isTest
    static void testResetElectContentions_equipmentRequestedChanged_removesPartOfLinkedDriveToken() {
        sked_Drive__c drive = setupDriveWithShiftRollups(5, 1, 1);
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_PART_OF_LINKED_DRIVE;
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        addJobToShift(ctx, drive.Id, buildStaffJob(5));
        addJobToShift(ctx, drive.Id, buildAssetJob(skedConstants.ASSET_TYPE_VEHICLE, 1));
        addJobToShift(ctx, drive.Id, buildAssetJob(skedConstants.ASSET_TYPE_EQUIPMENT, 2));

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals('', ctx.drive.sked_Contention_Resolution__c, 'A changed total equipment requested must remove ELECT_PART_OF_LINKED_DRIVE');
    }

    @isTest
    static void testResetElectContentions_allTotalsUnchanged_keepsPartOfLinkedDriveToken() {
        sked_Drive__c drive = setupDriveWithShiftRollups(5, 1, 2);
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_PART_OF_LINKED_DRIVE;
        skedDriveRegenContext ctx = buildContextForResetElectContentions(drive);
        addJobToShift(ctx, drive.Id, buildStaffJob(5));
        addJobToShift(ctx, drive.Id, buildAssetJob(skedConstants.ASSET_TYPE_VEHICLE, 1));
        addJobToShift(ctx, drive.Id, buildAssetJob(skedConstants.ASSET_TYPE_EQUIPMENT, 2));

        Test.startTest();
        skedMobileDriveRegenEngine.resetElectContentions(ctx);
        Test.stopTest();

        System.assertEquals(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_PART_OF_LINKED_DRIVE, ctx.drive.sked_Contention_Resolution__c,
            'Unchanged staff/vehicle/equipment totals must keep ELECT_PART_OF_LINKED_DRIVE');
    }
}
