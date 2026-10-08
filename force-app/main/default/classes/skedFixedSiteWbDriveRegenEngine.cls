/**
 * Fixed Site "Non Integrated WB" implementation of skedDriveRegenEngine. Ported only from
 * wbFixedSiteGenerator.js's proposeDriveShifts (wb:1320) and its post-steps - never from
 * mobileGenerator.js/fixedSiteGenerator.js directly, though it reuses their already-shipped Apex
 * wherever a body diff proved byte-identical (see 2026-08-07-hrp-10153-fixed-site-wb-engine-design.md).
 *
 * WB sits on two independent drive-type axes that point in OPPOSITE directions - both already
 * implemented by the classes this engine calls, and both preserved here rather than collapsed to one:
 * role-time/master-data reads as 'Fixed Site' (skedMobileDriveShiftCalculator.wbFixedSiteConfig()),
 * while staffing constraints/SDM record type read as 'Mobile' (skedMobileRoleQuantityCalculator.
 * loadStaffingDecisionMatrix and skedDriveRegenContextLoader's own WB branch).
 *
 * No ghost vehicle, no vehicle quantity, no dual-role generation, no APT anywhere - WB has none of
 * these (see the design doc's "Verdict on the hypothesis" section). restoreDualRoleModification is
 * NOT called: it is byte-identical to Fixed Site's own copy, which references undefined
 * resourceRoleQuantityAfterRegenreted/quantity - an evident source bug. Carrying the existing Fixed
 * Site deferral forward rather than re-deciding it, and matching that engine's own precedent of never
 * invoking the method at all.
 *
 * Phase order absent from the JS entirely (no Apex counterpart, not silently dropped):
 * - updateDriveAverageStaffCapacity: the source's own one-arg call passes no masterData, so its
 *   `if (masterData && masterData.staffingDecisionMatrix)` guard never passes and the result is
 *   always 0 - a pre-existing source bug (see the design doc). Mobile's own engine never writes
 *   Average_Staff_Capacity__c either; this engine follows that precedent rather than actively
 *   zeroing a persisted value.
 * - updateDriveRequestedResources: writes Total_Staff/Vehicle/Equipment_Requested__c, which are
 *   Roll-Up Summary fields on sked_Drive__c - not writable from Apex (see
 *   skedMobileDriveRegenEngine.applyToContext's own comment on the same fields).
 * - populateDriveTime: writes sked_Min_Shift_Start__c/sked_Max_Shift_End__c, both Roll-Up Summary
 *   fields; its only other effect (widening shift-0 asset jobs to the drive's time envelope) has no
 *   WB asset job to widen in the cases that matter, and Mobile's own Apex declined to port this too.
 *
 * updateDriveStaffCapacity is NOT skedMobileDriveJobBuilder's shared version: that method is
 * hardcoded to skedMobileRoleQuantityCalculator.calculateDriveShiftStaffCapacity, whose role list
 * (Driver, Driver Support, 2RBC, VP/HH, Charge) would count a legacy manually-created Driver job that
 * skedFixedSiteWbDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts deliberately keeps alive
 * (WB_SYSTEM_ROLES excludes Driver/Driver Support) - proven discriminating on a real fixture by
 * skedFixedSiteWbRoleQuantityCalc_Test (26 vs 59 on the same jobs). This engine computes it inline
 * using skedFixedSiteWbRoleQuantityCalculator.calculateDriveShiftStaffCapacity instead.
 *
 * updateDriveExcessStaffCapacity is also NOT skedMobileDualRoleGenerator's shared version - that one
 * recomputes from the role-quantity map with a VP/HH capacity override and Mobile's own capacity role
 * list. WB's own helper.calculateExcessStaffCapacity(drive) reads the DRIVE-level staffCapacity/
 * maxRoleCapacityWithDrawHours/projectedRegisteredDonors this engine just wrote, so it is computed
 * inline from those three values instead (calculateExcessStaffCapacity below).
 */
public with sharing class skedFixedSiteWbDriveRegenEngine implements skedDriveRegenEngine {

    private static final Set<String> SKIP_GENERATE_SLOTS_TOKENS = new Set<String>{ 'roleTimeDetailChanged', 'travelTimeChanged' };

    // wb:1677/1728/1837's calculateStaffSetup role list, duplicated from skedFixedSiteWbDriveJobBuilder's
    // own private constant rather than widening that class's surface for this one caller.
    private static final List<String> WB_STAFF_SETUP_ROLES = new List<String>{ '2RBC', 'VP/HH', 'Charge' };

    public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
        // Mirrors wb:1324's `if (this.drive.projectedRegisteredDonors)` - the WB source keeps this
        // guard (unlike Fixed Site, which dropped it), matching skedMobileDriveRegenEngine's own entry
        // gate exactly, same field, same semantics.
        if (ctx.drive.sked_Projected_Registered_Donors__c == null || ctx.drive.sked_Projected_Registered_Donors__c == 0) {
            return;
        }

        Boolean skipGenerateSlots = shouldSkipGenerateSlots(tokens);
        Map<Id, List<sked__Slot__c>> existingSlotsByShiftId = ctx.slotsByShiftId;
        sked_Drive__c drive = loadDrive(ctx.drive.Id);
        // Overlays the in-memory CO-change DCR mutation loadDrive's fresh query can't see yet - see
        // skedMobileDriveRegenEngine.onDriveDataChanged's own identical comment for why.
        drive.sked_Collection_Operation__c = ctx.drive.sked_Collection_Operation__c;
        drive.sked_Site_Collection_Operation__c = ctx.drive.sked_Site_Collection_Operation__c;

        skedMobileDriveShiftCalculator.ShiftMetadataConfig shiftConfig = skedMobileDriveShiftCalculator.wbFixedSiteConfig();
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive, shiftConfig);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData, shiftConfig);

        // WB's Fetch is constructed with driveType Mobile (wb:286-288), so this reads Mobile's SDM
        // pool exactly like Mobile's own engine - see skedFixedSiteWbRoleQuantityCalculator's own
        // ApexDoc for the same evidence.
        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantities = skedFixedSiteWbRoleQuantityCalculator.calculateRoleQuantities(
            drive, shiftsMetadata, sdm, masterData.driveSite.sked_Physical_Location_Type__c, masterData.timezoneSidId);
        Decimal numberOfEquipments = skedFixedSiteWbRoleQuantityCalculator.calculateEquipmentQuantity(drive);

        List<Volunteer_Staffing_Matrix__mdt> volunteerMatrix = Volunteer_Staffing_Matrix__mdt.getAll().values();
        Map<String, Integer> volunteerQuantities = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            collectShiftKeys(shiftsMetadata), drive.sked_Type_of_Drive__c, drive.sked_Operation_Type__c,
            drive.sked_Projected_Registered_Donors__c, volunteerMatrix);

        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = skedMobileLunchBreakCalculator.loadLunchBreakSettings();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = skedFixedSiteWbDriveJobBuilder.buildProposedDriveShifts(
            drive, shiftsMetadata, roleQuantities, volunteerQuantities, numberOfEquipments, masterData.timezoneSidId,
            lunchBreakSettingsConfig, masterData.jobTagsByResourceType, ctx.collectionOperationTimeBlocks);

        List<sked_Drive_Shift__c> existingShifts = loadExistingShiftsWithJobs(ctx.drive.Id);

        // No carryForwardVolunteerSponsorQuantity call - WB's own buildVolunteerJob always writes 0
        // (wb:1518 reads the freshly built shift, always empty), so a real regen legitimately zeroes
        // any saved sponsor quantity. Calling Mobile's would restore a value WB's own source discards
        // AND reintroduce a sked_System_Quantity__c write the job builder deliberately omits.

        // WB has no APT concept at all - passing 0 for both fresh/persisted APT (never
        // shiftsMetadata.aptSetup/drive.sked_APT_Quantity__c, which could carry a stale Mobile-era
        // value) keeps the VP/HH branch of the underlying gate from comparing against APT data that
        // doesn't apply to this drive type. The role-set itself needs no change: isEligibleForQuantityRestore
        // already excludes Driver/Driver Support explicitly, and WB never sets a dual role.
        Boolean isDriveGettingRegenerated = tokens.containsKey('regenerateDrive');
        skedMobileDriveJobBuilder.restoreUnchangedJobQuantities(proposed, existingShifts, 0, 0, isDriveGettingRegenerated);

        // Must run before capacity/slot generation - see preserveManuallyCreatedJobsForAllShifts's header.
        skedFixedSiteWbDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);

        // No recalculateVphhQuantityForAllShifts call for WB - see the class header's decision on
        // wb:1577-1579's tail call, deliberately left unwired.

        skedFixedSiteWbDriveJobBuilder.recalculateLunchBreakForAllShifts(proposed, shiftsMetadata, lunchBreakSettingsConfig,
            masterData.timezoneSidId, drive.sked_Lock_Lunch_Break__c, existingShifts);

        Decimal staffCapacity = updateDriveStaffCapacity(proposed, shiftsMetadata, sdm, drive.sked_Number_of_2RBC_Assets__c,
            masterData.timezoneSidId, masterData.adhocDriverSupportCapacity);

        if (!skipGenerateSlots) {
            Decimal paddingPercentage = skedMobileSlotGenerator.calculatePaddingPercentage(drive, masterData);
            skedMobileSlotGenerator.proposeDriveShiftSlots(proposed, shiftsMetadata, sdm, drive.sked_Number_of_2RBC_Assets__c, paddingPercentage,
                masterData.skipLastAppointmentForMobile, lunchBreakSettingsConfig, masterData.timezoneSidId, masterData.adhocDriverSupportCapacity,
                WB_STAFF_SETUP_ROLES);
        }

        skedMobileDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        if (skipGenerateSlots) {
            carryForwardExistingSlots(proposed, existingSlotsByShiftId);
        }
        skedMobileJobAllocationCarryForward.carryForwardJobAllocations(proposed, drive, masterData.collectionOperation, masterData.timezoneSidId);

        // Must run after applyExistingRecordIds - see applyShiftSetupRollups's header.
        skedMobileDriveJobBuilder.applyShiftSetupRollups(proposed, masterData.staffSetupExcludedRoleNames);

        MaxRoleCapacity maxRoleCapacity = updateDriveMaxRoleCapacity(proposed, shiftsMetadata, sdm, masterData.timezoneSidId);
        Decimal excessStaffCapacity = calculateExcessStaffCapacity(staffCapacity, maxRoleCapacity.withDrawHours, drive.sked_Projected_Registered_Donors__c);

        Decimal driveProductivityPlanned = skedMobileDriveJobBuilder.calculateDriveProductivityPlanned(
            drive, proposed, shiftsMetadata, shiftsMetadata.totalProductsProjected, masterData.timezoneSidId);

        applyToContext(ctx, shiftsMetadata, proposed, staffCapacity, maxRoleCapacity, excessStaffCapacity, driveProductivityPlanned, masterData.driveShiftTagResults);
        resetElectContentions(ctx);
    }

    private static List<String> collectShiftKeys(skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata) {
        List<String> shiftKeys = new List<String>();
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            shiftKeys.add(shift.key);
        }
        return shiftKeys;
    }

    /**
     * wb:769-778's own calculateDriveShiftStaffCapacity - NOT skedMobileDriveJobBuilder.updateDriveStaffCapacity,
     * which is hardcoded to Mobile's role list. See the class header for why that distinction is
     * load-bearing here, not cosmetic.
     */
    private static Decimal updateDriveStaffCapacity(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, sked_Staffing_Decision_Matrix__c sdm,
            Decimal numberOf2rbcAssets, String timezoneSidId, Decimal adhocDriverSupportCapacity) {
        if (sdm == null) {
            return 0;
        }
        Decimal driveStaffCapacity = 0;
        for (Integer i = 0; i < proposed.size(); i++) {
            skedMobileDriveJobBuilder.ProposedDriveShift shift = proposed[i];
            skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata = shiftsMetadata.driveShifts[i];
            Decimal shiftCapacity = skedFixedSiteWbRoleQuantityCalculator.calculateDriveShiftStaffCapacity(shift.jobs, shiftMetadata,
                sdm, numberOf2rbcAssets, timezoneSidId, false, shift.shiftRecord.sked_Lunch_Break__c,
                shift.shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c, adhocDriverSupportCapacity);
            shift.shiftRecord.sked_Max_Donor_Capacity__c = shiftCapacity;
            driveStaffCapacity += shiftCapacity;
        }
        return driveStaffCapacity;
    }

    private class MaxRoleCapacity {
        Decimal capacity = 0;
        Decimal withDrawHours = 0;
    }

    /**
     * wb:823-845's own bespoke updateDriveMaxRoleCapacity - max shift capacity (Mobile's role list;
     * calculateDriveShiftMaxStaffCapacity is identical between Mobile and WB, see the role-quantity
     * calculator's own ApexDoc) across shifts, times summed draw hours. Both fields are Number(18,2)
     * on sked_Drive__c (confirmed against the field metadata, not assumed), matching the JS's own
     * `.toFixed(2)` string intent - setScale(2) is the Apex equivalent. Written unconditionally, same
     * as the source: an absent SDM leaves both at 0.00, never left null.
     */
    private static MaxRoleCapacity updateDriveMaxRoleCapacity(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, sked_Staffing_Decision_Matrix__c sdm, String timezoneSidId) {
        MaxRoleCapacity result = new MaxRoleCapacity();
        if (sdm != null) {
            Decimal totalDrawHours = 0;
            for (Integer i = 0; i < proposed.size(); i++) {
                Decimal shiftMaxCapacity = skedMobileRoleQuantityCalculator.calculateDriveShiftMaxStaffCapacity(proposed[i].jobs, sdm);
                if (shiftMaxCapacity != null && shiftMaxCapacity > result.capacity) {
                    result.capacity = shiftMaxCapacity;
                }
                Decimal shiftDrawHours = skedMobileRoleQuantityCalculator.calculateShiftDrawHours(shiftsMetadata.driveShifts[i], timezoneSidId);
                if (shiftDrawHours != null) {
                    totalDrawHours += shiftDrawHours;
                }
            }
            if (totalDrawHours > 0) {
                result.withDrawHours = result.capacity * totalDrawHours;
            }
        }
        result.capacity = result.capacity.setScale(2);
        result.withDrawHours = result.withDrawHours.setScale(2);
        return result;
    }

    /**
     * helper.js:4075's own calculateExcessStaffCapacity - reads the drive-level values this engine
     * just computed, NOT skedMobileDualRoleGenerator's role-quantity-map version (wrong capacity role
     * list and a VP/HH override that doesn't apply here). Both branches are ported even though
     * projectedRegisteredDonors is guaranteed non-null/non-zero by this engine's own entry gate -
     * matching the already-shipped skedMobileDualRoleGenerator.calculateExcessStaffCapacity precedent,
     * which carries the same structurally-redundant guard forward from its own source.
     */
    private static Decimal calculateExcessStaffCapacity(Decimal staffCapacity, Decimal maxRoleCapacityWithDrawHours, Decimal projectedRegisteredDonors) {
        if (staffCapacity == null || staffCapacity <= 0 || maxRoleCapacityWithDrawHours == null || maxRoleCapacityWithDrawHours <= 0) {
            return 0;
        }
        if (projectedRegisteredDonors != null && projectedRegisteredDonors != 0) {
            return ((staffCapacity - projectedRegisteredDonors) / maxRoleCapacityWithDrawHours).setScale(1);
        }
        return (staffCapacity / maxRoleCapacityWithDrawHours).setScale(1);
    }

    /**
     * Mirrors skedMobileDriveRegenEngine.applyToContext's shift/job/slot rewiring exactly. Drive-level
     * writes differ: no sked_Number_of_Vehicles__c (WB never recalculates it), no sked_APT_Quantity__c/
     * sked_APT_Required__c (shiftsMetadata.aptSetup is forced to 0 by wbFixedSiteConfig - writing
     * aptRequired from it would clobber the drive's real APT_Required flag, which WB's OWN role-quantity
     * calculator reads as an INPUT, never as something this pipeline recomputes).
     */
    private void applyToContext(skedDriveRegenContext ctx, skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed, Decimal staffCapacity, MaxRoleCapacity maxRoleCapacity,
            Decimal excessStaffCapacity, Decimal driveProductivityPlanned, List<skedDriveShiftTagCalculator.TagResult> driveShiftTagResults) {
        List<sked_Drive_Shift__c> newDriveShifts = new List<sked_Drive_Shift__c>();
        Map<Id, List<sked__Job__c>> newJobsByShiftId = new Map<Id, List<sked__Job__c>>();
        Map<Id, List<sked__Slot__c>> newSlotsByShiftId = new Map<Id, List<sked__Slot__c>>();
        Map<Integer, List<sked__Job__c>> newJobsByNewShiftIndex = new Map<Integer, List<sked__Job__c>>();
        Map<Integer, List<sked__Slot__c>> newSlotsByNewShiftIndex = new Map<Integer, List<sked__Slot__c>>();
        Map<Integer, List<skedDriveShiftTagCalculator.TagResult>> newTagsByNewShiftIndex = new Map<Integer, List<skedDriveShiftTagCalculator.TagResult>>();
        Map<Id, List<sked__Job_Allocation__c>> newAllocationsByJobId = new Map<Id, List<sked__Job_Allocation__c>>();
        Integer totalSlots = 0;

        for (Integer i = 0; i < proposed.size(); i++) {
            skedMobileDriveJobBuilder.ProposedDriveShift shift = proposed[i];
            Id shiftId = shift.shiftRecord.Id;
            newDriveShifts.add(shift.shiftRecord);
            totalSlots += shift.slots.size();
            for (Id jobId : shift.jobAllocationsByJobId.keySet()) {
                newAllocationsByJobId.put(jobId, shift.jobAllocationsByJobId.get(jobId));
            }

            if (shiftId == null) {
                newJobsByNewShiftIndex.put(i, shift.jobs);
                newSlotsByNewShiftIndex.put(i, shift.slots);
                newTagsByNewShiftIndex.put(i, driveShiftTagResults);
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
        ctx.tagsByNewShiftIndex = newTagsByNewShiftIndex;
        ctx.allocationsByJobId = newAllocationsByJobId;

        ctx.drive.sked_Staff_Capacity__c = staffCapacity;
        ctx.drive.Max_Role_Capacity__c = maxRoleCapacity.capacity;
        ctx.drive.Max_Role_Capacity_With_Draw_Hours__c = maxRoleCapacity.withDrawHours;
        ctx.drive.Excess_Staff_Capacity__c = excessStaffCapacity;
        ctx.drive.sked_Total_Procedures_Projected__c = shiftsMetadata.totalProceduresProjected;
        ctx.drive.sked_Total_Products_Projected__c = shiftsMetadata.totalProductsProjected;
        ctx.drive.sked_Total_Slots__c = totalSlots;
        if (driveProductivityPlanned != null) {
            ctx.drive.sked_Drive_Productivity_Planned__c = driveProductivityPlanned;
        }
    }

    // `tokens` is the DCR's own applied token set for this single onDriveDataChanged call - see
    // skedMobileDriveRegenEngine.shouldSkipGenerateSlots's own identical comment.
    private static Boolean shouldSkipGenerateSlots(Map<String, Object> tokens) {
        if (tokens.isEmpty()) {
            return false;
        }
        for (String token : tokens.keySet()) {
            if (!SKIP_GENERATE_SLOTS_TOKENS.contains(token)) {
                return false;
            }
        }
        return true;
    }

    private static void carryForwardExistingSlots(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed,
            Map<Id, List<sked__Slot__c>> existingSlotsByShiftId) {
        for (skedMobileDriveJobBuilder.ProposedDriveShift shift : proposed) {
            List<sked__Slot__c> existingSlots = existingSlotsByShiftId.get(shift.shiftRecord.Id);
            shift.slots = existingSlots == null ? new List<sked__Slot__c>() : existingSlots;
        }
    }

    /**
     * Ported from skedMobileDriveRegenEngine.resetElectContentions, in full - not Fixed Site's own
     * trimmed copy. Fixed Site drops the EXCESS_STAFF_CAPACITY branch because it has no producer for
     * Max_Role_Capacity_With_Draw_Hours__c/Excess_Staff_Capacity__c; this engine writes both, so the
     * branch is genuinely live for WB. LACKING_VEHICLE removal is kept even though WB never creates a
     * vehicle job (sumVehicleRequested is always 0 on both sides) - inert, not wrong, matching Fixed
     * Site's own precedent of not special-casing an always-zero branch.
     */
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

        if (ctx.drive.sked_Projected_Registered_Donors__c != backupDrive.sked_Projected_Registered_Donors__c
                || ctx.drive.sked_Staff_Capacity__c != backupDrive.sked_Staff_Capacity__c
                || ctx.drive.Max_Role_Capacity_With_Draw_Hours__c != backupDrive.Max_Role_Capacity_With_Draw_Hours__c
                || ctx.drive.Excess_Staff_Capacity__c != backupDrive.Excess_Staff_Capacity__c) {
            resolutions.remove(skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_EXCESS_STAFF_CAPACITY);
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

    // Superset of every field the wrapped calculators read from `drive` - cross-checked against
    // loadMasterData/calculateDriveShiftsMetadata (wbFixedSiteConfig), the WB role-quantity/volunteer
    // calculators, and skedMobileSlotGenerator.calculatePaddingPercentage.
    private static sked_Drive__c loadDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_Site_Collection_Operation__c, sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c,
                sked_Projected_Registered_Donors__c, sked_Number_of_2RBC_Assets__c, sked_IMPACT__c, sked_APT_Required__c,
                sked_Type_of_Drive__c, sked_Operation_Type__c, sked_Lock_Lunch_Break__c, sked_Status__c, sked_Account__c,
                sked_Account__r.Type, sked_Account__r.Industry_Code__c, sked_Account__r.Accepts_Automation2__c,
                sked_Travel_Time_Included__c, sked_Opportunity__r.Call_List_Recipient_Exist__c, sked_Opportunity__r.Slot_Generator__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    // Matches skedMobileDriveJobBuilder.applyExistingRecordIds's expected shape - see
    // skedMobileDriveRegenEngine.loadExistingShiftsWithJobs's own identical field-set rationale.
    private static List<sked_Drive_Shift__c> loadExistingShiftsWithJobs(Id driveId) {
        return [
            SELECT Id, sked_Lunch_Break__c, sked_Lunch_Break_Before_Draw_Hours__c,
                (SELECT Id, sked_Resource_Role__c, sked_Dual_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c, sked_Equipment_Subtype__c,
                    sked__Quantity__c, sked_Manually_Created_From__c, sked_VPHH_Quantity__c, sked_APT_Quantity__c, sked_System_Quantity__c,
                    sked_Volunteer_Role__c, sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c
                FROM sked_Jobs__r)
            FROM sked_Drive_Shift__c
            WHERE sked_Drive__c = :driveId
            ORDER BY sked_Start_Time__c
        ];
    }
}
