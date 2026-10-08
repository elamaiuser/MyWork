@isTest
private class skedMobileLunchBreakCalculator_Test {

    private static sked_Drive__c queryDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Projected_Registered_Donors__c,
                sked_APT_Quantity__c, sked_Travel_Time_Included__c, sked_Account__r.Type, sked_Account__r.Industry_Code__c,
                sked_Account__r.Accepts_Automation2__c,
                sked_Do_Not_Use_Vehicle__c, sked_Number_of_Vehicles__c, sked_Total_Vehicle_Requested__c, sked_Number_of_2RBC_Assets__c, sked_IMPACT__c,
                sked_Type_of_Drive__c, sked_Operation_Type__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    // Draw hours default to 7:00-17:00 (600 minutes), long enough to qualify for a lunch break
    // (>= 360 minutes) once the CO's sked_Lunch_Break__c flag is on.
    private static sked_Drive__c setupDrive(String maximumLunchBreakDuration, Boolean lunchBreakBeforeDrawHours, Decimal unpaidLunchBreakDuration) {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Maximum_Shift_Length_Threshold__c = 700;
        collectionOperation.sked_No_Travel_Time__c = false;
        collectionOperation.sked_Lunch_Break__c = true;
        collectionOperation.sked_Lunch_Break_Duration_Mobile__c = maximumLunchBreakDuration;
        collectionOperation.sked_Lunch_Break_Before_Draw_Hours__c = lunchBreakBeforeDrawHours;
        collectionOperation.sked_Unpaid_Lunch_Break_Duration__c = unpaidLunchBreakDuration;
        update collectionOperation;

        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_2RBC_Projected_Procedures__c = 30;
        testDrive1.sked_WB_Projected_Procedures__c = 20;
        testDrive1.sked_Do_Not_Use_Vehicle__c = false;
        testDrive1.sked_Number_of_Vehicles__c = 2;
        testDrive1.sked_Number_of_2RBC_Assets__c = 4;
        update testDrive1;

        return queryDrive(testDrive1.Id);
    }

    private static void insertLunchBreakSetting(String maximumLunchBreakDuration, Decimal definitionDuration) {
        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = maximumLunchBreakDuration);
        insert setting;
        insert new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = definitionDuration,
            sked_Min_Number_of_Staff__c = 0, sked_Max_Number_of_Staff__c = 1000, sked_Slot_Reduction__c = 0
        );
    }

    private static List<skedMobileDriveJobBuilder.ProposedDriveShift> buildShifts(sked_Drive__c drive) {
        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);

        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantities = skedMobileRoleQuantityCalculator.calculateRoleQuantities(
            drive, shiftsMetadata, sdm, shiftMasterData.driveSite.sked_Physical_Location_Type__c, shiftMasterData.timezoneSidId);

        Decimal numberOfVehicles = skedMobileRoleQuantityCalculator.calculateVehicleQuantity(drive);
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = skedMobileLunchBreakCalculator.loadLunchBreakSettings();
        return skedMobileDriveJobBuilder.buildProposedDriveShifts(drive, shiftsMetadata, roleQuantities, numberOfVehicles, drive.sked_Number_of_2RBC_Assets__c,
            shiftMasterData.timezoneSidId, lunchBreakSettingsConfig, shiftMasterData.jobTagsByResourceType, new List<Collection_Operation_Time_Block__c>(), 0);
    }

    private static sked__Job__c findJobByRole(skedMobileDriveJobBuilder.ProposedDriveShift shift, String role) {
        for (sked__Job__c job : shift.jobs) {
            if (job.sked_Resource_Role__c == role) {
                return job;
            }
        }
        return null;
    }

    @isTest
    static void testPopulateLunchBreakTime_notBeforeDrawHours_roundsStartToNearest15Minutes() {
        sked_Drive__c drive = setupDrive('45', false, 20);
        insertLunchBreakSetting('45', 45);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        sked_Drive_Shift__c shift = shifts[0].shiftRecord;
        System.assertEquals(true, shift.sked_Lunch_Break__c, 'A 600-minute shift with the CO lunch break flag on must qualify for a lunch break');
        System.assertEquals(45, shift.sked_Lunch_Break_Duration__c, 'Duration must come from the matched Lunch Break Definition');
        // (600 - 45) / 2 = 277.5 -> floor 277, not a multiple of 15 -> floor(277/15)*15 = 270 minutes after 7:00 = 11:30
        System.assertEquals(Time.newInstance(11, 30, 0, 0), shift.sked_Lunch_Break_Start_Time__c,
            'Lunch start must be rounded down to the nearest 15-minute mark before the midpoint');
        System.assertEquals(Time.newInstance(12, 15, 0, 0), shift.sked_Lunch_Break_End_Time__c, 'Lunch end must be start + duration');
    }

    @isTest
    static void testPopulateLunchBreakTime_beforeDrawHours_placesBreakImmediatelyBeforeShiftStartAndWidensJobStart() {
        sked_Drive__c drive = setupDrive('30', true, 20);
        insertLunchBreakSetting('30', 30);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        sked_Drive_Shift__c shift = shifts[0].shiftRecord;
        System.assertEquals(20, shift.sked_Lunch_Break_Duration__c, 'Before-draw-hours breaks use the unpaid lunch break duration, not the definition duration');
        System.assertEquals(Time.newInstance(6, 40, 0, 0), shift.sked_Lunch_Break_Start_Time__c, 'Lunch must start exactly unpaidLunchBreakDuration minutes before draw-hours start');
        System.assertEquals(Time.newInstance(7, 0, 0, 0), shift.sked_Lunch_Break_End_Time__c, 'Lunch must end exactly at draw-hours start');

        sked__Job__c driverJob = findJobByRole(shifts[0], 'Driver');
        DateTime drawHoursStart = skedDateTimeUtils.getDateTimeFromDateAndTime(drive.sked_Drive_Date__c, drive.sked_Start_Time__c, UserInfo.getTimeZone().getID());
        System.assertEquals(drawHoursStart.addMinutes(-15).addMinutes(-20), driverJob.sked__Start__c,
            'The job start envelope must widen further back by the lunch break duration on top of the 15-minute fallback travel time');
    }

    @isTest
    static void testPopulateLunchBreakTime_lunchBreakDisabled_clearsFields() {
        sked_Drive__c testDrive1 = setupDrive('30', false, 20);
        Biomed_Collection_Op_Center__c collectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Id = :testDrive1.sked_Collection_Operation__c];
        collectionOperation.sked_Lunch_Break__c = false;
        update collectionOperation;
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        sked_Drive_Shift__c shift = shifts[0].shiftRecord;
        System.assertEquals(false, shift.sked_Lunch_Break__c, 'With the CO flag off, the shift must not qualify for a lunch break');
        System.assertEquals(null, shift.sked_Lunch_Break_Start_Time__c, 'Lunch start must be cleared when there is no lunch break');
        System.assertEquals(null, shift.sked_Lunch_Break_End_Time__c, 'Lunch end must be cleared when there is no lunch break');
        System.assertEquals(null, shift.sked_Lunch_Break_Duration__c, 'Lunch duration must be cleared when there is no lunch break');
    }
}
