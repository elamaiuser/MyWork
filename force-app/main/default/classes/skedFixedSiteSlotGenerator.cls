/**
 * Ported from fixedSiteGenerator.js's per-procedure-type slot generators: generatePlateletSlots/
 * calculatePlateletGroupsQuantity, generateWbSlots/reduceWbSlotsForLunchBreak (built on the shared
 * skedSlotGenerator.generateSlots/reduceSlots primitives), and generate2rbcSlots/generatePlasmaSlots
 * (built on the shared skedSlotGenerator.generateSlotsByNumberOfAssets primitive). Returns plain
 * sked__Slot__c records with no parent/shift reference set - a future job-builder task attaches
 * them to a real Drive Shift.
 */
public with sharing class skedFixedSiteSlotGenerator {

    private static final Integer PLATELET_SLOT_DURATION_MINUTES = 180;

    public static List<sked__Slot__c> generatePlateletSlots(sked__Location__c driveSite, Integer numberOfPlateletAssets,
            List<skedTimeRange> rounds, String timezoneSidId) {
        List<sked__Slot__c> slots = new List<sked__Slot__c>();
        if (numberOfPlateletAssets == null || numberOfPlateletAssets <= 0) {
            return slots;
        }

        List<Integer> minutesIntoStartOffsets = getMinutesIntoStartOffsets(driveSite.sked_Fixed_Site_Appointment_Pattern__c, numberOfPlateletAssets);
        List<Integer> groupQuantities = calculateGroupQuantities(minutesIntoStartOffsets.size(), numberOfPlateletAssets);

        for (skedTimeRange round : rounds) {
            // slotEnd is always roundStart + 180min, NOT slotStart + 180min - an offset slot is
            // therefore shorter than 180 minutes, matching fixedSiteGenerator.js:1731-1732 exactly.
            DateTime slotEnd = skedDateTimeUtils.addMinutes(round.rangeStart, PLATELET_SLOT_DURATION_MINUTES, timezoneSidId);
            for (Integer i = 0; i < minutesIntoStartOffsets.size(); i++) {
                DateTime slotStart = skedDateTimeUtils.addMinutes(round.rangeStart, minutesIntoStartOffsets[i], timezoneSidId);
                for (Integer j = 0; j < groupQuantities[i]; j++) {
                    slots.add(skedSlotGenerator.newSlot(skedConstants.PROCEDURE_TYPE_PLATELET, slotStart, slotEnd));
                }
            }
        }
        return slots;
    }

    // A blank pattern falls back to Grouped per fixedSiteGenerator.js:1683; an unrecognized non-blank
    // value would yield zero slots in the JS, Grouped here instead - unreachable today since the
    // picklist is restricted to exactly these 3 values.
    private static List<Integer> getMinutesIntoStartOffsets(String appointmentPattern, Integer numberOfPlateletAssets) {
        if (appointmentPattern == skedConstants.FIXED_SITE_APPOINTMENT_PATTERN_EVEN) {
            return trimToSize(new List<Integer>{ 0, 15, 30 }, Math.min(numberOfPlateletAssets, 3));
        }
        if (appointmentPattern == skedConstants.FIXED_SITE_APPOINTMENT_PATTERN_EVEN_4_INTERVAL) {
            return trimToSize(new List<Integer>{ 0, 30, 15, 45 }, Math.min(numberOfPlateletAssets, 4));
        }
        return numberOfPlateletAssets <= 2 ? new List<Integer>{ 0 } : new List<Integer>{ 0, 30 };
    }

    private static List<Integer> trimToSize(List<Integer> offsets, Integer size) {
        List<Integer> trimmed = new List<Integer>();
        for (Integer i = 0; i < size; i++) {
            trimmed.add(offsets[i]);
        }
        return trimmed;
    }

    // Ceiling-distributes numberOfPlateletAssets across groupCount groups within a single round
    // (fixedSiteGenerator.js:1665-1680) - same clamped-ceiling-division pattern already used for
    // drive-shift rounds (skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata) and role
    // time detail. groupCount is the number of appointment-pattern offsets, NOT the drive's own
    // 3-hour rounds - the JS's own parameter naming here ("allRounds") is misleading, see Global Constraints.
    private static List<Integer> calculateGroupQuantities(Integer groupCount, Integer numberOfPlateletAssets) {
        List<Integer> quantities = new List<Integer>();
        Integer remaining = numberOfPlateletAssets;
        for (Integer i = 0; i < groupCount; i++) {
            Integer quantity = Integer.valueOf(Math.ceil(Decimal.valueOf(remaining) / (groupCount - i)));
            if (quantity > remaining) {
                quantity = remaining;
            }
            quantities.add(quantity);
            remaining -= quantity;
        }
        return quantities;
    }

    private static final List<Integer> WB_GENERATION_ROUND_MINUTES_INTO_START = new List<Integer>{ 0, 15, 30, 45 };
    private static final List<Integer> LUNCH_BREAK_REDUCTION_ROUND_MINUTES_INTO_START = new List<Integer>{ 0, 30, 15, 45 };
    private static final Integer WB_INTERVAL_MINUTES = 60;
    private static final Integer WB_SLOT_DURATION_MINUTES = 15;
    private static final Integer WB_SLOT_TYPE_END_ADJUSTMENT_MINUTES = 15;
    private static final String SLOT_TYPE_WHOLE_BLOOD = 'Whole Blood';
    private static final List<String> WB_LUNCH_BREAK_STAFF_SETUP_ROLES = new List<String>{ 'Apheresis', 'Apheresis Charge' };

    public class MasterData {
        public String timezoneSidId;
        public List<sked_Fixed_Site_Procedure_Projection__c> fixedSiteProcedureProjections = new List<sked_Fixed_Site_Procedure_Projection__c>();
        public Decimal callListRecipientNoneFixedSiteCapacity;
        public Decimal slotGeneratorOverridePercent;
        public Boolean skipLastAppointmentForFixedSite = false;
        public List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = new List<sked_Lunch_Break_Setting__c>();
    }

    // Requires the drive to be queried with sked_Account__c, sked_Collection_Operation__c,
    // sked_Opportunity__r.Slot_Generator__c.
    public static MasterData loadMasterData(sked_Drive__c drive) {
        MasterData masterData = new MasterData();
        masterData.timezoneSidId = UserInfo.getTimeZone().getID();

        masterData.fixedSiteProcedureProjections = [
            SELECT Id, sked_Procedure_Type__c, sked_QNS__c, sked_Deferral__c
            FROM sked_Fixed_Site_Procedure_Projection__c
            WHERE sked_Account__c = :drive.sked_Account__c
                AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
        ];

        sked_Admin_Setting__c adminSetting = sked_Admin_Setting__c.getOrgDefaults();
        // Matches baseGenerator.js:139's shared /100 scaling of the raw admin setting value.
        masterData.callListRecipientNoneFixedSiteCapacity = adminSetting.Admin_Call_List_Recipient_None_FS__c == null
            ? 0 : adminSetting.Admin_Call_List_Recipient_None_FS__c / 100;
        masterData.slotGeneratorOverridePercent = drive.sked_Opportunity__r.Slot_Generator__c == null
            ? null : drive.sked_Opportunity__r.Slot_Generator__c / 100;

        Biomed_Collection_Op_Center__c collectionOperation = [
            SELECT Id, sked_Skip_Last_Appointment_For__c FROM Biomed_Collection_Op_Center__c WHERE Id = :drive.sked_Collection_Operation__c
        ];
        masterData.skipLastAppointmentForFixedSite = collectionOperation.sked_Skip_Last_Appointment_For__c != null
            && collectionOperation.sked_Skip_Last_Appointment_For__c.contains(skedConstants.DRIVE_TYPE_FIXED_SITE);

        masterData.lunchBreakSettingsConfig = skedLunchBreakCalculator.loadLunchBreakSettings();

        return masterData;
    }

    public static List<sked__Slot__c> generateWbSlots(sked_Drive__c drive, skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift,
            Boolean isLastShift, List<skedTimeRange> excludedTimeRanges, MasterData masterData) {
        sked_Fixed_Site_Procedure_Projection__c wbSetting = findProcedureProjection(masterData.fixedSiteProcedureProjections, skedConstants.PROCEDURE_TYPE_WB);
        Decimal projectedProcedures = drive.sked_WB_Projected_Procedures__c == null ? 0 : drive.sked_WB_Projected_Procedures__c;

        Decimal x = 0;
        if (wbSetting != null) {
            Decimal qns = wbSetting.sked_QNS__c == null ? 0 : wbSetting.sked_QNS__c;
            Decimal deferral = wbSetting.sked_Deferral__c == null ? 0 : wbSetting.sked_Deferral__c;
            Decimal qnsFactor = 1 - qns / 100;
            Decimal deferralFactor = 1 - deferral / 100;
            // Deliberate Apex-only guard (same pattern as skedFixedSiteRoleQuantityCalculator) - the
            // JS's division here has no protection and would silently produce NaN/Infinity in JS;
            // Apex throws on a zero/negative denominator instead, so guard explicitly.
            if (qnsFactor > 0 && deferralFactor > 0) {
                x = Math.ceil(projectedProcedures / qnsFactor / deferralFactor);
            }
        }

        Decimal paddingPercentage = masterData.slotGeneratorOverridePercent != null
            ? masterData.slotGeneratorOverridePercent : masterData.callListRecipientNoneFixedSiteCapacity;
        Integer totalSlots = Integer.valueOf(Math.ceil(x * paddingPercentage));

        DateTime shiftStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.startTime, masterData.timezoneSidId);
        DateTime shiftEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.endTime, masterData.timezoneSidId);

        DateTime lastSlotStart;
        if (isLastShift) {
            lastSlotStart = masterData.skipLastAppointmentForFixedSite
                ? skedDateTimeUtils.addMinutes(shiftEnd, -WB_SLOT_TYPE_END_ADJUSTMENT_MINUTES, masterData.timezoneSidId)
                : shiftEnd;
        } else {
            lastSlotStart = skedDateTimeUtils.addMinutes(shiftEnd, -WB_SLOT_TYPE_END_ADJUSTMENT_MINUTES, masterData.timezoneSidId);
        }

        return skedSlotGenerator.generateSlots(SLOT_TYPE_WHOLE_BLOOD, shiftStart, lastSlotStart, WB_INTERVAL_MINUTES,
            WB_SLOT_DURATION_MINUTES, WB_GENERATION_ROUND_MINUTES_INTO_START, totalSlots, masterData.timezoneSidId, excludedTimeRanges);
    }

    private static sked_Fixed_Site_Procedure_Projection__c findProcedureProjection(
            List<sked_Fixed_Site_Procedure_Projection__c> projections, String procedureType) {
        for (sked_Fixed_Site_Procedure_Projection__c projection : projections) {
            if (projection.sked_Procedure_Type__c == procedureType) {
                return projection;
            }
        }
        return null;
    }

    // A separate step from generateWbSlots because calculateStaffSetup needs real Job records
    // (fixedSiteGenerator.js:1610) that don't exist until a future job-builder task creates them -
    // call this only after that. Gates and writes on shiftRecord (sked_Drive_Shift__c), NOT the
    // freshly computed shift metadata - fixedSiteGenerator.js:1605-1634 reads/writes
    // driveShift.lunchBreak/lunchBreakBeforeDrawHours/lunchBreakStartTime/lunchBreakEndTime/
    // signUpReduction, and those can differ from the metadata's fresh values when
    // sked_Lock_Lunch_Break__c restored the record's booleans from a prior shift (see
    // skedLunchBreakCalculator's own header comment on that lock/restore behavior).
    public static void reduceWbSlotsForLunchBreak(List<sked__Slot__c> wbSlots, List<sked__Job__c> jobs,
            sked_Drive_Shift__c shiftRecord, skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift, MasterData masterData) {
        if (shiftRecord.sked_Lunch_Break__c != true) {
            return;
        }
        if (shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c == true) {
            shiftRecord.sked_Sign_Up_Reduction__c = null;
            return;
        }
        // wbSlots.isEmpty() has no signUpReduction equivalent in the JS (fixedSiteGenerator.js's inner
        // branch never assigns it here) - deliberately left untouched, not nulled, on this path.
        if (wbSlots.isEmpty()) {
            return;
        }
        sked_Lunch_Break_Setting__c matchedSetting = skedLunchBreakCalculator.findLunchBreakSetting(
            masterData.lunchBreakSettingsConfig, shift.lunchBreakSettings.maximumLunchBreakDuration);
        Decimal staffSetup = skedLunchBreakCalculator.calculateStaffSetup(jobs, WB_LUNCH_BREAK_STAFF_SETUP_ROLES);
        sked_Lunch_Break_Definition__c matchedDefinition = skedLunchBreakCalculator.findLunchBreakDefinition(matchedSetting, staffSetup);

        DateTime lunchStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shiftRecord.sked_Lunch_Break_Start_Time__c, masterData.timezoneSidId);
        DateTime lunchEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shiftRecord.sked_Lunch_Break_End_Time__c, masterData.timezoneSidId);
        skedSlotGenerator.reduceSlots(wbSlots, lunchStart, lunchEnd, WB_INTERVAL_MINUTES,
            LUNCH_BREAK_REDUCTION_ROUND_MINUTES_INTO_START, matchedDefinition.sked_Slot_Reduction__c, masterData.timezoneSidId);
        shiftRecord.sked_Sign_Up_Reduction__c = matchedDefinition.sked_Slot_Reduction__c;
    }

    private static final Integer TWO_RBC_ROUND_INTERVAL_MINUTES = 60;
    private static final Integer TWO_RBC_GROUP_COUNT = 2;
    private static final Integer TWO_RBC_GROUP_INTERVAL_MINUTES = 30;
    private static final Integer TWO_RBC_SLOT_DURATION_MINUTES = 60;
    private static final Integer TWO_RBC_LAST_SLOT_END_BUFFER_MINUTES = 30;

    private static final Integer PLASMA_ROUND_INTERVAL_MINUTES = 90;
    private static final Integer PLASMA_GROUP_COUNT = 2;
    private static final Integer PLASMA_GROUP_INTERVAL_MINUTES = 30;
    private static final Integer PLASMA_SLOT_DURATION_MINUTES = 90;
    private static final Integer PLASMA_FIRST_SLOT_ANCHOR_MINUTES = 60;
    private static final Integer PLASMA_LAST_SLOT_END_BUFFER_MINUTES = 50;

    public static List<sked__Slot__c> generate2rbcSlots(sked_Drive__c drive, skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift,
            List<skedTimeRange> excludedTimeRanges, String timezoneSidId) {
        DateTime shiftStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.startTime, timezoneSidId);
        DateTime shiftEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.endTime, timezoneSidId);
        DateTime lastSlotStart = skedDateTimeUtils.addMinutes(shiftEnd, -TWO_RBC_LAST_SLOT_END_BUFFER_MINUTES, timezoneSidId);

        return skedSlotGenerator.generateSlotsByNumberOfAssets(skedConstants.PROCEDURE_TYPE_2RBC, shiftStart, lastSlotStart,
            TWO_RBC_ROUND_INTERVAL_MINUTES, TWO_RBC_GROUP_COUNT, TWO_RBC_GROUP_INTERVAL_MINUTES, TWO_RBC_SLOT_DURATION_MINUTES,
            drive.sked_Number_of_2RBC_Assets__c, excludedTimeRanges, timezoneSidId);
    }

    public static List<sked__Slot__c> generatePlasmaSlots(sked_Drive__c drive, skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift,
            Boolean isLastShift, List<skedTimeRange> excludedTimeRanges, String timezoneSidId) {
        Decimal numberOfPlasmaAssets = drive.sked_Number_of_Plasma_Assets__c;
        if (numberOfPlasmaAssets == null || numberOfPlasmaAssets <= 0) {
            return new List<sked__Slot__c>();
        }

        DateTime shiftStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.startTime, timezoneSidId);
        DateTime shiftEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.endTime, timezoneSidId);

        DateTime firstSlotStart = skedDateTimeUtils.addMinutes(shiftStart, PLASMA_FIRST_SLOT_ANCHOR_MINUTES, timezoneSidId);
        Integer startMinute = skedMobileDriveShiftCalculator.extractLocalTime(firstSlotStart, timezoneSidId).minute();
        // fixedSiteGenerator.js:1758-1766's mutable Date.setMinutes rounding, ported via a timezone-aware
        // minute delta (DateTime is immutable in Apex) - >40 rolls to the next hour's :10 via addMinutes.
        if (startMinute > 40) {
            firstSlotStart = skedDateTimeUtils.addMinutes(setMinutesOfHour(firstSlotStart, 40, timezoneSidId), 30, timezoneSidId);
        } else if (startMinute > 10) {
            firstSlotStart = setMinutesOfHour(firstSlotStart, 40, timezoneSidId);
        } else {
            firstSlotStart = setMinutesOfHour(firstSlotStart, 10, timezoneSidId);
        }

        DateTime lastSlotStart = isLastShift
            ? skedDateTimeUtils.addMinutes(shiftEnd, -PLASMA_LAST_SLOT_END_BUFFER_MINUTES, timezoneSidId)
            : shiftEnd;

        return skedSlotGenerator.generateSlotsByNumberOfAssets(skedConstants.PROCEDURE_TYPE_PLASMA, firstSlotStart, lastSlotStart,
            PLASMA_ROUND_INTERVAL_MINUTES, PLASMA_GROUP_COUNT, PLASMA_GROUP_INTERVAL_MINUTES, PLASMA_SLOT_DURATION_MINUTES,
            numberOfPlasmaAssets, excludedTimeRanges, timezoneSidId);
    }

    private static DateTime setMinutesOfHour(DateTime dt, Integer targetMinute, String timezoneSidId) {
        Integer currentMinute = skedMobileDriveShiftCalculator.extractLocalTime(dt, timezoneSidId).minute();
        return skedDateTimeUtils.addMinutes(dt, targetMinute - currentMinute, timezoneSidId);
    }
}
