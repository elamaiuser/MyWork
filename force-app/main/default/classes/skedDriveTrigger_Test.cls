@isTest
private class skedDriveTrigger_Test {

    static testmethod void testApproveDrive() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Set<string> coNames = new Set<string>();
            coNames.add(testCollectionOperation1.Name);
            skedBiomedCollectionOpHandler.createQueues(coNames);
        }
        
        Test.startTest();
        
        testDrive1.sked_Approval_Status__c = 'Submitted';
        testDrive1.sked_Pending_Action__c = 'Drive Submission';
        testDrive1.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        update testDrive1;
        
        testDrive1.sked_Approval_Status__c = 'Approved';
        update testDrive1;
        
        Test.stopTest();
    }
    
    static testmethod void testRejectDrive() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Set<string> coNames = new Set<string>();
            coNames.add(testCollectionOperation1.Name);
            skedBiomedCollectionOpHandler.createQueues(coNames);
        }
        
        Test.startTest();
        
        testDrive1.sked_Approval_Status__c = 'Submitted';
        testDrive1.sked_Pending_Action__c = 'Drive Submission';
        testDrive1.sked_Route_Approval_Request_To__c = 'Request APS exception';
        update testDrive1;
        
        testDrive1.sked_Approval_Status__c = 'Rejected';
        update testDrive1;
        
        Test.stopTest();
    }
    
    static testmethod void testConfirmDrive() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        Test.startTest();

        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
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
        insert driveShift;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Resource_Role__c = 'Driver',
            sked_Travel_Time__c = 45,
            sked_Travel_Time2__c = 45
        );
        jobs.add(job);
        
        sked__Job__c equipmentJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Asset_Type__c = 'Equipment'
        );
        jobs.add(equipmentJob);
        
        insert jobs;

		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED
        );
        jobAllocations.add(testResource1_job1);
        insert jobAllocations;

        testDrive1.sked_Projected_Registered_Donors__c = testDrive1.sked_Projected_Registered_Donors__c + 1;
        update testDrive1;
        
        testDrive1.sked_End_Time__c = testDrive1.sked_End_Time__c.addMinutes(15);
        testDrive1.sked_Need_To_Notified__c = TRUE;
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED;
        update testDrive1;
        
        Test.stopTest();
    }
    
    static testmethod void testConfirmDriveByAPS() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        Test.startTest();

        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
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
        insert driveShift;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Resource_Role__c = 'Driver',
            sked_Travel_Time__c = 45,
            sked_Travel_Time2__c = 45
        );
        jobs.add(job);
        
        sked__Job__c equipmentJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Asset_Type__c = 'Equipment'
        );
        jobs.add(equipmentJob);
        
        insert jobs;

		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED
        );
        jobAllocations.add(testResource1_job1);
        insert jobAllocations;
        
        List<User> drdUsers = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name = 'DRD Profile' 
                               AND IsActive = TRUE 
                               LIMIT 1];
        if (!drdUsers.isEmpty()) {
            System.runAs(new User(Id = drdUsers.get(0).Id)){
                testDrive1.sked_End_Time__c = testDrive1.sked_End_Time__c.addMinutes(15);
                testDrive1.sked_Need_To_Notified__c = TRUE;
                testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED;
                update testDrive1;    
            }
        }
        
        Test.stopTest();
    }
    
    static testmethod void testHoldDrive() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        Account testAccount1 = (Account)mapTestData.get('testAccount1');
        
        Test.startTest();
        
        AccountTeamMember teamMember = new AccountTeamMember(
        	AccountId = testAccount1.Id, 
            TeamMemberRole = 'Booking Support',
            UserId = UserInfo.getUserId(),
            Start_Date__c = testDataFactory.summary.startDate,
            End_Date__c = testDataFactory.summary.endDate
        );
        insert teamMember;
            
        List<sObject> firstList = new List<sObject>();

        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
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
        insert driveShift;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id
        );
        jobs.add(job);
        insert jobs;

		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job1);
        insert jobAllocations;
        
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_HOLD;
        update testDrive1;
        
        //unhold drive
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        update testDrive1;
        
        Test.stopTest();
    }
    
    static testmethod void testCancelDrive() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        Account testAccount1 = (Account)mapTestData.get('testAccount1');
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Set<string> coNames = new Set<string>();
            coNames.add(testCollectionOperation1.Name);
            skedBiomedCollectionOpHandler.createQueues(coNames);
        }
        
        Test.startTest();

        List<sObject> firstList = new List<sObject>();
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
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
        insert driveShift;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id
        );
        jobs.add(job);
        insert jobs;

		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job1);
        insert jobAllocations;
        
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED;
        update testDrive1;
        
        testDrive1.sked_Pending_Action__c = 'Cancel In Process';
        testDrive1.sked_Route_Approval_Request_To__c = 'Request APS exception';
        testDrive1.sked_Approval_Status__c = 'Submitted';
        update testDrive1;
        
        testDrive1.sked_Approval_Status__c = 'Approved';
        update testDrive1;
        
        Test.stopTest();
    }
    
    static testmethod void testDeleteDrive() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        Account testAccount1 = (Account)mapTestData.get('testAccount1');
        
        Test.startTest();
        
        try {
            delete testDrive1;
        }
        catch(Exception ex) {}
        
        Test.stopTest();
    }
    
    static testmethod void testRankingDrive() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        Test.startTest();
        
        sked_Drive__c testDrive2 = testDrive1.clone();
        testDrive2.sked_Drive_Productivity_Planned__c = 0.5;
        insert testDrive2;
        
        Test.stopTest();
    }
    
    static testmethod void testLinkedDriveRemoval() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
                
        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        Account testAccount1 = (Account)mapTestData.get('testAccount1');
        
        sked_Linked_Drives__c testLinkedDrives = new sked_Linked_Drives__c(
            sked_Linked_Drive_Type__c = 'Same Day'
        );
        insert testLinkedDrives;
        
        testDrive1.sked_Linked_Drives__c = testLinkedDrives.Id;
        update testDrive1;
        
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
        update testDrive1;
        
        Test.stopTest();
    }

    static testmethod void onConfirmDrives_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name LIKE '%DRD%' LIMIT 1];
        sked_Drive__c testDrive1 = (sked_Drive__c) mapTestData.get('testDrive1');
        
        sked_Drive__c testDrive2 = testDrive1.clone();
        testDrive2.sked_Drive_Date__c = testDrive1.sked_Drive_Date__c.addDays(100);
        insert testDrive2;

        User testUser = new user(alias = 'testuser', email='test@testleton.com', emailencodingkey='UTF-8', firstName='test', lastname='testleton', 
        languagelocalekey='en_US', localesidkey='en_US', profileid = drdProfile.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username='test@testleton.com');
        insert testUser;
        
        testDrive2.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED;
        update testDrive2;
        
        Test.stopTest();
    }

    static testmethod void onStagingLocationChanged_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive1 = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testSite1 = (sked__Location__c) mapTestData.get('testLocation1');
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c) mapTestData.get('testStagingLocation1');
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 39.7450046,
            sked_Geolocation__Longitude__s = -120.4816244
        );
        insert testStagingLocation2;

        sked_Travel_Time_Index_Item__c testTtii1 = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = testSite1.sked__GeoLocation__Latitude__s,
            sked_From__Longitude__s = testSite1.sked__GeoLocation__Longitude__s,
            sked_To__Latitude__s = testStagingLocation1.sked_GeoLocation__Latitude__s,
            sked_To__Longitude__s = testStagingLocation1.sked_GeoLocation__Longitude__s,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_SITE_TO_CO + testStagingLocation1.sked_GeoLocation__Latitude__s + ':' + testStagingLocation1.sked_GeoLocation__Longitude__s,
            sked_Average_Travel_Time__c = 0
        );

        sked_Travel_Time_Index_Item__c testTtii2 = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = testSite1.sked__GeoLocation__Latitude__s,
            sked_From__Longitude__s = testSite1.sked__GeoLocation__Longitude__s,
            sked_To__Latitude__s = testStagingLocation2.sked_GeoLocation__Latitude__s,
            sked_To__Longitude__s = testStagingLocation2.sked_GeoLocation__Longitude__s,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_SITE_TO_CO + testStagingLocation2.sked_GeoLocation__Latitude__s + ':' + testStagingLocation2.sked_GeoLocation__Longitude__s,
            sked_Average_Travel_Time__c = 50
        );

        sked_Travel_Time_Index_Item__c testTtii3 = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = testStagingLocation1.sked_GeoLocation__Latitude__s,
            sked_From__Longitude__s = testStagingLocation1.sked_GeoLocation__Longitude__s,
            sked_To__Latitude__s = testSite1.sked__GeoLocation__Latitude__s,
            sked_To__Longitude__s = testSite1.sked__GeoLocation__Longitude__s,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_CO_TO_SITE + testStagingLocation1.sked_GeoLocation__Latitude__s + ':' + testStagingLocation1.sked_GeoLocation__Longitude__s,
            sked_Average_Travel_Time__c = 100
        );

        sked_Travel_Time_Index_Item__c testTtii4 = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = testStagingLocation2.sked_GeoLocation__Latitude__s,
            sked_From__Longitude__s = testStagingLocation2.sked_GeoLocation__Longitude__s,
            sked_To__Latitude__s = testSite1.sked__GeoLocation__Latitude__s,
            sked_To__Longitude__s = testSite1.sked__GeoLocation__Longitude__s,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_CO_TO_SITE + testStagingLocation2.sked_GeoLocation__Latitude__s + ':' + testStagingLocation2.sked_GeoLocation__Longitude__s,
            sked_Average_Travel_Time__c = 150
        );
        insert new List<sked_Travel_Time_Index_Item__c>{testTtii1, testTtii2, testTtii3, testTtii4};

        Test.startTest();
        testDrive1.sked_Staging_Location__c = testStagingLocation2.Id;
        update testDrive1;
        Test.stopTest();
    }

    static testmethod void repopulateDistrict_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive1 = (sked_Drive__c) mapTestData.get('testDrive1');
        sked_Territory__c testTerritory1 = (sked_Territory__c) mapTestData.get('testTerritory1');
        Biomed_Collection_Op_Center__c testCollectionOp1 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        Biomed_Collection_Op_Center__c testCollectionOp2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');

        sked_Territory_Collection_Operation__c testTerritory1_testCollectionOperation2 = new sked_Territory_Collection_Operation__c(
        	sked_Territory__c = testTerritory1.Id,
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert testTerritory1_testCollectionOperation2;

        Test.startTest();
        testDrive1.sked_Collection_Operation__c = testCollectionOp2.Id;
        update testDrive1;
        Test.stopTest();

    }
    
}