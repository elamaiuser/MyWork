@isTest
public class skedActivityTrigger_Test {
    
    static testmethod void testException() {
        sked_Admin_Setting__c skedAdminSetting = sked_Admin_Setting__c.getOrgDefaults();
        skedAdminSetting.sked_Admin_DateTime_Conversion__c = TRUE;
        upsert skedAdminSetting;
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(10),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION
        );
        insert job;
        
        sked__Job_Offer__c jobOffer = new sked__Job_Offer__c(
            sked__Job__c = job.Id
        );
        insert jobOffer;
        
        sked__Resource_Job_Offer__c resourceJobOffer = new sked__Resource_Job_Offer__c(sked__Job_Offer__c = jobOffer.Id,
                                                                                       sked__Resource__c = testResource1.Id
                                                                                      );
        insert resourceJobOffer;
        
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
        
        delete activity;
        
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        sked__Activity__c skedGroupActivity = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = activityTypes.get(0),
            sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE,
            sked_Fixed_Site_Staff_Quantity__c = 5,
            sked_Mobile_Staff_Quantity__c = 5
        );
        insert skedGroupActivity;
        
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = skedGroupActivity.Id,
            sked__Resource__c = testResource1.Id
        );
        insert skedActivityResource;
        
        sked__Activity__c activity2 = new sked__Activity__c(
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = testDataFactory.summary.startTime.addDays(1).addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addDays(1).addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert activity2;
        
        Test.stopTest();
    }
    
    @isTest
    static void syncResourcesFromLinkedDrive_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        sked__Resource__c testResource = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOp1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        
        Test.startTest();
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(1),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED
        );
        sked__Job_Allocation__c testJobAllocation2 = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED
        );
        insert new List<SObject>{testJobAllocation1, testJobAllocation2};
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Type__c = 'Administration',
            sked__Start__c = Datetime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(9, 0, 0, 0)),
            sked__End__c = Datetime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(17, 0, 0, 0)),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Drive__c = testDrive.Id,
            sked_Inherit_Resources_From_Drive__c = true,
            sked_Is_Group_Activity__c = true
        );
        insert testActivity;
        
        Test.stopTest();

        List<sked__Activity_Resource__c> testActivityResources = [
            SELECT Id
            FROM sked__Activity_Resource__c
            WHERE sked__Activity__c = :testActivity.Id
        ];
        Assert.areEqual(1, testActivityResources.size());
    }
    
    @isTest
    static void syncResourcesFromLinkedDrive_Edit_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        sked__Resource__c testResource = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOp1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        
        Test.startTest();
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(1),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id
        );
        
        insert testJobAllocation;
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Type__c = 'Administration',
            sked__Start__c = Datetime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(9, 0, 0, 0)),
            sked__End__c = Datetime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(17, 0, 0, 0)),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Is_Group_Activity__c = true
        );
        insert testActivity;
        
        testActivity.sked_Drive__c = testDrive.Id;
        testActivity.sked_Inherit_Resources_From_Drive__c = true;
        
        update testActivity;
        
        Test.stopTest();
    }
    
    @isTest
    static void deleteTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Type__c = 'Administration',
            sked__Start__c = System.now().addHours(6),
            sked__End__c = System.now().addHours(16),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Is_Group_Activity__c = true
        );
        insert testActivity;
        
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = testActivity.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testActivityResource;
        
        Test.startTest();
        
        delete testActivity;
        
        Test.stopTest();
    }
    
    @isTest
    static void deleteAvailabilityForOnCallResources_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_ON_CALL,
            sked__Start__c = System.now().addHours(6),
            sked__End__c = System.now().addHours(16),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Is_Group_Activity__c = true
        );
        insert testActivity;
        
        delete [SELECT Id FROM sked__Availability__c];
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = testActivity.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testActivityResource;
        
        Test.startTest();
        
        delete testActivity;
        
        Test.stopTest();
    }
}