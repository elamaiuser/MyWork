/**
 * calculateVolunteerDonorAmbassadors does no SOQL/DML of its own, but the drive still needs a real
 * Id (the drive.Id == null branch is tested separately with a genuinely unsaved sObject) - built via
 * skedTestDataFactory + real DML rather than sObjectType.newSObject(id, true), which throws "Record
 * Type is Unavailable" for sked_Drive__c (it has a required/defaulted RecordType this port doesn't
 * otherwise need to know about).
 */
@isTest
private class skedMobileVolunteerCalculator_Test {

    private static sked_Drive__c buildDrive(Boolean required, Decimal quantity, Decimal projectedRegisteredDonors, String accountType, String industryCode) {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        Account testAccount = [SELECT Id FROM Account WHERE Id = :((sked_Drive__c) testData.get('testDrive1')).sked_Account__c];
        testAccount.Type = accountType;
        testAccount.Industry_Code__c = industryCode;
        update testAccount;

        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_Redcross_Volunteer_Required__c = required;
        testDrive1.sked_Redcross_Volunteer_Quantity__c = quantity;
        testDrive1.sked_Projected_Registered_Donors__c = projectedRegisteredDonors;
        testDrive1.sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_MOBILE;
        update testDrive1;

        return [
            SELECT Id, sked_Redcross_Volunteer_Required__c, sked_Redcross_Volunteer_Quantity__c, sked_Projected_Registered_Donors__c,
                sked_Type_of_Drive__c, sked_Account__r.Type, sked_Account__r.Industry_Code__c
            FROM sked_Drive__c
            WHERE Id = :testDrive1.Id
        ];
    }

    private static Volunteer_Staffing_Matrix__mdt buildMatrixEntry(Decimal minDonors, Decimal maxDonors, Decimal volunteerQuantity, Boolean isHighSchoolDrive) {
        Volunteer_Staffing_Matrix__mdt entry = (Volunteer_Staffing_Matrix__mdt) Volunteer_Staffing_Matrix__mdt.sObjectType.newSObject(null, true);
        entry.Drive_Type__c = skedConstants.DRIVE_TYPE_MOBILE;
        entry.High_School_Drive__c = isHighSchoolDrive;
        entry.Min_Anticipated_Registered_Donors__c = minDonors;
        entry.Max_Anticipated_Registered_Donors__c = maxDonors;
        entry.Volunteer_Quantity__c = volunteerQuantity;
        return entry;
    }

    @isTest
    static void testCalculate_notRequired_returnsZero() {
        sked_Drive__c drive = buildDrive(false, 5, 40, 'Business', null);

        Decimal result = skedMobileVolunteerCalculator.calculateVolunteerDonorAmbassadors(drive, new List<Volunteer_Staffing_Matrix__mdt>(), false);

        System.assertEquals(0, result, 'A drive that does not require volunteers must return 0');
    }

    @isTest
    static void testCalculate_newDriveWithNoId_returnsExistingQuantityUnchanged() {
        sked_Drive__c drive = new sked_Drive__c(
            sked_Redcross_Volunteer_Required__c = true,
            sked_Redcross_Volunteer_Quantity__c = 3
        );
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ buildMatrixEntry(0, 50, 99, false) };

        Decimal result = skedMobileVolunteerCalculator.calculateVolunteerDonorAmbassadors(drive, matrix, false);

        System.assertEquals(3, result, 'A brand new (unsaved) drive must keep its existing quantity, not recompute from the matrix');
    }

    @isTest
    static void testCalculate_skipRecalculation_returnsExistingQuantityUnchanged() {
        sked_Drive__c drive = buildDrive(true, 4, 200, 'Business', null);
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ buildMatrixEntry(0, 50, 99, false) };

        Decimal result = skedMobileVolunteerCalculator.calculateVolunteerDonorAmbassadors(drive, matrix, true);

        System.assertEquals(4, result, 'When skipVolunteerRecalculation is true, the existing quantity must be left unchanged');
    }

    @isTest
    static void testCalculate_donorsWithinMatchedRange_returnsMatrixQuantity() {
        sked_Drive__c drive = buildDrive(true, 1, 75, 'Business', null);
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{
            buildMatrixEntry(0, 50, 2, false),
            buildMatrixEntry(51, 100, 3, false)
        };

        Decimal result = skedMobileVolunteerCalculator.calculateVolunteerDonorAmbassadors(drive, matrix, false);

        System.assertEquals(3, result, 'Donors falling within a matrix row\'s range must use that row\'s volunteer quantity');
    }

    @isTest
    static void testCalculate_donorsExceedAllRanges_nonHighSchool_addsExtraVolunteers() {
        sked_Drive__c drive = buildDrive(true, 1, 180, 'Business', null);
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ buildMatrixEntry(0, 100, 4, false) };

        Decimal result = skedMobileVolunteerCalculator.calculateVolunteerDonorAmbassadors(drive, matrix, false);

        System.assertEquals(6, result, '180 donors is 80 over the max of 100 - 2 extra volunteers (80/40) on top of the base 4');
    }

    @isTest
    static void testCalculate_donorsExceedAllRanges_highSchool_usesMaxQuantityWithNoExtra() {
        sked_Drive__c drive = buildDrive(true, 1, 180, 'Education', skedConstants.ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL);
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ buildMatrixEntry(0, 100, 4, true) };

        Decimal result = skedMobileVolunteerCalculator.calculateVolunteerDonorAmbassadors(drive, matrix, false);

        System.assertEquals(4, result, 'High school drives cap at the matrix max quantity - no extra volunteers are added');
    }

    @isTest
    static void testCalculate_donorsWithinMaxOfMatrix_noExtraAdded() {
        sked_Drive__c drive = buildDrive(true, 1, 60, 'Business', null);
        List<Volunteer_Staffing_Matrix__mdt> matrix = new List<Volunteer_Staffing_Matrix__mdt>{ buildMatrixEntry(0, 30, 2, false), buildMatrixEntry(80, 100, 5, false) };

        Decimal result = skedMobileVolunteerCalculator.calculateVolunteerDonorAmbassadors(drive, matrix, false);

        System.assertEquals(1, result, 'Donors between matrix gaps but not exceeding the overall max must leave the existing quantity unchanged');
    }
}
