@isTest
private class skedMobileJobTagLoader_Test {

    private static Id queryAnyRegionId() {
        return [SELECT Id FROM sked__Region__c LIMIT 1].Id;
    }

    // skedJobHandler.populateJobTags (an existing, unrelated after-insert trigger) auto-creates
    // Resource Role / Drive Type job tags on every Job insert - delete those here so tests can
    // reason about an isolated, known tag set instead of whatever that automation happened to add.
    private static sked__Job__c insertJob(Id driveShiftId, Id regionId) {
        sked__Job__c job = new sked__Job__c(sked_Drive_Shift__c = driveShiftId, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60);
        insert job;
        delete [SELECT Id FROM sked__Job_Tag__c WHERE sked__Job__c = :job.Id];
        return job;
    }

    @isTest
    static void testLoadForJobs_emptyJobIdList_returnsEmptyMap() {
        Map<Id, List<sked__Job_Tag__c>> result = skedMobileJobTagLoader.loadForJobs(new List<Id>());

        System.assertEquals(0, result.size(), 'An empty jobIds list must return an empty map, not perform a WHERE-IN-nothing query');
    }

    @isTest
    static void testLoadForJobs_jobWithNoTags_returnsNoEntryForThatJob() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Id regionId = queryAnyRegionId();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c job = insertJob(shift.Id, regionId);

        Map<Id, List<sked__Job_Tag__c>> result = skedMobileJobTagLoader.loadForJobs(new List<Id>{ job.Id });

        System.assertEquals(false, result.containsKey(job.Id), 'A job with zero tags must not appear as a key in the result map');
    }

    @isTest
    static void testLoadForJobs_jobWithTag_isGroupedUnderItsJobId() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Id regionId = queryAnyRegionId();
        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c job = insertJob(shift.Id, regionId);
        sked__Tag__c tag = new sked__Tag__c(Name = 'Test Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION);
        insert tag;
        insert new sked__Job_Tag__c(sked__Job__c = job.Id, sked__Tag__c = tag.Id, sked_SystemCreated__c = true);

        Map<Id, List<sked__Job_Tag__c>> result = skedMobileJobTagLoader.loadForJobs(new List<Id>{ job.Id });

        System.assertEquals(1, result.get(job.Id).size(), 'The job must be grouped with exactly its one tag');
        System.assertEquals(tag.Id, result.get(job.Id)[0].sked__Tag__c, 'The grouped tag must be the one inserted for this job');
    }
}
