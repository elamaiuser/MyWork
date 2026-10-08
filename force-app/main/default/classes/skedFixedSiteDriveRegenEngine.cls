/**
 * Fixed Site (not WB) implementation of skedDriveRegenEngine - orchestrates every already-closed
 * Fixed Site calculator (skedFixedSiteDriveShiftCalculator/RoleQuantityCalculator/VolunteerCalculator/
 * SlotGenerator/DriveJobBuilder) plus the shared skedLunchBreakCalculator into one real regeneration.
 * Ported only from the slwcDriveGenerator LWC's fixedSiteGenerator.js, never from a legacy class - see
 * 2026-08-05-hrp-10153-fixed-site-engine-design.md.
 *
 * Every token triggers a full recompute, same rationale as skedMobileDriveRegenEngine's own header -
 * the source's own token->recalculation mapping already collapses to "recompute everything" for
 * every token this batch pipeline produces.
 *
 * Entry gate: unlike Mobile's own single-condition gate (Projected_Registered_Donors__c),
 * fixedSiteGenerator.js has no single top-level skip of its own - individual methods
 * (calculateDriveShiftsMetadata, calculateApheresisStaffQuantity, several slot/lunch-break methods)
 * each null-guard driveDate/startTime/endTime internally and simply produce empty/zeroed output when
 * missing, never skipping the whole pipeline. Porting that literally here would let
 * calculateDriveShiftsMetadata return an empty driveShifts list, which would flow through to
 * applyToContext replacing ctx.driveShifts/jobsByShiftId/slotsByShiftId with EMPTY collections -
 * silently wiping a data-incomplete drive's entire shift graph. A single top-level gate (skip
 * entirely, leave ctx exactly as loaded) avoids that destructive outcome and matches Mobile's own
 * "skip, don't empty" posture - a deliberate, better-justified choice over a literal port of the
 * JS's per-method guards.
 *
 * Confirmed-ABSENT Mobile concepts, NOT ported here (per the plan's Global Constraints): ghost
 * vehicle, dual-role generation, excess-staff-capacity, VP/HH recalculation, APT restoration,
 * job-allocation carry-forward, drive-productivity-planned. Also deferred (documented in
 * skedFixedSiteDriveJobBuilder's own header): volunteer retain-if-zero/locked and manual
 * role-quantity carry-forward.
 *
 * Lunch break lock/restore: called with lockLunchBreak = false and existingShiftRecord = null (this
 * first version always recomputes fresh). Fixed Site's own lock/restore semantics
 * (sked_Lock_Lunch_Break__c) were not independently re-verified against the JS this session - see
 * task-1-report.md.
 */
public with sharing class skedFixedSiteDriveRegenEngine implements skedDriveRegenEngine {

    // Duplicated from skedFixedSiteSlotGenerator's own private constant of the same name/value rather
    // than widening that already-shipped, independently-tested class's surface for this one caller.
    private static final List<String> WB_LUNCH_BREAK_STAFF_SETUP_ROLES = new List<String>{ 'Apheresis', 'Apheresis Charge' };

    public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
        if (ctx.drive.sked_Drive_Date__c == null || ctx.drive.sked_Start_Time__c == null || ctx.drive.sked_End_Time__c == null) {
            return;
        }

        sked_Drive__c drive = loadDrive(ctx.drive.Id);
        // Overlays the in-memory CO-change DCR mutation loadDrive's fresh query can't see yet (skedDCRApplyService.applyCollectionOperationChange).
        drive.sked_Collection_Operation__c = ctx.drive.sked_Collection_Operation__c;
        drive.sked_Site_Collection_Operation__c = ctx.drive.sked_Site_Collection_Operation__c;

        skedFixedSiteDriveShiftCalculator.MasterData shiftMasterData = skedFixedSiteDriveShiftCalculator.loadMasterData(drive);
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);

        skedFixedSiteRoleQuantityCalculator.MasterData roleMasterData = skedFixedSiteRoleQuantityCalculator.loadMasterData(drive);
        Map<String, Decimal> assetQuantityByType = skedFixedSiteRoleQuantityCalculator.calculateAssetQuantity(drive);
        Map<String, Map<String, skedFixedSiteRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey =
            skedFixedSiteRoleQuantityCalculator.calculateRoleQuantities(drive, shiftsMetadata, roleMasterData);

        skedFixedSiteVolunteerCalculator.MasterData volunteerMasterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> volunteerQuantityByShiftKey = skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(
            shiftsMetadata, volunteerMasterData, shiftMasterData.timezoneSidId);

        Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>> jobTagsByResourceType = skedMobileDriveShiftCalculator.loadJobTagsMap(drive);

        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = skedFixedSiteDriveJobBuilder.buildProposedDriveShifts(
            drive, shiftsMetadata, roleQuantityByShiftKey, assetQuantityByType, volunteerQuantityByShiftKey, jobTagsByResourceType);

        List<sked_Drive_Shift__c> existingShifts = loadExistingShiftsWithJobs(ctx.drive.Id);

        // Must run before slot generation (WB's lunch-break reduction needs jobs) and before
        // applyExistingRecordIds - matches skedFixedSiteDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts's
        // own documented ordering requirement.
        skedFixedSiteDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);

        skedFixedSiteSlotGenerator.MasterData slotMasterData = skedFixedSiteSlotGenerator.loadMasterData(drive);
        // Reuses skedFixedSiteSlotGenerator.loadMasterData's own loadLunchBreakSettings() call instead of querying twice.
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = slotMasterData.lunchBreakSettingsConfig;
        // Platelet/Plasma generate for either operation type, WB/2RBC only for Integrated - matches fixedSiteGenerator.js's generateShiftSlots dispatch exactly.
        Boolean isIntegrated = drive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_INTEGRATED;
        Boolean isNonIntegratedAph = drive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_APH;

        // generatePlateletSlots needs sked_Fixed_Site_Appointment_Pattern__c, absent from skedFixedSiteDriveShiftCalculator's own driveSite query.
        sked__Location__c plateletSiteData = [SELECT Id, sked_Fixed_Site_Appointment_Pattern__c FROM sked__Location__c WHERE Id = :drive.sked_Drive_Site__c];

        for (Integer i = 0; i < proposed.size(); i++) {
            skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = proposed[i];
            skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shiftMetadata = shiftsMetadata.driveShifts[i];
            Boolean isLastShift = i == proposed.size() - 1;

            skedLunchBreakCalculator.populateLunchBreakTime(shift, shiftMetadata, lunchBreakSettingsConfig, shiftMasterData.timezoneSidId,
                false, null, WB_LUNCH_BREAK_STAFF_SETUP_ROLES);

            // Matches fixedSiteGenerator.js:1579 - a shift with no computed staff must never get NEW
            // bookable slots, but its already-saved slots (possibly booked) must survive untouched,
            // same as the JS's early return leaving driveShift.slots as loaded - not wiped on save.
            if (shift.jobs.isEmpty()) {
                if (i < existingShifts.size()) {
                    List<sked__Slot__c> preservedSlots = ctx.slotsByShiftId.get(existingShifts[i].Id);
                    if (preservedSlots != null) {
                        shift.slots.addAll(preservedSlots);
                    }
                }
                continue;
            }

            List<skedTimeRange> excludedTimeRanges = skedFixedSiteDriveShiftCalculator.generateExcludedTimeRangesFromPlateletRounds(
                shiftMetadata.rounds, shiftMasterData.timezoneSidId);

            List<sked__Slot__c> plateletSlots = new List<sked__Slot__c>();
            List<sked__Slot__c> plasmaSlots = new List<sked__Slot__c>();
            List<sked__Slot__c> wbSlots = new List<sked__Slot__c>();
            List<sked__Slot__c> twoRbcSlots = new List<sked__Slot__c>();

            if (isIntegrated || isNonIntegratedAph) {
                Integer numberOfPlateletAssets = drive.sked_Number_of_Platelet_Assets__c == null ? 0 : drive.sked_Number_of_Platelet_Assets__c.intValue();
                plateletSlots = skedFixedSiteSlotGenerator.generatePlateletSlots(plateletSiteData, numberOfPlateletAssets, shiftMetadata.rounds, shiftMasterData.timezoneSidId);
                plasmaSlots = skedFixedSiteSlotGenerator.generatePlasmaSlots(drive, shiftMetadata, isLastShift, excludedTimeRanges, shiftMasterData.timezoneSidId);
            }
            if (isIntegrated) {
                wbSlots = skedFixedSiteSlotGenerator.generateWbSlots(drive, shiftMetadata, isLastShift, excludedTimeRanges, slotMasterData);
                twoRbcSlots = skedFixedSiteSlotGenerator.generate2rbcSlots(drive, shiftMetadata, excludedTimeRanges, shiftMasterData.timezoneSidId);
            }

            // reduceSlots mutates its list argument in place - wbSlots must be reduced before it is
            // read for its default count or merged into shift.slots, or the reduction is silently lost.
            skedFixedSiteSlotGenerator.reduceWbSlotsForLunchBreak(wbSlots, shift.jobs, shift.shiftRecord, shiftMetadata, slotMasterData);

            shift.shiftRecord.sked_Default_Platelet_Slots__c = plateletSlots.size();
            shift.shiftRecord.sked_Default_Plasma_Slots__c = plasmaSlots.size();
            shift.shiftRecord.sked_Default_2RBC_Slots__c = twoRbcSlots.size();
            shift.shiftRecord.sked_Default_WB_Slots__c = wbSlots.size();

            // JS order: platelet, plasma, 2rbc, wb (fixedSiteGenerator.js:1640).
            shift.slots.addAll(plateletSlots);
            shift.slots.addAll(plasmaSlots);
            shift.slots.addAll(twoRbcSlots);
            shift.slots.addAll(wbSlots);
        }

        skedFixedSiteDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        // Empty - sked_Staff_Setup_Excluded_Role__c's currently configured rows are all Mobile-only role names with no Fixed Site overlap.
        skedFixedSiteDriveJobBuilder.applyShiftSetupRollups(proposed, new Set<String>());

        applyToContext(ctx, shiftsMetadata, proposed);
        resetElectContentions(ctx);
    }

    // Superset of every field the wrapped calculators read from `drive`, cross-checked field-by-field against each one's own ApexDoc.
    private static sked_Drive__c loadDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_Site_Collection_Operation__c, sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c,
                sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c, sked_Number_of_Vehicles__c,
                sked_Number_of_2RBC_Assets__c, sked_Number_of_Platelet_Assets__c, sked_Number_of_Plasma_Assets__c,
                sked_Account__c, sked_Account__r.Accepts_Automation2__c, sked_Travel_Time_Included__c,
                sked_Type_of_Drive__c, sked_Operation_Type__c, sked_Opportunity__c, sked_Opportunity__r.Slot_Generator__c,
                sked_Status__c, sked_Redcross_Volunteer_Quantity__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    // Ordered to match shiftsMetadata.driveShifts' own chronological build order - shifts pair by array position only.
    private static List<sked_Drive_Shift__c> loadExistingShiftsWithJobs(Id driveId) {
        return [
            SELECT Id, sked_Lunch_Break__c, sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Start_Time__c, sked_Lunch_Break_End_Time__c,
                (SELECT Id, sked_Resource_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c, sked_Equipment_Subtype__c,
                    sked__Quantity__c, sked_Manually_Created_From__c, sked_Volunteer_Role__c,
                    sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c
                 FROM sked_Jobs__r WHERE sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED)
            FROM sked_Drive_Shift__c
            WHERE sked_Drive__c = :driveId
            ORDER BY sked_Start_Time__c
        ];
    }

    /**
     * Ports each ProposedDriveShift back onto ctx: stamps sked_Drive_Shift__c onto each shift's
     * jobs/slots now that applyExistingRecordIds has resolved the shift's real Id, then replaces
     * ctx's shift/job/slot maps wholesale - mirrors skedMobileDriveRegenEngine.applyToContext's own
     * structure, minus the Mobile-only rollup fields (see that method's own header for the new-shift
     * deferral rationale, identical here).
     *
     * Total_Procedures/Products_Projected and Total_Slots ARE written back, even though the plan's
     * own draft omitted them - fixedSiteGenerator.js's own DRIVE_ACTION_GROUPS_ORDER runs
     * calculateTotalProceduresProjected and updateDriveTotalSlots on every regen, both drive-level and
     * drive-type-agnostic, and the data (shiftsMetadata's own totals, and a straight sum of every
     * proposed shift's slot count) is already in hand - see task-1-report.md. Staff_Capacity, APT,
     * Excess_Staff_Capacity, and Drive_Productivity_Planned are NOT written - no Fixed Site calculator
     * in this ticket produces any of them.
     */
    private void applyToContext(skedDriveRegenContext ctx, skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed) {
        List<sked_Drive_Shift__c> newDriveShifts = new List<sked_Drive_Shift__c>();
        Map<Id, List<sked__Job__c>> newJobsByShiftId = new Map<Id, List<sked__Job__c>>();
        Map<Id, List<sked__Slot__c>> newSlotsByShiftId = new Map<Id, List<sked__Slot__c>>();
        Map<Integer, List<sked__Job__c>> newJobsByNewShiftIndex = new Map<Integer, List<sked__Job__c>>();
        Map<Integer, List<sked__Slot__c>> newSlotsByNewShiftIndex = new Map<Integer, List<sked__Slot__c>>();
        Integer totalSlots = 0;

        for (Integer i = 0; i < proposed.size(); i++) {
            skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = proposed[i];
            Id shiftId = shift.shiftRecord.Id;
            newDriveShifts.add(shift.shiftRecord);
            totalSlots += shift.slots.size();

            if (shiftId == null) {
                newJobsByNewShiftIndex.put(i, shift.jobs);
                newSlotsByNewShiftIndex.put(i, shift.slots);
                continue;
            }
            for (sked__Job__c job : shift.jobs) {
                job.sked_Drive_Shift__c = shiftId;
            }
            for (sked__Slot__c slot : shift.slots) {
                slot.sked_Drive_Shift__c = shiftId;
            }
            newJobsByShiftId.put(shiftId, shift.jobs);
            newSlotsByShiftId.put(shiftId, shift.slots);
        }

        ctx.driveShifts = newDriveShifts;
        ctx.jobsByShiftId = newJobsByShiftId;
        ctx.slotsByShiftId = newSlotsByShiftId;
        ctx.jobsByNewShiftIndex = newJobsByNewShiftIndex;
        ctx.slotsByNewShiftIndex = newSlotsByNewShiftIndex;

        ctx.drive.sked_Total_Procedures_Projected__c = shiftsMetadata.totalProceduresProjected;
        ctx.drive.sked_Total_Products_Projected__c = shiftsMetadata.totalProductsProjected;
        ctx.drive.sked_Total_Slots__c = totalSlots;
    }

    // Fixed-Site-scoped subset of skedMobileDriveRegenEngine.resetElectContentions - drops the
    // EXCESS_STAFF_CAPACITY branch entirely. That branch's CONTENTION is a Mobile-only concept, and 2
    // of its 4 diffed fields (Max_Role_Capacity_With_Draw_Hours__c, Excess_Staff_Capacity__c) are
    // Mobile-only fields with no Fixed Site producer - sked_Projected_Registered_Donors__c and
    // sked_Staff_Capacity__c themselves do exist on sked_Drive__c generally, but with no Fixed Site
    // EXCESS_STAFF_CAPACITY contention to ever elect around, this whole branch is unreachable for a
    // Fixed Site drive regardless. Every remaining branch's field references were verified against
    // sked_Drive__c's actual field list before shipping - see task-1-report.md.
    private static void resetElectContentions(skedDriveRegenContext ctx) {
        Set<String> resolutions = String.isBlank(ctx.drive.sked_Contention_Resolution__c)
            ? new Set<String>()
            : new Set<String>(ctx.drive.sked_Contention_Resolution__c.split(';'));

        resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_DUAL_ROLE_REMOVAL);
        resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_WITHIN_42_DAYS);
        resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_STAFFING_COMPLEMENT_CHANGED_ACCEPT_NEW_CHANGE);
        resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_STAFFING_COMPLEMENT_CHANGED_KEEP_CURRENT);

        sked_Drive__c backupDrive = ctx.snapshot.drive;

        if (ctx.drive.sked_Drive_Date__c != backupDrive.sked_Drive_Date__c
                || ctx.drive.sked_Collection_Operation__c != backupDrive.sked_Collection_Operation__c) {
            resolutions.clear();
            for (sked_Drive_Shift__c shift : ctx.driveShifts) {
                shift.sked_Contention_Resolution__c = '';
            }
        }

        if (ctx.drive.sked_Start_Time__c < backupDrive.sked_Start_Time__c
                || ctx.drive.sked_End_Time__c > backupDrive.sked_End_Time__c) {
            resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_OUT_OF_OPERATIONAL_HOURS);
        }

        Decimal currentStaffRequested = skedDriveRegenContext.sumStaffRequested(ctx.jobsByShiftId);
        Decimal backupStaffRequested = backupDrive.sked_Total_Staff_Requested__c == null ? 0 : backupDrive.sked_Total_Staff_Requested__c;
        if (currentStaffRequested > backupStaffRequested) {
            resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_INSUFFICIENT_RESOURCES);
        }

        Decimal currentVehicleRequested = skedDriveRegenContext.sumVehicleRequested(ctx.jobsByShiftId);
        Decimal backupVehicleRequested = backupDrive.sked_Total_Vehicle_Requested__c == null ? 0 : backupDrive.sked_Total_Vehicle_Requested__c;
        if (currentVehicleRequested > backupVehicleRequested) {
            resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LACKING_VEHICLE_INSUFFICIENT_CAPACITY);
            resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LACKING_VEHICLE_USE_RENTAL);
        }

        Decimal currentEquipmentRequested = skedDriveRegenContext.sumEquipmentRequested(ctx.jobsByShiftId);
        Decimal backupEquipmentRequested = backupDrive.sked_Total_Equipment_Requested__c == null ? 0 : backupDrive.sked_Total_Equipment_Requested__c;
        if (currentStaffRequested != backupStaffRequested
                || currentVehicleRequested != backupVehicleRequested
                || currentEquipmentRequested != backupEquipmentRequested) {
            resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_PART_OF_LINKED_DRIVE);
        }

        ctx.drive.sked_Contention_Resolution__c = String.join(new List<String>(resolutions), ';');
    }
}
