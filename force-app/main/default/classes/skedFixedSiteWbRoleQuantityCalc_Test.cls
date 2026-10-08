@isTest
private class skedFixedSiteWbRoleQuantityCalc_Test {

    private static final Integer NUMBER_OF_2RBC_ASSETS = 4;
    // Chosen so vpHhCapacity * drawHours = 1.3 * 5 = 6.5 and the capacity shortfall is fractional (6.2).
    // That combination is what makes WB's ceil-before-divide observable: ceil(6.2)/6.5 -> 2 staff, while
    // Mobile's raw 6.2/6.5 -> 1. With an integral capacity*drawHours product the two formulas agree and
    // any assertion here would prove nothing.
    private static final Decimal VPHH_CAPACITY = 1.3;
    private static final Decimal CHARGE_CAPACITY = 1.1;
    private static final Decimal DONORS_SCHEDULED_WITH_SHORTFALL = 31.7;
    private static final Time SHIFT_START = Time.newInstance(8, 0, 0, 0);
    private static final Time SHIFT_END = Time.newInstance(13, 0, 0, 0);

    private static sked_Drive__c setupWbDrive(Boolean aptRequired) {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        sked_Drive__c testDrive2 = (sked_Drive__c) testData.get('testDrive2');
        testDrive2.sked_Number_of_2RBC_Assets__c = NUMBER_OF_2RBC_ASSETS;
        testDrive2.sked_APT_Required__c = aptRequired;
        update testDrive2;

        sked_Drive__c drive = [
            SELECT Id, sked_Drive_Date__c, sked_Collection_Operation__c, sked_Type_of_Drive__c, sked_Operation_Type__c,
                sked_Number_of_2RBC_Assets__c, sked_APT_Required__c, sked_IMPACT__c
            FROM sked_Drive__c
            WHERE Id = :testDrive2.Id
        ];
        System.assertEquals(skedConstants.OPERATION_TYPE_WB, drive.sked_Operation_Type__c,
            'Fixture must be a Fixed Site WB drive - testLocation2 supplies the WB operation type');
        return drive;
    }

    // sked_IMPACT__c is a cross-object formula over the Collection Operation's IMPACT date window, so it
    // is unassignable in Apex, and setting that window on the CO does not propagate to the Drive's formula
    // within the same test transaction (verified: window Aug 8-10 still yields false for an Aug 9 drive).
    private static sked_Drive__c asImpactDrive(sked_Drive__c drive) {
        Map<String, Object> fields = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(drive));
        fields.put('sked_IMPACT__c', true);
        return (sked_Drive__c) JSON.deserialize(JSON.serialize(fields), sked_Drive__c.class);
    }

    // setupCommonTestData already links testCollectionOperation1 to a shared Mobile-record-type matrix,
    // and loadStaffingDecisionMatrix is a LIMIT 1 query with no ORDER BY - a second matching junction is a
    // collision, not an addition. Replace the link so each test gets the capacities it asked for.
    private static sked_Staffing_Decision_Matrix__c replaceMobileSdm(Id collectionOperationId, Decimal vpHhCapacity, Decimal chargeThreshold) {
        sked_Staffing_Decision_Matrix__c matrix = new sked_Staffing_Decision_Matrix__c(
            sked_VP_HH_Capacity__c = vpHhCapacity,
            sked_Charge_Capacity__c = CHARGE_CAPACITY,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Team_Supervisor_Threshold__c = 36,
            sked_Charge_Threshold__c = chargeThreshold,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        insert matrix;

        delete [
            SELECT Id FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c = :collectionOperationId
                AND sked_Staffing_Decision_Matrix__r.RecordType.Name = :skedConstants.DRIVE_TYPE_MOBILE
        ];
        insert new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collectionOperationId,
            sked_Staffing_Decision_Matrix__c = matrix.Id
        );
        return matrix;
    }

    private static sked_Staffing_Decision_Matrix__c loadSdm(sked_Drive__c drive) {
        return skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
    }

    private static skedMobileDriveShiftCalculator.DriveShiftsMetadata buildSingleShiftMetadata(
            Date driveDate, Decimal donorsScheduled, Decimal totalProceduresProjected) {
        return buildShiftsMetadata(driveDate, new List<Decimal>{ donorsScheduled }, totalProceduresProjected);
    }

    private static skedMobileDriveShiftCalculator.DriveShiftsMetadata buildShiftsMetadata(
            Date driveDate, List<Decimal> donorsScheduledPerShift, Decimal totalProceduresProjected) {
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = new skedMobileDriveShiftCalculator.DriveShiftsMetadata();
        for (Integer i = 0; i < donorsScheduledPerShift.size(); i++) {
            skedMobileDriveShiftCalculator.DriveShiftMetadata shift = new skedMobileDriveShiftCalculator.DriveShiftMetadata();
            shift.key = 'drive_shift_' + i;
            shift.driveDate = driveDate;
            shift.startTime = SHIFT_START;
            shift.endTime = SHIFT_END;
            shift.lunchBreakSettings = new skedLunchBreakSettings();
            shift.donorsScheduled = donorsScheduledPerShift[i];
            shift.totalProceduresProjected = totalProceduresProjected;
            shiftsMetadata.driveShifts.add(shift);
        }
        shiftsMetadata.numberOfDriveShifts = shiftsMetadata.driveShifts.size();
        return shiftsMetadata;
    }

    private static Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> calculateForSingleShift(sked_Drive__c drive,
            sked_Staffing_Decision_Matrix__c sdm, skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata) {
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> byShiftKey =
            skedFixedSiteWbRoleQuantityCalculator.calculateRoleQuantities(drive, shiftsMetadata, sdm, 'Inside', UserInfo.getTimeZone().getID());
        return byShiftKey.get(shiftsMetadata.driveShifts[0].key);
    }

    @isTest
    static void testCalculateEquipmentQuantity_returnsTheDrivesNumberOf2rbcAssets() {
        sked_Drive__c drive = setupWbDrive(true);

        Test.startTest();
        Decimal equipmentQuantity = skedFixedSiteWbRoleQuantityCalculator.calculateEquipmentQuantity(drive);
        Test.stopTest();

        System.assertEquals(NUMBER_OF_2RBC_ASSETS, equipmentQuantity, 'Equipment quantity must be the drive\'s 2RBC asset count');
    }

    @isTest
    static void testCalculateRoleQuantities_capacityShortfall_roundsShortfallUpBeforeDividing() {
        sked_Drive__c drive = setupWbDrive(true);
        replaceMobileSdm(drive.sked_Collection_Operation__c, VPHH_CAPACITY, 36);
        sked_Staffing_Decision_Matrix__c sdm = loadSdm(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata =
            buildSingleShiftMetadata(drive.sked_Drive_Date__c, DONORS_SCHEDULED_WITH_SHORTFALL, 0);

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = calculateForSingleShift(drive, sdm, shiftsMetadata);
        Test.stopTest();

        System.assertEquals(2, roleQuantities.get('2RBC').quantity, '2RBC staff must be ceil(4 assets / 2) = 2');
        System.assertEquals(0, roleQuantities.get('Team Supervisor').quantity,
            'Team Supervisor must be 0: the shift\'s 0 projected procedures are below the 36 threshold');
        // Post-Charge recompute: 2RBC contributes 2 staff * 2 * 5h = 20 and Charge 1 * 1.1 * 5h = 5.5,
        // leaving a 6.2 shortfall against 31.7 donors. ceil(6.2) / (1.3 * 5) -> 2; Mobile's raw 6.2 -> 1.
        System.assertEquals(2, roleQuantities.get('VP/HH').vphhQuantity,
            'VP/HH must be 2 - the 6.2 capacity shortfall is rounded up to 7 before being divided by 6.5');
        System.assertEquals(1, roleQuantities.get('Charge').quantity,
            'Charge must be 1: ceil((2 2RBC + 2 VP/HH) / 11) = 1 leader, with no Team Supervisor to absorb it');
    }

    @isTest
    static void testCalculateRoleQuantities_twoShifts_quantifiesEachShiftFromItsOwnDonorCount() {
        sked_Drive__c drive = setupWbDrive(true);
        replaceMobileSdm(drive.sked_Collection_Operation__c, VPHH_CAPACITY, 36);
        sked_Staffing_Decision_Matrix__c sdm = loadSdm(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(drive.sked_Drive_Date__c,
            new List<Decimal>{ DONORS_SCHEDULED_WITH_SHORTFALL, 45 }, 0);

        Test.startTest();
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> byShiftKey =
            skedFixedSiteWbRoleQuantityCalculator.calculateRoleQuantities(drive, shiftsMetadata, sdm, 'Inside', UserInfo.getTimeZone().getID());
        Test.stopTest();

        System.assertEquals(2, byShiftKey.get('drive_shift_0').get('VP/HH').vphhQuantity,
            'Shift 0 must be quantified from its own 31.7 donors: ceil(31.7 - 25.5) / 6.5 -> 2');
        System.assertEquals(4, byShiftKey.get('drive_shift_1').get('VP/HH').vphhQuantity,
            'Shift 1 must be quantified from its own 45 donors: ceil(45 - 25.5) / 6.5 -> 4, not shift 0\'s value');
    }

    @isTest
    static void testCalculateRoleQuantities_aptRequired_addsOneAptStaffToVpHhTotal() {
        sked_Drive__c drive = setupWbDrive(true);
        replaceMobileSdm(drive.sked_Collection_Operation__c, VPHH_CAPACITY, 36);
        sked_Staffing_Decision_Matrix__c sdm = loadSdm(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata =
            buildSingleShiftMetadata(drive.sked_Drive_Date__c, DONORS_SCHEDULED_WITH_SHORTFALL, 0);

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = calculateForSingleShift(drive, sdm, shiftsMetadata);
        Test.stopTest();

        skedMobileRoleQuantityCalculator.RoleQuantity vpHh = roleQuantities.get('VP/HH');
        System.assertEquals(1, vpHh.aptQuantity, 'APT quantity must be 1 when the drive requires APT');
        System.assertEquals(3, vpHh.quantity, 'VP/HH total must be vphhQuantity (2) + aptQuantity (1)');
    }

    @isTest
    static void testCalculateRoleQuantities_aptNotRequired_zeroesTheAptComponent() {
        sked_Drive__c drive = setupWbDrive(false);
        replaceMobileSdm(drive.sked_Collection_Operation__c, VPHH_CAPACITY, 36);
        sked_Staffing_Decision_Matrix__c sdm = loadSdm(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata =
            buildSingleShiftMetadata(drive.sked_Drive_Date__c, DONORS_SCHEDULED_WITH_SHORTFALL, 0);

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = calculateForSingleShift(drive, sdm, shiftsMetadata);
        Test.stopTest();

        skedMobileRoleQuantityCalculator.RoleQuantity vpHh = roleQuantities.get('VP/HH');
        System.assertEquals(0, vpHh.aptQuantity, 'APT quantity must be 0 when the drive does not require APT');
        System.assertEquals(2, vpHh.quantity, 'VP/HH total must be vphhQuantity (2) alone when no APT staff is needed');
    }

    @isTest
    static void testCalculateRoleQuantities_teamSupervisorPresent_absorbsTheOnlyLeaderAndZeroesCharge() {
        sked_Drive__c drive = setupWbDrive(true);
        replaceMobileSdm(drive.sked_Collection_Operation__c, VPHH_CAPACITY, 36);
        sked_Staffing_Decision_Matrix__c sdm = loadSdm(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata =
            buildSingleShiftMetadata(drive.sked_Drive_Date__c, DONORS_SCHEDULED_WITH_SHORTFALL, 40);

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = calculateForSingleShift(drive, sdm, shiftsMetadata);
        Test.stopTest();

        System.assertEquals(1, roleQuantities.get('Team Supervisor').quantity,
            'Team Supervisor must be 1: 40 projected procedures exceed the 36 threshold on an Inside site');
        System.assertEquals(0, roleQuantities.get('Charge').quantity,
            'The single required leader is already covered by the Team Supervisor, so Charge must be 0');
    }

    @isTest
    static void testCalculateRoleQuantities_impactDrive_usesDriveLeadInsteadOfTeamSupervisor() {
        sked_Drive__c drive = setupWbDrive(true);
        replaceMobileSdm(drive.sked_Collection_Operation__c, VPHH_CAPACITY, 36);
        sked_Staffing_Decision_Matrix__c sdm = loadSdm(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata =
            buildSingleShiftMetadata(drive.sked_Drive_Date__c, DONORS_SCHEDULED_WITH_SHORTFALL, 40);

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities =
            calculateForSingleShift(asImpactDrive(drive), sdm, shiftsMetadata);
        Test.stopTest();

        System.assertEquals(1, roleQuantities.get('Drive Lead').quantity, 'An IMPACT drive must quantify Drive Lead rather than Team Supervisor');
        System.assertEquals(false, roleQuantities.containsKey('Team Supervisor'), 'An IMPACT drive must not produce a Team Supervisor quantity at all');
    }

    @isTest
    static void testCalculateRoleQuantities_nullStaffingDecisionMatrix_stillQuantifies2rbc() {
        sked_Drive__c drive = setupWbDrive(true);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata =
            buildSingleShiftMetadata(drive.sked_Drive_Date__c, DONORS_SCHEDULED_WITH_SHORTFALL, 0);

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = calculateForSingleShift(drive, null, shiftsMetadata);
        Test.stopTest();

        System.assertEquals(2, roleQuantities.get('2RBC').quantity, '2RBC is calculated from the asset count alone and must survive a missing matrix');
        System.assertEquals(false, roleQuantities.containsKey('VP/HH'), 'VP/HH needs the matrix and must be absent when there is none');
        System.assertEquals(false, roleQuantities.containsKey('Charge'), 'Charge needs the matrix and must be absent when there is none');
    }

    @isTest
    static void testCalculateRoleQuantities_noVpHhCapacity_stillQuantifiesChargeFrom2rbcAlone() {
        sked_Drive__c drive = setupWbDrive(true);
        replaceMobileSdm(drive.sked_Collection_Operation__c, null, 36);
        sked_Staffing_Decision_Matrix__c sdm = loadSdm(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata =
            buildSingleShiftMetadata(drive.sked_Drive_Date__c, DONORS_SCHEDULED_WITH_SHORTFALL, 0);

        Test.startTest();
        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = calculateForSingleShift(drive, sdm, shiftsMetadata);
        Test.stopTest();

        System.assertEquals(false, roleQuantities.containsKey('VP/HH'), 'An unconfigured VP/HH capacity must leave the role unquantified');
        System.assertEquals(1, roleQuantities.get('Charge').quantity,
            'Charge must still be ceil(2 2RBC / 11) = 1, reading the absent VP/HH as zero rather than failing');
    }

    @isTest
    static void testCalculateDriveShiftStaffCapacity_ignoresDriverJobsThatMobilesOwnRoleListCounts() {
        sked_Drive__c drive = setupWbDrive(true);
        replaceMobileSdm(drive.sked_Collection_Operation__c, VPHH_CAPACITY, 36);
        sked_Staffing_Decision_Matrix__c sdm = loadSdm(drive);
        skedMobileDriveShiftCalculator.DriveShiftMetadata shift =
            buildSingleShiftMetadata(drive.sked_Drive_Date__c, DONORS_SCHEDULED_WITH_SHORTFALL, 0).driveShifts[0];
        List<sked__Job__c> jobs = new List<sked__Job__c>{
            new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 3),
            new sked__Job__c(sked_Resource_Role__c = '2RBC', sked__Quantity__c = 2),
            new sked__Job__c(sked_Resource_Role__c = 'VP/HH', sked__Quantity__c = 1, sked_VPHH_Quantity__c = 1)
        };

        Test.startTest();
        Decimal wbCapacity = skedFixedSiteWbRoleQuantityCalculator.calculateDriveShiftStaffCapacity(jobs, shift, sdm,
            NUMBER_OF_2RBC_ASSETS, UserInfo.getTimeZone().getID(), false, false, false, null);
        Decimal mobileCapacity = skedMobileRoleQuantityCalculator.calculateDriveShiftStaffCapacity(jobs, shift, sdm,
            NUMBER_OF_2RBC_ASSETS, UserInfo.getTimeZone().getID(), false, false, false, null);
        Test.stopTest();

        System.assertEquals(26, wbCapacity, 'WB counts only 2RBC (2 * 2 * 5h = 20) and VP/HH (1 * 1.3 * 5h = 6.5), floored to 26');
        System.assertEquals(59, mobileCapacity, 'Mobile\'s role list additionally counts the 3 Driver staff (3 * 2.2 * 5h = 33), floored to 59');
    }
}
