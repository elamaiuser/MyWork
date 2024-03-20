@isTest
private class skedJobAllocationTravelTimeBatch_Test {
    
    static testmethod void skedJobAllocationTravelTimeBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        Test.startTest();
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        insert testJobAllocation;
        
        Set<Id> jaIds = new Set<Id>();
        jaIds.add(testJobAllocation.Id);
        
        Database.executeBatch(new skedJobAllocationTravelTimeBatch(jaIds));
        
        Test.stopTest();
    }
    
    static testmethod void skedJobAllocationTravelTimeBatch_ResourceOverride_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        Test.startTest();
        
        sked__Resource_Override__c testResourceOverride = new sked__Resource_Override__c(
            sked__Resource__c = testResource.Id,
            sked__Geolocation__Latitude__s = 30.7575256,
            sked__Geolocation__Longitude__s = -125.4730585,
            sked__End__c = testDataFactory.summary.endTime,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_End_Time__c = testDataFactory.summary.endTime.time(),
            sked__Start__c = testDataFactory.summary.startTime,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Start_Time__c = testDataFactory.summary.startTime.time(),
            sked_Collection_Operation__c = testCollectionOperation1.Id
        );
        insert testResourceOverride;
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked__Job_Allocation_Time_Source__c = FALSE
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        insert testJobAllocation;
        
        Set<Id> jaIds = new Set<Id>();
        jaIds.add(testJobAllocation.Id);
        
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        Database.executeBatch(new skedJobAllocationTravelTimeBatch(jaIds));
        
        Test.stopTest();
    }
}