@isTest
private class skedTriggerUtils_Test {
    @isTest
    static void maintainDateTimeField_Test() {
        sked_Admin_Setting__c skedAdminSetting = sked_Admin_Setting__c.getOrgDefaults();
        skedAdminSetting.sked_Admin_DateTime_Conversion__c = TRUE;
        upsert skedAdminSetting;
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        sked__Activity__c activity = new sked__Activity__c(
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert activity;
        
        activity.sked__Start__c = activity.sked__Start__c.addDays(7);
        activity.sked__End__c = activity.sked__End__c.addDays(7);
        update activity;
        
        Test.stopTest();
    }
    
    @isTest
    static void updateJobAllocations_Test() {
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
        insert testResourceJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testResourceJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;
        
        Set<Id> jobIds = new Set<Id>();
        jobIds.add(testResourceJob.Id);
        Set<Id> driveShiftIds = new Set<Id>();
        driveShiftIds.add(testDriveShift.Id);
        
        skedTriggerUtils.updateJobAllocations(jobIds, driveShiftIds);
        
        Test.stopTest();
    }
    
    @isTest
    static void hasPermissionSetAssignment_Test() {
        PermissionSet ps = new PermissionSet(Label = 'Test Permission Set', Name = 'testps');
        insert ps;
        
        // Given mocked Permission Set assigned to user for test
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = ps.Id
        );
        insert psa;
        
        Test.startTest();
        System.assert(skedTriggerUtils.hasPermissionSetAssignment(ps.Name));
        Test.stopTest();
    }
    
    @isTest
    static void userBelongsToProfile_Test() {
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        
        User testUser = new user(alias = 'testuser', email='test@testleton.com', emailencodingkey='UTF-8', firstName='test', lastname='testleton', 
                                 languagelocalekey='en_US', localesidkey='en_US', profileid = testProfile.Id, country='United States',
                                 timezonesidkey='America/Los_Angeles', username='test@testleton.com');
        insert testUser;
        
        System.runAs(testUser) {
            System.assert(skedTriggerUtils.userBelongsToProfile(testProfile.Name));
        }
    }

    static testmethod void testPopulateTimezoneFromTaxonomy() {
        insert new Taxonomy__c(
            Zip_Code__c = '61149',
            Time_Zone__c = 'Europe/Berlin',
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(1)
        );

        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea',
            sked_Zip_Code__c = '61149'
        );

        insert testStagingLocation1;
        
        testStagingLocation1 = [SELECT sked_Timezone__c FROM sked_Staging_Location__c LIMIT 1];
        System.assertEquals('Europe/Berlin', testStagingLocation1.sked_Timezone__c);
    }

    static testmethod void testValidateServiceEntry() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        Profile apsProfile = [SELECT Id FROM Profile WHERE Name = 'APS Planner' LIMIT 1];

        Test.startTest();
        skedHubBase.setBypassAllTriggers(true);
        User testUser = new user(
            alias = 'testuser', email='test@testleton.com', emailencodingkey='UTF-8', firstName='test', lastname='testleton', 
            languagelocalekey='en_US', localesidkey='en_US', profileid = apsProfile.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='test@testleton.com', UFID__c = '123456'
        );
        insert testUser;
        skedHubBase.setBypassAllTriggers(false);
        System.runAs(testUser) {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = false;
            skedTriggerUtils.validateServiceEntry(new List<SObject>{testDrive}, skedConstants.DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE);
        }
        Test.stopTest();
        Assert.isTrue(testDrive.hasErrors());
    }
}