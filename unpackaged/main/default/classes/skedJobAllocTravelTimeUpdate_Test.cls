@isTest
private class skedJobAllocTravelTimeUpdate_Test {
    @isTest
    static void skedScheduledJobAllocTravelTimeUpdate_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

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
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        insert testJobAllocation;
        
        skedScheduledJobAllocTravelTimeUpdate scheduler = new skedScheduledJobAllocTravelTimeUpdate();
		scheduler.execute(null);
        Test.stopTest();
    }
}