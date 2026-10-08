@isTest
private class skedMobileAssetReassigner_Test {

    // Mirrors exactly what skedMobileJobAllocationCarryForward.buildCarriedForwardAllocations puts
    // into ctx.allocationsByJobId pre-save (Id/sked__Job__c/sked__Resource__c only - no status/lock/
    // capacity, see skedMobileAssetReassigner's class header) - tests build ctx the same way
    // production code will have already populated it by the time reassignInvalidAssets runs.
    private static skedDriveRegenContext buildContext(sked_Drive__c drive, sked_Drive_Shift__c shift, sked__Job__c job,
            List<sked__Job_Allocation__c> currentAllocations) {
        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = drive;
        ctx.driveShifts = new List<sked_Drive_Shift__c>{ shift };
        ctx.jobsByShiftId.put(shift.Id, new List<sked__Job__c>{ job });
        if (job.Id != null) {
            ctx.allocationsByJobId.put(job.Id, currentAllocations);
        }
        return ctx;
    }

    private static sked__Job_Allocation__c ctxAllocation(Id allocationId, Id jobId, Id resourceId) {
        return new sked__Job_Allocation__c(Id = allocationId, sked__Job__c = jobId, sked__Resource__c = resourceId);
    }

    @isTest
    static void testReassignInvalidAssets_vehicleStillValidAndSufficient_leavesAllocationUntouched() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        drive.sked_Do_Not_Use_Vehicle__c = false;
        drive.sked_Projected_Registered_Donors__c = 20;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8), sked_Donors_Scheduled__c = 20);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert vehicleJob;

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Valid Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert vehicle;
        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(sked__Job__c = vehicleJob.Id, sked__Resource__c = vehicle.Id);
        insert allocation;

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob,
            new List<sked__Job_Allocation__c>{ ctxAllocation(allocation.Id, vehicleJob.Id, vehicle.Id) });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        System.assertEquals(1, result.size(), 'A still-valid, sufficient-capacity vehicle must not trigger any reassignment: ' + result);
        System.assertEquals(allocation.Id, result[0].Id, 'The existing allocation record must be left exactly as it was');
    }

    @isTest
    static void testReassignInvalidAssets_vehicleConflictedElsewhere_replacesWithAvailableVehicle() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        drive.sked_Do_Not_Use_Vehicle__c = false;
        drive.sked_Projected_Registered_Donors__c = 20;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowEnd, sked_Donors_Scheduled__c = 20);
        // conflictedVehicle is also allocated on a DIFFERENT drive, overlapping this shift's window.
        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = otherDrive.Id);
        insert new List<sked_Drive_Shift__c>{ shift, otherShift };

        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive_Shift__c = otherShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        // Bulk-inserted together (rather than one at a time) so the roll-up-summary-triggered
        // sked__Job__c update cascade (skedJobHandler.onAfterUpdate) runs once, not per record -
        // a per-record insert here was tipping this test over the 100-SOQL test governor limit.
        insert new List<sked__Job__c>{ vehicleJob, otherJob };

        sked__Resource__c conflictedVehicle = new sked__Resource__c(
            Name = 'Double-Booked Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        sked__Resource__c replacementVehicle = new sked__Resource__c(
            Name = 'Free Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert new List<sked__Resource__c>{ conflictedVehicle, replacementVehicle };

        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(sked__Job__c = vehicleJob.Id, sked__Resource__c = conflictedVehicle.Id);
        insert new List<sked__Job_Allocation__c>{
            allocation,
            new sked__Job_Allocation__c(
                sked__Job__c = otherJob.Id, sked__Resource__c = conflictedVehicle.Id,
                sked__Start__c = windowStart.addHours(2), sked__Set_End__c = windowStart.addHours(4))
        };

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob,
            new List<sked__Job_Allocation__c>{ ctxAllocation(allocation.Id, vehicleJob.Id, conflictedVehicle.Id) });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        System.assertEquals(2, result.size(), 'The conflicted allocation must be soft-deleted and a replacement inserted: ' + result);
        Boolean foundDeletedOriginal = false;
        Boolean foundNewReplacement = false;
        for (sked__Job_Allocation__c resultAllocation : result) {
            if (resultAllocation.Id != null && resultAllocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                foundDeletedOriginal = true;
            }
            if (resultAllocation.Id == null && resultAllocation.sked__Resource__c == replacementVehicle.Id) {
                foundNewReplacement = true;
            }
        }
        System.assert(foundDeletedOriginal, 'The conflicted allocation must be marked Deleted, not removed outright: ' + result);
        System.assert(foundNewReplacement, 'The available replacement vehicle must be picked as a new allocation: ' + result);
    }

    @isTest
    static void testReassignInvalidAssets_lockedVehicleInsufficientCapacity_keepsLockedAndAddsReplacement() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        drive.sked_Do_Not_Use_Vehicle__c = false;
        drive.sked_Projected_Registered_Donors__c = 40;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8), sked_Donors_Scheduled__c = 40);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert vehicleJob;

        sked__Resource__c lockedVehicle = new sked__Resource__c(
            Name = 'Locked Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert lockedVehicle;
        sked__Job_Allocation__c lockedAllocation = new sked__Job_Allocation__c(
            sked__Job__c = vehicleJob.Id, sked__Resource__c = lockedVehicle.Id, sked_Locked__c = true);
        insert lockedAllocation;

        sked__Resource__c replacementVehicle = new sked__Resource__c(
            Name = 'Extra Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert replacementVehicle;

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob,
            new List<sked__Job_Allocation__c>{ ctxAllocation(lockedAllocation.Id, vehicleJob.Id, lockedVehicle.Id) });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        Boolean lockedUntouched = false;
        sked__Job_Allocation__c newReplacement;
        for (sked__Job_Allocation__c allocation : result) {
            if (allocation.sked__Resource__c == lockedVehicle.Id) {
                System.assertNotEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, allocation.sked__Status__c,
                    'A locked allocation must never be marked Deleted: ' + result);
                lockedUntouched = true;
            }
            if (allocation.Id == null) {
                newReplacement = allocation;
            }
        }
        System.assert(lockedUntouched, 'The locked allocation must remain present, untouched: ' + result);
        System.assertNotEquals(null, newReplacement, 'A new vehicle must be added to cover the capacity the lock alone cannot satisfy: ' + result);
        System.assertEquals(480, newReplacement.sked__Duration__c,
            'A new replacement allocation must have its Duration computed from the shift window (8 hours = 480 minutes), not left null');
    }

    // Zero Donors Scheduled must fall back to the drive's Projected Registered Donors, exactly like
    // Donors Scheduled being unset - a truthy check, not a null check.
    @isTest
    static void testReassignInvalidAssets_zeroDonorsScheduled_fallsBackToProjectedRegisteredDonors() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        drive.sked_Do_Not_Use_Vehicle__c = false;
        drive.sked_Projected_Registered_Donors__c = 40;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8), sked_Donors_Scheduled__c = 0);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert vehicleJob;

        sked__Resource__c lockedVehicle = new sked__Resource__c(
            Name = 'Locked Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert lockedVehicle;
        sked__Job_Allocation__c lockedAllocation = new sked__Job_Allocation__c(
            sked__Job__c = vehicleJob.Id, sked__Resource__c = lockedVehicle.Id, sked_Locked__c = true);
        insert lockedAllocation;

        sked__Resource__c replacementVehicle = new sked__Resource__c(
            Name = 'Extra Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert replacementVehicle;

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob,
            new List<sked__Job_Allocation__c>{ ctxAllocation(lockedAllocation.Id, vehicleJob.Id, lockedVehicle.Id) });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        Boolean newReplacementAdded = false;
        for (sked__Job_Allocation__c allocation : result) {
            if (allocation.Id == null) {
                newReplacementAdded = true;
            }
        }
        System.assert(newReplacementAdded,
            'A shift with 0 Donors Scheduled must still require capacity for the drive\'s 40 Projected Registered Donors, not treat 0 as already-sufficient: '
                + result);
    }

    // Allocates every available vehicle when no combination covers the required capacity, rather
    // than allocating nothing.
    @isTest
    static void testReassignInvalidAssets_noVehicleCombinationCoversCapacity_allocatesAllAvailableAnyway() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        drive.sked_Do_Not_Use_Vehicle__c = false;
        // The factory registers 2 default vehicles at 50 capacity each (100 combined) for this CO -
        // requiring MORE than that guarantees no subset (not even "all of them") naturally covers
        // it via the normal exhaustive search, so the fallback path is what has to satisfy this.
        drive.sked_Projected_Registered_Donors__c = 150;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8), sked_Donors_Scheduled__c = 150);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert vehicleJob;

        Set<Id> availableVehicleIds = new Map<Id, sked__Resource__c>(skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, shift.sked_Start__c, shift.sked_Finish__c, new Set<Id>())).keySet();
        System.assert(!availableVehicleIds.isEmpty(), 'Setup check: the factory must provide at least one available vehicle for this CO');

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob, new List<sked__Job_Allocation__c>());

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        Set<Id> allocatedResourceIds = new Set<Id>();
        for (sked__Job_Allocation__c allocation : result) {
            allocatedResourceIds.add(allocation.sked__Resource__c);
        }
        System.assertEquals(availableVehicleIds, allocatedResourceIds,
            'When no combination covers the required capacity, EVERY available vehicle must be allocated, not a subset or nothing: ' + result);
    }

    // doNotUseVehicle deallocates EVERY current allocation, including locked ones.
    @isTest
    static void testReassignInvalidAssets_doNotUseVehicle_deallocatesEveryCurrentAllocationIncludingLocked() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        drive.sked_Do_Not_Use_Vehicle__c = true;
        drive.sked_Projected_Registered_Donors__c = 100;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Donors_Scheduled__c = 100);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert vehicleJob;

        sked__Resource__c lockedVehicle = new sked__Resource__c(
            Name = 'Locked Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert lockedVehicle;
        sked__Job_Allocation__c lockedAllocation = new sked__Job_Allocation__c(
            sked__Job__c = vehicleJob.Id, sked__Resource__c = lockedVehicle.Id, sked_Locked__c = true);
        insert lockedAllocation;

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob,
            new List<sked__Job_Allocation__c>{ ctxAllocation(lockedAllocation.Id, vehicleJob.Id, lockedVehicle.Id) });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        System.assertEquals(1, result.size(), 'The locked allocation record must be preserved (soft-deleted, not removed): ' + result);
        System.assertEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, result[0].sked__Status__c,
            'Do Not Use Vehicle must deallocate a vehicle even if it is locked');
    }

    // Locked capacity ALONE already covers the requirement, but the unlocked allocation is
    // conflicted elsewhere (allAssignedValid = false) - trim to just the locked set rather than
    // leaving the invalid/redundant unlocked allocation in place.
    @isTest
    static void testReassignInvalidAssets_lockedCapacitySufficientButUnlockedInvalid_trimsToLockedOnly() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        drive.sked_Do_Not_Use_Vehicle__c = false;
        drive.sked_Projected_Registered_Donors__c = 40;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowEnd, sked_Donors_Scheduled__c = 40);
        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = otherDrive.Id);
        insert new List<sked_Drive_Shift__c>{ shift, otherShift };

        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive__c = drive.Id, sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive__c = otherDrive.Id, sked_Drive_Shift__c = otherShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert new List<sked__Job__c>{ vehicleJob, otherJob };

        sked__Resource__c lockedVehicle = new sked__Resource__c(
            Name = 'Locked Sufficient Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 40, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        sked__Resource__c conflictedUnlockedVehicle = new sked__Resource__c(
            Name = 'Conflicted Unlocked Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert new List<sked__Resource__c>{ lockedVehicle, conflictedUnlockedVehicle };

        sked__Job_Allocation__c lockedAllocation = new sked__Job_Allocation__c(
            sked__Job__c = vehicleJob.Id, sked__Resource__c = lockedVehicle.Id, sked_Locked__c = true);
        sked__Job_Allocation__c unlockedAllocation = new sked__Job_Allocation__c(
            sked__Job__c = vehicleJob.Id, sked__Resource__c = conflictedUnlockedVehicle.Id);
        insert new List<sked__Job_Allocation__c>{
            lockedAllocation,
            unlockedAllocation,
            new sked__Job_Allocation__c(
                sked__Job__c = otherJob.Id, sked__Resource__c = conflictedUnlockedVehicle.Id,
                sked__Start__c = windowStart.addHours(2), sked__Set_End__c = windowStart.addHours(4))
        };

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob, new List<sked__Job_Allocation__c>{
            ctxAllocation(lockedAllocation.Id, vehicleJob.Id, lockedVehicle.Id),
            ctxAllocation(unlockedAllocation.Id, vehicleJob.Id, conflictedUnlockedVehicle.Id)
        });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        System.assertEquals(2, result.size(), 'The locked allocation survives and the conflicted unlocked one is soft-deleted - no new insert: ' + result);
        Boolean lockedUntouched = false;
        Boolean unlockedDeleted = false;
        for (sked__Job_Allocation__c allocation : result) {
            if (allocation.sked__Resource__c == lockedVehicle.Id) {
                System.assertNotEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, allocation.sked__Status__c, 'The locked allocation must survive untouched: ' + result);
                lockedUntouched = true;
            }
            if (allocation.sked__Resource__c == conflictedUnlockedVehicle.Id) {
                System.assertEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, allocation.sked__Status__c,
                    'The conflicted unlocked allocation must be trimmed (Deleted), not replaced with a new vehicle, since locked capacity alone already covers the requirement: ' + result);
                unlockedDeleted = true;
            }
        }
        System.assert(lockedUntouched && unlockedDeleted, 'Both allocations must be present in the result: ' + result);
    }

    // currentValidCount (2, one locked + one unlocked, both still valid) exceeds quantityNeeded (1) -
    // trim the redundant unlocked one rather than leaving it assigned.
    @isTest
    static void testReassignInvalidAssets_equipmentValidCountExceedsQuantity_trimsRedundantUnlocked() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8));
        insert shift;
        sked__Job__c equipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60, sked_Equipment_Subtype__c = '2RBC Asset');
        insert equipmentJob;

        sked__Resource__c lockedEquipment = new sked__Resource__c(
            Name = 'Locked Cot', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT, sked__Is_Active__c = true,
            sked__Primary_Region__c = region.Id, sked_Equipment_Subtype__c = '2RBC Asset');
        sked__Resource__c redundantEquipment = new sked__Resource__c(
            Name = 'Redundant Cot', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT, sked__Is_Active__c = true,
            sked__Primary_Region__c = region.Id, sked_Equipment_Subtype__c = '2RBC Asset');
        insert new List<sked__Resource__c>{ lockedEquipment, redundantEquipment };

        sked__Job_Allocation__c lockedAllocation = new sked__Job_Allocation__c(
            sked__Job__c = equipmentJob.Id, sked__Resource__c = lockedEquipment.Id, sked_Locked__c = true);
        sked__Job_Allocation__c redundantAllocation = new sked__Job_Allocation__c(
            sked__Job__c = equipmentJob.Id, sked__Resource__c = redundantEquipment.Id);
        insert new List<sked__Job_Allocation__c>{ lockedAllocation, redundantAllocation };

        skedDriveRegenContext ctx = buildContext(drive, shift, equipmentJob, new List<sked__Job_Allocation__c>{
            ctxAllocation(lockedAllocation.Id, equipmentJob.Id, lockedEquipment.Id),
            ctxAllocation(redundantAllocation.Id, equipmentJob.Id, redundantEquipment.Id)
        });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(equipmentJob.Id);
        Boolean lockedUntouched = false;
        Boolean redundantDeleted = false;
        for (sked__Job_Allocation__c allocation : result) {
            if (allocation.sked__Resource__c == lockedEquipment.Id) {
                System.assertNotEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, allocation.sked__Status__c, 'The locked equipment must survive untouched: ' + result);
                lockedUntouched = true;
            }
            if (allocation.sked__Resource__c == redundantEquipment.Id) {
                System.assertEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, allocation.sked__Status__c,
                    'The redundant unlocked equipment must be trimmed once the locked one alone meets quantity 1: ' + result);
                redundantDeleted = true;
            }
        }
        System.assert(lockedUntouched && redundantDeleted, 'Both allocations must be present in the result: ' + result);
    }

    @isTest
    static void testReassignInvalidAssets_newVehicleJobWithNoId_skipsWithoutError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        drive.sked_Do_Not_Use_Vehicle__c = false;
        drive.sked_Projected_Registered_Donors__c = 20;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = DateTime.now(), sked_Finish__c = DateTime.now().addHours(8), sked_Donors_Scheduled__c = 20);
        insert shift;
        // A freshly-built vehicle job that was never matched to an existing one (Id left null) -
        // e.g. Do Not Use Vehicle just flipped false with no prior vehicle job on this drive.
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob, new List<sked__Job_Allocation__c>());

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        System.assertEquals(null, ctx.allocationsByJobId.get(null),
            'A job with no Id must be skipped entirely - reassigning it would insert an allocation with no master-detail parent');
    }

    @isTest
    static void testReassignInvalidAssets_equipmentQuantityInsufficient_addsReplacementEquipment() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8));
        insert shift;
        sked__Job__c equipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Quantity__c = 2, sked__Region__c = region.Id, sked__Duration__c = 60, sked_Equipment_Subtype__c = '2RBC Asset');
        insert equipmentJob;
        // Zero allocations assigned - well short of the 2 required.

        sked__Resource__c equipment1 = new sked__Resource__c(
            Name = 'Cot 1', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id,
            sked_Equipment_Subtype__c = '2RBC Asset');
        sked__Resource__c equipment2 = new sked__Resource__c(
            Name = 'Cot 2', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id,
            sked_Equipment_Subtype__c = '2RBC Asset');
        insert new List<sked__Resource__c>{ equipment1, equipment2 };

        skedDriveRegenContext ctx = buildContext(drive, shift, equipmentJob, new List<sked__Job_Allocation__c>());

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(equipmentJob.Id);
        System.assertEquals(2, result.size(), 'Both available equipment resources must be picked to cover the required quantity of 2: ' + result);
        for (sked__Job_Allocation__c allocation : result) {
            System.assertEquals(null, allocation.Id, 'Every picked equipment allocation must be a new insert, since none was previously assigned');
        }
    }

    // Equipment of the WRONG subtype must never be picked, even though it's otherwise available.
    // The job requires 'Plasma Asset', deliberately NOT '2RBC Asset' - skedTestDataFactory's default
    // CO equipment (testEquipment1) is built with sked_Equipment_Subtype__c = '2RBC Asset', so using
    // that value here risks that default resource satisfying the requirement regardless of whether
    // the subtype filter does anything, if it's ever in this test's candidate pool.
    @isTest
    static void testReassignInvalidAssets_equipmentWrongSubtype_isNeverChosen() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8));
        insert shift;
        sked__Job__c equipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60, sked_Equipment_Subtype__c = 'Plasma Asset');
        insert equipmentJob;

        sked__Resource__c wrongSubtype = new sked__Resource__c(
            Name = 'Wrong Subtype Equipment', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT, sked__Is_Active__c = true,
            sked__Primary_Region__c = region.Id, sked_Equipment_Subtype__c = 'Platelet Asset');
        insert wrongSubtype;

        skedDriveRegenContext ctx = buildContext(drive, shift, equipmentJob, new List<sked__Job_Allocation__c>());

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(equipmentJob.Id);
        System.assertEquals(0, result.size(),
            'With no equipment of the required Plasma Asset subtype available (only a Platelet Asset one, plus the factory default 2RBC Asset one), nothing must be chosen: ' + result);
    }

    // A resource that's still valid and still gets re-picked keeps its EXISTING allocation Id,
    // not a blanket delete-all-then-insert-all. Forces reassignment to actually run (a second,
    // co-assigned vehicle is conflicted elsewhere) while keptVehicle's own capacity alone already
    // satisfies the requirement - and is deliberately given LESS capacity than the factory's default
    // 50-capacity CO vehicles (skedTestDataFactory's Test Vehicle 1/2, also in the candidate pool),
    // so pickSmallestVehicleSet's smallest-totalCap tie-break deterministically picks keptVehicle
    // over them, rather than the test depending on incidental candidate ordering.
    @isTest
    static void testReassignInvalidAssets_replacementIncludesCurrentResource_preservesExistingAllocationId() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        drive.sked_Do_Not_Use_Vehicle__c = false;
        drive.sked_Projected_Registered_Donors__c = 20;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowEnd, sked_Donors_Scheduled__c = 20);
        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = otherDrive.Id);
        insert new List<sked_Drive_Shift__c>{ shift, otherShift };

        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive__c = drive.Id, sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive__c = otherDrive.Id, sked_Drive_Shift__c = otherShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert new List<sked__Job__c>{ vehicleJob, otherJob };

        // keptVehicle alone covers the 20-donor requirement and has no conflict - it must remain
        // part of the plan. conflictedVehicle is also currently (unlocked) assigned to vehicleJob,
        // but is double-booked on otherDrive, overlapping this shift's window - its presence is what
        // forces isAllAssignedValid=false and reassignment to actually run.
        sked__Resource__c keptVehicle = new sked__Resource__c(
            Name = 'Kept Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        sked__Resource__c conflictedVehicle = new sked__Resource__c(
            Name = 'Conflicted Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 15, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert new List<sked__Resource__c>{ keptVehicle, conflictedVehicle };

        sked__Job_Allocation__c keptAllocation = new sked__Job_Allocation__c(sked__Job__c = vehicleJob.Id, sked__Resource__c = keptVehicle.Id);
        sked__Job_Allocation__c conflictedAllocation = new sked__Job_Allocation__c(sked__Job__c = vehicleJob.Id, sked__Resource__c = conflictedVehicle.Id);
        insert new List<sked__Job_Allocation__c>{
            keptAllocation,
            conflictedAllocation,
            new sked__Job_Allocation__c(
                sked__Job__c = otherJob.Id, sked__Resource__c = conflictedVehicle.Id,
                sked__Start__c = windowStart.addHours(2), sked__Set_End__c = windowStart.addHours(4))
        };

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob, new List<sked__Job_Allocation__c>{
            ctxAllocation(keptAllocation.Id, vehicleJob.Id, keptVehicle.Id),
            ctxAllocation(conflictedAllocation.Id, vehicleJob.Id, conflictedVehicle.Id)
        });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        Boolean keptRecordPreserved = false;
        Boolean conflictedRecordDeleted = false;
        for (sked__Job_Allocation__c allocation : result) {
            if (allocation.sked__Resource__c == keptVehicle.Id) {
                System.assertEquals(keptAllocation.Id, allocation.Id,
                    'A resource that is still part of the chosen set must keep its EXISTING allocation Id, not be deleted and recreated: ' + result);
                System.assertNotEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, allocation.sked__Status__c,
                    'The preserved allocation must not be marked Deleted: ' + result);
                keptRecordPreserved = true;
            }
            if (allocation.sked__Resource__c == conflictedVehicle.Id) {
                System.assertEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, allocation.sked__Status__c,
                    'The genuinely conflicted allocation must be marked Deleted: ' + result);
                conflictedRecordDeleted = true;
            }
        }
        System.assert(keptRecordPreserved, 'The still-valid, still-needed vehicle must remain in the result: ' + result);
        System.assert(conflictedRecordDeleted, 'The conflicted vehicle allocation must be soft-deleted: ' + result);
    }

    @isTest
    static void testReassignInvalidAssets_fixedSiteNonWbDrive_leavesInvalidVehicleAllocationUntouched() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2'); // Fixed Site
        // testLocation2 defaults to WB; SiteService.validateOperationTypeChange blocks changing it while this non-cancelled drive references it, so cancel first, flip, then restore.
        // That Cancel also queues an async cascade-cancel (skedDriveHandler -> cascadeCancelEvents) that Cancels this drive's Jobs at Test.stopTest() - harmless here since assertions only read the in-memory ctx, not a re-query.
        rawDrive.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
        update rawDrive;
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        site.Operation_Type__c = skedConstants.OPERATION_TYPE_INTEGRATED;
        update site;
        rawDrive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // reassignment only runs on non-Draft drives
        rawDrive.sked_Projected_Registered_Donors__c = 20;
        update rawDrive;
        // sked_Operation_Type__c is a formula field never populated on the in-memory rawDrive - re-fetch so the gate reads a real value.
        sked_Drive__c drive = [
            SELECT Id, sked_Status__c, sked_Type_of_Drive__c, sked_Operation_Type__c, sked_Do_Not_Use_Vehicle__c,
                sked_Collection_Operation__c, sked_Drive_Date__c, sked_Drive_Site__c, sked_Projected_Registered_Donors__c,
                sked_Account__c
            FROM sked_Drive__c WHERE Id = :rawDrive.Id
        ];
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8), sked_Donors_Scheduled__c = 20);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert vehicleJob;

        // Inactive - would trigger a Mobile-rules replacement if the gate didn't suppress it; Employment_Status__c must accompany Is_Active__c=false or skedResourceHandler.populateResourceActivation resets it on insert.
        sked__Resource__c invalidVehicle = new sked__Resource__c(
            Name = 'Inactive Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = false,
            sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE, sked__Primary_Region__c = region.Id);
        insert invalidVehicle;
        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(sked__Job__c = vehicleJob.Id, sked__Resource__c = invalidVehicle.Id);
        insert allocation;

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob,
            new List<sked__Job_Allocation__c>{ ctxAllocation(allocation.Id, vehicleJob.Id, invalidVehicle.Id) });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        System.assertEquals(1, result.size(), 'Fixed Site must not add or remove vehicle allocations at all: ' + result);
        System.assertEquals(allocation.Id, result[0].Id, 'The existing allocation record must be left exactly as it was');
        System.assertNotEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, result[0].sked__Status__c,
            'An inactive vehicle would be replaced under Mobile rules - Fixed Site must skip vehicle reassignment entirely');
    }

    @isTest
    static void testReassignInvalidAssets_fixedSiteNonWbDrive_stillReassignsInvalidEquipment() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2'); // Fixed Site
        // testLocation2 defaults to WB; SiteService.validateOperationTypeChange blocks changing it while this non-cancelled drive references it, so cancel first, flip, then restore.
        // That Cancel also queues an async cascade-cancel (skedDriveHandler -> cascadeCancelEvents) that Cancels this drive's Jobs at Test.stopTest() - harmless here since assertions only read the in-memory ctx, not a re-query.
        rawDrive.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
        update rawDrive;
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        site.Operation_Type__c = skedConstants.OPERATION_TYPE_INTEGRATED;
        update site;
        rawDrive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        update rawDrive;
        sked_Drive__c drive = [
            SELECT Id, sked_Status__c, sked_Type_of_Drive__c, sked_Operation_Type__c, sked_Do_Not_Use_Vehicle__c,
                sked_Collection_Operation__c, sked_Drive_Date__c, sked_Drive_Site__c, sked_Projected_Registered_Donors__c,
                sked_Account__c
            FROM sked_Drive__c WHERE Id = :rawDrive.Id
        ];
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8));
        insert shift;
        sked__Job__c equipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert equipmentJob;

        // Inactive - equipment reassignment is deliberately left ungated, so this must still be replaced; Employment_Status__c must accompany Is_Active__c=false (see the vehicle test above).
        sked__Resource__c invalidEquipment = new sked__Resource__c(
            Name = 'Inactive Scale', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Is_Active__c = false, sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE,
            sked__Primary_Region__c = region.Id);
        sked__Resource__c replacementEquipment = new sked__Resource__c(
            Name = 'Active Scale', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert new List<sked__Resource__c>{ invalidEquipment, replacementEquipment };
        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(sked__Job__c = equipmentJob.Id, sked__Resource__c = invalidEquipment.Id);
        insert allocation;

        skedDriveRegenContext ctx = buildContext(drive, shift, equipmentJob,
            new List<sked__Job_Allocation__c>{ ctxAllocation(allocation.Id, equipmentJob.Id, invalidEquipment.Id) });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(equipmentJob.Id);
        Boolean foundDeletedOriginal = false;
        Boolean foundNewReplacement = false;
        for (sked__Job_Allocation__c resultAllocation : result) {
            if (resultAllocation.Id == allocation.Id && resultAllocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                foundDeletedOriginal = true;
            }
            if (resultAllocation.Id == null && resultAllocation.sked__Resource__c == replacementEquipment.Id) {
                foundNewReplacement = true;
            }
        }
        System.assert(foundDeletedOriginal, 'The invalid equipment allocation must still be soft-deleted for a Fixed Site drive: ' + result);
        System.assert(foundNewReplacement, 'The available replacement equipment must still be picked for a Fixed Site drive: ' + result);
    }

    @isTest
    static void testReassignInvalidAssets_fixedSiteWbDrive_leavesInvalidVehicleAllocationUntouched() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2'); // Fixed Site
        rawDrive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        rawDrive.sked_Projected_Registered_Donors__c = 20;
        update rawDrive;
        // testLocation2 defaults to WB (skedTestDataFactory.cls:557) - this test needs it, so no flip required.
        sked_Drive__c drive = [
            SELECT Id, sked_Status__c, sked_Type_of_Drive__c, sked_Operation_Type__c, sked_Do_Not_Use_Vehicle__c,
                sked_Collection_Operation__c, sked_Drive_Date__c, sked_Drive_Site__c, sked_Projected_Registered_Donors__c,
                sked_Account__c
            FROM sked_Drive__c WHERE Id = :rawDrive.Id
        ];
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8), sked_Donors_Scheduled__c = 20);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert vehicleJob;

        // Employment_Status__c must accompany Is_Active__c=false here too - see test 1's invalidVehicle comment.
        sked__Resource__c invalidVehicle = new sked__Resource__c(
            Name = 'Inactive Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = false,
            sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE, sked__Primary_Region__c = region.Id);
        sked__Resource__c replacementVehicle = new sked__Resource__c(
            Name = 'Active Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert new List<sked__Resource__c>{ invalidVehicle, replacementVehicle };
        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(sked__Job__c = vehicleJob.Id, sked__Resource__c = invalidVehicle.Id);
        insert allocation;

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob,
            new List<sked__Job_Allocation__c>{ ctxAllocation(allocation.Id, vehicleJob.Id, invalidVehicle.Id) });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(vehicleJob.Id);
        System.assertEquals(1, result.size(),
            'A Non Integrated WB Fixed Site drive must not add or remove vehicle allocations at all - replacementVehicle is deliberately '
                + 'available and sufficient, so a non-empty candidate pool is not what suppresses the reassignment: ' + result);
        System.assertEquals(allocation.Id, result[0].Id, 'The existing allocation record must be left exactly as it was');
        System.assertNotEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, result[0].sked__Status__c,
            'An inactive vehicle would be replaced under Mobile rules - wbFixedSiteGenerator.js has no real vehicle validation either, '
                + 'so a WB Fixed Site drive must skip vehicle reassignment exactly like a non-WB one');
    }

    @isTest
    static void testReassignInvalidAssets_fixedSiteWbDrive_stillReassignsInvalidEquipment() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2'); // Fixed Site
        rawDrive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        update rawDrive;
        // testLocation2 defaults to WB (skedTestDataFactory.cls:557) - this test needs it, so no flip required.
        sked_Drive__c drive = [
            SELECT Id, sked_Status__c, sked_Type_of_Drive__c, sked_Operation_Type__c, sked_Do_Not_Use_Vehicle__c,
                sked_Collection_Operation__c, sked_Drive_Date__c, sked_Drive_Site__c, sked_Projected_Registered_Donors__c,
                sked_Account__c
            FROM sked_Drive__c WHERE Id = :rawDrive.Id
        ];
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        DateTime windowStart = DateTime.now();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id, sked_Start__c = windowStart, sked_Finish__c = windowStart.addHours(8));
        insert shift;
        sked__Job__c equipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert equipmentJob;

        // Employment_Status__c must accompany Is_Active__c=false - see the vehicle tests above.
        sked__Resource__c invalidEquipment = new sked__Resource__c(
            Name = 'Inactive Scale', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Is_Active__c = false, sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE,
            sked__Primary_Region__c = region.Id);
        sked__Resource__c replacementEquipment = new sked__Resource__c(
            Name = 'Active Scale', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Is_Active__c = true, sked__Primary_Region__c = region.Id);
        insert new List<sked__Resource__c>{ invalidEquipment, replacementEquipment };
        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(sked__Job__c = equipmentJob.Id, sked__Resource__c = invalidEquipment.Id);
        insert allocation;

        skedDriveRegenContext ctx = buildContext(drive, shift, equipmentJob,
            new List<sked__Job_Allocation__c>{ ctxAllocation(allocation.Id, equipmentJob.Id, invalidEquipment.Id) });

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        List<sked__Job_Allocation__c> result = ctx.allocationsByJobId.get(equipmentJob.Id);
        Boolean foundDeletedOriginal = false;
        Boolean foundNewReplacement = false;
        for (sked__Job_Allocation__c resultAllocation : result) {
            if (resultAllocation.Id == allocation.Id && resultAllocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DELETED) {
                foundDeletedOriginal = true;
            }
            if (resultAllocation.Id == null && resultAllocation.sked__Resource__c == replacementEquipment.Id) {
                foundNewReplacement = true;
            }
        }
        System.assert(foundDeletedOriginal,
            'The vehicle gate must not over-reach - equipment reassignment still runs for a WB Fixed Site drive: ' + result);
        System.assert(foundNewReplacement,
            'The available replacement equipment must still be picked for a WB Fixed Site drive: ' + result);
    }

    // A Draft-status drive must never be reassigned.
    @isTest
    static void testReassignInvalidAssets_draftDrive_neverReassigns() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        drive.sked_Do_Not_Use_Vehicle__c = false;
        drive.sked_Projected_Registered_Donors__c = 100;
        update drive;
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Donors_Scheduled__c = 100);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = region.Id, sked__Duration__c = 60);
        insert vehicleJob;
        // Zero allocations - would normally force a full reassignment on a non-Draft drive.

        skedDriveRegenContext ctx = buildContext(drive, shift, vehicleJob, new List<sked__Job_Allocation__c>());

        Test.startTest();
        skedMobileAssetReassigner.reassignInvalidAssets(ctx);
        Test.stopTest();

        System.assertEquals(0, ctx.allocationsByJobId.get(vehicleJob.Id).size(),
            'A Draft-status drive must never be reassigned - ctx is left exactly as the caller had it');
    }
}
