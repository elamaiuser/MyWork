/**
 * Backed by the Volunteer_Staffing_Matrix__mdt custom metadata type.
 *
 * Deliberately not handled: forcing a minimum of 1 (or resetting to 0) when a live edit toggles the
 * redcrossVolunteerRequired checkbox against a prior drive snapshot - that requires modeling
 * "prior drive state," which this class does not otherwise need.
 */
public with sharing class skedMobileVolunteerCalculator {

    public static Decimal calculateVolunteerDonorAmbassadors(sked_Drive__c drive, List<Volunteer_Staffing_Matrix__mdt> volunteerMatrix, Boolean skipVolunteerRecalculation) {
        if (drive.sked_Redcross_Volunteer_Required__c != true) {
            return 0;
        }

        Decimal noOfVolunteerDonorAmbassadors = drive.sked_Redcross_Volunteer_Quantity__c == null ? 0 : drive.sked_Redcross_Volunteer_Quantity__c;

        // A brand new, unsaved drive just keeps whatever quantity was already populated (e.g. from the Opportunity).
        if (drive.Id == null) {
            return noOfVolunteerDonorAmbassadors;
        }
        if (skipVolunteerRecalculation) {
            return noOfVolunteerDonorAmbassadors;
        }

        Boolean isHighSchoolDrive = drive.sked_Account__r.Type == skedConstants.ACCOUNT_TYPE_EDUCATION
            && drive.sked_Account__r.Industry_Code__c == skedConstants.ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL;

        List<Volunteer_Staffing_Matrix__mdt> matchingDriveTypeMatrix = new List<Volunteer_Staffing_Matrix__mdt>();
        for (Volunteer_Staffing_Matrix__mdt entry : volunteerMatrix) {
            if (entry.Drive_Type__c == drive.sked_Type_of_Drive__c && entry.High_School_Drive__c == isHighSchoolDrive) {
                matchingDriveTypeMatrix.add(entry);
            }
        }
        if (matchingDriveTypeMatrix.isEmpty()) {
            return noOfVolunteerDonorAmbassadors;
        }

        Decimal projectedRegisteredDonors = drive.sked_Projected_Registered_Donors__c == null ? 0 : drive.sked_Projected_Registered_Donors__c;
        Volunteer_Staffing_Matrix__mdt matchedEntry;
        for (Volunteer_Staffing_Matrix__mdt entry : matchingDriveTypeMatrix) {
            if (entry.Min_Anticipated_Registered_Donors__c <= projectedRegisteredDonors && entry.Max_Anticipated_Registered_Donors__c >= projectedRegisteredDonors) {
                matchedEntry = entry;
                break;
            }
        }

        if (matchedEntry != null) {
            return matchedEntry.Volunteer_Quantity__c;
        }

        Volunteer_Staffing_Matrix__mdt maxDonorValueMatrix = matchingDriveTypeMatrix[0];
        for (Volunteer_Staffing_Matrix__mdt entry : matchingDriveTypeMatrix) {
            if (entry.Max_Anticipated_Registered_Donors__c > maxDonorValueMatrix.Max_Anticipated_Registered_Donors__c) {
                maxDonorValueMatrix = entry;
            }
        }
        if (projectedRegisteredDonors <= maxDonorValueMatrix.Max_Anticipated_Registered_Donors__c) {
            return noOfVolunteerDonorAmbassadors;
        }

        Decimal maxVolunteerCount = maxDonorValueMatrix.Volunteer_Quantity__c;
        if (isHighSchoolDrive) {
            return maxVolunteerCount;
        }
        return maxVolunteerCount + extraVolunteers(projectedRegisteredDonors - maxDonorValueMatrix.Max_Anticipated_Registered_Donors__c);
    }

    // Iterative rather than recursive - same result, no recursion depth concerns for what's always
    // a small donor-count difference.
    private static Integer extraVolunteers(Decimal donorsOverMax) {
        Integer count = 0;
        while (donorsOverMax >= 40) {
            donorsOverMax -= 40;
            count++;
        }
        return count;
    }
}
