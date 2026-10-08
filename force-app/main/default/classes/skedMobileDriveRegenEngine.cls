/**
 * Mobile implementation of skedDriveRegenEngine. Wraps the calculator/builder/loader classes -
 * ported only from the slwcDriveGenerator LWC's mobile/base generator logic, never from the
 * legacy GenerateMobileDrive.cls/CreateSkedDrive.cls - into the single onDriveDataChanged entry
 * point skedDCRApplyService calls.
 *
 * Every token triggers a full recompute - the source's own token->recalculation mapping already
 * collapses to "recompute everything" for all 5 DCR-producible tokens on a Mobile drive, so a
 * token-specific partial recompute would just reimplement the same result with more branching.
 *
 * skedDriveRegenContextLoader loads ctx.drive/ctx.driveShifts flat, without the relationship/
 * subquery shape the calculators need (e.g. sked_Account__r.Type, an existing shift's
 * sked_Jobs__r) - this engine re-queries both itself rather than reshaping that loader for every
 * other (future) drive-type engine.
 *
 * Creating a genuinely NEW drive shift (regeneration wants more shifts than the drive currently
 * has) is supported: applyExistingRecordIds leaves shiftRecord.Id null for a proposed shift beyond
 * the drive's existing shift count, applyToContext routes that shift's jobs/slots into
 * ctx.jobsByNewShiftIndex/slotsByNewShiftIndex (keyed by position, since there's no real Id yet),
 * and skedDriveGraphSaver stamps the real Id and folds them in right after the shift insert.
 *
 * KNOWN GAP: contention checks that iterate ctx.jobsByShiftId.values() (e.g.
 * skedLockedResourceChecker's LOCKED_RESOURCE_UNAVAILABLE) run BEFORE save() and so do not see a
 * new shift's jobs - those only exist in ctx.jobsByNewShiftIndex pre-save. A DCR that both needs a
 * new shift AND has contention specific to that new shift's jobs will not be flagged by those
 * checks today. Widening every affected check to also see new-shift jobs is a separate, not-yet-
 * scoped follow-up.
 *
 * Donor Ambassador volunteer jobs ARE built (skedMobileDriveJobBuilder.buildVolunteerJob), one per
 * shift, gated on skedMobileVolunteerCalculator returning a positive quantity - contrary to an
 * earlier assumption in this ticket, this needs no new DCR type: the source builds/persists the
 * volunteer job on every regen for all 5 tokens, the same as any other role job (only a separate,
 * narrower function, handleRedcrossVolunteerRequirement, is gated to a User Change DCR or manual job
 * edit - not relevant here). What IS gated: quantity RECALCULATION. The source's own
 * skipVolunteerRecalculation only turns off when Projected_Registered_Donors__c is literally one of
 * the DCR's changed fields, which never happens for any DCR type this batch processes (see the
 * skipVolunteerRecalculation=true comment above) - so the quantity here is always whatever's already
 * on drive.sked_Redcross_Volunteer_Quantity__c, carried through unchanged, same as the source in
 * practice for this pipeline. Also NOT ported: the source's required-toggle "reset to 0 / min 1"
 * branch (needs modeling prior drive state, which skedMobileVolunteerCalculator deliberately doesn't
 * do) and handleRedcrossVolunteerRequirement itself (a different trigger entirely).
 *
 * sked_Drive_Productivity_Planned__c IS calculated and
 * written (skedMobileDriveJobBuilder.calculateDriveProductivityPlanned) - see that method's header
 * for what's deliberately excluded (the source's low-productivity confirmation gate, since there's
 * no interactive user in this headless pipeline).
 */
public with sharing class skedMobileDriveRegenEngine implements skedDriveRegenEngine {

    // When the DCR's only applied token(s) are these, slot generation is skipped and the shift's
    // pre-regen slots are carried forward untouched.
    private static final Set<String> SKIP_GENERATE_SLOTS_TOKENS = new Set<String>{ 'roleTimeDetailChanged', 'travelTimeChanged' };

    public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
        // A null or zero projected donor count skips shift/job/slot generation and every capacity
        // rollup entirely, leaving the drive's existing graph untouched. ctx is left exactly as
        // skedDriveRegenContextLoader loaded it.
        if (ctx.drive.sked_Projected_Registered_Donors__c == null || ctx.drive.sked_Projected_Registered_Donors__c == 0) {
            return;
        }

        Boolean skipGenerateSlots = shouldSkipGenerateSlots(tokens);
        Map<Id, List<sked__Slot__c>> existingSlotsByShiftId = ctx.slotsByShiftId;
        sked_Drive__c drive = loadDrive(ctx.drive.Id);
        // loadDrive() re-queries the database for the relationship-shaped fields ctx.drive lacks -
        // but nothing is saved yet (the whole point of the pre-save contention gate), so that query
        // reads the OLD, still-persisted value for any field a DCR mutated on ctx.drive in memory
        // before this call (skedDCRApplyService.applyCollectionOperationChange, the only such
        // mutation today). Overlay it back on, or a CO-change DCR would silently run every staffing/
        // role-quantity calculation below against the wrong Collection Operation.
        drive.sked_Collection_Operation__c = ctx.drive.sked_Collection_Operation__c;
        drive.sked_Site_Collection_Operation__c = ctx.drive.sked_Site_Collection_Operation__c;

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);

        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(drive, shiftsMetadata, masterData);

        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantities = skedMobileRoleQuantityCalculator.calculateRoleQuantities(
            drive, shiftsMetadata, sdm, masterData.driveSite.sked_Physical_Location_Type__c, masterData.timezoneSidId);

        skedMobileDualRoleGenerator.generateDualRoles(roleQuantities, drive, masterData.collectionOperation, shiftsMetadata, sdm,
            drive.sked_Number_of_2RBC_Assets__c, drive.sked_Projected_Registered_Donors__c, masterData.excessStaffCapacityThreshold, masterData.timezoneSidId,
            ctx.snapshot.driveShifts, ctx.snapshot.jobsByShiftId, ctx.snapshot.allocationsByJobId);
        // Recomputed post-merge (not reused from generateDualRoles's own internal gate check) so
        // it reflects the FINAL role quantities - persisted for skedDriveContentionValidator's
        // EXCESS_STAFF_CAPACITY check, which only reads the field, it doesn't compute anything.
        Decimal excessStaffCapacity = skedMobileDualRoleGenerator.calculateExcessStaffCapacity(roleQuantities, shiftsMetadata, sdm,
            drive.sked_Number_of_2RBC_Assets__c, drive.sked_Projected_Registered_Donors__c, masterData.timezoneSidId);

        Decimal numberOfVehicles = skedMobileRoleQuantityCalculator.calculateVehicleQuantity(drive);
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = skedMobileLunchBreakCalculator.loadLunchBreakSettings();
        // skipVolunteerRecalculation is hardcoded true: every DCR type this batch/engine processes
        // (RTD/RTV/travel-time change, regenerate, CO change) carries only synthetic marker fields,
        // never the literal Projected_Registered_Donors__c change that would flip the source's own
        // gate to false - that only happens via a User Change DCR, which this batch excludes entirely
        // (skedDCRProcessingBatch). So this always returns drive.sked_Redcross_Volunteer_Quantity__c
        // unchanged - the matrix lookup below is never reached by this pipeline, but wired in for
        // parity/future-proofing rather than reading the drive field directly.
        Decimal redcrossVolunteerQuantity = skedMobileVolunteerCalculator.calculateVolunteerDonorAmbassadors(drive, null, true);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = skedMobileDriveJobBuilder.buildProposedDriveShifts(drive, shiftsMetadata, roleQuantities,
            numberOfVehicles, drive.sked_Number_of_2RBC_Assets__c, masterData.timezoneSidId, lunchBreakSettingsConfig, masterData.jobTagsByResourceType,
            ctx.collectionOperationTimeBlocks, redcrossVolunteerQuantity);

        // Also needed by slot generation/capacity below. A proposed shift beyond existingShifts'
        // size (regeneration now needs more shifts than the drive has) is left with shiftRecord.Id
        // == null by applyExistingRecordIds below - applyToContext and skedDriveGraphSaver handle
        // that as a genuinely new shift to insert, not an error.
        List<sked_Drive_Shift__c> existingShifts = loadExistingShiftsWithJobs(ctx.drive.Id);
        // A fresh volunteer job always starts with sponsorVolunteerQuantity = 0 (buildVolunteerJob
        // can't see existing data) - this port never computes that value itself, so it must be carried
        // forward from any existing volunteer job on the same shift now that existingShifts is loaded.
        skedMobileDriveJobBuilder.carryForwardVolunteerSponsorQuantity(proposed, existingShifts);

        // Must run before preserveManuallyCreatedJobsForAllShifts: quantity restoration happens on
        // the pre-job-build role-quantity map, before manually created jobs exist at all -
        // restoring against a proposed list that already contains them would risk matching/
        // overwriting a manual job that happens to share a system role name. See
        // restoreUnchangedJobQuantities's header for the token-set gating.
        Boolean isDriveGettingRegenerated = tokens.containsKey('regenerateDrive');
        skedMobileDriveJobBuilder.restoreUnchangedJobQuantities(proposed, existingShifts,
            shiftsMetadata.aptSetup, drive.sked_APT_Quantity__c, isDriveGettingRegenerated);

        // Must run before capacity/slot generation - see preserveManuallyCreatedJobsForAllShifts's header.
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);

        // Must run after preserveManuallyCreatedJobsForAllShifts (needs the merged job list) and
        // before recalculateLunchBreakForAllShifts - see recalculateVphhQuantityForAllShifts's header.
        skedMobileDriveJobBuilder.recalculateVphhQuantityForAllShifts(proposed, shiftsMetadata, drive, sdm,
            drive.sked_Number_of_2RBC_Assets__c, masterData.timezoneSidId, masterData.adhocDriverSupportCapacity);

        // Must run after preserveManuallyCreatedJobsForAllShifts - see recalculateLunchBreakForAllShifts's header.
        skedMobileDriveJobBuilder.recalculateLunchBreakForAllShifts(proposed, shiftsMetadata, lunchBreakSettingsConfig, masterData.timezoneSidId,
            drive.sked_Lock_Lunch_Break__c, existingShifts);

        Decimal staffCapacity = skedMobileDriveJobBuilder.updateDriveStaffCapacity(proposed, shiftsMetadata, sdm, drive.sked_Number_of_2RBC_Assets__c,
            masterData.timezoneSidId, masterData.adhocDriverSupportCapacity);

        if (!skipGenerateSlots) {
            Decimal paddingPercentage = skedMobileSlotGenerator.calculatePaddingPercentage(drive, masterData);
            skedMobileSlotGenerator.proposeDriveShiftSlots(proposed, shiftsMetadata, sdm, drive.sked_Number_of_2RBC_Assets__c, paddingPercentage,
                masterData.skipLastAppointmentForMobile, lunchBreakSettingsConfig, masterData.timezoneSidId, masterData.adhocDriverSupportCapacity);
        }

        skedMobileDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        if (skipGenerateSlots) {
            carryForwardExistingSlots(proposed, existingSlotsByShiftId);
        }
        skedMobileJobAllocationCarryForward.carryForwardJobAllocations(proposed, drive, masterData.collectionOperation, masterData.timezoneSidId);

        // Must run after applyExistingRecordIds - see applyShiftSetupRollups's header.
        skedMobileDriveJobBuilder.applyShiftSetupRollups(proposed, masterData.staffSetupExcludedRoleNames);

        Decimal driveProductivityPlanned = skedMobileDriveJobBuilder.calculateDriveProductivityPlanned(
            drive, proposed, shiftsMetadata, shiftsMetadata.totalProductsProjected, masterData.timezoneSidId);

        applyToContext(ctx, drive, shiftsMetadata, proposed, staffCapacity, excessStaffCapacity, driveProductivityPlanned, masterData.driveShiftTagResults);
        resetElectContentions(ctx);
    }

    /**
     * Ported from baseGenerator.js's resetElectContentions - called at the same point in the
     * pipeline (right after the regen finishes mutating ctx). Clears elect-resolution tokens whose
     * underlying contention may have changed, so a stale election doesn't silently suppress a
     * contention that should re-surface for human approval.
     *
     * totalStaffRequested/Vehicle/Equipment are Roll-Up Summary fields on sked_Drive__c - not
     * writable, and ctx.snapshot.drive/ctx.drive share the same pre-regen queried value for them
     * (nothing ever recalculates the rollup in-memory - see applyToContext's comment). So the
     * "backup"/before side reads the rollup field directly (accurate: it reflects the
     * last-persisted, pre-this-regen state), while the "current"/after side is summed fresh from
     * ctx.jobsByShiftId via skedDriveRegenContext.sumStaffRequested/sumVehicleRequested/
     * sumEquipmentRequested, matching baseGenerator.js's updateDriveRequestedResources exactly (a
     * straight SUM on every branch, not the rollup fields' own MAX for vehicle/equipment).
     *
     * NOT ported: the source's driveShift.timeBlockManuallyChanged reset - that flag is pure LWC UI
     * session state (tracks a manual drag-edit within one interactive editing session) with no
     * persisted Apex field; there is nothing for a headless batch run to reset.
     */
    @TestVisible
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

    /**
     * Ports each ProposedDriveShift back onto ctx: stamps sked_Drive_Shift__c onto each shift's
     * jobs/slots now that applyExistingRecordIds has resolved the shift's real Id (neither
     * skedMobileDriveJobBuilder nor skedMobileSlotGenerator do this themselves - both build their
     * records before any shift Id exists), then replaces ctx's shift/job/slot/allocation maps
     * wholesale. Any shift previously in ctx.snapshot but absent here (regeneration now needs
     * fewer shifts) is picked up by skedDriveGraphSaver's existing snapshot-diff delete - no
     * special-casing needed.
     *
     * A genuinely new shift (shiftRecord.Id still null - regeneration needs more shifts than the
     * drive has) has no real Id to stamp onto its jobs/slots yet, so those go into
     * ctx.jobsByNewShiftIndex/slotsByNewShiftIndex instead, keyed by the shift's position in
     * ctx.driveShifts. skedDriveGraphSaver resolves the real Id and stamps them once the shift
     * itself is inserted. New jobs never carry job allocations in this pipeline (allocations are
     * only ever carried forward onto jobs that already had a real Id - see
     * skedMobileJobAllocationCarryForward), so no equivalent deferral is needed for allocations.
     */
    private void applyToContext(skedDriveRegenContext ctx, sked_Drive__c drive,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed, Decimal staffCapacity, Decimal excessStaffCapacity,
            Decimal driveProductivityPlanned, List<skedDriveShiftTagCalculator.TagResult> driveShiftTagResults) {
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

        // Only fields the calculators actually mutate on `drive` get copied back - ctx.drive is a
        // separate sObject instance from the freshly re-queried `drive` these calculators ran against.
        ctx.drive.sked_Number_of_Vehicles__c = drive.sked_Number_of_Vehicles__c;
        ctx.drive.sked_Staff_Capacity__c = staffCapacity;
        ctx.drive.sked_APT_Quantity__c = shiftsMetadata.aptSetup;
        ctx.drive.sked_Total_Procedures_Projected__c = shiftsMetadata.totalProceduresProjected;
        ctx.drive.sked_Total_Products_Projected__c = shiftsMetadata.totalProductsProjected;
        ctx.drive.sked_Total_Slots__c = totalSlots;
        ctx.drive.Excess_Staff_Capacity__c = excessStaffCapacity;
        // Null (guard conditions unmet or zero weighted staff-hours, matching the source's own
        // no-op path) leaves the field at its prior value, same as the LWC never assigning it.
        if (driveProductivityPlanned != null) {
            ctx.drive.sked_Drive_Productivity_Planned__c = driveProductivityPlanned;
        }
        // The drive-level Total_Staff/Equipment/Vehicle_Requested__c fields are roll-up summaries
        // (not writable here) - see applyShiftSetupRollups's header in skedMobileDriveJobBuilder.
        ctx.drive.sked_APT_Required__c = shiftsMetadata.aptSetup > 0;
    }

    // `tokens` is the DCR's own applied token set for this single onDriveDataChanged call, not
    // ctx.appliedTokens (which the caller may grow further with item-driven field tokens after
    // this call returns).
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

    // Carries the shift's pre-regen slots forward whenever slot generation is gated off. Existing
    // shifts/proposed shifts are matched purely by position (skedMobileDriveJobBuilder.applyExistingRecordIds
    // already did this - proposed[i].shiftRecord.Id is that same existing shift's real Id by this point).
    private static void carryForwardExistingSlots(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed,
            Map<Id, List<sked__Slot__c>> existingSlotsByShiftId) {
        for (skedMobileDriveJobBuilder.ProposedDriveShift shift : proposed) {
            List<sked__Slot__c> existingSlots = existingSlotsByShiftId.get(shift.shiftRecord.Id);
            shift.slots = existingSlots == null ? new List<sked__Slot__c>() : existingSlots;
        }
    }

    // Superset of every field the wrapped calculators read from `drive`, across loadMasterData,
    // calculateDriveShiftsMetadata/recalculateAptQuantity, the ghost-vehicle/role-quantity/dual-role
    // calculators, and skedMobileSlotGenerator.calculatePaddingPercentage.
    private static sked_Drive__c loadDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Projected_Registered_Donors__c,
                sked_APT_Quantity__c, sked_Travel_Time_Included__c, sked_Account__r.Type, sked_Account__r.Industry_Code__c,
                sked_Account__r.Accepts_Automation2__c,
                sked_Do_Not_Use_Vehicle__c, sked_Number_of_Vehicles__c, sked_Total_Vehicle_Requested__c, sked_Number_of_2RBC_Assets__c, sked_IMPACT__c,
                sked_Status__c, sked_Prefer_System_Generated_Vehicles__c, sked_Account__c, sked_Lock_Lunch_Break__c,
                sked_Type_of_Drive__c, sked_Operation_Type__c, sked_Redcross_Volunteer_Required__c, sked_Redcross_Volunteer_Quantity__c,
                sked_Linked_Drives__c, sked_Linked_Drives__r.sked_Linked_Drive_Type__c,
                sked_Opportunity__r.Call_List_Recipient_Exist__c, sked_Opportunity__r.Slot_Generator__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    // Matches skedMobileDriveJobBuilder.applyExistingRecordIds's expected shape (shifts ordered/
    // matched purely by position, jobs by findMatchingExistingJob's field set) - sked_System_Quantity__c
    // is additionally needed by restoreUnchangedJobQuantities's persisted-vs-fresh comparison.
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
