@isTest
private class skedMobileSlotGenerator_Test {

    private static sked_Drive__c queryDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Projected_Registered_Donors__c,
                sked_APT_Quantity__c, sked_Travel_Time_Included__c, sked_Account__r.Type, sked_Account__r.Industry_Code__c,
                sked_Account__r.Accepts_Automation2__c,
                sked_Do_Not_Use_Vehicle__c, sked_Number_of_Vehicles__c, sked_Total_Vehicle_Requested__c, sked_Number_of_2RBC_Assets__c, sked_IMPACT__c,
                sked_Opportunity__r.Call_List_Recipient_Exist__c, sked_Opportunity__r.Slot_Generator__c, sked_Type_of_Drive__c, sked_Operation_Type__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    // Draw hours default to 7:00-17:00 (600 minutes / 10 hours), CO lunch break off unless a test overrides it.
    private static sked_Drive__c setupDrive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Maximum_Shift_Length_Threshold__c = 700;
        collectionOperation.sked_No_Travel_Time__c = false;
        collectionOperation.sked_Lunch_Break__c = false;
        update collectionOperation;

        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_2RBC_Projected_Procedures__c = 30;
        testDrive1.sked_WB_Projected_Procedures__c = 20;
        testDrive1.sked_Do_Not_Use_Vehicle__c = false;
        testDrive1.sked_Number_of_Vehicles__c = 2;
        testDrive1.sked_Number_of_2RBC_Assets__c = 4;
        update testDrive1;

        // Deterministic padding (115% -> a 1.15 multiplier) regardless of whatever this sandbox's
        // real sked_Admin_Setting__c org defaults happen to be - without this, an un-scaled real org
        // value can blow the Apex heap (see skedMobileSlotGenerator.calculatePaddingPercentage).
        setAdminSettingCapacities(115, 130);
        Opportunity opp = new Opportunity(Id = queryOpportunityId(testDrive1.Id), Call_List_Recipient_Exist__c = true, Slot_Generator__c = null);
        update opp;

        return queryDrive(testDrive1.Id);
    }

    private static void setAdminSettingCapacities(Decimal callListRecipient, Decimal callListRecipientNone) {
        sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
        setting.sked_Admin_Call_List_Recipient__c = callListRecipient;
        setting.sked_Admin_Call_List_Recipient_None__c = callListRecipientNone;
        upsert setting;
    }

    private static Id queryOpportunityId(Id driveId) {
        return [SELECT sked_Opportunity__c FROM sked_Drive__c WHERE Id = :driveId].sked_Opportunity__c;
    }

    // Everything slot generation needs, kept together so a test can re-run slot generation against
    // one already-built set of shifts with a different staff-setup role list - proving a role-list
    // delta rather than a fixture delta caused any difference in output.
    private class SlotInputs {
        sked_Drive__c drive;
        skedMobileDriveShiftCalculator.MasterData masterData;
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata;
        sked_Staffing_Decision_Matrix__c sdm;
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig;
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;
        Decimal paddingPercentage;
    }

    private static SlotInputs buildShifts(sked_Drive__c drive) {
        SlotInputs inputs = new SlotInputs();
        inputs.drive = drive;
        inputs.masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        inputs.shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, inputs.masterData);

        inputs.sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantities = skedMobileRoleQuantityCalculator.calculateRoleQuantities(
            drive, inputs.shiftsMetadata, inputs.sdm, inputs.masterData.driveSite.sked_Physical_Location_Type__c, inputs.masterData.timezoneSidId);

        Decimal numberOfVehicles = skedMobileRoleQuantityCalculator.calculateVehicleQuantity(drive);
        inputs.lunchBreakSettingsConfig = skedMobileLunchBreakCalculator.loadLunchBreakSettings();
        inputs.shifts = skedMobileDriveJobBuilder.buildProposedDriveShifts(drive, inputs.shiftsMetadata, roleQuantities,
            numberOfVehicles, drive.sked_Number_of_2RBC_Assets__c, inputs.masterData.timezoneSidId, inputs.lunchBreakSettingsConfig,
            inputs.masterData.jobTagsByResourceType, new List<Collection_Operation_Time_Block__c>(), 0);
        skedMobileDriveJobBuilder.updateDriveStaffCapacity(inputs.shifts, inputs.shiftsMetadata, inputs.sdm, drive.sked_Number_of_2RBC_Assets__c,
            inputs.masterData.timezoneSidId, inputs.masterData.adhocDriverSupportCapacity);

        inputs.paddingPercentage = skedMobileSlotGenerator.calculatePaddingPercentage(drive, inputs.masterData);
        return inputs;
    }

    private static List<skedMobileDriveJobBuilder.ProposedDriveShift> buildShiftsWithSlots(sked_Drive__c drive) {
        SlotInputs inputs = buildShifts(drive);
        skedMobileSlotGenerator.proposeDriveShiftSlots(inputs.shifts, inputs.shiftsMetadata, inputs.sdm, drive.sked_Number_of_2RBC_Assets__c,
            inputs.paddingPercentage, inputs.masterData.skipLastAppointmentForMobile, inputs.lunchBreakSettingsConfig, inputs.masterData.timezoneSidId,
            inputs.masterData.adhocDriverSupportCapacity);
        return inputs.shifts;
    }

    private static void regenerateSlots(SlotInputs inputs, List<String> staffSetupRoles) {
        skedMobileSlotGenerator.proposeDriveShiftSlots(inputs.shifts, inputs.shiftsMetadata, inputs.sdm, inputs.drive.sked_Number_of_2RBC_Assets__c,
            inputs.paddingPercentage, inputs.masterData.skipLastAppointmentForMobile, inputs.lunchBreakSettingsConfig, inputs.masterData.timezoneSidId,
            inputs.masterData.adhocDriverSupportCapacity, staffSetupRoles);
    }

    @isTest
    static void testCalculatePaddingPercentage_callListRecipientNotExist_usesNoneCapacity() {
        sked_Drive__c testDrive1 = setupDrive();
        setAdminSettingCapacities(100, 200);
        Opportunity opp = new Opportunity(Id = queryOpportunityId(testDrive1.Id), Call_List_Recipient_Exist__c = false, Slot_Generator__c = null);
        update opp;
        sked_Drive__c drive = queryDrive(testDrive1.Id);
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);

        Test.startTest();
        Decimal paddingPercentage = skedMobileSlotGenerator.calculatePaddingPercentage(drive, masterData);
        Test.stopTest();

        System.assertEquals(2, paddingPercentage, 'With no call-list recipient on the Opportunity, the None capacity (200%) must be used, scaled to a 2.0 multiplier');
    }

    @isTest
    static void testCalculatePaddingPercentage_opportunitySlotGeneratorOverride_takesPrecedence() {
        sked_Drive__c testDrive1 = setupDrive();
        setAdminSettingCapacities(100, 200);
        // Slot_Generator__c has a validation rule requiring a changed, non-blank change-reason alongside it.
        Opportunity opp = new Opportunity(Id = queryOpportunityId(testDrive1.Id), Call_List_Recipient_Exist__c = true,
            Slot_Generator__c = 50, Slot_Generator_Change_Reason__c = 'Test override');
        update opp;
        sked_Drive__c drive = queryDrive(testDrive1.Id);
        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);

        Test.startTest();
        Decimal paddingPercentage = skedMobileSlotGenerator.calculatePaddingPercentage(drive, masterData);
        Test.stopTest();

        System.assertEquals(0.5, paddingPercentage, 'The Opportunity Slot Generator override (divided by 100) must win over both admin defaults');
    }

    @isTest
    static void testProposeDriveShiftSlots_2rbcSlotCountMatchesHandCalculation() {
        sked_Drive__c drive = setupDrive();

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShiftsWithSlots(drive);
        Test.stopTest();

        // 4 assets over a 7:00-17:00 shift: lastSlotStart = 16:30, rounds at 7:00..16:00 (10 rounds),
        // each round splits 4 assets into 2 groups of 2 (both within the 16:30 cutoff) = 4 slots/round.
        System.assertEquals(40, shifts[0].shiftRecord.sked_Default_2RBC_Slots__c, '10 hourly rounds x 4 slots/round (2 groups x 2 assets) = 40');

        Integer actual2rbcSlots = 0;
        for (sked__Slot__c slot : shifts[0].slots) {
            if (slot.sked_Type__c == '2RBC') {
                actual2rbcSlots++;
            }
        }
        System.assertEquals(40, actual2rbcSlots, 'The shift\'s own slots collection must contain exactly the counted number of 2RBC slots');
    }

    @isTest
    static void testProposeDriveShiftSlots_wbSlotCountMatchesHandCalculatedCapacityMinus2rbc() {
        sked_Drive__c drive = setupDrive();

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShiftsWithSlots(drive);
        Test.stopTest();

        // Driver 2*2.2*10 + Driver Support 2*2.2*10 + 2RBC 2*2*10 + VP/HH 0 = 128 staff capacity;
        // totalDefaultSlots = ceil(128 * 1.15) = 148; totalWbSlots = 148 - 40 (2RBC) = 108.
        System.assertEquals(108, shifts[0].shiftRecord.sked_Default_WB_Slots__c, 'WB slot count must equal the padded capacity minus the 2RBC slot count');
    }

    @isTest
    static void testProposeDriveShiftSlots_noNumberOf2rbcAssets_generatesNo2rbcSlots() {
        sked_Drive__c testDrive1 = setupDrive();
        testDrive1.sked_Number_of_2RBC_Assets__c = 0;
        update testDrive1;
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShiftsWithSlots(drive);
        Test.stopTest();

        System.assertEquals(0, shifts[0].shiftRecord.sked_Default_2RBC_Slots__c, 'With zero 2RBC assets, no 2RBC slots may be generated');
    }

    @isTest
    static void testProposeDriveShiftSlots_lunchBreakFullReduction_removesAllWbSlotsInsideLunchWindow() {
        sked_Drive__c testDrive1 = setupDrive();
        Biomed_Collection_Op_Center__c collectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Id = :testDrive1.sked_Collection_Operation__c];
        collectionOperation.sked_Lunch_Break__c = true;
        collectionOperation.sked_Lunch_Break_Duration_Mobile__c = '30';
        collectionOperation.sked_Lunch_Break_Before_Draw_Hours__c = false;
        update collectionOperation;
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = '30');
        insert setting;
        insert new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = 30,
            sked_Min_Number_of_Staff__c = 0, sked_Max_Number_of_Staff__c = 1000, sked_Slot_Reduction__c = 100
        );

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShiftsWithSlots(drive);
        Test.stopTest();

        sked_Drive_Shift__c shift = shifts[0].shiftRecord;
        System.assertEquals(100, shift.sked_Sign_Up_Reduction__c, 'The matched definition\'s 100% slot reduction must be recorded on the shift');

        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime lunchStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.sked_Drive_Date__c, shift.sked_Lunch_Break_Start_Time__c, timezoneSidId);
        DateTime lunchEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.sked_Drive_Date__c, shift.sked_Lunch_Break_End_Time__c, timezoneSidId);
        for (sked__Slot__c slot : shifts[0].slots) {
            if (slot.sked_Type__c != 'Whole Blood') {
                continue;
            }
            Boolean withinLunchWindow = slot.sked_Start__c >= lunchStart && slot.sked_End__c <= lunchEnd;
            System.assertEquals(false, withinLunchWindow, 'With a 100% reduction, no Whole Blood slot may remain fully inside the lunch-break window: ' + slot.sked_Start__c);
        }
    }

    @isTest
    static void testProposeDriveShiftSlots_lunchBreakPartialReduction_removesExactlyTheRoundedUpCount() {
        sked_Drive__c testDrive1 = setupDrive();
        Biomed_Collection_Op_Center__c collectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Id = :testDrive1.sked_Collection_Operation__c];
        collectionOperation.sked_Lunch_Break__c = true;
        collectionOperation.sked_Lunch_Break_Duration_Mobile__c = '30';
        collectionOperation.sked_Lunch_Break_Before_Draw_Hours__c = false;
        update collectionOperation;
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = '30');
        insert setting;
        insert new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = 30,
            sked_Min_Number_of_Staff__c = 0, sked_Max_Number_of_Staff__c = 1000, sked_Slot_Reduction__c = 50
        );

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShiftsWithSlots(drive);
        Test.stopTest();

        // Lunch window 11:45-12:15 (30 min after the (600-30)/2=285-minute, already-15-aligned
        // midpoint split) fully contains 5 generated Whole Blood slots (11:45 and 12:00 start times,
        // each duplicated across the slot-cycling rounds needed to reach 108 total). A 50% reduction
        // removes ceil(5 * 0.5) = 3 of them, leaving 108 - 3 = 105 total and exactly 2 still inside the window.
        System.assertEquals(50, shifts[0].shiftRecord.sked_Sign_Up_Reduction__c, 'The matched definition\'s 50% slot reduction must be recorded on the shift');
        System.assertEquals(105, shifts[0].shiftRecord.sked_Default_WB_Slots__c, 'Exactly 3 of the 108 WB slots must be removed by a 50% reduction of the 5 slots inside the window');
    }

    // Bands are non-overlapping because loadLunchBreakSettings' subquery has no ORDER BY and
    // findLunchBreakDefinition returns the first row spanning the computed staff count.
    private static void insertTwoBandLunchBreakConfig(Id collectionOperationId) {
        Biomed_Collection_Op_Center__c collectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Id = :collectionOperationId];
        collectionOperation.sked_Lunch_Break__c = true;
        collectionOperation.sked_Lunch_Break_Duration_Mobile__c = '30';
        collectionOperation.sked_Lunch_Break_Before_Draw_Hours__c = false;
        update collectionOperation;

        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = '30');
        insert setting;
        insert new List<sked_Lunch_Break_Definition__c>{
            new sked_Lunch_Break_Definition__c(
                sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = 30,
                sked_Min_Number_of_Staff__c = 0, sked_Max_Number_of_Staff__c = 3, sked_Slot_Reduction__c = 100
            ),
            new sked_Lunch_Break_Definition__c(
                sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = 30,
                sked_Min_Number_of_Staff__c = 4, sked_Max_Number_of_Staff__c = 1000, sked_Slot_Reduction__c = 0
            )
        };
    }

    @isTest
    static void testProposeDriveShiftSlots_wbStaffSetupRoles_landInDifferentLunchBreakBandThanMobile() {
        sked_Drive__c testDrive1 = setupDrive();
        insertTwoBandLunchBreakConfig(testDrive1.sked_Collection_Operation__c);
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        SlotInputs inputs = buildShifts(drive);
        regenerateSlots(inputs, new List<String>{ 'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge' });
        Decimal mobileWbSlots = inputs.shifts[0].shiftRecord.sked_Default_WB_Slots__c;
        Decimal mobileSignUpReduction = inputs.shifts[0].shiftRecord.sked_Sign_Up_Reduction__c;

        regenerateSlots(inputs, new List<String>{ '2RBC', 'VP/HH', 'Charge' });
        Decimal wbWbSlots = inputs.shifts[0].shiftRecord.sked_Default_WB_Slots__c;
        Decimal wbSignUpReduction = inputs.shifts[0].shiftRecord.sked_Sign_Up_Reduction__c;
        Test.stopTest();

        System.assertEquals(0, mobileSignUpReduction, 'Mobile\'s role list counts Driver and Driver Support, landing in the 4-1000 band with no slot reduction');
        System.assertEquals(100, wbSignUpReduction, 'Dropping Driver and Driver Support drops the staff count into the 0-3 band with a 100% slot reduction');
        System.assert(wbWbSlots < mobileWbSlots, 'The shorter role list must measurably reduce the generated Whole Blood slot count, not just the recorded reduction: '
            + wbWbSlots + ' vs ' + mobileWbSlots);
    }

    @isTest
    static void testProposeDriveShiftSlots_defaultOverload_matchesExplicitMobileRoleList() {
        sked_Drive__c testDrive1 = setupDrive();
        insertTwoBandLunchBreakConfig(testDrive1.sked_Collection_Operation__c);
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        SlotInputs inputs = buildShifts(drive);
        regenerateSlots(inputs, new List<String>{ 'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge' });
        Decimal explicitWbSlots = inputs.shifts[0].shiftRecord.sked_Default_WB_Slots__c;

        List<skedMobileDriveJobBuilder.ProposedDriveShift> defaultShifts = buildShiftsWithSlots(queryDrive(testDrive1.Id));
        Test.stopTest();

        System.assertEquals(explicitWbSlots, defaultShifts[0].shiftRecord.sked_Default_WB_Slots__c,
            'The existing role-list-free entry point must behave exactly as if Mobile\'s five roles were passed explicitly');
    }
}
