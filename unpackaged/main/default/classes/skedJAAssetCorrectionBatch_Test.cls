@isTest
private class skedJAAssetCorrectionBatch_Test {

    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
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
        insert testDriveShift;
        
        sked__Job__c job1 = new sked__Job__c(
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = 'Vehicle',
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked__Job_Allocation_Time_Source__c = FALSE
        );
        insert job1;

        sked__Job_Allocation__c testVehicle1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job1.Id,
            sked__Resource__c = testVehicle1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        insert testVehicle1_job1;
        
        Database.executeBatch(new skedJAAssetCorrectionBatch());
        
        Test.stopTest();
    }
    
}