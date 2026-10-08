/**
 * Ported only from wbFixedSiteGenerator.js:1287-1308's calculateVolunteerDonorAmbassadors - the
 * Fixed Site WB Donor Ambassador sizing, which is a third algorithm distinct from both
 * skedMobileVolunteerCalculator (drive-level, gated, high-school-aware) and
 * skedFixedSiteVolunteerCalculator (per-shift SDM band). Neither of those computes this.
 *
 * Deliberately absent, matching the source exactly: no Max_Anticipated_Registered_Donors__c upper
 * bound, no High_School_Drive__c branch, no sked_Redcross_Volunteer_Required__c gate, no
 * skipVolunteerRecalculation gate, no over-max recursion.
 *
 * The matrix arrives as a parameter because custom metadata records cannot be inserted in tests.
 */
public with sharing class skedFixedSiteWbVolunteerCalculator {

    private static final Integer NO_VOLUNTEERS = 0;

    /**
     * Donor Ambassador quantity per drive shift, keyed by shift key.
     *
     * @param siteOperationType the Operation Type of the drive's Site, not of the drive itself
     */
    public static Map<String, Integer> calculateVolunteerQuantities(
            List<String> shiftKeys,
            String typeOfDrive,
            String siteOperationType,
            Decimal projectedRegisteredDonors,
            List<Volunteer_Staffing_Matrix__mdt> volunteerMatrix) {
        Map<String, Integer> quantityByShiftKey = new Map<String, Integer>();
        // Only a null matrix short-circuits (wb:1289). An empty list is truthy in JS, so it falls
        // through and writes a zero for every shift - do not collapse this into an isEmpty() check.
        if (shiftKeys == null || volunteerMatrix == null) {
            return quantityByShiftKey;
        }

        Integer quantity = findHighestBandQuantity(typeOfDrive, siteOperationType, projectedRegisteredDonors, volunteerMatrix);
        // The source feeds a drive-level donor count into a per-shift map, so every shift deliberately
        // receives the same number (wbFixedSiteGenerator.js:1295) - not per-shift donorsScheduled.
        for (String shiftKey : shiftKeys) {
            quantityByShiftKey.put(shiftKey, quantity);
        }
        return quantityByShiftKey;
    }

    private static Integer findHighestBandQuantity(String typeOfDrive, String siteOperationType,
            Decimal projectedRegisteredDonors, List<Volunteer_Staffing_Matrix__mdt> volunteerMatrix) {
        // The JS compares each band minimum against an undefined donor count, which is false for every
        // band - so an unprojected drive matches nothing rather than falling into the zero-minimum band.
        if (projectedRegisteredDonors == null) {
            return NO_VOLUNTEERS;
        }

        Volunteer_Staffing_Matrix__mdt matchedBand;
        Decimal matchedMinDonors;
        for (Volunteer_Staffing_Matrix__mdt band : volunteerMatrix) {
            if (band.Drive_Type__c != typeOfDrive || band.Operation_Type__c != siteOperationType) {
                continue;
            }
            // JS coerces a null minimum to 0 in the <= comparison. The field is required on the mdt,
            // so this only guards a hand-built record - a real null would also invert the JS sort
            // order (lodash ranks null above every number), which this single pass cannot reproduce.
            Decimal minDonors = band.Min_Anticipated_Registered_Donors__c == null
                ? 0
                : band.Min_Anticipated_Registered_Donors__c;
            if (minDonors > projectedRegisteredDonors) {
                continue;
            }
            // Strict > keeps the earlier record on a tie, matching the stable sort the source relies on.
            if (matchedBand == null || minDonors > matchedMinDonors) {
                matchedBand = band;
                matchedMinDonors = minDonors;
            }
        }

        if (matchedBand == null || matchedBand.Volunteer_Quantity__c == null) {
            return NO_VOLUNTEERS;
        }
        return matchedBand.Volunteer_Quantity__c.intValue();
    }
}
