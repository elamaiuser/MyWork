/**
 * Computes drive Contentions - the checks skedDCRApplyService's saveDrive step reads to decide
 * whether the regenerated graph is even allowed to save. Never sourced from
 * GenerateMobileDrive.cls/CreateSkedDrive.cls, per standing product direction.
 *
 * Runs BEFORE skedDriveGraphSaver.save(): a non-Draft, non-Fixed-Site drive with contentions never
 * reaches the save step at all, so this validator cannot assume saved data exists. It reads
 * ctx.driveShifts/jobsByShiftId/allocationsByJobId directly (the exact shape skedDriveGraphSaver
 * would persist, per its own snapshot-diff), not a fresh post-DML requery. The one gap: ctx's
 * allocation rows never carry sked__Resource__r (carry-forward/reassignment only ever set the
 * resource Id) - resource capacity is bulk-fetched by Id instead, a lookup independent of this
 * drive's save state.
 *
 * LACKING_VEHICLE/LACKING_EQUIPMENT also discount a currently-assigned resource that's since become
 * unavailable elsewhere (skedAssetAvailabilityChecker.findConflictedResourceIds). Actually picking a
 * REPLACEMENT resource is out of scope here (see skedAssetAvailabilityChecker's header) - a drive
 * whose vehicle/equipment becomes unavailable this way routes to human approval instead of
 * self-healing.
 *
 * Scope: all 18 DRIVE_CONTENTION_* types are implemented, including the DRIVE_LIMIT/x2RBC_LIMIT/
 * DOT_LIMIT/CDL_LIMIT/INSUFFICIENT_RESOURCES family and its validateDriveTimeBlocks prerequisite
 * (see below).
 *
 * INSUFFICIENT_RESOURCES (checkInsufficientResources) has one notable, deliberately-preserved
 * source quirk: an unconfigured sked_Staffing_Constraint__c (no matching row at all for a CO/date/
 * time block) defaults the allowed-staff total to 0, not unlimited - so any nonzero staff request
 * on a drive with no staffing constraint configured will flag as contended. Confirmed against the
 * live LWC behavior and kept as-is rather than "fixed," per explicit product direction.
 *
 * CO_CHANGED_CROSS_REGIONS (checkCoChangedCrossRegions): implemented. Queries
 * sked_Territory_Collection_Operation__c live (not through ctx) because ctx.drive's Collection
 * Operation can itself be patched mid-pass by a CO-change DCR (skedDCRApplyService.
 * applyCollectionOperationChange runs AFTER skedDriveRegenContextLoader.load()) - caching this in
 * the loader would silently query the pre-change CO instead of the one this check actually needs to
 * evaluate.
 *
 * ASSETS_NOT_SHARED_WITH_NEW_CO (checkAssetsNotSharedWithNewCo): implemented, WITHOUT porting
 * slwcAvailator.js's possibleAllocations/exceptionLog engine. skedAssetAvailabilityChecker.
 * isCurrentlyAssignedAssetNotSharedWithCollectionOperation reproduces the one exceptionLog
 * predicate this check actually needs (exceptionLog.length === 1 && code ===
 * 'RESOURCE_NOT_AVAILABLE_FOR_CO') directly against a single already-assigned resource, which is
 * cheaper than building the full candidate-pool allocation matrix the LWC computes.
 *
 * LOCKED_RESOURCE_UNAVAILABLE (checkLockedResourceUnavailable): implemented via
 * skedLockedResourceChecker - see that class's header for the full rule-by-rule mapping to
 * existing Apex building blocks, including the person-side working-time-calendar sub-check behind
 * RESOURCE_TIME_CONFLICT (reformulated as an interval-coverage check, reusing
 * skedAvailabilityPatternService's already-ported pattern-generation logic). Deliberately NOT
 * ported: MAXIMUM_TRAVEL_TIME_VIOLATION's live distance calculation (reuses the already-persisted
 * sked_Geoservice_Travel_Time_To__c/Back__c fields instead, per product decision - has an
 * async-staleness caveat, documented there).
 *
 * validateDriveTimeBlocks (checked first, short-circuits validateDrive on failure - see below):
 * implemented. Every shift's OWN sked_Contention_Resolution__c overrides it, unlike every other
 * check here which reads the drive-level one.
 *
 * STAFFING_COMPLEMENT_CHANGED (checkStaffingComplementChanged): implemented. isSystemGeneratedRole
 * selects between three role lists based on ctx.drive's type and operation type - Mobile, Fixed Site
 * (non-WB), and WB Fixed Site - see the *_SYSTEM_GENERATED_RESOURCE_ROLES constants below. Shifts are
 * paired with their snapshot counterpart by Id (ctx.jobsByShiftId's key) - every shift already has a
 * persisted Id since this validator doesn't create new shifts.
 *
 * Known open deviation, scoped separately: helper.js also treats every ASSET job as a system role,
 * and a Donor Ambassador VOLUNTEER job as one on every non-Mobile drive type (helper.js:3556-3563).
 * isSystemGeneratedRole returns false for any job with a null sked_Resource_Role__c, so neither is
 * ever counted here.
 */
public with sharing class skedDriveContentionValidator {

    public class ValidationResult {
        public Boolean passed = true;
        public List<String> pendingActionReasonCodes = new List<String>();
    }

    private class CheckResult {
        String contention;
        Boolean violated = false;
        Boolean passed = true;
    }

    public static ValidationResult validateDrive(skedDriveRegenContext ctx) {
        List<sked_Drive_Shift__c> driveShifts = ctx.driveShifts;

        // Runs BEFORE every other check and short-circuits on failure - mirrors helper.js's
        // validateDrive, which returns immediately on an unresolved time-block contention rather
        // than accumulating it alongside the rest.
        ValidationResult timeBlockResult = validateDriveTimeBlocks(ctx, driveShifts);
        if (!timeBlockResult.passed) {
            return timeBlockResult;
        }

        // ctx's allocation rows never carry sked__Resource__r (carry-forward/reassignment only
        // ever set the resource Id) - bulk-fetch capacity by Id instead, independent of save state.
        Set<Id> resourceIds = new Set<Id>();
        for (List<sked__Job_Allocation__c> allocations : ctx.allocationsByJobId.values()) {
            for (sked__Job_Allocation__c allocation : allocations) {
                if (allocation.sked__Resource__c != null) {
                    resourceIds.add(allocation.sked__Resource__c);
                }
            }
        }
        // sked_DOT__c/sked_CDL__c are for checkDOTLimit/checkCDLLimit's "currently assigned vehicles"
        // count - same bulk-by-Id lookup, just with 2 extra fields, rather than a second query.
        Map<Id, Decimal> capacityByResourceId = new Map<Id, Decimal>();
        Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>([
            SELECT Id, sked_Pres_Donor_Capacity__c, sked_DOT__c, sked_CDL__c FROM sked__Resource__c WHERE Id IN :resourceIds
        ]);
        for (sked__Resource__c resource : resourceById.values()) {
            capacityByResourceId.put(resource.Id, resource.sked_Pres_Donor_Capacity__c == null ? 0 : resource.sked_Pres_Donor_Capacity__c);
        }

        Biomed_Collection_Op_Center__c collectionOperation = [
            SELECT Id, sked_Minimum_Drive_Start_Time__c, sked_Maximum_Drive_End_Time__c
            FROM Biomed_Collection_Op_Center__c
            WHERE Id = :ctx.drive.sked_Collection_Operation__c
        ];
        sked_Admin_Setting__c adminSetting = sked_Admin_Setting__c.getOrgDefaults();
        String timezoneSidId = resolveTimezoneSidId(ctx);
        // Computed once here rather than inside each of the 4 checks below that need it (3 via
        // checkQuantityLimit, 1 in checkInsufficientResources) - same ctx.sameDateDrives input every
        // time within a single validateDrive() call, no reason to recompute it 4 times.
        List<skedSameDayLinkedDriveCollapser.CollapsedDrive> collapsedSameDateDrives = skedSameDayLinkedDriveCollapser.collapseSameDayLinkedDrives(ctx.sameDateDrives);

        List<CheckResult> results = new List<CheckResult>();
        results.add(checkDriveLimit(ctx, driveShifts));
        results.add(checkX2RBCLimit(ctx, driveShifts, collapsedSameDateDrives));
        results.add(checkDOTLimit(ctx, driveShifts, resourceById, collapsedSameDateDrives));
        results.add(checkCDLLimit(ctx, driveShifts, resourceById, collapsedSameDateDrives));
        results.add(checkMultiShiftDrive(ctx, driveShifts));
        results.add(checkOutOfOperationalHours(ctx, driveShifts, collectionOperation, timezoneSidId));
        results.add(checkLackingEquipment(ctx, driveShifts));
        results.add(checkLackingVehicle(ctx, driveShifts, capacityByResourceId));
        results.add(checkWithin42Days(ctx, timezoneSidId, false));
        results.add(checkWithin42Days(ctx, timezoneSidId, true));
        results.add(checkPartOfLinkedDrive(ctx));
        results.add(checkExcessStaffCapacity(ctx, adminSetting));
        results.add(checkStaffingComplementChanged(ctx));
        results.add(checkInsufficientResources(ctx, driveShifts, collapsedSameDateDrives));
        results.add(checkCoChangedCrossRegions(ctx));
        results.add(checkAssetsNotSharedWithNewCo(ctx, driveShifts));
        results.add(checkLockedResourceUnavailable(ctx));
        // DUAL_ROLE_REMOVAL: intentionally always passes - this contention has never been enabled.

        ValidationResult result = new ValidationResult();
        for (CheckResult check : results) {
            if (!check.passed) {
                result.passed = false;
                result.pendingActionReasonCodes.add(check.contention);
            }
        }
        return result;
    }

    private static Boolean isContentionOverrided(skedDriveRegenContext ctx, String electResolution) {
        if (String.isBlank(ctx.drive.sked_Contention_Resolution__c)) {
            return false;
        }
        return ctx.drive.sked_Contention_Resolution__c.split(';').contains(electResolution);
    }

    /**
     * Ported from helper.js's validateDriveTimeBlocks - unlike every other check here, this is
     * per-shift: each shift's OWN sked_Contention_Resolution__c overrides it, not the drive-level
     * sked_Contention_Resolution__c. A shift with an already-assigned time block is checked for
     * still fitting its (possibly since-changed) start/end time (OUT_OF_TIME_BLOCK); one with none
     * is checked for whether the CO simply has no matching time block at all (MISSING_TIME_BLOCK)
     * or too many ambiguous matches (FIT_MULTIPLE_TIME_BLOCKS). Skips entirely for a Fixed Site
     * drive or a CO with no time blocks configured for this date at all.
     */
    private static ValidationResult validateDriveTimeBlocks(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts) {
        ValidationResult result = new ValidationResult();

        if (!skedCollectionOperationTimeBlockMatcher.isDriveUseTimeBlock(ctx.drive, ctx.collectionOperationTimeBlocks)) {
            return result;
        }

        List<Collection_Operation_Time_Block__c> availableCOTimeBlocks =
            skedCollectionOperationTimeBlockMatcher.findAvailableCOTimeBlocks(ctx.drive, ctx.collectionOperationTimeBlocks);

        Set<String> driveTimeBlockContentions = new Set<String>();
        Boolean allShiftsPassed = true;

        for (sked_Drive_Shift__c shift : driveShifts) {
            List<Collection_Operation_Time_Block__c> availableTimeBlocks = skedCollectionOperationTimeBlockMatcher.findAvailableTimeBlocks(
                ctx.drive, shift.sked_Start_Time__c, shift.sked_End_Time__c, ctx.collectionOperationTimeBlocks);

            String contention = null;
            Boolean passed = true;

            if (shift.sked_Time_Block__c != null) {
                Boolean isTimeBlockAvailable = false;
                for (Collection_Operation_Time_Block__c timeBlock : availableTimeBlocks) {
                    if (timeBlock.Time_Block__c == shift.sked_Time_Block__c) {
                        isTimeBlockAvailable = true;
                        break;
                    }
                }
                if (!isTimeBlockAvailable) {
                    contention = skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_OUT_OF_TIME_BLOCK;
                    passed = isDriveShiftContentionOverrided(shift, contention);
                }
            } else if (!availableCOTimeBlocks.isEmpty() && availableTimeBlocks.isEmpty()) {
                contention = skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_MISSING_TIME_BLOCK;
                passed = isDriveShiftContentionOverrided(shift, contention);
            } else if (availableTimeBlocks.size() >= 2) {
                contention = skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_FIT_MULTIPLE_TIME_BLOCKS;
                passed = isDriveShiftContentionOverrided(shift, contention);
            }

            if (!passed) {
                allShiftsPassed = false;
                driveTimeBlockContentions.add(contention);
            }
        }

        result.passed = allShiftsPassed;
        if (!allShiftsPassed) {
            result.pendingActionReasonCodes.addAll(driveTimeBlockContentions);
        }
        return result;
    }

    private static Boolean isDriveShiftContentionOverrided(sked_Drive_Shift__c shift, String contention) {
        if (String.isBlank(shift.sked_Contention_Resolution__c)) {
            return false;
        }
        List<String> resolutions = shift.sked_Contention_Resolution__c.split(';');
        if (contention == skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_OUT_OF_TIME_BLOCK
                && resolutions.contains(skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_RESOLUTION_ELECT_DRIVE_SHIFT_OUT_OF_TIME_BLOCK)) {
            return true;
        }
        return resolutions.contains(skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_RESOLUTION_ELECT_NOT_USE_DRIVE_SHIFT_TIME_BLOCK);
    }

    // Same-date drive statuses that count toward DRIVE_LIMIT - mirrors DRIVE_STATUS.SYSTEM_GENERATED/
    // TENTATIVE/CONFIRMED/HOLD in helper.js's validateDriveLimit. Public - also reused by
    // computeMaxDotCdlForDrive below (the ghost-vehicle/asset-reassignment ranking tiers).
    public static final Set<String> DRIVE_LIMIT_COUNTABLE_STATUSES = new Set<String>{
        skedConstants.DRIVE_STATUS_SYSTEM_GENERATED, skedConstants.DRIVE_STATUS_TENTATIVE,
        skedConstants.DRIVE_STATUS_CONFIRMED, skedConstants.DRIVE_STATUS_HOLD
    };

    /**
     * Ported from helper.js's validateDriveLimit - counts same-date, non-Fixed-Site drives in a
     * countable status against the CO's configured Drive Limit, both at the drive level (no time
     * block) and per-time-block (any of this drive's shifts' assigned time blocks). Skips entirely
     * for a Fixed Site drive.
     */
    private static CheckResult checkDriveLimit(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_DRIVE_LIMIT;

        if (skedCollectionOperationTimeBlockMatcher.isFixedSiteDrive(ctx.drive)) {
            return result;
        }

        Set<Id> timeBlockIds = collectShiftTimeBlockIds(driveShifts);
        Map<Id, Integer> sameDateConfirmedDrivesByTimeBlockId = new Map<Id, Integer>();
        for (Id timeBlockId : timeBlockIds) {
            sameDateConfirmedDrivesByTimeBlockId.put(timeBlockId, 0);
        }

        // Deliberately NOT collapsed by linked-drive pair - a linked pair still counts as 2
        // separate drives toward this limit (only the x2RBC/DOT/CDL_LIMIT quantity checks below
        // need collapsing, to avoid double-counting a pair's shared resource pool).
        Integer noOfConfirmedDrives = 0;
        for (sked_Drive__c sameDateDrive : ctx.sameDateDrives) {
            if (!DRIVE_LIMIT_COUNTABLE_STATUSES.contains(sameDateDrive.sked_Status__c)
                    || skedCollectionOperationTimeBlockMatcher.isFixedSiteDrive(sameDateDrive)) {
                continue;
            }
            noOfConfirmedDrives++;
            for (sked_Drive_Shift__c sameDateShift : sameDateDrive.sked_Drive_Shifts__r) {
                if (sameDateShift.sked_Time_Block__c != null && timeBlockIds.contains(sameDateShift.sked_Time_Block__c)) {
                    Id timeBlockId = sameDateShift.sked_Time_Block__c;
                    sameDateConfirmedDrivesByTimeBlockId.put(timeBlockId, sameDateConfirmedDrivesByTimeBlockId.get(timeBlockId) + 1);
                }
            }
        }

        Decimal driveLimit = findDriveLimitByDay(ctx.drive.sked_Drive_Date__c,
            filterOperationDriveLimitsByTimeBlock(ctx.operationDriveLimits, null), null);
        Boolean isDriveLimitViolated = driveLimit != null && driveLimit <= noOfConfirmedDrives;

        Boolean isAnyTimeBlockLimitViolated = false;
        for (Id timeBlockId : timeBlockIds) {
            Decimal timeBlockLimit = findDriveLimitByDay(ctx.drive.sked_Drive_Date__c,
                filterOperationDriveLimitsByTimeBlock(ctx.operationDriveLimits, timeBlockId), null);
            if (timeBlockLimit != null && timeBlockLimit <= sameDateConfirmedDrivesByTimeBlockId.get(timeBlockId)) {
                isAnyTimeBlockLimitViolated = true;
            }
        }

        result.violated = isDriveLimitViolated || isAnyTimeBlockLimitViolated;
        result.passed = !result.violated || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_DRIVE_LIMIT);
        return result;
    }

    // Which same-date-drive quantity a checkQuantityLimit call aggregates.
    private enum QuantityField { x2RBC, DOT, CDL }

    private static Decimal getSameDateQuantity(skedSameDayLinkedDriveCollapser.CollapsedDrive drive, QuantityField field) {
        Decimal value = field == QuantityField.x2RBC ? drive.totalEquipmentRequested
            : field == QuantityField.DOT ? drive.noOfAllocatedDOTVehicles
            : drive.noOfAllocatedCDLVehicles;
        return value == null ? 0 : value;
    }

    /**
     * Shared by checkX2RBCLimit/checkDOTLimit/checkCDLLimit - ported from helper.js's
     * validate2RBCLimit/validateDOTLimit/validateCDLLimit, which are structurally identical to
     * each other (only the field read differs). Same shape as checkDriveLimit, but sums a
     * quantity across same-date drives instead of counting drives, and only violates when THIS
     * drive itself requests/has-allocated >0. Same-date drives ARE collapsed by linked-drive pair
     * first (unlike checkDriveLimit) so a linked pair's shared resource pool isn't double-counted.
     * A same-date drive's quantity is added to EVERY one of its own matching time blocks, not
     * split across them - matches the source.
     */
    private static CheckResult checkQuantityLimit(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts,
            String contention, String resolutionElect, String operationDriveLimitType, QuantityField field, Decimal noOfRequested,
            List<skedSameDayLinkedDriveCollapser.CollapsedDrive> collapsedSameDateDrives) {
        CheckResult result = new CheckResult();
        result.contention = contention;

        if (skedCollectionOperationTimeBlockMatcher.isFixedSiteDrive(ctx.drive)) {
            return result;
        }

        Set<Id> timeBlockIds = collectShiftTimeBlockIds(driveShifts);
        Map<Id, Decimal> sameDateByTimeBlockId = new Map<Id, Decimal>();
        for (Id timeBlockId : timeBlockIds) {
            sameDateByTimeBlockId.put(timeBlockId, 0);
        }

        Decimal sameDateTotal = 0;
        for (skedSameDayLinkedDriveCollapser.CollapsedDrive sameDateDrive : collapsedSameDateDrives) {
            if (!DRIVE_LIMIT_COUNTABLE_STATUSES.contains(sameDateDrive.status) || sameDateDrive.isFixedSite) {
                continue;
            }
            Decimal quantity = getSameDateQuantity(sameDateDrive, field);
            sameDateTotal += quantity;
            for (skedSameDayLinkedDriveCollapser.CollapsedDriveShift shift : sameDateDrive.driveShifts) {
                if (shift.timeBlockId != null && timeBlockIds.contains(shift.timeBlockId)) {
                    sameDateByTimeBlockId.put(shift.timeBlockId, sameDateByTimeBlockId.get(shift.timeBlockId) + quantity);
                }
            }
        }

        Decimal operationalLimit = findDriveLimitByDay(ctx.drive.sked_Drive_Date__c,
            filterOperationDriveLimitsByTimeBlock(ctx.operationDriveLimits, null), operationDriveLimitType);
        Boolean isOverallViolated = noOfRequested > 0 && operationalLimit != null && sameDateTotal + noOfRequested > operationalLimit;

        Boolean isAnyTimeBlockViolated = false;
        for (Id timeBlockId : timeBlockIds) {
            Decimal timeBlockLimit = findDriveLimitByDay(ctx.drive.sked_Drive_Date__c,
                filterOperationDriveLimitsByTimeBlock(ctx.operationDriveLimits, timeBlockId), operationDriveLimitType);
            if (timeBlockLimit != null && noOfRequested > 0 && sameDateByTimeBlockId.get(timeBlockId) + noOfRequested > timeBlockLimit) {
                isAnyTimeBlockViolated = true;
            }
        }

        result.violated = isOverallViolated || isAnyTimeBlockViolated;
        result.passed = !result.violated || isContentionOverrided(ctx, resolutionElect);
        return result;
    }

    private static CheckResult checkX2RBCLimit(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts,
            List<skedSameDayLinkedDriveCollapser.CollapsedDrive> collapsedSameDateDrives) {
        Decimal noOf2RBCRequested = ctx.drive.sked_Total_Equipment_Requested__c == null ? 0 : ctx.drive.sked_Total_Equipment_Requested__c;
        return checkQuantityLimit(ctx, driveShifts, skedConstants.DRIVE_CONTENTION_x2RBC_LIMIT,
            skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_2RBC_LIMIT, skedConstants.OPERATION_DRIVE_LIMIT_TYPE_x2RBC_LIMIT,
            QuantityField.x2RBC, noOf2RBCRequested, collapsedSameDateDrives);
    }

    private static CheckResult checkDOTLimit(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts, Map<Id, sked__Resource__c> resourceById,
            List<skedSameDayLinkedDriveCollapser.CollapsedDrive> collapsedSameDateDrives) {
        Decimal noOfDOTRequested = countAssignedVehiclesWithFlag(ctx, driveShifts, resourceById, true);
        return checkQuantityLimit(ctx, driveShifts, skedConstants.DRIVE_CONTENTION_DOT_LIMIT,
            skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_DOT_LIMIT, skedConstants.OPERATION_DRIVE_LIMIT_TYPE_DOT_LIMIT,
            QuantityField.DOT, noOfDOTRequested, collapsedSameDateDrives);
    }

    private static CheckResult checkCDLLimit(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts, Map<Id, sked__Resource__c> resourceById,
            List<skedSameDayLinkedDriveCollapser.CollapsedDrive> collapsedSameDateDrives) {
        Decimal noOfCDLRequested = countAssignedVehiclesWithFlag(ctx, driveShifts, resourceById, false);
        return checkQuantityLimit(ctx, driveShifts, skedConstants.DRIVE_CONTENTION_CDL_LIMIT,
            skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_CDL_LIMIT, skedConstants.OPERATION_DRIVE_LIMIT_TYPE_CDL_LIMIT,
            QuantityField.CDL, noOfCDLRequested, collapsedSameDateDrives);
    }

    // Mirrors helper.js's getCurrentAssignedVehicles - the first shift's vehicle job's active
    // (non-Deleted) allocations, filtered by the resource's DOT or CDL flag.
    private static Integer countAssignedVehiclesWithFlag(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts,
            Map<Id, sked__Resource__c> resourceById, Boolean isDOT) {
        if (driveShifts.isEmpty()) {
            return 0;
        }
        sked_Drive_Shift__c shift = driveShifts[0];
        List<sked__Job__c> jobs = ctx.jobsByShiftId.get(shift.Id);
        sked__Job__c vehicleJob;
        for (sked__Job__c job : jobs == null ? new List<sked__Job__c>() : jobs) {
            if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                vehicleJob = job;
                break;
            }
        }
        if (vehicleJob == null) {
            return 0;
        }

        Integer count = 0;
        List<sked__Job_Allocation__c> allocations = ctx.allocationsByJobId.get(vehicleJob.Id);
        for (sked__Job_Allocation__c allocation : allocations == null ? new List<sked__Job_Allocation__c>() : allocations) {
            if (allocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                continue;
            }
            sked__Resource__c resource = resourceById.get(allocation.sked__Resource__c);
            Boolean flagValue = resource == null ? null : (isDOT ? resource.sked_DOT__c : resource.sked_CDL__c);
            if (flagValue == true) {
                count++;
            }
        }
        return count;
    }

    // Shared by the DRIVE_LIMIT family (checkDriveLimit/checkX2RBCLimit/checkDOTLimit/checkCDLLimit).
    private static Set<Id> collectShiftTimeBlockIds(List<sked_Drive_Shift__c> driveShifts) {
        Set<Id> timeBlockIds = new Set<Id>();
        for (sked_Drive_Shift__c shift : driveShifts) {
            if (shift.sked_Time_Block__c != null) {
                timeBlockIds.add(shift.sked_Time_Block__c);
            }
        }
        return timeBlockIds;
    }

    public static List<sked_Operation_Drive_Limit__c> filterOperationDriveLimitsByTimeBlock(
            List<sked_Operation_Drive_Limit__c> operationDriveLimits, Id timeBlockId) {
        List<sked_Operation_Drive_Limit__c> filtered = new List<sked_Operation_Drive_Limit__c>();
        for (sked_Operation_Drive_Limit__c odl : operationDriveLimits) {
            if (timeBlockId == null ? odl.Time_Block__c == null : odl.Time_Block__c == timeBlockId) {
                filtered.add(odl);
            }
        }
        return filtered;
    }

    /**
     * Ported from helper.js's findDriveLimitByDay - day-of-week/effective-date-range match against
     * limits of `type` (blank/null type defaults to DRIVE_LIMIT, matching the source), with a
     * per-date override taking precedence regardless of whether the parent limit's own date range/
     * day-of-week matched. Returns null when nothing configured (an unbounded/"infinite" limit).
     */
    public static Decimal findDriveLimitByDay(Date driveDate, List<sked_Operation_Drive_Limit__c> operationDriveLimits, String type) {
        if (driveDate == null || operationDriveLimits == null) {
            return null;
        }
        String dayOfWeek = skedMobileDriveShiftCalculator.getDayOfWeekName(driveDate);
        Decimal driveLimit = null;
        for (sked_Operation_Drive_Limit__c odl : operationDriveLimits) {
            Boolean matchesType = String.isBlank(type)
                ? (String.isBlank(odl.sked_Type__c) || odl.sked_Type__c == skedConstants.OPERATION_DRIVE_LIMIT_TYPE_DRIVE_LIMIT)
                : odl.sked_Type__c == type;
            if (!matchesType) {
                continue;
            }

            Boolean isDateRangeValid = (odl.sked_Effective_Start_Date__c == null || odl.sked_Effective_Start_Date__c <= driveDate)
                && (odl.sked_Effective_End_Date__c == null || driveDate <= odl.sked_Effective_End_Date__c);
            Boolean isDayOfWeekValid = String.isNotBlank(odl.sked_Days_of_Week__c) && odl.sked_Days_of_Week__c.split(';').contains(dayOfWeek);
            if (isDateRangeValid && isDayOfWeekValid) {
                driveLimit = odl.sked_Quantity__c;
            }

            for (sked_Operation_Drive_Limit_Override__c limitOverride : odl.sked_Operation_Drive_Limit_Overrides__r) {
                if (limitOverride.sked_Date__c == driveDate) {
                    driveLimit = limitOverride.sked_Quantity__c;
                }
            }
        }
        return driveLimit;
    }

    public class MaxDotCdl {
        public Decimal maxDOT;
        public Decimal maxCDL;
    }

    // A large-but-finite stand-in for "unbounded" - Apex has no Decimal infinity, and this value only
    // ever feeds a <= comparison against a real vehicle count, never arithmetic that could overflow.
    private static final Decimal UNBOUNDED_VEHICLE_LIMIT = 999999999;

    /**
     * Ported from helper.js's getMaxDOTAndCDLForDrive - used by the ghost-vehicle/asset-reassignment
     * vehicle-ranking tiers (skedMobileGhostVehicleCalculator/skedMobileAssetReassigner), NOT by
     * checkDOTLimit/checkCDLLimit above. This is a genuinely different call site in the source with
     * different semantics - no same-day-linked-drive collapsing here (skedSameDayLinkedDriveCollapser
     * is never invoked by the JS's own getMaxDOTAndCDLForDrive), matching the source exactly rather
     * than assuming parity with checkQuantityLimit's collapsed sum. Unbounded when no operational
     * limit is configured for that type (matches the source's Number.MAX_SAFE_INTEGER default).
     */
    public static MaxDotCdl computeMaxDotCdlForDrive(sked_Drive__c drive, List<sked_Operation_Drive_Limit__c> operationDriveLimits, List<sked_Drive__c> sameDateDrives) {
        MaxDotCdl result = new MaxDotCdl();
        result.maxDOT = UNBOUNDED_VEHICLE_LIMIT;
        result.maxCDL = UNBOUNDED_VEHICLE_LIMIT;
        if (drive == null || operationDriveLimits == null || operationDriveLimits.isEmpty()) {
            return result;
        }

        List<sked_Operation_Drive_Limit__c> overallLimits = filterOperationDriveLimitsByTimeBlock(operationDriveLimits, null);
        Decimal operationalDotLimit = findDriveLimitByDay(drive.sked_Drive_Date__c, overallLimits, skedConstants.OPERATION_DRIVE_LIMIT_TYPE_DOT_LIMIT);
        Decimal operationalCdlLimit = findDriveLimitByDay(drive.sked_Drive_Date__c, overallLimits, skedConstants.OPERATION_DRIVE_LIMIT_TYPE_CDL_LIMIT);

        Decimal sameDateDotAllocated = 0;
        Decimal sameDateCdlAllocated = 0;
        for (sked_Drive__c sameDateDrive : sameDateDrives == null ? new List<sked_Drive__c>() : sameDateDrives) {
            if (!DRIVE_LIMIT_COUNTABLE_STATUSES.contains(sameDateDrive.sked_Status__c) || skedCollectionOperationTimeBlockMatcher.isFixedSiteDrive(sameDateDrive)) {
                continue;
            }
            sameDateDotAllocated += sameDateDrive.sked_No_of_Allocated_DOT__c == null ? 0 : sameDateDrive.sked_No_of_Allocated_DOT__c;
            sameDateCdlAllocated += sameDateDrive.sked_No_of_Allocated_CDL__c == null ? 0 : sameDateDrive.sked_No_of_Allocated_CDL__c;
        }

        if (operationalDotLimit != null) {
            Decimal net = operationalDotLimit - sameDateDotAllocated;
            result.maxDOT = net < 0 ? 0 : net;
        }
        if (operationalCdlLimit != null) {
            Decimal net = operationalCdlLimit - sameDateCdlAllocated;
            result.maxCDL = net < 0 ? 0 : net;
        }
        return result;
    }

    /**
     * sked_Drive__c.sked_Timezone__c is a formula mirroring sked_Drive_Site__r.sked_Timezone__c
     * (Location), already selected by skedDriveRegenContextLoader - no extra query needed here.
     * Falls back to the running user's timezone when the drive has no site/timezone, since
     * skedDateTimeUtils throws on a null timezone. Public - also reused by skedLockedResourceChecker.
     */
    public static String resolveTimezoneSidId(skedDriveRegenContext ctx) {
        return String.isNotBlank(ctx.drive.sked_Timezone__c) ? ctx.drive.sked_Timezone__c : UserInfo.getTimeZone().getID();
    }

    private static CheckResult checkMultiShiftDrive(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_MULTI_SHIFT_DRIVE;
        result.violated = driveShifts.size() > 1;
        result.passed = !result.violated || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_MULTI_SHIFT_DRIVE);
        return result;
    }

    private static CheckResult checkOutOfOperationalHours(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts,
            Biomed_Collection_Op_Center__c collectionOperation, String timezoneSidId) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_OUT_OF_OPERATIONAL_HOURS;

        // A null drive date must make both bounds null (never violated) rather than throw -
        // skedDateTimeUtils.getDateTimeFromDateAndTime throws on a null Date argument.
        DateTime minimumDriveStart = (collectionOperation.sked_Minimum_Drive_Start_Time__c == null || ctx.drive.sked_Drive_Date__c == null) ? null
            : skedDateTimeUtils.getDateTimeFromDateAndTime(ctx.drive.sked_Drive_Date__c, collectionOperation.sked_Minimum_Drive_Start_Time__c, timezoneSidId);
        DateTime maximumDriveEnd = (collectionOperation.sked_Maximum_Drive_End_Time__c == null || ctx.drive.sked_Drive_Date__c == null) ? null
            : skedDateTimeUtils.getDateTimeFromDateAndTime(ctx.drive.sked_Drive_Date__c, collectionOperation.sked_Maximum_Drive_End_Time__c, timezoneSidId);

        Boolean isOutOfOperationalHours = false;
        for (sked_Drive_Shift__c shift : driveShifts) {
            if (shift.sked_Start__c == null || shift.sked_Finish__c == null) {
                continue;
            }
            if (minimumDriveStart != null && minimumDriveStart > shift.sked_Start__c) {
                isOutOfOperationalHours = true;
            }
            if (maximumDriveEnd != null && maximumDriveEnd < shift.sked_Finish__c) {
                isOutOfOperationalHours = true;
            }
        }

        result.violated = isOutOfOperationalHours;
        result.passed = !result.violated || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_OUT_OF_OPERATIONAL_HOURS);
        return result;
    }

    private static CheckResult checkLackingEquipment(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_LACKING_EQUIPMENT;
        if (driveShifts.isEmpty()) {
            result.passed = true;
            return result;
        }
        sked_Drive_Shift__c shift = driveShifts[0];
        List<sked__Job__c> jobs = ctx.jobsByShiftId.get(shift.Id);

        sked__Job__c equipmentJob;
        for (sked__Job__c job : jobs == null ? new List<sked__Job__c>() : jobs) {
            if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                equipmentJob = job;
                break;
            }
        }

        Integer quantityAssigned = 0;
        Decimal quantityNeeded = 0;
        if (equipmentJob != null) {
            quantityNeeded = equipmentJob.sked__Quantity__c == null ? 0 : equipmentJob.sked__Quantity__c;
            List<sked__Job_Allocation__c> allocations = ctx.allocationsByJobId.get(equipmentJob.Id);
            Set<Id> activeResourceIds = new Set<Id>();
            for (sked__Job_Allocation__c allocation : allocations == null ? new List<sked__Job_Allocation__c>() : allocations) {
                if (allocation.sked__Status__c != skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                    activeResourceIds.add(allocation.sked__Resource__c);
                }
            }
            // A currently-assigned resource that's since become unavailable elsewhere (e.g. the
            // drive date moved onto another drive's booking) no longer counts toward quantityAssigned.
            Set<Id> unavailableResourceIds = skedAssetAvailabilityChecker.findConflictedResourceIds(
                activeResourceIds, ctx.drive.Id, shift.sked_Start__c, shift.sked_Finish__c);
            quantityAssigned = activeResourceIds.size() - unavailableResourceIds.size();
        }

        result.violated = quantityAssigned < quantityNeeded;
        // No override resolution exists for this contention - never overridable.
        result.passed = !result.violated;
        return result;
    }

    private static CheckResult checkLackingVehicle(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts, Map<Id, Decimal> capacityByResourceId) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_LACKING_VEHICLE;
        if (driveShifts.isEmpty()) {
            result.passed = true;
            return result;
        }

        sked_Drive_Shift__c shift = driveShifts[0];
        List<sked__Job__c> jobs = ctx.jobsByShiftId.get(shift.Id);
        sked__Job__c vehicleJob;
        for (sked__Job__c job : jobs == null ? new List<sked__Job__c>() : jobs) {
            if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                vehicleJob = job;
                break;
            }
        }

        Decimal totalCurrentAssignedVehiclesCapacity = 0;
        if (vehicleJob != null) {
            List<sked__Job_Allocation__c> allocations = ctx.allocationsByJobId.get(vehicleJob.Id);
            Map<Id, Decimal> capacityByAssignedResourceId = new Map<Id, Decimal>();
            for (sked__Job_Allocation__c allocation : allocations == null ? new List<sked__Job_Allocation__c>() : allocations) {
                if (allocation.sked__Status__c != skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                    Decimal capacity = capacityByResourceId.get(allocation.sked__Resource__c);
                    capacityByAssignedResourceId.put(allocation.sked__Resource__c, capacity == null ? 0 : capacity);
                }
            }
            // Same discounting as checkLackingEquipment - a currently-assigned vehicle that's since
            // become unavailable elsewhere no longer counts toward the drive's assigned capacity.
            Set<Id> unavailableResourceIds = skedAssetAvailabilityChecker.findConflictedResourceIds(
                capacityByAssignedResourceId.keySet(), ctx.drive.Id, shift.sked_Start__c, shift.sked_Finish__c);
            for (Id resourceId : capacityByAssignedResourceId.keySet()) {
                if (!unavailableResourceIds.contains(resourceId)) {
                    totalCurrentAssignedVehiclesCapacity += capacityByAssignedResourceId.get(resourceId);
                }
            }
        }

        Decimal maxRegisteredDonors = 0;
        for (sked_Drive_Shift__c eachShift : driveShifts) {
            if (eachShift.sked_Donors_Scheduled__c != null && eachShift.sked_Donors_Scheduled__c > maxRegisteredDonors) {
                maxRegisteredDonors = eachShift.sked_Donors_Scheduled__c;
            }
        }
        if (maxRegisteredDonors == 0) {
            maxRegisteredDonors = ctx.drive.sked_Projected_Registered_Donors__c == null ? 0 : ctx.drive.sked_Projected_Registered_Donors__c;
        }

        result.violated = ctx.drive.sked_Do_Not_Use_Vehicle__c != true && totalCurrentAssignedVehiclesCapacity < maxRegisteredDonors;
        result.passed = !result.violated
            || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LACKING_VEHICLE_INSUFFICIENT_CAPACITY)
            || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LACKING_VEHICLE_USE_RENTAL);
        return result;
    }

    // isConfirmVariant=false -> WITHIN_42_DAYS (violated when NOT just moved to Confirmed);
    // isConfirmVariant=true -> CONFIRM_WITHIN_42_DAYS (violated when it WAS just moved to Confirmed).
    // Both share the same diff/within42Days computation.
    private static CheckResult checkWithin42Days(skedDriveRegenContext ctx, String timezoneSidId, Boolean isConfirmVariant) {
        CheckResult result = new CheckResult();
        result.contention = isConfirmVariant ? skedConstants.DRIVE_CONTENTION_CONFIRM_WITHIN_42_DAYS : skedConstants.DRIVE_CONTENTION_WITHIN_42_DAYS;

        // A null drive date must never violate either variant.
        if (ctx.drive.sked_Drive_Date__c == null) {
            result.violated = false;
            result.passed = true;
            return result;
        }

        Boolean isDriveStatusMovedToConfirmed = ctx.snapshot.drive.sked_Status__c != skedConstants.DRIVE_STATUS_CONFIRMED
            && ctx.drive.sked_Status__c == skedConstants.DRIVE_STATUS_CONFIRMED;
        Date today = skedDateTimeUtils.getDate(DateTime.now(), timezoneSidId);
        Integer diff = today.daysBetween(ctx.drive.sked_Drive_Date__c);
        Boolean within42Days = diff <= 42;

        result.violated = isConfirmVariant ? (isDriveStatusMovedToConfirmed && within42Days) : (!isDriveStatusMovedToConfirmed && within42Days);
        String electResolution = isConfirmVariant
            ? skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_CONFIRM_WITHIN_42_DAYS
            : skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_WITHIN_42_DAYS;
        result.passed = !result.violated || isContentionOverrided(ctx, electResolution);
        return result;
    }

    // totalStaffRequestedChanged/VehicleRequestedChanged/EquipmentRequestedChanged compare the
    // rollup's pre-regen value (backupDrive - accurate, reflects the last-persisted state) against
    // a FRESH total summed from ctx.jobsByShiftId (skedDriveRegenContext.sumStaffRequested/
    // sumVehicleRequested/sumEquipmentRequested, matching baseGenerator.js's
    // updateDriveRequestedResources exactly), not against ctx.drive's own copy of the rollup -
    // sked_Total_Staff/Vehicle/Equipment_Requested__c are Roll-Up Summary fields, never recalculated
    // in-memory during a regen, so ctx.drive's value is identical to backupDrive's and every one of
    // these comparisons would be a structural no-op if it read ctx.drive directly instead.
    private static CheckResult checkPartOfLinkedDrive(skedDriveRegenContext ctx) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_PART_OF_LINKED_DRIVE;

        sked_Drive__c backupDrive = ctx.snapshot.drive;
        Decimal backupStaffRequested = backupDrive.sked_Total_Staff_Requested__c == null ? 0 : backupDrive.sked_Total_Staff_Requested__c;
        Decimal backupVehicleRequested = backupDrive.sked_Total_Vehicle_Requested__c == null ? 0 : backupDrive.sked_Total_Vehicle_Requested__c;
        Decimal backupEquipmentRequested = backupDrive.sked_Total_Equipment_Requested__c == null ? 0 : backupDrive.sked_Total_Equipment_Requested__c;

        Boolean isDriveDateChanged = backupDrive.sked_Drive_Date__c != ctx.drive.sked_Drive_Date__c;
        Boolean totalStaffRequestedChanged = backupStaffRequested != skedDriveRegenContext.sumStaffRequested(ctx.jobsByShiftId);
        Boolean totalVehicleRequestedChanged = backupVehicleRequested != skedDriveRegenContext.sumVehicleRequested(ctx.jobsByShiftId);
        Boolean totalEquipmentRequestedChanged = backupEquipmentRequested != skedDriveRegenContext.sumEquipmentRequested(ctx.jobsByShiftId);
        Boolean isPartOfLinkedDrive = backupDrive.sked_Linked_Drives__c != null;

        result.violated = (isDriveDateChanged || totalStaffRequestedChanged || totalVehicleRequestedChanged || totalEquipmentRequestedChanged) && isPartOfLinkedDrive;
        result.passed = !result.violated || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_PART_OF_LINKED_DRIVE);
        return result;
    }

    private static CheckResult checkExcessStaffCapacity(skedDriveRegenContext ctx, sked_Admin_Setting__c adminSetting) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_EXCESS_STAFF_CAPACITY;

        // Not drive-type gated - matches helper.js:3145's validateExcessStaffCapacity, which also
        // runs for Fixed Site. fixedSiteGenerator.js doesn't recompute excessStaffCapacity, but batch
        // writers (BSF_UpdateDriveExcessStaffCapacityBatch, DriveResourceAllocationBatch) still
        // populate the field for Fixed Site drives.
        // An unconfigured (null) threshold must never violate - it must not default to some
        // in-range value like 1.
        Decimal threshold = adminSetting.Admin_Excess_Staff_Capacity_Threshold__c;
        Decimal excessStaffCapacity = ctx.drive.Excess_Staff_Capacity__c == null ? 0 : ctx.drive.Excess_Staff_Capacity__c;

        result.violated = threshold != null && excessStaffCapacity >= threshold;
        result.passed = !result.violated || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_EXCESS_STAFF_CAPACITY);
        return result;
    }

    // STAFFING_COMPLEMENT_CHANGED-only literals - 'Staffing Modal' matches skedMobileDriveJobBuilder's
    // own private MANUALLY_CREATED_FROM_STAFFING_MODAL constant (duplicated, not shared - single string).
    private static final Set<String> MOBILE_SYSTEM_GENERATED_RESOURCE_ROLES = new Set<String>{
        'Driver', 'Driver Support', '2RBC', 'Drive Lead', 'Team Supervisor', 'Charge', 'VP/HH'
    };
    // Matches helper.js:3551-3552's isSystemRole Fixed Site (not WB) branch.
    private static final Set<String> FIXED_SITE_SYSTEM_GENERATED_RESOURCE_ROLES = new Set<String>{
        'Apheresis Charge', 'Apheresis'
    };
    // Matches helper.js:3553-3554's isSystemRole WB Fixed Site branch - Mobile's list minus Driver and
    // Driver Support, which WB's generator never creates.
    private static final Set<String> WB_FIXED_SITE_SYSTEM_GENERATED_RESOURCE_ROLES = new Set<String>{
        '2RBC', 'Drive Lead', 'Team Supervisor', 'Charge', 'VP/HH'
    };
    private static final String RESOURCE_ROLE_VPHH = 'VP/HH';
    private static final String MANUALLY_CREATED_FROM_STAFFING_MODAL = 'Staffing Modal';

    /**
     * Diffs ctx (post-regen) against ctx.snapshot (pre-regen, populated at load time before any
     * regen mutation - see skedDriveRegenContextLoader), restricted to system-generated
     * resource-role jobs.
     */
    private static CheckResult checkStaffingComplementChanged(skedDriveRegenContext ctx) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED;

        Boolean staffingComplementChanged = false;

        for (Id shiftId : ctx.jobsByShiftId.keySet()) {
            List<sked__Job__c> backupJobs = ctx.snapshot.jobsByShiftId.get(shiftId);
            for (sked__Job__c job : ctx.jobsByShiftId.get(shiftId)) {
                if (isManuallyCreatedFromStaffingModal(job) || !isSystemGeneratedRole(job, ctx.drive)) {
                    continue;
                }
                sked__Job__c backupJob = findJobWithSameRole(job, backupJobs);
                if (backupJob == null) {
                    Decimal quantity = job.sked__Quantity__c == null ? 0 : job.sked__Quantity__c;
                    Decimal vphhQuantity = job.sked_VPHH_Quantity__c == null ? 0 : job.sked_VPHH_Quantity__c;
                    Decimal aptQuantity = job.sked_APT_Quantity__c == null ? 0 : job.sked_APT_Quantity__c;
                    if (quantity > 0 || vphhQuantity > 0 || aptQuantity > 0) {
                        staffingComplementChanged = true;
                    }
                } else if (isJobChanged(job, backupJob, ctx.drive, ctx.snapshot.drive)) {
                    staffingComplementChanged = true;
                }
            }
        }

        for (Id shiftId : ctx.snapshot.jobsByShiftId.keySet()) {
            List<sked__Job__c> currentJobs = ctx.jobsByShiftId.get(shiftId);
            for (sked__Job__c backupJob : ctx.snapshot.jobsByShiftId.get(shiftId)) {
                if (isManuallyCreatedFromStaffingModal(backupJob) || !isSystemGeneratedRole(backupJob, ctx.drive)) {
                    continue;
                }
                if (findJobWithSameRole(backupJob, currentJobs) == null) {
                    staffingComplementChanged = true;
                }
            }
        }

        result.violated = staffingComplementChanged;
        // No override resolution defined for this contention in the source - never overridable.
        result.passed = !result.violated;
        return result;
    }

    private static Boolean isJobChanged(sked__Job__c job, sked__Job__c backupJob, sked_Drive__c currentDrive, sked_Drive__c backupDrive) {
        // Coalesced to 0 deliberately, unlike the source's raw !== comparison - null and 0 both mean
        // "no system quantity," and systemQuantity is always system-computed, never left genuinely
        // null in practice, so this can't diverge from the source on any real drive.
        Decimal jobSystemQuantity = job.sked_System_Quantity__c == null ? 0 : job.sked_System_Quantity__c;
        Decimal backupJobSystemQuantity = backupJob.sked_System_Quantity__c == null ? 0 : backupJob.sked_System_Quantity__c;

        if (job.sked_Resource_Role__c != RESOURCE_ROLE_VPHH) {
            return jobSystemQuantity != backupJobSystemQuantity;
        }

        Decimal jobAptQuantity = job.sked_APT_Quantity__c == null ? 0 : job.sked_APT_Quantity__c;
        Decimal backupJobAptQuantity = backupJob.sked_APT_Quantity__c == null ? 0 : backupJob.sked_APT_Quantity__c;
        if (jobAptQuantity != backupJobAptQuantity) {
            return true;
        }

        // VP/HH's systemQuantity is netted against the drive-level APT quantity before comparing -
        // a VP/HH job's own systemQuantity includes APT donors, which move independently of it.
        Decimal currentDriveAptQuantity = currentDrive.sked_APT_Quantity__c == null ? 0 : currentDrive.sked_APT_Quantity__c;
        Decimal backupDriveAptQuantity = backupDrive.sked_APT_Quantity__c == null ? 0 : backupDrive.sked_APT_Quantity__c;
        Decimal currentVphhSystemQuantity = Math.max(jobSystemQuantity - currentDriveAptQuantity, 0);
        Decimal backupVphhSystemQuantity = Math.max(backupJobSystemQuantity - backupDriveAptQuantity, 0);
        return currentVphhSystemQuantity != backupVphhSystemQuantity;
    }

    private static Boolean isSystemGeneratedRole(sked__Job__c job, sked_Drive__c drive) {
        if (job.sked_Resource_Role__c == null) {
            return false;
        }
        // Three-way, mirroring helper.js:3544-3555. The fallback stays Mobile rather than helper.js's
        // implicit `return false` for a drive type matching none of the three (RSMO) - that divergence
        // predates this branch and RSMO has no engine at all, so narrowing it is a separate decision.
        Set<String> systemGeneratedRoles = MOBILE_SYSTEM_GENERATED_RESOURCE_ROLES;
        if (drive.sked_Type_of_Drive__c == skedConstants.DRIVE_TYPE_FIXED_SITE) {
            systemGeneratedRoles = drive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_WB
                ? WB_FIXED_SITE_SYSTEM_GENERATED_RESOURCE_ROLES
                : FIXED_SITE_SYSTEM_GENERATED_RESOURCE_ROLES;
        }
        return systemGeneratedRoles.contains(job.sked_Resource_Role__c);
    }

    private static Boolean isManuallyCreatedFromStaffingModal(sked__Job__c job) {
        return job.sked_Is_Manually_Created__c == true && job.sked_Manually_Created_From__c == MANUALLY_CREATED_FROM_STAFFING_MODAL;
    }

    // dualRole null and blank must be treated as the same (no dual role), not as a mismatch.
    private static sked__Job__c findJobWithSameRole(sked__Job__c job, List<sked__Job__c> candidates) {
        if (candidates == null) {
            return null;
        }
        String dualRole = job.sked_Dual_Role__c == null ? '' : job.sked_Dual_Role__c;
        for (sked__Job__c candidate : candidates) {
            String candidateDualRole = candidate.sked_Dual_Role__c == null ? '' : candidate.sked_Dual_Role__c;
            if (job.sked_Resource_Role__c == candidate.sked_Resource_Role__c && dualRole == candidateDualRole) {
                return candidate;
            }
        }
        return null;
    }

    /**
     * Ported from helper.js's validateInsufficientResources. No Fixed-Site early return - unlike
     * the DRIVE_LIMIT family, this check runs for every drive type. Same-date drives/activities are
     * collapsed by linked pair first (see skedSameDayLinkedDriveCollapser), same as the quantity
     * limit checks. An unconfigured staffing constraint (no matching sked_Staffing_Constraint__c row
     * at all) is NOT treated as "unlimited" - it defaults to 0 (zero staff allowed), matching the
     * source exactly; confirmed and accepted as intentional rather than an unconfigured-limit bug.
     */
    private static CheckResult checkInsufficientResources(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts,
            List<skedSameDayLinkedDriveCollapser.CollapsedDrive> collapsedSameDateDrives) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_INSUFFICIENT_RESOURCES;

        Set<Id> timeBlockIds = collectShiftTimeBlockIds(driveShifts);
        Map<Id, Decimal> staffRequestedByTimeBlockId = new Map<Id, Decimal>();
        Map<Id, Decimal> sameDateStaffRequestedByTimeBlockId = new Map<Id, Decimal>();
        Map<Id, Decimal> staffingConstraintByTimeBlockId = new Map<Id, Decimal>();
        for (Id timeBlockId : timeBlockIds) {
            sameDateStaffRequestedByTimeBlockId.put(timeBlockId, 0);
            staffingConstraintByTimeBlockId.put(timeBlockId, 0);
        }

        Decimal totalStaffRequested = 0;
        for (sked_Drive_Shift__c shift : driveShifts) {
            if (shift.sked_Time_Block__c != null) {
                staffRequestedByTimeBlockId.put(shift.sked_Time_Block__c, shift.sked_Staff_Setup__c == null ? 0 : shift.sked_Staff_Setup__c);
            }
            List<sked__Job__c> jobs = ctx.jobsByShiftId.get(shift.Id);
            for (sked__Job__c job : jobs == null ? new List<sked__Job__c>() : jobs) {
                if (isManuallyCreatedFromStaffingModal(job)) {
                    continue;
                }
                if (job.sked_Resource_Role__c != null) {
                    totalStaffRequested += job.sked__Quantity__c == null ? 0 : job.sked__Quantity__c;
                }
            }
        }

        // HRP-15611: collapse same-day linked drives/activities to max(staff), not sum, before
        // summing same-date totals - see skedSameDayLinkedDriveCollapser.
        Boolean isFixedSite = skedCollectionOperationTimeBlockMatcher.isFixedSiteDrive(ctx.drive);
        Decimal sameDateDrivesStaffRequested = 0;
        for (skedSameDayLinkedDriveCollapser.CollapsedDrive sameDateDrive : collapsedSameDateDrives) {
            if (!DRIVE_LIMIT_COUNTABLE_STATUSES.contains(sameDateDrive.status) || isFixedSite != sameDateDrive.isFixedSite) {
                continue;
            }
            sameDateDrivesStaffRequested += sameDateDrive.totalStaffRequested == null ? 0 : sameDateDrive.totalStaffRequested;
            for (skedSameDayLinkedDriveCollapser.CollapsedDriveShift shift : sameDateDrive.driveShifts) {
                if (shift.timeBlockId != null && timeBlockIds.contains(shift.timeBlockId)) {
                    Decimal staffSetup = shift.staffSetup == null ? 0 : shift.staffSetup;
                    sameDateStaffRequestedByTimeBlockId.put(shift.timeBlockId, sameDateStaffRequestedByTimeBlockId.get(shift.timeBlockId) + staffSetup);
                }
            }
        }

        Decimal sameDateNceStaffRequested = 0;
        for (skedSameDayLinkedDriveCollapser.CollapsedActivity sameDateActivity : skedSameDayLinkedDriveCollapser.collapseSameDayLinkedActivities(ctx.sameDateActivities)) {
            Decimal staffQuantity = isFixedSite ? sameDateActivity.fixedSiteStaffQuantity : sameDateActivity.mobileStaffQuantity;
            staffQuantity = staffQuantity == null ? 0 : staffQuantity;
            if (sameDateActivity.timeBlockId != null && timeBlockIds.contains(sameDateActivity.timeBlockId)) {
                sameDateStaffRequestedByTimeBlockId.put(sameDateActivity.timeBlockId, sameDateStaffRequestedByTimeBlockId.get(sameDateActivity.timeBlockId) + staffQuantity);
            }
            sameDateNceStaffRequested += staffQuantity;
        }

        Decimal totalStaffConstraints = 0;
        for (sked_Staffing_Constraint__c constraint : ctx.staffingConstraints) {
            Decimal quantity = constraint.sked_Total_Staff_Constraints__c == null ? 0 : constraint.sked_Total_Staff_Constraints__c;
            if (constraint.sked_Time_Block__c == null) {
                totalStaffConstraints += quantity;
            } else if (timeBlockIds.contains(constraint.sked_Time_Block__c)) {
                staffingConstraintByTimeBlockId.put(constraint.sked_Time_Block__c, staffingConstraintByTimeBlockId.get(constraint.sked_Time_Block__c) + quantity);
            }
        }

        Boolean isStaffRequestedViolated = sameDateDrivesStaffRequested + sameDateNceStaffRequested + totalStaffRequested > totalStaffConstraints;

        Boolean isAnyTimeBlockStaffRequestedViolated = false;
        for (Id timeBlockId : timeBlockIds) {
            Decimal shiftStaffRequested = staffRequestedByTimeBlockId.get(timeBlockId);
            Decimal sameDateStaffRequested = sameDateStaffRequestedByTimeBlockId.get(timeBlockId);
            Decimal staffConstraint = staffingConstraintByTimeBlockId.get(timeBlockId);
            if (sameDateStaffRequested + (shiftStaffRequested == null ? 0 : shiftStaffRequested) > staffConstraint) {
                isAnyTimeBlockStaffRequestedViolated = true;
            }
        }

        result.violated = isStaffRequestedViolated || isAnyTimeBlockStaffRequestedViolated;
        result.passed = !result.violated || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_INSUFFICIENT_RESOURCES);
        return result;
    }

    /**
     * Ported from helper.js's validateCOChangeCrossRegions. Only relevant for a drive that's part
     * of a linked-drive pair whose Collection Operation actually changed this pass - skips the
     * region lookup entirely otherwise, since it's the only consumer of
     * sked_Territory_Collection_Operation__c and there's no reason to pay for that query when the
     * check can't violate anyway.
     */
    private static CheckResult checkCoChangedCrossRegions(skedDriveRegenContext ctx) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_CO_CHANGED_CROSS_REGIONS;

        sked_Drive__c backupDrive = ctx.snapshot.drive;
        if (ctx.drive.sked_Linked_Drives__c == null || backupDrive.sked_Collection_Operation__c == ctx.drive.sked_Collection_Operation__c) {
            return result;
        }

        String currentRegionId = findDriveRegionId(ctx.drive);
        result.violated = backupDrive.sked_ARC_Region_ID__c != currentRegionId;
        result.passed = !result.violated
            || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_CO_CHANGED_CROSS_REGIONS_REMOVE_FROM_LINKED_DRIVE);
        return result;
    }

    // Mirrors helper.js's getDriveTerritory - the date-effective Territory Collection Operation
    // matching the drive's (current, possibly just-changed) Collection Operation, whose parent
    // Territory carries the region. Queried live rather than through ctx: ctx.drive's Collection
    // Operation can itself be patched after skedDriveRegenContextLoader.load() already ran (see
    // this class's header), so a ctx-cached query would silently target the wrong CO.
    private static String findDriveRegionId(sked_Drive__c drive) {
        if (drive.sked_Collection_Operation__c == null || drive.sked_Drive_Date__c == null) {
            return null;
        }
        for (sked_Territory_Collection_Operation__c tco : [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c, sked_Territory__r.sked_Parent__c
            FROM sked_Territory_Collection_Operation__c
            WHERE sked_Collection_Operation__c = :drive.sked_Collection_Operation__c
        ]) {
            Boolean isDateRangeValid = (tco.sked_Start_Date__c == null || tco.sked_Start_Date__c <= drive.sked_Drive_Date__c)
                && (tco.sked_End_Date__c == null || drive.sked_Drive_Date__c <= tco.sked_End_Date__c);
            if (isDateRangeValid) {
                return tco.sked_Territory__r.sked_Parent__c;
            }
        }
        return null;
    }

    /**
     * Ported from helper.js's validateAssetsNotSharedWithNewCO. The complement of
     * checkCoChangedCrossRegions: relevant for the same linked-pair/CO-changed situation, but only
     * when the region STAYED THE SAME (a CO change that also crosses regions is handled by that
     * other check instead - the two are mutually exclusive by construction). Violates when a
     * currently-assigned vehicle/equipment resource (first shift only, matching
     * checkLackingVehicle/checkLackingEquipment's own assumption) is available for every reason
     * except CO membership against the new Collection Operation.
     *
     * isCurrentlyAssignedAssetNotSharedWithCollectionOperation issues up to ~10 SOQL per allocation
     * it's called on (not pre-batched) - a real per-allocation cost, left as-is here because this
     * loop's iteration count is inherently bounded to at most 2 (one vehicle + one equipment job,
     * first shift only), unlike skedLockedResourceChecker's equivalent locked-staff loop (headcount-
     * scaled, worth batching). Bulk-batching this would mean restructuring
     * skedAssetAvailabilityChecker's shared candidate/conflict-lookup methods, which
     * checkLackingVehicle/checkLackingEquipment also depend on - not worth that risk for a capped
     * ~10-16 SOQL saved here.
     */
    private static CheckResult checkAssetsNotSharedWithNewCo(skedDriveRegenContext ctx, List<sked_Drive_Shift__c> driveShifts) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_ASSETS_NOT_SHARED_WITH_NEW_CO;

        sked_Drive__c backupDrive = ctx.snapshot.drive;
        if (ctx.drive.sked_Linked_Drives__c == null || backupDrive.sked_Collection_Operation__c == ctx.drive.sked_Collection_Operation__c) {
            return result;
        }
        if (backupDrive.sked_ARC_Region_ID__c != findDriveRegionId(ctx.drive) || driveShifts.isEmpty()) {
            return result;
        }

        sked_Drive_Shift__c shift = driveShifts[0];
        List<sked__Job__c> jobs = ctx.jobsByShiftId.get(shift.Id);
        Boolean hasAssignedAssetNotSharedWithNewCo = false;
        for (sked__Job__c job : jobs == null ? new List<sked__Job__c>() : jobs) {
            if (job.sked_Asset_Type__c != skedConstants.ASSET_TYPE_VEHICLE && job.sked_Asset_Type__c != skedConstants.ASSET_TYPE_EQUIPMENT) {
                continue;
            }
            List<sked__Job_Allocation__c> allocations = ctx.allocationsByJobId.get(job.Id);
            for (sked__Job_Allocation__c allocation : allocations == null ? new List<sked__Job_Allocation__c>() : allocations) {
                if (allocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                    continue;
                }
                if (skedAssetAvailabilityChecker.isCurrentlyAssignedAssetNotSharedWithCollectionOperation(
                        job.sked_Asset_Type__c, ctx.drive.sked_Collection_Operation__c, ctx.drive.sked_Drive_Date__c, ctx.drive.sked_Drive_Site__c,
                        allocation.sked__Resource__c, ctx.drive.Id, shift.sked_Start__c, shift.sked_Finish__c, new Set<Id>())) {
                    hasAssignedAssetNotSharedWithNewCo = true;
                }
            }
        }

        result.violated = hasAssignedAssetNotSharedWithNewCo;
        result.passed = !result.violated || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_ASSETS_NOT_SHARED_WITH_NEW_CO);
        return result;
    }

    /**
     * Ported from helper.js's validateLockedResourceUnavailable - see
     * skedLockedResourceChecker's header for the full rule-by-rule mapping. Violates
     * when ANY currently-Locked staff allocation on the drive now fails at least one eligibility
     * rule against its own job.
     */
    private static CheckResult checkLockedResourceUnavailable(skedDriveRegenContext ctx) {
        CheckResult result = new CheckResult();
        result.contention = skedConstants.DRIVE_CONTENTION_LOCKED_RESOURCE_UNAVAILABLE;

        List<skedLockedResourceChecker.LockedAllocation> lockedStaffAllocations =
            skedLockedResourceChecker.collectLockedStaffAllocations(ctx);
        List<skedLockedResourceChecker.LockedAllocation> lockedAssetAllocations =
            skedLockedResourceChecker.collectLockedAssetAllocations(ctx);
        result.violated = skedLockedResourceChecker.hasUnavailableLockedResource(ctx, lockedStaffAllocations)
            || skedLockedResourceChecker.hasUnavailableLockedAsset(ctx, lockedAssetAllocations);
        result.passed = !result.violated || isContentionOverrided(ctx, skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LOCKED_RESOURCE_UNAVAILABLE);
        return result;
    }
}
