/**
 * Recomputes how many vehicles a DRAFT drive with sked_Prefer_System_Generated_Vehicles__c needs, by
 * finding a DOT/CDL-tiered set of tag-eligible CO vehicles whose combined sked_Pres_Donor_Capacity__c
 * covers the drive's max scheduled donors.
 *
 * DOT/CDL ranking tiers ported from helper.js's calculateNumberOfVehiclesForDrive, but NOT its
 * exhaustive-subset-enumeration-then-rank approach - that has no bound on candidate-pool size (only
 * SKIP_EXHAUSTIVE_SEARCH_ABOVE, itself gated on required capacity, not pool size), a real CPU-limit
 * risk for a large low-capacity fleet (e.g. ~50 vehicles at ~10 capacity each needing to combine
 * ~40-50 of them, still under that threshold). Ported instead as 3 bounded greedy passes
 * (greedyAccumulate), each hard-capping how many DOT/CDL vehicles it's willing to include: rank 1
 * (both maxDOT/maxCDL respected), rank 2 (only one relaxed - whichever succeeds, or the
 * smaller/cheaper of the two if both do), rank 3 (both relaxed, always succeeds if the pool has
 * enough total capacity - never returns nothing). Each pass itself mirrors the source's own
 * single-vehicle-vs-multi-vehicle split: a lone vehicle whose capacity alone meets the requirement
 * always beats any multi-vehicle combination (fewer vehicles wins first) - the CHEAPEST such vehicle
 * is preferred (least waste), found scanning capacity-ascending; only when none suffices alone does
 * it fall back to a largest-first greedy accumulation (minimizing count is what matters once
 * multiple vehicles are needed). O(n log n) regardless of fleet size, at the cost of no longer being
 * the mathematically fewest-vehicles/least-capacity combination in every multi-vehicle edge case a
 * full enumeration could find - largest-first greedy is a strong heuristic for that case, not an
 * exact one. maxDOT/maxCDL come from skedDriveContentionValidator.computeMaxDotCdlForDrive - when
 * unbounded (no operational limit configured), rank 1 always succeeds.
 */
public with sharing class skedMobileGhostVehicleCalculator {

    private class VehicleSet implements Comparable {
        Decimal totalCap;
        List<sked__Resource__c> vehicles = new List<sked__Resource__c>();

        public Integer compareTo(Object other) {
            VehicleSet otherSet = (VehicleSet) other;
            if (vehicles.size() != otherSet.vehicles.size()) {
                return vehicles.size() < otherSet.vehicles.size() ? -1 : 1;
            }
            if (totalCap == otherSet.totalCap) {
                return 0;
            }
            return totalCap < otherSet.totalCap ? -1 : 1;
        }
    }

    // Deliberately unbounded DOT/CDL - matches mobileGenerator.js:1590, which passes {} (no limits)
    // to calculateNumberOfVehiclesForDrive for this specific Draft ghost-vehicle-count path. Real
    // DOT/CDL limits only apply once an actual vehicle is being assigned (pickSmallestVehicleSet,
    // called by skedMobileAssetReassigner and skedMobileDriveJobBuilder's own vehicle-count path) -
    // this is just an estimate of how many vehicles a Draft drive is LIKELY to need.
    public static void calculateDraftDriveGhostVehicleQuantity(sked_Drive__c drive,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, skedMobileDriveShiftCalculator.MasterData masterData) {
        if (drive.sked_Status__c != skedConstants.DRIVE_STATUS_DRAFT) {
            return;
        }
        if (drive.sked_Do_Not_Use_Vehicle__c) {
            drive.sked_Number_of_Vehicles__c = 0;
            return;
        }
        if (drive.sked_Prefer_System_Generated_Vehicles__c != true) {
            return;
        }

        List<sked__Resource__c> availableVehicles = filterByTagsAndCapacity(masterData.vehicles, masterData.vehicleRequiredTagIds, drive.sked_Drive_Date__c);
        Decimal maxRegisteredDonors = getMaxDonorsScheduled(shiftsMetadata, drive);

        VehicleSet best = pickBestRankedSet(availableVehicles, maxRegisteredDonors, UNBOUNDED_VEHICLE_LIMIT, UNBOUNDED_VEHICLE_LIMIT);
        drive.sked_Number_of_Vehicles__c = best != null ? best.vehicles.size() : 1;
    }

    /**
     * Public entry to the best-ranked-set search, for callers that already have a tag/CO/conflict-filtered
     * candidate pool (e.g. skedMobileAssetReassigner, via skedAssetAvailabilityChecker.loadAvailableAssets)
     * and just need the actual vehicle picks, not a bare count. Filters out null-capacity candidates
     * defensively, since callers aren't guaranteed to have already excluded those.
     */
    public static List<sked__Resource__c> pickSmallestVehicleSet(List<sked__Resource__c> candidateVehicles, Decimal requiredCapacity, Decimal maxDOT, Decimal maxCDL) {
        List<sked__Resource__c> withCapacity = new List<sked__Resource__c>();
        for (sked__Resource__c vehicle : candidateVehicles) {
            if (vehicle.sked_Pres_Donor_Capacity__c != null) {
                withCapacity.add(vehicle);
            }
        }
        VehicleSet best = pickBestRankedSet(withCapacity, requiredCapacity, maxDOT, maxCDL);
        return best != null ? best.vehicles : new List<sked__Resource__c>();
    }

    // A vehicle qualifies only if its valid tags are a superset of the drive's required tags.
    private static List<sked__Resource__c> filterByTagsAndCapacity(List<sked__Resource__c> vehicles, Set<Id> requiredTagIds, Date driveDate) {
        List<sked__Resource__c> result = new List<sked__Resource__c>();
        for (sked__Resource__c vehicle : vehicles) {
            if (vehicle.sked_Pres_Donor_Capacity__c == null) {
                continue;
            }
            Set<Id> validTagIds = new Set<Id>();
            for (sked__Resource_Tag__c resourceTag : vehicle.sked__ResourceTags__r) {
                if (resourceTag.sked_Start_Date__c <= driveDate) {
                    validTagIds.add(resourceTag.sked__Tag__c);
                }
            }
            if (validTagIds.containsAll(requiredTagIds)) {
                result.add(vehicle);
            }
        }
        return result;
    }

    // Falls back to the drive's own Projected Registered Donors when every shift's donorsScheduled
    // is 0/null (e.g. a shift with zero duration) - matches the same fallback already used by
    // skedDriveContentionValidator.checkLackingVehicle and skedMobileAssetReassigner.reassignVehicle.
    private static Decimal getMaxDonorsScheduled(skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, sked_Drive__c drive) {
        Decimal maxRegisteredDonors = 0;
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            if (shift.donorsScheduled != null && shift.donorsScheduled > maxRegisteredDonors) {
                maxRegisteredDonors = shift.donorsScheduled;
            }
        }
        if (maxRegisteredDonors == 0) {
            maxRegisteredDonors = drive.sked_Projected_Registered_Donors__c == null ? 0 : drive.sked_Projected_Registered_Donors__c;
        }
        return maxRegisteredDonors;
    }

    // Apex's stand-in for "no cap" - large enough that dotCount/cdlCount (bounded by fleet size) can
    // never reach it, so greedyAccumulate never skips a vehicle for exceeding it.
    private static final Decimal UNBOUNDED_VEHICLE_LIMIT = 999999999;

    private static VehicleSet pickBestRankedSet(List<sked__Resource__c> vehicles, Decimal requiredCap, Decimal maxDOT, Decimal maxCDL) {
        List<sked__Resource__c> ascending = sortByCapacity(vehicles, true);
        List<sked__Resource__c> descending = sortByCapacity(vehicles, false);
        Decimal dotCap = maxDOT != null && maxDOT > 0 ? maxDOT : 0;
        Decimal cdlCap = maxCDL != null && maxCDL > 0 ? maxCDL : 0;

        VehicleSet rank1 = greedyAccumulate(ascending, descending, requiredCap, dotCap, cdlCap);
        if (rank1 != null) {
            return rank1;
        }

        VehicleSet rank2 = betterOf(
            greedyAccumulate(ascending, descending, requiredCap, UNBOUNDED_VEHICLE_LIMIT, cdlCap),
            greedyAccumulate(ascending, descending, requiredCap, dotCap, UNBOUNDED_VEHICLE_LIMIT));
        if (rank2 != null) {
            return rank2;
        }

        return greedyAccumulate(ascending, descending, requiredCap, UNBOUNDED_VEHICLE_LIMIT, UNBOUNDED_VEHICLE_LIMIT);
    }

    /**
     * Mirrors the source's own two-bucket split (see class header): a single vehicle whose capacity
     * alone already meets requiredCap is always preferable to any multi-vehicle combination (fewer
     * vehicles wins first) - among those, the CHEAPEST sufficient one wins (least waste), found by
     * scanning ascending and taking the first that qualifies. Only when NO single vehicle suffices
     * does it fall back to a multi-vehicle combination, where minimizing COUNT is what matters most,
     * found by scanning descending (largest first) and accumulating until requiredCap is met. Each
     * scan skips a vehicle that would push its flagged count past dotCap/cdlCap; returns null
     * (infeasible at these caps) rather than violating them - the caller decides what to try next.
     */
    private static VehicleSet greedyAccumulate(List<sked__Resource__c> ascending, List<sked__Resource__c> descending,
            Decimal requiredCap, Decimal dotCap, Decimal cdlCap) {
        for (sked__Resource__c vehicle : ascending) {
            if (isCapExceeded(vehicle, dotCap, cdlCap, 0, 0)) {
                continue;
            }
            if (vehicle.sked_Pres_Donor_Capacity__c >= requiredCap) {
                VehicleSet single = new VehicleSet();
                single.vehicles.add(vehicle);
                single.totalCap = vehicle.sked_Pres_Donor_Capacity__c;
                return single;
            }
        }

        VehicleSet result = new VehicleSet();
        Decimal totalCap = 0;
        Integer dotCount = 0;
        Integer cdlCount = 0;
        for (sked__Resource__c vehicle : descending) {
            if (isCapExceeded(vehicle, dotCap, cdlCap, dotCount, cdlCount)) {
                continue;
            }
            result.vehicles.add(vehicle);
            totalCap += vehicle.sked_Pres_Donor_Capacity__c;
            if (vehicle.sked_DOT__c == true) {
                dotCount++;
            }
            if (vehicle.sked_CDL__c == true) {
                cdlCount++;
            }
            if (totalCap >= requiredCap) {
                result.totalCap = totalCap;
                return result;
            }
        }
        return null;
    }

    private static Boolean isCapExceeded(sked__Resource__c vehicle, Decimal dotCap, Decimal cdlCap, Integer dotCount, Integer cdlCount) {
        return (vehicle.sked_DOT__c == true && dotCount >= dotCap) || (vehicle.sked_CDL__c == true && cdlCount >= cdlCap);
    }

    // Rank 2 relaxes only one of DOT/CDL - if both the DOT-relaxed and CDL-relaxed attempts succeed,
    // prefer whichever needs fewer/cheaper vehicles (VehicleSet's own count-then-capacity tie-break).
    private static VehicleSet betterOf(VehicleSet a, VehicleSet b) {
        if (a == null) {
            return b;
        }
        if (b == null) {
            return a;
        }
        return a.compareTo(b) <= 0 ? a : b;
    }

    private class VehicleByCapacity implements Comparable {
        sked__Resource__c vehicle;
        Boolean ascending;

        public Integer compareTo(Object other) {
            Decimal otherCapacity = ((VehicleByCapacity) other).vehicle.sked_Pres_Donor_Capacity__c;
            if (vehicle.sked_Pres_Donor_Capacity__c == otherCapacity) {
                return 0;
            }
            Boolean isSmaller = vehicle.sked_Pres_Donor_Capacity__c < otherCapacity;
            Boolean wantsSmallerFirst = ascending;
            return isSmaller == wantsSmallerFirst ? -1 : 1;
        }
    }

    private static List<sked__Resource__c> sortByCapacity(List<sked__Resource__c> vehicles, Boolean ascending) {
        List<VehicleByCapacity> wrapped = new List<VehicleByCapacity>();
        for (sked__Resource__c vehicle : vehicles) {
            VehicleByCapacity entry = new VehicleByCapacity();
            entry.vehicle = vehicle;
            entry.ascending = ascending;
            wrapped.add(entry);
        }
        wrapped.sort();
        List<sked__Resource__c> sorted = new List<sked__Resource__c>();
        for (VehicleByCapacity entry : wrapped) {
            sorted.add(entry.vehicle);
        }
        return sorted;
    }
}
