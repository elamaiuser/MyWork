@isTest
private class slwcOpportunityService_Test {

    static testmethod void testCloneOpportunity() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        Opportunity testOpportunity = (Opportunity)mapTestData.get('testOpportunity');
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
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Resource_Role__c = 'Driver'
        );
        jobs.add(job);
        
        sked__Job__c equipmentJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Asset_Type__c = 'Equipment'
        );
        jobs.add(equipmentJob);
        
        insert jobs;
        
        sked__Slot__c slot = new sked__Slot__c(
        	sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Type__c = '2RBC',
            sked_Status__c = slwcConstants.SLOT_STATUS_OPEN,
            sked_Start__c = testDataFactory.summary.startTime.addHours(11),
            sked_End__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15)
        );
        insert slot;
        
        string newDriveDateIso = Json.serialize(testOpportunity.Drive_Date__c.addDays(1)).replace('"', '');
        slwcOpportunityService.cloneOpportunity(testOpportunity.Id, newDriveDateIso, true);
        
        Test.stopTest();
    }
    
}