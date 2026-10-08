@isTest
private class skedLunchBreakCalculator_Test {

    private static final List<String> MOBILE_ROLES = new List<String>{ 'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge' };
    private static final List<String> FIXED_SITE_ROLES = new List<String>{ 'Apheresis', 'Apheresis Charge' };

    private static void insertLunchBreakSetting(String maximumLunchBreakDuration, Decimal definitionDuration) {
        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = maximumLunchBreakDuration);
        insert setting;
        insert new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = definitionDuration,
            sked_Min_Number_of_Staff__c = 0, sked_Max_Number_of_Staff__c = 1000, sked_Slot_Reduction__c = 0
        );
    }

    // Builds shift + metadata directly - no dependency on either drive type's build pipeline, so
    // this class's tests stay independent of skedMobileDriveJobBuilder/a future Fixed Site builder.
    private static skedMobileDriveShiftCalculator.DriveShiftMetadata buildMetadata(Boolean lunchBreak,
            Boolean lunchBreakBeforeDrawHours, Decimal maximumLunchBreakDuration, Decimal unpaidLunchBreakDuration) {
        skedLunchBreakSettings settings = new skedLunchBreakSettings();
        settings.lunchBreak = lunchBreak;
        settings.lunchBreakBeforeDrawHours = lunchBreakBeforeDrawHours;
        settings.maximumLunchBreakDuration = maximumLunchBreakDuration;
        settings.unpaidLunchBreakDuration = unpaidLunchBreakDuration;

        skedMobileDriveShiftCalculator.DriveShiftMetadata metadata = new skedMobileDriveShiftCalculator.DriveShiftMetadata();
        metadata.driveDate = Date.newInstance(2026, 9, 1);
        metadata.startTime = Time.newInstance(7, 0, 0, 0);
        metadata.endTime = Time.newInstance(17, 0, 0, 0);
        metadata.lunchBreakSettings = settings;
        return metadata;
    }

    private static skedMobileDriveJobBuilder.ProposedDriveShift buildProposed(List<sked__Job__c> jobs) {
        skedMobileDriveJobBuilder.ProposedDriveShift proposed = new skedMobileDriveJobBuilder.ProposedDriveShift();
        proposed.shiftRecord = new sked_Drive_Shift__c();
        proposed.jobs = jobs;
        return proposed;
    }

    @isTest
    static void testPopulateLunchBreakTime_notBeforeDrawHours_roundsStartToNearest15Minutes() {
        insertLunchBreakSetting('45', 45);
        List<sked_Lunch_Break_Setting__c> config = skedLunchBreakCalculator.loadLunchBreakSettings();
        skedMobileDriveJobBuilder.ProposedDriveShift proposed = buildProposed(
            new List<sked__Job__c>{ new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1) });
        skedMobileDriveShiftCalculator.DriveShiftMetadata metadata = buildMetadata(true, false, 45, 20);

        Test.startTest();
        skedLunchBreakCalculator.populateLunchBreakTime(proposed, metadata, config, UserInfo.getTimeZone().getID(), false, null, MOBILE_ROLES);
        Test.stopTest();

        // (600 draw-hours minutes - 45 duration) / 2 = 277.5 -> floor 277, not a multiple of 15 -> floor(277/15)*15 = 270 minutes after 7:00 = 11:30
        System.assertEquals(Time.newInstance(11, 30, 0, 0), proposed.shiftRecord.sked_Lunch_Break_Start_Time__c,
            'Lunch start must be rounded down to the nearest 15-minute mark before the midpoint');
        System.assertEquals(Time.newInstance(12, 15, 0, 0), proposed.shiftRecord.sked_Lunch_Break_End_Time__c, 'Lunch end must be start + duration');
        System.assertEquals(45, proposed.shiftRecord.sked_Lunch_Break_Duration__c, 'Duration must come from the matched Lunch Break Definition');
    }

    @isTest
    static void testPopulateLunchBreakTime_beforeDrawHours_placesBreakImmediatelyBeforeShiftStart() {
        insertLunchBreakSetting('30', 30);
        List<sked_Lunch_Break_Setting__c> config = skedLunchBreakCalculator.loadLunchBreakSettings();
        skedMobileDriveJobBuilder.ProposedDriveShift proposed = buildProposed(
            new List<sked__Job__c>{ new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1) });
        skedMobileDriveShiftCalculator.DriveShiftMetadata metadata = buildMetadata(true, true, 30, 20);

        Test.startTest();
        skedLunchBreakCalculator.populateLunchBreakTime(proposed, metadata, config, UserInfo.getTimeZone().getID(), false, null, MOBILE_ROLES);
        Test.stopTest();

        System.assertEquals(20, proposed.shiftRecord.sked_Lunch_Break_Duration__c, 'Before-draw-hours breaks use the unpaid lunch break duration, not the definition duration');
        System.assertEquals(Time.newInstance(6, 40, 0, 0), proposed.shiftRecord.sked_Lunch_Break_Start_Time__c, 'Lunch must start exactly unpaidLunchBreakDuration minutes before draw-hours start');
        System.assertEquals(Time.newInstance(7, 0, 0, 0), proposed.shiftRecord.sked_Lunch_Break_End_Time__c, 'Lunch must end exactly at draw-hours start');
    }

    @isTest
    static void testPopulateLunchBreakTime_lunchBreakOff_clearsFields() {
        skedMobileDriveJobBuilder.ProposedDriveShift proposed = buildProposed(new List<sked__Job__c>());
        skedMobileDriveShiftCalculator.DriveShiftMetadata metadata = buildMetadata(false, false, 30, 20);

        Test.startTest();
        skedLunchBreakCalculator.populateLunchBreakTime(proposed, metadata, new List<sked_Lunch_Break_Setting__c>(), UserInfo.getTimeZone().getID(), false, null, MOBILE_ROLES);
        Test.stopTest();

        System.assertEquals(false, proposed.shiftRecord.sked_Lunch_Break__c, 'lunchBreakSettings.lunchBreak == false must be copied onto the shift record');
        System.assertEquals(null, proposed.shiftRecord.sked_Lunch_Break_Start_Time__c, 'Lunch start must be cleared when there is no lunch break');
        System.assertEquals(null, proposed.shiftRecord.sked_Lunch_Break_End_Time__c, 'Lunch end must be cleared when there is no lunch break');
        System.assertEquals(null, proposed.shiftRecord.sked_Lunch_Break_Duration__c, 'Lunch duration must be cleared when there is no lunch break');
    }

    @isTest
    static void testPopulateLunchBreakTime_lockedWithExistingShift_restoresOnlyTheBooleans() {
        insertLunchBreakSetting('45', 45);
        List<sked_Lunch_Break_Setting__c> config = skedLunchBreakCalculator.loadLunchBreakSettings();
        skedMobileDriveJobBuilder.ProposedDriveShift proposed = buildProposed(
            new List<sked__Job__c>{ new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1) });
        // Fresh metadata says lunch break is OFF and not before-draw-hours...
        skedMobileDriveShiftCalculator.DriveShiftMetadata metadata = buildMetadata(false, false, 45, 20);
        // ...but the existing (pre-regen) shift had it ON and before-draw-hours - locked must restore these two booleans from it.
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Lunch_Break__c = true, sked_Lunch_Break_Before_Draw_Hours__c = true);

        Test.startTest();
        skedLunchBreakCalculator.populateLunchBreakTime(proposed, metadata, config, UserInfo.getTimeZone().getID(), true, existingShift, MOBILE_ROLES);
        Test.stopTest();

        System.assertEquals(true, proposed.shiftRecord.sked_Lunch_Break__c, 'Locked must restore lunchBreak from the existing shift, not the fresh metadata');
        System.assertEquals(true, proposed.shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c, 'Locked must restore lunchBreakBeforeDrawHours from the existing shift, not the fresh metadata');
        // Literal times are always recomputed fresh, lock or no lock - the "before draw hours" branch fires since the restored boolean is true.
        System.assertEquals(20, proposed.shiftRecord.sked_Lunch_Break_Duration__c, 'Literal duration must still be recomputed fresh even when locked');
    }

    @isTest
    static void testCalculateStaffSetup_withFixedSiteStyleRoles_countsOnlyMatchingRoles() {
        List<sked__Job__c> jobs = new List<sked__Job__c>{
            new sked__Job__c(sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 2),
            new sked__Job__c(sked_Resource_Role__c = 'Apheresis Charge', sked__Quantity__c = 1),
            new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 5) // Mobile-only role, must not count
        };

        Test.startTest();
        Decimal staffSetup = skedLunchBreakCalculator.calculateStaffSetup(jobs, FIXED_SITE_ROLES);
        Test.stopTest();

        System.assertEquals(3, staffSetup, 'Only jobs whose role is in the caller-supplied role list must be counted, proving the role list is genuinely parameterized');
    }
}