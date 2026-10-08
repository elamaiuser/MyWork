@isTest
private class skedSameDayLinkedDriveCollapser_Test {

    @isTest
    static void testCollapseSameDayLinkedDrives_noLinkedDrive_passesThroughUnchanged() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Staff_Setup__c = 5);
        insert shift;

        List<sked_Drive__c> sameDateDrives = new List<sked_Drive__c>{ requeryDrive(drive.Id) };

        Test.startTest();
        List<skedSameDayLinkedDriveCollapser.CollapsedDrive> result = skedSameDayLinkedDriveCollapser.collapseSameDayLinkedDrives(sameDateDrives);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'A non-linked drive must pass through as its own entry');
        System.assertEquals(5, result[0].totalStaffRequested, 'A non-linked drive\'s staff total must be untouched');
    }

    @isTest
    static void testCollapseSameDayLinkedDrives_linkedPairSameTimeBlock_collapsesToMaxStaffSetup() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c driveA = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c driveB = (sked_Drive__c) testData.get('testDrive2');

        Time_Block__c timeBlock = new Time_Block__c(
            Name = 'Collapser Test Block Shared',
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            Start_Time__c = Time.newInstance(7, 0, 0, 0), End_Time__c = Time.newInstance(17, 0, 0, 0)
        );
        insert timeBlock;

        sked_Linked_Drives__c link = new sked_Linked_Drives__c(sked_Linked_Drive_Type__c = skedConstants.LINKED_DRIVE_TYPE_SINGLE);
        insert link;
        driveA.sked_Linked_Drives__c = link.Id;
        driveB.sked_Linked_Drives__c = link.Id;
        update new List<sked_Drive__c>{ driveA, driveB };

        insert new List<sked_Drive_Shift__c>{
            new sked_Drive_Shift__c(sked_Drive__c = driveA.Id, sked_Time_Block__c = timeBlock.Id, sked_Staff_Setup__c = 3),
            new sked_Drive_Shift__c(sked_Drive__c = driveB.Id, sked_Time_Block__c = timeBlock.Id, sked_Staff_Setup__c = 5)
        };

        List<sked_Drive__c> sameDateDrives = new List<sked_Drive__c>{ requeryDrive(driveA.Id), requeryDrive(driveB.Id) };

        Test.startTest();
        List<skedSameDayLinkedDriveCollapser.CollapsedDrive> result = skedSameDayLinkedDriveCollapser.collapseSameDayLinkedDrives(sameDateDrives);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'A same-day linked pair must collapse into a single entry');
        System.assertEquals(1, result[0].driveShifts.size(), 'The collapsed entry keeps one shift for a time block shared by both drives');
        System.assertEquals(5, result[0].driveShifts[0].staffSetup, 'The collapsed shift keeps the max staffSetup across the pair, not the sum');
    }

    @isTest
    static void testCollapseSameDayLinkedDrives_linkedPairDifferentTimeBlocks_collapsesToEarliestBlockWithMaxTotalStaff() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c driveA = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c driveB = (sked_Drive__c) testData.get('testDrive2');

        Time_Block__c earlierBlock = new Time_Block__c(
            Name = 'Collapser Test Block Earlier',
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            Start_Time__c = Time.newInstance(6, 0, 0, 0), End_Time__c = Time.newInstance(10, 0, 0, 0)
        );
        Time_Block__c laterBlock = new Time_Block__c(
            Name = 'Collapser Test Block Later',
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            Start_Time__c = Time.newInstance(12, 0, 0, 0), End_Time__c = Time.newInstance(16, 0, 0, 0)
        );
        insert new List<Time_Block__c>{ earlierBlock, laterBlock };

        sked_Linked_Drives__c link = new sked_Linked_Drives__c(sked_Linked_Drive_Type__c = skedConstants.LINKED_DRIVE_TYPE_SINGLE);
        insert link;
        driveA.sked_Linked_Drives__c = link.Id;
        driveB.sked_Linked_Drives__c = link.Id;
        update new List<sked_Drive__c>{ driveA, driveB };

        // driveA's only shift is in the LATER block with staffSetup 10; driveB's is in the EARLIER
        // block with staffSetup 14 - the collapsed entry must keep only the earlier block, with
        // staffSetup = max(driveA.totalStaffRequested, driveB.totalStaffRequested) = 14, not 10.
        insert new List<sked_Drive_Shift__c>{
            new sked_Drive_Shift__c(sked_Drive__c = driveA.Id, sked_Time_Block__c = laterBlock.Id, sked_Staff_Setup__c = 10),
            new sked_Drive_Shift__c(sked_Drive__c = driveB.Id, sked_Time_Block__c = earlierBlock.Id, sked_Staff_Setup__c = 14)
        };

        List<sked_Drive__c> sameDateDrives = new List<sked_Drive__c>{ requeryDrive(driveA.Id), requeryDrive(driveB.Id) };

        Test.startTest();
        List<skedSameDayLinkedDriveCollapser.CollapsedDrive> result = skedSameDayLinkedDriveCollapser.collapseSameDayLinkedDrives(sameDateDrives);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'A same-day linked pair spanning two time blocks must still collapse into a single entry');
        System.assertEquals(1, result[0].driveShifts.size(), 'The collapsed entry keeps only the earliest time block');
        System.assertEquals(earlierBlock.Id, result[0].driveShifts[0].timeBlockId, 'The earliest time block by start time must be the one kept');
        System.assertEquals(14, result[0].driveShifts[0].staffSetup, 'staffSetup must be max(totalStaffRequested) across the pair');
    }

    @isTest
    static void testCollapseSameDayLinkedActivities_nonLinkedActivity_passesThroughUnchanged() {
        sked__Activity__c activity = new sked__Activity__c(
            sked__Type__c = 'Administration',
            sked__Start__c = DateTime.now(),
            sked__End__c = DateTime.now().addHours(1),
            sked_Fixed_Site_Staff_Quantity__c = 3,
            sked_Mobile_Staff_Quantity__c = 4
        );
        // Bypass triggers, matching skedTestDataFactory's own convention for Activity inserts -
        // skedActivityTrigger's exception-log capture needs context this bare test record doesn't have.
        skedHubBase.setBypassAllTriggers(true);
        insert activity;
        skedHubBase.setBypassAllTriggers(false);

        Test.startTest();
        List<skedSameDayLinkedDriveCollapser.CollapsedActivity> result =
            skedSameDayLinkedDriveCollapser.collapseSameDayLinkedActivities(new List<sked__Activity__c>{ requeryActivity(activity.Id) });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'A non-linked activity must pass through as its own entry');
        System.assertEquals(3, result[0].fixedSiteStaffQuantity, 'A non-linked activity\'s quantities must be untouched');
        System.assertEquals(4, result[0].mobileStaffQuantity, 'A non-linked activity\'s quantities must be untouched');
    }

    @isTest
    static void testCollapseSameDayLinkedActivities_linkedGroupOfTwo_maxesBothQuantitiesAndDropsSecondMember() {
        sked_Linked_Drives__c link = new sked_Linked_Drives__c(sked_Linked_Drive_Type__c = skedConstants.LINKED_DRIVE_TYPE_SINGLE);
        insert link;

        sked__Activity__c activityA = new sked__Activity__c(
            sked__Type__c = 'Administration', sked__Start__c = DateTime.now(), sked__End__c = DateTime.now().addHours(1),
            sked_Linked_Drives__c = link.Id, sked_Fixed_Site_Staff_Quantity__c = 3, sked_Mobile_Staff_Quantity__c = 10
        );
        sked__Activity__c activityB = new sked__Activity__c(
            sked__Type__c = 'Administration', sked__Start__c = DateTime.now(), sked__End__c = DateTime.now().addHours(1),
            sked_Linked_Drives__c = link.Id, sked_Fixed_Site_Staff_Quantity__c = 7, sked_Mobile_Staff_Quantity__c = 4
        );
        skedHubBase.setBypassAllTriggers(true);
        insert new List<sked__Activity__c>{ activityA, activityB };
        skedHubBase.setBypassAllTriggers(false);

        List<sked__Activity__c> sameDateActivities = new List<sked__Activity__c>{
            requeryActivity(activityA.Id), requeryActivity(activityB.Id)
        };

        Test.startTest();
        List<skedSameDayLinkedDriveCollapser.CollapsedActivity> result = skedSameDayLinkedDriveCollapser.collapseSameDayLinkedActivities(sameDateActivities);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Only the first member of a linked activity group produces a collapsed entry');
        System.assertEquals(7, result[0].fixedSiteStaffQuantity, 'fixedSiteStaffQuantity must be maxed across the whole group');
        System.assertEquals(10, result[0].mobileStaffQuantity, 'mobileStaffQuantity must be maxed across the whole group');
    }

    private static sked_Drive__c requeryDrive(Id driveId) {
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

    private static sked__Activity__c requeryActivity(Id activityId) {
        return [
            SELECT Id, sked_Time_Block__c, sked_Fixed_Site_Staff_Quantity__c, sked_Mobile_Staff_Quantity__c,
                sked_Linked_Drives__c, sked_Linked_Drives__r.sked_Linked_Drive_Type__c
            FROM sked__Activity__c
            WHERE Id = :activityId
        ];
    }
}
