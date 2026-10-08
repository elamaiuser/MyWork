@isTest
private class skedMobileJobAllocationCarryForward_Test {

    private static final String TIMEZONE = 'America/New_York';

    private static Id queryAnyRegionId() {
        return [SELECT Id FROM sked__Region__c LIMIT 1].Id;
    }

    private static sked__Job__c insertExistingJob(Id driveShiftId, Id regionId, String resourceRole, String dualRole) {
        sked__Job__c job = new sked__Job__c(
            sked_Drive_Shift__c = driveShiftId, sked_Resource_Role__c = resourceRole, sked_Dual_Role__c = dualRole,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert job;
        return job;
    }

    private static sked__Job_Allocation__c insertAllocation(Id jobId, Id resourceId, Decimal travelTimeTo, Decimal travelTimeBack, Boolean isRelocated) {
        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(
            sked__Job__c = jobId, sked__Resource__c = resourceId, sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED,
            sked_Travel_Time_To__c = travelTimeTo, sked_Travel_Time_Back__c = travelTimeBack, sked_Is_Relocated_Resource__c = isRelocated
        );
        insert allocation;
        return allocation;
    }

    private static skedMobileDriveJobBuilder.ProposedDriveShift buildShift(sked__Job__c proposedJob) {
        skedMobileDriveJobBuilder.ProposedDriveShift shift = new skedMobileDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.add(proposedJob);
        return shift;
    }

    private static sked_Drive__c buildDrive(String travelTimeIncluded) {
        return new sked_Drive__c(sked_Travel_Time_Included__c = travelTimeIncluded);
    }

    private static Biomed_Collection_Op_Center__c buildCollectionOperation(Boolean noTravelTime) {
        return new Biomed_Collection_Op_Center__c(sked_No_Travel_Time__c = noTravelTime);
    }

    @isTest
    static void testCarryForward_noCarriedForwardJobs_leavesAllocationsMapEmpty() {
        skedMobileDriveJobBuilder.ProposedDriveShift shift = buildShift(new sked__Job__c(sked_Resource_Role__c = 'Driver'));

        Test.startTest();
        skedMobileJobAllocationCarryForward.carryForwardJobAllocations(new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ shift },
            buildDrive('Drivers Only'), buildCollectionOperation(false), TIMEZONE);
        Test.stopTest();

        System.assertEquals(0, shift.jobAllocationsByJobId.size(), 'With no proposed job carrying a real Id, no allocation query/result is expected');
    }

    @isTest
    static void testCarryForward_assetJob_keepsJobsOwnStartFinishUnchanged() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked__Resource__c resource = (sked__Resource__c) testData.get('testVehicle1');
        Id regionId = queryAnyRegionId();
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert driveShift;
        sked__Job__c existingJob = insertExistingJob(driveShift.Id, regionId, null, null);
        existingJob.sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE;
        update existingJob;
        insertAllocation(existingJob.Id, resource.Id, null, null, false);

        DateTime jobStart = DateTime.newInstanceGmt(2026, 8, 3, 7, 0, 0);
        DateTime jobFinish = jobStart.addHours(10);
        sked__Job__c proposedJob = new sked__Job__c(Id = existingJob.Id, sked__Start__c = jobStart, sked__Finish__c = jobFinish);
        skedMobileDriveJobBuilder.ProposedDriveShift shift = buildShift(proposedJob);

        Test.startTest();
        skedMobileJobAllocationCarryForward.carryForwardJobAllocations(new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ shift },
            buildDrive('Drivers Only'), buildCollectionOperation(false), TIMEZONE);
        Test.stopTest();

        sked__Job_Allocation__c carried = shift.jobAllocationsByJobId.get(existingJob.Id)[0];
        System.assertEquals(jobStart, carried.sked__Start__c, 'An asset job (no resourceRole) must keep the job\'s own start unchanged');
        System.assertEquals(jobFinish, carried.sked__Set_End__c, 'An asset job (no resourceRole) must keep the job\'s own finish unchanged');
    }

    @isTest
    static void testCarryForward_drivingRoleJob_alwaysRequiresTravelTime_netsZeroWhenAllocationHasNoOwnTravelTime() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked__Resource__c resource = (sked__Resource__c) testData.get('testResource1');
        Id regionId = queryAnyRegionId();
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert driveShift;
        sked__Job__c existingJob = insertExistingJob(driveShift.Id, regionId, 'Driver', null);
        insertAllocation(existingJob.Id, resource.Id, null, null, false);

        DateTime jobStart = DateTime.newInstanceGmt(2026, 8, 3, 7, 0, 0);
        DateTime jobFinish = jobStart.addHours(10);
        sked__Job__c proposedJob = new sked__Job__c(
            Id = existingJob.Id, sked_Resource_Role__c = 'Driver', sked__Start__c = jobStart, sked__Finish__c = jobFinish,
            sked_Travel_Time__c = 15, sked_Travel_Time2__c = 20
        );
        skedMobileDriveJobBuilder.ProposedDriveShift shift = buildShift(proposedJob);

        // CO has travel time on, but drive-level settings must not matter here - Driver is a Driving
        // Roles group member, which unconditionally requires travel time regardless of these flags.
        Test.startTest();
        skedMobileJobAllocationCarryForward.carryForwardJobAllocations(new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ shift },
            buildDrive('Drivers Only'), buildCollectionOperation(false), TIMEZONE);
        Test.stopTest();

        sked__Job_Allocation__c carried = shift.jobAllocationsByJobId.get(existingJob.Id)[0];
        System.assertEquals(jobStart, carried.sked__Start__c,
            'With no allocation-specific travel time, the fallback to job.travelTime nets to a zero adjustment for a driving role');
        System.assertEquals(jobFinish, carried.sked__Set_End__c,
            'With no allocation-specific travel time, the fallback to job.travelTime2 nets to a zero adjustment for a driving role');
    }

    @isTest
    static void testCarryForward_nonDrivingRole_noTravelTimeIncluded_notRelocated_usesRawFallbackAsShift() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked__Resource__c resource = (sked__Resource__c) testData.get('testResource1');
        Id regionId = queryAnyRegionId();
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert driveShift;
        sked__Job__c existingJob = insertExistingJob(driveShift.Id, regionId, '2RBC', null);
        insertAllocation(existingJob.Id, resource.Id, null, null, false);

        DateTime jobStart = DateTime.newInstanceGmt(2026, 8, 3, 7, 0, 0);
        DateTime jobFinish = jobStart.addHours(10);
        sked__Job__c proposedJob = new sked__Job__c(
            Id = existingJob.Id, sked_Resource_Role__c = '2RBC', sked__Start__c = jobStart, sked__Finish__c = jobFinish,
            sked_Travel_Time__c = 15, sked_Travel_Time2__c = 20
        );
        skedMobileDriveJobBuilder.ProposedDriveShift shift = buildShift(proposedJob);

        // 2RBC is not a Driving Roles group member; CO has travel time on, drive is "Drivers Only",
        // and the allocation isn't relocated - requiresTravelTime is false, so the raw fallback
        // (job.travelTime/travelTime2, since the allocation carries none of its own) is used AS the
        // shift itself, not netted against job.travelTime.
        Test.startTest();
        skedMobileJobAllocationCarryForward.carryForwardJobAllocations(new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ shift },
            buildDrive('Drivers Only'), buildCollectionOperation(false), TIMEZONE);
        Test.stopTest();

        sked__Job_Allocation__c carried = shift.jobAllocationsByJobId.get(existingJob.Id)[0];
        System.assertEquals(jobStart.addMinutes(-15), carried.sked__Start__c, 'Without travel time required, the raw travelTime fallback (15) becomes the start shift itself');
        System.assertEquals(jobFinish.addMinutes(20), carried.sked__Set_End__c, 'Without travel time required, the raw travelTime2 fallback (20) becomes the finish shift itself');
    }

    @isTest
    static void testCarryForward_nonDrivingRole_relocatedResource_forcesTravelTimeRequired() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked__Resource__c resource = (sked__Resource__c) testData.get('testResource1');
        Id regionId = queryAnyRegionId();
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert driveShift;
        sked__Job__c existingJob = insertExistingJob(driveShift.Id, regionId, '2RBC', null);
        insertAllocation(existingJob.Id, resource.Id, null, null, true);

        DateTime jobStart = DateTime.newInstanceGmt(2026, 8, 3, 7, 0, 0);
        DateTime jobFinish = jobStart.addHours(10);
        sked__Job__c proposedJob = new sked__Job__c(
            Id = existingJob.Id, sked_Resource_Role__c = '2RBC', sked__Start__c = jobStart, sked__Finish__c = jobFinish,
            sked_Travel_Time__c = 15, sked_Travel_Time2__c = 20
        );
        skedMobileDriveJobBuilder.ProposedDriveShift shift = buildShift(proposedJob);

        Test.startTest();
        skedMobileJobAllocationCarryForward.carryForwardJobAllocations(new List<skedMobileDriveJobBuilder.ProposedDriveShift>{ shift },
            buildDrive('Drivers Only'), buildCollectionOperation(false), TIMEZONE);
        Test.stopTest();

        sked__Job_Allocation__c carried = shift.jobAllocationsByJobId.get(existingJob.Id)[0];
        System.assertEquals(jobStart, carried.sked__Start__c,
            'A relocated resource forces travel time required even for a non-driving role - fallback nets to zero, same as the driving-role case');
    }
}
