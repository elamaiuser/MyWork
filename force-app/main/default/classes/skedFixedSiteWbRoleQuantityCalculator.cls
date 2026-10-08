/**
 * Staff role quantities for Fixed Site WB (Non Integrated WB) drives, ported from
 * wbFixedSiteGenerator.js's calculateResourceQuantity chain (wb:1011) - equipment count, then
 * 2RBC -> Team Supervisor -> VP/HH -> Charge. WB has no driver quantity, no vehicle quantity, no
 * ghost-vehicle calculation and no dual-role generation, so the returned map is keyed by plain
 * resourceRole, never Mobile's composite "${resourceRole}-${dualRole}" job key.
 *
 * 2RBC and Team Supervisor delegate to skedMobileRoleQuantityCalculator (byte-identical JS bodies);
 * all capacity/draw-hour math delegates to that class's public primitives. VP/HH and Charge are
 * WB-owned - see their own comments for the three deltas from Mobile.
 *
 * Volunteer Donor Ambassador quantity is deliberately not handled here even though WB's JS computes
 * it inside the same calculateResourceQuantity method - it is a separate WB-owned algorithm
 * (skedFixedSiteWbVolunteerCalculator).
 *
 * calculateDriveShiftMaxStaffCapacity is not redefined here: WB's role list (wb:785-793) is identical
 * to Mobile's, so skedMobileRoleQuantityCalculator.calculateDriveShiftMaxStaffCapacity already is
 * WB's. That list still carries 'Driver'/'Driver Support' while WB's calculateDriveShiftStaffCapacity
 * and countDriveShiftStaffs dropped them - inert (WB never creates those jobs) but preserved as the
 * source's behavior, not corrected.
 */
public with sharing class skedFixedSiteWbRoleQuantityCalculator {

    private static final String ROLE_2RBC = '2RBC';
    private static final String ROLE_TEAM_SUPERVISOR = 'Team Supervisor';
    private static final String ROLE_DRIVE_LEAD = 'Drive Lead';
    private static final String ROLE_VPHH = 'VP/HH';
    private static final String ROLE_CHARGE = 'Charge';

    private static final Decimal STAFF_PER_LEADER = 11;
    private static final Decimal APT_QUANTITY_WHEN_REQUIRED = 1;

    // wbFixedSiteGenerator.js:1148 - Mobile's equivalent list also carries Driver/Driver Support.
    private static final List<String> VPHH_CAPACITY_ROLES = new List<String>{ ROLE_2RBC, ROLE_CHARGE };
    // wbFixedSiteGenerator.js:769-778.
    private static final List<String> SHIFT_STAFF_CAPACITY_ROLES = new List<String>{ ROLE_2RBC, ROLE_VPHH, ROLE_CHARGE };

    /**
     * Drive-level equipment count (wbFixedSiteGenerator.js:1107, byte-identical to Mobile's).
     * @param drive Caller must have queried: sked_Number_of_2RBC_Assets__c.
     */
    public static Decimal calculateEquipmentQuantity(sked_Drive__c drive) {
        return drive.sked_Number_of_2RBC_Assets__c == null ? 0 : drive.sked_Number_of_2RBC_Assets__c;
    }

    /**
     * Returns shift key -> plain resourceRole -> RoleQuantity. Requires shiftsMetadata to already have
     * lunchBreakSettings populated per shift.
     *
     * @param drive Caller must have queried: sked_Number_of_2RBC_Assets__c, sked_IMPACT__c, sked_APT_Required__c.
     * @param staffingDecisionMatrix The Mobile-record-type matrix. WB's own Fetch is constructed with
     * driveType Mobile (wbFixedSiteGenerator.js:286-288), so its SDM query filters on RecordType.Name
     * 'Mobile' exactly like Mobile's - use skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix.
     * May be null, in which case only 2RBC is calculated (matching WB's three per-role null guards).
     */
    public static Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> calculateRoleQuantities(
            sked_Drive__c drive, skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, String physicalLocationType, String timezoneSidId) {
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> resourceQuantityByShiftKey =
            new Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>>();
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            resourceQuantityByShiftKey.put(shift.key, new Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>());
        }

        skedMobileRoleQuantityCalculator.calculate2rbcQuantity(shiftsMetadata, resourceQuantityByShiftKey, calculateEquipmentQuantity(drive));

        // Team Supervisor, VP/HH and Charge each guard on a null matrix in the JS; 2RBC above does not.
        if (staffingDecisionMatrix == null) {
            return resourceQuantityByShiftKey;
        }

        skedMobileRoleQuantityCalculator.calculateTeamSupervisorQuantity(shiftsMetadata, resourceQuantityByShiftKey,
            staffingDecisionMatrix, physicalLocationType, drive.sked_IMPACT__c);
        calculateVpHhQuantity(drive, shiftsMetadata, resourceQuantityByShiftKey, staffingDecisionMatrix, timezoneSidId);
        calculateChargeQuantity(drive, shiftsMetadata, resourceQuantityByShiftKey, staffingDecisionMatrix, timezoneSidId);

        return resourceQuantityByShiftKey;
    }

    /**
     * Per-shift staff capacity over WB's own role list (no Driver/Driver Support).
     * Signature mirrors skedMobileRoleQuantityCalculator.calculateDriveShiftStaffCapacity so the WB
     * job builder can substitute this call. adhocDriverSupportCapacity is inert for WB's role list.
     */
    public static Decimal calculateDriveShiftStaffCapacity(List<sked__Job__c> jobs, skedMobileDriveShiftCalculator.DriveShiftMetadata shift,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, Decimal numberOf2rbcAssets, String timezoneSidId,
            Boolean ignoreLunchBreak, Boolean driveShiftLunchBreak, Boolean driveShiftLunchBreakBeforeDrawHours, Decimal adhocDriverSupportCapacity) {
        shift.lunchBreakSettings.lunchBreak = driveShiftLunchBreak;
        shift.lunchBreakSettings.lunchBreakBeforeDrawHours = driveShiftLunchBreakBeforeDrawHours;

        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap =
            skedMobileRoleQuantityCalculator.buildResourceQuantityFromJobs(jobs);
        Decimal staffCapacity = skedMobileRoleQuantityCalculator.calculateStaffCapacity(SHIFT_STAFF_CAPACITY_ROLES, resourceQuantityMap,
            shift, staffingDecisionMatrix, numberOf2rbcAssets, timezoneSidId, ignoreLunchBreak, adhocDriverSupportCapacity);
        return Math.floor(staffCapacity);
    }

    // Three deltas from Mobile's calculateVpHhQuantity (wbFixedSiteGenerator.js:1148-1181): the role
    // list excludes Driver/Driver Support, the capacity shortfall is rounded UP before being divided,
    // and the APT component comes from the drive's own APT Required flag - WB has no APT
    // recalculation and no driveShiftsMetadata.APTSetup.
    private static void calculateVpHhQuantity(sked_Drive__c drive, skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> resourceQuantityByShiftKey,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, String timezoneSidId) {
        if (staffingDecisionMatrix.sked_VP_HH_Capacity__c == null) {
            return;
        }
        Decimal vpHhCapacity = staffingDecisionMatrix.sked_VP_HH_Capacity__c;
        Decimal aptQuantity = drive.sked_APT_Required__c == true ? APT_QUANTITY_WHEN_REQUIRED : 0;

        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap = resourceQuantityByShiftKey.get(shift.key);
            // adhocDriverSupportCapacity is null-safe here: Driver Support is not in VPHH_CAPACITY_ROLES,
            // so its capacity fallback is unreachable on this path.
            Decimal staffCapacity = skedMobileRoleQuantityCalculator.calculateStaffCapacity(VPHH_CAPACITY_ROLES, resourceQuantityMap,
                shift, staffingDecisionMatrix, drive.sked_Number_of_2RBC_Assets__c, timezoneSidId, false, null);

            Decimal totalVpHhCapacity = (shift.donorsScheduled - staffCapacity).setScale(0, System.RoundingMode.CEILING);
            if (totalVpHhCapacity < 0) {
                totalVpHhCapacity = 0;
            }

            Decimal drawHours = skedMobileRoleQuantityCalculator.calculateShiftDrawHours(shift, timezoneSidId);
            // Apex-only guard: the JS divides by zero into Infinity and ceils it, Apex would throw.
            Decimal noOfVpHhStaffs = (drawHours <= 0 || vpHhCapacity <= 0)
                ? 0 : Math.ceil(totalVpHhCapacity / vpHhCapacity / drawHours);

            skedMobileRoleQuantityCalculator.RoleQuantity vpHh = new skedMobileRoleQuantityCalculator.RoleQuantity();
            vpHh.vphhQuantity = noOfVpHhStaffs;
            vpHh.aptQuantity = aptQuantity;
            // WB's JS stores only the two components here and derives the job's quantity at population
            // time (wbFixedSiteGenerator.js:1497); populated eagerly so downstream reads .quantity uniformly.
            vpHh.quantity = noOfVpHhStaffs + aptQuantity;
            resourceQuantityMap.put(ROLE_VPHH, vpHh);
        }
    }

    // Delta from Mobile's calculateChargeQuantity (wbFixedSiteGenerator.js:1255-1285): the leader count
    // sums only 2RBC + VP/HH, where Mobile also adds Driver + Driver Support. VP/HH is recalculated for
    // ALL shifts on every iteration of this per-shift loop - redundant, since shifts never influence each
    // other's capacity, but kept to mirror the source's structure.
    private static void calculateChargeQuantity(sked_Drive__c drive, skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> resourceQuantityByShiftKey,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, String timezoneSidId) {
        if (staffingDecisionMatrix.sked_Charge_Threshold__c == null) {
            return;
        }
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap = resourceQuantityByShiftKey.get(shift.key);
            Decimal noOf2rbcStaffs = quantityOrZero(resourceQuantityMap, ROLE_2RBC);
            Decimal noOfTeamSupervisor = quantityOrZero(resourceQuantityMap, ROLE_TEAM_SUPERVISOR);
            Decimal noOfDriveLeads = quantityOrZero(resourceQuantityMap, ROLE_DRIVE_LEAD);
            Decimal noOfVpHhStaffs = vphhQuantityOrZero(resourceQuantityMap);

            Decimal noOfStaffWithoutLeaders = noOf2rbcStaffs + noOfVpHhStaffs;
            Decimal noOfLeaders = Math.ceil(noOfStaffWithoutLeaders / STAFF_PER_LEADER);
            Decimal noOfCharges = noOfLeaders - noOfTeamSupervisor - noOfDriveLeads;
            if (noOfCharges < 0) {
                noOfCharges = 0;
            }
            skedMobileRoleQuantityCalculator.RoleQuantity charge = new skedMobileRoleQuantityCalculator.RoleQuantity();
            charge.quantity = noOfCharges;
            resourceQuantityMap.put(ROLE_CHARGE, charge);

            calculateVpHhQuantity(drive, shiftsMetadata, resourceQuantityByShiftKey, staffingDecisionMatrix, timezoneSidId);
        }
    }

    // containsKey guards are an Apex-only deviation: WB's JS destructures resourceQuantityMap.get('VP/HH')
    // unguarded (wb:1265) and throws when a null VP/HH capacity left the role unset.
    private static Decimal quantityOrZero(Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap, String role) {
        return resourceQuantityMap.containsKey(role) && resourceQuantityMap.get(role).quantity != null
            ? resourceQuantityMap.get(role).quantity : 0;
    }

    private static Decimal vphhQuantityOrZero(Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap) {
        return resourceQuantityMap.containsKey(ROLE_VPHH) && resourceQuantityMap.get(ROLE_VPHH).vphhQuantity != null
            ? resourceQuantityMap.get(ROLE_VPHH).vphhQuantity : 0;
    }
}
