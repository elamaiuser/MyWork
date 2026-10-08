/**
 * Whether a drive's currently-assigned Vehicle/Equipment resources are still valid (validate-only;
 * see skedMobileAssetReassigner for the replacement-picking half). findConflictedResourceIds is
 * called from skedDriveContentionValidator's LACKING_VEHICLE/LACKING_EQUIPMENT checks to discount an
 * assigned resource that's since become unavailable. loadAvailableAssets is the pool
 * skedMobileAssetReassigner picks replacements from AND validates current assignments against
 * (inlined there as a membership check against this same pool, not a separate call) -
 * isCurrentlyAssignedResourceStillAvailable below is that identical membership check exposed as its
 * own method, for callers that want it directly: an existing assignment is "valid" iff its resource
 * Id is a member of the exact same available-asset pool used to pick new candidates, not a narrower
 * check.
 *
 * Deliberately scoped to only the checks that are semantically meaningful for an asset (not a
 * person): CO membership (primary CO + secondary CO junction + relocated-in override - same scoping
 * already used by skedMobileDriveShiftCalculator.loadVehicles), dedicated-to-site (a HARD exclusion -
 * a resource with dedicatedToSiteId set and not equal to the drive's site is excluded from candidacy
 * entirely, not merely deprioritized), time conflict (job allocation on a DIFFERENT drive, an explicit
 * unavailability window, or a conflicting activity, all overlapping the shift window), tag match
 * including restriction windows (a tag inside its own restriction window does not count toward
 * satisfying a required tag).
 *
 * Deliberately not handled (people-only / driver concepts that don't apply to an asset resource
 * itself): max travel time / turnaround time violations (both matter for picking the *best* resource,
 * not for "is the currently-assigned one still valid"), CDL/DOT max-shift-duration (a driver-role
 * constraint, already partially covered by the tag requirement instead), account/site decline
 * blacklisting (a people-preference concept), and max weekly work days (a labor-law concept). Also
 * not handled: the temporary-CO override bypass of the dedicated-site rule, and custom-availability /
 * group-activity conflicts - both real, documented gaps, not oversights.
 */
public with sharing class skedAssetAvailabilityChecker {

    // People and Asset resources share the same sked__Activity__c object - these two activity
    // types never count as a conflict. Public - skedLockedResourceChecker's own bulk conflict-window
    // query reuses this same exclusion list rather than duplicating it.
    public static final List<String> EXCLUDED_ACTIVITY_TYPES = new List<String>{
        skedConstants.ACTIVITY_TYPE_ON_CALL, skedConstants.ACTIVITY_TYPE_AFTER_HOURS_CALL_OUT_MANAGEMENT
    };

    /**
     * Every currently-CO-eligible resource of assetType, not hard-excluded by dedicated-to-site,
     * still passing tag match (including restriction windows), and with no time conflict (job
     * allocation / unavailability / activity) against [windowStart, windowEnd) on a drive other
     * than excludeDriveId.
     */
    public static List<sked__Resource__c> loadAvailableAssets(String assetType, Id collectionOperationId, Date driveDate,
            Id driveSiteId, Id excludeDriveId, DateTime windowStart, DateTime windowEnd, Set<Id> requiredTagIds) {
        List<sked__Resource__c> candidates = loadCandidateAssets(assetType, collectionOperationId, driveSiteId, driveDate);

        List<sked__Resource__c> tagEligible = new List<sked__Resource__c>();
        for (sked__Resource__c candidate : candidates) {
            if (hasAllRequiredTags(candidate, requiredTagIds, driveDate)) {
                tagEligible.add(candidate);
            }
        }
        if (tagEligible.isEmpty()) {
            return tagEligible;
        }

        Set<Id> conflictedResourceIds = findConflictedResourceIds(
            new Map<Id, sked__Resource__c>(tagEligible).keySet(), excludeDriveId, windowStart, windowEnd);

        List<sked__Resource__c> available = new List<sked__Resource__c>();
        for (sked__Resource__c candidate : tagEligible) {
            if (!conflictedResourceIds.contains(candidate.Id)) {
                available.add(candidate);
            }
        }
        return available;
    }

    /**
     * Whether a specific, already-assigned resource is still a member of the full available-asset
     * pool - the SAME pool loadAvailableAssets hands back for picking a brand-new candidate, rather
     * than a narrower time-conflict-only test. A currently-assigned resource that's since become
     * dedicated to a different site, tag-restricted, or CO-ineligible is just as invalid as a
     * brand-new candidate would be.
     */
    public static Boolean isCurrentlyAssignedResourceStillAvailable(String assetType, Id collectionOperationId, Date driveDate,
            Id driveSiteId, Id resourceId, Id excludeDriveId, DateTime windowStart, DateTime windowEnd, Set<Id> requiredTagIds) {
        for (sked__Resource__c resource : loadAvailableAssets(
                assetType, collectionOperationId, driveDate, driveSiteId, excludeDriveId, windowStart, windowEnd, requiredTagIds)) {
            if (resource.Id == resourceId) {
                return true;
            }
        }
        return false;
    }

    /**
     * Whether a currently-assigned resource has become unavailable for EXACTLY ONE reason: it no
     * longer belongs to collectionOperationId's resource pool, while dedicated-to-site, tag match,
     * and time conflict all still pass. Mirrors slwcAvailator.js's
     * exceptionLog.length === 1 && exceptionCode === 'RESOURCE_NOT_AVAILABLE_FOR_CO' predicate - a
     * resource failing CO membership AND some other rule at the same time does not count, since
     * that's a different (and un-ported) contention reason, not this one.
     */
    public static Boolean isCurrentlyAssignedAssetNotSharedWithCollectionOperation(String assetType, Id collectionOperationId, Date driveDate,
            Id driveSiteId, Id resourceId, Id excludeDriveId, DateTime windowStart, DateTime windowEnd, Set<Id> requiredTagIds) {
        if (isCurrentlyAssignedResourceStillAvailable(
                assetType, collectionOperationId, driveDate, driveSiteId, resourceId, excludeDriveId, windowStart, windowEnd, requiredTagIds)) {
            return false;
        }
        for (sked__Resource__c candidate : loadCandidateAssetsAnyCollectionOperation(assetType, driveSiteId, driveDate)) {
            if (candidate.Id != resourceId) {
                continue;
            }
            if (!hasAllRequiredTags(candidate, requiredTagIds, driveDate)) {
                return false;
            }
            return findConflictedResourceIds(new Set<Id>{ resourceId }, excludeDriveId, windowStart, windowEnd).isEmpty();
        }
        return false;
    }

    /**
     * Any of the following overlapping [windowStart, windowEnd) counts as a conflict:
     *  - another allocation of this resource on a different drive (excludeDriveId itself is not a
     *    conflict - that's what this regen is replacing/keeping). Deleted and Declined statuses are
     *    excluded, as is an allocation on a Cancelled job, matching this repo's SOQL rule.
     *  - an explicit sked__Availability__c unavailability window (Approved status,
     *    sked__Is_Available__c = false).
     *  - a conflicting sked__Activity__c, excluding On Call / After Hours Call Out Management.
     * Public: also called by skedDriveContentionValidator to discount a currently-assigned
     * vehicle/equipment resource that's since become unavailable (e.g. the drive date moved).
     */
    public static Set<Id> findConflictedResourceIds(Set<Id> resourceIds, Id excludeDriveId, DateTime windowStart, DateTime windowEnd) {
        if (resourceIds.isEmpty() || windowStart == null || windowEnd == null) {
            return new Set<Id>();
        }
        Set<Id> conflicted = new Set<Id>();
        for (sked__Job_Allocation__c allocation : [
            SELECT sked__Resource__c
            FROM sked__Job_Allocation__c
            WHERE sked__Resource__c IN :resourceIds
            AND sked__Status__c NOT IN :skedConstants.JOB_ALLOCATION_DELETED_STATUSES
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked__Job__r.sked_Drive__c != :excludeDriveId
            AND sked__Start__c < :windowEnd
            AND sked__Set_End__c > :windowStart
        ]) {
            conflicted.add(allocation.sked__Resource__c);
        }
        for (sked__Availability__c unavailability : [
            SELECT sked__Resource__c
            FROM sked__Availability__c
            WHERE sked__Resource__c IN :resourceIds
            AND sked__Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
            AND sked__Is_Available__c = false
            AND sked__Start__c < :windowEnd
            AND sked__Finish__c > :windowStart
        ]) {
            conflicted.add(unavailability.sked__Resource__c);
        }
        for (sked__Activity__c activity : [
            SELECT sked__Resource__c
            FROM sked__Activity__c
            WHERE sked__Resource__c IN :resourceIds
            AND sked__Type__c NOT IN :EXCLUDED_ACTIVITY_TYPES
            AND sked__Start__c < :windowEnd
            AND sked__End__c > :windowStart
        ]) {
            conflicted.add(activity.sked__Resource__c);
        }
        return conflicted;
    }

    // Same CO scoping as skedMobileDriveShiftCalculator.loadVehicles, generalized to any asset type
    // (Vehicle or Equipment). Dedicated-to-site is a HARD exclusion in the WHERE clause, not a
    // post-filter/sort preference.
    private static List<sked__Resource__c> loadCandidateAssets(String assetType, Id collectionOperationId, Id driveSiteId, Date driveDate) {
        Set<Id> additionalResourceIds = new Set<Id>();
        for (sked__Resource_Override__c ro : [
            SELECT Id, sked__Resource__c
            FROM sked__Resource_Override__c
            WHERE sked_Collection_Operation__c = :collectionOperationId
                AND sked_Start_Date__c <= :driveDate AND sked_End_Date__c >= :driveDate
        ]) {
            additionalResourceIds.add(ro.sked__Resource__c);
        }
        for (sked_Resource_Biomed_Collection_Op__c rco : [
            SELECT Id, sked_Resource__c
            FROM sked_Resource_Biomed_Collection_Op__c
            WHERE sked_Biomed_Collection_Op_Center__c = :collectionOperationId
                AND (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :driveDate)
                AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :driveDate)
        ]) {
            additionalResourceIds.add(rco.sked_Resource__c);
        }

        return [
            SELECT Id, Name, sked_Asset_Type__c, sked_Pres_Donor_Capacity__c, sked_CDL__c, sked_DOT__c, sked_Dedicated_to_Site__c,
                sked_Equipment_Subtype__c,
                (SELECT Id, sked__Tag__c, sked_Start_Date__c, sked_Restriction_Start_Date__c, sked_Restriction_End_Date__c
                 FROM sked__ResourceTags__r WHERE sked_Start_Date__c <= :driveDate)
            FROM sked__Resource__c
            WHERE sked_Asset_Type__c = :assetType
                AND sked__Is_Active__c = TRUE
                AND (sked_Effective_Date__c = NULL OR sked_Effective_Date__c <= :driveDate)
                AND (sked_Future_Inactive_Date__c = NULL OR sked_Future_Inactive_Date__c > :driveDate)
                AND (sked_Dedicated_to_Site__c = NULL OR sked_Dedicated_to_Site__c = :driveSiteId)
                AND (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c = :collectionOperationId
                     OR Id IN :additionalResourceIds)
        ];
    }

    // Same as loadCandidateAssets, minus the CO/override membership condition - lets
    // isCurrentlyAssignedAssetNotSharedWithCollectionOperation isolate CO as the sole reason a
    // resource fails, by re-checking every OTHER rule with CO membership removed from the WHERE clause.
    private static List<sked__Resource__c> loadCandidateAssetsAnyCollectionOperation(String assetType, Id driveSiteId, Date driveDate) {
        return [
            SELECT Id, Name, sked_Asset_Type__c, sked_Pres_Donor_Capacity__c, sked_CDL__c, sked_DOT__c, sked_Dedicated_to_Site__c,
                sked_Equipment_Subtype__c,
                (SELECT Id, sked__Tag__c, sked_Start_Date__c, sked_Restriction_Start_Date__c, sked_Restriction_End_Date__c
                 FROM sked__ResourceTags__r WHERE sked_Start_Date__c <= :driveDate)
            FROM sked__Resource__c
            WHERE sked_Asset_Type__c = :assetType
                AND sked__Is_Active__c = TRUE
                AND (sked_Effective_Date__c = NULL OR sked_Effective_Date__c <= :driveDate)
                AND (sked_Future_Inactive_Date__c = NULL OR sked_Future_Inactive_Date__c > :driveDate)
                AND (sked_Dedicated_to_Site__c = NULL OR sked_Dedicated_to_Site__c = :driveSiteId)
        ];
    }

    // A tag only counts toward a required-tag match if its own start date has passed AND it isn't
    // currently inside its own restriction window. Public: sked__Resource_Tag__c/sked__ResourceTags__r
    // is the same relationship for Person and Asset resources alike, so skedLockedResourceAvailability
    // Checker reuses this unchanged for staff eligibility rather than duplicating it.
    public static Boolean hasAllRequiredTags(sked__Resource__c resource, Set<Id> requiredTagIds, Date driveDate) {
        if (requiredTagIds == null || requiredTagIds.isEmpty()) {
            return true;
        }
        Set<Id> validTagIds = new Set<Id>();
        for (sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {
            if (resourceTag.sked_Start_Date__c <= driveDate && !isTagRestricted(resourceTag, driveDate)) {
                validTagIds.add(resourceTag.sked__Tag__c);
            }
        }
        return validTagIds.containsAll(requiredTagIds);
    }

    // This only deals with single-day mobile drives, so both bounds collapse to driveDate.
    private static Boolean isTagRestricted(sked__Resource_Tag__c resourceTag, Date driveDate) {
        if (resourceTag.sked_Restriction_Start_Date__c == null && resourceTag.sked_Restriction_End_Date__c == null) {
            return false;
        }
        if (resourceTag.sked_Restriction_End_Date__c != null) {
            return resourceTag.sked_Restriction_Start_Date__c <= driveDate && resourceTag.sked_Restriction_End_Date__c >= driveDate;
        }
        return resourceTag.sked_Restriction_Start_Date__c <= driveDate;
    }
}
