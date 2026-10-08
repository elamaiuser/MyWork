/**
 * Whether a drive's currently-Locked job allocations - staff (role) AND asset (Vehicle/Equipment) -
 * are still eligible, for LOCKED_RESOURCE_UNAVAILABLE. Ported from slwcAvailator.js's
 * buildScheduledAllocations, but only the narrow predicate that check actually needs: does ANY
 * currently-Locked allocation now fail at least one eligibility rule (helper.js's
 * validateLockedResourceUnavailable just tests exceptionLog.length > 0 - it never inspects which
 * code fired or the source's exceptionLog-reset ordering for inactive/pending-termination, so this
 * class doesn't replicate that ordering either; an independent OR of boolean predicates is
 * sufficient and faithful for this one check).
 *
 * Staff and asset allocations use entirely different rule sets, matching the source's own split
 * (staffPossibleAllocations vs. availableAssetsInfo.possibleAllocations, concatenated into one pool
 * before the uniform exceptionLog check): collectLockedStaffAllocations/findViolatedRules below
 * cover staff, via the 9 rules documented next; collectLockedAssetAllocations/
 * hasUnavailableLockedAsset (further below) cover Vehicle/Equipment, by reusing
 * skedAssetAvailabilityChecker's existing candidate-pool-membership check instead of a parallel
 * asset rule set - the same building block LACKING_VEHICLE/LACKING_EQUIPMENT/
 * ASSETS_NOT_SHARED_WITH_NEW_CO already use.
 *
 * Rules ported, each adapted from an existing Apex building block rather than reinvented:
 *  - CO membership: skedResourceUtils.getResourceBelongsToCollectionOp (override REPLACES rather
 *    than adds to primary/secondary match - deliberately NOT skedAssetAvailabilityChecker's
 *    candidate-query pattern, which uses different, additive override semantics for assets only).
 *  - Required tags: skedAssetAvailabilityChecker.hasAllRequiredTags/isTagRestricted, unchanged -
 *    sked__Resource_Tag__c/sked__ResourceTags__r is the same relationship for Person and Asset
 *    resources. Required tag ids come from the job's own sked__JobTags__r, not any role metadata.
 *  - Active/termination: adapted from the per-(job,resource) evaluation in slwcAvailator.js
 *    directly (skedResourceHandler's getInactiveUnavailability/etc. are a different, event-driven
 *    code path producing generic unavailability windows, not this per-allocation boolean).
 *  - Account/site decline: adapted from skedJobAllocationPostProcessBatch.captureBlacklistExceptionLog.
 *  - Travel time: adapted from captureTravelTimeExceptionLog - reuses the already-persisted
 *    sked_Geoservice_Travel_Time_To__c/Back__c fields (populated async by
 *    skedJobAllocationTravelTimeBatch) rather than a live distance calculation, per product decision.
 *  - Turnaround time: adapted from captureTurnaroundTimeExceptionLog - "any" non-overlapping
 *    neighbor allocation inside the turnaround window counts, not strictly the nearest one; for a
 *    realistic schedule this converges with the source's nearest-neighbor walk.
 *  - CDL/DOT max-shift: adapted from capture14hrsMoreExceptionLog, but reads the role off the JOB
 *    (sked_Resource_Role__c/sked_Dual_Role__c), matching slwcAvailator.js's
 *    isJobBelongToDrivingRolesGroup - NOT off the allocation, which is what the Apex batch method
 *    reads (a real divergence between the two existing Apex/JS implementations); also uses strict
 *    `>` against the max-duration threshold, matching the JS, not the batch's `>=`.
 *  - Weekly work days: adapted from skedResourceHoursRecordUtils's stored sked_Total_Working_Days__c
 *    rollup (already synced per-allocation by skedJobAllocationPostProcessBatch), rather than the
 *    live per-request recomputation slwcAvailator.js does for a not-yet-persisted candidate -
 *    appropriate here since every allocation this check evaluates is already persisted and Locked.
 *  - Plain time conflict: the JobAllocation/Availability/Activity overlap component of
 *    RESOURCE_TIME_CONFLICT reuses skedAssetAvailabilityChecker.findConflictedResourceIds directly
 *    (resource-type-agnostic, no Person/Asset distinction in its own logic) - a Locked resource
 *    that's since been double-booked elsewhere is exactly as ineligible here as an unlocked one.
 *  - Working-time calendar (Person only): the other half of RESOURCE_TIME_CONFLICT -
 *    slwcAvailator.js's dateslotModel merge (default the day to NON_WORKING, then punch in
 *    AVAILABILITY windows from recurring patterns + explicit availability + custom availability;
 *    conflict = any gap left over). Reformulated as an interval-coverage check - is
 *    [job.start, job.finish) a subset of the union of AVAILABILITY windows - which is equivalent
 *    and simpler to get right than replicating the JS's subtraction algorithm directly. Recurring
 *    patterns reuse skedAvailabilityPatternService.getPatternEvents unchanged (already a faithful
 *    port of getWeeklyPatternEvents/getCustomPatternEvents, just not previously wired into drive
 *    generation). Only the exceptionLog/isAvailable half of the source's output is needed here -
 *    isResourceQualified is a separate concern this check never consumes.
 *    KNOWN RISK: the JS applies dateUtils.correctPatternDateTimes to pattern-generated events for
 *    DST; skedDateTimeUtils has no confirmed equivalent (plain addMinutes) - unverified, could
 *    diverge right at a DST boundary.
 */
public with sharing class skedLockedResourceChecker {

    public class LockedAllocation {
        public sked__Job__c job;
        public sked__Job_Allocation__c allocation;
    }

    /**
     * Every currently-Locked (sked_Is_Locked__c - Locked OR Guarded, matching
     * validateLockedResourceUnavailable's own ja.isLocked||ja.locked check, not the looser
     * ja.locked-only filter getCurrentLockedStaff uses to build its data-fetch scope), active,
     * staff (sked_Resource_Role__c present) job allocation across every shift AND drive-level job.
     */
    public static List<LockedAllocation> collectLockedStaffAllocations(skedDriveRegenContext ctx) {
        List<LockedAllocation> lockedAllocations = new List<LockedAllocation>();
        List<sked__Job__c> allJobs = new List<sked__Job__c>(ctx.driveLevelJobs);
        for (List<sked__Job__c> shiftJobs : ctx.jobsByShiftId.values()) {
            allJobs.addAll(shiftJobs);
        }
        for (sked__Job__c job : allJobs) {
            if (job.sked_Resource_Role__c == null) {
                continue;
            }
            List<sked__Job_Allocation__c> allocations = ctx.allocationsByJobId.get(job.Id);
            for (sked__Job_Allocation__c allocation : allocations == null ? new List<sked__Job_Allocation__c>() : allocations) {
                // A resource-reassignment step (e.g. skedMobileAssetReassigner) can mark an
                // allocation Deleted in memory, on this same ctx instance, after load - a stale
                // Deleted-but-Locked allocation must not still trigger a spurious contention.
                if (allocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                    continue;
                }
                if (allocation.sked_Is_Locked__c == true) {
                    LockedAllocation locked = new LockedAllocation();
                    locked.job = job;
                    locked.allocation = allocation;
                    lockedAllocations.add(locked);
                }
            }
        }
        return lockedAllocations;
    }

    /**
     * Same collection as collectLockedStaffAllocations, above, but for asset (Vehicle/Equipment)
     * jobs instead of staff-role ones - helper.js's validateLockedResourceUnavailable checks every
     * locked job allocation uniformly, staff AND asset, against a single concatenated availability
     * pool (staff possible-allocations + asset possible-allocations). This class's own staff-only
     * scope (see header) was a real gap until this method + hasUnavailableLockedAsset, below.
     */
    public static List<LockedAllocation> collectLockedAssetAllocations(skedDriveRegenContext ctx) {
        List<LockedAllocation> lockedAllocations = new List<LockedAllocation>();
        List<sked__Job__c> allJobs = new List<sked__Job__c>(ctx.driveLevelJobs);
        for (List<sked__Job__c> shiftJobs : ctx.jobsByShiftId.values()) {
            allJobs.addAll(shiftJobs);
        }
        for (sked__Job__c job : allJobs) {
            if (job.sked_Asset_Type__c == null) {
                continue;
            }
            List<sked__Job_Allocation__c> allocations = ctx.allocationsByJobId.get(job.Id);
            for (sked__Job_Allocation__c allocation : allocations == null ? new List<sked__Job_Allocation__c>() : allocations) {
                if (allocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                    continue;
                }
                if (allocation.sked_Is_Locked__c == true) {
                    LockedAllocation locked = new LockedAllocation();
                    locked.job = job;
                    locked.allocation = allocation;
                    lockedAllocations.add(locked);
                }
            }
        }
        return lockedAllocations;
    }

    /**
     * Reuses skedAssetAvailabilityChecker's own "is this specific assigned resource still a member
     * of the full available-asset pool" check (CO membership, dedicated-to-site, tag match, time
     * conflict) - the same rules LACKING_VEHICLE/LACKING_EQUIPMENT and ASSETS_NOT_SHARED_WITH_NEW_CO
     * already use, rather than reinventing asset eligibility here.
     */
    public static Boolean hasUnavailableLockedAsset(skedDriveRegenContext ctx, List<LockedAllocation> lockedAssetAllocations) {
        for (LockedAllocation locked : lockedAssetAllocations) {
            if (locked.job.sked__Start__c == null || locked.job.sked__Finish__c == null) {
                continue;
            }
            Set<Id> requiredTagIds = new Set<Id>();
            for (sked__Job_Tag__c jobTag : locked.job.sked__JobTags__r) {
                requiredTagIds.add(jobTag.sked__Tag__c);
            }
            Boolean isStillAvailable = skedAssetAvailabilityChecker.isCurrentlyAssignedResourceStillAvailable(
                locked.job.sked_Asset_Type__c, ctx.drive.sked_Collection_Operation__c, ctx.drive.sked_Drive_Date__c,
                ctx.drive.sked_Drive_Site__c, locked.allocation.sked__Resource__c, ctx.drive.Id,
                locked.job.sked__Start__c, locked.job.sked__Finish__c, requiredTagIds);
            if (!isStillAvailable) {
                return true;
            }
        }
        return false;
    }

    /** True if ANY currently-Locked staff allocation would now fail at least one eligibility rule. */
    public static Boolean hasUnavailableLockedResource(skedDriveRegenContext ctx, List<LockedAllocation> lockedAllocations) {
        return !findViolatedRules(ctx, lockedAllocations).isEmpty();
    }

    // One entry per locked allocation that fails at least one rule, named for whichever rule fired
    // first - @TestVisible so tests can bisect exactly which rule misfires, rather than only
    // observing the collapsed boolean.
    @TestVisible
    private static List<String> findViolatedRules(skedDriveRegenContext ctx, List<LockedAllocation> lockedAllocations) {
        List<String> violatedRules = new List<String>();
        if (lockedAllocations.isEmpty()) {
            return violatedRules;
        }

        Set<Id> resourceIds = new Set<Id>();
        for (LockedAllocation locked : lockedAllocations) {
            resourceIds.add(locked.allocation.sked__Resource__c);
        }

        Id collectionOperationId = ctx.drive.sked_Collection_Operation__c;
        Id driveAccountId = ctx.drive.sked_Account__c;
        Id driveSiteId = ctx.drive.sked_Drive_Site__c;
        Date driveDate = ctx.drive.sked_Drive_Date__c;

        Map<Id, sked__Resource__c> resourceById = loadResources(resourceIds, driveAccountId, driveSiteId);
        Set<String> drivingRoles = skedResourceUtils.getResourceRolesByGroup().get(skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES);
        if (drivingRoles == null) {
            drivingRoles = new Set<String>();
        }
        Map<Id, Decimal> totalWorkingDaysByResourceId = loadTotalWorkingDaysByResourceId(resourceById, driveDate);
        Map<Id, List<sked__Job_Allocation__c>> neighborAllocationsByResourceId = loadNeighborAllocations(lockedAllocations, resourceById);
        String timezoneSidId = skedDriveContentionValidator.resolveTimezoneSidId(ctx);
        Map<Id, List<skedModels.event>> availabilityWindowsByResourceId = loadAvailabilityWindows(lockedAllocations, resourceById, timezoneSidId);
        Map<Id, List<TimeWindow>> conflictWindowsByResourceId = loadConflictWindowsByResourceId(lockedAllocations, ctx.drive.Id);

        for (LockedAllocation locked : lockedAllocations) {
            sked__Resource__c resource = resourceById.get(locked.allocation.sked__Resource__c);
            if (resource == null) {
                continue;
            }
            String violatedRule = findViolatedRule(locked, resource, collectionOperationId, driveAccountId, driveSiteId, driveDate,
                drivingRoles, totalWorkingDaysByResourceId.get(resource.Id), neighborAllocationsByResourceId.get(resource.Id),
                conflictWindowsByResourceId.get(resource.Id), availabilityWindowsByResourceId.get(resource.Id));
            if (violatedRule != null) {
                violatedRules.add(violatedRule);
            }
        }
        return violatedRules;
    }

    private static String findViolatedRule(LockedAllocation locked, sked__Resource__c resource, Id collectionOperationId,
            Id driveAccountId, Id driveSiteId, Date driveDate, Set<String> drivingRoles, Decimal totalWorkingDays,
            List<sked__Job_Allocation__c> neighborAllocations, List<TimeWindow> conflictWindows, List<skedModels.event> availabilityWindows) {
        if (isInactiveOrPendingTermination(resource, driveDate)) {
            return 'INACTIVE_OR_PENDING_TERMINATION';
        }
        if (isConflictedElsewhere(locked.job, conflictWindows)) {
            return 'CONFLICTED_ELSEWHERE';
        }
        if (isWorkingTimeConflict(locked.job, resource, availabilityWindows)) {
            return 'WORKING_TIME_CONFLICT';
        }
        if (!skedResourceUtils.getResourceBelongsToCollectionOp(resource, collectionOperationId, driveDate)) {
            return 'NOT_BELONG_TO_COLLECTION_OP';
        }
        Set<Id> requiredTagIds = new Set<Id>();
        for (sked__Job_Tag__c jobTag : locked.job.sked__JobTags__r) {
            requiredTagIds.add(jobTag.sked__Tag__c);
        }
        if (!skedAssetAvailabilityChecker.hasAllRequiredTags(resource, requiredTagIds, driveDate)) {
            return 'MISSING_REQUIRED_TAG';
        }
        if (isAccountBlacklisted(resource, driveAccountId)) {
            return 'ACCOUNT_BLACKLISTED';
        }
        if (isLocationBlacklisted(resource, driveSiteId)) {
            return 'LOCATION_BLACKLISTED';
        }
        if (isMaxTravelTimeViolated(locked.allocation, resource)) {
            return 'MAX_TRAVEL_TIME_VIOLATED';
        }
        if (isCdlDotViolated(locked.job, drivingRoles)) {
            return 'CDL_DOT_VIOLATED';
        }
        if (isMaxWeeklyWorkDaysViolated(resource, totalWorkingDays)) {
            return 'MAX_WEEKLY_WORK_DAYS_VIOLATED';
        }
        if (isTurnaroundViolated(locked.job, resource, neighborAllocations)) {
            return 'TURNAROUND_VIOLATED';
        }
        return null;
    }

    // Mirrors slwcAvailator.js's inactive/leave/termination branch for a Person resource (the
    // Asset branch is a different rule, already covered by skedAssetAvailabilityChecker's
    // candidate-query WHERE clause for the already-ported checks).
    private static Boolean isInactiveOrPendingTermination(sked__Resource__c resource, Date driveDate) {
        if (driveDate == null) {
            return false;
        }
        Date terminationDate = skedUtils.getMinFromDates(
            new List<Date>{ resource.sked_Planned_Termination_Date__c, resource.sked_Termination_Date__c });
        if (terminationDate != null && terminationDate <= driveDate) {
            return true;
        }
        if (resource.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE) {
            return !(resource.sked_Anticipated_Leave_Return_Date__c != null && resource.sked_Anticipated_Leave_Return_Date__c <= driveDate);
        }
        return resource.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE;
    }

    // Same overlap rule as the asset-side checks (LACKING_VEHICLE/LACKING_EQUIPMENT) - a Locked
    // resource double-booked elsewhere since this allocation was locked is no less ineligible.
    // conflictWindows is pre-batched by loadConflictWindowsByResourceId, below - not a live query
    // here, unlike skedAssetAvailabilityChecker.findConflictedResourceIds's own per-call queries.
    private static Boolean isConflictedElsewhere(sked__Job__c job, List<TimeWindow> conflictWindows) {
        if (job.sked__Start__c == null || job.sked__Finish__c == null || conflictWindows == null) {
            return false;
        }
        for (TimeWindow window : conflictWindows) {
            if (window.windowStart < job.sked__Finish__c && window.windowEnd > job.sked__Start__c) {
                return true;
            }
        }
        return false;
    }

    private class TimeWindow {
        private DateTime windowStart;
        private DateTime windowEnd;
    }

    // Bulk equivalent of skedAssetAvailabilityChecker.findConflictedResourceIds, called once across
    // every locked allocation's own job window (mirrors loadNeighborAllocations/loadAvailabilityWindows
    // above) instead of 3 SOQL per locked allocation. Same 3 conflict sources (job allocation,
    // availability, activity), widened to a shared min/max window then filtered per-job in Apex by
    // isConflictedElsewhere, since different locked allocations can have different job windows.
    private static Map<Id, List<TimeWindow>> loadConflictWindowsByResourceId(List<LockedAllocation> lockedAllocations, Id excludeDriveId) {
        Map<Id, List<TimeWindow>> windowsByResourceId = new Map<Id, List<TimeWindow>>();
        Set<Id> resourceIds = new Set<Id>();
        DateTime minTime;
        DateTime maxTime;
        for (LockedAllocation locked : lockedAllocations) {
            if (locked.job.sked__Start__c == null || locked.job.sked__Finish__c == null) {
                continue;
            }
            resourceIds.add(locked.allocation.sked__Resource__c);
            minTime = minTime == null || locked.job.sked__Start__c < minTime ? locked.job.sked__Start__c : minTime;
            maxTime = maxTime == null || locked.job.sked__Finish__c > maxTime ? locked.job.sked__Finish__c : maxTime;
        }
        if (resourceIds.isEmpty()) {
            return windowsByResourceId;
        }

        for (sked__Job_Allocation__c allocation : [
            SELECT sked__Resource__c, sked__Start__c, sked__Set_End__c
            FROM sked__Job_Allocation__c
            WHERE sked__Resource__c IN :resourceIds
            AND sked__Status__c NOT IN :skedConstants.JOB_ALLOCATION_DELETED_STATUSES
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked__Job__r.sked_Drive__c != :excludeDriveId
            AND sked__Start__c < :maxTime
            AND sked__Set_End__c > :minTime
        ]) {
            addConflictWindow(windowsByResourceId, allocation.sked__Resource__c, allocation.sked__Start__c, allocation.sked__Set_End__c);
        }
        for (sked__Availability__c unavailability : [
            SELECT sked__Resource__c, sked__Start__c, sked__Finish__c
            FROM sked__Availability__c
            WHERE sked__Resource__c IN :resourceIds
            AND sked__Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
            AND sked__Is_Available__c = false
            AND sked__Start__c < :maxTime
            AND sked__Finish__c > :minTime
        ]) {
            addConflictWindow(windowsByResourceId, unavailability.sked__Resource__c, unavailability.sked__Start__c, unavailability.sked__Finish__c);
        }
        for (sked__Activity__c activity : [
            SELECT sked__Resource__c, sked__Start__c, sked__End__c
            FROM sked__Activity__c
            WHERE sked__Resource__c IN :resourceIds
            AND sked__Type__c NOT IN :skedAssetAvailabilityChecker.EXCLUDED_ACTIVITY_TYPES
            AND sked__Start__c < :maxTime
            AND sked__End__c > :minTime
        ]) {
            addConflictWindow(windowsByResourceId, activity.sked__Resource__c, activity.sked__Start__c, activity.sked__End__c);
        }
        return windowsByResourceId;
    }

    private static void addConflictWindow(Map<Id, List<TimeWindow>> windowsByResourceId, Id resourceId, DateTime windowStart, DateTime windowEnd) {
        if (!windowsByResourceId.containsKey(resourceId)) {
            windowsByResourceId.put(resourceId, new List<TimeWindow>());
        }
        TimeWindow window = new TimeWindow();
        window.windowStart = windowStart;
        window.windowEnd = windowEnd;
        windowsByResourceId.get(resourceId).add(window);
    }

    // Person-only (mirrors slwcAvailator.js's asset-skip) - is any part of the job's window
    // outside the union of the resource's AVAILABILITY windows (pattern + explicit + custom)?
    private static Boolean isWorkingTimeConflict(sked__Job__c job, sked__Resource__c resource, List<skedModels.event> availabilityWindows) {
        if (resource.sked__Resource_Type__c != skedConstants.RESOURCE_TYPE_PERSON
                || job.sked__Start__c == null || job.sked__Finish__c == null) {
            return false;
        }
        return !isFullyCoveredByAvailability(job.sked__Start__c, job.sked__Finish__c,
            availabilityWindows == null ? new List<skedModels.event>() : availabilityWindows);
    }

    // Interval-coverage reformulation of slwcAvailator.js's dateslotModel.addEvent/_addAvailableBlock
    // per-day NON_WORKING-default-then-punch-AVAILABILITY-windows merge (see class header) - sorts
    // the windows overlapping the range and sweeps a "covered up to" pointer, same as a classic
    // interval-merge; any gap before rangeFinish is reached means the range isn't fully covered.
    private static Boolean isFullyCoveredByAvailability(DateTime rangeStart, DateTime rangeFinish, List<skedModels.event> availabilityWindows) {
        List<skedModels.event> overlapping = new List<skedModels.event>();
        for (skedModels.event window : availabilityWindows) {
            if (window.start < rangeFinish && window.finish > rangeStart) {
                overlapping.add(window);
            }
        }
        overlapping.sort();

        DateTime coveredUpTo = rangeStart;
        for (skedModels.event window : overlapping) {
            if (window.start > coveredUpTo) {
                return false;
            }
            if (window.finish > coveredUpTo) {
                coveredUpTo = window.finish;
            }
            if (coveredUpTo >= rangeFinish) {
                return true;
            }
        }
        return coveredUpTo >= rangeFinish;
    }

    private static Boolean isAccountBlacklisted(sked__Resource__c resource, Id driveAccountId) {
        if (driveAccountId == null) {
            return false;
        }
        for (sked__Account_Resource_Score__c score : resource.sked__Account_Resource_Scores__r) {
            if (score.sked__Account__c == driveAccountId) {
                return true;
            }
        }
        return false;
    }

    private static Boolean isLocationBlacklisted(sked__Resource__c resource, Id driveSiteId) {
        if (driveSiteId == null) {
            return false;
        }
        for (sked__Location_Resource_Score__c score : resource.sked__Location_Resource_Scores__r) {
            if (score.sked__Location__c == driveSiteId) {
                return true;
            }
        }
        return false;
    }

    private static Boolean isMaxTravelTimeViolated(sked__Job_Allocation__c allocation, sked__Resource__c resource) {
        if (resource.sked_Max_Travel_Time__c == null
                || allocation.sked_Geoservice_Travel_Time_To__c == null
                || allocation.sked_Geoservice_Travel_Time_Back__c == null) {
            return false;
        }
        return resource.sked_Max_Travel_Time__c < allocation.sked_Geoservice_Travel_Time_To__c
            || resource.sked_Max_Travel_Time__c < allocation.sked_Geoservice_Travel_Time_Back__c;
    }

    // Reads the role off the JOB, matching slwcAvailator.js's isJobBelongToDrivingRolesGroup -
    // NOT off the allocation, which is what skedJobAllocationPostProcessBatch reads (a real
    // divergence between the batch and the source this check is ported from). Strict `>`,
    // matching the JS - exactly-at-the-threshold does not violate.
    private static Boolean isCdlDotViolated(sked__Job__c job, Set<String> drivingRoles) {
        if (job.sked__Duration__c == null) {
            return false;
        }
        Boolean isDrivingRole = drivingRoles.contains(job.sked_Resource_Role__c) || drivingRoles.contains(job.sked_Dual_Role__c);
        Decimal maxCdlDotDurationInMinutes = skedSetting.instance.Admin.maxCDLDOTDuration * 60;
        return isDrivingRole && job.sked__Duration__c > maxCdlDotDurationInMinutes;
    }

    // sked_Max_Working_Days_Per_Week__c is a Picklist (String), matching
    // skedResourceHoursRecordUtils's own Integer.valueOf conversion for the same field.
    private static Boolean isMaxWeeklyWorkDaysViolated(sked__Resource__c resource, Decimal totalWorkingDays) {
        if (totalWorkingDays == null || String.isBlank(resource.sked_Max_Working_Days_Per_Week__c)) {
            return false;
        }
        return totalWorkingDays > Integer.valueOf(resource.sked_Max_Working_Days_Per_Week__c);
    }

    // "Any" non-overlapping neighbor inside the turnaround window, not strictly the nearest one
    // (see class header) - converges with the source for a realistic (non-overlapping) schedule.
    private static Boolean isTurnaroundViolated(sked__Job__c job, sked__Resource__c resource, List<sked__Job_Allocation__c> neighbors) {
        if (resource.sked_Turnaround_Time__c == null || resource.sked_Turnaround_Time__c == 0
                || job.sked__Start__c == null || job.sked__Finish__c == null || neighbors == null) {
            return false;
        }
        Integer turnaroundHours = Integer.valueOf(resource.sked_Turnaround_Time__c);
        DateTime allowedLatestJobFinishBefore = job.sked__Start__c.addHours(-turnaroundHours);
        DateTime allowedSoonestJobStartAfter = job.sked__Finish__c.addHours(turnaroundHours);
        for (sked__Job_Allocation__c neighbor : neighbors) {
            Boolean isOverlapping = neighbor.sked__Start__c < job.sked__Finish__c && neighbor.sked__Set_End__c > job.sked__Start__c;
            if (isOverlapping) {
                continue;
            }
            if (neighbor.sked__Start__c < allowedSoonestJobStartAfter && neighbor.sked__Set_End__c > allowedLatestJobFinishBefore) {
                return true;
            }
        }
        return false;
    }

    // Mirrors skedJobAllocationPostProcessBatch.initializeMasterModel's resource SOQL, scoped to
    // just the currently-Locked resourceIds rather than every resource on the drive.
    private static Map<Id, sked__Resource__c> loadResources(Set<Id> resourceIds, Id driveAccountId, Id driveSiteId) {
        return new Map<Id, sked__Resource__c>([
            SELECT Id, sked__Resource_Type__c, sked_Turnaround_Time__c, sked_Max_Travel_Time__c, sked_Employment_Status__c,
                sked_Termination_Date__c, sked_Planned_Termination_Date__c, sked_Anticipated_Leave_Return_Date__c,
                sked_Max_Working_Days_Per_Week__c,
                sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c,
                (SELECT Id, sked__Tag__c, sked_Start_Date__c, sked_Restriction_Start_Date__c, sked_Restriction_End_Date__c
                 FROM sked__ResourceTags__r
                 WHERE (sked_Role_Status__c = NULL OR sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE)),
                (SELECT Id, sked__Account__c FROM sked__Account_Resource_Scores__r
                 WHERE sked__Account__c = :driveAccountId AND sked__Blacklisted__c = TRUE),
                (SELECT Id, sked__Location__c FROM sked__Location_Resource_Scores__r
                 WHERE sked__Location__c = :driveSiteId AND sked__Blacklisted__c = TRUE),
                (SELECT Id, sked_Biomed_Collection_Op_Center__c, sked_Start_Date__c, sked_End_Date__c
                 FROM sked_Resource_Biomed_Collection_Ops__r),
                (SELECT Id, sked_Collection_Operation__c, sked_Start_Date__c, sked_End_Date__c
                 FROM sked__Resource_Overrides__r)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
    }

    // Reuses the already-synced sked_Total_Working_Days__c rollup (skedJobAllocationPostProcessBatch
    // keeps this current per allocation) rather than recomputing live - see class header.
    private static Map<Id, Decimal> loadTotalWorkingDaysByResourceId(Map<Id, sked__Resource__c> resourceById, Date driveDate) {
        Map<Id, Decimal> totalWorkingDaysByResourceId = new Map<Id, Decimal>();
        if (driveDate == null) {
            return totalWorkingDaysByResourceId;
        }
        Map<String, Id> resourceIdByUniqueKey = new Map<String, Id>();
        for (sked__Resource__c resource : resourceById.values()) {
            String workWeekday = String.isBlank(resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c)
                ? 'Sunday' : resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            Date startOfWeek = skedDateTimeUtils.findWeekStartDate(driveDate, workWeekday);
            Date endOfWeek = startOfWeek.addDays(6);
            resourceIdByUniqueKey.put(skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(resource.Id, startOfWeek, endOfWeek), resource.Id);
        }
        for (sked_Resource_Hours_Record__c record : [
            SELECT sked_Unique_Key__c, sked_Total_Working_Days__c
            FROM sked_Resource_Hours_Record__c
            WHERE sked_Unique_Key__c IN :resourceIdByUniqueKey.keySet()
        ]) {
            Id resourceId = resourceIdByUniqueKey.get(record.sked_Unique_Key__c);
            if (resourceId != null) {
                totalWorkingDaysByResourceId.put(resourceId, record.sked_Total_Working_Days__c);
            }
        }
        return totalWorkingDaysByResourceId;
    }

    // One bulk query covering every locked allocation's turnaround window, rather than one query
    // per resource - mirrors captureTurnaroundTimeExceptionLog's own min/max-time batching.
    private static Map<Id, List<sked__Job_Allocation__c>> loadNeighborAllocations(List<LockedAllocation> lockedAllocations, Map<Id, sked__Resource__c> resourceById) {
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> excludeAllocationIds = new Set<Id>();
        DateTime minTime;
        DateTime maxTime;
        for (LockedAllocation locked : lockedAllocations) {
            sked__Resource__c resource = resourceById.get(locked.allocation.sked__Resource__c);
            if (resource == null || locked.job.sked__Start__c == null || locked.job.sked__Finish__c == null) {
                continue;
            }
            Integer turnaroundHours = resource.sked_Turnaround_Time__c == null ? 0 : Integer.valueOf(resource.sked_Turnaround_Time__c);
            DateTime windowStart = locked.job.sked__Start__c.addHours(-turnaroundHours);
            DateTime windowEnd = locked.job.sked__Finish__c.addHours(turnaroundHours);
            minTime = minTime == null || windowStart < minTime ? windowStart : minTime;
            maxTime = maxTime == null || windowEnd > maxTime ? windowEnd : maxTime;
            resourceIds.add(locked.allocation.sked__Resource__c);
            excludeAllocationIds.add(locked.allocation.Id);
        }

        Map<Id, List<sked__Job_Allocation__c>> neighborsByResourceId = new Map<Id, List<sked__Job_Allocation__c>>();
        if (resourceIds.isEmpty() || minTime == null) {
            return neighborsByResourceId;
        }
        for (sked__Job_Allocation__c allocation : [
            SELECT Id, sked__Resource__c, sked__Start__c, sked__Set_End__c
            FROM sked__Job_Allocation__c
            WHERE sked__Resource__c IN :resourceIds
            AND Id NOT IN :excludeAllocationIds
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            AND sked__Start__c < :maxTime
            AND sked__Set_End__c > :minTime
        ]) {
            if (!neighborsByResourceId.containsKey(allocation.sked__Resource__c)) {
                neighborsByResourceId.put(allocation.sked__Resource__c, new List<sked__Job_Allocation__c>());
            }
            neighborsByResourceId.get(allocation.sked__Resource__c).add(allocation);
        }
        return neighborsByResourceId;
    }

    // Bulk-builds each Person resource's AVAILABILITY windows (recurring pattern + explicit
    // sked__Availability__c + sked_Custom_Availability__c) spanning every locked allocation's job -
    // mirrors slwcAvailator.js's populateWorkingEvents/loadWorkingTime sources. sked__Availability__c
    // is gated Approved + Is_Available__c = true (skedAssetAvailabilityChecker's own gating).
    // sked_Custom_Availability__c is gated Approved only, NOT Is_Available__c - confirmed faithful
    // to the real source, not assumed: skedRacController.cls's customAvailabilityStatuses param
    // gates the upstream feeder query the same way (Approved only), and slwcAvailator.js's
    // populateWorkingEvents unconditionally treats every fetched custom-availability record as an
    // AVAILABILITY window regardless of isAvailable - the whole pipeline treats this object as an
    // always-additive grant, unlike sked__Availability__c.
    private static Map<Id, List<skedModels.event>> loadAvailabilityWindows(List<LockedAllocation> lockedAllocations,
            Map<Id, sked__Resource__c> resourceById, String timezoneSidId) {
        Map<Id, List<skedModels.event>> windowsByResourceId = new Map<Id, List<skedModels.event>>();
        Set<Id> personResourceIds = new Set<Id>();
        Set<Date> dates = new Set<Date>();
        DateTime minTime;
        DateTime maxTime;
        for (LockedAllocation locked : lockedAllocations) {
            sked__Resource__c resource = resourceById.get(locked.allocation.sked__Resource__c);
            if (resource == null || resource.sked__Resource_Type__c != skedConstants.RESOURCE_TYPE_PERSON
                    || locked.job.sked__Start__c == null || locked.job.sked__Finish__c == null) {
                continue;
            }
            personResourceIds.add(resource.Id);
            windowsByResourceId.put(resource.Id, new List<skedModels.event>());
            minTime = minTime == null || locked.job.sked__Start__c < minTime ? locked.job.sked__Start__c : minTime;
            maxTime = maxTime == null || locked.job.sked__Finish__c > maxTime ? locked.job.sked__Finish__c : maxTime;
            Date lastDate = skedDateTimeUtils.getDate(locked.job.sked__Finish__c, timezoneSidId);
            for (Date day = skedDateTimeUtils.getDate(locked.job.sked__Start__c, timezoneSidId); day <= lastDate; day = day.addDays(1)) {
                dates.add(day);
            }
        }
        if (personResourceIds.isEmpty()) {
            return windowsByResourceId;
        }

        skedAvailabilityPatternService patternService = new skedAvailabilityPatternService();
        patternService.setTimezoneSidId(timezoneSidId);
        Map<Id, List<skedModels.event>> patternEventsByResourceId = patternService.getPatternEvents(personResourceIds, dates);
        for (Id resourceId : patternEventsByResourceId.keySet()) {
            if (windowsByResourceId.containsKey(resourceId)) {
                windowsByResourceId.get(resourceId).addAll(patternEventsByResourceId.get(resourceId));
            }
        }

        for (sked__Availability__c availability : [
            SELECT sked__Resource__c, sked__Start__c, sked__Finish__c
            FROM sked__Availability__c
            WHERE sked__Resource__c IN :personResourceIds
            AND sked__Status__c IN :skedConstants.AVAILABILITY_APPROVED_STATUSES
            AND sked__Is_Available__c = true
            AND sked__Start__c < :maxTime
            AND sked__Finish__c > :minTime
        ]) {
            addAvailabilityWindow(windowsByResourceId, availability.sked__Resource__c, availability.sked__Start__c, availability.sked__Finish__c);
        }

        for (sked_Custom_Availability__c customAvailability : [
            SELECT sked_Resource__c, sked_Start__c, sked_Finish__c
            FROM sked_Custom_Availability__c
            WHERE sked_Resource__c IN :personResourceIds
            AND sked_Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
            AND sked_Start__c < :maxTime
            AND sked_Finish__c > :minTime
        ]) {
            addAvailabilityWindow(windowsByResourceId, customAvailability.sked_Resource__c, customAvailability.sked_Start__c, customAvailability.sked_Finish__c);
        }

        return windowsByResourceId;
    }

    private static void addAvailabilityWindow(Map<Id, List<skedModels.event>> windowsByResourceId, Id resourceId, DateTime start, DateTime finish) {
        if (!windowsByResourceId.containsKey(resourceId) || start == null || finish == null) {
            return;
        }
        skedModels.event window = new skedModels.event();
        window.start = start;
        window.finish = finish;
        windowsByResourceId.get(resourceId).add(window);
    }
}
