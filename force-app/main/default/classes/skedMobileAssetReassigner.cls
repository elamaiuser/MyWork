/**
 * When a drive's currently-assigned Vehicle/Equipment resources are invalid or insufficient, picks
 * a replacement set and mutates the graph, rather than just flagging it. Runs PRE-save (unlike
 * skedDriveContentionValidator's validate-only checks) since it mutates ctx.allocationsByJobId
 * directly - skedDriveGraphSaver then persists the result normally.
 *
 * sked__Resource__c is a master field skedDriveGraphSaver never re-points on update, so a resource
 * change can only happen via mark-existing-Deleted + insert-new for the resources that actually
 * change - applyReplacement preserves the existing record/Id for any resource still in the chosen set.
 *
 * Scope, matching skedDriveContentionValidator's checkLackingVehicle/checkLackingEquipment:
 * only the first Vehicle job and first Equipment job on the drive's single shift (Mobile drives with
 * more than one shift are already flagged MULTI_SHIFT_DRIVE elsewhere; this port never builds more
 * than one job per asset type per shift).
 *
 * Guards:
 * - reassignInvalidAssets no-ops for a Draft-status drive. An unconditional skip matches this
 *   pipeline's actually-reachable behavior today (the promotion from Draft to Tentative once
 *   contention clears happens later, well after this class's call site) - if an approval flow
 *   that needs to reassign a pending-approval Draft is added later, this guard will need a matching
 *   opt-in parameter.
 * - reassignVehicle/reassignEquipment skip entirely when the job itself has no Id yet (e.g. a
 *   drive whose Do Not Use Vehicle flag just flipped false, with no prior vehicle job to match). A
 *   brand-new job has no current assignment to validate, and picking replacements for it would insert
 *   a sked__Job_Allocation__c with a null sked__Job__c master-detail parent, failing the whole save -
 *   left for the post-save LACKING_VEHICLE/LACKING_EQUIPMENT check to flag instead.
 *
 * "Current" allocations are read from ctx.allocationsByJobId (already carried-forward pre-save by
 * skedMobileJobAllocationCarryForward), matching how skedDriveContentionValidator's
 * checkLackingVehicle/checkLackingEquipment already treat ctx as the authoritative in-memory source,
 * rather than issuing a fresh per-job query. Caveat: the carried records only carry
 * Id/sked__Job__c/sked__Resource__c/start/end/duration - they do NOT carry sked_Is_Locked__c or the
 * resource's capacity, both of which this class needs. loadCurrentAllocations enriches by Id (scoped
 * to exactly the allocation Ids ctx already identified as active), rather than re-deriving "what's
 * current" from the database. This relies on the carry-forward step only ever producing real-Id,
 * non-Deleted entries - a future change to that step could silently orphan an allocation here.
 *
 * maxDOT/maxCDL vehicle ranking tiers ARE honored (skedDriveContentionValidator.computeMaxDotCdlForDrive
 * + skedMobileGhostVehicleCalculator.pickSmallestVehicleSet - see that class's header for the tiering
 * itself).
 *
 * Deliberately not handled:
 * - Linked-drive cross-CO asset sharing - same family as the deferred cross-region contentions.
 * - A field-change gate that skips revalidation entirely unless a specific field changed - always
 *   runs here instead, since there isn't enough field-level granularity carried through to
 *   reconstruct that gate cheaply.
 * - A donor-count gate on the Do Not Use Vehicle deallocation - not handled, consistent with the
 *   field-change gate point above.
 *
 * Vehicle reassignment additionally skips entirely for any Fixed Site drive, both operation types -
 * see reassignInvalidAssets's isFixedSiteDrive check. Equipment reassignment runs for every drive
 * type, unchanged.
 */
public with sharing class skedMobileAssetReassigner {

    public static void reassignInvalidAssets(skedDriveRegenContext ctx) {
        if (ctx.drive.sked_Status__c == skedConstants.DRIVE_STATUS_DRAFT) {
            return;
        }
        if (ctx.driveShifts.isEmpty()) {
            return;
        }
        sked_Drive_Shift__c shift = ctx.driveShifts[0];
        List<sked__Job__c> jobs = ctx.jobsByShiftId.get(shift.Id);
        if (jobs == null || jobs.isEmpty()) {
            return;
        }

        Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>> jobTagsByResourceType =
            skedMobileDriveShiftCalculator.loadJobTagsMap(ctx.drive);

        // Neither Fixed Site operation type has real vehicle validation - validateVehicles is a permanent
        // no-op stub in both fixedSiteGenerator.js:544-549 and wbFixedSiteGenerator.js:558-563 (byte-identical).
        Boolean isFixedSiteDrive = ctx.drive.sked_Type_of_Drive__c == skedConstants.DRIVE_TYPE_FIXED_SITE;

        if (!isFixedSiteDrive) {
            for (sked__Job__c job : jobs) {
                if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                    reassignVehicle(ctx, shift, job, tagIdSet(jobTagsByResourceType.get(skedConstants.ASSET_TYPE_VEHICLE)));
                    break;
                }
            }
        }
        for (sked__Job__c job : jobs) {
            if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                reassignEquipment(ctx, shift, job, tagIdSet(jobTagsByResourceType.get(skedConstants.ASSET_TYPE_EQUIPMENT)));
                break;
            }
        }
    }

    private static Set<Id> tagIdSet(List<skedMobileDriveShiftCalculator.RequiredJobTag> tags) {
        Set<Id> tagIds = new Set<Id>();
        if (tags == null) {
            return tagIds;
        }
        for (skedMobileDriveShiftCalculator.RequiredJobTag tag : tags) {
            tagIds.add(tag.tagId);
        }
        return tagIds;
    }

    // One currently-assigned allocation, enriched with the two fields ctx's carried-forward record
    // doesn't carry (sked_Is_Locked__c, resource capacity) - see class header caveat. `record` is the
    // actual ctx-owned sObject; mutating/reusing it (rather than building a new one) is how
    // applyReplacement preserves an existing allocation's Id.
    private class CurrentAllocation {
        sked__Job_Allocation__c record;
        Id resourceId;
        Boolean isLocked;
        Decimal capacity;
        Boolean isDOT;
        Boolean isCDL;
    }

    // Splits a job's CURRENT active allocations into locked (sked_Is_Locked__c - a real field, never
    // reassigned) vs unlocked (candidates for replacement).
    private class CurrentAllocations {
        List<CurrentAllocation> locked = new List<CurrentAllocation>();
        List<CurrentAllocation> unlocked = new List<CurrentAllocation>();
        Set<Id> lockedResourceIds = new Set<Id>();
    }

    // "current" allocations come from ctx.allocationsByJobId (already carried-forward pre-save),
    // not a fresh query keyed by Job Id - matches skedDriveContentionValidator's checkLackingVehicle/
    // checkLackingEquipment. The only DB read left is a narrow by-Id enrichment for the two fields
    // ctx's carried record doesn't have (see class header).
    private static CurrentAllocations loadCurrentAllocations(skedDriveRegenContext ctx, Id jobId) {
        CurrentAllocations result = new CurrentAllocations();
        if (jobId == null) {
            return result;
        }
        List<sked__Job_Allocation__c> ctxAllocations = ctx.allocationsByJobId.get(jobId);
        if (ctxAllocations == null || ctxAllocations.isEmpty()) {
            return result;
        }

        Set<Id> activeIds = new Set<Id>();
        List<sked__Job_Allocation__c> activeRecords = new List<sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c allocation : ctxAllocations) {
            if (allocation.sked__Status__c != skedConstants.JOB_ALLOCATION_STATUS_DELETED && allocation.Id != null) {
                activeIds.add(allocation.Id);
                activeRecords.add(allocation);
            }
        }
        Map<Id, sked__Job_Allocation__c> enrichmentById = activeIds.isEmpty() ? new Map<Id, sked__Job_Allocation__c>()
            : new Map<Id, sked__Job_Allocation__c>([
                SELECT Id, sked_Is_Locked__c, sked__Resource__r.sked_Pres_Donor_Capacity__c,
                    sked__Resource__r.sked_DOT__c, sked__Resource__r.sked_CDL__c
                FROM sked__Job_Allocation__c
                WHERE Id IN :activeIds
            ]);

        for (sked__Job_Allocation__c record : activeRecords) {
            sked__Job_Allocation__c enrichment = enrichmentById.get(record.Id);
            CurrentAllocation allocation = new CurrentAllocation();
            allocation.record = record;
            allocation.resourceId = record.sked__Resource__c;
            allocation.isLocked = enrichment != null && enrichment.sked_Is_Locked__c == true;
            allocation.capacity = (enrichment == null || enrichment.sked__Resource__r.sked_Pres_Donor_Capacity__c == null)
                ? 0 : enrichment.sked__Resource__r.sked_Pres_Donor_Capacity__c;
            allocation.isDOT = enrichment != null && enrichment.sked__Resource__r.sked_DOT__c == true;
            allocation.isCDL = enrichment != null && enrichment.sked__Resource__r.sked_CDL__c == true;
            if (allocation.isLocked) {
                result.locked.add(allocation);
                result.lockedResourceIds.add(allocation.resourceId);
            } else {
                result.unlocked.add(allocation);
            }
        }
        return result;
    }

    private static void reassignVehicle(skedDriveRegenContext ctx, sked_Drive_Shift__c shift, sked__Job__c job, Set<Id> requiredTagIds) {
        if (job.Id == null) {
            // A brand-new job (e.g. Do Not Use Vehicle just flipped false, no prior vehicle job to
            // match) has no current assignment to validate - nothing to reassign. Picking a fresh
            // set here would call applyReplacement with a null sked__Job__c, which
            // skedDriveGraphSaver would try to insert with no master-detail parent and fail the
            // whole save. A zero-allocation new job is already correctly caught post-save by
            // skedDriveContentionValidator's LACKING_VEHICLE check instead.
            return;
        }
        CurrentAllocations current = loadCurrentAllocations(ctx, job.Id);

        if (ctx.drive.sked_Do_Not_Use_Vehicle__c == true) {
            // Do Not Use Vehicle marks EVERY current allocation Deleted, locked or not - it
            // overrides even a lock.
            deleteAllCurrentAllocations(ctx, job.Id, current);
            return;
        }

        List<sked__Resource__c> availableVehicles = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, ctx.drive.sked_Collection_Operation__c, ctx.drive.sked_Drive_Date__c,
            ctx.drive.sked_Drive_Site__c, ctx.drive.Id, shift.sked_Start__c, shift.sked_Finish__c, requiredTagIds);
        Set<Id> availableVehicleIds = new Map<Id, sked__Resource__c>(availableVehicles).keySet();

        // An existing assignment (locked or unlocked) is valid iff it's a member of the SAME
        // pool used to pick new candidates, not merely conflict-free.
        Boolean allAssignedValid = true;
        Decimal lockedCapacity = 0;
        Integer lockedDOTCount = 0;
        Integer lockedCDLCount = 0;
        Decimal totalCurrentCapacity = 0;
        for (CurrentAllocation allocation : current.locked) {
            totalCurrentCapacity += allocation.capacity;
            lockedCapacity += allocation.capacity;
            if (allocation.isDOT) {
                lockedDOTCount++;
            }
            if (allocation.isCDL) {
                lockedCDLCount++;
            }
            if (!availableVehicleIds.contains(allocation.resourceId)) {
                allAssignedValid = false;
            }
        }
        for (CurrentAllocation allocation : current.unlocked) {
            totalCurrentCapacity += allocation.capacity;
            if (!availableVehicleIds.contains(allocation.resourceId)) {
                allAssignedValid = false;
            }
        }

        // A zero Donors Scheduled falls back to Projected Registered Donors too - a truthy check,
        // not a null check, matching the sibling checkLackingVehicle's same fallback.
        Decimal maxRegisteredDonors = (shift.sked_Donors_Scheduled__c != null && shift.sked_Donors_Scheduled__c > 0) ? shift.sked_Donors_Scheduled__c
            : (ctx.drive.sked_Projected_Registered_Donors__c == null ? 0 : ctx.drive.sked_Projected_Registered_Donors__c);

        if (allAssignedValid && totalCurrentCapacity >= maxRegisteredDonors) {
            return; // everything valid and sufficient, no-op
        }

        Decimal remainingCapacityNeeded = maxRegisteredDonors - lockedCapacity;
        if (remainingCapacityNeeded < 0) {
            remainingCapacityNeeded = 0;
        }
        if (remainingCapacityNeeded <= 0) {
            // Locked capacity alone already covers the requirement, but something currently
            // assigned is invalid (the only way this branch is reached) - trim to just the locked
            // set rather than leaving a redundant/invalid unlocked allocation in place.
            applyReplacement(ctx, job.Id, current, new List<sked__Resource__c>(), shift);
            return;
        }

        List<sked__Resource__c> candidatePool = new List<sked__Resource__c>();
        for (sked__Resource__c vehicle : availableVehicles) {
            if (!current.lockedResourceIds.contains(vehicle.Id)) {
                candidatePool.add(vehicle);
            }
        }
        // Net already-locked DOT/CDL vehicles off the drive's own limits before picking a
        // replacement for the UNLOCKED portion - those locked vehicles aren't being replaced, but
        // they still count against the drive-wide limit (helper.js's preProcessSuggestVehicles).
        // Safe to subtract unconditionally even when maxDOT/maxCDL is the unbounded sentinel - still
        // effectively unbounded afterward.
        skedDriveContentionValidator.MaxDotCdl maxDotCdl = skedDriveContentionValidator.computeMaxDotCdlForDrive(ctx.drive, ctx.operationDriveLimits, ctx.sameDateDrives);
        Decimal remainingMaxDOTRaw = maxDotCdl.maxDOT - lockedDOTCount;
        Decimal remainingMaxCDLRaw = maxDotCdl.maxCDL - lockedCDLCount;
        Decimal remainingMaxDOT = remainingMaxDOTRaw < 0 ? 0 : remainingMaxDOTRaw;
        Decimal remainingMaxCDL = remainingMaxCDLRaw < 0 ? 0 : remainingMaxCDLRaw;
        List<sked__Resource__c> chosen = skedMobileGhostVehicleCalculator.pickSmallestVehicleSet(candidatePool, remainingCapacityNeeded, remainingMaxDOT, remainingMaxCDL);
        if (chosen.isEmpty() && !candidatePool.isEmpty()) {
            // Falls back to allocating every available vehicle when no combination covers the
            // required capacity (still under-capacity, but staffed with what exists), rather than
            // allocating nothing. Only applies when candidates genuinely exist but none of them
            // cover the need - an empty candidatePool has nothing to fall back to either way.
            chosen = candidatePool;
        }

        applyReplacement(ctx, job.Id, current, chosen, shift);
    }

    private static void reassignEquipment(skedDriveRegenContext ctx, sked_Drive_Shift__c shift, sked__Job__c job, Set<Id> requiredTagIds) {
        if (job.Id == null) {
            // Same reasoning as reassignVehicle's guard: a brand-new equipment job has no current
            // assignment to validate, and applyReplacement would insert an allocation with a null
            // sked__Job__c master-detail parent - left for the post-save LACKING_EQUIPMENT check.
            return;
        }
        Decimal quantityNeeded = job.sked__Quantity__c == null ? 0 : job.sked__Quantity__c;
        CurrentAllocations current = loadCurrentAllocations(ctx, job.Id);

        List<sked__Resource__c> availableEquipment = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_EQUIPMENT, ctx.drive.sked_Collection_Operation__c, ctx.drive.sked_Drive_Date__c,
            ctx.drive.sked_Drive_Site__c, ctx.drive.Id, shift.sked_Start__c, shift.sked_Finish__c, requiredTagIds);
        Map<Id, sked__Resource__c> availableEquipmentById = new Map<Id, sked__Resource__c>(availableEquipment);

        // Same full-pool validity check as reassignVehicle.
        Integer currentTotalCount = current.locked.size() + current.unlocked.size();
        Integer currentValidCount = 0;
        Boolean allAssignedValid = true;
        for (CurrentAllocation allocation : current.locked) {
            if (availableEquipmentById.containsKey(allocation.resourceId)) {
                currentValidCount++;
            } else {
                allAssignedValid = false;
            }
        }
        for (CurrentAllocation allocation : current.unlocked) {
            if (availableEquipmentById.containsKey(allocation.resourceId)) {
                currentValidCount++;
            } else {
                allAssignedValid = false;
            }
        }

        if (allAssignedValid && currentValidCount == quantityNeeded) {
            return; // everything valid and at target count, no-op
        }

        Integer neededCount = (quantityNeeded - current.locked.size()).intValue();
        if (neededCount < 0) {
            neededCount = 0;
        }

        List<sked__Resource__c> candidatePool;
        if (!allAssignedValid || currentTotalCount < quantityNeeded) {
            // Under target (or something invalid) - pick from the FULL available pool.
            candidatePool = orderEquipmentCandidates(availableEquipment, job, ctx.drive.sked_Drive_Site__c, current.lockedResourceIds);
        } else {
            // currentValidCount > quantityNeeded - trim from only the CURRENTLY valid equipment,
            // not the fresh available pool.
            List<sked__Resource__c> validCurrent = new List<sked__Resource__c>();
            for (CurrentAllocation allocation : current.unlocked) {
                if (availableEquipmentById.containsKey(allocation.resourceId)) {
                    validCurrent.add(availableEquipmentById.get(allocation.resourceId));
                }
            }
            candidatePool = orderEquipmentCandidates(validCurrent, job, ctx.drive.sked_Drive_Site__c, current.lockedResourceIds);
        }

        List<sked__Resource__c> chosen = new List<sked__Resource__c>();
        for (Integer i = 0; i < candidatePool.size() && chosen.size() < neededCount; i++) {
            chosen.add(candidatePool[i]);
        }

        applyReplacement(ctx, job.Id, current, chosen, shift);
    }

    // A candidate must match the job's required equipment subtype (e.g. '2RBC Asset') to be
    // eligible at all. Then prefers equipment already dedicated to this drive's site.
    private static List<sked__Resource__c> orderEquipmentCandidates(List<sked__Resource__c> candidates, sked__Job__c job,
            Id driveSiteId, Set<Id> lockedResourceIds) {
        List<sked__Resource__c> dedicated = new List<sked__Resource__c>();
        List<sked__Resource__c> notDedicated = new List<sked__Resource__c>();
        for (sked__Resource__c equipment : candidates) {
            if (lockedResourceIds.contains(equipment.Id)) {
                continue;
            }
            if (job.sked_Equipment_Subtype__c != equipment.sked_Equipment_Subtype__c) {
                continue;
            }
            if (equipment.sked_Dedicated_to_Site__c == driveSiteId) {
                dedicated.add(equipment);
            } else {
                notDedicated.add(equipment);
            }
        }
        List<sked__Resource__c> ordered = new List<sked__Resource__c>();
        ordered.addAll(dedicated);
        ordered.addAll(notDedicated);
        return ordered;
    }

    // Forces every current allocation (locked included) to Deleted - see reassignVehicle's
    // doNotUseVehicle branch.
    private static void deleteAllCurrentAllocations(skedDriveRegenContext ctx, Id jobId, CurrentAllocations current) {
        List<sked__Job_Allocation__c> updated = new List<sked__Job_Allocation__c>();
        for (CurrentAllocation allocation : current.locked) {
            allocation.record.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
            updated.add(allocation.record);
        }
        for (CurrentAllocation allocation : current.unlocked) {
            allocation.record.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
            updated.add(allocation.record);
        }
        ctx.allocationsByJobId.put(jobId, updated);
    }

    // A chosen replacement resource that matches an already-assigned unlocked resource PRESERVES
    // the existing allocation record (same Id) rather than delete+recreate. Locked allocations
    // always pass through untouched; truly-dropped unlocked resources are marked Deleted;
    // truly-new chosen resources get inserted.
    private static void applyReplacement(skedDriveRegenContext ctx, Id jobId, CurrentAllocations current,
            List<sked__Resource__c> chosenReplacements, sked_Drive_Shift__c shift) {
        Set<Id> chosenResourceIds = new Set<Id>();
        for (sked__Resource__c resource : chosenReplacements) {
            chosenResourceIds.add(resource.Id);
        }

        List<sked__Job_Allocation__c> updated = new List<sked__Job_Allocation__c>();
        for (CurrentAllocation allocation : current.locked) {
            updated.add(allocation.record);
        }

        Set<Id> keptResourceIds = new Set<Id>();
        for (CurrentAllocation allocation : current.unlocked) {
            if (chosenResourceIds.contains(allocation.resourceId)) {
                updated.add(allocation.record); // still needed - preserve the existing record/Id
                keptResourceIds.add(allocation.resourceId);
            } else {
                allocation.record.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
                updated.add(allocation.record);
            }
        }
        for (sked__Resource__c resource : chosenReplacements) {
            if (keptResourceIds.contains(resource.Id)) {
                continue; // already preserved above
            }
            updated.add(new sked__Job_Allocation__c(
                sked__Job__c = jobId,
                sked__Resource__c = resource.Id,
                sked__Start__c = shift.sked_Start__c,
                sked__Set_End__c = shift.sked_Finish__c,
                sked__Duration__c = (shift.sked_Finish__c.getTime() - shift.sked_Start__c.getTime()) / (1000 * 60)
            ));
        }
        ctx.allocationsByJobId.put(jobId, updated);
    }
}
