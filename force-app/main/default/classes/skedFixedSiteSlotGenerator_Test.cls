@isTest
private class skedFixedSiteSlotGenerator_Test {

    private static List<skedTimeRange> oneRound(DateTime roundStart, String timezoneSidId) {
        skedTimeRange round = new skedTimeRange();
        round.rangeStart = roundStart;
        round.rangeEnd = skedDateTimeUtils.addMinutes(roundStart, 180, timezoneSidId);
        return new List<skedTimeRange>{ round };
    }

    @isTest
    static void testGeneratePlateletSlots_zeroAssets_returnsEmpty() {
        sked__Location__c driveSite = new sked__Location__c(sked_Fixed_Site_Appointment_Pattern__c = 'Grouped');
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime roundStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlateletSlots(driveSite, 0, oneRound(roundStart, timezoneSidId), timezoneSidId);
        Test.stopTest();

        System.assertEquals(0, slots.size(), 'Zero Platelet assets must produce zero slots');
    }

    @isTest
    static void testGeneratePlateletSlots_groupedPatternTwoAssets_producesOneOffsetGroupOfTwo() {
        sked__Location__c driveSite = new sked__Location__c(sked_Fixed_Site_Appointment_Pattern__c = 'Grouped');
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime roundStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlateletSlots(driveSite, 2, oneRound(roundStart, timezoneSidId), timezoneSidId);
        Test.stopTest();

        System.assertEquals(2, slots.size(), 'Grouped pattern with <=2 assets must produce a single offset (minutesIntoStart=0) holding both assets');
        for (sked__Slot__c slot : slots) {
            System.assertEquals(roundStart, slot.sked_Start__c, 'The single Grouped offset must start exactly at the round start');
        }
    }

    @isTest
    static void testGeneratePlateletSlots_groupedPatternFourAssets_splitsAcrossTwoOffsets() {
        sked__Location__c driveSite = new sked__Location__c(sked_Fixed_Site_Appointment_Pattern__c = 'Grouped');
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime roundStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlateletSlots(driveSite, 4, oneRound(roundStart, timezoneSidId), timezoneSidId);
        Test.stopTest();

        System.assertEquals(4, slots.size(), 'Grouped pattern with >2 assets must produce 2 offsets (0 and 30 minutes) splitting the 4 assets 2/2');
        Integer atRoundStart = 0;
        Integer atThirtyMinutes = 0;
        for (sked__Slot__c slot : slots) {
            if (slot.sked_Start__c == roundStart) {
                atRoundStart++;
            } else if (slot.sked_Start__c == skedDateTimeUtils.addMinutes(roundStart, 30, timezoneSidId)) {
                atThirtyMinutes++;
            }
        }
        System.assertEquals(2, atRoundStart, 'Ceiling-distribution of 4 assets across 2 offsets must be exactly 2/2');
        System.assertEquals(2, atThirtyMinutes, 'Ceiling-distribution of 4 assets across 2 offsets must be exactly 2/2');
    }

    @isTest
    static void testGeneratePlateletSlots_evenPatternTwoAssets_slicesOffsetListToAssetCount() {
        sked__Location__c driveSite = new sked__Location__c(sked_Fixed_Site_Appointment_Pattern__c = 'Even');
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime roundStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlateletSlots(driveSite, 2, oneRound(roundStart, timezoneSidId), timezoneSidId);
        Test.stopTest();

        // Even's full offset list is [0,15,30] but slices to 2 entries for 2 assets - each offset gets exactly 1 asset.
        System.assertEquals(2, slots.size(), 'Even pattern slices its 3-offset list down to 2 offsets for 2 assets, one asset each');
        Set<DateTime> startTimes = new Set<DateTime>();
        for (sked__Slot__c slot : slots) {
            startTimes.add(slot.sked_Start__c);
        }
        System.assert(startTimes.contains(roundStart), 'Even pattern must include the 0-minute offset');
        System.assert(startTimes.contains(skedDateTimeUtils.addMinutes(roundStart, 15, timezoneSidId)), 'Even pattern must include the 15-minute offset');
    }

    @isTest
    static void testGeneratePlateletSlots_even4IntervalPatternFiveAssets_capsAtFourOffsets() {
        sked__Location__c driveSite = new sked__Location__c(sked_Fixed_Site_Appointment_Pattern__c = 'Even - 4 Interval');
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime roundStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlateletSlots(driveSite, 5, oneRound(roundStart, timezoneSidId), timezoneSidId);
        Test.stopTest();

        // Even - 4 Interval caps at 4 offsets even for 5 assets (Math.min(5,4)=4) - ceiling-distributed 5 across 4: 2,1,1,1.
        System.assertEquals(5, slots.size(), 'Even - 4 Interval must still place all 5 assets, ceiling-distributed across its 4-offset cap');
        Set<DateTime> startTimes = new Set<DateTime>();
        for (sked__Slot__c slot : slots) {
            startTimes.add(slot.sked_Start__c);
        }
        System.assertEquals(4, startTimes.size(), 'Even - 4 Interval must use exactly 4 distinct offsets, never a 5th');
    }

    @isTest
    static void testGeneratePlateletSlots_even4IntervalPatternTwoAssets_usesZeroAndThirtyNotZeroAndFifteen() {
        sked__Location__c driveSite = new sked__Location__c(sked_Fixed_Site_Appointment_Pattern__c = 'Even - 4 Interval');
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime roundStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlateletSlots(driveSite, 2, oneRound(roundStart, timezoneSidId), timezoneSidId);
        Test.stopTest();

        // The offset list is [0,30,15,45], not sorted ascending - slicing the first 2 entries for 2
        // assets must yield {0,30}, not {0,15}. This is the only assertion in the suite that can
        // detect an accidental re-sort of that array to [0,15,30,45].
        Set<DateTime> startTimes = new Set<DateTime>();
        for (sked__Slot__c slot : slots) {
            startTimes.add(slot.sked_Start__c);
        }
        System.assert(startTimes.contains(roundStart), 'Even - 4 Interval with 2 assets must include the 0-minute offset');
        System.assert(startTimes.contains(skedDateTimeUtils.addMinutes(roundStart, 30, timezoneSidId)), 'Even - 4 Interval with 2 assets must include the 30-minute offset, since the unsorted offset list is [0,30,15,45]');
        System.assert(!startTimes.contains(skedDateTimeUtils.addMinutes(roundStart, 15, timezoneSidId)), 'Even - 4 Interval with 2 assets must NOT include the 15-minute offset - that would only happen if the array were wrongly sorted to [0,15,30,45]');
    }

    @isTest
    static void testGeneratePlateletSlots_slotEndAnchoredToRoundStartNotSlotStart() {
        sked__Location__c driveSite = new sked__Location__c(sked_Fixed_Site_Appointment_Pattern__c = 'Grouped');
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime roundStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);

        Test.startTest();
        // 4 assets -> Grouped uses 2 offsets (0 and 30 minutes).
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlateletSlots(driveSite, 4, oneRound(roundStart, timezoneSidId), timezoneSidId);
        Test.stopTest();

        DateTime expectedEnd = skedDateTimeUtils.addMinutes(roundStart, 180, timezoneSidId);
        for (sked__Slot__c slot : slots) {
            System.assertEquals(expectedEnd, slot.sked_End__c,
                'Every slot in the round must end at roundStart+180min regardless of its own start offset - the 30-minute-offset slots are genuinely only 150 minutes long, not a bug');
        }
    }

    @isTest
    static void testGeneratePlateletSlots_blankAppointmentPattern_defaultsToGrouped() {
        sked__Location__c driveSite = new sked__Location__c(sked_Fixed_Site_Appointment_Pattern__c = null);
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime roundStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlateletSlots(driveSite, 2, oneRound(roundStart, timezoneSidId), timezoneSidId);
        Test.stopTest();

        System.assertEquals(2, slots.size(), 'A blank appointment pattern must default to Grouped (single offset for <=2 assets), not zero slots');
    }

    @isTest
    static void testGeneratePlateletSlots_twoRounds_generatesIndependentlyPerRound() {
        sked__Location__c driveSite = new sked__Location__c(sked_Fixed_Site_Appointment_Pattern__c = 'Grouped');
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime firstRoundStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);
        DateTime secondRoundStart = skedDateTimeUtils.addMinutes(firstRoundStart, 180, timezoneSidId);

        skedTimeRange firstRound = new skedTimeRange();
        firstRound.rangeStart = firstRoundStart;
        firstRound.rangeEnd = skedDateTimeUtils.addMinutes(firstRoundStart, 180, timezoneSidId);
        skedTimeRange secondRound = new skedTimeRange();
        secondRound.rangeStart = secondRoundStart;
        secondRound.rangeEnd = skedDateTimeUtils.addMinutes(secondRoundStart, 180, timezoneSidId);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlateletSlots(
            driveSite, 2, new List<skedTimeRange>{ firstRound, secondRound }, timezoneSidId);
        Test.stopTest();

        System.assertEquals(4, slots.size(), '2 rounds x 1 offset x 2 assets each = 4 total slots, independently per round');
    }

    // ===== generateWbSlots / loadMasterData =====

    private static skedFixedSiteDriveShiftCalculator.DriveShiftMetadata buildWbShift(Time startTime, Time endTime) {
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = new skedFixedSiteDriveShiftCalculator.DriveShiftMetadata();
        shift.driveDate = Date.newInstance(2026, 9, 1);
        shift.startTime = startTime;
        shift.endTime = endTime;
        return shift;
    }

    // generateWbSlots never queries inside itself - the whole MasterData it needs can be built in
    // memory. A null qns omits the WB projection entirely (scenario: no matching projection).
    private static skedFixedSiteSlotGenerator.MasterData buildWbMasterData(Decimal qns, Decimal deferral,
            Decimal slotGeneratorOverridePercent, Decimal callListRecipientNoneFixedSiteCapacity, Boolean skipLastAppointmentForFixedSite) {
        skedFixedSiteSlotGenerator.MasterData masterData = new skedFixedSiteSlotGenerator.MasterData();
        masterData.timezoneSidId = UserInfo.getTimeZone().getID();
        masterData.slotGeneratorOverridePercent = slotGeneratorOverridePercent;
        masterData.callListRecipientNoneFixedSiteCapacity = callListRecipientNoneFixedSiteCapacity;
        masterData.skipLastAppointmentForFixedSite = skipLastAppointmentForFixedSite;
        if (qns != null) {
            masterData.fixedSiteProcedureProjections.add(new sked_Fixed_Site_Procedure_Projection__c(
                sked_Procedure_Type__c = skedConstants.PROCEDURE_TYPE_WB, sked_QNS__c = qns, sked_Deferral__c = deferral));
        }
        return masterData;
    }

    private static DateTime maxSlotStart(List<sked__Slot__c> slots) {
        DateTime latest;
        for (sked__Slot__c slot : slots) {
            if (latest == null || slot.sked_Start__c > latest) {
                latest = slot.sked_Start__c;
            }
        }
        return latest;
    }

    private static Boolean hasSlotStartingAt(List<sked__Slot__c> slots, DateTime start) {
        for (sked__Slot__c slot : slots) {
            if (slot.sked_Start__c == start) {
                return true;
            }
        }
        return false;
    }

    @isTest
    static void testGenerateWbSlots_noMatchingWbProjection_producesZeroSlots() {
        sked_Drive__c drive = new sked_Drive__c(sked_WB_Projected_Procedures__c = 100);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(9, 0, 0, 0));
        skedFixedSiteSlotGenerator.MasterData masterData = buildWbMasterData(null, null, 1, 0, false);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generateWbSlots(drive, shift, false, new List<skedTimeRange>(), masterData);
        Test.stopTest();

        System.assertEquals(0, slots.size(), 'With no matching WB Fixed Site Procedure Projection, x must stay 0 and produce zero slots regardless of projected procedures');
    }

    @isTest
    static void testGenerateWbSlots_projectionListHasOnlyWrongProcedureType_stillProducesZeroSlots() {
        sked_Drive__c drive = new sked_Drive__c(sked_WB_Projected_Procedures__c = 100);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(9, 0, 0, 0));
        skedFixedSiteSlotGenerator.MasterData masterData = new skedFixedSiteSlotGenerator.MasterData();
        masterData.timezoneSidId = UserInfo.getTimeZone().getID();
        masterData.slotGeneratorOverridePercent = 1;
        masterData.callListRecipientNoneFixedSiteCapacity = 0;
        // A same-list Platelet-typed row with a non-zero QNS must NOT be mistaken for the WB row - a
        // version that ignored the type filter and just returned the first entry would wrongly produce
        // slots here, unlike the plain-empty-list test above which can't distinguish that.
        masterData.fixedSiteProcedureProjections.add(new sked_Fixed_Site_Procedure_Projection__c(
            sked_Procedure_Type__c = skedConstants.PROCEDURE_TYPE_PLATELET, sked_QNS__c = 50, sked_Deferral__c = 50));

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generateWbSlots(drive, shift, false, new List<skedTimeRange>(), masterData);
        Test.stopTest();

        System.assertEquals(0, slots.size(),
            'A projections list containing only a Platelet-typed row (never WB) must still resolve to zero WB slots - proves findProcedureProjection filters by type');
    }

    @isTest
    static void testGenerateWbSlots_nonLastShift_capsLastSlotAtShiftEndMinus15MinutesEvenWhenSkipFlagIsTrue() {
        sked_Drive__c drive = new sked_Drive__c(sked_WB_Projected_Procedures__c = 4);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(9, 0, 0, 0));
        // skipLastAppointmentForFixedSite=true must be ignored here - that flag only applies to the last shift.
        skedFixedSiteSlotGenerator.MasterData masterData = buildWbMasterData(0, 0, 1, 0, true);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generateWbSlots(drive, shift, false, new List<skedTimeRange>(), masterData);
        Test.stopTest();

        System.assertEquals(4, slots.size(), '4 projected WB procedures with no QNS/Deferral and 100% padding must generate exactly 4 slots');
        DateTime expectedLastSlotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, Time.newInstance(8, 45, 0, 0), masterData.timezoneSidId);
        System.assertEquals(expectedLastSlotStart, maxSlotStart(slots),
            'A non-last shift must cap its last slot at shiftEnd-15min regardless of skipLastAppointmentForFixedSite');
    }

    @isTest
    static void testGenerateWbSlots_lastShiftWithSkipLastAppointmentTrue_capsAtShiftEndMinus15Minutes() {
        sked_Drive__c drive = new sked_Drive__c(sked_WB_Projected_Procedures__c = 4);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(9, 0, 0, 0));
        skedFixedSiteSlotGenerator.MasterData masterData = buildWbMasterData(0, 0, 1, 0, true);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generateWbSlots(drive, shift, true, new List<skedTimeRange>(), masterData);
        Test.stopTest();

        System.assertEquals(4, slots.size(), '4 projected WB procedures with no QNS/Deferral and 100% padding must generate exactly 4 slots');
        DateTime expectedLastSlotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, Time.newInstance(8, 45, 0, 0), masterData.timezoneSidId);
        System.assertEquals(expectedLastSlotStart, maxSlotStart(slots),
            'The last shift with skipLastAppointmentForFixedSite=true must still cap its last slot at shiftEnd-15min');
    }

    @isTest
    static void testGenerateWbSlots_lastShiftWithSkipLastAppointmentFalse_extendsToShiftEndExactly() {
        sked_Drive__c drive = new sked_Drive__c(sked_WB_Projected_Procedures__c = 5);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(9, 0, 0, 0));
        skedFixedSiteSlotGenerator.MasterData masterData = buildWbMasterData(0, 0, 1, 0, false);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generateWbSlots(drive, shift, true, new List<skedTimeRange>(), masterData);
        Test.stopTest();

        System.assertEquals(5, slots.size(), '5 projected WB procedures with no QNS/Deferral and 100% padding must generate exactly 5 slots');
        DateTime shiftEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.endTime, masterData.timezoneSidId);
        System.assert(hasSlotStartingAt(slots, shiftEnd),
            'The last shift with skipLastAppointmentForFixedSite=false must allow a slot exactly at shiftEnd, not stop 15 minutes early');
    }

    @isTest
    static void testGenerateWbSlots_prefersOpportunitySlotGeneratorOverAdminSettingFallback() {
        sked_Drive__c drive = new sked_Drive__c(sked_WB_Projected_Procedures__c = 4);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(9, 0, 0, 0));
        // slotGeneratorOverridePercent=50% would yield 2 slots; the admin-setting fallback of 100% would yield 4 - both present, override must win.
        skedFixedSiteSlotGenerator.MasterData masterData = buildWbMasterData(0, 0, 0.5, 1, false);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generateWbSlots(drive, shift, false, new List<skedTimeRange>(), masterData);
        Test.stopTest();

        System.assertEquals(2, slots.size(), 'Opportunity.Slot_Generator__c (50%) must be preferred over the admin-setting fallback (100%) when both are present');
    }

    @isTest
    static void testGenerateWbSlots_distinctNonZeroQnsAndDeferral_combineIntoExpectedSlotCount() {
        sked_Drive__c drive = new sked_Drive__c(sked_WB_Projected_Procedures__c = 10);
        // A wide window (7h) so the 25 requested slots are never capped by running out of the window.
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(15, 0, 0, 0));
        // qns=20% -> qnsFactor=0.8, deferral=50% -> deferralFactor=0.5: x = ceil(10/0.8/0.5) = 25, totalSlots = ceil(25*1) = 25.
        // Distinct, non-zero values on both factors - a swapped qns/deferral, a dropped divisor, or a
        // missing Math.ceil would all still pass every other test in this suite (they all use qns=deferral=0).
        skedFixedSiteSlotGenerator.MasterData masterData = buildWbMasterData(20, 50, 1, 0, false);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generateWbSlots(drive, shift, false, new List<skedTimeRange>(), masterData);
        Test.stopTest();

        System.assertEquals(25, slots.size(),
            'Distinct non-zero QNS(20%) and Deferral(50%) factors must combine as ceil(10/0.8/0.5)=25, proving neither factor nor Math.ceil is dropped or swapped');
    }

    @isTest
    static void testGenerateWbSlots_hundredPercentQns_guardsDivideByZeroAndProducesZeroSlots() {
        sked_Drive__c drive = new sked_Drive__c(sked_WB_Projected_Procedures__c = 10);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(9, 0, 0, 0));
        skedFixedSiteSlotGenerator.MasterData masterData = buildWbMasterData(100, 0, 1, 0, false);

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generateWbSlots(drive, shift, false, new List<skedTimeRange>(), masterData);
        Test.stopTest();

        System.assertEquals(0, slots.size(), 'A 100% QNS factor must resolve qnsFactor to 0 and guard the divide-by-zero, producing zero slots instead of throwing');
    }

    // See reference_fixed_site_test_fixture_gotchas.md - testDrive2/testLocation2 default to WB Operation
    // Type, but loadMasterData never reads sked_Operation_Type__c, so no cancel-flip-restore is needed
    // here - only a re-query for the relationship field (sked_Opportunity__r.Slot_Generator__c) that the
    // in-memory testDrive2 doesn't carry.
    private static sked_Drive__c queryDriveForMasterData(Id driveId) {
        return [
            SELECT Id, sked_Account__c, sked_Collection_Operation__c, sked_Drive_Date__c, sked_WB_Projected_Procedures__c,
                sked_Opportunity__r.Slot_Generator__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    @isTest
    static void testLoadMasterData_mapsAdminSettingOpportunityAndSkipLastAppointmentFields() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');

        // Slot_Generator_Change_Reason_Required validation rule forces a distinct reason on every Slot_Generator__c change.
        update new Opportunity(Id = rawDrive.sked_Opportunity__c, Slot_Generator__c = 110, Slot_Generator_Change_Reason__c = 'Test override for HRP-10153 loadMasterData test');
        update new Biomed_Collection_Op_Center__c(Id = rawDrive.sked_Collection_Operation__c, sked_Skip_Last_Appointment_For__c = skedConstants.DRIVE_TYPE_FIXED_SITE);
        sked_Admin_Setting__c adminSetting = sked_Admin_Setting__c.getOrgDefaults();
        adminSetting.Admin_Call_List_Recipient_None_FS__c = 80;
        upsert adminSetting;

        sked_Drive__c drive = queryDriveForMasterData(rawDrive.Id);

        Test.startTest();
        skedFixedSiteSlotGenerator.MasterData masterData = skedFixedSiteSlotGenerator.loadMasterData(drive);
        Test.stopTest();

        System.assertEquals(0.8, masterData.callListRecipientNoneFixedSiteCapacity, 'The admin setting percent (80) must be scaled by /100 into 0.8');
        System.assertEquals(1.1, masterData.slotGeneratorOverridePercent, 'The Opportunity Slot_Generator__c percent (110) must be scaled by /100 into 1.1');
        System.assertEquals(true, masterData.skipLastAppointmentForFixedSite,
            'sked_Skip_Last_Appointment_For__c containing Fixed Site must map to skipLastAppointmentForFixedSite=true');
        Boolean hasWbProjection = false;
        for (sked_Fixed_Site_Procedure_Projection__c projection : masterData.fixedSiteProcedureProjections) {
            if (projection.sked_Procedure_Type__c == skedConstants.PROCEDURE_TYPE_WB) {
                hasWbProjection = true;
            }
        }
        System.assert(hasWbProjection, 'loadMasterData must retrieve the WB Fixed Site Procedure Projection already seeded for the drive Account by setupCommonTestData');
    }

    // ===== reduceWbSlotsForLunchBreak =====

    private static final String SLOT_TYPE_WHOLE_BLOOD_TEST = 'Whole Blood';

    private static sked__Slot__c buildWbSlot(DateTime start, Integer durationMinutes, String timezoneSidId) {
        return skedSlotGenerator.newSlot(SLOT_TYPE_WHOLE_BLOOD_TEST, start, skedDateTimeUtils.addMinutes(start, durationMinutes, timezoneSidId));
    }

    // reduceWbSlotsForLunchBreak gates/writes on the shift RECORD (sked_Drive_Shift__c), not the shift
    // metadata - the record can differ from the metadata when sked_Lock_Lunch_Break__c restored its
    // booleans from a prior shift. shift.lunchBreakSettings is only needed for the positive path below
    // (findLunchBreakSetting's maximumLunchBreakDuration lookup), not for these gate checks.
    private static sked_Drive_Shift__c buildWbShiftRecord(Boolean lunchBreak, Boolean lunchBreakBeforeDrawHours,
            Time lunchBreakStartTime, Time lunchBreakEndTime, Decimal signUpReduction) {
        return new sked_Drive_Shift__c(
            sked_Lunch_Break__c = lunchBreak, sked_Lunch_Break_Before_Draw_Hours__c = lunchBreakBeforeDrawHours,
            sked_Lunch_Break_Start_Time__c = lunchBreakStartTime, sked_Lunch_Break_End_Time__c = lunchBreakEndTime,
            sked_Sign_Up_Reduction__c = signUpReduction
        );
    }

    @isTest
    static void testReduceWbSlotsForLunchBreak_lunchBreakOff_isNoOpAndLeavesSignUpReductionUntouched() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        Date driveDate = Date.newInstance(2026, 9, 1);
        DateTime slotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(driveDate, Time.newInstance(11, 30, 0, 0), timezoneSidId);
        List<sked__Slot__c> wbSlots = new List<sked__Slot__c>{ buildWbSlot(slotStart, 15, timezoneSidId) };

        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(18, 0, 0, 0));
        sked_Drive_Shift__c shiftRecord = buildWbShiftRecord(false, false, Time.newInstance(11, 30, 0, 0), Time.newInstance(12, 15, 0, 0), 7);
        skedFixedSiteSlotGenerator.MasterData masterData = new skedFixedSiteSlotGenerator.MasterData();

        Test.startTest();
        skedFixedSiteSlotGenerator.reduceWbSlotsForLunchBreak(wbSlots, new List<sked__Job__c>(), shiftRecord, shift, masterData);
        Test.stopTest();

        System.assertEquals(1, wbSlots.size(), 'sked_Lunch_Break__c != true must be a no-op on the WB slot list');
        System.assertEquals(slotStart, wbSlots[0].sked_Start__c, 'The single slot must remain unmodified when the lunch break is off');
        System.assertEquals(7, shiftRecord.sked_Sign_Up_Reduction__c, 'The lunch-break-off gate returns before touching signUpReduction at all - it must stay whatever it already was');
    }

    @isTest
    static void testReduceWbSlotsForLunchBreak_lunchBreakBeforeDrawHours_isNoOpOnSlotsButClearsSignUpReduction() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        Date driveDate = Date.newInstance(2026, 9, 1);
        DateTime slotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(driveDate, Time.newInstance(11, 30, 0, 0), timezoneSidId);
        List<sked__Slot__c> wbSlots = new List<sked__Slot__c>{ buildWbSlot(slotStart, 15, timezoneSidId) };

        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(18, 0, 0, 0));
        sked_Drive_Shift__c shiftRecord = buildWbShiftRecord(true, true, Time.newInstance(6, 40, 0, 0), Time.newInstance(7, 0, 0, 0), 42);
        skedFixedSiteSlotGenerator.MasterData masterData = new skedFixedSiteSlotGenerator.MasterData();

        Test.startTest();
        skedFixedSiteSlotGenerator.reduceWbSlotsForLunchBreak(wbSlots, new List<sked__Job__c>(), shiftRecord, shift, masterData);
        Test.stopTest();

        System.assertEquals(1, wbSlots.size(), 'lunchBreakBeforeDrawHours=true must be a no-op on the WB slot list, per fixedSiteGenerator.js:1605-1634');
        System.assertEquals(slotStart, wbSlots[0].sked_Start__c, 'The single slot must remain unmodified when lunchBreakBeforeDrawHours=true');
        System.assertEquals(null, shiftRecord.sked_Sign_Up_Reduction__c, 'lunchBreakBeforeDrawHours=true must clear signUpReduction, per fixedSiteGenerator.js:1605-1634');
    }

    @isTest
    static void testReduceWbSlotsForLunchBreak_emptySlotList_isNoOpAndLeavesSignUpReductionUntouched() {
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(18, 0, 0, 0));
        sked_Drive_Shift__c shiftRecord = buildWbShiftRecord(true, false, Time.newInstance(11, 30, 0, 0), Time.newInstance(12, 15, 0, 0), 7);
        skedFixedSiteSlotGenerator.MasterData masterData = new skedFixedSiteSlotGenerator.MasterData();
        List<sked__Slot__c> wbSlots = new List<sked__Slot__c>();

        Test.startTest();
        skedFixedSiteSlotGenerator.reduceWbSlotsForLunchBreak(wbSlots, new List<sked__Job__c>(), shiftRecord, shift, masterData);
        Test.stopTest();

        System.assertEquals(0, wbSlots.size(), 'An empty WB slot list must stay empty');
        // fixedSiteGenerator.js's inner branch never assigns signUpReduction when there are no slots -
        // it must be left untouched here too, not nulled the way the lunchBreakBeforeDrawHours branch does.
        System.assertEquals(7, shiftRecord.sked_Sign_Up_Reduction__c, 'An empty WB slot list must leave signUpReduction untouched, not null it');
    }

    private static void insertWbLunchBreakSetting(String maximumLunchBreakDuration, Decimal definitionDuration, Decimal slotReductionPercent) {
        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = maximumLunchBreakDuration);
        insert setting;
        insert new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = definitionDuration,
            sked_Min_Number_of_Staff__c = 0, sked_Max_Number_of_Staff__c = 1000, sked_Slot_Reduction__c = slotReductionPercent
        );
    }

    @isTest
    static void testReduceWbSlotsForLunchBreak_usesItsOwnRoundOffsetOrderDistinctFromGenerationAndWritesSignUpReduction() {
        insertWbLunchBreakSetting('45', 45, 50);
        String timezoneSidId = UserInfo.getTimeZone().getID();
        Date driveDate = Date.newInstance(2026, 9, 1);
        DateTime firstSlotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(driveDate, Time.newInstance(11, 30, 0, 0), timezoneSidId);
        DateTime secondSlotStart = skedDateTimeUtils.addMinutes(firstSlotStart, 15, timezoneSidId);
        DateTime thirdSlotStart = skedDateTimeUtils.addMinutes(secondSlotStart, 15, timezoneSidId);
        List<sked__Slot__c> wbSlots = new List<sked__Slot__c>{
            buildWbSlot(firstSlotStart, 15, timezoneSidId), buildWbSlot(secondSlotStart, 15, timezoneSidId), buildWbSlot(thirdSlotStart, 15, timezoneSidId)
        };

        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(18, 0, 0, 0));
        shift.lunchBreakSettings = new skedLunchBreakSettings();
        shift.lunchBreakSettings.maximumLunchBreakDuration = 45;
        sked_Drive_Shift__c shiftRecord = buildWbShiftRecord(true, false, Time.newInstance(11, 30, 0, 0), Time.newInstance(12, 15, 0, 0), null);
        skedFixedSiteSlotGenerator.MasterData masterData = new skedFixedSiteSlotGenerator.MasterData();
        masterData.timezoneSidId = timezoneSidId;
        masterData.lunchBreakSettingsConfig = skedLunchBreakCalculator.loadLunchBreakSettings();
        List<sked__Job__c> jobs = new List<sked__Job__c>{ new sked__Job__c(sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 2) };

        Test.startTest();
        skedFixedSiteSlotGenerator.reduceWbSlotsForLunchBreak(wbSlots, jobs, shiftRecord, shift, masterData);
        Test.stopTest();

        // All 3 slots fall within the 11:30-12:15 lunch window, and 50% reduction ceilings to 2 removed.
        // LUNCH_BREAK_REDUCTION_ROUND_MINUTES_INTO_START cycles {0,30,15,45} minutes-into-start (removing
        // 11:30 then 12:00, leaving 11:45) - a DIFFERENT order than generateWbSlots' own {0,15,30,45}
        // (which would instead remove 11:30 then 11:45, leaving 12:00 the survivor). This is the only
        // assertion in the suite that can catch the two round-offset lists being collapsed into one.
        System.assertEquals(1, wbSlots.size(), '2 of the 3 in-window slots must be removed: ceil(3 slots * 50%) = 2');
        System.assertEquals(secondSlotStart, wbSlots[0].sked_Start__c,
            'The survivor must be the 11:45 slot, proving reduceWbSlotsForLunchBreak cycles {0,30,15,45}, not generateWbSlots\' {0,15,30,45}');
        System.assertEquals(50, shiftRecord.sked_Sign_Up_Reduction__c,
            'The matched Lunch Break Definition\'s slot-reduction percent must be written back onto shiftRecord.sked_Sign_Up_Reduction__c, not just used locally and discarded');
    }

    // ===== skedSlotGenerator.generateSlotsByNumberOfAssets =====

    private static DateTime minSlotStart(List<sked__Slot__c> slots) {
        DateTime earliest;
        for (sked__Slot__c slot : slots) {
            if (earliest == null || slot.sked_Start__c < earliest) {
                earliest = slot.sked_Start__c;
            }
        }
        return earliest;
    }

    @isTest
    static void testGenerateSlotsByNumberOfAssets_zeroAssets_returnsEmpty() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime firstSlotStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedSlotGenerator.generateSlotsByNumberOfAssets('Test', firstSlotStart, firstSlotStart,
            60, 2, 30, 60, 0, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        System.assertEquals(0, slots.size(), 'Zero assets must produce zero slots');
    }

    @isTest
    static void testGenerateSlotsByNumberOfAssets_twoAssetsTwoGroups_splitsOneEachAcrossTheGroupInterval() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime firstSlotStart = DateTime.newInstanceGmt(2026, 1, 5, 8, 0, 0);
        // lastSlotStart must reach the last group's offset (30min) for that group to be included -
        // a single round only, since the next round (firstSlotStart+60) would exceed it.
        DateTime lastSlotStart = skedDateTimeUtils.addMinutes(firstSlotStart, 30, timezoneSidId);

        Test.startTest();
        List<sked__Slot__c> slots = skedSlotGenerator.generateSlotsByNumberOfAssets('Test', firstSlotStart, lastSlotStart,
            60, 2, 30, 60, 2, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        System.assertEquals(2, slots.size(), '2 assets ceiling-distributed across 2 groups must be exactly 1 each, one slot per group');
        Set<DateTime> startTimes = new Set<DateTime>();
        for (sked__Slot__c slot : slots) {
            startTimes.add(slot.sked_Start__c);
        }
        System.assert(startTimes.contains(firstSlotStart), 'The first group must start exactly at firstSlotStart');
        System.assert(startTimes.contains(lastSlotStart), 'The second group must start at firstSlotStart + groupIntervalMinutes (30min)');
    }

    // ===== generate2rbcSlots =====

    @isTest
    static void testGenerate2rbcSlots_lastSlotStartIsClampedToShiftEndMinus30Minutes() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        sked_Drive__c drive = new sked_Drive__c(sked_Number_of_2RBC_Assets__c = 2);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(9, 30, 0, 0));

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generate2rbcSlots(drive, shift, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        DateTime shiftEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.endTime, timezoneSidId);
        DateTime expectedLastSlotStart = skedDateTimeUtils.addMinutes(shiftEnd, -30, timezoneSidId);
        System.assertEquals(expectedLastSlotStart, maxSlotStart(slots), 'The last 2RBC slot must never start later than shiftEnd - 30 minutes');
        System.assert(!hasSlotStartingAt(slots, shiftEnd), 'No 2RBC slot must start exactly at shiftEnd - the 30-minute buffer must have excluded it');
    }

    // ===== generatePlasmaSlots =====

    @isTest
    static void testGeneratePlasmaSlots_zeroAssets_returnsEmpty() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        sked_Drive__c drive = new sked_Drive__c(sked_Number_of_Plasma_Assets__c = 0);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(13, 0, 0, 0));

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlasmaSlots(drive, shift, false, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        System.assertEquals(0, slots.size(), 'Zero Plasma assets must produce zero slots');
    }

    @isTest
    static void testGeneratePlasmaSlots_firstSlotStartMinuteOverForty_rollsToNextHoursTenMinutePastFortyRound() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        sked_Drive__c drive = new sked_Drive__c(sked_Number_of_Plasma_Assets__c = 2);
        // shiftStart minute 50 -> +60min anchor keeps minute at 50 (a whole-hour add), landing in the >40 branch.
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 50, 0, 0), Time.newInstance(13, 0, 0, 0));

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlasmaSlots(drive, shift, false, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        // 8:50 + 60min anchor = 9:50 (minute 50, >40) -> round down to :40 (9:40) then +30min = 10:10.
        DateTime expectedFirstSlotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, Time.newInstance(10, 10, 0, 0), timezoneSidId);
        System.assertEquals(expectedFirstSlotStart, minSlotStart(slots), 'A minute > 40 must roll to the next hour\'s :10 via the :40 anchor + 30 minutes');
    }

    @isTest
    static void testGeneratePlasmaSlots_firstSlotStartMinuteBetweenElevenAndForty_roundsDownToForty() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        sked_Drive__c drive = new sked_Drive__c(sked_Number_of_Plasma_Assets__c = 2);
        // shiftStart minute 25 -> +60min anchor keeps minute at 25, landing in the 11-40 branch.
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 25, 0, 0), Time.newInstance(13, 0, 0, 0));

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlasmaSlots(drive, shift, false, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        // 8:25 + 60min anchor = 9:25 (minute 25, 11-40) -> rounds to :40, i.e. 9:40.
        DateTime expectedFirstSlotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, Time.newInstance(9, 40, 0, 0), timezoneSidId);
        System.assertEquals(expectedFirstSlotStart, minSlotStart(slots), 'A minute between 11 and 40 must round up to :40 of the same hour');
    }

    @isTest
    static void testGeneratePlasmaSlots_firstSlotStartMinuteAtOrBelowTen_roundsUpToTen() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        sked_Drive__c drive = new sked_Drive__c(sked_Number_of_Plasma_Assets__c = 2);
        // shiftStart minute 5 -> +60min anchor keeps minute at 5, landing in the <=10 branch.
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 5, 0, 0), Time.newInstance(13, 0, 0, 0));

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlasmaSlots(drive, shift, false, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        // 8:05 + 60min anchor = 9:05 (minute 5, <=10) -> rounds up to :10, i.e. 9:10.
        DateTime expectedFirstSlotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, Time.newInstance(9, 10, 0, 0), timezoneSidId);
        System.assertEquals(expectedFirstSlotStart, minSlotStart(slots), 'A minute at or below 10 must round up to :10 of the same hour');
    }

    @isTest
    static void testGeneratePlasmaSlots_fractionalOffsetTimezone_usesLocalMinuteNotGmtMinute() {
        // Asia/Kolkata is UTC+5:30 (no DST) - a naive GMT-based minute read (Datetime.minute()) would
        // be off by the 30-minute fractional offset from the org default test-context timezone,
        // landing in a different rounding branch than the correct local-time read via extractLocalTime.
        String timezoneSidId = 'Asia/Kolkata';
        sked_Drive__c drive = new sked_Drive__c(sked_Number_of_Plasma_Assets__c = 2);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 50, 0, 0), Time.newInstance(13, 0, 0, 0));

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlasmaSlots(drive, shift, false, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        // 8:50 Kolkata local + 60min anchor = 9:50 Kolkata local (minute 50, >40) -> :40 anchor + 30min = 10:10 Kolkata local.
        DateTime expectedFirstSlotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, Time.newInstance(10, 10, 0, 0), timezoneSidId);
        System.assertEquals(expectedFirstSlotStart, minSlotStart(slots),
            'Minute rounding must use the local time in the passed-in timezoneSidId, not a GMT-based minute read');
    }

    @isTest
    static void testGeneratePlasmaSlots_isLastShiftTrue_clampsLastSlotStartToShiftEndMinus50Minutes() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        sked_Drive__c drive = new sked_Drive__c(sked_Number_of_Plasma_Assets__c = 2);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(11, 10, 0, 0));

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlasmaSlots(drive, shift, true, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        DateTime shiftEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.endTime, timezoneSidId);
        System.assert(!hasSlotStartingAt(slots, shiftEnd), 'isLastShift=true must clamp the last slot start to shiftEnd - 50 minutes, excluding a slot exactly at shiftEnd');
        DateTime expectedMaxSlotStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, Time.newInstance(9, 40, 0, 0), timezoneSidId);
        System.assertEquals(expectedMaxSlotStart, maxSlotStart(slots), 'With the 50-minute buffer, the round starting at 10:40 must be excluded entirely, leaving 9:40 as the last slot start');
    }

    @isTest
    static void testGeneratePlasmaSlots_isLastShiftFalse_extendsLastSlotStartToShiftEndExactly() {
        String timezoneSidId = UserInfo.getTimeZone().getID();
        sked_Drive__c drive = new sked_Drive__c(sked_Number_of_Plasma_Assets__c = 2);
        skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift = buildWbShift(Time.newInstance(8, 0, 0, 0), Time.newInstance(11, 10, 0, 0));

        Test.startTest();
        List<sked__Slot__c> slots = skedFixedSiteSlotGenerator.generatePlasmaSlots(drive, shift, false, new List<skedTimeRange>(), timezoneSidId);
        Test.stopTest();

        DateTime shiftEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.endTime, timezoneSidId);
        System.assert(hasSlotStartingAt(slots, shiftEnd), 'isLastShift=false must allow a slot exactly at shiftEnd, not clamp it 50 minutes early');
        System.assertEquals(shiftEnd, maxSlotStart(slots), 'Without the 50-minute buffer, the round starting at 10:40 must still fit, making shiftEnd the last slot start');
    }
}
