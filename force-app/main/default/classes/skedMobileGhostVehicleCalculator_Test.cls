/**
 * Verifies the live vehicle-matching path is actually reachable: it depends on a specific Apex method
 * being the one that backs the LWC's resource-data call, since a same-named method exists whose query
 * doesn't select the required capacity/tag fields.
 */
@isTest
private class skedMobileGhostVehicleCalculator_Test {

    private static sked_Drive__c setupDrive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_2RBC_Projected_Procedures__c = 30;
        testDrive1.sked_WB_Projected_Procedures__c = 20;
        testDrive1.sked_Do_Not_Use_Vehicle__c = false;
        testDrive1.sked_Prefer_System_Generated_Vehicles__c = true;
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        update testDrive1;

        return queryDrive(testDrive1.Id);
    }

    private static sked_Drive__c queryDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Projected_Registered_Donors__c,
                sked_APT_Quantity__c, sked_Travel_Time_Included__c, sked_Account__r.Type, sked_Account__r.Industry_Code__c,
                sked_Account__r.Accepts_Automation2__c,
                sked_Do_Not_Use_Vehicle__c, sked_Number_of_Vehicles__c, sked_Total_Vehicle_Requested__c, sked_Number_of_2RBC_Assets__c, sked_IMPACT__c,
                sked_Status__c, sked_Prefer_System_Generated_Vehicles__c, sked_Account__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    private static void setShiftDonorsScheduled(skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, Decimal donorsScheduled) {
        for (skedMobileDriveShiftCalculator.DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            shift.donorsScheduled = donorsScheduled;
        }
    }

    @isTest
    static void testCalculate_notDraftStatus_leavesNumberOfVehiclesUnchanged() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        update drive;
        drive = queryDrive(drive.Id);
        drive.sked_Number_of_Vehicles__c = 7;

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);

        Test.startTest();
        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(
            drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(7, drive.sked_Number_of_Vehicles__c, 'A non-Draft drive must not have its vehicle count recomputed');
    }

    @isTest
    static void testCalculate_doNotUseVehicle_setsZeroVehicles() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Do_Not_Use_Vehicle__c = true;
        update drive;
        drive = queryDrive(drive.Id);

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);

        Test.startTest();
        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(
            drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(0, drive.sked_Number_of_Vehicles__c, 'A do-not-use-vehicle drive must have zero vehicles');
    }

    @isTest
    static void testCalculate_notPreferSystemGenerated_leavesNumberOfVehiclesUnchanged() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Prefer_System_Generated_Vehicles__c = false;
        update drive;
        drive = queryDrive(drive.Id);
        drive.sked_Number_of_Vehicles__c = 3;

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);

        Test.startTest();
        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(
            drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(3, drive.sked_Number_of_Vehicles__c, 'Without preferSystemGeneratedVehicles, the vehicle count must be left as-is');
    }

    @isTest
    static void testCalculate_donorsWithinSingleVehicleCapacity_setsOneVehicle() {
        sked_Drive__c drive = setupDrive();

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        setShiftDonorsScheduled(shiftsMetadata, 40);
        System.assertEquals(2, masterData.vehicles.size(), 'Test setup must produce 2 available Vehicle-type resources for the CO (50 capacity each)');

        Test.startTest();
        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(
            drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(1, drive.sked_Number_of_Vehicles__c, 'One 50-capacity vehicle covers 40 scheduled donors');
    }

    @isTest
    static void testCalculate_donorsExceedSingleVehicleCapacity_setsTwoVehicles() {
        sked_Drive__c drive = setupDrive();

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        setShiftDonorsScheduled(shiftsMetadata, 80);

        Test.startTest();
        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(
            drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(2, drive.sked_Number_of_Vehicles__c, 'Two 50-capacity vehicles are needed to cover 80 scheduled donors');
    }

    // The Draft ghost-vehicle count is deliberately unbounded (see this method's header) - a DOT
    // vehicle must never be passed over here just for being DOT-flagged, unlike pickSmallestVehicleSet
    // (used once an actual vehicle is being assigned), which does respect real DOT/CDL limits.
    @isTest
    static void testCalculate_singleDotFlaggedVehicleSufficient_stillChosenDespiteBeingDot() {
        sked_Drive__c drive = setupDrive();
        sked__Resource__c testVehicle1 = [SELECT Id FROM sked__Resource__c WHERE Name = 'Test Vehicle 1'];
        testVehicle1.sked_DOT__c = true;
        update testVehicle1;
        drive = queryDrive(drive.Id);

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        setShiftDonorsScheduled(shiftsMetadata, 40);

        Test.startTest();
        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(
            drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(1, drive.sked_Number_of_Vehicles__c, 'A single 50-capacity vehicle covers 40 donors regardless of its DOT flag - this path never applies DOT/CDL limits');
    }

    @isTest
    static void testCalculate_everyShiftHasZeroDonorsScheduled_fallsBackToProjectedRegisteredDonors() {
        sked_Drive__c drive = setupDrive();
        drive.sked_Projected_Registered_Donors__c = 80;
        update drive;
        drive = queryDrive(drive.Id);

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        setShiftDonorsScheduled(shiftsMetadata, 0); // degenerate case: every shift reports zero

        Test.startTest();
        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(
            drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(2, drive.sked_Number_of_Vehicles__c,
            'With every shift at 0 donorsScheduled, capacity must be sized against the drive\'s 80 Projected Registered Donors, not treated as needing zero vehicles');
    }

    @isTest
    static void testCalculate_noVehicleCombinationCoversDonors_defaultsToOneVehicle() {
        sked_Drive__c drive = setupDrive();

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        setShiftDonorsScheduled(shiftsMetadata, 1000);

        Test.startTest();
        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(
            drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(1, drive.sked_Number_of_Vehicles__c, 'When no combination of available vehicles can cover the requirement, default to 1');
    }

    @isTest
    static void testCalculate_vehicleMissingRequiredTag_isExcludedFromCandidates() {
        sked_Drive__c drive = setupDrive();

        sked__Tag__c requiredTag = new sked__Tag__c(Name = 'Vehicle Only Tag', sked__Type__c = skedConstants.TAG_TYPE_ASSET_TYPE, sked_Resource_Type__c = 'Vehicle');
        insert requiredTag;
        insert new sked__Account_Tag__c(sked__Account__c = drive.sked_Account__c, sked__Tag__c = requiredTag.Id, sked__Required__c = true);

        sked__Resource__c testVehicle1 = [SELECT Id FROM sked__Resource__c WHERE Name = 'Test Vehicle 1'];
        insert new sked__Resource_Tag__c(sked__Resource__c = testVehicle1.Id, sked__Tag__c = requiredTag.Id, sked_Start_Date__c = drive.sked_Drive_Date__c.addDays(-1));

        skedMobileDriveShiftCalculator.MasterData masterData = skedMobileDriveShiftCalculator.loadMasterData(drive);
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedMobileDriveShiftCalculator.calculateDriveShiftsMetadata(drive, masterData);
        setShiftDonorsScheduled(shiftsMetadata, 40);
        System.assertEquals(1, masterData.vehicleRequiredTagIds.size(), 'The required account tag must be resolved as a Vehicle-applicable required tag');

        Test.startTest();
        skedMobileGhostVehicleCalculator.calculateDraftDriveGhostVehicleQuantity(
            drive, shiftsMetadata, masterData);
        Test.stopTest();

        System.assertEquals(1, drive.sked_Number_of_Vehicles__c, 'Only the tagged vehicle is eligible - it alone still covers 40 donors');
    }

    @isTest
    static void testPickSmallestVehicleSet_multiVehicleRequirement_returnsSufficientCapacitySet() {
        // No single vehicle covers 550 - the greedy accumulator must combine multiple.
        List<sked__Resource__c> candidates = new List<sked__Resource__c>{
            new sked__Resource__c(Name = 'V1', sked_Pres_Donor_Capacity__c = 100),
            new sked__Resource__c(Name = 'V2', sked_Pres_Donor_Capacity__c = 100),
            new sked__Resource__c(Name = 'V3', sked_Pres_Donor_Capacity__c = 300),
            new sked__Resource__c(Name = 'V4', sked_Pres_Donor_Capacity__c = 300)
        };

        Test.startTest();
        List<sked__Resource__c> chosen = skedMobileGhostVehicleCalculator.pickSmallestVehicleSet(candidates, 550, 999999999, 999999999);
        Test.stopTest();

        Decimal totalCapacity = 0;
        for (sked__Resource__c vehicle : chosen) {
            totalCapacity += vehicle.sked_Pres_Donor_Capacity__c;
        }
        System.assert(totalCapacity >= 550, 'The chosen vehicle set must cover the required capacity, got ' + totalCapacity);
    }

    // ===== DOT/CDL ranking tiers (helper.js:1299-1363) =====

    @isTest
    static void testPickSmallestVehicleSet_smallestSetViolatesMaxDOT_prefersLargerValidSet() {
        List<sked__Resource__c> candidates = new List<sked__Resource__c>{
            new sked__Resource__c(Name = 'DOT Vehicle', sked_Pres_Donor_Capacity__c = 50, sked_DOT__c = true),
            new sked__Resource__c(Name = 'Non-DOT Vehicle', sked_Pres_Donor_Capacity__c = 60, sked_DOT__c = false)
        };

        Test.startTest();
        List<sked__Resource__c> chosen = skedMobileGhostVehicleCalculator.pickSmallestVehicleSet(candidates, 40, 0, 999999999);
        Test.stopTest();

        System.assertEquals(1, chosen.size(), 'Exactly one vehicle must be chosen');
        System.assertEquals('Non-DOT Vehicle', chosen[0].Name,
            'With maxDOT=0, the smaller-capacity DOT vehicle must lose to the larger-capacity non-DOT vehicle, even though the DOT vehicle alone would satisfy capacity at lower cost');
    }

    @isTest
    static void testPickSmallestVehicleSet_noSetSatisfiesMaxDOTOrMaxCDL_stillReturnsRank3Fallback() {
        List<sked__Resource__c> candidates = new List<sked__Resource__c>{
            new sked__Resource__c(Name = 'DOT+CDL Vehicle', sked_Pres_Donor_Capacity__c = 50, sked_DOT__c = true, sked_CDL__c = true)
        };

        Test.startTest();
        List<sked__Resource__c> chosen = skedMobileGhostVehicleCalculator.pickSmallestVehicleSet(candidates, 40, 0, 0);
        Test.stopTest();

        System.assertEquals(1, chosen.size(), 'Even when no candidate set satisfies either cap, the rank-3 fallback must still return a covering set, never nothing');
    }
}
