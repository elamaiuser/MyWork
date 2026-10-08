/**
 * Merges 2RBC + Driver Support into a single dual-role entry in the role quantity map produced by
 * skedMobileRoleQuantityCalculator.calculateRoleQuantities, before skedMobileDriveJobBuilder builds
 * real job records from it - it operates on quantities, not built jobs. Gated behind the CO's
 * sked_Auto_Generate_Dual_Role__c/sked_Only_Generate_Dual_If_1_Machine__c flags, a multi-day-linked-drive
 * check, an excess-staff-capacity threshold checked both before attempting the merge and after (the
 * merge is discarded if it would push excess capacity negative), and a per-shift check against the
 * pre-regen snapshot: a shift whose persisted 2RBC or Driver Support job already has a non-Deleted
 * allocation is skipped entirely, so regenerating an already-staffed drive never merges roles a
 * person is already actively assigned to.
 *
 * Merge behavior: equal quantities merge fully (one role's entry becomes the dual-role entry, the other
 * is fully absorbed); unequal quantities merge only the smaller amount, and the larger role's leftover
 * becomes its own single-role entry (never a brand-new entry - the original role's entry, resized).
 *
 * Restoring a dual-role merge back to its original two roles (e.g. on manual override) is not implemented.
 */
public with sharing class skedMobileDualRoleGenerator {

    private static final String ROLE_2RBC = '2RBC';
    private static final String ROLE_DRIVER_SUPPORT = 'Driver Support';
    private static final String ROLE_VPHH = 'VP/HH';
    private static final List<String> CAPACITY_ROLES = new List<String>{ 'Driver', ROLE_DRIVER_SUPPORT, ROLE_2RBC, ROLE_VPHH, 'Charge' };
    private static final Integer MIN_VALID_ROLES_TO_MERGE = 4;

    /**
     * Mutates roleQuantityByShiftKey in place only if a merge is actually generated AND survives the
     * post-merge excess-capacity check; otherwise leaves it untouched.
     */
    public static void generateDualRoles(Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey,
            sked_Drive__c drive, Biomed_Collection_Op_Center__c collectionOperation, skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, Decimal numberOf2rbcAssets, Decimal projectedRegisteredDonors,
            Decimal excessStaffCapacityThreshold, String timezoneSidId, List<sked_Drive_Shift__c> backupDriveShifts,
            Map<Id, List<sked__Job__c>> backupJobsByShiftId, Map<Id, List<sked__Job_Allocation__c>> backupAllocationsByJobId) {
        if (!shouldGenerateDualRoles(drive, collectionOperation, staffingDecisionMatrix, numberOf2rbcAssets)) {
            return;
        }

        Decimal excessStaffCapacity = calculateExcessStaffCapacity(roleQuantityByShiftKey, shiftsMetadata, staffingDecisionMatrix,
            numberOf2rbcAssets, projectedRegisteredDonors, timezoneSidId);
        if (excessStaffCapacity < excessStaffCapacityThreshold) {
            return;
        }

        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> tentative = deepClone(roleQuantityByShiftKey);
        Boolean dualRolesGenerated = false;
        for (Integer i = 0; i < shiftsMetadata.driveShifts.size(); i++) {
            skedMobileDriveShiftCalculator.DriveShiftMetadata shift = shiftsMetadata.driveShifts[i];
            Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap = tentative.get(shift.key);
            if (!containsRoles(resourceQuantityMap, ROLE_2RBC, ROLE_DRIVER_SUPPORT) || getValidRoles(resourceQuantityMap).size() < MIN_VALID_ROLES_TO_MERGE) {
                continue;
            }
            if (isRoleAlreadyStaffed(backupDriveShifts, backupJobsByShiftId, backupAllocationsByJobId, i, ROLE_2RBC)
                    || isRoleAlreadyStaffed(backupDriveShifts, backupJobsByShiftId, backupAllocationsByJobId, i, ROLE_DRIVER_SUPPORT)) {
                continue;
            }
            mergeDualRole(resourceQuantityMap, ROLE_2RBC, ROLE_DRIVER_SUPPORT);
            dualRolesGenerated = true;
        }
        if (!dualRolesGenerated) {
            return;
        }

        Decimal excessAfterMerge = calculateExcessStaffCapacity(tentative, shiftsMetadata, staffingDecisionMatrix,
            numberOf2rbcAssets, projectedRegisteredDonors, timezoneSidId);
        if (excessAfterMerge >= 0) {
            roleQuantityByShiftKey.clear();
            roleQuantityByShiftKey.putAll(tentative);
        }
    }

    private static Boolean shouldGenerateDualRoles(sked_Drive__c drive, Biomed_Collection_Op_Center__c collectionOperation,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, Decimal numberOf2rbcAssets) {
        if (collectionOperation.sked_Auto_Generate_Dual_Role__c != true) {
            return false;
        }
        if (collectionOperation.sked_Only_Generate_Dual_If_1_Machine__c == true && numberOf2rbcAssets != 1) {
            return false;
        }
        if (isDriveAPartOfMultiDaysLinkedDrive(drive)) {
            return false;
        }
        return staffingDecisionMatrix != null;
    }

    // Pairs shiftsMetadata.driveShifts[shiftIndex] with backupDriveShifts[shiftIndex] by position -
    // the same positional correspondence skedMobileDriveJobBuilder's carry-forward steps already
    // rely on between proposed shifts and their real persisted counterparts.
    private static Boolean isRoleAlreadyStaffed(List<sked_Drive_Shift__c> backupDriveShifts,
            Map<Id, List<sked__Job__c>> backupJobsByShiftId, Map<Id, List<sked__Job_Allocation__c>> backupAllocationsByJobId,
            Integer shiftIndex, String role) {
        if (shiftIndex >= backupDriveShifts.size()) {
            return false;
        }
        List<sked__Job__c> backupJobs = backupJobsByShiftId.get(backupDriveShifts[shiftIndex].Id);
        if (backupJobs == null) {
            return false;
        }
        for (sked__Job__c job : backupJobs) {
            if (job.sked_Resource_Role__c != role && job.sked_Dual_Role__c != role) {
                continue;
            }
            List<sked__Job_Allocation__c> allocations = backupAllocationsByJobId.get(job.Id);
            if (allocations == null) {
                continue;
            }
            for (sked__Job_Allocation__c allocation : allocations) {
                if (allocation.sked__Status__c != skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                    return true;
                }
            }
        }
        return false;
    }

    private static Boolean isDriveAPartOfMultiDaysLinkedDrive(sked_Drive__c drive) {
        return drive.sked_Linked_Drives__c != null && drive.sked_Linked_Drives__r.sked_Linked_Drive_Type__c == skedConstants.LINKED_DRIVE_TYPE_MULTI;
    }

    // Keys are compared as-is, not split by base role - VP/HH's key is never dual-keyed so an exact match is correct.
    private static Boolean containsRoles(Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap, String role1, String role2) {
        List<String> validRoles = getValidRoles(resourceQuantityMap);
        return validRoles.contains(role1) && validRoles.contains(role2);
    }

    private static List<String> getValidRoles(Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap) {
        List<String> validRoles = new List<String>();
        for (String key : resourceQuantityMap.keySet()) {
            skedMobileRoleQuantityCalculator.RoleQuantity data = resourceQuantityMap.get(key);
            Boolean quantityValid = key == ROLE_VPHH ? positive(data.vphhQuantity) : positive(data.quantity);
            if (quantityValid) {
                validRoles.add(key);
            }
        }
        return validRoles;
    }

    private static Boolean positive(Decimal value) {
        return value != null && value > 0;
    }

    // role1's entry becomes the merged dual-role job; role2 either shrinks to its own leftover or is fully absorbed and removed.
    private static void mergeDualRole(Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap, String role1, String role2) {
        Decimal quantity1 = resourceQuantityMap.get(role1).quantity;
        Decimal quantity2 = resourceQuantityMap.get(role2).quantity;
        String mergedKey = role1 + '-' + role2;

        resourceQuantityMap.remove(role1);
        resourceQuantityMap.remove(role2);

        if (quantity1 == quantity2) {
            resourceQuantityMap.put(mergedKey, newQuantity(quantity1));
        } else if (quantity1 < quantity2) {
            resourceQuantityMap.put(mergedKey, newQuantity(quantity1));
            resourceQuantityMap.put(role2, newQuantity(quantity2 - quantity1));
        } else {
            resourceQuantityMap.put(mergedKey, newQuantity(quantity2));
            resourceQuantityMap.put(role1, newQuantity(quantity1 - quantity2));
        }
    }

    private static skedMobileRoleQuantityCalculator.RoleQuantity newQuantity(Decimal quantity) {
        skedMobileRoleQuantityCalculator.RoleQuantity roleQuantity = new skedMobileRoleQuantityCalculator.RoleQuantity();
        roleQuantity.quantity = quantity;
        return roleQuantity;
    }

    // Public because skedMobileDriveRegenEngine also calls this after dual-role merging settles, to
    // persist the final value onto sked_Drive__c.Excess_Staff_Capacity__c for skedDriveContentionValidator.
    public static Decimal calculateExcessStaffCapacity(Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            Decimal numberOf2rbcAssets, Decimal projectedRegisteredDonors, String timezoneSidId) {
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> capacityMap = applyVpHhCapacityOverride(roleQuantityByShiftKey);

        Decimal staffCapacity = 0;
        Decimal maxStaffCapacity = 0;
        Decimal totalDrawHours = 0;
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap = capacityMap.get(shift.key);

            // null adhocDriverSupportCapacity is safe here - applyVpHhCapacityOverride's RoleQuantity
            // entries never carry isManuallyCreated (built fresh via newQuantity), so the Driver-Support
            // adhoc-capacity fallback's gate can never trigger for this call regardless of the value passed.
            Decimal shiftStaffCapacity = Math.floor(skedMobileRoleQuantityCalculator.calculateStaffCapacity(
                CAPACITY_ROLES, resourceQuantityMap, shift, staffingDecisionMatrix, numberOf2rbcAssets, timezoneSidId, false, null));
            staffCapacity += shiftStaffCapacity;

            Decimal shiftMaxStaffCapacity = skedMobileRoleQuantityCalculator.calculateMaximumStaffCapacity(CAPACITY_ROLES, resourceQuantityMap, staffingDecisionMatrix);
            if (shiftMaxStaffCapacity > maxStaffCapacity) {
                maxStaffCapacity = shiftMaxStaffCapacity;
            }

            Decimal shiftDrawHours = skedMobileRoleQuantityCalculator.calculateShiftDrawHours(shift, timezoneSidId);
            if (shiftDrawHours != null) {
                totalDrawHours += shiftDrawHours;
            }
        }

        Decimal maxRoleCapacityWithDrawHours = totalDrawHours > 0 ? (maxStaffCapacity * totalDrawHours).setScale(2) : 0;

        if (staffCapacity > 0 && maxRoleCapacityWithDrawHours > 0) {
            if (projectedRegisteredDonors != null && projectedRegisteredDonors != 0) {
                return ((staffCapacity - projectedRegisteredDonors) / maxRoleCapacityWithDrawHours).setScale(1);
            }
            return (staffCapacity / maxRoleCapacityWithDrawHours).setScale(1);
        }
        return 0;
    }

    // For the excess-capacity calculation only, a VP/HH entry with a positive aptQuantity has its
    // quantity overridden to vphhQuantity - applied fresh to a clone, never persisted.
    private static Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> applyVpHhCapacityOverride(
            Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> source) {
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> cloned = deepClone(source);
        for (Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> shiftRoleQuantities : cloned.values()) {
            skedMobileRoleQuantityCalculator.RoleQuantity vpHh = shiftRoleQuantities.get(ROLE_VPHH);
            if (vpHh != null && vpHh.aptQuantity != null && vpHh.aptQuantity != 0) {
                vpHh.quantity = vpHh.vphhQuantity;
            }
        }
        return cloned;
    }

    private static Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> deepClone(
            Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> source) {
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> result = new Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>>();
        for (String shiftKey : source.keySet()) {
            Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> clonedInner = new Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>();
            for (String roleKey : source.get(shiftKey).keySet()) {
                skedMobileRoleQuantityCalculator.RoleQuantity original = source.get(shiftKey).get(roleKey);
                skedMobileRoleQuantityCalculator.RoleQuantity clone = new skedMobileRoleQuantityCalculator.RoleQuantity();
                clone.quantity = original.quantity;
                clone.vphhQuantity = original.vphhQuantity;
                clone.aptQuantity = original.aptQuantity;
                clonedInner.put(roleKey, clone);
            }
            result.put(shiftKey, clonedInner);
        }
        return result;
    }
}
