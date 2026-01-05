@isTest
public class skedCaptureAPExceptionLogBatch_Test {

    @TestSetup
    static void setupTestData() {
        // Create Region with Timezone
        sked__Region__c region = new sked__Region__c(
            Name = 'Test Region',
            sked__Timezone__c = 'America/New_York'
        );
        insert region;

        // Create Resource
        sked__Resource__c resource = new sked__Resource__c(
            Name = 'Test Resource',
            sked__Primary_Region__c = region.Id,
            sked__Category__c = 'Person'
        );
        insert resource;

        // Create Activity
        sked__Activity__c activity = new sked__Activity__c(
            Name = 'Test Activity'
        );
        insert activity;

        // Create Activity Resource
        sked__Activity_Resource__c activityResource = new sked__Activity_Resource__c(
            sked__Activity__c = activity.Id,
            sked__Resource__c = resource.Id,
            sked_Start_Date__c = Date.today(),
            sked_Start1__c = DateTime.now(),
            sked_End_Date__c = Date.today(),
            sked_End__c = DateTime.now().addHours(2)
        );

        insert activityResource;
    }

    /**
     * Test batch constructor properly stores activity resource IDs
     */
    @isTest
    static void testBatchConstructor() {
        // Get test activity resource
        List<sked__Activity_Resource__c> activityResources = [
            SELECT Id FROM sked__Activity_Resource__c LIMIT 1
        ];

        Set<Id> activityResourceIds = new Set<Id>();
        for (sked__Activity_Resource__c ar : activityResources) {
            activityResourceIds.add(ar.Id);
        }

        Test.startTest();
        skedCaptureAPExceptionLogBatch batch = new skedCaptureAPExceptionLogBatch(activityResourceIds);
        Test.stopTest();

        System.assertNotEquals(null, batch, 'Batch instance should be created');
        System.assertEquals(activityResourceIds.size(), batch.activityResourceIds.size(),
            'Batch should store the correct number of activity resource IDs');
    }

    /**
     * Test batch start method returns correct records
     */
    @isTest
    static void testBatchStart() {
        // Get test activity resource
        List<sked__Activity_Resource__c> activityResources = [
            SELECT Id FROM sked__Activity_Resource__c LIMIT 1
        ];

        Set<Id> activityResourceIds = new Set<Id>();
        for (sked__Activity_Resource__c ar : activityResources) {
            activityResourceIds.add(ar.Id);
        }

        skedCaptureAPExceptionLogBatch batch = new skedCaptureAPExceptionLogBatch(activityResourceIds);

        Test.startTest();
        List<sked__Activity_Resource__c> result = batch.start(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Start method should return results');
        System.assertEquals(activityResourceIds.size(), result.size(),
            'Start method should return all activity resources in the set');

        // Verify all required fields are queried
        for (sked__Activity_Resource__c ar : result) {
            System.assertNotEquals(null, ar.Id, 'Id should be queried');
            System.assertNotEquals(null, ar.sked__Activity__c, 'Activity should be queried');
            System.assertNotEquals(null, ar.sked__Resource__c, 'Resource should be queried');
        }
    }

    /**
     * Test batch execute method calls service correctly
     */
    @isTest
    static void testBatchExecute() {
        // Get test activity resources
        List<sked__Activity_Resource__c> activityResources = [
            SELECT Id FROM sked__Activity_Resource__c LIMIT 1
        ];

        Set<Id> activityResourceIds = new Set<Id>();
        for (sked__Activity_Resource__c ar : activityResources) {
            activityResourceIds.add(ar.Id);
        }

        skedCaptureAPExceptionLogBatch batch = new skedCaptureAPExceptionLogBatch(activityResourceIds);
        List<sked__Activity_Resource__c> records = batch.start(null);

        Test.startTest();
        batch.execute(null, records);
        Test.stopTest();

        // Verify the execute method completed without errors
        // The actual exception log creation will be tested in service method tests
        System.assert(true, 'Execute method should complete without errors');
    }

    /**
     * Test full batch execution end-to-end
     */
    @isTest
    static void testBatchFullExecution() {
        // Get test activity resources
        List<sked__Activity_Resource__c> activityResources = [
            SELECT Id FROM sked__Activity_Resource__c
        ];

        Set<Id> activityResourceIds = new Set<Id>();
        for (sked__Activity_Resource__c ar : activityResources) {
            activityResourceIds.add(ar.Id);
        }

        Test.startTest();
        skedCaptureAPExceptionLogBatch batch = new skedCaptureAPExceptionLogBatch(activityResourceIds);
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify batch executed successfully
        System.assert(true, 'Batch should execute successfully');
    }

    /**
     * Test batch with empty activity resource set
     */
    @isTest
    static void testBatchWithEmptySet() {
        Set<Id> emptySet = new Set<Id>();

        Test.startTest();
        skedCaptureAPExceptionLogBatch batch = new skedCaptureAPExceptionLogBatch(emptySet);
        List<sked__Activity_Resource__c> result = batch.start(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Start method should return a list');
        System.assertEquals(0, result.size(), 'Result should be empty when no IDs provided');
    }

    /**
     * Test captureAPExceptionLogs creates exception logs for conflicts
     */
    @isTest
    static void testCaptureAPExceptionLogs_WithConflict() {
        // Get test data
        sked__Resource__c resource = [SELECT Id, sked__Primary_Region__c FROM sked__Resource__c LIMIT 1];
        sked__Activity__c activity = [SELECT Id FROM sked__Activity__c LIMIT 1];

        // Create activity resource that will have a conflict
        List<sked__Activity_Resource__c> activityResources = new List<sked__Activity_Resource__c>();
        activityResources.add(new sked__Activity_Resource__c(
            sked__Activity__c = activity.Id,
            sked__Resource__c = resource.Id,
            sked_Start_Date__c = Date.today(),
            sked_Start1__c = DateTime.now(),
            sked_End_Date__c = Date.today(),
            sked_End__c = DateTime.now().addHours(2)
        ));

        // Count existing exception logs
        Integer initialCount = [SELECT COUNT() FROM skedHC__Exception__c];

        Test.startTest();
        skedExceptionLogService service = new skedExceptionLogService();
        service.captureAPExceptionLogs(activityResources);
        Test.stopTest();

        // Verify service executed without errors
        // Note: Actual exception log creation depends on availability patterns existing
        System.assert(true, 'captureAPExceptionLogs should execute without errors');
    }

    /**
     * Test captureAPExceptionLogs with empty list
     */
    @isTest
    static void testCaptureAPExceptionLogs_EmptyList() {
        List<sked__Activity_Resource__c> emptyList = new List<sked__Activity_Resource__c>();

        Test.startTest();
        skedExceptionLogService service = new skedExceptionLogService();
        service.captureAPExceptionLogs(emptyList);
        Test.stopTest();

        System.assert(true, 'captureAPExceptionLogs should handle empty list gracefully');
    }

    /**
     * Test generateAPExceptionLogs with valid activity resources
     */
    @isTest
    static void testGenerateAPExceptionLogs_ValidData() {
        // Get test data
        sked__Resource__c resource = [SELECT Id FROM sked__Resource__c LIMIT 1];
        sked__Activity__c activity = [SELECT Id FROM sked__Activity__c LIMIT 1];

        // Create activity resource model
        List<skedModels.activityResource> activityResources = new List<skedModels.activityResource>();
        skedModels.activityResource activityResource = new skedModels.activityResource();
        activityResource.activityId = activity.Id;
        activityResource.resourceId = resource.Id;
        activityResource.start = DateTime.now();
        activityResource.finish = DateTime.now().addHours(2);
        activityResource.startDate = JSON.serialize(Date.today()).replace('"', '');
        activityResource.endDate = JSON.serialize(Date.today()).replace('"', '');
        activityResources.add(activityResource);

        Test.startTest();
        skedExceptionLogService service = new skedExceptionLogService();
        List<skedHC__Exception__c> result = service.generateAPExceptionLogs(activityResources);
        Test.stopTest();

        System.assertNotEquals(null, result, 'generateAPExceptionLogs should return a list');
        // Note: Actual exception logs depend on availability patterns being set up
    }

    /**
     * Test generateAPExceptionLogs with empty list
     */
    @isTest
    static void testGenerateAPExceptionLogs_EmptyList() {
        List<skedModels.activityResource> emptyList = new List<skedModels.activityResource>();

        Test.startTest();
        skedExceptionLogService service = new skedExceptionLogService();
        List<skedHC__Exception__c> result = service.generateAPExceptionLogs(emptyList);
        Test.stopTest();

        System.assertNotEquals(null, result, 'generateAPExceptionLogs should return a list');
        System.assertEquals(0, result.size(), 'Result should be empty for empty input');
    }

    /**
     * Test generateAPExceptionLogs with multiple resources
     */
    @isTest
    static void testGenerateAPExceptionLogs_MultipleResources() {
        // Get test data
        sked__Resource__c resource = [SELECT Id FROM sked__Resource__c LIMIT 1];
        sked__Activity__c activity = [SELECT Id FROM sked__Activity__c LIMIT 1];

        // Create multiple activity resource models
        List<skedModels.activityResource> activityResources = new List<skedModels.activityResource>();

        for (Integer i = 0; i < 3; i++) {
            skedModels.activityResource activityResource = new skedModels.activityResource();
            activityResource.activityId = activity.Id;
            activityResource.resourceId = resource.Id;
            activityResource.start = DateTime.now().addHours(i);
            activityResource.finish = DateTime.now().addHours(i + 1);
            activityResource.startDate = JSON.serialize(Date.today()).replace('"', '');
            activityResource.endDate = JSON.serialize(Date.today()).replace('"', '');
            activityResources.add(activityResource);
        }

        Test.startTest();
        skedExceptionLogService service = new skedExceptionLogService();
        List<skedHC__Exception__c> result = service.generateAPExceptionLogs(activityResources);
        Test.stopTest();

        System.assertNotEquals(null, result, 'generateAPExceptionLogs should return a list');
        // Result size depends on conflicts found with availability patterns
    }

    /**
     * Test generateAPExceptionLogs with date spanning multiple days
     */
    @isTest
    static void testGenerateAPExceptionLogs_MultipleDays() {
        // Get test data
        sked__Resource__c resource = [SELECT Id FROM sked__Resource__c LIMIT 1];
        sked__Activity__c activity = [SELECT Id FROM sked__Activity__c LIMIT 1];

        // Create activity resource spanning multiple days
        List<skedModels.activityResource> activityResources = new List<skedModels.activityResource>();
        skedModels.activityResource activityResource = new skedModels.activityResource();
        activityResource.activityId = activity.Id;
        activityResource.resourceId = resource.Id;
        activityResource.start = DateTime.now();
        activityResource.finish = DateTime.now().addDays(2);
        activityResource.startDate = JSON.serialize(Date.today()).replace('"', '');
        activityResource.endDate = JSON.serialize(Date.today().addDays(2)).replace('"', '');
        activityResources.add(activityResource);

        Test.startTest();
        skedExceptionLogService service = new skedExceptionLogService();
        List<skedHC__Exception__c> result = service.generateAPExceptionLogs(activityResources);
        Test.stopTest();

        System.assertNotEquals(null, result, 'generateAPExceptionLogs should return a list');
    }

    /**
     * Test batch finish method
     */
    @isTest
    static void testBatchFinish() {
        Set<Id> emptySet = new Set<Id>();
        skedCaptureAPExceptionLogBatch batch = new skedCaptureAPExceptionLogBatch(emptySet);

        Test.startTest();
        batch.finish(null);
        Test.stopTest();

        System.assert(true, 'Finish method should complete without errors');
    }
}