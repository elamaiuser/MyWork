@isTest
private class slwcOptimizationService_Test {

    static testmethod void testEvaluateOptimizationRun() {
        Test.setMock(HttpCalloutMock.class, new skedMockTest());

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Territory__c testTerritory1 = (sked_Territory__c) mapTestData.get('testTerritory1');
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        Test.startTest();

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;

        slwcOptimizationService.optimizationSettingModel setting = new slwcOptimizationService.optimizationSettingModel();
        setting.constraint = 'Account/Site Preferences';
        setting.constraintType = 'Soft Constraint';
        setting.driveType = 'Mobile';
        setting.defaultWeight = 'High';
        setting.enabled = true;

        List<string> driveIds = new List<string>();
        driveIds.add(testDrive.Id);

        slwcOptimizationService.initiateOptimizationRunRequestModel initiateOptimizationRunRequest = new slwcOptimizationService.initiateOptimizationRunRequestModel();
        initiateOptimizationRunRequest.driveIds = driveIds;
        initiateOptimizationRunRequest.startDate = testDataFactory.summary.startDate;
        initiateOptimizationRunRequest.endDate = testDataFactory.summary.endDate;
        initiateOptimizationRunRequest.optimizationSettings = new List<slwcOptimizationService.optimizationSettingModel> {setting};

        // Assert the return value
        slwcAuraResult initResult = slwcOptimizationService.initiateOptimizationRun(initiateOptimizationRunRequest);
        System.assertNotEquals(null, initResult, 'Result should not be null');

        // Verify Optimization Run was created correctly
        List<sked_Optimization_Run__c> optimizationRunQuery = [
            SELECT Id, sked_Status__c, sked_Collection_Operation__c, sked_Start_Date__c,
                   sked_End_Date__c, sked_Drive_Types__c, sked_Timezone__c, sked_UniqueKey__c
            FROM sked_Optimization_Run__c
        ];
        System.assertEquals(1, optimizationRunQuery.size(), 'Should create exactly one optimization run');

        sked_Optimization_Run__c optimizationRun = optimizationRunQuery[0];
        System.assertEquals(skedConstants.OPTIMIZATION_RUN_STATUS_PENDING, optimizationRun.sked_Status__c,
                           'Status should be Pending');
        System.assertEquals(testCollectionOperation1.Id, optimizationRun.sked_Collection_Operation__c,
                           'Collection Operation should match');
        System.assertEquals(testDataFactory.summary.startDate, optimizationRun.sked_Start_Date__c,
                           'Start date should match');
        System.assertEquals(testDataFactory.summary.endDate, optimizationRun.sked_End_Date__c,
                           'End date should match');
        System.assertNotEquals(null, optimizationRun.sked_Drive_Types__c, 'Drive types should be populated');
        System.assertNotEquals(null, optimizationRun.sked_Timezone__c, 'Timezone should be populated');

        // Verify Optimization Queue was created
        List<sked_Optimization_Queue__c> queues = [
            SELECT Id, sked_Status__c, sked_Drive_Type__c, sked_Collection_Operation__c,
                   sked_Optimization_Run__c, sked_Start_Date__c, sked_End_Date__c
            FROM sked_Optimization_Queue__c
            WHERE sked_Optimization_Run__c = :optimizationRun.Id
        ];
        System.assertEquals(1, queues.size(), 'Should create exactly one optimization queue');
        System.assertEquals(skedConstants.OPTIMIZATION_QUEUE_STATUS_PENDING, queues[0].sked_Status__c,
                           'Queue status should be Pending');
        System.assertEquals(optimizationRun.Id, queues[0].sked_Optimization_Run__c,
                           'Queue should be linked to optimization run');

        // Verify Optimization Queue Items were created
        List<sked_Optimization_Queue_Item__c> queueItems = [
            SELECT Id, sked_Drive__c, sked_Optimization_Queue__c, sked_Type__c
            FROM sked_Optimization_Queue_Item__c
            WHERE sked_Optimization_Queue__c IN :queues
        ];
        System.assertEquals(1, queueItems.size(), 'Should create one queue item for the drive');
        System.assertEquals(testDrive.Id, queueItems[0].sked_Drive__c, 'Queue item should reference the test drive');
        System.assertEquals('Selected', queueItems[0].sked_Type__c, 'Queue item type should be Selected');

        // Verify Optimizer Settings were created
        List<sked_CollectionOperationOptimizerSetting__c> settings = [
            SELECT Id, sked_Constraint__c, sked_Default_Weight__c, sked_Enabled__c,
                   sked_Optimizer_Mapped_Weight__c, sked_Drive_Type__c
            FROM sked_CollectionOperationOptimizerSetting__c
            WHERE sked_Optimization_Run__c = :optimizationRun.Id
        ];
        System.assertEquals(1, settings.size(), 'Should create optimizer settings');
        System.assertEquals('Account/Site Preferences', settings[0].sked_Constraint__c,
                           'Constraint should match input');
        System.assertEquals('High', settings[0].sked_Default_Weight__c, 'Weight should match input');
        System.assertEquals(true, settings[0].sked_Enabled__c, 'Setting should be enabled');
        System.assertNotEquals(null, settings[0].sked_Optimizer_Mapped_Weight__c,
                              'Mapped weight should be calculated');

        // Update optimization run for subsequent tests
        if (!optimizationRunQuery.isEmpty()) {
            optimizationRun.sked_Run_ID__c = 'abc786ff-f168-426c-8325-0abafdf370af';
            optimizationRun.sked_Status__c = skedConstants.OPTIMIZATION_RUN_STATUS_COMPLETE;
            optimizationRun.sked_Opt_Run_Meta__c = '[{"jobId":"driverdota1J5c00000YbwEUEAZ","featureAllocId":"alloc_a2l5c000003Gs91AAC:driverdota1J5c00000YbwEUEAZ:0","existingAllocationId":null},{"jobId":"a1J5c00000YbwEVEAZ","featureAllocId":"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEVEAZ:0","existingAllocationId":null},{"jobId":"a1J5c00000YbwEWEAZ","featureAllocId":"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEWEAZ:0","existingAllocationId":null},{"jobId":"a1J5c00000YbwEWEAZ","featureAllocId":"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEWEAZ:1","existingAllocationId":null},{"jobId":"a1J5c00000YbwEWEAZ","featureAllocId":"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEWEAZ:2","existingAllocationId":null},{"jobId":"a1J5c00000YbwEWEAZ","featureAllocId":"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEWEAZ:3","existingAllocationId":null}]';
            optimizationRun.sked_Opt_Run_Diff__c = '{"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEWEAZ:1":{"deallocation":null,"allocation":"a1c5c00000FBnMdAAL"},"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEWEAZ:0":{"deallocation":null,"allocation":"a1c5c00000FBmATAA1"},"alloc_a2l5c000003Gs91AAC:driverdota1J5c00000YbwEUEAZ:0":{"deallocation":null,"allocation":"a1c5c00000FBnWMAA1"},"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEWEAZ:3":{"deallocation":null,"allocation":"a1c5c00000FBmhIAAT"},"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEWEAZ:2":{"deallocation":null,"allocation":"a1c5c00000FBmJcAAL"},"alloc_a2l5c000003Gs91AAC:a1J5c00000YbwEVEAZ:0":{"deallocation":null,"allocation":"a1c5c00000FBmmcAAD"}}';
            update optimizationRun;

            Set<Id> optimizationRunIds = new Set<Id>();
            optimizationRunIds.add(optimizationRun.Id);

            slwcOptimizationService.getOptimizationRunsRequestModel getOptimizationRunsRequest = new slwcOptimizationService.getOptimizationRunsRequestModel();
            getOptimizationRunsRequest.territoryKeys = new List<string>();
            getOptimizationRunsRequest.territoryKeys.add(testTerritory1.Id + ':' + testCollectionOperation1.Id);
            getOptimizationRunsRequest.startDate = testDataFactory.summary.startDate;
            getOptimizationRunsRequest.endDate = testDataFactory.summary.endDate;

            // Test getOptimizationRuns
            slwcAuraResult runsResult = slwcOptimizationService.getOptimizationRuns(getOptimizationRunsRequest);
            System.assertNotEquals(null, runsResult, 'Result should not be null');
            System.assertNotEquals(null, runsResult.returnedData, 'Returned data should not be null');

            List<sked_Optimization_Run__c> returnedRuns = (List<sked_Optimization_Run__c>) runsResult.returnedData;
            System.assertEquals(1, returnedRuns.size(), 'Should return the optimization run');
            System.assertEquals(optimizationRun.Id, returnedRuns[0].Id, 'Should return correct optimization run');

            // Test getOptimizationRunStatistics
            slwcAuraResult statsResult = slwcOptimizationService.getOptimizationRunStatistics(optimizationRun.Id);
            System.assertNotEquals(null, statsResult, 'Statistics result should not be null');
            System.assertNotEquals(null, statsResult.returnedData, 'Statistics data should not be null');

            List<sked_Optimization_Run__c> statsRuns = (List<sked_Optimization_Run__c>) statsResult.returnedData;
            System.assertEquals(1, statsRuns.size(), 'Should return one optimization run with stats');
            System.assertNotEquals(null, statsRuns[0].sked_Start_Date__c, 'Start date should be populated');
            System.assertNotEquals(null, statsRuns[0].sked_End_Date__c, 'End date should be populated');

            // Test getOptimizedJobAllocation
            slwcAuraResult allocResult = slwcOptimizationService.getOptimizedJobAllocation(optimizationRun.Id);
            System.assertNotEquals(null, allocResult, 'Allocation result should not be null');
            System.assertNotEquals(null, allocResult.returnedData, 'Allocation data should not be null');

            // Test compareOptimizerSettings
            Set<Id> matchingIds = slwcOptimizationService.compareOptimizerSettings(optimizationRun.Id, optimizationRunIds);
            System.assertNotEquals(null, matchingIds, 'Matching IDs should not be null');
            System.assertEquals(1, matchingIds.size(), 'Should match with itself');
            System.assert(matchingIds.contains(optimizationRun.Id), 'Should include the same optimization run');

            sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
                sked__Job__c = testJob.Id,
                sked__Resource__c = testResource.Id,
                sked_Optimization_Run__c = optimizationRun.Id
            );
            insert testJobAllocation;

            // Test evaluateOptimizationRunResult
            slwcOptimizationService.evaluateOptimizationRunResult(optimizationRun.Id);

            // Verify optimization run was updated with evaluation results
            sked_Optimization_Run__c updatedRun = [
                SELECT Id, sked_Total_Travel_Time__c, sked_No_of_Percent_Jobs_Filled__c,
                       sked_Priority_Role_Scheduled_Percent__c, sked_Average_Hours_per_Staff__c
                FROM sked_Optimization_Run__c
                WHERE Id = :optimizationRun.Id
            ];
            System.assertNotEquals(null, updatedRun.sked_Total_Travel_Time__c,
                                  'Total travel time should be calculated');
            System.assertNotEquals(null, updatedRun.sked_No_of_Percent_Jobs_Filled__c,
                                  'Percent jobs filled should be calculated');
        }

        Test.stopTest();
    }

    static testmethod void testInitiateRun() {
        Test.setMock(HttpCalloutMock.class, new skedMockTest());

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Territory__c testTerritory1 = (sked_Territory__c) mapTestData.get('testTerritory1');
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive1 = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        sked_Linked_Drives__c testLinkedDrives = new sked_Linked_Drives__c(
            sked_Linked_Drive_Type__c = 'Same Day'
        );
        insert testLinkedDrives;

        testDrive1.sked_Linked_Drives__c = testLinkedDrives.Id;
        update testDrive1;

        sked_Drive__c testDrive2 = testDrive1.clone();
        testDrive2.sked_Linked_Drives__c = testLinkedDrives.Id;
        insert testDrive2;

        Test.startTest();

        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c testDriveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        driveShifts.add(testDriveShift1);

        sked_Drive_Shift__c testDriveShift2 = testDriveShift1.clone();
        driveShifts.add(testDriveShift2);

        insert driveShifts;

        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(testJob1);

        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Shift__c = testDriveShift2.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job2);
        insert jobs;

        slwcOptimizationService.optimizationSettingModel setting = new slwcOptimizationService.optimizationSettingModel();
        setting.constraint = 'Account/Site Preferences';
        setting.constraintType = 'Soft Constraint';
        setting.driveType = 'Mobile';
        setting.defaultWeight = 'High';
        setting.enabled = true;

        List<string> driveIds = new List<string>();
        driveIds.add(testDrive1.Id);
        driveIds.add(testDrive2.Id);

        slwcOptimizationService.initiateOptimizationRunRequestModel initiateOptimizationRunRequest = new slwcOptimizationService.initiateOptimizationRunRequestModel();
        initiateOptimizationRunRequest.driveIds = driveIds;
        initiateOptimizationRunRequest.startDate = testDataFactory.summary.startDate;
        initiateOptimizationRunRequest.endDate = testDataFactory.summary.endDate;
        initiateOptimizationRunRequest.optimizationSettings = new List<slwcOptimizationService.optimizationSettingModel> {setting};

        slwcAuraResult initResult = slwcOptimizationService.initiateOptimizationRun(initiateOptimizationRunRequest);
        System.assertNotEquals(null, initResult, 'Result should not be null');

        // Verify linked drives were handled correctly
        List<sked_Optimization_Queue_Item__c> queueItems = [
            SELECT Id, sked_Drive__c, sked_Type__c, sked_Inherit_Result_From__c
            FROM sked_Optimization_Queue_Item__c
        ];
        System.assertEquals(2, queueItems.size(), 'Should create queue items for both linked drives');

        // Verify inheritance was set up (one drive should inherit from the other)
        Integer inheritanceCount = 0;
        for (sked_Optimization_Queue_Item__c item : queueItems) {
            if (item.sked_Inherit_Result_From__c != null) {
                inheritanceCount++;
            }
        }
        System.assertEquals(1, inheritanceCount,
                           'One drive should inherit from the other in linked drive scenario');

        Test.stopTest();
    }

}