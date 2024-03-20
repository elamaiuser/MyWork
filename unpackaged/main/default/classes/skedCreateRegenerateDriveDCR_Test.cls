@isTest
private class skedCreateRegenerateDriveDCR_Test {
    @isTest
    static void skedCreateRegenerateDriveDCR_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, Object> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

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
            sked_Volunteer_Setup__c = 1,
            sked_2RBC_Projected_Procedures__c = 50
        );
        insert testDriveShift;

        testDrive.sked_2RBC_Projected_Procedures__c = 40;
        update testDrive;
        
        Database.executeBatch(new skedCreateRegenerateDriveDCRBatch(), 1);
        Test.stopTest();
    }
}