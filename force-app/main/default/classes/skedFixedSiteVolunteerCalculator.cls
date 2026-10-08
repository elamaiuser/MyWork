/**
 * Ported only from fixedSiteGenerator.js's calculateVolunteerDonorAmbassadors - Fixed Site's
 * volunteer/Donor Ambassador sizing, deliberately kept out of skedFixedSiteRoleQuantityCalculator
 * (which explicitly excludes it, matching Mobile's own skedMobileRoleQuantityCalculator). Returns
 * a shift-key -> quantity map for a single role ('Donor Ambassador') - no role-name nesting, since
 * Fixed Site has exactly one volunteer role today.
 */
public with sharing class skedFixedSiteVolunteerCalculator {

    private static final Integer BAND_LOW_QUANTITY = 0;
    private static final Integer BAND_MID_QUANTITY = 1;
    private static final Integer BAND_HIGH_QUANTITY = 2;

    public class MasterData {
        public sked_Staffing_Decision_Matrix__c staffingDecisionMatrix;
    }

    // Requires drive to be queried with sked_Collection_Operation__c, sked_Drive_Date__c.
    public static MasterData loadMasterData(sked_Drive__c drive) {
        MasterData masterData = new MasterData();
        List<sked_Collection_Operation_SDM__c> sdmMatches = [
            SELECT Id, sked_Staffing_Decision_Matrix__r.sked_NR_Volunteer_Fixed_Site_Band_Lower__c,
                sked_Staffing_Decision_Matrix__r.sked_NR_Volunteer_Fixed_Site_Band_Upper__c
            FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c = :drive.sked_Collection_Operation__c
                AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
                AND sked_Staffing_Decision_Matrix__r.RecordType.Name = :skedConstants.DRIVE_TYPE_FIXED_SITE
            LIMIT 1
        ];
        masterData.staffingDecisionMatrix = sdmMatches.isEmpty() ? null : sdmMatches[0].sked_Staffing_Decision_Matrix__r;
        return masterData;
    }

    public static Map<String, Integer> calculateVolunteerQuantities(
            skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, MasterData masterData, String timezoneSidId) {
        Map<String, Integer> volunteerQuantityByShiftKey = new Map<String, Integer>();
        if (masterData.staffingDecisionMatrix == null) {
            return volunteerQuantityByShiftKey;
        }

        Decimal bandLower = masterData.staffingDecisionMatrix.sked_NR_Volunteer_Fixed_Site_Band_Lower__c;
        Decimal bandUpper = masterData.staffingDecisionMatrix.sked_NR_Volunteer_Fixed_Site_Band_Upper__c;

        for (skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Decimal drawHours = calculateDrawHours(shift, timezoneSidId);
            if (drawHours <= 0) {
                continue;
            }
            // A null band is a deliberate 0-volunteer divergence from the JS's undefined-comparison
            // fallthrough (which lands on 2, almost certainly unintentionally) - HRP-10153.
            if (bandLower == null || bandUpper == null) {
                volunteerQuantityByShiftKey.put(shift.key, BAND_LOW_QUANTITY);
                continue;
            }

            Decimal totalProceduresProjected = shift.totalProceduresProjected;
            Integer quantity;
            if (totalProceduresProjected < bandLower) {
                quantity = BAND_LOW_QUANTITY;
            } else if (totalProceduresProjected <= bandUpper) {
                quantity = BAND_MID_QUANTITY;
            } else {
                quantity = BAND_HIGH_QUANTITY;
            }
            volunteerQuantityByShiftKey.put(shift.key, quantity);
        }

        return volunteerQuantityByShiftKey;
    }

    // Ported from helper.js:1857-1882's calculateDrawHours/calculateDrawHoursInMinutes, called here
    // with no lunchBreakSettings argument (fixedSiteGenerator.js:1076 passes none) - no lunch subtraction.
    private static Decimal calculateDrawHours(skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shift, String timezoneSidId) {
        if (shift.driveDate == null || shift.startTime == null || shift.endTime == null) {
            return 0;
        }
        DateTime startDateTime = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.startTime, timezoneSidId);
        DateTime endDateTime = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.driveDate, shift.endTime, timezoneSidId);
        return (endDateTime.getTime() - startDateTime.getTime()) / 60000.0 / 60;
    }
}
