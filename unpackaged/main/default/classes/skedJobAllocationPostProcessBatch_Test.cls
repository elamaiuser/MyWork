@isTest
private class skedJobAllocationPostProcessBatch_Test {
    
    @isTest
    static void skedJobAllocationPostProcessBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Resource__c testVehicle = (sked__Resource__c) mapTestData.get('testVehicle1');
        
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
        
        sked__Job__c testResourceJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        
        sked__Job__c testVehicleJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Asset_Type__c = 'Vehicle'
        );
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Drive__c = testDrive.Id,
            sked_Inherit_Resources_From_Drive__c = true,
            sked_Is_Group_Activity__c = true
        );
        insert new List<SObject>{testResourceJob, testVehicleJob, testActivity};
            
            sked__Job_Allocation__c testResourceJobAllocation = new sked__Job_Allocation__c(
                sked__Job__c = testResourceJob.Id,
                sked__Resource__c = testResource.Id,
                sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
                sked_Roles_Assignment_Str__c = '2RBC',
                sked_Additional_Roles__c = '2RBC Sign-off'
            );
        
        sked__Job_Allocation__c testVehicleJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testVehicleJob.Id,
            sked__Resource__c = testVehicle.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Resource__c = testResource.Id,
            sked__Activity__c = testActivity.Id
        );
        insert new List<SObject>{testActivityResource, testResourceJobAllocation, testVehicleJobAllocation};
            
            List<sked__Job_Allocation__c> testJobAllocations = [SELECT Id FROM sked__Job_Allocation__c];
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c testJobAllocation : testJobAllocations) {
            jobAllocationIds.add(testJobAllocation.Id);
        }
        
        skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
        batchSetting.geographicException = false;
        Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, jobAllocationIds));
        
        Test.stopTest();
    }
    
    @isTest
    static void skedJobAllocationPostProcessBatch_Test_NoResourceHoursRecord() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Resource__c testVehicle = (sked__Resource__c) mapTestData.get('testVehicle1');
        
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
        
        sked__Job__c testResourceJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        
        sked__Job__c testVehicleJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Asset_Type__c = 'Vehicle'
        );
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Drive__c = testDrive.Id,
            sked_Inherit_Resources_From_Drive__c = true,
            sked_Is_Group_Activity__c = true
        );
        insert new List<SObject>{testResourceJob, testVehicleJob, testActivity};
            
            sked__Job_Allocation__c testResourceJobAllocation = new sked__Job_Allocation__c(
                sked__Job__c = testResourceJob.Id,
                sked__Resource__c = testResource.Id,
                sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
                sked_Roles_Assignment_Str__c = '2RBC',
                sked_Additional_Roles__c = '2RBC Sign-off'
            );
        
        sked__Job_Allocation__c testVehicleJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testVehicleJob.Id,
            sked__Resource__c = testVehicle.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Resource__c = testResource.Id,
            sked__Activity__c = testActivity.Id
        );
        insert new List<SObject>{testActivityResource, testResourceJobAllocation, testVehicleJobAllocation};
            
            delete [SELECT Id FROM sked_Resource_Hours_Record__c];
        List<sked__Job_Allocation__c> testJobAllocations = [SELECT Id FROM sked__Job_Allocation__c];
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c testJobAllocation : testJobAllocations) {
            jobAllocationIds.add(testJobAllocation.Id);
        }
        
        skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
        batchSetting.geographicException = false;
        Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, jobAllocationIds));
        
        Test.stopTest();
    }
    
    @isTest
    static void skedJobAllocationPostProcessBatch_LinkedDrive_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Resource__c testVehicle = (sked__Resource__c) mapTestData.get('testVehicle1');
        sked__Tag__c testTag = [SELECT Id FROM sked__Tag__c LIMIT 1][0];
        
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
        
        sked__Job__c testResourceJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        
        sked__Job__c testVehicleJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Asset_Type__c = 'Vehicle'
        );
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Drive__c = testDrive.Id,
            sked_Inherit_Resources_From_Drive__c = true,
            sked_Is_Group_Activity__c = true
        );
        insert new List<SObject>{testResourceJob, testVehicleJob, testActivity};
            
            sked__Job_Allocation__c testResourceJobAllocation = new sked__Job_Allocation__c(
                sked__Job__c = testResourceJob.Id,
                sked__Resource__c = testResource.Id,
                sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
                sked_Roles_Assignment_Str__c = '2RBC',
                sked_Additional_Roles__c = '2RBC Sign-off'
            );
        
        sked__Job_Allocation__c testVehicleJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testVehicleJob.Id,
            sked__Resource__c = testVehicle.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Resource__c = testResource.Id,
            sked__Activity__c = testActivity.Id
        );
        insert new List<SObject>{testActivityResource, testResourceJobAllocation, testVehicleJobAllocation};
            
        sked_Drive_Shift_Tag__c testDriveShiftTag = new sked_Drive_Shift_Tag__c(
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_MigrationID__c = 'test-migration-id',
            sked_Minimum_Quantity__c = 5,
            sked_Tag__c = testTag.Id
        );
        insert testDriveShiftTag;
        
        List<sked__Job_Allocation__c> testJobAllocations = [SELECT Id FROM sked__Job_Allocation__c];
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c testJobAllocation : testJobAllocations) {
            jobAllocationIds.add(testJobAllocation.Id);
        }
        
        sked_Linked_Drives__c testLinkedDrives = new sked_Linked_Drives__c(
            sked_Linked_Drive_Type__c = 'Same Day'
        );
        insert testLinkedDrives;
        
        testDrive.sked_Linked_Drives__c = testLinkedDrives.Id;
        
        testActivity.sked_Linked_Drives__c = testLinkedDrives.Id;
        update new List<SObject>{testDrive, testActivity};    
            
        skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
        batchSetting.geographicException = false;
        Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, jobAllocationIds));
        
        Test.stopTest();
    }
    
    @isTest
    static void skedJobAllocationPostProcessBatch_DriveShiftException_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Resource__c testVehicle = (sked__Resource__c) mapTestData.get('testVehicle1');
        sked__Tag__c testTag = [SELECT Id FROM sked__Tag__c LIMIT 1][0];
        
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
        
        sked__Job__c testResourceJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        
        sked__Job__c testVehicleJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Asset_Type__c = 'Vehicle'
        );
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Drive__c = testDrive.Id,
            sked_Inherit_Resources_From_Drive__c = true,
            sked_Is_Group_Activity__c = true
        );
        insert new List<SObject>{testResourceJob, testVehicleJob, testActivity};
            
            sked__Job_Allocation__c testResourceJobAllocation = new sked__Job_Allocation__c(
                sked__Job__c = testResourceJob.Id,
                sked__Resource__c = testResource.Id,
                sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
                sked_Roles_Assignment_Str__c = '2RBC',
                sked_Additional_Roles__c = '2RBC Sign-off'
            );
        
        sked__Job_Allocation__c testVehicleJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testVehicleJob.Id,
            sked__Resource__c = testVehicle.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Resource__c = testResource.Id,
            sked__Activity__c = testActivity.Id
        );
        insert new List<SObject>{testActivityResource, testResourceJobAllocation, testVehicleJobAllocation};
            
        sked_Drive_Shift_Tag__c testDriveShiftTag = new sked_Drive_Shift_Tag__c(
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_MigrationID__c = 'test-migration-id',
            sked_Minimum_Quantity__c = 5,
            sked_Tag__c = testTag.Id
        );
        insert testDriveShiftTag;
        
        List<sked__Job_Allocation__c> testJobAllocations = [SELECT Id FROM sked__Job_Allocation__c];
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c testJobAllocation : testJobAllocations) {
            jobAllocationIds.add(testJobAllocation.Id);
        }
        
        skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
        batchSetting.geographicException = false;
        Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, jobAllocationIds));
        
        Test.stopTest();
    }

    @isTest
    static void skedJobAllocationPostProcessBatch_Test_ValidResourceCo() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        
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
        
        sked__Job__c testResourceJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert new List<SObject>{testResourceJob};
            
        sked__Job_Allocation__c testResourceJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testResourceJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        
        sked__Resource_Override__c testResourceOverride = new sked__Resource_Override__c(
            sked__Resource__c = testResource.Id,
            sked_Collection_Operation__c = testCo.Id,
            sked__End__c = System.now().addHours(6),
            sked__Start__c = System.now().addHours(6),
            sked_Travel_To_Start__c = System.now().addMinutes(5),
            sked_Travel_To_End__c = System.now().addMinutes(5),
            sked_Travel_Back_Start__c = System.now().addMinutes(5),
            sked_Travel_Back_End__c = System.now().addMinutes(5),
            sked_End_Date__c = System.today(),
            sked_Start_Date__c = System.today(),
            sked_Travel_Back_End_Date__c = System.today(),
            sked_Travel_Back_Start_Date__c = System.today(),
            sked_Travel_To_End_Date__c = System.today(),
            sked_Travel_To_Start_Date__c = System.today(),
            sked_End_Time__c = System.now().time(),
            sked_Travel_Back_End_Time__c = System.now().addMinutes(5).time(),
            sked_Travel_Back_Start_Time__c = System.now().time(),
            sked_Travel_To_End_Time__c = System.now().addMinutes(5).time(),
            sked_Start_Time__c = System.now().time(),
            sked_Travel_To_Start_Time__c = System.now().addMinutes(5).time()
        );
        
        sked__Resource_Region__c testResourceRegion = new sked__Resource_Region__c(
            sked__Resource__c = testResource.Id,
            sked__Region__c = testRegion.Id
        );
        insert new List<SObject>{testResourceJobAllocation, testResourceOverride, testResourceRegion};

        List<sked__Job_Allocation__c> testJobAllocations = [SELECT Id FROM sked__Job_Allocation__c];
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c testJobAllocation : testJobAllocations) {
            jobAllocationIds.add(testJobAllocation.Id);
        }

        skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
        batchSetting.geographicException = false;
        Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, jobAllocationIds));
        
        Test.stopTest();
    }

    @isTest
    static void skedJobAllocationPostProcessBatch_Test_InvalidResourceCo() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        Biomed_Collection_Op_Center__c testCo2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');

        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Region__c testRegion2 = testRegion.clone(false, false, false, false);
        testRegion2.Name = 'Test Region 2';
        testRegion2.sked_Biomed_Collection_Op_Center__c = testCo2.Id;
        insert testRegion2;

        Test.startTest();

        testResource.sked__Primary_Region__c = testRegion2.Id;
        update testResource;
        
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
        
        sked__Job__c testResourceJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert new List<SObject>{testResourceJob};
            
        sked__Job_Allocation__c testResourceJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testResourceJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        
        sked__Resource_Override__c testResourceOverride = new sked__Resource_Override__c(
            sked__Resource__c = testResource.Id,
            sked_Collection_Operation__c = testCo.Id,
            sked__End__c = System.now().addHours(6),
            sked__Start__c = System.now().addHours(6),
            sked_Travel_To_Start__c = System.now().addMinutes(5),
            sked_Travel_To_End__c = System.now().addMinutes(5),
            sked_Travel_Back_Start__c = System.now().addMinutes(5),
            sked_Travel_Back_End__c = System.now().addMinutes(5),
            sked_End_Date__c = System.today(),
            sked_Start_Date__c = System.today(),
            sked_Travel_Back_End_Date__c = System.today(),
            sked_Travel_Back_Start_Date__c = System.today(),
            sked_Travel_To_End_Date__c = System.today(),
            sked_Travel_To_Start_Date__c = System.today(),
            sked_End_Time__c = System.now().time(),
            sked_Travel_Back_End_Time__c = System.now().addMinutes(5).time(),
            sked_Travel_Back_Start_Time__c = System.now().time(),
            sked_Travel_To_End_Time__c = System.now().addMinutes(5).time(),
            sked_Start_Time__c = System.now().time(),
            sked_Travel_To_Start_Time__c = System.now().addMinutes(5).time()
        );
        
        sked__Resource_Region__c testResourceRegion = new sked__Resource_Region__c(
            sked__Resource__c = testResource.Id,
            sked__Region__c = testRegion.Id
        );
        insert new List<SObject>{testResourceJobAllocation, testResourceOverride, testResourceRegion};

        List<sked__Job_Allocation__c> testJobAllocations = [SELECT Id FROM sked__Job_Allocation__c];
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c testJobAllocation : testJobAllocations) {
            jobAllocationIds.add(testJobAllocation.Id);
        }

        skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
        batchSetting.geographicException = false;
        Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, jobAllocationIds));
        
        Test.stopTest();
    }

    @isTest
    static void skedJobAllocationPostProcessBatch_Test_RoleRestricted() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Resource_Tag__c test2rbcResourceTag = (sked__Resource_Tag__c) mapTestData.get('testResource1_testTag2RBC');

        test2rbcResourceTag.sked_Restriction_Start_Date__c = System.today().addDays(-100);
        update test2rbcResourceTag;

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
        
        sked__Job__c testResourceJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = 'Charge',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert new List<SObject>{testResourceJob};
            
        sked__Job_Allocation__c testResourceJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testResourceJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC'
        );

        insert testResourceJobAllocation;

        skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
        batchSetting.geographicException = false;
        Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, new Set<Id>{testResourceJobAllocation.Id}));
        
        Test.stopTest();
    }
}