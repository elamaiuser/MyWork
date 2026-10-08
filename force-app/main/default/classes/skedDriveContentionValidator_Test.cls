@isTest
private class skedDriveContentionValidator_Test {

    // Must run AFTER skedTestDataFactory.setupCommonTestData() has already created the org-default
    // row (that factory does its own insert, not getOrgDefaults()+upsert) - upserting before it
    // races the factory's own insert and throws DUPLICATE_VALUE on SetupOwnerId.
    private static void setExcessStaffCapacityThreshold(Decimal threshold) {
        sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
        setting.Admin_Excess_Staff_Capacity_Threshold__c = threshold;
        upsert setting;
    }

    private static sked_Drive__c setupDrive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        return queryDrive(testDrive1.Id);
    }

    // setupDriveData() already creates a second drive (testDrive2) in the same call as testDrive1 -
    // both returned from ONE factory setup here, since calling factory.setupCommonTestData() twice
    // in one test method races its own org-default insert and throws DUPLICATE_VALUE on
    // SetupOwnerId (see setExcessStaffCapacityThreshold's comment above for the same pitfall).
    // testDrive2 is Fixed Site by default - callers needing a second Mobile drive must override
    // sked_Type_of_Drive__c in memory afterward.
    private static List<sked_Drive__c> setupTwoDrivesSameCollectionOperation() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c testDrive2 = (sked_Drive__c) testData.get('testDrive2');
        return new List<sked_Drive__c>{ queryDrive(testDrive1.Id), queryDrive(testDrive2.Id) };
    }

    private static sked_Drive__c queryDrive(Id driveId) {
        return [
            SELECT Id, sked_Status__c, sked_Type_of_Drive__c, sked_Operation_Type__c, sked_Drive_Date__c,
                sked_Collection_Operation__c, sked_Linked_Drives__c, sked_Contention_Resolution__c,
                sked_Do_Not_Use_Vehicle__c, sked_Projected_Registered_Donors__c, Excess_Staff_Capacity__c,
                sked_Total_Staff_Requested__c, sked_Total_Vehicle_Requested__c, sked_Total_Equipment_Requested__c,
                sked_Timezone__c, sked_ARC_Region_ID__c, sked_Drive_Site__c, sked_Account__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    // ctx.snapshot must be set BEFORE any test-specific mutation to ctx.drive, matching how
    // skedDriveRegenContextLoader.load() takes the snapshot at load time, before an engine runs.
    private static skedDriveRegenContext buildContext(sked_Drive__c drive) {
        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = drive;
        ctx.snapshot = ctx.deepClone();
        return ctx;
    }

    // validateDrive reads driveShifts/jobs/allocations straight off ctx instead of re-querying by
    // drive Id, so tests build the in-memory shape directly rather than relying on the validator's
    // own query to discover inserted records.
    private static void addJobToContext(skedDriveRegenContext ctx, sked__Job__c job) {
        if (!ctx.jobsByShiftId.containsKey(job.sked_Drive_Shift__c)) {
            ctx.jobsByShiftId.put(job.sked_Drive_Shift__c, new List<sked__Job__c>());
        }
        ctx.jobsByShiftId.get(job.sked_Drive_Shift__c).add(job);
    }

    private static void addAllocationToContext(skedDriveRegenContext ctx, Id jobId, Id resourceId) {
        if (!ctx.allocationsByJobId.containsKey(jobId)) {
            ctx.allocationsByJobId.put(jobId, new List<sked__Job_Allocation__c>());
        }
        ctx.allocationsByJobId.get(jobId).add(new sked__Job_Allocation__c(sked__Job__c = jobId, sked__Resource__c = resourceId));
    }

    // Simulates the pre-regen backup state (ctx.snapshot.jobsByShiftId) for STAFFING_COMPLEMENT_CHANGED
    // tests - buildContext() already took the snapshot before any job exists, so the backup side has
    // to be populated directly rather than through addJobToContext (which only ever targets ctx itself).
    private static void addJobToSnapshot(skedDriveRegenContext ctx, sked__Job__c job) {
        if (!ctx.snapshot.jobsByShiftId.containsKey(job.sked_Drive_Shift__c)) {
            ctx.snapshot.jobsByShiftId.put(job.sked_Drive_Shift__c, new List<sked__Job__c>());
        }
        ctx.snapshot.jobsByShiftId.get(job.sked_Drive_Shift__c).add(job);
    }

    private static Id queryAnyRegionId() {
        return [SELECT Id FROM sked__Region__c LIMIT 1].Id;
    }

    @isTest
    static void testValidateDrive_singleShiftNoIssues_passes() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Drive_Date__c = Date.today().addDays(60); // outside 42 days, avoids that contention
        drive.sked_Do_Not_Use_Vehicle__c = true; // avoids lacking-vehicle contention with no vehicle data
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assertEquals(true, result.passed, 'A single-shift drive with no data issues must have no contention: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_multipleShifts_flagsMultiShiftDrive() {
        sked_Drive__c drive = setupDrive();
        List<sked_Drive_Shift__c> shifts = new List<sked_Drive_Shift__c>{
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id),
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id)
        };
        insert shifts;
        skedDriveRegenContext ctx = buildContext(drive);
        ctx.driveShifts.addAll(shifts);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assertEquals(false, result.passed, 'A 2-shift drive must be flagged as contended');
        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_MULTI_SHIFT_DRIVE),
            'Multi Shift Drive must be one of the reported reason codes: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_equipmentQuantityUnassigned_flagsLackingEquipment() {
        sked_Drive__c drive = setupDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c equipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Quantity__c = 2, sked__Region__c = queryAnyRegionId(), sked__Duration__c = 60
        );
        insert equipmentJob;
        skedDriveRegenContext ctx = buildContext(drive);
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, equipmentJob);
        // No allocation added - zero assigned against a quantity of 2.

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_LACKING_EQUIPMENT),
            'An equipment job with quantity 2 and zero allocations must be flagged as lacking equipment: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_vehicleCapacityBelowDonors_flagsLackingVehicle() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_Do_Not_Use_Vehicle__c = false;
        testDrive1.sked_Projected_Registered_Donors__c = 100;
        update testDrive1;
        sked_Drive__c drive = queryDrive(testDrive1.Id);

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Donors_Scheduled__c = 100);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = queryAnyRegionId(), sked__Duration__c = 60
        );
        insert vehicleJob;
        skedDriveRegenContext ctx = buildContext(drive);
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, vehicleJob);
        // No job allocation added - zero assigned vehicle capacity, well below 100 donors needed.

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_LACKING_VEHICLE),
            'Zero assigned vehicle capacity against 100 scheduled donors must be flagged as lacking vehicles: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_assignedEquipmentBecameUnavailableElsewhere_flagsLackingEquipment() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = queryAnyRegionId();

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = testDrive1.Id, sked_Start__c = windowStart, sked_Finish__c = windowEnd);
        insert shift;
        sked__Job__c equipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert equipmentJob;

        sked__Resource__c equipment = new sked__Resource__c(
            Name = 'Shared Cot', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT, sked__Is_Active__c = true
        );
        insert equipment;

        // Same equipment resource double-booked on an overlapping window, but on a DIFFERENT drive -
        // this one stays a real DB row since skedAssetAvailabilityChecker queries other drives fresh.
        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = otherDrive.Id);
        insert otherShift;
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive_Shift__c = otherShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert otherJob;
        insert new sked__Job_Allocation__c(
            sked__Job__c = otherJob.Id, sked__Resource__c = equipment.Id,
            sked__Start__c = windowStart.addHours(2), sked__Set_End__c = windowStart.addHours(4)
        );

        skedDriveRegenContext ctx = buildContext(queryDrive(testDrive1.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, equipmentJob);
        addAllocationToContext(ctx, equipmentJob.Id, equipment.Id);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_LACKING_EQUIPMENT),
            'An assigned equipment resource double-booked elsewhere during this window must no longer count, flagging Lacking Equipment: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_assignedVehicleBecameUnavailableElsewhere_flagsLackingVehicle() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        testDrive1.sked_Do_Not_Use_Vehicle__c = false;
        testDrive1.sked_Projected_Registered_Donors__c = 20;
        update testDrive1;
        Id regionId = queryAnyRegionId();

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = testDrive1.Id, sked_Start__c = windowStart, sked_Finish__c = windowEnd, sked_Donors_Scheduled__c = 20);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert vehicleJob;

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Shared Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true
        );
        insert vehicle;

        // Same vehicle double-booked on an overlapping window, but on a DIFFERENT drive - stays a
        // real DB row since skedAssetAvailabilityChecker queries other drives fresh.
        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = otherDrive.Id);
        insert otherShift;
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive_Shift__c = otherShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert otherJob;
        insert new sked__Job_Allocation__c(
            sked__Job__c = otherJob.Id, sked__Resource__c = vehicle.Id,
            sked__Start__c = windowStart.addHours(2), sked__Set_End__c = windowStart.addHours(4)
        );

        skedDriveRegenContext ctx = buildContext(queryDrive(testDrive1.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, vehicleJob);
        addAllocationToContext(ctx, vehicleJob.Id, vehicle.Id);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_LACKING_VEHICLE),
            'An assigned vehicle double-booked elsewhere during this window must no longer count toward capacity, flagging Lacking Vehicle: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_assignedVehicleStillAvailable_doesNotFlagLackingVehicle() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_Do_Not_Use_Vehicle__c = false;
        testDrive1.sked_Projected_Registered_Donors__c = 20;
        update testDrive1;
        Id regionId = queryAnyRegionId();

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = testDrive1.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8),
            sked_Donors_Scheduled__c = 20);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert vehicleJob;

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Free Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true
        );
        insert vehicle;
        // No conflicting allocation anywhere else - the assigned vehicle remains available.

        skedDriveRegenContext ctx = buildContext(queryDrive(testDrive1.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, vehicleJob);
        addAllocationToContext(ctx, vehicleJob.Id, vehicle.Id);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_LACKING_VEHICLE),
            'A vehicle with sufficient capacity and no conflict elsewhere must still satisfy Lacking Vehicle: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_within42Days_flagsWithin42DaysWhenNotMovedToConfirmed() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Drive_Date__c = Date.today().addDays(10);
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        // snapshot and current both Tentative - status was never moved to Confirmed this regen.

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_WITHIN_42_DAYS),
            'A drive 10 days out, not just confirmed, must be flagged Within 42 Days: ' + result.pendingActionReasonCodes);
        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_CONFIRM_WITHIN_42_DAYS),
            'Confirmed-within-42-days must NOT fire when the drive was not just moved to Confirmed');
    }

    @isTest
    static void testValidateDrive_movedToConfirmedWithin42Days_flagsConfirmWithin42Days() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Drive_Date__c = Date.today().addDays(10);
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.drive.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED; // simulate this regen confirming the drive

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_CONFIRM_WITHIN_42_DAYS),
            'A drive just moved Tentative -> Confirmed, 10 days out, must be flagged Confirmed within 42 days: ' + result.pendingActionReasonCodes);
        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_WITHIN_42_DAYS),
            'Plain Within 42 Days must NOT also fire once the confirmed-variant already covers this case');
    }

    @isTest
    static void testValidateDrive_linkedDriveWithChangedStaffing_flagsPartOfLinkedDrive() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Drive_Date__c = Date.today().addDays(60); // outside 42 days, isolates this test
        drive.sked_Do_Not_Use_Vehicle__c = true; // avoids lacking-vehicle contention, isolates this test
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;

        // sked_Drive__c.sked_Linked_Drives__c looks up a sked_Linked_Drives__c grouping record, NOT
        // another Drive directly. Some existing Drive trigger clears this field on a plain DML
        // update for a freshly-created test drive - set it directly on the context objects instead,
        // which is all this check actually reads.
        sked_Linked_Drives__c linkedDrivesGroup = new sked_Linked_Drives__c();
        insert linkedDrivesGroup;

        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.snapshot.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        // sked_Drive_Date__c is a plain field (unlike sked_Total_Staff_Requested__c etc., which are
        // rollups this test can't easily drive) - mutating it directly is enough to exercise the
        // "did a tracked field change since the snapshot" half of this check.
        ctx.drive.sked_Drive_Date__c = ctx.drive.sked_Drive_Date__c.addDays(1);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_PART_OF_LINKED_DRIVE),
            'A linked drive whose staffing changed since the snapshot must be flagged Part of Linked Drive: ' + result.pendingActionReasonCodes);
    }

    // sked_Total_Staff_Requested__c is a Roll-Up Summary field - never recalculated in-memory during
    // a regen, so ctx.drive's copy of it is always identical to ctx.snapshot.drive's. This proves the
    // check detects a staffing change via a FRESH total summed from ctx.jobsByShiftId instead, not by
    // (mis)reading ctx.drive's own stale rollup copy - the drive date is deliberately left unchanged
    // to isolate this from the sibling test above.
    @isTest
    static void testValidateDrive_linkedDriveWithStaffSetupIncreasedInMemory_flagsPartOfLinkedDrive() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Drive_Date__c = Date.today().addDays(60); // outside 42 days, isolates this test
        drive.sked_Do_Not_Use_Vehicle__c = true; // avoids lacking-vehicle contention, isolates this test
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Staff_Setup__c = 0);
        insert shift;

        sked_Linked_Drives__c linkedDrivesGroup = new sked_Linked_Drives__c();
        insert linkedDrivesGroup;

        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.snapshot.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.driveShifts.add(shift);
        // Simulates the regen adding a fresh, system-generated role job this pass - the backup
        // (rollup, still 0) never sees it, matching the source's own live-jobs sum.
        addJobToContext(ctx, new sked__Job__c(sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 5));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_PART_OF_LINKED_DRIVE),
            'A linked drive whose in-memory staffing increased since the snapshot must be flagged Part of Linked Drive, ' +
            'even with the drive date unchanged: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_excessStaffCapacityAtThreshold_flagsExcessStaffCapacity() {
        sked_Drive__c drive = setupDrive();
        setExcessStaffCapacityThreshold(1);
        drive.Excess_Staff_Capacity__c = 1.5;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_EXCESS_STAFF_CAPACITY),
            'Excess staff capacity 1.5 >= threshold 1 must be flagged: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_contentionResolutionOverride_suppressesThatContentionOnly() {
        sked_Drive__c drive = setupDrive();
        setExcessStaffCapacityThreshold(1);
        drive.Excess_Staff_Capacity__c = 1.5;
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_EXCESS_STAFF_CAPACITY;
        update drive;
        List<sked_Drive_Shift__c> shifts = new List<sked_Drive_Shift__c>{
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id),
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id)
        };
        insert shifts;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.addAll(shifts);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_EXCESS_STAFF_CAPACITY),
            'Excess Staff Capacity must be suppressed once its own elect-resolution is present: ' + result.pendingActionReasonCodes);
        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_MULTI_SHIFT_DRIVE),
            'Multi Shift Drive has its own elect-resolution, which this scenario never sets, so it must still fire: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_multiShiftDriveOverrideResolutionPresent_suppressesMultiShiftDrive() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_MULTI_SHIFT_DRIVE;
        update drive;
        List<sked_Drive_Shift__c> shifts = new List<sked_Drive_Shift__c>{
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id),
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id)
        };
        insert shifts;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.addAll(shifts);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_MULTI_SHIFT_DRIVE),
            'Multi Shift Drive must be suppressed once its elect-resolution is present: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_nullDriveDate_doesNotFlagWithin42DaysContentions() {
        sked_Drive__c drive = setupDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        // A real DML null-out of sked_Drive_Date__c trips an unrelated Taxonomy validation rule -
        // set it directly on the in-memory ctx, which is all this check actually reads.
        ctx.drive.sked_Drive_Date__c = null;
        // Simulate this regen also moving the drive to Confirmed, so both variants' violation
        // conditions would otherwise be in play - only the null date should suppress them.
        ctx.drive.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED;

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_WITHIN_42_DAYS),
            'A null drive date must never flag Within 42 Days: ' + result.pendingActionReasonCodes);
        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_CONFIRM_WITHIN_42_DAYS),
            'A null drive date must never flag Confirmed Within 42 Days: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_excessStaffCapacityThresholdNotConfigured_doesNotFlagExcessStaffCapacity() {
        sked_Drive__c drive = setupDrive();
        // No setExcessStaffCapacityThreshold() call - threshold stays null (unconfigured).
        drive.Excess_Staff_Capacity__c = 100;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_EXCESS_STAFF_CAPACITY),
            'An unconfigured (null) threshold must never flag Excess Staff Capacity, regardless of the capacity value: '
                + result.pendingActionReasonCodes);
    }

    // Both timezone tests below hold the same fixed absolute shift start/CO minimum-start-time
    // constant and vary ONLY the drive site's sked_Timezone__c - proving checkOutOfOperationalHours
    // resolves timezone from the drive's own site (sked_Drive__c.sked_Timezone__c, a formula
    // mirroring sked_Drive_Site__r.sked_Timezone__c), not UserInfo.getTimeZone(). Midnight local in
    // an eastern (UTC+14) site precedes the fixed shift start; midnight local in a western (UTC-11)
    // site follows it - so the two site timezones must produce opposite violated outcomes.
    private static final Date FIXED_DRIVE_DATE = Date.newInstance(2026, 8, 15);
    private static final DateTime FIXED_SHIFT_START = DateTime.newInstanceGmt(2026, 8, 14, 12, 0, 0);

    private static sked_Drive__c setupDriveForTimezoneTest(String siteTimezoneSidId) {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation1');
        Biomed_Collection_Op_Center__c collectionOperation1 = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');

        site.sked_Timezone__c = siteTimezoneSidId;
        update site;
        collectionOperation1.sked_Minimum_Drive_Start_Time__c = Time.newInstance(0, 0, 0, 0); // midnight, site-local
        collectionOperation1.sked_Maximum_Drive_End_Time__c = null; // isolate the minimum-start branch only
        update collectionOperation1;

        testDrive1.sked_Drive_Date__c = FIXED_DRIVE_DATE;
        update testDrive1;
        return queryDrive(testDrive1.Id);
    }

    @isTest
    static void testValidateDrive_outOfOperationalHours_easternSiteTimezoneNotViolated() {
        sked_Drive__c drive = setupDriveForTimezoneTest('Pacific/Kiritimati'); // UTC+14
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = FIXED_SHIFT_START, sked_Finish__c = FIXED_SHIFT_START.addHours(1));
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_OUT_OF_OPERATIONAL_HOURS),
            'Midnight in the site\'s UTC+14 timezone precedes the fixed shift start, so this must NOT be flagged: '
                + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_outOfOperationalHours_westernSiteTimezoneViolated() {
        sked_Drive__c drive = setupDriveForTimezoneTest('Pacific/Pago_Pago'); // UTC-11
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = FIXED_SHIFT_START, sked_Finish__c = FIXED_SHIFT_START.addHours(1));
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_OUT_OF_OPERATIONAL_HOURS),
            'Midnight in the site\'s UTC-11 timezone follows the fixed shift start, so this must be flagged: '
                + result.pendingActionReasonCodes);
    }

    // testDrive2/testLocation2 default to WB (see reference_fixed_site_test_fixture_gotchas.md) -
    // SiteService blocks an Operation Type change on a Site referenced by a live, non-cancelled
    // Drive, so this flips it via the required cancel -> flip -> restore dance, then re-queries the
    // drive since sked_Operation_Type__c is a formula field.
    private static sked_Drive__c setupFixedSiteNonWbDrive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
        update drive;
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        site.Operation_Type__c = skedConstants.OPERATION_TYPE_INTEGRATED;
        update site;
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        update drive;
        return queryDrive(drive.Id);
    }

    // testDrive2/testLocation2 already default to WB, so unlike setupFixedSiteNonWbDrive this needs no
    // Operation Type flip - just the re-query, since sked_Operation_Type__c is a formula field.
    private static sked_Drive__c setupFixedSiteWbDrive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        return queryDrive(((sked_Drive__c) testData.get('testDrive2')).Id);
    }

    private static sked__Job__c newSystemRoleJob(Id shiftId, String resourceRole, Decimal systemQuantity) {
        return new sked__Job__c(
            sked_Drive_Shift__c = shiftId, sked_Resource_Role__c = resourceRole, sked_System_Quantity__c = systemQuantity,
            sked__Region__c = queryAnyRegionId(), sked__Duration__c = 60
        );
    }

    @isTest
    static void testValidateDrive_newSystemGeneratedRoleJobWithQuantity_flagsStaffingComplementChanged() {
        sked_Drive__c drive = setupDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c driverJob = newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_DRIVER, 2);
        driverJob.sked__Quantity__c = 2;
        insert driverJob;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, driverJob);
        // No matching job added to ctx.snapshot - this Driver job is new since the pre-regen backup.

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'A new system-generated Driver job with quantity 2, absent from the backup, must be flagged: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_deletedSystemGeneratedRoleJob_flagsStaffingComplementChanged() {
        sked_Drive__c drive = setupDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToSnapshot(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_DRIVE_LEAD, 1));
        // No corresponding job added to ctx itself - the Drive Lead job present at load time is gone now.

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'A Drive Lead job present in the backup but missing from the current drive must be flagged: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_systemQuantityUnchanged_doesNotFlagStaffingComplementChanged() {
        sked_Drive__c drive = setupDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToSnapshot(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 2));
        addJobToContext(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 2));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'A Team Supervisor job with the same systemQuantity as its backup counterpart must not be flagged: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_systemQuantityChanged_flagsStaffingComplementChanged() {
        sked_Drive__c drive = setupDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToSnapshot(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 2));
        addJobToContext(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 3));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'A Team Supervisor job whose systemQuantity changed from 2 to 3 since the backup must be flagged: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_manuallyCreatedFromStaffingModal_excludedFromStaffingComplementDiff() {
        sked_Drive__c drive = setupDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c manualJob = newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_DRIVER, 5);
        manualJob.sked__Quantity__c = 5;
        manualJob.sked_Is_Manually_Created__c = true;
        manualJob.sked_Manually_Created_From__c = 'Staffing Modal';
        insert manualJob;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, manualJob);
        // No backup counterpart - would otherwise look like a brand-new job, but Staffing-Modal-manual
        // jobs are excluded from this diff entirely.

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'A Staffing-Modal-manual Driver job must be excluded from the staffing complement diff: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_vphhAptQuantityChanged_flagsStaffingComplementChanged() {
        sked_Drive__c drive = setupDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);

        sked__Job__c backupVphhJob = newSystemRoleJob(shift.Id, 'VP/HH', 4);
        backupVphhJob.sked_APT_Quantity__c = 0;
        addJobToSnapshot(ctx, backupVphhJob);

        sked__Job__c currentVphhJob = newSystemRoleJob(shift.Id, 'VP/HH', 4);
        currentVphhJob.sked_APT_Quantity__c = 3;
        addJobToContext(ctx, currentVphhJob);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'A VP/HH job whose aptQuantity changed from 0 to 3 since the backup must be flagged, even with systemQuantity unchanged: '
                + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_fixedSiteNonWbApheresisQuantityChanged_flagsStaffingComplementChanged() {
        sked_Drive__c drive = setupFixedSiteNonWbDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(drive);
        ctx.driveShifts.add(shift);
        addJobToSnapshot(ctx, newSystemRoleJob(shift.Id, 'Apheresis', 2));
        addJobToContext(ctx, newSystemRoleJob(shift.Id, 'Apheresis', 3));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'An Apheresis job whose systemQuantity changed from 2 to 3 since the backup must be flagged on a Fixed Site (non-WB) drive: '
                + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_fixedSiteNonWbDriverRoleQuantityChanged_doesNotFlagStaffingComplementChanged() {
        sked_Drive__c drive = setupFixedSiteNonWbDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(drive);
        ctx.driveShifts.add(shift);
        addJobToSnapshot(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_DRIVER, 2));
        addJobToContext(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_DRIVER, 3));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'Driver is a Mobile-only system-generated role - on a Fixed Site (non-WB) drive it must not be treated as '
                + 'system-generated at all, so its quantity change must not leak into this contention: ' + result.pendingActionReasonCodes);
    }

    // WB's role set is a strict subset of Mobile's, so this positive case passes under either role set -
    // it exists as a vacuity canary for the negative Driver test below (if the WB fixture ever
    // short-circuits validateDrive before checkStaffingComplementChanged runs, this one fails first).
    @isTest
    static void testValidateDrive_fixedSiteWbTeamSupervisorQuantityChanged_flagsStaffingComplementChanged() {
        sked_Drive__c drive = setupFixedSiteWbDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(drive);
        ctx.driveShifts.add(shift);
        addJobToSnapshot(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 2));
        addJobToContext(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 3));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'Team Supervisor is system-generated on a WB Fixed Site drive, so its systemQuantity change from 2 to 3 must be flagged: '
                + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_fixedSiteWbDriverRoleQuantityChanged_doesNotFlagStaffingComplementChanged() {
        sked_Drive__c drive = setupFixedSiteWbDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(drive);
        ctx.driveShifts.add(shift);
        addJobToSnapshot(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_DRIVER, 2));
        addJobToContext(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_DRIVER, 3));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'helper.js:3553-3554 omits Driver from the WB Fixed Site system-generated role list, so a Driver job\'s quantity change '
                + 'must not leak into this contention on a WB drive either: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_staffingComplementChangedNoContentionResolutionSuppressesIt_stillFlagsWhenChanged() {
        sked_Drive__c drive = setupDrive();
        // No override resolution exists for this contention in the source - setting an arbitrary
        // (even plausible-sounding) resolution string must never suppress it.
        drive.sked_Contention_Resolution__c = 'Accept New Staffing Complement';
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToSnapshot(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 2));
        addJobToContext(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 3));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'Staffing Complement Changed has no override resolution in the source and must never be suppressed: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_staffingComplementChangedRegenerateDriveTokenApplied_doesNotFlagUnchangedQuantities() {
        sked_Drive__c drive = setupDrive();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.appliedTokens.add('regenerateDrive');
        addJobToSnapshot(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 2));
        addJobToContext(ctx, newSystemRoleJob(shift.Id, skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR, 2));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_STAFFING_COMPLEMENT_CHANGED),
            'A regenerateDrive DCR token must not force this contention to fire when no quantity actually changed - the source never conditions this check on that token: '
                + result.pendingActionReasonCodes);
    }

    // Covers every day of week and a wide effective-date range so any test drive date matches,
    // matching the same simplification used by GenerateMobileDriveTest's own time-block fixtures.
    private static Collection_Operation_Time_Block__c insertCollectionOperationTimeBlock(Id collectionOperationId, Time startTime, Time endTime) {
        Time_Block__c timeBlock = new Time_Block__c(
            Name = 'TB ' + startTime + '-' + endTime,
            Start_Time__c = startTime,
            End_Time__c = endTime,
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert timeBlock;
        Collection_Operation_Time_Block__c coTimeBlock = new Collection_Operation_Time_Block__c(
            Collection_Operation__c = collectionOperationId, Time_Block__c = timeBlock.Id,
            Effective_Start_Date__c = Date.today().addDays(-1000), Effective_End_Date__c = Date.today().addDays(1000)
        );
        insert coTimeBlock;
        return [
            SELECT Id, Collection_Operation__c, Time_Block__c, Effective_Start_Date__c, Effective_End_Date__c,
                Time_Block__r.Days_of_Week__c, Time_Block__r.Start_Time__c, Time_Block__r.End_Time__c
            FROM Collection_Operation_Time_Block__c WHERE Id = :coTimeBlock.Id
        ];
    }

    @isTest
    static void testValidateDrive_shiftHasNoTimeBlockAndNoneFitsItsHours_flagsMissingTimeBlockAndShortCircuits() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Drive_Date__c = Date.today().addDays(60); // outside 42 days, would otherwise also fire
        update drive;
        Collection_Operation_Time_Block__c coTimeBlock = insertCollectionOperationTimeBlock(
            drive.sked_Collection_Operation__c, Time.newInstance(8, 0, 0, 0), Time.newInstance(12, 0, 0, 0));
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(13, 0, 0, 0), sked_End_Time__c = Time.newInstance(15, 0, 0, 0));
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.collectionOperationTimeBlocks.add(coTimeBlock);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assertEquals(false, result.passed, 'A shift with no time block whose hours fit none of the CO\'s time blocks must fail');
        System.assertEquals(1, result.pendingActionReasonCodes.size(),
            'Time-block validation must short-circuit before any other check runs: ' + result.pendingActionReasonCodes);
        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_MISSING_TIME_BLOCK),
            'Must flag Missing Time Block: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_missingTimeBlockOverridden_passesDespiteNoFittingTimeBlock() {
        sked_Drive__c drive = setupDrive();
        Collection_Operation_Time_Block__c coTimeBlock = insertCollectionOperationTimeBlock(
            drive.sked_Collection_Operation__c, Time.newInstance(8, 0, 0, 0), Time.newInstance(12, 0, 0, 0));
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(13, 0, 0, 0), sked_End_Time__c = Time.newInstance(15, 0, 0, 0),
            sked_Contention_Resolution__c = skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_RESOLUTION_ELECT_NOT_USE_DRIVE_SHIFT_TIME_BLOCK);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.collectionOperationTimeBlocks.add(coTimeBlock);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_MISSING_TIME_BLOCK),
            'The shift\'s own contentionResolution must override Missing Time Block, independent of the drive-level resolution field: '
                + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_shiftHoursFitTwoTimeBlocks_flagsFitMultipleTimeBlocks() {
        sked_Drive__c drive = setupDrive();
        Collection_Operation_Time_Block__c wideBlock = insertCollectionOperationTimeBlock(
            drive.sked_Collection_Operation__c, Time.newInstance(6, 0, 0, 0), Time.newInstance(20, 0, 0, 0));
        Collection_Operation_Time_Block__c widerBlock = insertCollectionOperationTimeBlock(
            drive.sked_Collection_Operation__c, Time.newInstance(0, 0, 0, 0), Time.newInstance(23, 59, 59, 0));
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0), sked_End_Time__c = Time.newInstance(10, 0, 0, 0));
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.collectionOperationTimeBlocks.add(wideBlock);
        ctx.collectionOperationTimeBlocks.add(widerBlock);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_FIT_MULTIPLE_TIME_BLOCKS),
            'A shift whose hours fit 2+ available time blocks with none assigned must flag Fits Multiple Time Block: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_assignedTimeBlockNoLongerFitsShiftHours_flagsOutOfTimeBlock() {
        sked_Drive__c drive = setupDrive();
        Collection_Operation_Time_Block__c coTimeBlock = insertCollectionOperationTimeBlock(
            drive.sked_Collection_Operation__c, Time.newInstance(8, 0, 0, 0), Time.newInstance(12, 0, 0, 0));
        // Shift's hours no longer fit its own assigned time block (e.g. the shift's time moved since assignment).
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(13, 0, 0, 0), sked_End_Time__c = Time.newInstance(15, 0, 0, 0),
            sked_Time_Block__c = coTimeBlock.Time_Block__c);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.collectionOperationTimeBlocks.add(coTimeBlock);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_OUT_OF_TIME_BLOCK),
            'A shift whose assigned time block no longer covers its own hours must flag Out Of Time Block: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_outOfTimeBlockOverridden_passesDespiteMismatch() {
        sked_Drive__c drive = setupDrive();
        Collection_Operation_Time_Block__c coTimeBlock = insertCollectionOperationTimeBlock(
            drive.sked_Collection_Operation__c, Time.newInstance(8, 0, 0, 0), Time.newInstance(12, 0, 0, 0));
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(13, 0, 0, 0), sked_End_Time__c = Time.newInstance(15, 0, 0, 0),
            sked_Time_Block__c = coTimeBlock.Time_Block__c,
            sked_Contention_Resolution__c = skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_RESOLUTION_ELECT_DRIVE_SHIFT_OUT_OF_TIME_BLOCK);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.collectionOperationTimeBlocks.add(coTimeBlock);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_SHIFT_TIME_BLOCK_CONTENTION_OUT_OF_TIME_BLOCK),
            'The shift\'s own ELECT_DRIVE_SHIFT_OUT_OF_TIME_BLOCK resolution must override Out Of Time Block: ' + result.pendingActionReasonCodes);
    }

    // Matches skedDriveRegenContextLoader's own ctx.sameDateDrives subquery shape.
    private static sked_Drive__c querySameDateDriveShape(Id driveId) {
        return [
            SELECT Id, sked_Status__c, sked_Type_of_Drive__c, sked_Operation_Type__c,
                sked_Linked_Drives__c, sked_Linked_Drives__r.sked_Linked_Drive_Type__c,
                sked_Total_Staff_Requested__c, sked_Total_Equipment_Requested__c,
                sked_No_of_Allocated_DOT__c, sked_No_of_Allocated_CDL__c,
                (SELECT Id, sked_Time_Block__c, sked_Staff_Setup__c, sked_Time_Block__r.Start_Time__c FROM sked_Drive_Shifts__r)
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    // testDrive2 (from setupTwoDrivesSameCollectionOperation) is Fixed Site by default - flipped to
    // Mobile in memory here so it counts toward DRIVE_LIMIT, matching this file's established
    // in-memory-mutation precedent rather than risking a real DML status/type change.
    private static sked_Drive__c queryAsCountableSameDateDrive(Id driveId) {
        sked_Drive__c sameDateDrive = querySameDateDriveShape(driveId);
        sameDateDrive.sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_MOBILE;
        sameDateDrive.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED;
        return sameDateDrive;
    }

    // ===== computeMaxDotCdlForDrive (ghost-vehicle/asset-reassignment ranking tiers) =====

    @isTest
    static void testComputeMaxDotCdlForDrive_noOperationDriveLimitsConfigured_returnsUnbounded() {
        List<sked_Drive__c> drives = setupTwoDrivesSameCollectionOperation();
        sked_Drive__c drive = drives[0];

        Test.startTest();
        skedDriveContentionValidator.MaxDotCdl result = skedDriveContentionValidator.computeMaxDotCdlForDrive(
            drive, new List<sked_Operation_Drive_Limit__c>(), new List<sked_Drive__c>{ queryAsCountableSameDateDrive(drives[1].Id) });
        Test.stopTest();

        System.assertEquals(999999999, result.maxDOT, 'With no operational limit configured, maxDOT must be unbounded');
        System.assertEquals(999999999, result.maxCDL, 'With no operational limit configured, maxCDL must be unbounded');
    }

    @isTest
    static void testComputeMaxDotCdlForDrive_sameDateAllocationSubtractedFromOperationalLimit() {
        List<sked_Drive__c> drives = setupTwoDrivesSameCollectionOperation();
        sked_Drive__c drive = drives[0];
        sked_Drive__c sameDateDrive = queryAsCountableSameDateDrive(drives[1].Id);
        sameDateDrive.sked_No_of_Allocated_DOT__c = 3;
        sked_Operation_Drive_Limit__c odl = new sked_Operation_Drive_Limit__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c, sked_Quantity__c = 5,
            sked_Type__c = skedConstants.OPERATION_DRIVE_LIMIT_TYPE_DOT_LIMIT,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert odl;

        Test.startTest();
        skedDriveContentionValidator.MaxDotCdl result = skedDriveContentionValidator.computeMaxDotCdlForDrive(
            drive, new List<sked_Operation_Drive_Limit__c>{ odl }, new List<sked_Drive__c>{ sameDateDrive });
        Test.stopTest();

        System.assertEquals(2, result.maxDOT, 'maxDOT must be the operational limit (5) minus the same-date allocated DOT total (3)');
        System.assertEquals(999999999, result.maxCDL, 'With no CDL_LIMIT type configured, maxCDL must remain unbounded');
    }

    // Fixed Site exclusion itself is not re-tested here - it's the same shared
    // skedCollectionOperationTimeBlockMatcher.isFixedSiteDrive this file's own DRIVE_LIMIT/x2RBC/
    // DOT/CDL_LIMIT tests already exercise (every one of them flips a same-date drive to Mobile via
    // queryAsCountableSameDateDrive specifically because Fixed Site would otherwise be excluded).

@isTest
    static void testValidateDrive_driveLimitExceededBySameDateConfirmedDrive_flagsDriveLimit() {
        List<sked_Drive__c> drives = setupTwoDrivesSameCollectionOperation();
        sked_Drive__c drive = drives[0];
        drive.sked_Do_Not_Use_Vehicle__c = true;
        update drive;
        sked_Operation_Drive_Limit__c odl = new sked_Operation_Drive_Limit__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c, sked_Quantity__c = 1,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert odl;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.operationDriveLimits.add(odl);
        ctx.sameDateDrives.add(queryAsCountableSameDateDrive(drives[1].Id));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_DRIVE_LIMIT),
            'One confirmed same-date drive against a limit of 1 must flag DRIVE_LIMIT: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_driveLimitOverridden_passesDespiteExceedingLimit() {
        List<sked_Drive__c> drives = setupTwoDrivesSameCollectionOperation();
        sked_Drive__c drive = drives[0];
        drive.sked_Do_Not_Use_Vehicle__c = true;
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_DRIVE_LIMIT;
        update drive;
        sked_Operation_Drive_Limit__c odl = new sked_Operation_Drive_Limit__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c, sked_Quantity__c = 1,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert odl;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.operationDriveLimits.add(odl);
        ctx.sameDateDrives.add(queryAsCountableSameDateDrive(drives[1].Id));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_DRIVE_LIMIT),
            'ELECT_DRIVE_LIMIT must override DRIVE_LIMIT: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_noOperationDriveLimitConfigured_neverFlagsDriveLimit() {
        List<sked_Drive__c> drives = setupTwoDrivesSameCollectionOperation();
        sked_Drive__c drive = drives[0];
        drive.sked_Do_Not_Use_Vehicle__c = true;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        // No operationDriveLimits at all - an unconfigured (infinite) limit must never violate,
        // regardless of how many same-date drives exist.
        ctx.sameDateDrives.add(queryAsCountableSameDateDrive(drives[1].Id));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_DRIVE_LIMIT),
            'With no Operation Drive Limit configured, DRIVE_LIMIT must never fire: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_x2RBCLimitExceededBySameDateConfirmedDrive_flagsX2RBCLimit() {
        List<sked_Drive__c> drives = setupTwoDrivesSameCollectionOperation();
        sked_Drive__c drive = drives[0];
        drive.sked_Do_Not_Use_Vehicle__c = true;
        update drive;
        sked_Operation_Drive_Limit__c odl = new sked_Operation_Drive_Limit__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c, sked_Quantity__c = 5,
            sked_Type__c = skedConstants.OPERATION_DRIVE_LIMIT_TYPE_x2RBC_LIMIT,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert odl;
        // sked_Total_Equipment_Requested__c is a MAX rollup off the shift's own sked_Equipment__c -
        // set via the shift, then requery the drive to read the rolled-up total.
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Equipment__c = 2);
        insert shift;
        sked_Drive_Shift__c sameDateShift = new sked_Drive_Shift__c(sked_Drive__c = drives[1].Id, sked_Equipment__c = 5);
        insert sameDateShift;

        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.operationDriveLimits.add(odl);
        ctx.sameDateDrives.add(queryAsCountableSameDateDrive(drives[1].Id));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_x2RBC_LIMIT),
            'Same-date 2RBC total (5) plus this drive\'s own request (2) exceeding a limit of 5 must flag x2RBC_LIMIT: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_x2RBCLimitOverridden_passesDespiteExceedingLimit() {
        List<sked_Drive__c> drives = setupTwoDrivesSameCollectionOperation();
        sked_Drive__c drive = drives[0];
        drive.sked_Do_Not_Use_Vehicle__c = true;
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_2RBC_LIMIT;
        update drive;
        sked_Operation_Drive_Limit__c odl = new sked_Operation_Drive_Limit__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c, sked_Quantity__c = 5,
            sked_Type__c = skedConstants.OPERATION_DRIVE_LIMIT_TYPE_x2RBC_LIMIT,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert odl;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Equipment__c = 2);
        insert shift;
        sked_Drive_Shift__c sameDateShift = new sked_Drive_Shift__c(sked_Drive__c = drives[1].Id, sked_Equipment__c = 5);
        insert sameDateShift;

        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.operationDriveLimits.add(odl);
        ctx.sameDateDrives.add(queryAsCountableSameDateDrive(drives[1].Id));

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_x2RBC_LIMIT),
            'ELECT_2RBC_LIMIT must override x2RBC_LIMIT: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_dotLimitExceededByAssignedDOTVehicle_flagsDOTLimit() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> commonData = factory.setupCommonTestData();
        Map<String, sObject> driveData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) driveData.get('testDrive1');
        sked_Drive__c sameDateDrive = (sked_Drive__c) driveData.get('testDrive2');
        drive.sked_Do_Not_Use_Vehicle__c = true;
        update drive;

        sked__Resource__c dotResource = (sked__Resource__c) commonData.get('testResource1');
        dotResource.sked_DOT__c = true;
        update dotResource;

        sked_Operation_Drive_Limit__c odl = new sked_Operation_Drive_Limit__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c, sked_Quantity__c = 5,
            sked_Type__c = skedConstants.OPERATION_DRIVE_LIMIT_TYPE_DOT_LIMIT,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert odl;

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Region__c = queryAnyRegionId(), sked__Duration__c = 60
        );
        insert vehicleJob;

        // sked_No_of_Allocated_DOT__c is a plain Number field on the same-date drive, not a rollup.
        sameDateDrive.sked_No_of_Allocated_DOT__c = 5;
        update sameDateDrive;

        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.operationDriveLimits.add(odl);
        ctx.sameDateDrives.add(queryAsCountableSameDateDrive(sameDateDrive.Id));
        addJobToContext(ctx, vehicleJob);
        addAllocationToContext(ctx, vehicleJob.Id, dotResource.Id);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_DOT_LIMIT),
            'Same-date DOT total (5) plus this drive\'s own assigned DOT vehicle (1) exceeding a limit of 5 must flag DOT_LIMIT: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_cdlLimitExceededByAssignedCDLVehicle_flagsCDLLimit() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> commonData = factory.setupCommonTestData();
        Map<String, sObject> driveData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) driveData.get('testDrive1');
        sked_Drive__c sameDateDrive = (sked_Drive__c) driveData.get('testDrive2');
        drive.sked_Do_Not_Use_Vehicle__c = true;
        update drive;

        sked__Resource__c cdlResource = (sked__Resource__c) commonData.get('testResource1');
        cdlResource.sked_CDL__c = true;
        update cdlResource;

        sked_Operation_Drive_Limit__c odl = new sked_Operation_Drive_Limit__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c, sked_Quantity__c = 5,
            sked_Type__c = skedConstants.OPERATION_DRIVE_LIMIT_TYPE_CDL_LIMIT,
            sked_Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert odl;

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Region__c = queryAnyRegionId(), sked__Duration__c = 60
        );
        insert vehicleJob;

        sameDateDrive.sked_No_of_Allocated_CDL__c = 5;
        update sameDateDrive;

        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.operationDriveLimits.add(odl);
        ctx.sameDateDrives.add(queryAsCountableSameDateDrive(sameDateDrive.Id));
        addJobToContext(ctx, vehicleJob);
        addAllocationToContext(ctx, vehicleJob.Id, cdlResource.Id);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_CDL_LIMIT),
            'Same-date CDL total (5) plus this drive\'s own assigned CDL vehicle (1) exceeding a limit of 5 must flag CDL_LIMIT: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_insufficientResourcesNoStaffingConstraintConfigured_flagsInsufficientResources() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Do_Not_Use_Vehicle__c = true;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c driverJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2,
            sked__Region__c = queryAnyRegionId(), sked__Duration__c = 60
        );
        insert driverJob;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, driverJob);
        // No sked_Staffing_Constraint__c at all - an unconfigured constraint defaults to 0 (zero
        // staff allowed), matching helper.js's own validateInsufficientResources exactly.

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_INSUFFICIENT_RESOURCES),
            'A Driver job requesting 2 staff with no staffing constraint configured at all must flag INSUFFICIENT_RESOURCES: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_insufficientResourcesOverridden_passesDespiteNoStaffingConstraint() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Do_Not_Use_Vehicle__c = true;
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_INSUFFICIENT_RESOURCES;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c driverJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2,
            sked__Region__c = queryAnyRegionId(), sked__Duration__c = 60
        );
        insert driverJob;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, driverJob);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_INSUFFICIENT_RESOURCES),
            'ELECT_INSUFFICIENT_RESOURCES must override INSUFFICIENT_RESOURCES: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_insufficientResourcesWithSufficientStaffingConstraint_passes() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Do_Not_Use_Vehicle__c = true;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c driverJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2,
            sked__Region__c = queryAnyRegionId(), sked__Duration__c = 60
        );
        insert driverJob;
        sked_Staffing_Constraint__c constraint = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c,
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_MOBILE,
            sked_Date_of_Constraint__c = drive.sked_Drive_Date__c,
            sked_Total_Staff_Constraints__c = 10
        );
        insert constraint;
        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        ctx.staffingConstraints.add(constraint);
        addJobToContext(ctx, driverJob);

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_INSUFFICIENT_RESOURCES),
            'A staffing constraint of 10 comfortably covering a request of 2 must not flag INSUFFICIENT_RESOURCES: ' + result.pendingActionReasonCodes);
    }

    // Deliberately calls skedDriveRegenContextLoader.load() instead of buildContext() - that's the
    // only way to exercise the loader's own staffingConstraints query, which is what HRP-10153's
    // drive-type fix touches. A hand-built ctx.staffingConstraints (as the sibling Mobile test above
    // does) would pass identically whether the query filtered on this drive's own type or was still
    // hardcoded to Mobile, so it can't prove the fix.
    @isTest
    static void testValidateDrive_fixedSiteStaffingConstraintQueriedByLoader_passesInsufficientResources() {
        sked_Drive__c drive = setupFixedSiteNonWbDrive();
        System.assertEquals(skedConstants.DRIVE_TYPE_FIXED_SITE, drive.sked_Type_of_Drive__c,
            'Fixture must actually be a Fixed Site drive for this regression test to mean anything');
        drive.sked_Do_Not_Use_Vehicle__c = true; // isolates this test from the unrelated lacking-vehicle contention
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c driverJob = new sked__Job__c(
            sked_Drive__c = drive.Id, sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'Driver',
            sked__Quantity__c = 2, sked__Region__c = queryAnyRegionId(), sked__Duration__c = 60
        );
        insert driverJob;
        sked_Staffing_Constraint__c constraint = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c,
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_FIXED_SITE,
            sked_Date_of_Constraint__c = drive.sked_Drive_Date__c,
            sked_Total_Staff_Constraints__c = 10
        );
        insert constraint;

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assertEquals(1, ctx.staffingConstraints.size(),
            'The Fixed Site staffing constraint must be picked up by the loader\'s own query for this drive\'s type');
        System.assertEquals(constraint.Id, ctx.staffingConstraints[0].Id,
            'The queried constraint must be the one just inserted for this Fixed Site drive');
        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_INSUFFICIENT_RESOURCES),
            'A Fixed Site staffing constraint of 10, queried live for this drive\'s own type, must cover a request of 2 staff '
                + 'and not flag INSUFFICIENT_RESOURCES: ' + result.pendingActionReasonCodes);
    }

    // Builds a Region Territory <- District Territory <- TCO chain for collectionOperationId, so
    // findDriveRegionId can resolve a region for it.
    private static void setupTerritoryCollectionOperation(Id collectionOperationId, String regionName) {
        sked_Territory__c region = new sked_Territory__c(Name = regionName);
        insert region;
        sked_Territory__c district = new sked_Territory__c(Name = regionName + ' District', sked_Parent__c = region.Id);
        insert district;
        insert new sked_Territory_Collection_Operation__c(
            sked_Collection_Operation__c = collectionOperationId, sked_Territory__c = district.Id
        );
    }

    // sked_ARC_Region_ID__c is a formula (CASESAFEID(sked_District__r.sked_Parent__c)) - read-only,
    // can't be assigned directly even in-memory. Point the drive's own District at a fresh
    // Region/District pair instead, so the field reflects a real, distinct region once requeried.
    private static void setupDriveRegion(sked_Drive__c drive, String regionName) {
        sked_Territory__c region = new sked_Territory__c(Name = regionName);
        insert region;
        sked_Territory__c district = new sked_Territory__c(Name = regionName + ' District', sked_Parent__c = region.Id);
        insert district;
        drive.sked_District__c = district.Id;
        update drive;
    }

    // Builds ONE region Territory reused by BOTH the drive's district chain and the new Collection
    // Operation's TCO - unlike setupDriveRegion/setupTerritoryCollectionOperation (always two
    // distinct regions, for CO_CHANGED_CROSS_REGIONS), ASSETS_NOT_SHARED_WITH_NEW_CO's own tests
    // need the region to STAY THE SAME across the CO change.
    private static void setupSameRegionForDriveAndCollectionOperation(sked_Drive__c drive, Id newCollectionOperationId, String regionName) {
        sked_Territory__c region = new sked_Territory__c(Name = regionName);
        insert region;
        sked_Territory__c driveDistrict = new sked_Territory__c(Name = regionName + ' Drive District', sked_Parent__c = region.Id);
        sked_Territory__c coDistrict = new sked_Territory__c(Name = regionName + ' CO District', sked_Parent__c = region.Id);
        insert new List<sked_Territory__c>{ driveDistrict, coDistrict };
        drive.sked_District__c = driveDistrict.Id;
        update drive;
        insert new sked_Territory_Collection_Operation__c(
            sked_Collection_Operation__c = newCollectionOperationId, sked_Territory__c = coDistrict.Id
        );
    }

    @isTest
    static void testValidateDrive_assetNotSharedWithNewCoSameRegion_flagsAssetsNotSharedWithNewCo() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> testData = factory.setupCommonTestData();
        testData.putAll(factory.setupDriveData());
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c newCollectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation2');
        sked__Region__c oldCoRegion = (sked__Region__c) testData.get('testRegion1');
        testDrive1.sked_Do_Not_Use_Vehicle__c = true;
        update testDrive1;
        setupSameRegionForDriveAndCollectionOperation(testDrive1, newCollectionOperation.Id, 'Shared Region');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = testDrive1.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8));
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = oldCoRegion.Id, sked__Duration__c = 60
        );
        insert vehicleJob;
        // Only a member of the OLD Collection Operation's pool (sked__Primary_Region__c ties it to
        // testRegion1, which belongs to testCollectionOperation1, not the new testCollectionOperation2).
        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Old CO Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = oldCoRegion.Id
        );
        insert vehicle;

        sked_Linked_Drives__c linkedDrivesGroup = new sked_Linked_Drives__c();
        insert linkedDrivesGroup;

        skedDriveRegenContext ctx = buildContext(queryDrive(testDrive1.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, vehicleJob);
        addAllocationToContext(ctx, vehicleJob.Id, vehicle.Id);
        ctx.snapshot.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Collection_Operation__c = newCollectionOperation.Id;

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_ASSETS_NOT_SHARED_WITH_NEW_CO),
            'A linked drive whose CO changed within the same region, with an assigned vehicle only shared with the OLD CO, must flag ASSETS_NOT_SHARED_WITH_NEW_CO: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_assetsNotSharedWithNewCoOverridden_passesDespiteMismatch() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> testData = factory.setupCommonTestData();
        testData.putAll(factory.setupDriveData());
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c newCollectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation2');
        sked__Region__c oldCoRegion = (sked__Region__c) testData.get('testRegion1');
        testDrive1.sked_Do_Not_Use_Vehicle__c = true;
        testDrive1.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_ASSETS_NOT_SHARED_WITH_NEW_CO;
        update testDrive1;
        setupSameRegionForDriveAndCollectionOperation(testDrive1, newCollectionOperation.Id, 'Shared Region 2');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = testDrive1.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8));
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = oldCoRegion.Id, sked__Duration__c = 60
        );
        insert vehicleJob;
        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Old CO Van 2', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = oldCoRegion.Id
        );
        insert vehicle;

        sked_Linked_Drives__c linkedDrivesGroup = new sked_Linked_Drives__c();
        insert linkedDrivesGroup;

        skedDriveRegenContext ctx = buildContext(queryDrive(testDrive1.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, vehicleJob);
        addAllocationToContext(ctx, vehicleJob.Id, vehicle.Id);
        ctx.snapshot.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Collection_Operation__c = newCollectionOperation.Id;

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_ASSETS_NOT_SHARED_WITH_NEW_CO),
            'ELECT_ASSETS_NOT_SHARED_WITH_NEW_CO must override ASSETS_NOT_SHARED_WITH_NEW_CO: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_coChangedCrossRegionsToo_neverFlagsAssetsNotSharedWithNewCo() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> testData = factory.setupCommonTestData();
        testData.putAll(factory.setupDriveData());
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c newCollectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation2');
        sked__Region__c oldCoRegion = (sked__Region__c) testData.get('testRegion1');
        testDrive1.sked_Do_Not_Use_Vehicle__c = true;
        update testDrive1;
        // Two DIFFERENT regions this time (mirrors setupDriveRegion/setupTerritoryCollectionOperation) -
        // CO_CHANGED_CROSS_REGIONS is the one that should fire here, not ASSETS_NOT_SHARED_WITH_NEW_CO,
        // even though the same CO-mismatched vehicle is still assigned.
        setupDriveRegion(testDrive1, 'Old Region 4');
        setupTerritoryCollectionOperation(newCollectionOperation.Id, 'New Region 4');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = testDrive1.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8));
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = oldCoRegion.Id, sked__Duration__c = 60
        );
        insert vehicleJob;
        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Old CO Van 3', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = oldCoRegion.Id
        );
        insert vehicle;

        sked_Linked_Drives__c linkedDrivesGroup = new sked_Linked_Drives__c();
        insert linkedDrivesGroup;

        skedDriveRegenContext ctx = buildContext(queryDrive(testDrive1.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, vehicleJob);
        addAllocationToContext(ctx, vehicleJob.Id, vehicle.Id);
        ctx.snapshot.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Collection_Operation__c = newCollectionOperation.Id;

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_CO_CHANGED_CROSS_REGIONS),
            'Sanity check - a cross-region CO change must still flag CO_CHANGED_CROSS_REGIONS: ' + result.pendingActionReasonCodes);
        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_ASSETS_NOT_SHARED_WITH_NEW_CO),
            'A CO change that ALSO crosses regions must be handled by CO_CHANGED_CROSS_REGIONS only, never ASSETS_NOT_SHARED_WITH_NEW_CO: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_coChangedCrossRegions_flagsWhenLinkedDriveCoChangesRegion() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> testData = factory.setupCommonTestData();
        testData.putAll(factory.setupDriveData());
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c newCollectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation2');
        testDrive1.sked_Drive_Date__c = Date.today().addDays(60);
        testDrive1.sked_Do_Not_Use_Vehicle__c = true;
        update testDrive1;
        setupDriveRegion(testDrive1, 'Old Region');
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert shift;

        sked_Linked_Drives__c linkedDrivesGroup = new sked_Linked_Drives__c();
        insert linkedDrivesGroup;
        setupTerritoryCollectionOperation(newCollectionOperation.Id, 'New Region');

        skedDriveRegenContext ctx = buildContext(queryDrive(testDrive1.Id));
        ctx.driveShifts.add(shift);
        ctx.snapshot.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Collection_Operation__c = newCollectionOperation.Id;

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_CO_CHANGED_CROSS_REGIONS),
            'A linked drive whose Collection Operation changed to a different region must flag CO_CHANGED_CROSS_REGIONS: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_coChangedCrossRegionsOverridden_passesDespiteRegionChange() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> testData = factory.setupCommonTestData();
        testData.putAll(factory.setupDriveData());
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c newCollectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation2');
        testDrive1.sked_Drive_Date__c = Date.today().addDays(60);
        testDrive1.sked_Do_Not_Use_Vehicle__c = true;
        testDrive1.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_CO_CHANGED_CROSS_REGIONS_REMOVE_FROM_LINKED_DRIVE;
        update testDrive1;
        setupDriveRegion(testDrive1, 'Old Region 2');
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert shift;

        sked_Linked_Drives__c linkedDrivesGroup = new sked_Linked_Drives__c();
        insert linkedDrivesGroup;
        setupTerritoryCollectionOperation(newCollectionOperation.Id, 'New Region 2');

        skedDriveRegenContext ctx = buildContext(queryDrive(testDrive1.Id));
        ctx.driveShifts.add(shift);
        ctx.snapshot.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Linked_Drives__c = linkedDrivesGroup.Id;
        ctx.drive.sked_Collection_Operation__c = newCollectionOperation.Id;

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_CO_CHANGED_CROSS_REGIONS),
            'ELECT_CO_CHANGED_CROSS_REGIONS_REMOVE_FROM_LINKED_DRIVE must override CO_CHANGED_CROSS_REGIONS: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_notPartOfLinkedDrive_neverFlagsCoChangedCrossRegions() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> testData = factory.setupCommonTestData();
        testData.putAll(factory.setupDriveData());
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c newCollectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation2');
        testDrive1.sked_Drive_Date__c = Date.today().addDays(60);
        testDrive1.sked_Do_Not_Use_Vehicle__c = true;
        update testDrive1;
        setupDriveRegion(testDrive1, 'Old Region 3');
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert shift;
        setupTerritoryCollectionOperation(newCollectionOperation.Id, 'New Region 3');

        skedDriveRegenContext ctx = buildContext(queryDrive(testDrive1.Id));
        ctx.driveShifts.add(shift);
        // No sked_Linked_Drives__c set on either side - the CO change alone must never be enough.
        ctx.drive.sked_Collection_Operation__c = newCollectionOperation.Id;

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_CO_CHANGED_CROSS_REGIONS),
            'A drive that is not part of a linked pair must never flag CO_CHANGED_CROSS_REGIONS regardless of CO change: ' + result.pendingActionReasonCodes);
    }

    // Rule-by-rule coverage (CO membership, tags, decline, travel time, turnaround, CDL/DOT,
    // weekly work days, plain time conflict) lives in skedLockedResourceChecker_Test - these two
    // just confirm checkLockedResourceUnavailable wires into validateDrive correctly.
    private static sked__Job_Allocation__c buildLockedRoleAllocation(sked_Drive_Shift__c shift, sked__Resource__c resource) {
        Id anyRegionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        sked__Job__c roleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'Driver', sked__Region__c = anyRegionId, sked__Duration__c = 60);
        insert roleJob;
        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(
            sked__Job__c = roleJob.Id, sked__Resource__c = resource.Id, sked_Locked__c = true);
        insert allocation;
        return allocation;
    }

    @isTest
    static void testValidateDrive_lockedStaffInactive_flagsLockedResourceUnavailable() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Drive_Date__c = Date.today().addDays(60);
        drive.sked_Do_Not_Use_Vehicle__c = true;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Resource__c resource = new sked__Resource__c(
            Name = 'Locked Inactive Driver', sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE);
        insert resource;
        sked__Job_Allocation__c allocation = buildLockedRoleAllocation(shift, resource);

        sked__Job__c roleJob = [
            SELECT Id, sked_Drive__c, sked_Drive_Shift__c, sked_Asset_Type__c, sked__Quantity__c, sked_Resource_Role__c, sked_Dual_Role__c, sked_System_Quantity__c, sked_VPHH_Quantity__c, sked_APT_Quantity__c, sked_Is_Manually_Created__c, sked_Manually_Created_From__c, sked__Duration__c, sked__Start__c, sked__Finish__c,
                (SELECT Id, sked__Tag__c FROM sked__JobTags__r)
            FROM sked__Job__c WHERE Id = :allocation.sked__Job__c
        ];
        allocation = [
            SELECT Id, sked__Job__c, sked__Resource__c, sked__Status__c, sked_Is_Locked__c,
                sked_Geoservice_Travel_Time_To__c, sked_Geoservice_Travel_Time_Back__c
            FROM sked__Job_Allocation__c WHERE Id = :allocation.Id
        ];

        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, roleJob);
        ctx.allocationsByJobId.put(roleJob.Id, new List<sked__Job_Allocation__c>{ allocation });

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_LOCKED_RESOURCE_UNAVAILABLE),
            'A Locked staff allocation whose resource is Inactive must flag LOCKED_RESOURCE_UNAVAILABLE: ' + result.pendingActionReasonCodes);
    }

    @isTest
    static void testValidateDrive_lockedResourceUnavailableOverridden_passesDespiteInactive() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Drive_Date__c = Date.today().addDays(60);
        drive.sked_Do_Not_Use_Vehicle__c = true;
        drive.sked_Contention_Resolution__c = skedConstants.DRIVE_CONTENTION_RESOLUTION_ELECT_LOCKED_RESOURCE_UNAVAILABLE;
        update drive;
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Resource__c resource = new sked__Resource__c(
            Name = 'Locked Inactive Driver 2', sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE);
        insert resource;
        sked__Job_Allocation__c allocation = buildLockedRoleAllocation(shift, resource);

        sked__Job__c roleJob = [
            SELECT Id, sked_Drive__c, sked_Drive_Shift__c, sked_Asset_Type__c, sked__Quantity__c, sked_Resource_Role__c, sked_Dual_Role__c, sked_System_Quantity__c, sked_VPHH_Quantity__c, sked_APT_Quantity__c, sked_Is_Manually_Created__c, sked_Manually_Created_From__c, sked__Duration__c, sked__Start__c, sked__Finish__c,
                (SELECT Id, sked__Tag__c FROM sked__JobTags__r)
            FROM sked__Job__c WHERE Id = :allocation.sked__Job__c
        ];
        allocation = [
            SELECT Id, sked__Job__c, sked__Resource__c, sked__Status__c, sked_Is_Locked__c,
                sked_Geoservice_Travel_Time_To__c, sked_Geoservice_Travel_Time_Back__c
            FROM sked__Job_Allocation__c WHERE Id = :allocation.Id
        ];

        skedDriveRegenContext ctx = buildContext(queryDrive(drive.Id));
        ctx.driveShifts.add(shift);
        addJobToContext(ctx, roleJob);
        ctx.allocationsByJobId.put(roleJob.Id, new List<sked__Job_Allocation__c>{ allocation });

        Test.startTest();
        skedDriveContentionValidator.ValidationResult result = skedDriveContentionValidator.validateDrive(ctx);
        Test.stopTest();

        System.assert(!result.pendingActionReasonCodes.contains(skedConstants.DRIVE_CONTENTION_LOCKED_RESOURCE_UNAVAILABLE),
            'ELECT_LOCKED_RESOURCE_UNAVAILABLE must override LOCKED_RESOURCE_UNAVAILABLE: ' + result.pendingActionReasonCodes);
    }
}
