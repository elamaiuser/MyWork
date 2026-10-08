@isTest
private class skedMobileJobCarryForward_Test {

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

    private static sked_Drive__c setupSingleShiftDrive() {
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

        return queryDrive(testDrive1.Id);
    }

    private static List<skedMobileDriveJobBuilder.ProposedDriveShift> buildProposedShifts(sked_Drive__c drive) {
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

    private static List<sked_Drive_Shift__c> queryExistingShiftsWithJobs(Id driveId) {
        return [
            SELECT Id, (SELECT Id, sked_Resource_Role__c, sked_Dual_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c, sked_Equipment_Subtype__c,
                    sked__Quantity__c, sked_Manually_Created_From__c, sked_VPHH_Quantity__c, sked_APT_Quantity__c,
                    sked_Volunteer_Role__c, sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c
                FROM sked_Jobs__r)
            FROM sked_Drive_Shift__c
            WHERE sked_Drive__c = :driveId
            ORDER BY sked_Start_Time__c
        ];
    }

    private static skedMobileDriveJobBuilder.ProposedDriveShift buildProposedShiftWithJobs(List<sked__Job__c> jobs) {
        skedMobileDriveJobBuilder.ProposedDriveShift shift = new skedMobileDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.addAll(jobs);
        return shift;
    }

    // sked__Job__c has a validation rule requiring sked__Region__c - the real generation flow
    // populates it, but a test inserting Job records directly must set it explicitly.
    private static Id queryAnyRegionId() {
        return [SELECT Id FROM sked__Region__c LIMIT 1].Id;
    }

    private static sked__Job__c findProposedJobByRole(skedMobileDriveJobBuilder.ProposedDriveShift shift, String role) {
        for (sked__Job__c job : shift.jobs) {
            if (job.sked_Resource_Role__c == role) {
                return job;
            }
        }
        return null;
    }

    private static Integer findProposedJobIndexByRole(skedMobileDriveJobBuilder.ProposedDriveShift shift, String role) {
        for (Integer i = 0; i < shift.jobs.size(); i++) {
            if (shift.jobs[i].sked_Resource_Role__c == role) {
                return i;
            }
        }
        return null;
    }

    private static Boolean containsTagId(List<sked__Job_Tag__c> jobTags, Id tagId) {
        for (sked__Job_Tag__c jobTag : jobTags) {
            if (jobTag.sked__Tag__c == tagId) {
                return true;
            }
        }
        return false;
    }

    @isTest
    static void testApplyExistingRecordIds_matchesRoleJobByResourceRoleIgnoringManuallyCreatedDuplicate() {
        sked_Drive__c drive = setupSingleShiftDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;

        Id regionId = queryAnyRegionId();
        sked__Job__c manuallyCreatedDriver = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1, sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        sked__Job__c systemDriver = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2, sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert new List<sked__Job__c>{ manuallyCreatedDriver, systemDriver };

        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildProposedShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(existingShift.Id, proposed[0].shiftRecord.Id, 'The single proposed shift must carry forward the single existing shift\'s Id by position');
        sked__Job__c proposedDriverJob = findProposedJobByRole(proposed[0], 'Driver');
        System.assertEquals(systemDriver.Id, proposedDriverJob.Id,
            'The proposed Driver job must match the non-manually-created existing Driver job, not the manually-created duplicate');
    }

    @isTest
    static void testApplyExistingRecordIds_matchesAssetJobsByAssetTypeAndEquipmentSubtype() {
        sked_Drive__c drive = setupSingleShiftDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;

        Id regionId = queryAnyRegionId();
        sked__Job__c existingVehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE, sked__Quantity__c = 2, sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        sked__Job__c existingEquipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT, sked_Equipment_Subtype__c = '2RBC Asset',
            sked__Quantity__c = 4, sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert new List<sked__Job__c>{ existingVehicleJob, existingEquipmentJob };

        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildProposedShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        sked__Job__c proposedVehicleJob, proposedEquipmentJob;
        for (sked__Job__c job : proposed[0].jobs) {
            if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                proposedVehicleJob = job;
            } else if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                proposedEquipmentJob = job;
            }
        }
        System.assertEquals(existingVehicleJob.Id, proposedVehicleJob.Id, 'The proposed Vehicle job must carry forward the existing Vehicle job\'s Id');
        System.assertEquals(existingEquipmentJob.Id, proposedEquipmentJob.Id, 'The proposed Equipment job must carry forward the existing Equipment job\'s Id, matched by equipmentSubtype too');
    }

    @isTest
    static void testApplyExistingRecordIds_shiftsPairByPositionNotByTimeOverlap() {
        sked_Drive__c drive = setupSingleShiftDrive();
        // Existing shift has a wildly different time window from the freshly computed shift -
        // carry-forward must still occur since pairing is purely positional (index 0 <-> index 0).
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start_Time__c = Time.newInstance(1, 0, 0, 0), sked_End_Time__c = Time.newInstance(2, 0, 0, 0)
        );
        insert existingShift;

        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildProposedShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(existingShift.Id, proposed[0].shiftRecord.Id, 'Shift carry-forward must be purely positional, ignoring any mismatch in start/end time');
    }

    @isTest
    static void testApplyExistingRecordIds_noExistingShifts_leavesAllIdsNull() {
        sked_Drive__c drive = setupSingleShiftDrive();

        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildProposedShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);
        System.assertEquals(0, existingShifts.size(), 'Test setup must have no pre-existing Drive Shift records for this drive');

        Test.startTest();
        skedMobileDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(null, proposed[0].shiftRecord.Id, 'With no existing shifts to carry forward from, the proposed shift must remain a fresh insert (null Id)');
        for (sked__Job__c job : proposed[0].jobs) {
            System.assertEquals(null, job.Id, 'With no existing jobs to carry forward from, every proposed job must remain a fresh insert (null Id)');
        }
    }

    @isTest
    static void testPreserveManuallyCreatedJobsForAllShifts_offMenuRole_isAppendedToProposedJobs() {
        sked_Drive__c drive = setupSingleShiftDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = queryAnyRegionId();
        // Not flagged sked_Is_Manually_Created__c - any off-menu role is treated as manually created
        // regardless of the flag, since data migration doesn't track it reliably.
        sked__Job__c offMenuJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Translator', sked__Quantity__c = 1,
            sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert offMenuJob;

        skedMobileDriveJobBuilder.ProposedDriveShift proposedShift = buildProposedShiftWithJobs(new List<sked__Job__c>{
            new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2)
        });
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ proposedShift }, existingShifts);
        Test.stopTest();

        sked__Job__c preserved = findProposedJobByRole(proposedShift, 'Translator');
        System.assertNotEquals(null, preserved, 'A manually-created job with an off-menu role must be preserved into the proposed job list');
        System.assertEquals(offMenuJob.Id, preserved.Id, 'The preserved job must carry the existing record\'s real Id');
    }

    // A manually-created probe only ever matches an equally-manually-created candidate - the fresh
    // proposed job here is never manually created, so this duplicate-role manual job must survive
    // alongside it rather than being dropped in favor of the system-generated job of that same role.
    @isTest
    static void testPreserveManuallyCreatedJobsForAllShifts_duplicateOfSystemRole_isPreservedAlongsideProposedJob() {
        sked_Drive__c drive = setupSingleShiftDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = queryAnyRegionId();
        sked__Job__c manualDriver = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1,
            sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert manualDriver;

        skedMobileDriveJobBuilder.ProposedDriveShift proposedShift = buildProposedShiftWithJobs(new List<sked__Job__c>{
            new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2)
        });
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ proposedShift }, existingShifts);
        Test.stopTest();

        System.assertEquals(2, proposedShift.jobs.size(),
            'The manually-created Driver duplicate must be preserved alongside the proposed system-generated Driver job, not dropped in its favor');
        Boolean manualJobPreserved = false;
        for (sked__Job__c job : proposedShift.jobs) {
            if (job.Id == manualDriver.Id) {
                manualJobPreserved = true;
            }
        }
        System.assert(manualJobPreserved, 'The preserved job must be the manually-created record itself (Id reused), not a second fresh copy');
    }

    @isTest
    static void testPreserveManuallyCreatedJobsForAllShifts_consumedViaDualRole_isNotAppended() {
        sked_Drive__c drive = setupSingleShiftDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = queryAnyRegionId();
        sked__Job__c manual2rbc = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = '2RBC', sked__Quantity__c = 1,
            sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert manual2rbc;

        skedMobileDriveJobBuilder.ProposedDriveShift proposedShift = buildProposedShiftWithJobs(new List<sked__Job__c>{
            new sked__Job__c(sked_Resource_Role__c = 'Driver Support', sked_Dual_Role__c = '2RBC', sked__Quantity__c = 2)
        });
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ proposedShift }, existingShifts);
        Test.stopTest();

        System.assertEquals(1, proposedShift.jobs.size(),
            'A manually-created plain-role job absorbed into a dual-role merge must not be separately preserved');
    }

    @isTest
    static void testPreserveManuallyCreatedJobsForAllShifts_zeroQuantity_isNotAppended() {
        sked_Drive__c drive = setupSingleShiftDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = queryAnyRegionId();
        sked__Job__c zeroQtyJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Translator', sked__Quantity__c = 0,
            sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert zeroQtyJob;

        skedMobileDriveJobBuilder.ProposedDriveShift proposedShift = buildProposedShiftWithJobs(new List<sked__Job__c>());
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ proposedShift }, existingShifts);
        Test.stopTest();

        System.assertEquals(0, proposedShift.jobs.size(), 'A manually-created job with zero (or null) quantity must not be preserved');
    }

    @isTest
    static void testApplyExistingRecordIds_mergesForwardExistingSystemCreatedTagNotAlreadyPresent() {
        sked_Drive__c drive = setupSingleShiftDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = queryAnyRegionId();
        sked__Job__c existingDriverJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2,
            sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingDriverJob;
        sked__Tag__c systemTag = new sked__Tag__c(Name = 'System Merged Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION);
        insert systemTag;
        insert new sked__Job_Tag__c(sked__Job__c = existingDriverJob.Id, sked__Tag__c = systemTag.Id, sked_SystemCreated__c = true);

        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildProposedShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        Integer driverIndex = findProposedJobIndexByRole(proposed[0], 'Driver');
        List<sked__Job_Tag__c> jobTags = proposed[0].jobTagsByJobIndex.get(driverIndex);
        System.assertEquals(true, containsTagId(jobTags, systemTag.Id),
            'A systemCreated tag on the matched existing job must merge forward into the carried-forward job\'s tag set');
    }

    @isTest
    static void testApplyExistingRecordIds_doesNotMergeForwardPhysicalLocationTypeTag() {
        sked_Drive__c drive = setupSingleShiftDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = queryAnyRegionId();
        sked__Job__c existingDriverJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2,
            sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingDriverJob;
        sked__Tag__c physicalLocationTag = new sked__Tag__c(Name = 'Physical Location Tag', sked__Type__c = skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE);
        insert physicalLocationTag;
        insert new sked__Job_Tag__c(sked__Job__c = existingDriverJob.Id, sked__Tag__c = physicalLocationTag.Id, sked_SystemCreated__c = true);

        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildProposedShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        Integer driverIndex = findProposedJobIndexByRole(proposed[0], 'Driver');
        List<sked__Job_Tag__c> jobTags = proposed[0].jobTagsByJobIndex.get(driverIndex);
        System.assertEquals(false, containsTagId(jobTags, physicalLocationTag.Id),
            'A Physical Location Type tag must always be re-derived fresh, never carried forward from the existing job');
    }

    @isTest
    static void testApplyExistingRecordIds_doesNotMergeForwardNonSystemCreatedTag() {
        sked_Drive__c drive = setupSingleShiftDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        Id regionId = queryAnyRegionId();
        sked__Job__c existingDriverJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2,
            sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingDriverJob;
        sked__Tag__c userAddedTag = new sked__Tag__c(Name = 'User Added Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION);
        insert userAddedTag;
        insert new sked__Job_Tag__c(sked__Job__c = existingDriverJob.Id, sked__Tag__c = userAddedTag.Id, sked_SystemCreated__c = false);

        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = buildProposedShifts(drive);
        List<sked_Drive_Shift__c> existingShifts = queryExistingShiftsWithJobs(drive.Id);

        Test.startTest();
        skedMobileDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        Integer driverIndex = findProposedJobIndexByRole(proposed[0], 'Driver');
        List<sked__Job_Tag__c> jobTags = proposed[0].jobTagsByJobIndex.get(driverIndex);
        System.assertEquals(false, containsTagId(jobTags, userAddedTag.Id),
            'A non-systemCreated (user-added) tag must not merge forward - only systemCreated tags do');
    }
}
