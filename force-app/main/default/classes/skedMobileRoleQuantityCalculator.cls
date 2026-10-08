/**
 * Role->quantity resolution for the 5 quantifiable roles (Driver, Driver Support, 2RBC,
 * Team Supervisor/Drive Lead, VP/HH, Charge) plus vehicle/equipment asset counts, given an already
 * computed skedMobileDriveShiftCalculator.DriveShiftsMetadata. Also includes calculateDriveShiftStaffCapacity
 * and calculateDriveShiftMaxStaffCapacity (used by skedMobileDualRoleGenerator's excess-capacity gate) -
 * both of these, and calculateStaffCapacity itself, are dual-role-aware: a resourceQuantityMap/job entry
 * keyed with a composite "${resourceRole}-${dualRole}" key is handled by splitting off the base role
 * for capacity lookups. Deliberately not handled: ghost-vehicle live tag-matching, volunteer donor
 * ambassador quantities.
 */
public with sharing class skedMobileRoleQuantityCalculator {

    public class RoleQuantity {
        public Decimal quantity = 0;
        // VP/HH is stored as vphhQuantity + aptQuantity; quantity is their derived sum (see calculateVpHhQuantity).
        public Decimal vphhQuantity;
        public Decimal aptQuantity;
        // Only populated by buildResourceQuantityFromJobs (from the job's own fields) - used by
        // calculateStaffCapacity's Driver-Support adhoc-capacity fallback and by
        // skedMobileDriveJobBuilder.recalculateVphhQuantity's capacity-hold gate. Never set by the
        // role-quantity calculators above, which build fresh (never-manually-created) quantities.
        public Boolean isManuallyCreated;
        public String manuallyCreatedFrom;
    }

    private static final String ROLE_DRIVER = 'Driver';
    private static final String ROLE_DRIVER_SUPPORT = 'Driver Support';
    private static final String ROLE_2RBC = '2RBC';
    private static final String ROLE_TEAM_SUPERVISOR = 'Team Supervisor';
    private static final String ROLE_DRIVE_LEAD = 'Drive Lead';
    private static final String ROLE_VPHH = 'VP/HH';
    private static final String ROLE_CHARGE = 'Charge';

    public static sked_Staffing_Decision_Matrix__c loadStaffingDecisionMatrix(Id collectionOperationId, Date driveDate) {
        List<sked_Collection_Operation_SDM__c> matches = [
            SELECT Id, sked_Staffing_Decision_Matrix__r.sked_Driver_Capacity__c, sked_Staffing_Decision_Matrix__r.sked_Driver_Support_Capacity__c,
                sked_Staffing_Decision_Matrix__r.sked_2RBC_Staff_Capacity__c, sked_Staffing_Decision_Matrix__r.sked_Charge_Capacity__c,
                sked_Staffing_Decision_Matrix__r.sked_VP_HH_Capacity__c, sked_Staffing_Decision_Matrix__r.sked_Team_Supervisor_Threshold__c,
                sked_Staffing_Decision_Matrix__r.sked_Charge_Threshold__c
            FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c = :collectionOperationId
                AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :driveDate)
                AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :driveDate)
                AND sked_Staffing_Decision_Matrix__r.RecordType.Name = :skedConstants.DRIVE_TYPE_MOBILE
            LIMIT 1
        ];
        return matches.isEmpty() ? null : matches[0].sked_Staffing_Decision_Matrix__r;
    }

    /**
     * Returns shift key -> role name -> RoleQuantity. Requires shiftsMetadata to already have
     * lunchBreakSettings populated per shift (skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata).
     */
    public static Map<String, Map<String, RoleQuantity>> calculateRoleQuantities(
            sked_Drive__c drive, skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, String physicalLocationType, String timezoneSidId) {
        Map<String, Map<String, RoleQuantity>> resourceQuantityByShiftKey = new Map<String, Map<String, RoleQuantity>>();
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            resourceQuantityByShiftKey.put(shift.key, new Map<String, RoleQuantity>());
        }

        Decimal numberOfVehicles = calculateVehicleQuantity(drive);
        Decimal numberOfEquipments = drive.sked_Number_of_2RBC_Assets__c == null ? 0 : drive.sked_Number_of_2RBC_Assets__c;

        calculateDriverQuantity(shiftsMetadata, resourceQuantityByShiftKey, numberOfVehicles, drive.sked_Do_Not_Use_Vehicle__c, staffingDecisionMatrix);
        calculate2rbcQuantity(shiftsMetadata, resourceQuantityByShiftKey, numberOfEquipments);
        calculateTeamSupervisorQuantity(shiftsMetadata, resourceQuantityByShiftKey, staffingDecisionMatrix, physicalLocationType, drive.sked_IMPACT__c);
        calculateVpHhQuantity(shiftsMetadata, resourceQuantityByShiftKey, staffingDecisionMatrix, drive.sked_Number_of_2RBC_Assets__c, timezoneSidId,
            new List<String>{ ROLE_DRIVER, ROLE_DRIVER_SUPPORT, ROLE_2RBC, ROLE_CHARGE });
        calculateChargeQuantity(shiftsMetadata, resourceQuantityByShiftKey, staffingDecisionMatrix, drive, timezoneSidId);

        return resourceQuantityByShiftKey;
    }

    public static Decimal calculateVehicleQuantity(sked_Drive__c drive) {
        if (drive.sked_Do_Not_Use_Vehicle__c) {
            return 0;
        }
        Decimal numberOfVehicles = drive.sked_Number_of_Vehicles__c != null ? drive.sked_Number_of_Vehicles__c : drive.sked_Total_Vehicle_Requested__c;
        return numberOfVehicles == null ? 0 : numberOfVehicles;
    }

    private static void calculateDriverQuantity(skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, RoleQuantity>> resourceQuantityByShiftKey, Decimal numberOfVehicles, Boolean doNotUseVehicle,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix) {
        Decimal numberOfDrivers = numberOfVehicles;
        if (numberOfDrivers < 1 && !doNotUseVehicle) {
            numberOfDrivers = 1;
        }
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Map<String, RoleQuantity> resourceQuantityMap = resourceQuantityByShiftKey.get(shift.key);
            resourceQuantityMap.put(ROLE_DRIVER, newQuantity(numberOfDrivers));
            if (staffingDecisionMatrix.sked_Driver_Support_Capacity__c != null && staffingDecisionMatrix.sked_Driver_Support_Capacity__c > 0) {
                resourceQuantityMap.put(ROLE_DRIVER_SUPPORT, newQuantity(numberOfDrivers));
            }
        }
    }

    // Public (not private) because wbFixedSiteGenerator.js's own calculate2rbcQuantity is byte-identical
    // to mobileGenerator.js's, so skedFixedSiteWbRoleQuantityCalculator calls this rather than duplicating it.
    public static void calculate2rbcQuantity(skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, RoleQuantity>> resourceQuantityByShiftKey, Decimal numberOfEquipments) {
        Decimal noOf2rbcStaffs = Math.ceil(numberOfEquipments / 2);
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            resourceQuantityByShiftKey.get(shift.key).put(ROLE_2RBC, newQuantity(noOf2rbcStaffs));
        }
    }

    // Public for the same reason as calculate2rbcQuantity above. Both of its non-shiftsMetadata inputs
    // are explicit in WB's own JS (wbFixedSiteGenerator.js:1125-1147 reads driveSite.physicalLocationType
    // and drive.IMPACT identically), so nothing here is Mobile-specific. Callers must null-check the
    // matrix themselves - WB's JS guards it, this method does not.
    public static void calculateTeamSupervisorQuantity(skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, RoleQuantity>> resourceQuantityByShiftKey, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            String physicalLocationType, Boolean isImpact) {
        if (staffingDecisionMatrix.sked_Team_Supervisor_Threshold__c == null) {
            return;
        }
        Decimal threshold = staffingDecisionMatrix.sked_Team_Supervisor_Threshold__c;
        String role = isImpact ? ROLE_DRIVE_LEAD : ROLE_TEAM_SUPERVISOR;
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Decimal noOfTeamSupervisors = 0;
            // 'Inside/Outside' must also qualify - matches the source's String.includes('Inside') substring check.
            if (threshold > 0 && shift.totalProceduresProjected >= threshold
                    && physicalLocationType != null && physicalLocationType.contains('Inside')) {
                noOfTeamSupervisors = 1;
            }
            resourceQuantityByShiftKey.get(shift.key).put(role, newQuantity(noOfTeamSupervisors));
        }
    }

    private static void calculateVpHhQuantity(skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, RoleQuantity>> resourceQuantityByShiftKey, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            Decimal numberOf2rbcAssets, String timezoneSidId, List<String> resourceRoles) {
        if (staffingDecisionMatrix.sked_VP_HH_Capacity__c == null) {
            return;
        }
        Decimal vpHhCapacity = staffingDecisionMatrix.sked_VP_HH_Capacity__c;
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Map<String, RoleQuantity> resourceQuantityMap = resourceQuantityByShiftKey.get(shift.key);
            // null adhocDriverSupportCapacity is safe here - this is the fresh, first-pass role-quantity
            // calc (resourceQuantityMap entries are always built via newQuantity(...), never carrying
            // isManuallyCreated), so the Driver-Support adhoc-capacity fallback's gate can never trigger.
            Decimal staffCapacity = calculateStaffCapacity(resourceRoles, resourceQuantityMap, shift, staffingDecisionMatrix,
                numberOf2rbcAssets, timezoneSidId, false, null);

            Decimal totalVpHhCapacity = shift.donorsScheduled - staffCapacity;
            if (totalVpHhCapacity < 0) {
                totalVpHhCapacity = 0;
            }

            Decimal drawHours = calculateDrawHours(shift, timezoneSidId, shift.lunchBreakSettings);
            Decimal noOfVpHhStaffs = Math.ceil(totalVpHhCapacity / vpHhCapacity / drawHours);

            RoleQuantity vpHh = new RoleQuantity();
            vpHh.vphhQuantity = noOfVpHhStaffs;
            vpHh.aptQuantity = shiftsMetadata.aptSetup;
            vpHh.quantity = noOfVpHhStaffs + (shiftsMetadata.aptSetup == null ? 0 : shiftsMetadata.aptSetup);
            resourceQuantityMap.put(ROLE_VPHH, vpHh);
        }
    }

    // VP/HH is recalculated for ALL shifts on every iteration of this per-shift loop rather than
    // once at the end, since later shifts' Charge values feed earlier shifts' VP/HH recompute and
    // vice versa within the same pass.
    private static void calculateChargeQuantity(skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, RoleQuantity>> resourceQuantityByShiftKey, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            sked_Drive__c drive, String timezoneSidId) {
        if (staffingDecisionMatrix.sked_Charge_Threshold__c == null) {
            return;
        }
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Map<String, RoleQuantity> resourceQuantityMap = resourceQuantityByShiftKey.get(shift.key);
            Decimal noOfDrivers = quantityOrZero(resourceQuantityMap, ROLE_DRIVER);
            Decimal noOfDriverSupports = quantityOrZero(resourceQuantityMap, ROLE_DRIVER_SUPPORT);
            Decimal noOf2rbcStaffs = quantityOrZero(resourceQuantityMap, ROLE_2RBC);
            Decimal noOfTeamSupervisor = quantityOrZero(resourceQuantityMap, ROLE_TEAM_SUPERVISOR);
            Decimal noOfDriveLeads = quantityOrZero(resourceQuantityMap, ROLE_DRIVE_LEAD);
            Decimal noOfVpHhStaffs = resourceQuantityMap.containsKey(ROLE_VPHH) && resourceQuantityMap.get(ROLE_VPHH).vphhQuantity != null
                ? resourceQuantityMap.get(ROLE_VPHH).vphhQuantity : 0;

            Decimal noOfStaffWithoutLeaders = noOfDrivers + noOfDriverSupports + noOf2rbcStaffs + noOfVpHhStaffs;
            Decimal noOfLeaders = Math.ceil(noOfStaffWithoutLeaders / 11);
            Decimal noOfCharges = noOfLeaders - noOfTeamSupervisor - noOfDriveLeads;
            if (noOfCharges < 0) {
                noOfCharges = 0;
            }
            resourceQuantityMap.put(ROLE_CHARGE, newQuantity(noOfCharges));

            calculateVpHhQuantity(shiftsMetadata, resourceQuantityByShiftKey, staffingDecisionMatrix, drive.sked_Number_of_2RBC_Assets__c,
                timezoneSidId, new List<String>{ ROLE_DRIVER, ROLE_DRIVER_SUPPORT, ROLE_2RBC, ROLE_CHARGE });
        }
    }

    private static Decimal quantityOrZero(Map<String, RoleQuantity> resourceQuantityMap, String role) {
        return resourceQuantityMap.containsKey(role) && resourceQuantityMap.get(role).quantity != null ? resourceQuantityMap.get(role).quantity : 0;
    }

    private static RoleQuantity newQuantity(Decimal quantity) {
        RoleQuantity roleQuantity = new RoleQuantity();
        roleQuantity.quantity = quantity;
        return roleQuantity;
    }

    private static final List<String> STAFF_CAPACITY_ROLES = new List<String>{ ROLE_DRIVER, ROLE_DRIVER_SUPPORT, ROLE_2RBC, ROLE_VPHH, ROLE_CHARGE };

    /**
     * Once a shift's own lunch-break fields are populated (see skedMobileLunchBreakCalculator),
     * they take precedence over the freshly computed shift.lunchBreakSettings for this capacity
     * calculation.
     */
    public static Decimal calculateDriveShiftStaffCapacity(List<sked__Job__c> jobs, skedMobileDriveShiftCalculator.DriveShiftMetadata shift,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, Decimal numberOf2rbcAssets, String timezoneSidId,
            Boolean ignoreLunchBreak, Boolean driveShiftLunchBreak, Boolean driveShiftLunchBreakBeforeDrawHours, Decimal adhocDriverSupportCapacity) {
        shift.lunchBreakSettings.lunchBreak = driveShiftLunchBreak;
        shift.lunchBreakSettings.lunchBreakBeforeDrawHours = driveShiftLunchBreakBeforeDrawHours;

        Map<String, RoleQuantity> resourceQuantityMap = buildResourceQuantityFromJobs(jobs);
        Decimal staffCapacity = calculateStaffCapacity(STAFF_CAPACITY_ROLES, resourceQuantityMap, shift, staffingDecisionMatrix,
            numberOf2rbcAssets, timezoneSidId, ignoreLunchBreak, adhocDriverSupportCapacity);
        return Math.floor(staffCapacity);
    }

    // For VP/HH, quantity is always read from vphhQuantity (calculateStaffCapacity below does the
    // same) regardless of what's stored in .quantity here. Builds a composite
    // "${resourceRole}-${dualRole}" key when a job carries a dual role.
    public static Map<String, RoleQuantity> buildResourceQuantityFromJobs(List<sked__Job__c> jobs) {
        Map<String, RoleQuantity> resourceQuantityMap = new Map<String, RoleQuantity>();
        for (sked__Job__c job : jobs) {
            if (String.isBlank(job.sked_Resource_Role__c)) {
                continue;
            }
            RoleQuantity roleQuantity = new RoleQuantity();
            roleQuantity.quantity = job.sked__Quantity__c == null ? 0 : job.sked__Quantity__c;
            roleQuantity.vphhQuantity = job.sked_VPHH_Quantity__c == null ? 0 : job.sked_VPHH_Quantity__c;
            roleQuantity.isManuallyCreated = job.sked_Is_Manually_Created__c;
            roleQuantity.manuallyCreatedFrom = job.sked_Manually_Created_From__c;
            String key = String.isBlank(job.sked_Dual_Role__c) ? job.sked_Resource_Role__c : job.sked_Resource_Role__c + '-' + job.sked_Dual_Role__c;
            resourceQuantityMap.put(key, roleQuantity);
        }
        return resourceQuantityMap;
    }

    public static Decimal calculateStaffCapacity(List<String> resourceRoles, Map<String, RoleQuantity> resourceQuantityMap,
            skedMobileDriveShiftCalculator.DriveShiftMetadata shift, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            Decimal numberOf2rbcAssets, String timezoneSidId, Boolean ignoreLunchBreak, Decimal adhocDriverSupportCapacity) {
        Decimal drawHours = calculateDrawHours(shift, timezoneSidId, shift.lunchBreakSettings);
        Decimal drawHoursWithoutLunchBreak = calculateDrawHours(shift, timezoneSidId, null);
        if (ignoreLunchBreak) {
            drawHours = drawHoursWithoutLunchBreak;
        }

        // Must scan every key's base role (not an exact "2RBC" lookup) - a merged dual-role key like
        // "2RBC-Driver Support" still counts toward 2RBC's asset-backed capacity below.
        Decimal total2RBCResources = 0;
        for (String key : resourceQuantityMap.keySet()) {
            if (key.split('-')[0] == ROLE_2RBC) {
                RoleQuantity data = resourceQuantityMap.get(key);
                total2RBCResources += data.quantity == null ? 0 : data.quantity;
            }
        }
        Decimal noOf2RBCAssets = numberOf2rbcAssets == null ? 0 : numberOf2rbcAssets;
        Decimal resourcesHaveEnough2RBCAssetsCount = Math.min(total2RBCResources, Math.floor(noOf2RBCAssets / 2));
        Decimal resourcesNotHaveEnough2RBCAssetsCount = Math.max(total2RBCResources - resourcesHaveEnough2RBCAssetsCount, 0);

        Decimal staffCapacity = 0;
        for (String resourceRole : resourceQuantityMap.keySet()) {
            // A dual-role entry is keyed "${resourceRole}-${dualRole}" - the base role alone
            // determines both the capacity-list membership and the capacity lookup.
            String baseRole = resourceRole.split('-')[0];
            if (!resourceRoles.contains(baseRole)) {
                continue;
            }
            RoleQuantity data = resourceQuantityMap.get(resourceRole);
            Decimal noOfResources = baseRole == ROLE_VPHH
                ? (data.vphhQuantity == null ? 0 : data.vphhQuantity)
                : (data.quantity == null ? 0 : data.quantity);
            Decimal roleCapacity = getCapacityForRole(staffingDecisionMatrix, baseRole);

            // Ported inline (not inside getCapacityForRole) so calculateMaximumStaffCapacity - a
            // different JS function entirely, sharing only getCapacityForRole - never picks up this
            // fallback; the source itself only applies it inside calculateStaffCapacity.
            if (baseRole == ROLE_DRIVER_SUPPORT && roleCapacity <= 0 && data.isManuallyCreated == true
                    && data.manuallyCreatedFrom != skedMobileDriveJobBuilder.MANUALLY_CREATED_FROM_STAFFING_MODAL) {
                roleCapacity = adhocDriverSupportCapacity == null ? 0 : adhocDriverSupportCapacity;
            }

            if (baseRole == ROLE_2RBC) {
                Decimal noOfResourcesHaveEnough = Math.min(noOfResources, resourcesHaveEnough2RBCAssetsCount);
                Decimal noOfResourcesNotHaveEnough = Math.min(noOfResources - noOfResourcesHaveEnough, resourcesNotHaveEnough2RBCAssetsCount);
                Decimal capacity1 = noOfResourcesHaveEnough * 2 * drawHoursWithoutLunchBreak;
                Decimal capacity2 = noOfResourcesNotHaveEnough * roleCapacity * drawHoursWithoutLunchBreak;
                staffCapacity += capacity1 + capacity2;
                resourcesHaveEnough2RBCAssetsCount -= noOfResourcesHaveEnough;
                resourcesNotHaveEnough2RBCAssetsCount -= noOfResourcesNotHaveEnough;
            } else {
                staffCapacity += noOfResources * roleCapacity * drawHours;
            }
        }
        return staffCapacity;
    }

    /**
     * NOT the same calculation as calculateStaffCapacity above (no quantities or draw hours; just the
     * single largest per-unit role-capacity rate among the roles present). Used by
     * skedMobileDualRoleGenerator's excess-capacity gate.
     */
    public static Decimal calculateDriveShiftMaxStaffCapacity(List<sked__Job__c> jobs, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix) {
        return calculateMaximumStaffCapacity(STAFF_CAPACITY_ROLES, buildResourceQuantityFromJobs(jobs), staffingDecisionMatrix);
    }

    public static Decimal calculateMaximumStaffCapacity(List<String> resourceRoles, Map<String, RoleQuantity> resourceQuantityMap,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix) {
        Decimal maxStaffCapacity = 0;
        for (String resourceRole : resourceQuantityMap.keySet()) {
            String baseRole = resourceRole.split('-')[0];
            if (!resourceRoles.contains(baseRole)) {
                continue;
            }
            Decimal roleCapacity = getCapacityForRole(staffingDecisionMatrix, baseRole);
            if (roleCapacity > maxStaffCapacity) {
                maxStaffCapacity = roleCapacity;
            }
        }
        return maxStaffCapacity;
    }

    public static Decimal getCapacityForRole(sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, String role) {
        Decimal capacity;
        if (role == ROLE_DRIVER) {
            capacity = staffingDecisionMatrix.sked_Driver_Capacity__c;
        } else if (role == ROLE_DRIVER_SUPPORT) {
            capacity = staffingDecisionMatrix.sked_Driver_Support_Capacity__c;
        } else if (role == ROLE_2RBC) {
            capacity = staffingDecisionMatrix.sked_2RBC_Staff_Capacity__c;
        } else if (role == ROLE_CHARGE) {
            capacity = staffingDecisionMatrix.sked_Charge_Capacity__c;
        } else if (role == ROLE_VPHH) {
            capacity = staffingDecisionMatrix.sked_VP_HH_Capacity__c;
        }
        return capacity == null ? 0 : capacity;
    }

    // Uses the shift's own freshly computed lunchBreakSettings, with no override (that only exists
    // inside calculateStaffCapacity's own callers, e.g. skedMobileDriveJobBuilder.calculateDriveShiftStaffCapacity).
    public static Decimal calculateShiftDrawHours(skedMobileDriveShiftCalculator.DriveShiftMetadata shift, String timezoneSidId) {
        return calculateDrawHours(shift, timezoneSidId, shift.lunchBreakSettings);
    }

    private static Decimal calculateDrawHours(skedMobileDriveShiftCalculator.DriveShiftMetadata shift, String timezoneSidId,
            skedLunchBreakSettings lunchBreakSettings) {
        return skedMobileDriveShiftCalculator.calculateDrawHoursInMinutes(shift.driveDate, shift.startTime, shift.endTime, timezoneSidId, lunchBreakSettings) / 60.0;
    }
}
