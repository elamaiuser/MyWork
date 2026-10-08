@isTest
private class skedSlotGenerator_Test {

    private static final String TIMEZONE = 'America/New_York';

    private static DateTime dt(Integer hour, Integer minute) {
        return skedDateTimeUtils.getDateTimeFromDateAndTime(Date.newInstance(2026, 8, 10), Time.newInstance(hour, minute, 0, 0), TIMEZONE);
    }

    @isTest
    static void testGenerateSlots_singleRoundSufficient_noExclusions_returnsSlotsInOrder() {
        List<Integer> roundOffsets = new List<Integer>{ 0, 30, 15, 45 };

        Test.startTest();
        List<sked__Slot__c> slots = skedSlotGenerator.generateSlots('Whole Blood', dt(7, 0), dt(16, 30), 60, 15,
            roundOffsets, 5, TIMEZONE, new List<skedTimeRange>());
        Test.stopTest();

        // Round 1 (offset 0) alone reaches totalSlots=5: candidates at 7,8,9,10,11 - no exclusions to skip.
        System.assertEquals(5, slots.size(), 'Exactly totalSlots must be generated when a single round has enough room');
        List<Integer> expectedStartHours = new List<Integer>{ 7, 8, 9, 10, 11 };
        for (Integer i = 0; i < slots.size(); i++) {
            System.assertEquals(dt(expectedStartHours[i], 0), slots[i].sked_Start__c, 'Slot ' + i + ' must start at the expected hourly candidate');
            System.assertEquals(dt(expectedStartHours[i], 0).addMinutes(15), slots[i].sked_End__c, 'Slot ' + i + ' must be 15 minutes long');
            System.assertEquals('Whole Blood', slots[i].sked_Type__c, 'sked_Type__c must carry the requested slot type');
        }
    }

    @isTest
    static void testGenerateSlots_excludedTimeRange_skipsMatchingCandidateAndShiftsLaterOnes() {
        List<Integer> roundOffsets = new List<Integer>{ 0, 30, 15, 45 };
        skedTimeRange excluded = new skedTimeRange();
        excluded.rangeStart = dt(9, 0);
        excluded.rangeEnd = dt(10, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedSlotGenerator.generateSlots('Whole Blood', dt(7, 0), dt(16, 30), 60, 15,
            roundOffsets, 5, TIMEZONE, new List<skedTimeRange>{ excluded });
        Test.stopTest();

        // The 9:00 candidate falls inside [9:00,10:00) and must be skipped without counting toward
        // totalSlots - round 1 must instead continue to 12:00 to find its 5th non-excluded candidate.
        System.assertEquals(5, slots.size(), 'totalSlots must still be reached by continuing past excluded candidates');
        List<Integer> expectedStartHours = new List<Integer>{ 7, 8, 10, 11, 12 };
        for (Integer i = 0; i < slots.size(); i++) {
            System.assertEquals(dt(expectedStartHours[i], 0), slots[i].sked_Start__c, 'Slot ' + i + ' must skip the excluded 9:00 candidate');
        }
    }

    @isTest
    static void testGenerateSlots_totalSlotsZeroOrNull_returnsEmptyList() {
        Test.startTest();
        List<sked__Slot__c> zeroResult = skedSlotGenerator.generateSlots('Whole Blood', dt(7, 0), dt(16, 30), 60, 15,
            new List<Integer>{ 0 }, 0, TIMEZONE, new List<skedTimeRange>());
        List<sked__Slot__c> nullResult = skedSlotGenerator.generateSlots('Whole Blood', dt(7, 0), dt(16, 30), 60, 15,
            new List<Integer>{ 0 }, null, TIMEZONE, new List<skedTimeRange>());
        Test.stopTest();

        System.assertEquals(0, zeroResult.size(), 'totalSlots=0 must generate no slots');
        System.assertEquals(0, nullResult.size(), 'totalSlots=null must generate no slots');
    }

    @isTest
    static void testGenerateSlots_exclusionCoversEveryOffset_terminatesInsteadOfHangingWithFewerThanTotalSlots() {
        skedTimeRange excludeEverything = new skedTimeRange();
        excludeEverything.rangeStart = dt(7, 0);
        excludeEverything.rangeEnd = dt(10, 0);

        Test.startTest();
        List<sked__Slot__c> slots = skedSlotGenerator.generateSlots('Whole Blood', dt(7, 0), dt(9, 0), 60, 15,
            new List<Integer>{ 0 }, 3, TIMEZONE, new List<skedTimeRange>{ excludeEverything });
        Test.stopTest();

        // Every candidate (7:00, 8:00, 9:00) falls inside the exclusion range, and there is only one
        // offset to cycle through - a full cycle makes zero progress, so generation must stop rather
        // than spin forever trying to reach totalSlots=3.
        System.assertEquals(0, slots.size(), 'With every candidate excluded, generation must terminate with an empty result, not hang');
    }

    @isTest
    static void testGenerateSlots_oneOffsetFullyExcluded_stillSucceedsViaTheOtherOffset() {
        skedTimeRange excludeOnTheHour1 = new skedTimeRange();
        excludeOnTheHour1.rangeStart = dt(7, 0);
        excludeOnTheHour1.rangeEnd = dt(7, 1);
        skedTimeRange excludeOnTheHour2 = new skedTimeRange();
        excludeOnTheHour2.rangeStart = dt(8, 0);
        excludeOnTheHour2.rangeEnd = dt(8, 1);

        Test.startTest();
        List<sked__Slot__c> slots = skedSlotGenerator.generateSlots('Whole Blood', dt(7, 0), dt(8, 0), 60, 15,
            new List<Integer>{ 0, 30 }, 1, TIMEZONE, new List<skedTimeRange>{ excludeOnTheHour1, excludeOnTheHour2 });
        Test.stopTest();

        // Round 1 (offset 0) has both its candidates (7:00, 8:00) excluded and makes zero progress -
        // but that must not abort the loop, since round 2 (offset 30, candidate 7:30) is unaffected
        // and can still satisfy totalSlots=1. A no-progress round only stops generation once every
        // offset in a full cycle has been tried with no progress, not on the first one.
        System.assertEquals(1, slots.size(), 'A single no-progress round must not abort generation when another offset can still succeed');
        System.assertEquals(dt(7, 30), slots[0].sked_Start__c, 'The only non-excluded candidate, from the second offset, must be the one generated');
    }

    @isTest
    static void testReduceSlots_noSlotMatchesTheRoundCyclingGrid_terminatesWithoutRemovingAnything() {
        List<sked__Slot__c> slots = new List<sked__Slot__c>{
            skedSlotGenerator.newSlot('Whole Blood', dt(11, 7), dt(11, 22))  // inside the window, but off the 15-minute grid
        };

        Test.startTest();
        skedSlotGenerator.reduceSlots(slots, dt(11, 0), dt(12, 0), 15, new List<Integer>{ 0 }, 100, TIMEZONE);
        Test.stopTest();

        // The single in-window slot never lands on any 11:00/11:15/.../11:45 candidate, so no round
        // ever finds a match. With only one offset to cycle through, this must terminate immediately
        // rather than spin forever looking for a match that can never occur.
        System.assertEquals(1, slots.size(), 'With no slot ever matching the grid, nothing may be removed, and the call must still return');
    }

    @isTest
    static void testReduceSlots_fiftyPercentReduction_removesCeilingCountWithinWindowOnly() {
        List<sked__Slot__c> slots = new List<sked__Slot__c>{
            skedSlotGenerator.newSlot('Whole Blood', dt(10, 45), dt(11, 0)),  // outside window
            skedSlotGenerator.newSlot('Whole Blood', dt(11, 0), dt(11, 15)),
            skedSlotGenerator.newSlot('Whole Blood', dt(11, 15), dt(11, 30)),
            skedSlotGenerator.newSlot('Whole Blood', dt(11, 30), dt(11, 45)),
            skedSlotGenerator.newSlot('Whole Blood', dt(11, 45), dt(12, 0))
        };

        Test.startTest();
        skedSlotGenerator.reduceSlots(slots, dt(11, 0), dt(12, 0), 15, new List<Integer>{ 0 }, 50, TIMEZONE);
        Test.stopTest();

        // 4 slots fall inside [11:00,12:00]; ceil(4 * 0.5) = 2 removed, cycling from 11:00 in 15-minute
        // steps: 11:00 removed first, then 11:15 removed second, reaching the target count.
        System.assertEquals(3, slots.size(), 'Exactly 2 of the 4 in-window slots must be removed, leaving 3 (1 outside + 2 untouched inside)');
        for (sked__Slot__c slot : slots) {
            System.assertNotEquals(dt(11, 0), slot.sked_Start__c, '11:00 slot must have been removed');
            System.assertNotEquals(dt(11, 15), slot.sked_Start__c, '11:15 slot must have been removed');
        }
    }
}
