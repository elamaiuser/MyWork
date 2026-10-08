/**
 * Ported only from fixedSiteGenerator.js's calculateResourceQuantity chain - asset counts
 * (Vehicle/2RBC Equipment) and the 2 quantifiable Fixed Site staff roles (Apheresis, Apheresis
 * Charge), given an already computed skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata.
 * Volunteer Donor Ambassador quantity is deliberately not handled here (see the plan's Global
 * Constraints) - same exclusion Mobile's own role-quantity calculator already makes.
 */
public with sharing class skedFixedSiteRoleQuantityCalculator {

    public class RoleQuantity {
        public Decimal quantity = 0;
    }

    public class MasterData {
        public String timezoneSidId;
        public sked_Staffing_Decision_Matrix__c staffingDecisionMatrix;
        public List<sked_Fixed_Site_Procedure_Projection__c> fixedSiteProcedureProjections = new List<sked_Fixed_Site_Procedure_Projection__c>();
        public Boolean skipLastAppointmentForFixedSite = false;
    }

    private static final String ROLE_APHERESIS = 'Apheresis';
    private static final String ROLE_APHERESIS_CHARGE = 'Apheresis Charge';
    private static final String ASSET_TYPE_VEHICLE_QUANTITY = 'Vehicle';
    private static final String ASSET_TYPE_2RBC_EQUIPMENT_QUANTITY = 'Equipment - 2RBC Asset';

    /**
     * @param drive Caller must have queried: sked_Collection_Operation__c, sked_Drive_Date__c, sked_Account__c.
     */
    public static MasterData loadMasterData(sked_Drive__c drive) {
        MasterData masterData = new MasterData();
        masterData.timezoneSidId = UserInfo.getTimeZone().getID();

        List<sked_Collection_Operation_SDM__c> sdmMatches = [
            SELECT Id, sked_Staffing_Decision_Matrix__r.sked_Platelet_Round_Capacity__c, sked_Staffing_Decision_Matrix__r.sked_Plasma_Hourly_Capacity__c,
                sked_Staffing_Decision_Matrix__r.sked_WB_Hourly_Capacity__c, sked_Staffing_Decision_Matrix__r.sked_2RBC_Hourly_Capacity__c
            FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c = :drive.sked_Collection_Operation__c
                AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
                AND sked_Staffing_Decision_Matrix__r.RecordType.Name = :skedConstants.DRIVE_TYPE_FIXED_SITE
            LIMIT 1
        ];
        masterData.staffingDecisionMatrix = sdmMatches.isEmpty() ? null : sdmMatches[0].sked_Staffing_Decision_Matrix__r;

        masterData.fixedSiteProcedureProjections = [
            SELECT Id, sked_Procedure_Type__c, sked_QNS__c, sked_Deferral__c
            FROM sked_Fixed_Site_Procedure_Projection__c
            WHERE sked_Account__c = :drive.sked_Account__c
                AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
        ];

        Biomed_Collection_Op_Center__c collectionOperation = [
            SELECT Id, sked_Skip_Last_Appointment_For__c FROM Biomed_Collection_Op_Center__c WHERE Id = :drive.sked_Collection_Operation__c
        ];
        masterData.skipLastAppointmentForFixedSite = collectionOperation.sked_Skip_Last_Appointment_For__c != null
            && collectionOperation.sked_Skip_Last_Appointment_For__c.contains(skedConstants.DRIVE_TYPE_FIXED_SITE);

        return masterData;
    }

    // mapAssetQuantity is drive-level in the JS (fixedSiteGenerator.js:997-1015), not per-shift -
    // returned separately from calculateRoleQuantities' per-shift staff map, matching that structure.
    /**
     * @param drive Caller must have queried: sked_Operation_Type__c, sked_Number_of_Vehicles__c, sked_Number_of_2RBC_Assets__c.
     */
    public static Map<String, Decimal> calculateAssetQuantity(sked_Drive__c drive) {
        Map<String, Decimal> assetQuantityByType = new Map<String, Decimal>();
        assetQuantityByType.put(ASSET_TYPE_VEHICLE_QUANTITY, drive.sked_Number_of_Vehicles__c == null ? 0 : drive.sked_Number_of_Vehicles__c);
        // Fixed Site's own Platelet/Plasma equipment-quantity block is commented out in fixedSiteGenerator.js:1008-1014 - not ported, matching the live (inactive) JS behavior.
        if (drive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_INTEGRATED) {
            assetQuantityByType.put(ASSET_TYPE_2RBC_EQUIPMENT_QUANTITY, drive.sked_Number_of_2RBC_Assets__c == null ? 0 : drive.sked_Number_of_2RBC_Assets__c);
        }
        return assetQuantityByType;
    }

    /**
     * @param drive Caller must have queried: sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Operation_Type__c,
     * sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c.
     */
    public static Map<String, Map<String, RoleQuantity>> calculateRoleQuantities(sked_Drive__c drive,
            skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, MasterData masterData) {
        Map<String, Map<String, RoleQuantity>> resourceQuantityByShiftKey = new Map<String, Map<String, RoleQuantity>>();

        Decimal totalApheresisStaff = calculateApheresisStaffQuantity(drive, shiftsMetadata, masterData);
        // Math.round(Double) is half-up like JS's Math.round; Decimal.round() defaults to half-even and would silently diverge.
        Long apheresisQuantity = Math.round(totalApheresisStaff.doubleValue());
        for (skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Map<String, RoleQuantity> roleQuantityByRole = new Map<String, RoleQuantity>();
            roleQuantityByRole.put(ROLE_APHERESIS, newQuantity(apheresisQuantity));
            // calculateApheresisChargeQuantity (fixedSiteGenerator.js:1062-1070) has no null-date guard - Charge is always 1 on every shift.
            roleQuantityByRole.put(ROLE_APHERESIS_CHARGE, newQuantity(1));
            resourceQuantityByShiftKey.put(shift.key, roleQuantityByRole);
        }

        return resourceQuantityByShiftKey;
    }

    private static Decimal calculateApheresisStaffQuantity(sked_Drive__c drive,
            skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, MasterData masterData) {
        // Guard ported from fixedSiteGenerator.js:1018 - only calculateApheresisStaffQuantity is gated on the drive
        // having a date/time window; calculateApheresisChargeQuantity has no equivalent guard (see calculateRoleQuantities).
        if (drive.sked_Drive_Date__c == null || drive.sked_Start_Time__c == null || drive.sked_End_Time__c == null) {
            return 0;
        }

        Decimal totalApheresisStaff = 0;

        Decimal plateletProcedureProjected = getProjectedProceduresByProcedureType(drive, skedConstants.PROCEDURE_TYPE_PLATELET);
        Decimal plateletRoundCapacity = getFixedSiteProcedureTypeCapacity(skedConstants.PROCEDURE_TYPE_PLATELET, masterData);
        Integer plateletRounds = 0;
        for (skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            plateletRounds += shift.numberOfRounds;
        }
        // Deliberate Apex-only guard (see Global Constraints) - the JS's own guard here is a near-total
        // no-op and would silently divide by zero into NaN; Apex throws instead, so guard explicitly.
        if (plateletRounds > 0 && plateletRoundCapacity > 0) {
            totalApheresisStaff = plateletProcedureProjected / plateletRounds / plateletRoundCapacity;
        }

        for (sked_Fixed_Site_Procedure_Projection__c setting : masterData.fixedSiteProcedureProjections) {
            String procedureType = setting.sked_Procedure_Type__c;
            Decimal noOfStaff = calculateNonPlateletStaffCount(drive, masterData, setting, procedureType);

            Boolean isResourceRoleApplied =
                (drive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_INTEGRATED
                    && (procedureType == skedConstants.PROCEDURE_TYPE_WB || procedureType == skedConstants.PROCEDURE_TYPE_2RBC))
                || ((drive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_INTEGRATED || drive.sked_Operation_Type__c == skedConstants.OPERATION_TYPE_APH)
                    && (procedureType == skedConstants.PROCEDURE_TYPE_PLATELET || procedureType == skedConstants.PROCEDURE_TYPE_PLASMA));
            if (isResourceRoleApplied) {
                totalApheresisStaff += noOfStaff;
            }
        }

        return totalApheresisStaff;
    }

    // Platelet is calculated separately above (fixedSiteGenerator.js:1037's "!== PLATELET" guard) - a
    // Platelet setting always contributes 0 here, regardless of isResourceRoleApplied's gating.
    private static Decimal calculateNonPlateletStaffCount(sked_Drive__c drive, MasterData masterData,
            sked_Fixed_Site_Procedure_Projection__c setting, String procedureType) {
        if (procedureType == skedConstants.PROCEDURE_TYPE_PLATELET) {
            return 0;
        }
        Decimal procedureTypeCapacity = getFixedSiteProcedureTypeCapacity(procedureType, masterData);
        Decimal drawHoursInMinutes = getDrawHoursInMinutesByProcedureType(drive, procedureType, masterData);
        Decimal projectedProcedures = getProjectedProceduresByProcedureType(drive, procedureType);
        Decimal qns = setting.sked_QNS__c == null ? 0 : setting.sked_QNS__c;
        Decimal deferral = setting.sked_Deferral__c == null ? 0 : setting.sked_Deferral__c;
        Decimal qnsFactor = 1 - qns / 100;
        Decimal deferralFactor = 1 - deferral / 100;

        // Real guard, ported from fixedSiteGenerator.js:1041 (isNaN/!isFinite reset to 0) - Apex has no
        // NaN/Infinity for Decimal, so guard every denominator explicitly instead. Using <= 0 (rather than
        // strictly mirroring isNaN/!isFinite) is a deliberate safety improvement, not an accidental divergence:
        // it also zeroes out genuinely invalid input (QNS/deferral over 100%, negative capacity) that the JS's
        // own guard would let through as a finite negative contribution.
        if (qnsFactor <= 0 || deferralFactor <= 0 || drawHoursInMinutes <= 0 || procedureTypeCapacity <= 0) {
            return 0;
        }
        return projectedProcedures / qnsFactor / deferralFactor / (drawHoursInMinutes / 60) / procedureTypeCapacity;
    }

    private static Decimal getFixedSiteProcedureTypeCapacity(String procedureType, MasterData masterData) {
        if (masterData.staffingDecisionMatrix == null) {
            return 0;
        }
        if (procedureType == skedConstants.PROCEDURE_TYPE_PLATELET) {
            return masterData.staffingDecisionMatrix.sked_Platelet_Round_Capacity__c == null ? 0 : masterData.staffingDecisionMatrix.sked_Platelet_Round_Capacity__c;
        }
        if (procedureType == skedConstants.PROCEDURE_TYPE_PLASMA) {
            return masterData.staffingDecisionMatrix.sked_Plasma_Hourly_Capacity__c == null ? 0 : masterData.staffingDecisionMatrix.sked_Plasma_Hourly_Capacity__c;
        }
        if (procedureType == skedConstants.PROCEDURE_TYPE_WB) {
            return masterData.staffingDecisionMatrix.sked_WB_Hourly_Capacity__c == null ? 0 : masterData.staffingDecisionMatrix.sked_WB_Hourly_Capacity__c;
        }
        if (procedureType == skedConstants.PROCEDURE_TYPE_2RBC) {
            return masterData.staffingDecisionMatrix.sked_2RBC_Hourly_Capacity__c == null ? 0 : masterData.staffingDecisionMatrix.sked_2RBC_Hourly_Capacity__c;
        }
        return 0;
    }

    private static Decimal getProjectedProceduresByProcedureType(sked_Drive__c drive, String procedureType) {
        if (procedureType == skedConstants.PROCEDURE_TYPE_PLATELET) {
            return drive.sked_Platelet_Projected_Procedures__c == null ? 0 : drive.sked_Platelet_Projected_Procedures__c;
        }
        if (procedureType == skedConstants.PROCEDURE_TYPE_PLASMA) {
            return drive.sked_Plasma_Projected_Procedures__c == null ? 0 : drive.sked_Plasma_Projected_Procedures__c;
        }
        if (procedureType == skedConstants.PROCEDURE_TYPE_WB) {
            return drive.sked_WB_Projected_Procedures__c == null ? 0 : drive.sked_WB_Projected_Procedures__c;
        }
        if (procedureType == skedConstants.PROCEDURE_TYPE_2RBC) {
            return drive.sked_2RBC_Projected_Procedures__c == null ? 0 : drive.sked_2RBC_Projected_Procedures__c;
        }
        return 0;
    }

    // Drive-level time window, offset per procedure type (helper.js:2214-2252) - not per-shift.
    private static Decimal getDrawHoursInMinutesByProcedureType(sked_Drive__c drive, String procedureType, MasterData masterData) {
        DateTime driveStart = skedDateTimeUtils.getDateTimeFromDateAndTime(drive.sked_Drive_Date__c, drive.sked_Start_Time__c, masterData.timezoneSidId);
        DateTime driveEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(drive.sked_Drive_Date__c, drive.sked_End_Time__c, masterData.timezoneSidId);

        if (procedureType == skedConstants.PROCEDURE_TYPE_PLASMA) {
            driveStart = skedDateTimeUtils.addMinutes(driveStart, 60, masterData.timezoneSidId);
            driveEnd = skedDateTimeUtils.addMinutes(driveEnd, -50, masterData.timezoneSidId);
        } else if (procedureType == skedConstants.PROCEDURE_TYPE_WB) {
            driveStart = skedDateTimeUtils.addMinutes(driveStart, 60, masterData.timezoneSidId);
            if (masterData.skipLastAppointmentForFixedSite) {
                driveEnd = skedDateTimeUtils.addMinutes(driveEnd, -15, masterData.timezoneSidId);
            }
        } else if (procedureType == skedConstants.PROCEDURE_TYPE_2RBC) {
            driveStart = skedDateTimeUtils.addMinutes(driveStart, 60, masterData.timezoneSidId);
            driveEnd = skedDateTimeUtils.addMinutes(driveEnd, -30, masterData.timezoneSidId);
        }

        Long durationInMinutes = (driveEnd.getTime() - driveStart.getTime()) / 60000;
        return durationInMinutes < 0 ? 0 : durationInMinutes;
    }

    private static RoleQuantity newQuantity(Decimal quantity) {
        RoleQuantity roleQuantity = new RoleQuantity();
        roleQuantity.quantity = quantity;
        return roleQuantity;
    }
}
