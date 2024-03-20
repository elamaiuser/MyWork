@isTest
private class skedRegMedScreenerGenBatch_Test {

    @TestSetup
    static void setupTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        
        Test.startTest();
        
        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
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
        driveShifts.add(driveShift1);
        
        insert driveShifts;

        update new sked_Drive__c(Id = testDrive1.Id, sked_Total_Products_Projected__c = 40);

        update new Account(Id = testDrive1.sked_Account__c, Type = 'Education', Industry_Code__c = 'High School');
        
        insert new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testDrive1.sked_Collection_Operation__c,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_Site__c = testDrive1.sked_Drive_Site__c,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_Region__c = testRegion1.Id
        );

        //Actual test
        System.schedule('skedRegulatedMedicalScreenerGenBatch_' + String.valueOf(Datetime.now()), 
            '0 0 0 * * ?', new skedRegulatedMedicalScreenerGenBatch());

        Test.stopTest();
    }

    @isTest
    static void testRegulatedMedicalScreenerJobCreation() {
        Id driveId = [SELECT Id From sked_Drive__c Where Name like 'Test%' LIMIT 1]?.Id;

        // Actual test was ran in setup method, as we can't run and verify scheduled job results
        // in the same test method context.

        //verify Medical Screener job created successfully
        System.assert([SELECT count() FROM sked__Job__c WHERE sked_drive__c =: driveId] == 1);
    }
}