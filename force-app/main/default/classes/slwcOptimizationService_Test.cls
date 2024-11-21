@isTest
private class slwcOptimizationService_Test {
    
    static testmethod void mainTest() {
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
        
        slwcOptimizationService.initiateOptimizationRun(initiateOptimizationRunRequest);
        
        List<sked_Optimization_Run__c> optimizationRunQuery = [SELECT Id, sked_Status__c
                                                               FROM sked_Optimization_Run__c];
        system.assert(optimizationRunQuery.size() == 1);
        if (!optimizationRunQuery.isEmpty()) {
            sked_Optimization_Run__c optimizationRun = optimizationRunQuery.get(0);
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
            
            slwcOptimizationService.getOptimizationRuns(getOptimizationRunsRequest);
            slwcOptimizationService.getOptimizationRunStatistics(optimizationRun.Id);
            slwcOptimizationService.getOptimizedJobAllocation(optimizationRun.Id);
            slwcOptimizationService.compareOptimizerSettings(optimizationRun.Id, optimizationRunIds);
            
            sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
                sked__Job__c = testJob.Id,
                sked__Resource__c = testResource.Id,
                sked_Optimization_Run__c = optimizationRun.Id
            );
            insert testJobAllocation;
            
            slwcOptimizationService.evaluateOptimizationRunResult(optimizationRun.Id);
        }
        
        Test.stopTest();
    }
    
}