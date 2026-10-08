@isTest
private class skedMobileDriveJobBuilder_Test {

    private static sked_Drive__c queryDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Projected_Registered_Donors__c,
                sked_APT_Quantity__c, sked_Travel_Time_Included__c, sked_Account__r.Type, sked_Account__r.Industry_Code__c,
                sked_Account__r.Accepts_Automation2__c,
                sked_Do_Not_Use_Vehicle__c, sked_Number_of_Vehicles__c, sked_Total_Vehicle_Requested__c, sked_Number_of_2RBC_Assets__c, sked_IMPACT__c,
                sked_Type_of_Drive__c, sked_Operation_Type__c, sked_Lock_Lunch_Break__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    private static sked_Drive__c setupDrive(Decimal maximumShiftLengthThreshold) {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Maximum_Shift_Length_Threshold__c = maximumShiftLengthThreshold;
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

        return queryDrive(testDrive1.Id);
    }

    private static List<skedMobileDriveJobBuilder.ProposedDriveShift> buildShifts(sked_Drive__c drive) {
        return buildShifts(drive, new List<Collection_Operation_Time_Block__c>());
    }

    private static List<skedMobileDriveJobBuilder.ProposedDriveShift> buildShifts(sked_Drive__c drive, List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks) {
        return buildShifts(drive, collectionOperationTimeBlocks, 0);
    }

    private static List<skedMobileDriveJobBuilder.ProposedDriveShift> buildShifts(sked_Drive__c drive,
            List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks, Decimal redcrossVolunteerQuantity) {
        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);

        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantities = skedMobileRoleQuantityCalculator.calculateRoleQuantities(
            drive, shiftsMetadata, sdm, shiftMasterData.driveSite.sked_Physical_Location_Type__c, shiftMasterData.timezoneSidId);

        Decimal numberOfVehicles = skedMobileRoleQuantityCalculator.calculateVehicleQuantity(drive);
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = skedMobileLunchBreakCalculator.loadLunchBreakSettings();
        return skedMobileDriveJobBuilder.buildProposedDriveShifts(drive, shiftsMetadata, roleQuantities, numberOfVehicles, drive.sked_Number_of_2RBC_Assets__c,
            shiftMasterData.timezoneSidId, lunchBreakSettingsConfig, shiftMasterData.jobTagsByResourceType, collectionOperationTimeBlocks, redcrossVolunteerQuantity);
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
    static void testBuildProposedDriveShifts_singleShift_driverJobCarriesQuantityAndFallbackTravelTime() {
        sked_Drive__c drive = setupDrive(700);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        System.assertEquals(1, shifts.size(), 'Test setup must produce exactly one shift');
        sked__Job__c driverJob = findJobByRole(shifts[0], 'Driver');
        System.assertNotEquals(null, driverJob, 'A Driver job must be created since the drive requests 2 vehicles');
        System.assertEquals(2, driverJob.sked__Quantity__c, 'Driver job quantity must equal the role-quantity calculator\'s output');
        System.assertEquals(15, driverJob.sked_Travel_Time__c, 'With no Role Time Detail/Variance seeded, travel time must fall back to the site\'s flat 15-minute travelTimeToStagingLocation');
        System.assertEquals(15, driverJob.sked_Travel_Time2__c, 'Return travel time must fall back the same way');
        System.assertEquals(0, driverJob.sked_Lead_Time__c, 'Lead time must be 0 with no Role Time Detail seeded');
    }

    @isTest
    static void testBuildProposedDriveShifts_singleAvailableCOTimeBlockCoversShiftHours_assignsItToTheShift() {
        sked_Drive__c drive = setupDrive(700);
        Time_Block__c timeBlock = new Time_Block__c(
            Name = 'All Day', Start_Time__c = Time.newInstance(0, 0, 0, 0), End_Time__c = Time.newInstance(23, 59, 0, 0),
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert timeBlock;
        Collection_Operation_Time_Block__c coTimeBlock = new Collection_Operation_Time_Block__c(
            Collection_Operation__c = drive.sked_Collection_Operation__c, Time_Block__c = timeBlock.Id,
            Effective_Start_Date__c = Date.today().addDays(-1000), Effective_End_Date__c = Date.today().addDays(1000)
        );
        insert coTimeBlock;
        List<Collection_Operation_Time_Block__c> coTimeBlocks = [
            SELECT Id, Collection_Operation__c, Time_Block__c, Effective_Start_Date__c, Effective_End_Date__c,
                Time_Block__r.Days_of_Week__c, Time_Block__r.Start_Time__c, Time_Block__r.End_Time__c
            FROM Collection_Operation_Time_Block__c WHERE Id = :coTimeBlock.Id
        ];

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive, coTimeBlocks);
        Test.stopTest();

        System.assertEquals(timeBlock.Id, shifts[0].shiftRecord.sked_Time_Block__c,
            'The one CO time block covering the shift\'s full day must be assigned to it');
    }

    @isTest
    static void testBuildProposedDriveShifts_noCOTimeBlocksConfigured_leavesTimeBlockUnset() {
        sked_Drive__c drive = setupDrive(700);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive, new List<Collection_Operation_Time_Block__c>());
        Test.stopTest();

        System.assertEquals(null, shifts[0].shiftRecord.sked_Time_Block__c,
            'With no CO time blocks configured at all, a shift must be left without a time block');
    }

    @isTest
    static void testBuildProposedDriveShifts_singleShift_jobStartPrecedesDrawHoursStartByTravelTime() {
        sked_Drive__c drive = setupDrive(700);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        sked__Job__c driverJob = findJobByRole(shifts[0], 'Driver');
        DateTime drawHoursStart = skedDateTimeUtils.getDateTimeFromDateAndTime(drive.sked_Drive_Date__c, drive.sked_Start_Time__c, UserInfo.getTimeZone().getID());
        DateTime drawHoursEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(drive.sked_Drive_Date__c, drive.sked_End_Time__c, UserInfo.getTimeZone().getID());

        System.assertEquals(drawHoursStart.addMinutes(-15), driverJob.sked__Start__c,
            'Job start must precede draw-hours start by exactly the 15-minute fallback travel time (no lead/setup time seeded)');
        System.assertEquals(drawHoursEnd.addMinutes(15), driverJob.sked__Finish__c,
            'Job finish must follow draw-hours end by exactly the 15-minute fallback return travel time');
        System.assertEquals(driverJob.sked__Start__c, shifts[0].shiftRecord.sked_Start__c,
            'The shift\'s own start must widen to match its earliest job (the Driver job, here the only role-bearing job pushing the envelope)');
    }

    @isTest
    static void testBuildProposedDriveShifts_multiShift_assetJobsOnlyOnFirstShift() {
        sked_Drive__c drive = setupDrive(400);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        System.assertEquals(2, shifts.size(), 'Test setup must produce exactly two shifts so the asset-job placement rule is verifiable');

        Integer firstShiftAssetJobs = 0;
        for (sked__Job__c job : shifts[0].jobs) {
            if (job.sked_Asset_Type__c != null) {
                firstShiftAssetJobs++;
            }
        }
        System.assertEquals(2, firstShiftAssetJobs, 'The first shift must carry both the Vehicle and Equipment asset jobs');

        Integer secondShiftAssetJobs = 0;
        for (sked__Job__c job : shifts[1].jobs) {
            if (job.sked_Asset_Type__c != null) {
                secondShiftAssetJobs++;
            }
        }
        System.assertEquals(0, secondShiftAssetJobs, 'Only the first shift may carry asset jobs - later shifts keep only resourceRole/volunteerRole jobs');
    }

    private static sked__Job__c findVolunteerJob(skedMobileDriveJobBuilder.ProposedDriveShift shift) {
        for (sked__Job__c job : shift.jobs) {
            if (job.sked_Volunteer_Role__c == skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR) {
                return job;
            }
        }
        return null;
    }

    @isTest
    static void testBuildProposedDriveShifts_volunteerJobBuiltOnEveryShift() {
        sked_Drive__c drive = setupDrive(400);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive, new List<Collection_Operation_Time_Block__c>(), 5);
        Test.stopTest();

        System.assertEquals(2, shifts.size(), 'Test setup must produce exactly two shifts');
        for (Integer i = 0; i < shifts.size(); i++) {
            sked__Job__c volunteerJob = findVolunteerJob(shifts[i]);
            System.assertNotEquals(null, volunteerJob, 'Every shift must get its own volunteer job, not just the first - shift ' + i);
            System.assertEquals(5, volunteerJob.sked_Redcross_Volunteer_Quantity__c, 'Redcross quantity is drive-level, same value on every shift');
            System.assertEquals(0, volunteerJob.sked_Sponsor_Volunteer_Quantity__c, 'A freshly built volunteer job has no sponsor quantity yet - carried forward separately');
            System.assertEquals(5, volunteerJob.sked__Quantity__c, 'Total quantity is redcross + sponsor (0) at build time');
        }
    }

    @isTest
    static void testBuildProposedDriveShifts_zeroVolunteerQuantity_noVolunteerJobBuilt() {
        sked_Drive__c drive = setupDrive(400);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive, new List<Collection_Operation_Time_Block__c>(), 0);
        Test.stopTest();

        for (skedMobileDriveJobBuilder.ProposedDriveShift shift : shifts) {
            System.assertEquals(null, findVolunteerJob(shift), 'A zero/blank redcross quantity must not emit a volunteer job at all, matching the source\'s own quantity > 0 gate');
        }
    }

    @isTest
    static void testBuildProposedDriveShifts_vehicleJobEmittedEvenAtZeroQuantity() {
        sked_Drive__c testDrive1 = setupDrive(700);
        testDrive1.sked_Do_Not_Use_Vehicle__c = true;
        update testDrive1;
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        sked__Job__c vehicleJob;
        for (sked__Job__c job : shifts[0].jobs) {
            if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                vehicleJob = job;
            }
        }
        System.assertNotEquals(null, vehicleJob, 'A Vehicle job must still be created even at zero quantity, unlike Equipment which is only created when positive');
        System.assertEquals(0, vehicleJob.sked__Quantity__c, 'Do Not Use Vehicle must zero out the Vehicle job quantity');
    }

    @isTest
    static void testBuildProposedDriveShifts_roleJob_getsFreshRequiredPersonTag() {
        sked_Drive__c drive = setupDrive(700);
        sked__Tag__c requiredTag = new sked__Tag__c(Name = 'Required Person Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION, sked_Resource_Type__c = 'Person');
        insert requiredTag;
        insert new sked__Account_Tag__c(sked__Account__c = drive.sked_Account__r.Id, sked__Tag__c = requiredTag.Id, sked__Required__c = true);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        Integer driverJobIndex = findJobIndexByRole(shifts[0], 'Driver');
        List<sked__Job_Tag__c> jobTags = shifts[0].jobTagsByJobIndex.get(driverJobIndex);
        Boolean found = false;
        for (sked__Job_Tag__c jobTag : jobTags) {
            if (jobTag.sked__Tag__c == requiredTag.Id) {
                found = true;
            }
        }
        System.assertEquals(true, found, 'A role job must receive the account\'s required Person-type tag');
    }

    @isTest
    static void testBuildProposedDriveShifts_vehicleJob_doesNotGetRequiredPersonTag() {
        sked_Drive__c drive = setupDrive(700);
        sked__Tag__c requiredTag = new sked__Tag__c(Name = 'Required Person Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION, sked_Resource_Type__c = 'Person');
        insert requiredTag;
        insert new sked__Account_Tag__c(sked__Account__c = drive.sked_Account__r.Id, sked__Tag__c = requiredTag.Id, sked__Required__c = true);

        Test.startTest();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        Integer vehicleJobIndex;
        for (Integer i = 0; i < shifts[0].jobs.size(); i++) {
            if (shifts[0].jobs[i].sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                vehicleJobIndex = i;
            }
        }
        List<sked__Job_Tag__c> jobTags = shifts[0].jobTagsByJobIndex.get(vehicleJobIndex);
        System.assertEquals(0, jobTags.size(), 'A Person-type required tag must not be assigned to a Vehicle asset job');
    }

    private static Integer findJobIndexByRole(skedMobileDriveJobBuilder.ProposedDriveShift shift, String role) {
        for (Integer i = 0; i < shift.jobs.size(); i++) {
            if (shift.jobs[i].sked_Resource_Role__c == role) {
                return i;
            }
        }
        return null;
    }

    @isTest
    static void testUpdateDriveStaffCapacity_singleShift_matchesHandCalculatedCapacity() {
        sked_Drive__c drive = setupDrive(700);
        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);
        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);

        Test.startTest();
        Decimal driveStaffCapacity = skedMobileDriveJobBuilder.updateDriveStaffCapacity(
            shifts, shiftsMetadata, sdm, drive.sked_Number_of_2RBC_Assets__c, shiftMasterData.timezoneSidId, shiftMasterData.adhocDriverSupportCapacity);
        Test.stopTest();

        // Driver 2*2.2*10 + Driver Support 2*2.2*10 + 2RBC 2*2*10 (both resources covered by the 4 seeded assets) + VP/HH 0 = 128
        System.assertEquals(128, driveStaffCapacity, 'Drive-level staff capacity must match the hand-calculated sum across all capacity-bearing roles');
        System.assertEquals(128, shifts[0].shiftRecord.sked_Max_Donor_Capacity__c, 'The single shift\'s own Max Donor Capacity must equal the drive total');
    }

    @isTest
    static void testUpdateDriveStaffCapacity_usesShiftRecordsOwnLunchBreakOverFreshlyComputedSettings() {
        sked_Drive__c drive = setupDrive(700);
        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);
        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);

        // The freshly computed shift has no lunch break (CO flag is off in setupDrive), but simulate
        // an already-persisted shift where the user turned it on - the source's useDriveShift override
        // means THIS value must win, shrinking draw hours (and therefore Driver/Driver Support capacity).
        shifts[0].shiftRecord.sked_Lunch_Break__c = true;
        shifts[0].shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c = false;

        Test.startTest();
        Decimal driveStaffCapacity = skedMobileDriveJobBuilder.updateDriveStaffCapacity(
            shifts, shiftsMetadata, sdm, drive.sked_Number_of_2RBC_Assets__c, shiftMasterData.timezoneSidId, shiftMasterData.adhocDriverSupportCapacity);
        Test.stopTest();

        // Draw hours drop from 10 to 9.5 (600 - the CO's 30-minute default duration): Driver 2*2.2*9.5
        // + Driver Support 2*2.2*9.5 + 2RBC unchanged at 40 (drawHoursWithoutLunchBreak is never
        // affected by the override) + VP/HH 0 = 123.6, floored to 123.
        System.assertEquals(123, driveStaffCapacity, 'The shift record\'s own lunch break fields must override the freshly computed (lunch-break-off) settings');
    }

    private static List<sked_Drive_Shift__c> queryShiftsWithJobs(Id shiftId) {
        return [
            SELECT Id, (SELECT Id, sked_Resource_Role__c, sked_Dual_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c, sked_Equipment_Subtype__c,
                    sked__Quantity__c, sked_Manually_Created_From__c, sked_VPHH_Quantity__c, sked_APT_Quantity__c, sked_System_Quantity__c,
                    sked_Volunteer_Role__c, sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c
                FROM sked_Jobs__r)
            FROM sked_Drive_Shift__c WHERE Id = :shiftId
        ];
    }

    @isTest
    static void testRestoreUnchangedJobQuantities_noSystemQuantityChange_restoresPersistedQuantityOverFreshValue() {
        sked_Drive__c drive = setupDrive(700);
        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);
        // VP/HH's systemQuantityChanged check nets aptQuantity against this drive-level baseline -
        // align it with the freshly computed value so VP/HH itself never looks "changed" here (this
        // test is about 2RBC's plain quantity restore, not VP/HH's APT-netting behavior).
        drive.sked_APT_Quantity__c = shiftsMetadata.aptSetup;
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildShifts(drive);
        sked__Job__c fresh2rbcJob = findJobByRole(proposed[0], '2RBC');
        System.assertNotEquals(null, fresh2rbcJob, 'Setup check: this drive must propose a 2RBC job');
        Decimal fresh2rbcQuantity = fresh2rbcJob.sked__Quantity__c;

        // A persisted shift with the SAME systemQuantity as every fresh role job (no real system
        // change anywhere on the drive) except 2RBC's plain quantity, which is bumped above the
        // system minimum - simulating a user's manual adjustment that a same-system-quantity regen
        // must preserve rather than silently overwrite.
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        List<sked__Job__c> existingJobs = new List<sked__Job__c>();
        for (sked__Job__c job : proposed[0].jobs) {
            if (String.isBlank(job.sked_Resource_Role__c)) {
                continue; // asset (vehicle/equipment) jobs are never restore-eligible
            }
            Boolean is2rbc = job.sked_Resource_Role__c == '2RBC';
            existingJobs.add(new sked__Job__c(
                sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = job.sked_Resource_Role__c, sked_Dual_Role__c = job.sked_Dual_Role__c,
                sked__Quantity__c = is2rbc ? fresh2rbcQuantity + 2 : job.sked__Quantity__c,
                sked_System_Quantity__c = job.sked_System_Quantity__c, sked_VPHH_Quantity__c = job.sked_VPHH_Quantity__c,
                sked_APT_Quantity__c = job.sked_APT_Quantity__c, sked_Is_Manually_Created__c = false,
                sked__Region__c = regionId, sked__Duration__c = 60));
        }
        insert existingJobs;
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.restoreUnchangedJobQuantities(proposed, existingShifts, shiftsMetadata.aptSetup, drive.sked_APT_Quantity__c, false);
        Test.stopTest();

        System.assertEquals(fresh2rbcQuantity + 2, fresh2rbcJob.sked__Quantity__c,
            'With no system-generated quantity change anywhere on the drive, a role\'s persisted (user-adjusted) quantity must be restored over the freshly computed value');
    }

    // Manually-created jobs are merged in before updateDriveStaffCapacity runs, so capacity already
    // reflects a manual job's contribution. Proves preserveManuallyCreatedJobsForAllShifts must run
    // BEFORE updateDriveStaffCapacity, not after.
    @isTest
    static void testPreserveManuallyCreatedJobsForAllShifts_beforeCapacityCalc_manualJobContributesToStaffCapacity() {
        sked_Drive__c drive = setupDrive(700);
        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);
        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildShifts(drive);

        Decimal staffCapacityWithoutManualJob = skedMobileDriveJobBuilder.updateDriveStaffCapacity(
            proposed, shiftsMetadata, sdm, drive.sked_Number_of_2RBC_Assets__c, shiftMasterData.timezoneSidId, shiftMasterData.adhocDriverSupportCapacity);

        // A manually-created job with a real, non-zero Charge capacity (sked_Charge_Capacity__c = 1.1
        // in the factory's SDM) - preserveManuallyCreatedJobs always keeps a manually-created job as a
        // duplicate alongside any fresh system-generated job of the same role.
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        insert new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Charge',
            sked__Quantity__c = 3, sked_System_Quantity__c = 3, sked_Is_Manually_Created__c = true,
            sked_Manually_Created_From__c = 'Drive Scheduling', sked__Region__c = regionId, sked__Duration__c = 60);
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);
        Decimal staffCapacityWithManualJob = skedMobileDriveJobBuilder.updateDriveStaffCapacity(
            proposed, shiftsMetadata, sdm, drive.sked_Number_of_2RBC_Assets__c, shiftMasterData.timezoneSidId, shiftMasterData.adhocDriverSupportCapacity);
        Test.stopTest();

        System.assert(staffCapacityWithManualJob > staffCapacityWithoutManualJob,
            'A manually-created job merged in before capacity calculation must contribute to staff capacity: without='
            + staffCapacityWithoutManualJob + ', with=' + staffCapacityWithManualJob);
    }

    @isTest
    static void testApplyShiftSetupRollups_noExclusions_sumsJobQuantitiesOntoShiftRecord() {
        sked_Drive__c drive = setupDrive(700);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildShifts(drive);

        Decimal expectedStaffTotal = 0;
        Decimal expectedVehicleTotal = 0;
        for (sked__Job__c job : proposed[0].jobs) {
            Decimal quantity = job.sked__Quantity__c == null ? 0 : job.sked__Quantity__c;
            if (String.isNotBlank(job.sked_Resource_Role__c)) {
                expectedStaffTotal += quantity;
            } else if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                expectedVehicleTotal += quantity;
            }
        }
        System.assert(expectedStaffTotal > 0, 'Setup check: this drive must propose at least one role job');

        Test.startTest();
        skedMobileDriveJobBuilder.applyShiftSetupRollups(proposed, new Set<String>());
        Test.stopTest();

        System.assertEquals(expectedStaffTotal, proposed[0].shiftRecord.sked_Staff_Setup__c,
            'With no excluded roles, Staff_Setup__c must sum every role job\'s quantity');
        System.assertEquals(expectedVehicleTotal, proposed[0].shiftRecord.sked_Vehicles_Needed__c,
            'Vehicles_Needed__c must sum every vehicle-asset job\'s quantity');
    }

    @isTest
    static void testApplyShiftSetupRollups_excludedRole_isDroppedFromStaffSetup() {
        sked_Drive__c drive = setupDrive(700);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildShifts(drive);
        sked__Job__c driverJob = findJobByRole(proposed[0], 'Driver');
        System.assertNotEquals(null, driverJob, 'Setup check: a 2-vehicle drive must propose a Driver job');

        Decimal expectedStaffTotalWithoutDriver = 0;
        for (sked__Job__c job : proposed[0].jobs) {
            if (String.isNotBlank(job.sked_Resource_Role__c) && job.sked_Resource_Role__c != 'Driver') {
                expectedStaffTotalWithoutDriver += job.sked__Quantity__c == null ? 0 : job.sked__Quantity__c;
            }
        }

        Test.startTest();
        skedMobileDriveJobBuilder.applyShiftSetupRollups(proposed, new Set<String>{ 'Driver' });
        Test.stopTest();

        System.assertEquals(expectedStaffTotalWithoutDriver, proposed[0].shiftRecord.sked_Staff_Setup__c,
            'A role in staffSetupExcludedRoleNames must be dropped from Staff_Setup__c entirely');
    }

    // A preserved existing volunteer/donor-ambassador job has neither a resourceRole nor an assetType
    // (this port doesn't build volunteer jobs itself - see class header) - previously
    // sked_Volunteer_Setup__c was hardcoded to 0 regardless, silently zeroing a real preserved job's
    // contribution every regen.
    @isTest
    static void testApplyShiftSetupRollups_preservedVolunteerJob_sumsIntoVolunteerSetupInsteadOfZero() {
        sked_Drive__c drive = setupDrive(700);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildShifts(drive);
        proposed[0].jobs.add(new sked__Job__c(sked__Quantity__c = 3));

        Test.startTest();
        skedMobileDriveJobBuilder.applyShiftSetupRollups(proposed, new Set<String>());
        Test.stopTest();

        System.assertEquals(3, proposed[0].shiftRecord.sked_Volunteer_Setup__c,
            'A job with neither resourceRole nor assetType must sum into Volunteer_Setup__c, not be silently dropped to 0');
    }

    // Run in reverse by preserveManuallyCreatedJobs to decide whether a manually-created existing job
    // is already "covered" by a fresh system job of the same role. A manually-created probe must
    // only ever match an equally-manually-created candidate - our fresh proposed jobs are never
    // manually created, so a user-added DUPLICATE-role manual job must survive alongside the
    // system-generated one, never be dropped in favor of it.
    @isTest
    static void testApplyExistingRecordIds_manuallyCreatedDuplicateOfSystemRole_isPreservedAlongsideFreshJob() {
        sked_Drive__c drive = setupDrive(700);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        sked__Job__c fresh2rbcJob = findJobByRole(shifts[0], '2RBC');
        System.assertNotEquals(null, fresh2rbcJob, 'Setup check: this drive setup must system-generate a positive-quantity 2RBC job');

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        sked__Job__c existingSystemJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = '2RBC', sked__Quantity__c = fresh2rbcJob.sked__Quantity__c,
            sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        sked__Job__c existingManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = '2RBC', sked__Quantity__c = 1,
            sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert new List<sked__Job__c>{ existingSystemJob, existingManualJob };

        List<sked_Drive_Shift__c> existingShifts = [
            SELECT Id, (SELECT Id, sked_Resource_Role__c, sked_Dual_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c,
                    sked_Equipment_Subtype__c, sked__Quantity__c, sked_Manually_Created_From__c, sked_VPHH_Quantity__c, sked_APT_Quantity__c,
                    sked_Volunteer_Role__c, sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c
                FROM sked_Jobs__r)
            FROM sked_Drive_Shift__c
            WHERE Id = :existingShift.Id
        ];

        Test.startTest();
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(shifts, existingShifts);
        Test.stopTest();

        Integer twoRbcJobCount = 0;
        Boolean manualJobPreserved = false;
        for (sked__Job__c job : shifts[0].jobs) {
            if (job.sked_Resource_Role__c == '2RBC') {
                twoRbcJobCount++;
                if (job.Id == existingManualJob.Id) {
                    manualJobPreserved = true;
                }
            }
        }
        System.assertEquals(2, twoRbcJobCount, 'Both the system-generated 2RBC job (Id reused) and the manually-created duplicate must be present after applyExistingRecordIds');
        System.assert(manualJobPreserved, 'A manually-created duplicate-role job must be preserved, not silently dropped because a fresh system job of the same role exists');
    }

    // This port never computes sponsorVolunteerQuantity itself (a separate, non-regen workflow owns
    // it) - it must survive from the existing volunteer job onto the freshly-built one every regen.
    @isTest
    static void testCarryForwardVolunteerSponsorQuantity_preservesExistingSponsorQuantity() {
        sked_Drive__c drive = setupDrive(700);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive, new List<Collection_Operation_Time_Block__c>(), 5);

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        insert new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Volunteer_Role__c = skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR,
            sked_Redcross_Volunteer_Quantity__c = 3, sked_Sponsor_Volunteer_Quantity__c = 7, sked__Quantity__c = 10,
            sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        List<sked_Drive_Shift__c> existingShifts = [
            SELECT Id, (SELECT Id, sked_Volunteer_Role__c, sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c, sked_Is_Manually_Created__c FROM sked_Jobs__r)
            FROM sked_Drive_Shift__c
            WHERE Id = :existingShift.Id
        ];

        Test.startTest();
        skedMobileDriveJobBuilder.carryForwardVolunteerSponsorQuantity(shifts, existingShifts);
        Test.stopTest();

        sked__Job__c volunteerJob = findVolunteerJob(shifts[0]);
        System.assertNotEquals(null, volunteerJob, 'Setup check: a fresh volunteer job must exist to carry forward onto');
        System.assertEquals(7, volunteerJob.sked_Sponsor_Volunteer_Quantity__c, 'The existing sponsor quantity must be carried forward, not left at the freshly-built 0');
        System.assertEquals(12, volunteerJob.sked__Quantity__c, 'Total quantity must be recomputed as redcross (5) + carried-forward sponsor (7)');
    }

    // Exercises the real production call order (preserveManuallyCreatedJobsForAllShifts, THEN
    // applyExistingRecordIds) - the previous test above only calls the first step, so it can't catch
    // applyExistingRecordIds re-matching an already-Id-stamped manually-preserved job against the
    // system job of the same role and overwriting its Id, which would leave two jobs sharing one Id.
    @isTest
    static void testApplyExistingRecordIds_afterManualJobAlreadyPreserved_doesNotOverwriteItsId() {
        sked_Drive__c drive = setupDrive(700);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        sked__Job__c fresh2rbcJob = findJobByRole(shifts[0], '2RBC');
        System.assertNotEquals(null, fresh2rbcJob, 'Setup check: this drive setup must system-generate a positive-quantity 2RBC job');

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        sked__Job__c existingSystemJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = '2RBC', sked__Quantity__c = fresh2rbcJob.sked__Quantity__c,
            sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        sked__Job__c existingManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = '2RBC', sked__Quantity__c = 1,
            sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert new List<sked__Job__c>{ existingSystemJob, existingManualJob };

        List<sked_Drive_Shift__c> existingShifts = [
            SELECT Id, (SELECT Id, sked_Resource_Role__c, sked_Dual_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c,
                    sked_Equipment_Subtype__c, sked__Quantity__c, sked_Manually_Created_From__c, sked_VPHH_Quantity__c, sked_APT_Quantity__c,
                    sked_Volunteer_Role__c, sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c
                FROM sked_Jobs__r)
            FROM sked_Drive_Shift__c
            WHERE Id = :existingShift.Id
        ];

        Test.startTest();
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(shifts, existingShifts);
        skedMobileDriveJobBuilder.applyExistingRecordIds(shifts, existingShifts);
        Test.stopTest();

        Set<Id> twoRbcJobIds = new Set<Id>();
        for (sked__Job__c job : shifts[0].jobs) {
            if (job.sked_Resource_Role__c == '2RBC') {
                twoRbcJobIds.add(job.Id);
            }
        }
        System.assertEquals(2, twoRbcJobIds.size(),
            'The system job and the manually-created duplicate must retain two DISTINCT Ids after applyExistingRecordIds runs - a collision means one got silently overwritten');
        System.assert(twoRbcJobIds.contains(existingSystemJob.Id), 'The system-generated job must carry the persisted system job\'s Id');
        System.assert(twoRbcJobIds.contains(existingManualJob.Id), 'The manually-created job must still carry its OWN persisted Id, not the system job\'s');
    }

    @isTest
    static void testRecalculateLunchBreakForAllShifts_manualJobPushesStaffCountAcrossBucket_updatesDuration() {
        sked_Drive__c drive = setupDrive(700);
        Biomed_Collection_Op_Center__c collectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Id = :drive.sked_Collection_Operation__c];
        collectionOperation.sked_Lunch_Break__c = true;
        collectionOperation.sked_Lunch_Break_Before_Draw_Hours__c = false;
        collectionOperation.sked_Lunch_Break_Duration_Mobile__c = '30';
        update collectionOperation;
        drive = queryDrive(drive.Id);

        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = '30');
        insert setting;
        insert new List<sked_Lunch_Break_Definition__c>{
            new sked_Lunch_Break_Definition__c(
                sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = 30,
                sked_Min_Number_of_Staff__c = 0, sked_Max_Number_of_Staff__c = 50, sked_Slot_Reduction__c = 0
            ),
            new sked_Lunch_Break_Definition__c(
                sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = 90,
                sked_Min_Number_of_Staff__c = 51, sked_Max_Number_of_Staff__c = 1000, sked_Slot_Reduction__c = 0
            )
        };

        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);
        sked_Staffing_Decision_Matrix__c sdm = skedMobileRoleQuantityCalculator.loadStaffingDecisionMatrix(drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c);
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantities = skedMobileRoleQuantityCalculator.calculateRoleQuantities(
            drive, shiftsMetadata, sdm, shiftMasterData.driveSite.sked_Physical_Location_Type__c, shiftMasterData.timezoneSidId);
        Decimal numberOfVehicles = skedMobileRoleQuantityCalculator.calculateVehicleQuantity(drive);
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = skedMobileLunchBreakCalculator.loadLunchBreakSettings();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = skedMobileDriveJobBuilder.buildProposedDriveShifts(
            drive, shiftsMetadata, roleQuantities, numberOfVehicles, drive.sked_Number_of_2RBC_Assets__c,
            shiftMasterData.timezoneSidId, lunchBreakSettingsConfig, shiftMasterData.jobTagsByResourceType, new List<Collection_Operation_Time_Block__c>(), 0);

        System.assertEquals(30, proposed[0].shiftRecord.sked_Lunch_Break_Duration__c,
            'Setup check: the fresh (pre-manual-job) staff count must land in the low-staff bucket');

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        sked__Job__c manualDriverSupport = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Driver Support', sked__Quantity__c = 100,
            sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert manualDriverSupport;
        List<sked_Drive_Shift__c> existingShifts = [
            SELECT Id, (SELECT Id, sked_Resource_Role__c, sked_Dual_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c,
                    sked_Equipment_Subtype__c, sked__Quantity__c, sked_Manually_Created_From__c, sked_VPHH_Quantity__c, sked_APT_Quantity__c,
                    sked_Volunteer_Role__c, sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c
                FROM sked_Jobs__r)
            FROM sked_Drive_Shift__c
            WHERE Id = :existingShift.Id
        ];

        Test.startTest();
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);
        skedMobileDriveJobBuilder.recalculateLunchBreakForAllShifts(proposed, shiftsMetadata, lunchBreakSettingsConfig, shiftMasterData.timezoneSidId, false, existingShifts);
        Test.stopTest();

        System.assertEquals(90, proposed[0].shiftRecord.sked_Lunch_Break_Duration__c,
            'Once the manually-preserved Driver Support job pushes staff count past 50, the recalculated lunch break duration must reflect the high-staff bucket, not the stale pre-merge value');
    }

    // ===== lockLunchBreak / restoreLunchBreak (mobileGenerator.js:2243-2249) =====

    private static sked_Drive_Shift__c setupLunchBreakLockFixture(sked_Drive__c drive, Boolean lockDrive, Boolean existingLunchBreak, Boolean existingLunchBreakBeforeDrawHours) {
        drive.sked_Lock_Lunch_Break__c = lockDrive;
        update drive;

        Biomed_Collection_Op_Center__c collectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Id = :drive.sked_Collection_Operation__c];
        collectionOperation.sked_Lunch_Break__c = true;
        collectionOperation.sked_Lunch_Break_Before_Draw_Hours__c = false;
        collectionOperation.sked_Lunch_Break_Duration_Mobile__c = '30';
        collectionOperation.sked_Unpaid_Lunch_Break_Duration__c = 15;
        update collectionOperation;

        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = '30');
        insert setting;
        insert new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Setting__c = setting.Id, sked_Lunch_Break_Duration__c = 30,
            sked_Min_Number_of_Staff__c = 0, sked_Max_Number_of_Staff__c = 1000, sked_Slot_Reduction__c = 0);

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Lunch_Break__c = existingLunchBreak, sked_Lunch_Break_Before_Draw_Hours__c = existingLunchBreakBeforeDrawHours);
        insert existingShift;
        return existingShift;
    }

    @isTest
    static void testRecalculateLunchBreakForAllShifts_lockedWithExistingShift_restoresOnOffFlagOverFreshValue() {
        sked_Drive__c drive = setupDrive(700);
        sked_Drive_Shift__c existingShift = setupLunchBreakLockFixture(drive, true, false, false);
        drive = queryDrive(drive.Id);

        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = skedMobileLunchBreakCalculator.loadLunchBreakSettings();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = new List<sked_Drive_Shift__c>{
            [SELECT Id, sked_Lunch_Break__c, sked_Lunch_Break_Before_Draw_Hours__c FROM sked_Drive_Shift__c WHERE Id = :existingShift.Id]
        };

        System.assertEquals(true, proposed[0].shiftRecord.sked_Lunch_Break__c, 'Setup check: the fresh (CO-derived) value must be lunch break ON before recalculation');

        Test.startTest();
        skedMobileDriveJobBuilder.recalculateLunchBreakForAllShifts(
            proposed, shiftsMetadata, lunchBreakSettingsConfig, shiftMasterData.timezoneSidId, drive.sked_Lock_Lunch_Break__c, existingShifts);
        Test.stopTest();

        System.assertEquals(false, proposed[0].shiftRecord.sked_Lunch_Break__c,
            'With the drive locked, the existing shift\'s OFF flag must be restored over the freshly-computed ON value');
        System.assertEquals(null, proposed[0].shiftRecord.sked_Lunch_Break_Duration__c, 'A restored-OFF lunch break must clear the duration/start/end fields, same as the fresh-OFF path');
    }

    @isTest
    static void testRecalculateLunchBreakForAllShifts_notLocked_ignoresExistingShiftFlag() {
        sked_Drive__c drive = setupDrive(700);
        sked_Drive_Shift__c existingShift = setupLunchBreakLockFixture(drive, false, false, false);
        drive = queryDrive(drive.Id);

        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = skedMobileLunchBreakCalculator.loadLunchBreakSettings();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = new List<sked_Drive_Shift__c>{
            [SELECT Id, sked_Lunch_Break__c, sked_Lunch_Break_Before_Draw_Hours__c FROM sked_Drive_Shift__c WHERE Id = :existingShift.Id]
        };

        Test.startTest();
        skedMobileDriveJobBuilder.recalculateLunchBreakForAllShifts(
            proposed, shiftsMetadata, lunchBreakSettingsConfig, shiftMasterData.timezoneSidId, drive.sked_Lock_Lunch_Break__c, existingShifts);
        Test.stopTest();

        System.assertEquals(true, proposed[0].shiftRecord.sked_Lunch_Break__c,
            'With the drive NOT locked, the existing shift\'s OFF flag must be ignored - the fresh CO-derived ON value wins');
    }

    @isTest
    static void testRecalculateLunchBreakForAllShifts_lockedRestoresBeforeDrawHours_usesUnpaidDurationNotBucketedDuration() {
        sked_Drive__c drive = setupDrive(700);
        sked_Drive_Shift__c existingShift = setupLunchBreakLockFixture(drive, true, true, true);
        drive = queryDrive(drive.Id);

        skedMobileDriveShiftCalculator.MasterData shiftMasterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = skedMobileLunchBreakCalculator.loadLunchBreakSettings();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = new List<sked_Drive_Shift__c>{
            [SELECT Id, sked_Lunch_Break__c, sked_Lunch_Break_Before_Draw_Hours__c FROM sked_Drive_Shift__c WHERE Id = :existingShift.Id]
        };

        System.assertEquals(false, proposed[0].shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c, 'Setup check: the fresh CO-derived value must be during-draw-hours before recalculation');

        Test.startTest();
        skedMobileDriveJobBuilder.recalculateLunchBreakForAllShifts(
            proposed, shiftsMetadata, lunchBreakSettingsConfig, shiftMasterData.timezoneSidId, drive.sked_Lock_Lunch_Break__c, existingShifts);
        Test.stopTest();

        System.assertEquals(true, proposed[0].shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c, 'The existing shift\'s before-draw-hours flag must be restored over the fresh during-draw-hours value');
        // Proves the REST of populateLunchBreakTime branches off the restored flag, not the stale
        // fresh one: before-draw-hours uses the CO's flat unpaidLunchBreakDuration (15), never the
        // staff-count-bucketed sked_Lunch_Break_Definition__c duration (30) the fresh path would use.
        System.assertEquals(15, proposed[0].shiftRecord.sked_Lunch_Break_Duration__c,
            'Once restored to before-draw-hours, duration must come from the CO\'s unpaid lunch break duration, not the bucketed during-draw-hours duration');
    }

    // ===== calculateDriveProductivityPlanned =====
    // Pure calculation over in-memory objects - no DML needed, so these build minimal
    // DriveShiftsMetadata/ProposedDriveShift fixtures directly rather than going through the full
    // buildShifts() pipeline (which produces multiple SDM-driven roles, too many terms to hand-verify).

    private static sked_Drive__c buildProductivityDrive() {
        return new sked_Drive__c(sked_Drive_Date__c = Date.today(), sked_Start_Time__c = Time.newInstance(8, 0, 0, 0), sked_End_Time__c = Time.newInstance(16, 0, 0, 0));
    }

    private static skedMobileDriveShiftCalculator.DriveShiftsMetadata buildProductivityShiftsMetadata(Boolean lunchBreak, Boolean lunchBreakBeforeDrawHours) {
        skedLunchBreakSettings lunchBreakSettings = new skedLunchBreakSettings();
        lunchBreakSettings.lunchBreak = lunchBreak;
        lunchBreakSettings.lunchBreakBeforeDrawHours = lunchBreakBeforeDrawHours;
        lunchBreakSettings.maximumLunchBreakDuration = 30;

        skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata = new skedMobileDriveShiftCalculator.DriveShiftMetadata();
        shiftMetadata.driveDate = Date.today();
        shiftMetadata.startTime = Time.newInstance(8, 0, 0, 0);
        shiftMetadata.endTime = Time.newInstance(16, 0, 0, 0);
        shiftMetadata.lunchBreakSettings = lunchBreakSettings;

        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = new skedMobileDriveShiftCalculator.DriveShiftsMetadata();
        shiftsMetadata.driveShifts.add(shiftMetadata);
        return shiftsMetadata;
    }

    // The shift record's OWN lunch-break flags (not shiftsMetadata's fresh-config copy) are what
    // calculateDriveProductivityPlanned actually reads now - mirrored here from the same
    // shiftsMetadata so every caller's already-consistent (lunchBreak, lunchBreakBeforeDrawHours)
    // pair doesn't need to be passed twice.
    private static skedMobileDriveJobBuilder.ProposedDriveShift buildProductivityShift(
            List<sked__Job__c> jobs, skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata) {
        skedMobileDriveJobBuilder.ProposedDriveShift shift = new skedMobileDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        skedLunchBreakSettings lunchBreakSettings = shiftsMetadata.driveShifts[0].lunchBreakSettings;
        shift.shiftRecord.sked_Lunch_Break__c = lunchBreakSettings.lunchBreak;
        shift.shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c = lunchBreakSettings.lunchBreakBeforeDrawHours;
        shift.jobs = jobs;
        return shift;
    }

    @isTest
    static void testCalculateDriveProductivityPlanned_singleStaffedJob_matchesHandCalculatedValue() {
        sked_Drive__c drive = buildProductivityDrive();
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildProductivityShiftsMetadata(false, false);
        sked__Job__c driverJob = new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = new List<skedMobileDriveJobBuilder.ProposedDriveShift>{
            buildProductivityShift(new List<sked__Job__c>{ driverJob }, shiftsMetadata)
        };

        Test.startTest();
        // No lunch break: draw duration is the full 8am-4pm window = 480 minutes. quantity 1 * 480 = 480.
        // totalProductsProjected 240 * 60 / 480 = 30.00.
        Decimal result = skedMobileDriveJobBuilder.calculateDriveProductivityPlanned(drive, shifts, shiftsMetadata, 240, 'America/New_York');
        Test.stopTest();

        System.assertEquals(30.00, result, 'Productivity planned must match the hand-calculated totalProductsProjected/(weighted staff-hours) formula');
    }

    @isTest
    static void testCalculateDriveProductivityPlanned_excludesManuallyCreatedAndAssetJobs_resultUnchanged() {
        sked_Drive__c drive = buildProductivityDrive();
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildProductivityShiftsMetadata(false, false);
        sked__Job__c driverJob = new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1);
        sked__Job__c manualDriverJob = new sked__Job__c(
            sked_Resource_Role__c = 'Driver', sked__Quantity__c = 100, sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Staffing Modal');
        sked__Job__c vehicleJob = new sked__Job__c(sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE, sked__Quantity__c = 5);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = new List<skedMobileDriveJobBuilder.ProposedDriveShift>{
            buildProductivityShift(new List<sked__Job__c>{ driverJob, manualDriverJob, vehicleJob }, shiftsMetadata)
        };

        Test.startTest();
        Decimal result = skedMobileDriveJobBuilder.calculateDriveProductivityPlanned(drive, shifts, shiftsMetadata, 240, 'America/New_York');
        Test.stopTest();

        System.assertEquals(30.00, result, 'A Staffing-Modal-manual job and an asset job must both be excluded from the weighted sum, leaving the result identical to the single-staffed-job case');
    }

    @isTest
    static void testCalculateDriveProductivityPlanned_lunchBreakDuringDrawHours_subtractsFromDenominator() {
        sked_Drive__c drive = buildProductivityDrive();
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildProductivityShiftsMetadata(true, false);
        sked__Job__c driverJob = new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = new List<skedMobileDriveJobBuilder.ProposedDriveShift>{
            buildProductivityShift(new List<sked__Job__c>{ driverJob }, shiftsMetadata)
        };

        Test.startTest();
        // Lunch break during draw hours (not before) subtracts the 30-min maximum: 480 - 30 = 450.
        // 450 * 60 / 450 = 60.00.
        Decimal result = skedMobileDriveJobBuilder.calculateDriveProductivityPlanned(drive, shifts, shiftsMetadata, 450, 'America/New_York');
        Test.stopTest();

        System.assertEquals(60.00, result, 'Lunch break during draw hours must shrink the denominator, matching calculateDrawHoursInMinutes\' own subtraction');
    }

    // recalculateLunchBreakForAllShifts' lock/restore logic (sked_Lock_Lunch_Break__c) can leave the
    // shift record's own flags DIFFERENT from shiftsMetadata's fresh CO-derived copy - this proves
    // the shift record's (restored) flags win, not the stale fresh-config ones.
    @isTest
    static void testCalculateDriveProductivityPlanned_shiftRecordFlagsDivergeFromFreshMetadata_usesShiftRecord() {
        sked_Drive__c drive = buildProductivityDrive();
        // Fresh CO-derived config says lunch break IS during draw hours...
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildProductivityShiftsMetadata(true, false);
        sked__Job__c driverJob = new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1);
        skedMobileDriveJobBuilder.ProposedDriveShift shift = buildProductivityShift(new List<sked__Job__c>{ driverJob }, shiftsMetadata);
        // ...but lock/restore left the ACTUAL shift record with lunch break turned off entirely.
        shift.shiftRecord.sked_Lunch_Break__c = false;
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        // No lunch break subtracted (shift record wins): full 480-minute window. 240 * 60 / 480 = 30.00,
        // not 60.00 (which testCalculateDriveProductivityPlanned_lunchBreakDuringDrawHours_subtractsFromDenominator
        // would get from shiftsMetadata's stale "lunch break on" copy).
        Decimal result = skedMobileDriveJobBuilder.calculateDriveProductivityPlanned(drive, shifts, shiftsMetadata, 240, 'America/New_York');
        Test.stopTest();

        System.assertEquals(30.00, result, 'The shift record\'s own (possibly restored) lunch-break flag must be used, not shiftsMetadata\'s fresh, pre-restore copy');
    }

    @isTest
    static void testCalculateDriveProductivityPlanned_lunchBreakBeforeDrawHours_notSubtracted() {
        sked_Drive__c drive = buildProductivityDrive();
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildProductivityShiftsMetadata(true, true);
        sked__Job__c driverJob = new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = new List<skedMobileDriveJobBuilder.ProposedDriveShift>{
            buildProductivityShift(new List<sked__Job__c>{ driverJob }, shiftsMetadata)
        };

        Test.startTest();
        // lunchBreakBeforeDrawHours true means lunch happens outside the draw window, so the full
        // 480-minute window counts unreduced: 450 * 60 / 480 = 56.25, not 60.00 as in the sibling test.
        Decimal result = skedMobileDriveJobBuilder.calculateDriveProductivityPlanned(drive, shifts, shiftsMetadata, 450, 'America/New_York');
        Test.stopTest();

        System.assertEquals(56.25, result, 'Lunch break before draw hours must NOT be subtracted from the denominator - the opposite polarity from the during-draw-hours case');
    }

    @isTest
    static void testCalculateDriveProductivityPlanned_zeroWeightedSum_returnsNull() {
        sked_Drive__c drive = buildProductivityDrive();
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildProductivityShiftsMetadata(false, false);
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = new List<skedMobileDriveJobBuilder.ProposedDriveShift>{
            buildProductivityShift(new List<sked__Job__c>(), shiftsMetadata)
        };

        Test.startTest();
        Decimal result = skedMobileDriveJobBuilder.calculateDriveProductivityPlanned(drive, shifts, shiftsMetadata, 240, 'America/New_York');
        Test.stopTest();

        System.assertEquals(null, result, 'With no staffed jobs the weighted sum is 0, so the caller must leave the field untouched rather than writing a division result');
    }

    // ===== recalculateVphhQuantityForAllShifts (mobileGenerator.js:1701-1770, helper.js:4278-4305) =====

    private static sked_Staffing_Decision_Matrix__c buildVphhSdm(Decimal driverSupportCapacity, Decimal vpHhCapacity) {
        return new sked_Staffing_Decision_Matrix__c(
            sked_VP_HH_Capacity__c = vpHhCapacity, sked_Driver_Capacity__c = 0,
            sked_Driver_Support_Capacity__c = driverSupportCapacity, sked_2RBC_Staff_Capacity__c = 0, sked_Charge_Capacity__c = 0
        );
    }

    private static skedMobileDriveShiftCalculator.DriveShiftsMetadata buildVphhShiftsMetadata(Decimal donorsScheduled) {
        skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata = new skedMobileDriveShiftCalculator.DriveShiftMetadata();
        shiftMetadata.driveDate = Date.today();
        shiftMetadata.startTime = Time.newInstance(8, 0, 0, 0);
        shiftMetadata.endTime = Time.newInstance(16, 0, 0, 0);
        shiftMetadata.donorsScheduled = donorsScheduled;
        shiftMetadata.lunchBreakSettings = new skedLunchBreakSettings();
        shiftMetadata.resourceRoleGroupRoleTimeDataMap = new Map<String, skedMobileDriveShiftCalculator.RoleTimeData>();

        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = new skedMobileDriveShiftCalculator.DriveShiftsMetadata();
        shiftsMetadata.driveShifts.add(shiftMetadata);
        return shiftsMetadata;
    }

    @isTest
    static void testRecalculateVphhQuantityForAllShifts_manualDriverSupportHoldsCapacity_createsNewVphhJob() {
        sked_Drive__c drive = new sked_Drive__c();
        sked_Staffing_Decision_Matrix__c sdm = buildVphhSdm(5, 2);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildVphhShiftsMetadata(50);
        sked__Job__c driverSupportJob = new sked__Job__c(
            sked_Resource_Role__c = 'Driver Support', sked__Quantity__c = 1,
            sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Drive Scheduling'
        );
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = new List<skedMobileDriveJobBuilder.ProposedDriveShift>{
            buildProductivityShift(new List<sked__Job__c>{ driverSupportJob }, shiftsMetadata)
        };

        Test.startTest();
        // Driver Support capacity: 1 * 5 * 8hrs = 40. totalVpHhCapacity = 50 - 40 = 10.
        // noOfVpHhStaffs = ceil(10 / 2 / 8) = ceil(0.625) = 1.
        skedMobileDriveJobBuilder.recalculateVphhQuantityForAllShifts(shifts, shiftsMetadata, drive, sdm, 0, 'America/New_York', 0);
        Test.stopTest();

        System.assertEquals(2, shifts[0].jobs.size(), 'A new VP/HH job must be added alongside the manually-created Driver Support job');
        sked__Job__c vphhJob = shifts[0].jobs[1];
        System.assertEquals('VP/HH', vphhJob.sked_Resource_Role__c, 'The newly added job must be VP/HH');
        System.assertEquals(1, vphhJob.sked_VPHH_Quantity__c, 'VP/HH quantity must match the hand-calculated ceil(10/2/8) = 1');
        System.assertEquals(1, vphhJob.sked__Quantity__c, 'Quantity must equal vphhQuantity + aptQuantity(0)');
    }

    @isTest
    static void testRecalculateVphhQuantityForAllShifts_noManuallyCreatedJobHoldsCapacity_noVphhJobAdded() {
        sked_Drive__c drive = new sked_Drive__c();
        // Driver Support capacity is 0 and no adhoc fallback capacity is provided (0), so the manually
        // created job never holds capacity - the gate must skip recalculation entirely.
        sked_Staffing_Decision_Matrix__c sdm = buildVphhSdm(0, 2);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildVphhShiftsMetadata(50);
        sked__Job__c driverSupportJob = new sked__Job__c(
            sked_Resource_Role__c = 'Driver Support', sked__Quantity__c = 1,
            sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Drive Scheduling'
        );
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = new List<skedMobileDriveJobBuilder.ProposedDriveShift>{
            buildProductivityShift(new List<sked__Job__c>{ driverSupportJob }, shiftsMetadata)
        };

        Test.startTest();
        skedMobileDriveJobBuilder.recalculateVphhQuantityForAllShifts(shifts, shiftsMetadata, drive, sdm, 0, 'America/New_York', 0);
        Test.stopTest();

        System.assertEquals(1, shifts[0].jobs.size(), 'With no manually-created job holding capacity, the gate must skip recalculation and no VP/HH job is added');
    }

    @isTest
    static void testRecalculateVphhQuantityForAllShifts_existingVphhJobFromStaffingModal_leftUntouched() {
        sked_Drive__c drive = new sked_Drive__c();
        sked_Staffing_Decision_Matrix__c sdm = buildVphhSdm(5, 2);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildVphhShiftsMetadata(50);
        sked__Job__c driverSupportJob = new sked__Job__c(
            sked_Resource_Role__c = 'Driver Support', sked__Quantity__c = 1,
            sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Drive Scheduling'
        );
        sked__Job__c modalVphhJob = new sked__Job__c(
            sked_Resource_Role__c = 'VP/HH', sked_VPHH_Quantity__c = 99, sked__Quantity__c = 99,
            sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Staffing Modal'
        );
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = new List<skedMobileDriveJobBuilder.ProposedDriveShift>{
            buildProductivityShift(new List<sked__Job__c>{ driverSupportJob, modalVphhJob }, shiftsMetadata)
        };

        Test.startTest();
        skedMobileDriveJobBuilder.recalculateVphhQuantityForAllShifts(shifts, shiftsMetadata, drive, sdm, 0, 'America/New_York', 0);
        Test.stopTest();

        System.assertEquals(2, shifts[0].jobs.size(), 'No job must be added or removed');
        System.assertEquals(99, modalVphhJob.sked_VPHH_Quantity__c, 'A Staffing-Modal-created VP/HH job must never be recalculated, regardless of the computed value');
    }

    // ===== The drive-type-neutral seam (ShiftJobPopulator / ManualJobPreservationConfig) =====

    private static List<skedMobileDriveJobBuilder.ProposedDriveShift> buildSeamShifts() {
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildVphhShiftsMetadata(50);
        shiftsMetadata.aptSetup = 7;
        shiftsMetadata.driveShifts[0].key = 'seam-shift';
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantities =
            new Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>>{
                'seam-shift' => new Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>()
            };
        return skedMobileDriveJobBuilder.buildProposedDriveShifts(new sked_Drive__c(), shiftsMetadata, roleQuantities, 0, 0,
            'America/New_York', new List<sked_Lunch_Break_Setting__c>(),
            new Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>>(), new List<Collection_Operation_Time_Block__c>(), 0);
    }

    // The Mobile entry point delegates to the neutral overload, which takes the shift-level APT setup
    // as a parameter - nothing else asserts sked_APT_Setup__c before applyShiftSetupRollups overwrites it.
    @isTest
    static void testBuildProposedDriveShifts_mobileEntryPoint_writesMetadataAptSetupOntoTheShiftRecord() {
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = buildSeamShifts();
        Test.stopTest();

        System.assertEquals(7, shifts[0].shiftRecord.sked_APT_Setup__c, 'A Mobile shift record must still carry the metadata\'s drive-level APT setup at build time');
    }

    @isTest
    static void testPreserveManuallyCreatedJobsForAllShifts_defaultConfig_existingDriverJobNotPreserved() {
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = buildSeamShifts();
        Integer jobCountBefore = shifts[0].jobs.size();
        String jobJson = '{"attributes":{"type":"sked__Job__c"},"sked_Resource_Role__c":"Driver","sked__Quantity__c":1,"sked_Is_Manually_Created__c":false}';
        String shiftJson = '{"attributes":{"type":"sked_Drive_Shift__c"},"sked_Jobs__r":{"totalSize":1,"done":true,"records":[' + jobJson + ']}}';
        List<sked_Drive_Shift__c> existingShifts = new List<sked_Drive_Shift__c>{
            (sked_Drive_Shift__c) JSON.deserialize(shiftJson, sked_Drive_Shift__c.class)
        };

        Test.startTest();
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(shifts, existingShifts);
        Test.stopTest();

        System.assertEquals(jobCountBefore, shifts[0].jobs.size(),
            'Driver is a Mobile system role, so the default config must still treat an existing Driver job as system-generated and not carry it forward');
    }
}
