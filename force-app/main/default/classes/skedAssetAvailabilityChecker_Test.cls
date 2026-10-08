@isTest
private class skedAssetAvailabilityChecker_Test {

    @isTest
    static void testLoadAvailableAssets_coMemberNoConflict_returnsResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Test Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, DateTime.now(), DateTime.now().addHours(8), new Set<Id>());
        Test.stopTest();

        Boolean found = false;
        for (sked__Resource__c resource : available) {
            if (resource.Id == vehicle.Id) {
                found = true;
            }
        }
        System.assert(found, 'A CO-member vehicle with no conflicting allocation must be returned as available');
    }

    @isTest
    static void testLoadAvailableAssets_missingRequiredTag_excludesResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Untagged Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;
        sked__Tag__c requiredTag = new sked__Tag__c(Name = 'DOT', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION);
        insert requiredTag;
        // Deliberately not tagging the vehicle with it.

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, DateTime.now(), DateTime.now().addHours(8), new Set<Id>{ requiredTag.Id });
        Test.stopTest();

        for (sked__Resource__c resource : available) {
            System.assertNotEquals(vehicle.Id, resource.Id, 'A vehicle missing a required tag must be excluded');
        }
    }

    @isTest
    static void testLoadAvailableAssets_conflictingAllocationOnOtherDrive_excludesResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Booked Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;

        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = otherDrive.Id);
        insert otherShift;
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive__c = otherDrive.Id, sked_Drive_Shift__c = otherShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert otherJob;

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        insert new sked__Job_Allocation__c(
            sked__Job__c = otherJob.Id, sked__Resource__c = vehicle.Id,
            sked__Start__c = windowStart.addHours(2), sked__Set_End__c = windowStart.addHours(4) // overlaps [start, end)
        );

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, windowStart, windowEnd, new Set<Id>());
        Test.stopTest();

        for (sked__Resource__c resource : available) {
            System.assertNotEquals(vehicle.Id, resource.Id, 'A vehicle already allocated to an overlapping window on a different drive must be excluded');
        }
    }

    @isTest
    static void testLoadAvailableAssets_declinedAllocationOnOtherDrive_doesNotExcludeResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Declined Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;

        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = otherDrive.Id);
        insert otherShift;
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive__c = otherDrive.Id, sked_Drive_Shift__c = otherShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert otherJob;

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        insert new sked__Job_Allocation__c(
            sked__Job__c = otherJob.Id, sked__Resource__c = vehicle.Id, sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DECLINED,
            sked__Start__c = windowStart.addHours(2), sked__Set_End__c = windowStart.addHours(4) // overlaps [start, end)
        );

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, windowStart, windowEnd, new Set<Id>());
        Test.stopTest();

        Boolean found = false;
        for (sked__Resource__c resource : available) {
            if (resource.Id == vehicle.Id) {
                found = true;
            }
        }
        System.assert(found, 'A Declined allocation must not count as a conflict, matching slwcAvailator skipping EVENT_STATUS.DECLINED events');
    }

    @isTest
    static void testLoadAvailableAssets_allocationOnCancelledJob_doesNotExcludeResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Cancelled Job Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;

        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = otherDrive.Id);
        insert otherShift;
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive__c = otherDrive.Id, sked_Drive_Shift__c = otherShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_CANCELLED
        );
        insert otherJob;

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        insert new sked__Job_Allocation__c(
            sked__Job__c = otherJob.Id, sked__Resource__c = vehicle.Id,
            sked__Start__c = windowStart.addHours(2), sked__Set_End__c = windowStart.addHours(4) // overlaps [start, end)
        );

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, windowStart, windowEnd, new Set<Id>());
        Test.stopTest();

        Boolean found = false;
        for (sked__Resource__c resource : available) {
            if (resource.Id == vehicle.Id) {
                found = true;
            }
        }
        System.assert(found, 'An allocation on a Cancelled job must not count as a conflict, matching the repo SOQL rule and the LWC source query');
    }

    @isTest
    static void testIsCurrentlyAssignedResourceStillAvailable_noConflict_returnsTrue() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Free Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;

        Test.startTest();
        Boolean stillAvailable = skedAssetAvailabilityChecker.isCurrentlyAssignedResourceStillAvailable(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, vehicle.Id, drive.Id, DateTime.now(), DateTime.now().addHours(8), new Set<Id>());
        Test.stopTest();

        System.assertEquals(true, stillAvailable, 'A vehicle with no conflicting allocation elsewhere must still be considered available');
    }

    // isCurrentlyAssignedResourceStillAvailable must reuse the exact same pool loadAvailableAssets
    // uses for new candidates, not a narrower time-conflict-only check - a resource dedicated to a
    // different site must be considered invalid here too. Uses Equipment (not Vehicle) -
    // skedResourceHandler.validate rejects sked_Dedicated_to_Site__c on a Vehicle.
    @isTest
    static void testIsCurrentlyAssignedResourceStillAvailable_dedicatedToDifferentSite_returnsFalse() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c equipment = new sked__Resource__c(
            Name = 'Dedicated Equipment', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Is_Active__c = true, sked__Primary_Region__c = region.Id,
            sked_Dedicated_to_Site__c = otherDrive.sked_Drive_Site__c
        );
        insert equipment;
        System.assertNotEquals(drive.sked_Drive_Site__c, otherDrive.sked_Drive_Site__c, 'Test setup must use two different drive sites');

        Test.startTest();
        Boolean stillAvailable = skedAssetAvailabilityChecker.isCurrentlyAssignedResourceStillAvailable(
            skedConstants.ASSET_TYPE_EQUIPMENT, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, equipment.Id, drive.Id, DateTime.now(), DateTime.now().addHours(8), new Set<Id>());
        Test.stopTest();

        System.assertEquals(false, stillAvailable, 'Equipment dedicated to a different site must not be considered still available, even with no time conflict');
    }

    // An explicit sked__Availability__c unavailability window overlapping the shift must exclude
    // the resource.
    @isTest
    static void testLoadAvailableAssets_unavailabilityWindowOverlapsShift_excludesResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Unavailable Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        insert new sked__Availability__c(
            sked__Resource__c = vehicle.Id, sked__Is_Available__c = false, sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked__Start__c = windowStart.addHours(2), sked__Finish__c = windowStart.addHours(4)
        );

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, windowStart, windowEnd, new Set<Id>());
        Test.stopTest();

        for (sked__Resource__c resource : available) {
            System.assertNotEquals(vehicle.Id, resource.Id, 'A vehicle with an overlapping unavailability window must be excluded');
        }
    }

    // A conflicting sked__Activity__c overlapping the shift must exclude the resource.
    @isTest
    static void testLoadAvailableAssets_conflictingActivityOverlapsShift_excludesResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Busy Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        insert new sked__Activity__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c, sked__Resource__c = vehicle.Id,
            sked__Type__c = 'Administration', sked__Start__c = windowStart.addHours(2), sked__End__c = windowStart.addHours(4)
        );

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, windowStart, windowEnd, new Set<Id>());
        Test.stopTest();

        for (sked__Resource__c resource : available) {
            System.assertNotEquals(vehicle.Id, resource.Id, 'A vehicle with an overlapping conflicting activity must be excluded');
        }
    }

    // An On Call activity is explicitly excluded from the conflict check.
    @isTest
    static void testLoadAvailableAssets_onCallActivityOverlapsShift_doesNotExcludeResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'On Call Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;

        DateTime windowStart = DateTime.now();
        DateTime windowEnd = windowStart.addHours(8);
        insert new sked__Activity__c(
            sked_Collection_Operation__c = drive.sked_Collection_Operation__c, sked__Resource__c = vehicle.Id,
            sked__Type__c = skedConstants.ACTIVITY_TYPE_ON_CALL, sked__Start__c = windowStart.addHours(2), sked__End__c = windowStart.addHours(4)
        );

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, windowStart, windowEnd, new Set<Id>());
        Test.stopTest();

        Boolean found = false;
        for (sked__Resource__c resource : available) {
            if (resource.Id == vehicle.Id) {
                found = true;
            }
        }
        System.assert(found, 'An On Call activity must never count as a conflict, matching slwcAllocationService excludedActivityTypes');
    }

    // A tag inside its own restriction window does not count toward satisfying a required tag.
    @isTest
    static void testLoadAvailableAssets_requiredTagCurrentlyRestricted_excludesResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Restricted Tag Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked_Pres_Donor_Capacity__c = 20, sked__Is_Active__c = true, sked__Primary_Region__c = region.Id
        );
        insert vehicle;
        sked__Tag__c requiredTag = new sked__Tag__c(Name = 'DOT', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION);
        insert requiredTag;
        insert new sked__Resource_Tag__c(
            sked__Resource__c = vehicle.Id, sked__Tag__c = requiredTag.Id, sked_Start_Date__c = drive.sked_Drive_Date__c.addDays(-30),
            sked_Restriction_Start_Date__c = drive.sked_Drive_Date__c.addDays(-1), sked_Restriction_End_Date__c = drive.sked_Drive_Date__c.addDays(1)
        );

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_VEHICLE, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, DateTime.now(), DateTime.now().addHours(8), new Set<Id>{ requiredTag.Id });
        Test.stopTest();

        for (sked__Resource__c resource : available) {
            System.assertNotEquals(vehicle.Id, resource.Id, 'A tag inside its own restriction window must not satisfy the requirement');
        }
    }

    // Dedicated-to-site is a HARD exclusion, not a soft preference.
    @isTest
    static void testLoadAvailableAssets_dedicatedToDifferentSite_excludesResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c otherDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c equipment = new sked__Resource__c(
            Name = 'Other Site Equipment', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Is_Active__c = true, sked__Primary_Region__c = region.Id,
            sked_Dedicated_to_Site__c = otherDrive.sked_Drive_Site__c
        );
        insert equipment;
        System.assertNotEquals(drive.sked_Drive_Site__c, otherDrive.sked_Drive_Site__c, 'Test setup must use two different drive sites');

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_EQUIPMENT, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, DateTime.now(), DateTime.now().addHours(8), new Set<Id>());
        Test.stopTest();

        for (sked__Resource__c resource : available) {
            System.assertNotEquals(equipment.Id, resource.Id, 'Equipment dedicated to a different site must be hard-excluded');
        }
    }

    // Positive case: a resource dedicated to THIS drive's own site must still be available.
    // Uses Equipment (not Vehicle) - skedResourceHandler.validate rejects sked_Dedicated_to_Site__c
    // on a Vehicle.
    @isTest
    static void testLoadAvailableAssets_dedicatedToSameSite_returnsResource() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked__Resource__c equipment = new sked__Resource__c(
            Name = 'Same Site Equipment', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Is_Active__c = true, sked__Primary_Region__c = region.Id,
            sked_Dedicated_to_Site__c = drive.sked_Drive_Site__c
        );
        insert equipment;

        Test.startTest();
        List<sked__Resource__c> available = skedAssetAvailabilityChecker.loadAvailableAssets(
            skedConstants.ASSET_TYPE_EQUIPMENT, drive.sked_Collection_Operation__c, drive.sked_Drive_Date__c,
            drive.sked_Drive_Site__c, drive.Id, DateTime.now(), DateTime.now().addHours(8), new Set<Id>());
        Test.stopTest();

        Boolean found = false;
        for (sked__Resource__c resource : available) {
            if (resource.Id == equipment.Id) {
                found = true;
            }
        }
        System.assert(found, 'Equipment dedicated to this drive\'s own site must still be available');
    }
}
