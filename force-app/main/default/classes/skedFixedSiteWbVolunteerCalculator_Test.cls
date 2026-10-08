@isTest
private class skedFixedSiteWbVolunteerCalculator_Test {

    private static final String DRIVE_TYPE = skedConstants.DRIVE_TYPE_FIXED_SITE;
    private static final String SITE_OPERATION_TYPE = skedConstants.OPERATION_TYPE_WB;
    private static final String SHIFT_KEY_1 = 'shift-1';
    private static final String SHIFT_KEY_2 = 'shift-2';
    private static final String SHIFT_KEY_3 = 'shift-3';

    @isTest
    static void testCalculateVolunteerQuantities_picksHighestBandAtOrBelowProjectedDonors() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{
            band(0, 49, 1),
            band(50, 999, 5)
        };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100, matrix);

        System.assertEquals(5, result.get(SHIFT_KEY_1),
            'The highest band whose minimum is at or below the projected donors must win, regardless of list order');
    }

    @isTest
    static void testCalculateVolunteerQuantities_matchesBandEvenWhenProjectedDonorsExceedItsMaximum() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ band(10, 50, 5) };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 500, matrix);

        System.assertEquals(5, result.get(SHIFT_KEY_1),
            'WB ignores Max_Anticipated_Registered_Donors__c entirely - a band 10x over its maximum still matches');
    }

    @isTest
    static void testCalculateVolunteerQuantities_ignoresBandsForOtherOperationTypes() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{
            band(DRIVE_TYPE, SITE_OPERATION_TYPE, 10, 999, 3, false),
            band(DRIVE_TYPE, 'Integrated', 90, 999, 9, false)
        };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100, matrix);

        System.assertEquals(3, result.get(SHIFT_KEY_1),
            'A higher band belonging to another operation type must lose to the matching operation type');
    }

    @isTest
    static void testCalculateVolunteerQuantities_ignoresBandsForOtherDriveTypes() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{
            band(DRIVE_TYPE, SITE_OPERATION_TYPE, 10, 999, 3, false),
            band(skedConstants.DRIVE_TYPE_MOBILE, SITE_OPERATION_TYPE, 90, 999, 9, false)
        };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100, matrix);

        System.assertEquals(3, result.get(SHIFT_KEY_1),
            'A higher band belonging to another drive type must lose to the matching drive type');
    }

    @isTest
    static void testCalculateVolunteerQuantities_ignoresHighSchoolDriveFlag() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{
            band(DRIVE_TYPE, SITE_OPERATION_TYPE, 10, 999, 7, true)
        };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100, matrix);

        System.assertEquals(7, result.get(SHIFT_KEY_1),
            'WB has no high-school branch - a High_School_Drive__c band matches a non-high-school drive');
    }

    @isTest
    static void testCalculateVolunteerQuantities_appliesTheSameQuantityToEveryShift() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ band(0, 999, 4) };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1, SHIFT_KEY_2, SHIFT_KEY_3 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100, matrix);

        System.assertEquals(new Map<String, Integer>{ SHIFT_KEY_1 => 4, SHIFT_KEY_2 => 4, SHIFT_KEY_3 => 4 }, result,
            'The drive-level donor count drives every shift, so all shifts get the same quantity');
    }

    @isTest
    static void testCalculateVolunteerQuantities_returnsEmptyMapWhenMatrixIsNull() {
        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1, SHIFT_KEY_2 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100, null);

        System.assertEquals(0, result.size(),
            'A null matrix leaves the per-shift volunteer map untouched');
    }

    @isTest
    static void testCalculateVolunteerQuantities_assignsZeroToEveryShiftWhenMatrixIsEmpty() {
        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1, SHIFT_KEY_2 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100,
            new List<Volunteer_Staffing_Matrix__mdt>());

        System.assertEquals(new Map<String, Integer>{ SHIFT_KEY_1 => 0, SHIFT_KEY_2 => 0 }, result,
            'An empty matrix is not an early return - every shift is written a zero');
    }

    @isTest
    static void testCalculateVolunteerQuantities_returnsZeroWhenNoBandMinimumIsLowEnough() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ band(200, 999, 8) };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100, matrix);

        System.assertEquals(0, result.get(SHIFT_KEY_1),
            'No band with a minimum at or below the projected donors means zero volunteers');
    }

    @isTest
    static void testCalculateVolunteerQuantities_returnsZeroWhenProjectedDonorsIsNull() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ band(0, 999, 7) };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, null, matrix);

        System.assertEquals(0, result.get(SHIFT_KEY_1),
            'An unprojected drive matches no band, including the zero-minimum band');
    }

    @isTest
    static void testCalculateVolunteerQuantities_treatsNullBandMinimumAsZero() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ band(null, 999, 6) };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 10, matrix);

        System.assertEquals(6, result.get(SHIFT_KEY_1),
            'A band with no minimum matches any projected donor count');
    }

    @isTest
    static void testCalculateVolunteerQuantities_keepsTheFirstOfTwoBandsWithTheSameMinimum() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{
            band(50, 999, 2),
            band(50, 999, 9)
        };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100, matrix);

        System.assertEquals(2, result.get(SHIFT_KEY_1),
            'Tied minimums resolve to the first record, matching the stable sort the LWC relies on');
    }

    @isTest
    static void testCalculateVolunteerQuantities_returnsZeroWhenMatchedBandHasNoQuantity() {
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ band(0, 999, null) };

        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 100, matrix);

        System.assertEquals(0, result.get(SHIFT_KEY_1),
            'A matched band with no configured quantity must not blow up on the Integer conversion');
    }

    @isTest
    static void testCalculateVolunteerQuantities_selectsMiddleBandOfTheDeployedWbConfiguration() {
        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 50, deployedWbBands());

        System.assertEquals(1, result.get(SHIFT_KEY_1),
            'The deployed 18-69 band must supply 1 Donor Ambassador for 50 projected donors');
    }

    @isTest
    static void testCalculateVolunteerQuantities_selectsTopBandOfTheDeployedWbConfiguration() {
        Map<String, Integer> result = skedFixedSiteWbVolunteerCalculator.calculateVolunteerQuantities(
            new List<String>{ SHIFT_KEY_1 }, DRIVE_TYPE, SITE_OPERATION_TYPE, 500, deployedWbBands());

        System.assertEquals(2, result.get(SHIFT_KEY_1),
            'The deployed open-ended 70+ band must still match despite carrying no maximum');
    }

    // Mirrors the three Volunteer_Staffing_Matrix records deployed for Fixed Site / Non Integrated WB.
    private static List<Volunteer_Staffing_Matrix__mdt> deployedWbBands() {
        return new List<Volunteer_Staffing_Matrix__mdt>{
            band(0, 17, 0),
            band(18, 69, 1),
            band(70, null, 2)
        };
    }

    private static Volunteer_Staffing_Matrix__mdt band(Decimal minDonors, Decimal maxDonors, Decimal volunteerQuantity) {
        return band(DRIVE_TYPE, SITE_OPERATION_TYPE, minDonors, maxDonors, volunteerQuantity, false);
    }

    private static Volunteer_Staffing_Matrix__mdt band(String driveType, String operationType,
            Decimal minDonors, Decimal maxDonors, Decimal volunteerQuantity, Boolean isHighSchoolDrive) {
        Volunteer_Staffing_Matrix__mdt entry =
            (Volunteer_Staffing_Matrix__mdt) Volunteer_Staffing_Matrix__mdt.sObjectType.newSObject(null, true);
        entry.Drive_Type__c = driveType;
        entry.Operation_Type__c = operationType;
        entry.Min_Anticipated_Registered_Donors__c = minDonors;
        entry.Max_Anticipated_Registered_Donors__c = maxDonors;
        entry.Volunteer_Quantity__c = volunteerQuantity;
        entry.High_School_Drive__c = isHighSchoolDrive;
        return entry;
    }
}
