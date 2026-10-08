/**
 * Handles the from-scratch, initial-generation slot placement only. Builds sked__Slot__c records
 * (no sked_Drive_Shift__c Id set yet - wiring shift/job/slot parent Ids happens in a later
 * orchestration step once shifts are actually inserted, exactly like sked__Job__c already
 * works in skedMobileDriveJobBuilder) and attaches them to ProposedDriveShift.slots.
 *
 * Deliberately not handled: anything that exists to support INTERACTIVE editing of an
 * already-generated drive, none of which applies to a from-scratch batch regeneration -
 * single-slot edit/lock/unlock UI actions, overlap-checking against a backup of a previous
 * interactive edit. Excluded time ranges ARE part of the shared slot-generation contract (see
 * skedSlotGenerator.generateSlots) - Mobile's own regeneration path just never has any to pass.
 */
public with sharing class skedMobileSlotGenerator {

    private static final Integer TWO_RBC_ROUND_INTERVAL_MINUTES = 60;
    private static final Integer TWO_RBC_GROUP_COUNT = 2;
    private static final Integer TWO_RBC_GROUP_INTERVAL_MINUTES = 30;
    private static final Integer TWO_RBC_SLOT_DURATION_MINUTES = 60;
    private static final Integer TWO_RBC_LAST_SLOT_BUFFER_MINUTES = 30;

    private static final String SLOT_TYPE_2RBC = '2RBC';
    private static final String SLOT_TYPE_WHOLE_BLOOD = 'Whole Blood';
    private static final Integer WB_SLOT_DURATION_MINUTES = 15;
    private static final Integer WB_INTERVAL_MINUTES = 60;
    private static final List<Integer> WB_ROUND_MINUTES_INTO_START = new List<Integer>{ 0, 30, 15, 45 };
    private static final Integer WB_LAST_SLOT_BUFFER_MINUTES = 15;

    // Mobile's own staff-setup role list (mobileGenerator.js:2424). Duplicated from
    // skedMobileLunchBreakCalculator's private constant of the same name so the role-list-free entry
    // points below stay behaviorally identical for existing Mobile callers. WB Fixed Site
    // (wbFixedSiteGenerator.js:1837) drops 'Driver'/'Driver Support' and passes its own list instead.
    private static final List<String> MOBILE_STAFF_SETUP_ROLES = new List<String>{ 'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge' };

    /**
     * Requires shiftsMetadata.driveShifts and proposedShifts to be in the same order (guaranteed -
     * both come from the same skedMobileDriveJobBuilder.buildProposedDriveShifts pass).
     */
    public static void proposeDriveShiftSlots(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposedShifts,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            Decimal numberOf2rbcAssets, Decimal paddingPercentage, Boolean skipLastAppointment,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig, String timezoneSidId, Decimal adhocDriverSupportCapacity) {
        proposeDriveShiftSlots(proposedShifts, shiftsMetadata, staffingDecisionMatrix, numberOf2rbcAssets, paddingPercentage, skipLastAppointment,
            lunchBreakSettingsConfig, timezoneSidId, adhocDriverSupportCapacity, MOBILE_STAFF_SETUP_ROLES);
    }

    /**
     * staffSetupRoles is the only per-drive-type variation in this class - it feeds the lunch-break
     * headcount that selects the slot-reduction definition, and nothing else.
     */
    public static void proposeDriveShiftSlots(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposedShifts,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            Decimal numberOf2rbcAssets, Decimal paddingPercentage, Boolean skipLastAppointment,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig, String timezoneSidId, Decimal adhocDriverSupportCapacity,
            List<String> staffSetupRoles) {
        for (Integer i = 0; i < proposedShifts.size(); i++) {
            Boolean isLastShift = i == proposedShifts.size() - 1;
            generateShiftSlots(proposedShifts[i], shiftsMetadata.driveShifts[i], staffingDecisionMatrix, numberOf2rbcAssets,
                paddingPercentage, isLastShift, skipLastAppointment, lunchBreakSettingsConfig, timezoneSidId, adhocDriverSupportCapacity,
                staffSetupRoles);
        }
    }

    // The admin setting's callListRecipient/callListRecipientNone Percent fields (e.g. 115 for
    // "115%") must be scaled by /100, same as the Opportunity's Slot_Generator__c override - this is
    // the multiplier applied against driveShiftStaffCapacity in both branches. Left un-scaled, a
    // capacity of 128 produces ceil(128 * 115) = 14720 slots for one shift, which blows the Apex heap
    // limit. Scaled by /100 (128 * 1.15 = 148 slots), it matches "pad capacity by 15% for no-shows"
    // and sits in the same order of magnitude as the 2RBC slot count.
    // baseGenerator.js defaults to callListRecipient and only switches to callListRecipientNone when
    // an Opportunity exists AND its flag is falsy (baseGenerator.js's own `this.drive.opportunity &&
    // !this.drive.opportunity.callListRecipientExist` guard) - a null Opportunity must keep
    // callListRecipientCapacity, not fall to callListRecipientNoneCapacity.
    public static Decimal calculatePaddingPercentage(sked_Drive__c drive, skedMobileDriveShiftCalculator.MasterData masterData) {
        Boolean useNoneCapacity = drive.sked_Opportunity__r != null && drive.sked_Opportunity__r.Call_List_Recipient_Exist__c != true;
        Decimal paddingPercentage = useNoneCapacity ? masterData.callListRecipientNoneCapacity / 100 : masterData.callListRecipientCapacity / 100;
        if (drive.sked_Opportunity__r != null && drive.sked_Opportunity__r.Slot_Generator__c != null) {
            paddingPercentage = drive.sked_Opportunity__r.Slot_Generator__c / 100;
        }
        return paddingPercentage;
    }

    public static void generateShiftSlots(skedMobileDriveJobBuilder.ProposedDriveShift proposed,
            skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            Decimal numberOf2rbcAssets, Decimal paddingPercentage, Boolean isLastShift, Boolean skipLastAppointment,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig, String timezoneSidId, Decimal adhocDriverSupportCapacity) {
        generateShiftSlots(proposed, shiftMetadata, staffingDecisionMatrix, numberOf2rbcAssets, paddingPercentage, isLastShift, skipLastAppointment,
            lunchBreakSettingsConfig, timezoneSidId, adhocDriverSupportCapacity, MOBILE_STAFF_SETUP_ROLES);
    }

    public static void generateShiftSlots(skedMobileDriveJobBuilder.ProposedDriveShift proposed,
            skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            Decimal numberOf2rbcAssets, Decimal paddingPercentage, Boolean isLastShift, Boolean skipLastAppointment,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig, String timezoneSidId, Decimal adhocDriverSupportCapacity,
            List<String> staffSetupRoles) {
        sked_Drive_Shift__c shift = proposed.shiftRecord;
        proposed.slots = new List<sked__Slot__c>();
        if (shift.sked_Drive_Date__c == null || shift.sked_Start_Time__c == null || shift.sked_End_Time__c == null
                || shift.sked_Max_Donor_Capacity__c == null || staffingDecisionMatrix == null || proposed.jobs.isEmpty()) {
            return;
        }

        DateTime shiftStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.sked_Drive_Date__c, shift.sked_Start_Time__c, timezoneSidId);
        DateTime shiftEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.sked_Drive_Date__c, shift.sked_End_Time__c, timezoneSidId);
        if (shiftStart >= shiftEnd) {
            return;
        }

        // NOT calculateDriveShiftStaffCapacity - hardcoded to Mobile's 5-role list (wb:770 uses only 2RBC/VP-HH/Charge); staffSetupRoles is already the correct per-drive-type list.
        shiftMetadata.lunchBreakSettings.lunchBreak = shift.sked_Lunch_Break__c;
        shiftMetadata.lunchBreakSettings.lunchBreakBeforeDrawHours = shift.sked_Lunch_Break_Before_Draw_Hours__c;
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap = skedMobileRoleQuantityCalculator.buildResourceQuantityFromJobs(proposed.jobs);
        Decimal driveShiftStaffCapacity = Math.floor(skedMobileRoleQuantityCalculator.calculateStaffCapacity(staffSetupRoles, resourceQuantityMap,
            shiftMetadata, staffingDecisionMatrix, numberOf2rbcAssets, timezoneSidId, true, adhocDriverSupportCapacity));
        Integer totalDefaultSlots = Math.ceil(driveShiftStaffCapacity * paddingPercentage).intValue();

        List<sked__Slot__c> twoRbcSlots = generate2rbcSlots(shiftStart, shiftEnd, numberOf2rbcAssets, timezoneSidId);

        DateTime wbLastSlotStart = isLastShift
            ? (skipLastAppointment == true ? skedDateTimeUtils.addMinutes(shiftEnd, -WB_LAST_SLOT_BUFFER_MINUTES, timezoneSidId) : shiftEnd)
            : skedDateTimeUtils.addMinutes(shiftEnd, -WB_LAST_SLOT_BUFFER_MINUTES, timezoneSidId);
        Integer totalWbSlots = totalDefaultSlots - twoRbcSlots.size();
        List<sked__Slot__c> wbSlots = skedSlotGenerator.generateSlots(SLOT_TYPE_WHOLE_BLOOD, shiftStart, wbLastSlotStart, WB_INTERVAL_MINUTES,
            WB_SLOT_DURATION_MINUTES, WB_ROUND_MINUTES_INTO_START, totalWbSlots, timezoneSidId, new List<skedTimeRange>());

        Decimal signUpReduction = null;
        if (shift.sked_Lunch_Break__c == true) {
            if (shift.sked_Lunch_Break_Before_Draw_Hours__c != true) {
                sked_Lunch_Break_Definition__c definition = findSlotReductionDefinition(shiftMetadata, proposed.jobs, lunchBreakSettingsConfig, staffSetupRoles);
                if (!wbSlots.isEmpty() && definition != null) {
                    DateTime lunchStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.sked_Drive_Date__c, shift.sked_Lunch_Break_Start_Time__c, timezoneSidId);
                    DateTime lunchEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.sked_Drive_Date__c, shift.sked_Lunch_Break_End_Time__c, timezoneSidId);
                    skedSlotGenerator.reduceSlots(wbSlots, lunchStart, lunchEnd, WB_INTERVAL_MINUTES, WB_ROUND_MINUTES_INTO_START, definition.sked_Slot_Reduction__c, timezoneSidId);
                }
                signUpReduction = definition == null ? null : definition.sked_Slot_Reduction__c;
            }
        }

        shift.sked_Default_2RBC_Slots__c = twoRbcSlots.size();
        shift.sked_Default_WB_Slots__c = wbSlots.size();
        shift.sked_Sign_Up_Reduction__c = signUpReduction;

        proposed.slots.addAll(twoRbcSlots);
        proposed.slots.addAll(wbSlots);
    }

    // Unlike skedLunchBreakCalculator.populateLunchBreakTime's lookup, which throws if misconfigured,
    // this tolerates a missing setting/definition by treating it as "no slot reduction".
    // NOTE: supersedes skedMobileLunchBreakCalculator.findMatchingDefinitionForSlotReduction, which
    // hardcodes Mobile's role list and so cannot serve WB Fixed Site; that method now has no callers.
    private static sked_Lunch_Break_Definition__c findSlotReductionDefinition(skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata,
            List<sked__Job__c> jobs, List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig, List<String> staffSetupRoles) {
        sked_Lunch_Break_Setting__c matchedSetting = skedLunchBreakCalculator.findLunchBreakSetting(
            lunchBreakSettingsConfig, shiftMetadata.lunchBreakSettings.maximumLunchBreakDuration);
        if (matchedSetting == null) {
            return null;
        }
        return skedLunchBreakCalculator.findLunchBreakDefinition(matchedSetting, skedLunchBreakCalculator.calculateStaffSetup(jobs, staffSetupRoles));
    }

    // 2RBC generation is Mobile-only orchestration, not one of the shared low-level primitives -
    // unlike skedSlotGenerator.generateSlots, it doesn't accept excludedTimeRanges.
    private static List<sked__Slot__c> generate2rbcSlots(DateTime shiftStart, DateTime shiftEnd, Decimal numberOf2rbcAssets, String timezoneSidId) {
        List<sked__Slot__c> slots = new List<sked__Slot__c>();
        Decimal assets = numberOf2rbcAssets == null ? 0 : numberOf2rbcAssets;
        if (assets <= 0) {
            return slots;
        }

        DateTime lastSlotStart = skedDateTimeUtils.addMinutes(shiftEnd, -TWO_RBC_LAST_SLOT_BUFFER_MINUTES, timezoneSidId);
        DateTime tempStart = shiftStart;
        while (tempStart <= lastSlotStart) {
            Decimal remainingAssets = assets;
            for (Integer i = 0; i < TWO_RBC_GROUP_COUNT; i++) {
                Decimal groupQuantity = Math.ceil(remainingAssets / (TWO_RBC_GROUP_COUNT - i));
                if (groupQuantity > remainingAssets) {
                    groupQuantity = remainingAssets;
                }

                DateTime slotStart = skedDateTimeUtils.addMinutes(tempStart, i * TWO_RBC_GROUP_INTERVAL_MINUTES, timezoneSidId);
                DateTime slotEnd = skedDateTimeUtils.addMinutes(slotStart, TWO_RBC_SLOT_DURATION_MINUTES, timezoneSidId);
                if (slotStart <= lastSlotStart) {
                    for (Integer q = 0; q < groupQuantity.intValue(); q++) {
                        slots.add(skedSlotGenerator.newSlot(SLOT_TYPE_2RBC, slotStart, slotEnd));
                    }
                }
                remainingAssets -= groupQuantity;
            }
            tempStart = skedDateTimeUtils.addMinutes(tempStart, TWO_RBC_ROUND_INTERVAL_MINUTES, timezoneSidId);
        }
        return slots;
    }
}
