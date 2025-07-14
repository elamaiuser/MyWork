@isTest
private class skedExceptionLogService_Test {
    
    static testmethod void testFSWBDriveException() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive2 = (sked_Drive__c)mapTestData.get('testDrive2');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation2 = (sked__Location__c)mapTestData.get('testLocation2');
        Time_Block__c testTimeBlock1 = (Time_Block__c)mapTestData.get('testTimeBlock1');
        
        Test.startTest();
        
        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Date__c = testDrive2.sked_Drive_Date__c,
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
        driveShifts.add(driveShift1);
        
        sked_Drive_Shift__c driveShift2 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(4, 0, 0, 0),
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Date__c = testDrive2.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(10, 0, 0, 0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(4, 0, 0, 0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1,
            sked_Time_Block__c = testTimeBlock1.Id
        );
        driveShifts.add(driveShift2);
        
        insert driveShifts;
        
        driveShift1.sked_Time_Block__c = testTimeBlock1.Id;
        update driveShift1;
        
        testDrive2.sked_Drive_Date__c = testDrive2.sked_Drive_Date__c.addDays(1);
        update testDrive2;
        
        testDrive2.sked_Drive_Date__c = testDrive2.sked_Drive_Date__c.addYears(1);
        update testDrive2;
        
        Test.stopTest();
    }

}