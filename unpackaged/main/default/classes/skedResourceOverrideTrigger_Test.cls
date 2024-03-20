@isTest
private class skedResourceOverrideTrigger_Test {
    @isTest
    static void skedResourceOverrideTrigger_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Tag__c mobileTag = [SELECT Id FROM sked__Tag__c WHERE Name = 'Mobile' LIMIT 1][0];
        
        skedHubBase.setBypassAllTriggers(true);
        insert new sked__Resource_Tag__c(
            sked_Start_Date__c = System.today().addYears(-1),
            sked__Resource__c = testResource.Id,
            sked__Tag__c = mobileTag.Id
        );

        sked_Staffing_Constraint__c testStaffingConstraintFS = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Date_of_Constraint__c = testDataFactory.summary.startDate,
            sked_Drive_Type__c = 'Fixed Site',
            sked_Total_Staff_Constraints__c = 20
        );
        sked_Staffing_Constraint__c testStaffingConstraintM = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Date_of_Constraint__c = testDataFactory.summary.startDate,
            sked_Drive_Type__c = 'Mobile',
            sked_Total_Staff_Constraints__c = 20
        );
        insert new List<sked_Staffing_Constraint__c>{testStaffingConstraintFS, testStaffingConstraintM};
        
        sked__Resource_Override__c testResourceOverride = new sked__Resource_Override__c(
            sked__Resource__c = testResource.Id,
            sked__Geolocation__Latitude__s = 30.7575256,
            sked__Geolocation__Longitude__s = -125.4730585,
            sked__End__c = System.now().addHours(6),
            sked__Start__c = System.now().addHours(6),
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Travel_To_Start__c = System.now().addMinutes(5),
            sked_Travel_To_End__c = System.now().addMinutes(5),
            sked_Travel_Back_Start__c = System.now().addMinutes(5),
            sked_Travel_Back_End__c = System.now().addMinutes(5),
            sked_End_Date__c = System.today().addDays(5),
            sked_Start_Date__c = System.today().addDays(-5),
            sked_Travel_Back_End_Date__c = System.today().addDays(5),
            sked_Travel_Back_Start_Date__c = System.today(),
            sked_Travel_To_End_Date__c = System.today(),
            sked_Travel_To_Start_Date__c = System.today(),
            sked_End_Time__c = System.now().time(),
            sked_Travel_Back_End_Time__c = System.now().addMinutes(5).time(),
            sked_Travel_Back_Start_Time__c = System.now().time(),
            sked_Travel_To_End_Time__c = System.now().addMinutes(5).time(),
            sked_Start_Time__c = System.now().time(),
            sked_Travel_To_Start_Time__c = System.now().addMinutes(5).time(),
            sked_Is_Travel_Required__c = true
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
        skedHubBase.setBypassAllTriggers(false);

        Set<Id> jaIds = new Set<Id>();
        jaIds.add(testJobAllocation.Id);
        
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        testResourceOverride.sked_Start_Date__c = System.today();
        update testResourceOverride;
        delete testResourceOverride;
        
        Test.stopTest();
    }
}