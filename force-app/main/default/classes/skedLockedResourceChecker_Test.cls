@isTest
private class skedLockedResourceChecker_Test {

    private class TestFixture {
        skedDriveRegenContext ctx;
        sked_Drive__c drive;
        sked_Drive__c otherDrive; // testDrive2, from the SAME factory.setupDriveData() call - never
                                  // re-invoke the factory, see setupCommonTestData()'s own DUPLICATE_VALUE pitfall.
        Id shiftId;
        sked__Job__c job;
        sked__Job_Allocation__c allocation;
        sked__Resource__c resource;
    }

    // Every rule passes by construction: active resource, primary region matches the drive's CO,
    // no required tags, no blacklist scores, no travel-time/turnaround/weekly-work-days limits
    // configured, no conflicting allocation elsewhere. Each test mutates exactly one thing to break
    // exactly one rule.
    private static TestFixture buildPassingFixture() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> testData = factory.setupCommonTestData();
        testData.putAll(factory.setupDriveData());
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c testDrive2 = (sked_Drive__c) testData.get('testDrive2');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');
        testDrive1.sked_Drive_Date__c = Date.today().addDays(30);
        update testDrive1;

        TestFixture fixture = new TestFixture();
        fixture.drive = [
            SELECT Id, sked_Collection_Operation__c, sked_Account__c, sked_Drive_Site__c, sked_Drive_Date__c, sked_Timezone__c
            FROM sked_Drive__c WHERE Id = :testDrive1.Id
        ];
        fixture.otherDrive = testDrive2;

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = fixture.drive.Id);
        insert shift;
        fixture.shiftId = shift.Id;

        DateTime jobStart = DateTime.now();
        sked__Job__c job = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'Driver',
            sked__Region__c = region.Id, sked__Duration__c = 60,
            sked__Start__c = jobStart, sked__Finish__c = jobStart.addHours(1)
        );
        insert job;
        fixture.job = requeryJob(job.Id);

        sked__Resource__c resource = new sked__Resource__c(
            Name = 'Locked Driver', sked__Primary_Region__c = region.Id,
            sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_ACTIVE
        );
        insert resource;
        fixture.resource = resource;

        // The 'Driver' role job-tag requirement is auto-populated by trigger automation on the job
        // (see reference_vehicle_dot_cdl_driver_tags memory) - give the resource a matching tag for
        // each one actually required, discovered from the job's own (already-populated) JobTags,
        // rather than assuming no tags are required.
        List<sked__Resource_Tag__c> resourceTags = new List<sked__Resource_Tag__c>();
        for (sked__Job_Tag__c jobTag : fixture.job.sked__JobTags__r) {
            resourceTags.add(new sked__Resource_Tag__c(
                sked__Resource__c = resource.Id, sked__Tag__c = jobTag.sked__Tag__c, sked_Start_Date__c = Date.today().addDays(-1)));
        }
        if (!resourceTags.isEmpty()) {
            insert resourceTags;
        }

        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(
            sked__Job__c = job.Id, sked__Resource__c = resource.Id, sked_Locked__c = true
        );
        insert allocation;
        fixture.allocation = [
            SELECT Id, sked__Job__c, sked__Resource__c, sked__Status__c, sked_Is_Locked__c,
                sked_Geoservice_Travel_Time_To__c, sked_Geoservice_Travel_Time_Back__c
            FROM sked__Job_Allocation__c WHERE Id = :allocation.Id
        ];

        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = fixture.drive;
        ctx.jobsByShiftId.put(shift.Id, new List<sked__Job__c>{ fixture.job });
        ctx.allocationsByJobId.put(job.Id, new List<sked__Job_Allocation__c>{ fixture.allocation });
        fixture.ctx = ctx;

        return fixture;
    }

    private static sked__Job__c requeryJob(Id jobId) {
        return [
            SELECT Id, sked_Resource_Role__c, sked_Dual_Role__c, sked_Asset_Type__c, sked__Duration__c, sked__Start__c, sked__Finish__c,
                (SELECT Id, sked__Tag__c FROM sked__JobTags__r)
            FROM sked__Job__c
            WHERE Id = :jobId
        ];
    }

    private static List<skedLockedResourceChecker.LockedAllocation> collectLocked(TestFixture fixture) {
        return skedLockedResourceChecker.collectLockedStaffAllocations(fixture.ctx);
    }

    @isTest
    static void testHasUnavailableLockedResource_allRulesPass_returnsFalse() {
        TestFixture fixture = buildPassingFixture();
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        List<String> violatedRules = skedLockedResourceChecker.findViolatedRules(fixture.ctx, locked);
        Test.stopTest();

        System.assert(violatedRules.isEmpty(), 'A locked staff allocation passing every eligibility rule must not be flagged unavailable: ' + violatedRules);
    }

    @isTest
    static void testHasUnavailableLockedResource_noLockedAllocations_returnsFalse() {
        TestFixture fixture = buildPassingFixture();
        fixture.allocation.sked_Locked__c = false;
        update fixture.allocation;
        // sked_Is_Locked__c is a formula (Locked||Guarded) - requery so ctx reflects the real value.
        fixture.allocation = [SELECT Id, sked__Resource__c, sked_Is_Locked__c, sked__Status__c FROM sked__Job_Allocation__c WHERE Id = :fixture.allocation.Id];
        fixture.ctx.allocationsByJobId.put(fixture.job.Id, new List<sked__Job_Allocation__c>{ fixture.allocation });
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assertEquals(0, locked.size(), 'An unlocked allocation must never be collected as a candidate');
        System.assert(!result, 'No locked allocations means nothing can be flagged unavailable');
    }

    @isTest
    static void testCollectLockedStaffAllocations_nonRoleJob_excluded() {
        TestFixture fixture = buildPassingFixture();
        fixture.job.sked_Resource_Role__c = null;
        // sked_Resource_Role__c is on the cached job reference already stored in ctx - no requery needed.
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        System.assertEquals(0, locked.size(), 'A job with no resourceRole (e.g. an asset job) must never be collected, even if its allocation is Locked');
    }

    // A resource-reassignment step (e.g. skedMobileAssetReassigner) can mark an allocation Deleted
    // in memory, on this same ctx instance, after load - a stale Deleted-but-Locked allocation must
    // not still surface as a candidate.
    @isTest
    static void testCollectLockedStaffAllocations_deletedAllocation_excluded() {
        TestFixture fixture = buildPassingFixture();
        fixture.allocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
        fixture.ctx.allocationsByJobId.put(fixture.job.Id, new List<sked__Job_Allocation__c>{ fixture.allocation });

        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        System.assertEquals(0, locked.size(), 'A Deleted allocation must never be collected as a candidate, even if it is still Locked');
    }

    // LOCKED_RESOURCE_UNAVAILABLE covers locked Vehicle/Equipment allocations too, not just staff -
    // reuses skedAssetAvailabilityChecker's own candidate-pool-membership check (same pattern as
    // skedAssetAvailabilityChecker_Test's dedicated-to-different-site test) rather than a new rule set.
    @isTest
    static void testHasUnavailableLockedAsset_dedicatedToDifferentSite_returnsTrue() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        Map<String, sObject> testData = factory.setupCommonTestData();
        testData.putAll(factory.setupDriveData());
        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive__c testDrive2 = (sked_Drive__c) testData.get('testDrive2');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        sked_Drive__c drive = [SELECT Id, sked_Collection_Operation__c, sked_Drive_Site__c, sked_Drive_Date__c FROM sked_Drive__c WHERE Id = :testDrive1.Id];
        System.assertNotEquals(drive.sked_Drive_Site__c, testDrive2.sked_Drive_Site__c, 'Test setup must use two different drive sites');

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;

        DateTime jobStart = DateTime.now();
        sked__Job__c equipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Region__c = region.Id, sked__Duration__c = 60,
            sked__Start__c = jobStart, sked__Finish__c = jobStart.addHours(1)
        );
        insert equipmentJob;

        sked__Resource__c equipment = new sked__Resource__c(
            Name = 'Dedicated Locked Equipment', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Is_Active__c = true, sked__Primary_Region__c = region.Id,
            sked_Dedicated_to_Site__c = testDrive2.sked_Drive_Site__c
        );
        insert equipment;

        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(
            sked__Job__c = equipmentJob.Id, sked__Resource__c = equipment.Id, sked_Locked__c = true
        );
        insert allocation;
        sked__Job_Allocation__c requeriedAllocation = [
            SELECT Id, sked__Job__c, sked__Resource__c, sked__Status__c, sked_Is_Locked__c FROM sked__Job_Allocation__c WHERE Id = :allocation.Id
        ];

        skedDriveRegenContext ctx = new skedDriveRegenContext();
        ctx.drive = drive;
        ctx.jobsByShiftId.put(shift.Id, new List<sked__Job__c>{ requeryJob(equipmentJob.Id) });
        ctx.allocationsByJobId.put(equipmentJob.Id, new List<sked__Job_Allocation__c>{ requeriedAllocation });

        Test.startTest();
        List<skedLockedResourceChecker.LockedAllocation> lockedAssets = skedLockedResourceChecker.collectLockedAssetAllocations(ctx);
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedAsset(ctx, lockedAssets);
        Test.stopTest();

        System.assertEquals(1, lockedAssets.size(), 'The locked equipment allocation must be collected');
        System.assert(result, 'A locked Equipment resource dedicated to a different site must be flagged unavailable');
    }

    @isTest
    static void testHasUnavailableLockedAsset_noLockedAssetAllocations_returnsFalse() {
        TestFixture fixture = buildPassingFixture();
        List<skedLockedResourceChecker.LockedAllocation> lockedAssets = skedLockedResourceChecker.collectLockedAssetAllocations(fixture.ctx);

        Boolean result = skedLockedResourceChecker.hasUnavailableLockedAsset(fixture.ctx, lockedAssets);

        System.assertEquals(0, lockedAssets.size(), 'The passing fixture only has a staff job, no asset job to collect');
        System.assert(!result, 'No locked asset allocations means nothing can be flagged unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_resourceInactive_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        fixture.resource.sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE;
        update fixture.resource;
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'An Inactive locked resource must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_resourcePendingTermination_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        fixture.resource.sked_Termination_Date__c = fixture.drive.sked_Drive_Date__c.addDays(-1);
        update fixture.resource;
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A resource whose termination date has already passed the drive date must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_resourceOnLeaveNotYetReturned_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        fixture.resource.sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE;
        fixture.resource.sked_Anticipated_Leave_Return_Date__c = fixture.drive.sked_Drive_Date__c.addDays(5);
        update fixture.resource;
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A resource on Leave whose anticipated return date is after the drive date must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_notBelongToCollectionOp_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        Biomed_Collection_Op_Center__c otherCo = new Biomed_Collection_Op_Center__c(
            Name = 'Other CO', sked_Lunch_Break_Duration_Fixed_Site__c = '30', sked_Lunch_Break_Duration_Mobile__c = '30');
        insert otherCo;
        sked__Region__c otherRegion = new sked__Region__c(
            Name = 'Other Region', sked_Biomed_Collection_Op_Center__c = otherCo.Id, sked__Timezone__c = UserInfo.getTimeZone().getID());
        insert otherRegion;
        fixture.resource.sked__Primary_Region__c = otherRegion.Id;
        update fixture.resource;
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A resource whose primary region belongs to a different Collection Operation, with no override, must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_missingRequiredTag_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        sked__Tag__c requiredTag = new sked__Tag__c(Name = 'Required Cert', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION);
        insert requiredTag;
        insert new sked__Job_Tag__c(sked__Job__c = fixture.job.Id, sked__Tag__c = requiredTag.Id);
        // The job's sked__JobTags__r subquery was snapshotted before this tag existed - requery and
        // replace the cached ctx reference so the checker sees the new required tag.
        fixture.job = requeryJob(fixture.job.Id);
        fixture.ctx.jobsByShiftId.put(fixture.shiftId, new List<sked__Job__c>{ fixture.job });
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A resource missing a tag the job requires must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_accountBlacklisted_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        insert new sked__Account_Resource_Score__c(
            sked__Account__c = fixture.drive.sked_Account__c, sked__Resource__c = fixture.resource.Id, sked__Blacklisted__c = true,
            sked_Account_Resource_Relationship__c = skedConstants.ACCCOUNT_RESOURCE_SCORE_DECLINED);
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A resource blacklisted against the drive\'s Account must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_locationBlacklisted_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        insert new sked__Location_Resource_Score__c(
            sked__Location__c = fixture.drive.sked_Drive_Site__c, sked__Resource__c = fixture.resource.Id, sked__Blacklisted__c = true,
            sked_Location_Resource_Relationship__c = skedConstants.LOCATION_RESOURCE_SCORE_DECLINED);
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A resource blacklisted against the drive\'s Site must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_maxTravelTimeExceeded_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        fixture.resource.sked_Max_Travel_Time__c = 30;
        update fixture.resource;
        fixture.allocation.sked_Geoservice_Travel_Time_To__c = 60;
        fixture.allocation.sked_Geoservice_Travel_Time_Back__c = 20;
        update fixture.allocation;
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A travel time exceeding the resource\'s max must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_cdlDotMaxDurationExceeded_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        // 'Driver' is in the 'Driving roles' group (skedTestDataFactory) - default max is 14hrs =
        // 840min. Finish must be extended alongside Duration - a validation rule requires them to match.
        fixture.job.sked__Duration__c = 900;
        fixture.job.sked__Finish__c = fixture.job.sked__Start__c.addMinutes(900);
        update fixture.job;
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A Driving-role job exceeding the max CDL/DOT shift duration must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_maxWeeklyWorkDaysExceeded_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        fixture.resource.sked_Max_Working_Days_Per_Week__c = '5';
        update fixture.resource;
        Date startOfWeek = skedDateTimeUtils.findWeekStartDate(fixture.drive.sked_Drive_Date__c, 'Sunday');
        Date endOfWeek = startOfWeek.addDays(6);
        insert new sked_Resource_Hours_Record__c(
            sked_Resource__c = fixture.resource.Id, sked_Start_Date__c = startOfWeek, sked_End_Date__c = endOfWeek,
            sked_Unique_Key__c = skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(fixture.resource.Id, startOfWeek, endOfWeek),
            sked_Total_Working_Days__c = 6
        );
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A resource whose already-worked days this week exceed its max must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_turnaroundTimeViolated_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        fixture.resource.sked_Turnaround_Time__c = 4;
        update fixture.resource;

        // Bypass triggers purely to stay under the SOQL governor limit - this insert's own side
        // effects aren't under test (see the identical note in the conflictedElsewhere test). The
        // "job is the time source" validation rule is declarative, not trigger-based, so it still
        // applies regardless - time is set on the job, not the allocation, same as that test.
        skedHubBase.setBypassAllTriggers(true);
        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = fixture.drive.Id);
        insert otherShift;
        Id anyRegionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        // Non-overlapping with the evaluated job [now, now+1h], but inside the 4-hour turnaround window.
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive_Shift__c = otherShift.Id, sked_Resource_Role__c = 'Driver', sked__Region__c = anyRegionId, sked__Duration__c = 60,
            sked__Start__c = fixture.job.sked__Finish__c.addHours(1), sked__Finish__c = fixture.job.sked__Finish__c.addHours(2)
        );
        insert otherJob;
        insert new sked__Job_Allocation__c(sked__Job__c = otherJob.Id, sked__Resource__c = fixture.resource.Id);
        skedHubBase.setBypassAllTriggers(false);
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A neighboring allocation inside the resource\'s turnaround window must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_conflictedElsewhere_returnsTrue() {
        TestFixture fixture = buildPassingFixture();

        // fixture.otherDrive (testDrive2) is Fixed Site by default - its automation is heavier than
        // the Mobile-drive path exercised elsewhere in this file, so bypass triggers here purely to
        // stay under the SOQL governor limit; this insert's own side effects aren't under test.
        skedHubBase.setBypassAllTriggers(true);
        sked_Drive_Shift__c otherShift = new sked_Drive_Shift__c(sked_Drive__c = fixture.otherDrive.Id);
        insert otherShift;
        Id anyRegionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        // The job (not the allocation) is the time source - a validation rule blocks setting
        // sked__Start__c/sked__Set_End__c directly on the allocation, so overlap is set here instead
        // and the allocation inherits it. Overlaps the evaluated job's own window [now, now+1h] directly.
        sked__Job__c otherJob = new sked__Job__c(
            sked_Drive_Shift__c = otherShift.Id, sked_Resource_Role__c = 'Driver', sked__Region__c = anyRegionId, sked__Duration__c = 60,
            sked__Start__c = fixture.job.sked__Start__c.addMinutes(30), sked__Finish__c = fixture.job.sked__Finish__c.addMinutes(30)
        );
        insert otherJob;
        insert new sked__Job_Allocation__c(sked__Job__c = otherJob.Id, sked__Resource__c = fixture.resource.Id);
        skedHubBase.setBypassAllTriggers(false);
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A resource double-booked on another drive during the same window must flag as unavailable');
    }

    // buildPassingFixture() leaves sked__Resource_Type__c unset (null), which skips this rule
    // entirely (see skedLockedResourceChecker.isWorkingTimeConflict) - so unlike the other rules,
    // this one needs Person type (and every other Person-required field the org enforces) set
    // explicitly in each of its own tests rather than being exercised for free by the shared
    // "all rules pass" baseline.
    private static void makeResourcePerson(TestFixture fixture) {
        fixture.resource.sked__Resource_Type__c = skedConstants.RESOURCE_TYPE_PERSON;
        fixture.resource.sked_Employee_ID__c = 'EMP-' + fixture.resource.Id;
        fixture.resource.sked_First_Name__c = 'Test';
        fixture.resource.sked_Last_Name__c = 'Driver';
        fixture.resource.sked_ULID__c = 'ULID-' + fixture.resource.Id;
        fixture.resource.sked_Daily_Time_Off_Hours__c = 1;
        fixture.resource.sked_Max_Hours_Per_Week__c = 40;
        fixture.resource.sked_Min_Hours_Per_Week__c = 0;
        fixture.resource.sked_Turnaround_Time__c = 0;
        update fixture.resource;
    }

    @isTest
    static void testHasUnavailableLockedResource_workingTimeConflictNoAvailability_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        makeResourcePerson(fixture);
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'A Person resource with no availability window covering the job\'s time must flag as unavailable');
    }

    @isTest
    static void testHasUnavailableLockedResource_workingTimeConflictFullyCovered_returnsFalse() {
        TestFixture fixture = buildPassingFixture();
        makeResourcePerson(fixture);
        insert new sked__Availability__c(
            sked__Resource__c = fixture.resource.Id, sked__Is_Available__c = true, sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked__Start__c = fixture.job.sked__Start__c.addHours(-1), sked__Finish__c = fixture.job.sked__Finish__c.addHours(1)
        );
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(!result, 'A Person resource with an approved availability window fully covering the job\'s time must not flag as unavailable');
    }

    // Discriminates a correct interval merge from a broken one - two windows that each cover part
    // of the job but leave a real gap between them must still flag, not just "some availability exists."
    @isTest
    static void testHasUnavailableLockedResource_workingTimeConflictGapBetweenWindows_returnsTrue() {
        TestFixture fixture = buildPassingFixture();
        makeResourcePerson(fixture);
        DateTime jobStart = fixture.job.sked__Start__c;
        DateTime jobFinish = fixture.job.sked__Finish__c;
        insert new List<sked__Availability__c>{
            new sked__Availability__c(
                sked__Resource__c = fixture.resource.Id, sked__Is_Available__c = true, sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
                sked__Start__c = jobStart.addMinutes(-30), sked__Finish__c = jobStart.addMinutes(15)),
            new sked__Availability__c(
                sked__Resource__c = fixture.resource.Id, sked__Is_Available__c = true, sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
                sked__Start__c = jobFinish.addMinutes(-15), sked__Finish__c = jobFinish.addMinutes(30))
        };
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(result, 'Two availability windows leaving a real gap in the middle of the job must still flag as unavailable, not just any coverage existing');
    }

    // The adjacent-boundary case: two windows meeting exactly at one instant with no gap must be
    // treated as fully covered - proves the merge's boundary comparisons aren't off-by-one.
    @isTest
    static void testHasUnavailableLockedResource_workingTimeConflictAdjacentWindows_returnsFalse() {
        TestFixture fixture = buildPassingFixture();
        makeResourcePerson(fixture);
        DateTime jobStart = fixture.job.sked__Start__c;
        DateTime jobFinish = fixture.job.sked__Finish__c;
        DateTime midpoint = jobStart.addMinutes(30);
        insert new List<sked__Availability__c>{
            new sked__Availability__c(
                sked__Resource__c = fixture.resource.Id, sked__Is_Available__c = true, sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
                sked__Start__c = jobStart.addMinutes(-15), sked__Finish__c = midpoint),
            new sked__Availability__c(
                sked__Resource__c = fixture.resource.Id, sked__Is_Available__c = true, sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
                sked__Start__c = midpoint, sked__Finish__c = jobFinish.addMinutes(15))
        };
        List<skedLockedResourceChecker.LockedAllocation> locked = collectLocked(fixture);

        Test.startTest();
        Boolean result = skedLockedResourceChecker.hasUnavailableLockedResource(fixture.ctx, locked);
        Test.stopTest();

        System.assert(!result, 'Two availability windows meeting exactly with no gap must be treated as fully covering the job');
    }
}
