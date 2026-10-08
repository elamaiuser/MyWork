/**
 * Ported only from the slwcDriveGenerator LWC's fixedSiteGenerator.js, never from a legacy class -
 * Fixed Site has no legacy interactive-Apex equivalent to compare against.
 *
 * Scope: the pure, side-effect-free calculation chain - calculateDriveShiftsMetadata, covering
 * rounds-based shift splitting and all 4 procedure types' projection splitting. Role-time/travel-time
 * itself lives in skedRoleTimeCalculator (drive-type-agnostic, shared with Mobile). This class never
 * runs for a WB Fixed Site drive (see the plan's Global Constraints) and has no entry gate of its own -
 * that belongs to a future engine task, same as Mobile's own calculateDriveShiftsMetadata.
 */
public with sharing class skedFixedSiteDriveShiftCalculator {

    public class DriveShiftMetadata extends skedDriveShiftMetadata {
        public String key;
        public String label;
        public Integer numberOfRounds = 0;
        public List<skedTimeRange> rounds = new List<skedTimeRange>();
        public Decimal x2rbcProjectedProcedures = 0;
        public Decimal wbProjectedProcedures = 0;
        public Decimal plateletProjectedProcedures = 0;
        public Decimal plasmaProjectedProcedures = 0;
        public Decimal totalProceduresProjected = 0;
        public Decimal totalProductsProjected = 0;
        public Map<String, skedRoleTimeData> resourceRoleGroupRoleTimeDataMap;
    }

    public class DriveShiftsMetadata {
        public Decimal x2rbcProjectedProcedures = 0;
        public Decimal wbProjectedProcedures = 0;
        public Decimal plateletProjectedProcedures = 0;
        public Decimal plasmaProjectedProcedures = 0;
        public Integer numberOfDriveShifts = 0;
        public List<DriveShiftMetadata> driveShifts = new List<DriveShiftMetadata>();
        public Map<String, skedRoleTimeData> resourceRoleGroupRoleTimeDataMap;
        public Decimal totalProceduresProjected = 0;
        public Decimal totalProductsProjected = 0;
    }

    public class MasterData {
        public String timezoneSidId;
        public Map<String, sked_Role_Time_Detail__c> roleGroupTimeDetailMap = new Map<String, sked_Role_Time_Detail__c>();
        public Map<String, List<sked_Role_Time_Variance__c>> roleGroupTimeVarianceMap = new Map<String, List<sked_Role_Time_Variance__c>>();
        public Map<String, sked_Travel_Time_Index_Item__c> travelTimeIndexItemMap = new Map<String, sked_Travel_Time_Index_Item__c>();
        public sked__Location__c driveSite;
        public Biomed_Collection_Op_Center__c collectionOperation;
    }

    // Fixed Site's lunch-break-eligible resourceRoleGroupsFilter (helper.js:1813, "if Fixed Site,
    // exclude driving roles group") - Driving roles don't exist on a Fixed Site shift.
    private static final List<String> LUNCH_BREAK_RESOURCE_ROLE_GROUPS_FILTER = new List<String>{
        skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES,
        skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES
    };
    private static final Integer ROUND_DURATION_MINUTES = 180;
    private static final Integer EXCLUSION_DURATION_MINUTES = 60;
    private static final Integer MIN_DRIVE_SHIFTS = 1;
    private static final Integer MAX_DRIVE_SHIFTS = 2;

    // ===== Master data retrieval =====

    /**
     * @param drive Caller must have queried: sked_Drive_Site__c, sked_Collection_Operation__c, sked_Drive_Date__c,
     * sked_Start_Time__c, sked_End_Time__c, sked_Operation_Type__c.
     */
    public static MasterData loadMasterData(sked_Drive__c drive) {
        MasterData masterData = new MasterData();
        masterData.timezoneSidId = UserInfo.getTimeZone().getID();

        masterData.driveSite = [
            SELECT Id, sked_Physical_Location_Type__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,
                sked_Travel_Time_to_Staging_Location__c
            FROM sked__Location__c
            WHERE Id = :drive.sked_Drive_Site__c
        ];

        masterData.collectionOperation = [
            SELECT Id, sked_Breakdown_Time_Threshold__c, sked_Setup_Time_Threshold__c, sked_Lunch_Break__c,
                sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Duration_Fixed_Site__c, sked_Unpaid_Lunch_Break_Duration__c,
                sked_No_Travel_Time__c,
                (SELECT Id, sked_Start_Date__c, sked_End_Date__c,
                    sked_Staging_Location__r.sked_GeoLocation__Latitude__s, sked_Staging_Location__r.sked_GeoLocation__Longitude__s
                 FROM sked_Collection_Op_Staging_Locations__r)
            FROM Biomed_Collection_Op_Center__c
            WHERE Id = :drive.sked_Collection_Operation__c
        ];

        String dayOfWeekName = skedMobileDriveShiftCalculator.getDayOfWeekName(drive.sked_Drive_Date__c);

        // INCLUDES/EXCLUDES don't accept bind variables in Apex SOQL, so the day-of-week match is done in-memory instead.
        for (sked_Role_Time_Detail__c rtd : [
            SELECT Id, sked_Type__c, sked_Resource_Role_Group__c, sked_Days_of_Week__c, sked_Lead_Time__c, sked_Setup_Time__c,
                sked_Breakdown_Time__c, sked_Wrap_up_Time__c
            FROM sked_Role_Time_Detail__c
            WHERE (sked_Type__c = 'Global' OR sked_Collection_Operation__c = :drive.sked_Collection_Operation__c)
                AND sked_Drive_Type__c = :skedConstants.DRIVE_TYPE_FIXED_SITE
                AND sked_Mobile_Type__c = :masterData.driveSite.sked_Physical_Location_Type__c
                AND (sked_Fixed_Site_Operation_Type__c = NULL OR sked_Fixed_Site_Operation_Type__c = :drive.sked_Operation_Type__c)
                AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
        ]) {
            if (!includesDayOfWeek(rtd.sked_Days_of_Week__c, dayOfWeekName)) {
                continue;
            }
            // Collection-Operation-specific rows override Global for the same group (query order: Global first).
            for (String resourceRoleGroup : rtd.sked_Resource_Role_Group__c.split(';')) {
                if (rtd.sked_Type__c == 'Global' || !masterData.roleGroupTimeDetailMap.containsKey(resourceRoleGroup)) {
                    masterData.roleGroupTimeDetailMap.put(resourceRoleGroup, rtd);
                }
            }
        }
        for (sked_Role_Time_Detail__c rtd : [
            SELECT Id, sked_Type__c, sked_Resource_Role_Group__c, sked_Days_of_Week__c, sked_Lead_Time__c, sked_Setup_Time__c,
                sked_Breakdown_Time__c, sked_Wrap_up_Time__c
            FROM sked_Role_Time_Detail__c
            WHERE sked_Type__c = 'Collection Operation' AND sked_Collection_Operation__c = :drive.sked_Collection_Operation__c
                AND sked_Drive_Type__c = :skedConstants.DRIVE_TYPE_FIXED_SITE
                AND sked_Mobile_Type__c = :masterData.driveSite.sked_Physical_Location_Type__c
                AND (sked_Fixed_Site_Operation_Type__c = NULL OR sked_Fixed_Site_Operation_Type__c = :drive.sked_Operation_Type__c)
                AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
        ]) {
            if (!includesDayOfWeek(rtd.sked_Days_of_Week__c, dayOfWeekName)) {
                continue;
            }
            for (String resourceRoleGroup : rtd.sked_Resource_Role_Group__c.split(';')) {
                masterData.roleGroupTimeDetailMap.put(resourceRoleGroup, rtd);
            }
        }

        for (sked_Role_Time_Variance__c rtv : [
            SELECT Id, sked_Resource_Role_Group__c, sked_Buffer_Type__c, sked_Variance_Applies_to__c, sked_Variation_Amount__c, sked_Days_Of_Week__c
            FROM sked_Role_Time_Variance__c
            WHERE sked_Location__c = :drive.sked_Drive_Site__c
                AND sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c
                AND sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c
        ]) {
            if (!includesDayOfWeek(rtv.sked_Days_Of_Week__c, dayOfWeekName)) {
                continue;
            }
            for (String resourceRoleGroup : rtv.sked_Resource_Role_Group__c.split(';')) {
                if (!masterData.roleGroupTimeVarianceMap.containsKey(resourceRoleGroup)) {
                    masterData.roleGroupTimeVarianceMap.put(resourceRoleGroup, new List<sked_Role_Time_Variance__c>());
                }
                masterData.roleGroupTimeVarianceMap.get(resourceRoleGroup).add(rtv);
            }
        }

        masterData.travelTimeIndexItemMap = skedRoleTimeCalculator.loadTravelTimeIndexItemMap(
            masterData.driveSite, masterData.collectionOperation, drive.sked_Drive_Date__c);

        return masterData;
    }

    private static Boolean includesDayOfWeek(String semicolonDelimitedDays, String dayName) {
        if (String.isBlank(semicolonDelimitedDays)) {
            return false;
        }
        return semicolonDelimitedDays.split(';').indexOf(dayName) >= 0;
    }

    // ===== Platelet rounds / shift splitting =====

    /*
      HRP-10428
      Any drive up to 3 hours defaults to 1 round, over 3 up to 6 hours to 2 rounds, over 6 up to 9
      hours to 3 rounds, over 9 up to 12 hours to 4 rounds, over 12 hours to 5 rounds.
    */
    public static Integer calculatePlateletRounds(sked_Drive__c drive, String timezoneSidId) {
        if (drive.sked_Drive_Date__c == null || drive.sked_Start_Time__c == null || drive.sked_End_Time__c == null) {
            return 0;
        }
        Integer driveDrawHoursInMinutes = skedMobileDriveShiftCalculator.calculateDrawHoursInMinutes(
            drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, timezoneSidId, null);

        if (driveDrawHoursInMinutes <= 3 * 60) {
            return 1;
        }
        if (driveDrawHoursInMinutes <= 6 * 60) {
            return 2;
        }
        if (driveDrawHoursInMinutes <= 9 * 60) {
            return 3;
        }
        if (driveDrawHoursInMinutes <= 12 * 60) {
            return 4;
        }
        return 5;
    }

    // Guards only roundStart < shiftEnd (matching fixedSiteGenerator.js:1434) - a round's END can
    // overrun its shift's end; this is a deliberate port of the JS's own behavior, not a bug.
    public static List<skedTimeRange> generateDriveShiftRounds(DateTime shiftStart, DateTime shiftEnd, Integer numberOfRounds, String timezoneSidId) {
        List<skedTimeRange> rounds = new List<skedTimeRange>();
        for (Integer i = 0; i < numberOfRounds; i++) {
            DateTime roundStart = skedDateTimeUtils.addMinutes(shiftStart, i * ROUND_DURATION_MINUTES, timezoneSidId);
            DateTime roundEnd = skedDateTimeUtils.addMinutes(roundStart, ROUND_DURATION_MINUTES, timezoneSidId);
            if (roundStart < shiftEnd) {
                skedTimeRange round = new skedTimeRange();
                round.rangeStart = roundStart;
                round.rangeEnd = roundEnd;
                rounds.add(round);
            }
        }
        return rounds;
    }

    // Feeds skedSlotGenerator.generateSlots's excludedTimeRanges parameter (not wired up until a
    // future slot-generation task) - one 1-hour exclusion window per round.
    public static List<skedTimeRange> generateExcludedTimeRangesFromPlateletRounds(List<skedTimeRange> rounds, String timezoneSidId) {
        List<skedTimeRange> excludedTimeRanges = new List<skedTimeRange>();
        for (skedTimeRange round : rounds) {
            skedTimeRange excluded = new skedTimeRange();
            excluded.rangeStart = round.rangeStart;
            excluded.rangeEnd = skedDateTimeUtils.addMinutes(round.rangeStart, EXCLUSION_DURATION_MINUTES, timezoneSidId);
            excludedTimeRanges.add(excluded);
        }
        return excludedTimeRanges;
    }

    // ===== Drive Shifts metadata =====

    /**
     * @param drive Caller must have queried, in addition to loadMasterData's requirements: sked_Account__r.Accepts_Automation2__c,
     * sked_Travel_Time_Included__c, sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c,
     * sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c.
     */
    public static DriveShiftsMetadata calculateDriveShiftsMetadata(sked_Drive__c drive, MasterData masterData) {
        DriveShiftsMetadata shiftsMetadata = new DriveShiftsMetadata();
        shiftsMetadata.x2rbcProjectedProcedures = drive.sked_2RBC_Projected_Procedures__c == null ? 0 : drive.sked_2RBC_Projected_Procedures__c;
        shiftsMetadata.wbProjectedProcedures = drive.sked_WB_Projected_Procedures__c == null ? 0 : drive.sked_WB_Projected_Procedures__c;
        shiftsMetadata.plateletProjectedProcedures = drive.sked_Platelet_Projected_Procedures__c == null ? 0 : drive.sked_Platelet_Projected_Procedures__c;
        shiftsMetadata.plasmaProjectedProcedures = drive.sked_Plasma_Projected_Procedures__c == null ? 0 : drive.sked_Plasma_Projected_Procedures__c;
        shiftsMetadata.resourceRoleGroupRoleTimeDataMap = skedRoleTimeCalculator.calculateDriveRoleTimeData(
            drive, masterData.roleGroupTimeDetailMap, masterData.roleGroupTimeVarianceMap,
            masterData.collectionOperation, masterData.driveSite, masterData.travelTimeIndexItemMap, masterData.timezoneSidId);

        if (drive.sked_Drive_Date__c != null && drive.sked_Start_Time__c != null && drive.sked_End_Time__c != null) {
            DateTime driveStart = skedDateTimeUtils.getDateTimeFromDateAndTime(drive.sked_Drive_Date__c, drive.sked_Start_Time__c, masterData.timezoneSidId);
            DateTime driveEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(drive.sked_Drive_Date__c, drive.sked_End_Time__c, masterData.timezoneSidId);
            Integer totalRounds = calculatePlateletRounds(drive, masterData.timezoneSidId);

            Integer numberOfDriveShifts = Integer.valueOf(Math.ceil(Decimal.valueOf(totalRounds) / 3));
            if (numberOfDriveShifts < MIN_DRIVE_SHIFTS) {
                numberOfDriveShifts = MIN_DRIVE_SHIFTS;
            }
            if (numberOfDriveShifts > MAX_DRIVE_SHIFTS) {
                numberOfDriveShifts = MAX_DRIVE_SHIFTS;
            }

            Integer remainingRounds = totalRounds;
            DateTime lastShiftEnd = driveStart;
            // Carried into the next shift's round anchor (see the plan's Global Constraints) -
            // structurally always null-or-equal-to-shiftStart given the <=2-shift clamp, kept for
            // fidelity with fixedSiteGenerator.js:834-867.
            DateTime lastRoundEnd = null;
            for (Integer i = 0; i < numberOfDriveShifts; i++) {
                Integer numberOfRounds = Integer.valueOf(Math.ceil(Decimal.valueOf(remainingRounds) / (numberOfDriveShifts - i)));
                if (numberOfRounds > remainingRounds) {
                    numberOfRounds = remainingRounds;
                }

                DateTime shiftStart = lastShiftEnd;
                DateTime shiftEnd = i == numberOfDriveShifts - 1
                    ? driveEnd
                    : skedDateTimeUtils.addMinutes(shiftStart, numberOfRounds * ROUND_DURATION_MINUTES, masterData.timezoneSidId);

                DateTime roundAnchor = (lastRoundEnd != null && lastRoundEnd > shiftStart) ? lastRoundEnd : shiftStart;
                List<skedTimeRange> rounds = generateDriveShiftRounds(roundAnchor, shiftEnd, numberOfRounds, masterData.timezoneSidId);

                DriveShiftMetadata shift = new DriveShiftMetadata();
                shift.key = 'drive_shift_' + i;
                shift.label = 'Drive Shift ' + (i + 1);
                shift.driveDate = drive.sked_Drive_Date__c;
                shift.startTime = skedMobileDriveShiftCalculator.extractLocalTime(shiftStart, masterData.timezoneSidId);
                shift.endTime = skedMobileDriveShiftCalculator.extractLocalTime(shiftEnd, masterData.timezoneSidId);
                shift.numberOfRounds = rounds.size();
                shift.rounds = rounds;
                shiftsMetadata.driveShifts.add(shift);

                remainingRounds -= numberOfRounds;
                lastShiftEnd = shiftEnd;
                lastRoundEnd = rounds.isEmpty() ? null : rounds[rounds.size() - 1].rangeEnd;
            }

            shiftsMetadata.numberOfDriveShifts = shiftsMetadata.driveShifts.size();

            // showWBField/show2RBCField reduce to an Integrated-only check here (see Global
            // Constraints) - showPlateletField/showPlasmaField are unconditionally true.
            Boolean isIntegrated = drive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_INTEGRATED;
            // sked_Account__c isn't required on sked_Drive__c - mirrors the JS's own `drive && drive.account && ...` guard.
            Boolean accountAcceptsAutomation = drive.sked_Account__r != null && drive.sked_Account__r.Accepts_Automation2__c == 'Yes';
            if (accountAcceptsAutomation && isIntegrated) {
                splitProjectedProcedures(shiftsMetadata, skedConstants.PROCEDURE_TYPE_2RBC);
            }
            if (isIntegrated) {
                splitProjectedProcedures(shiftsMetadata, skedConstants.PROCEDURE_TYPE_WB);
            }
            splitProjectedProcedures(shiftsMetadata, skedConstants.PROCEDURE_TYPE_PLATELET);
            splitProjectedProcedures(shiftsMetadata, skedConstants.PROCEDURE_TYPE_PLASMA);
            // splitScheduledDonors is deliberately not called - Fixed Site has no donor-count concept (helper.js:267 hard-returns for it).

            applyProcedureTotals(shiftsMetadata);

            for (Integer i = 0; i < shiftsMetadata.driveShifts.size(); i++) {
                DriveShiftMetadata shift = shiftsMetadata.driveShifts[i];
                applyProcedureTotals(shift);
                shift.resourceRoleGroupRoleTimeDataMap = skedRoleTimeCalculator.calculateDriveShiftRoleTimeData(
                    drive, masterData.collectionOperation, masterData.driveSite, masterData.travelTimeIndexItemMap, masterData.timezoneSidId,
                    shiftsMetadata.resourceRoleGroupRoleTimeDataMap, shift.driveDate, shift.startTime, shift.endTime, i, shiftsMetadata.driveShifts.size());
                shift.lunchBreakSettings = skedRoleTimeCalculator.calculateDriveShiftLunchBreakSettings(
                    masterData.collectionOperation, masterData.collectionOperation.sked_Lunch_Break_Duration_Fixed_Site__c, masterData.timezoneSidId,
                    shift.resourceRoleGroupRoleTimeDataMap, shift.driveDate, shift.startTime, shift.endTime,
                    LUNCH_BREAK_RESOURCE_ROLE_GROUPS_FILTER, false);
            }
        }

        return shiftsMetadata;
    }

    private static void splitProjectedProcedures(DriveShiftsMetadata shiftsMetadata, String procedureType) {
        if (shiftsMetadata.driveShifts.isEmpty()) {
            return;
        }
        // excludeOverlappedTime/useRoundTimes are per-procedure-type axes mirroring helper.js's
        // splitProjectedProcedures dispatch (helper.js:303-304) - WB is the only type false on both.
        Boolean excludeOverlappedTime = procedureType != skedConstants.PROCEDURE_TYPE_WB;
        Boolean useRoundTimes = procedureType == skedConstants.PROCEDURE_TYPE_PLATELET || procedureType == skedConstants.PROCEDURE_TYPE_PLASMA;
        Decimal totalProjected = getProjectedProcedures(shiftsMetadata, procedureType);

        Map<String, Decimal> weightByKey = new Map<String, Decimal>();
        Decimal totalWeight = 0;
        for (Integer i = 0; i < shiftsMetadata.driveShifts.size(); i++) {
            DriveShiftMetadata shift = shiftsMetadata.driveShifts[i];
            Decimal weight;
            if (useRoundTimes) {
                weight = shift.numberOfRounds;
            } else {
                Decimal shiftStartMinutes = excludeOverlappedTime
                    ? shiftStartMinutesExcludingOverlap(shiftsMetadata.driveShifts, i)
                    : minutesOfDay(shift.startTime);
                Decimal shiftEndMinutes = minutesOfDay(shift.endTime);
                // helper.js:336-338 clamps a start past the end to the end unconditionally, not just
                // on the excludeOverlappedTime branch - mirrored here for both.
                if (shiftStartMinutes > shiftEndMinutes) {
                    shiftStartMinutes = shiftEndMinutes;
                }
                weight = shiftEndMinutes - shiftStartMinutes;
            }
            weightByKey.put(shift.key, weight);
            totalWeight += weight;
        }

        Decimal remaining = totalProjected;
        for (DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            // totalWeight == 0 short-circuits every shift to 0%, instead of JS's Math.ceil(NaN) - a
            // deliberate divergence (see Global Constraints), not an accidental omission.
            Decimal percentage = totalWeight == 0 ? 0 : weightByKey.get(shift.key) / totalWeight;
            Decimal scheduled = (totalProjected * percentage).setScale(0, System.RoundingMode.CEILING);
            if (scheduled > remaining) {
                scheduled = remaining;
            }
            remaining -= scheduled;
            setProjectedProcedures(shift, procedureType, scheduled);
        }
    }

    private static Decimal getProjectedProcedures(DriveShiftsMetadata shiftsMetadata, String procedureType) {
        if (procedureType == skedConstants.PROCEDURE_TYPE_2RBC) {
            return shiftsMetadata.x2rbcProjectedProcedures;
        }
        if (procedureType == skedConstants.PROCEDURE_TYPE_WB) {
            return shiftsMetadata.wbProjectedProcedures;
        }
        if (procedureType == skedConstants.PROCEDURE_TYPE_PLATELET) {
            return shiftsMetadata.plateletProjectedProcedures;
        }
        return shiftsMetadata.plasmaProjectedProcedures;
    }

    private static void setProjectedProcedures(DriveShiftMetadata shift, String procedureType, Decimal scheduled) {
        if (procedureType == skedConstants.PROCEDURE_TYPE_2RBC) {
            shift.x2rbcProjectedProcedures = scheduled;
        } else if (procedureType == skedConstants.PROCEDURE_TYPE_WB) {
            shift.wbProjectedProcedures = scheduled;
        } else if (procedureType == skedConstants.PROCEDURE_TYPE_PLATELET) {
            shift.plateletProjectedProcedures = scheduled;
        } else {
            shift.plasmaProjectedProcedures = scheduled;
        }
    }

    // Matches Mobile's own shiftStartMinutesExcludingOverlap - structurally unreachable today (see
    // Global Constraints) since this class always builds shifts back-to-back with no gap, kept for
    // parity with the JS's own defensive check.
    private static Decimal shiftStartMinutesExcludingOverlap(List<DriveShiftMetadata> shifts, Integer index) {
        DriveShiftMetadata shift = shifts[index];
        Time effectiveStartTime = shift.startTime;
        if (index > 0 && shifts[index - 1].endTime > shift.startTime) {
            effectiveStartTime = shifts[index - 1].endTime;
        }
        if (effectiveStartTime > shift.endTime) {
            effectiveStartTime = shift.endTime;
        }
        return minutesOfDay(effectiveStartTime);
    }

    private static Decimal minutesOfDay(Time t) {
        return t.hour() * 60 + t.minute();
    }

    private static void applyProcedureTotals(DriveShiftsMetadata shiftsMetadata) {
        shiftsMetadata.totalProceduresProjected = shiftsMetadata.x2rbcProjectedProcedures + shiftsMetadata.wbProjectedProcedures
            + shiftsMetadata.plateletProjectedProcedures + shiftsMetadata.plasmaProjectedProcedures;
        shiftsMetadata.totalProductsProjected = shiftsMetadata.x2rbcProjectedProcedures * 2 + shiftsMetadata.wbProjectedProcedures
            + shiftsMetadata.plateletProjectedProcedures + shiftsMetadata.plasmaProjectedProcedures;
    }

    private static void applyProcedureTotals(DriveShiftMetadata shift) {
        shift.totalProceduresProjected = shift.x2rbcProjectedProcedures + shift.wbProjectedProcedures
            + shift.plateletProjectedProcedures + shift.plasmaProjectedProcedures;
        shift.totalProductsProjected = shift.x2rbcProjectedProcedures * 2 + shift.wbProjectedProcedures
            + shift.plateletProjectedProcedures + shift.plasmaProjectedProcedures;
    }
}
