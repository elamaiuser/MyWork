@isTest
private class skedMobileJobAllocationLoader_Test {

    private static Id queryAnyRegionId() {
        return [SELECT Id FROM sked__Region__c LIMIT 1].Id;
    }

    private static sked__Job__c insertJob(Id driveShiftId, Id regionId) {
        sked__Job__c job = new sked__Job__c(sked_Drive_Shift__c = driveShiftId, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60);
        insert job;
        return job;
    }

    @isTest
    static void testLoadForJobs_emptyJobIdList_returnsEmptyMap() {
        Map<Id, List<sked__Job_Allocation__c>> result = skedMobileJobAllocationLoader.loadForJobs(new List<Id>());

        System.assertEquals(0, result.size(), 'An empty jobIds list must return an empty map, not perform a WHERE-IN-nothing query');
    }

    @isTest
    static void testLoadForJobs_jobWithNoAllocations_returnsNoEntryForThatJob() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Id regionId = queryAnyRegionId();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c job = insertJob(shift.Id, regionId);

        Map<Id, List<sked__Job_Allocation__c>> result = skedMobileJobAllocationLoader.loadForJobs(new List<Id>{ job.Id });

        System.assertEquals(false, result.containsKey(job.Id), 'A job with zero allocations must not appear as a key in the result map');
        System.assertEquals(false, skedMobileJobAllocationLoader.hasAnyAllocation(result, job.Id), 'hasAnyAllocation must be false for a job with no allocations');
    }

    @isTest
    static void testLoadForJobs_jobWithActiveAllocation_isGroupedUnderItsJobId() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Resource__c resource = (sked__Resource__c) testData.get('testResource1');
        Id regionId = queryAnyRegionId();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c job = insertJob(shift.Id, regionId);
        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(sked__Job__c = job.Id, sked__Resource__c = resource.Id, sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED);
        insert allocation;

        Map<Id, List<sked__Job_Allocation__c>> result = skedMobileJobAllocationLoader.loadForJobs(new List<Id>{ job.Id });

        System.assertEquals(1, result.get(job.Id).size(), 'The job must be grouped with exactly its one active allocation');
        System.assertEquals(true, skedMobileJobAllocationLoader.hasAnyAllocation(result, job.Id), 'hasAnyAllocation must be true when an active allocation exists');
    }

    @isTest
    static void testLoadForJobs_deletedAllocation_isExcluded() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Resource__c resource = (sked__Resource__c) testData.get('testResource1');
        Id regionId = queryAnyRegionId();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c job = insertJob(shift.Id, regionId);
        sked__Job_Allocation__c deletedAllocation = new sked__Job_Allocation__c(sked__Job__c = job.Id, sked__Resource__c = resource.Id, sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED);
        insert deletedAllocation;

        Map<Id, List<sked__Job_Allocation__c>> result = skedMobileJobAllocationLoader.loadForJobs(new List<Id>{ job.Id });

        System.assertEquals(false, skedMobileJobAllocationLoader.hasAnyAllocation(result, job.Id), 'A Deleted-status allocation must not count as an active allocation');
    }

    @isTest
    static void testHasAnyAllocation_nullJobId_returnsFalse() {
        Boolean result = skedMobileJobAllocationLoader.hasAnyAllocation(new Map<Id, List<sked__Job_Allocation__c>>(), null);

        System.assertEquals(false, result, 'A null jobId (a not-yet-persisted proposed job) must never be treated as having an allocation');
    }
}
