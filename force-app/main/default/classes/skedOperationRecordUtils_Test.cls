@isTest
private class skedOperationRecordUtils_Test {
    @isTest
    static void hasPremiumTagForRole_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Account testAccount = (Account) mapTestData.get('testAccount1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

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
        
        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            sked_Drive__c = testDriveShift.sked_Drive__c,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Status__c = 'Not Submitted'
        );
        insert testOperationRecord;

        sked_Operation_Record_Staff__c testOperationRecordStaff = new sked_Operation_Record_Staff__c(
            sked_Operation_Record__c = testOperationRecord.Id,
            sked_Resource__c = testResource.Id,
            sked_Premiums_Op_Pay__c = 'Driver',
            sked_Actual_Roles__c = 'Driver CDL B'
        );
        insert testOperationRecordStaff;

        sked__Tag__c testDriverCdlBTag = [SELECT Id FROM sked__Tag__c WHERE Name = 'Driver CDL B'];
        sked__Resource_Tag__c testResourceDriverCdlBTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = testDriverCdlBTag.Id,
            sked_Premium_Pay__c = true,
            sked_Start_Date__c = System.today().addDays(-100)
        );
        insert testResourceDriverCdlBTag;

        testResource = [
            SELECT Id, Name, 
                (SELECT Id, sked__Tag__r.Name, sked_Premium_Pay__c, sked_Start_Date__c, sked_Expiry_Date__c
                FROM sked__ResourceTags__r)
            FROM sked__Resource__c
            WHERE Id = :testResource.Id
        ];

        Map<String, List<String>> premiumOpPayToRole = skedUtils.getMapPremiumOpPayToRole();
        System.assert(skedOperationRecordUtils.hasPremiumTagForRole('Driver', premiumOpPayToRole.get('Driver'), testResource, testOperationRecordStaff, System.today()));
        Test.stopTest();
    }

    @isTest
    static void hasPremiumTagForRole_Test_Invalid() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Account testAccount = (Account) mapTestData.get('testAccount1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

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
        
        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            sked_Drive__c = testDriveShift.sked_Drive__c,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Status__c = 'Not Submitted'
        );
        insert testOperationRecord;

        sked_Operation_Record_Staff__c testOperationRecordStaff = new sked_Operation_Record_Staff__c(
            sked_Operation_Record__c = testOperationRecord.Id,
            sked_Resource__c = testResource.Id,
            sked_Premiums_Op_Pay__c = 'Driver',
            sked_Actual_Roles__c = 'Driver - DOT'
        );
        insert testOperationRecordStaff;

        sked__Tag__c testDriverCdlBTag = [SELECT Id FROM sked__Tag__c WHERE Name = 'Driver CDL B'];
        sked__Resource_Tag__c testResourceDriverCdlBTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = testDriverCdlBTag.Id,
            sked_Premium_Pay__c = true,
            sked_Start_Date__c = System.today().addDays(-100)
        );
        insert testResourceDriverCdlBTag;

        testResource = [
            SELECT Id, Name, 
                (SELECT Id, sked__Tag__r.Name, sked_Premium_Pay__c, sked_Start_Date__c, sked_Expiry_Date__c
                FROM sked__ResourceTags__r)
            FROM sked__Resource__c
            WHERE Id = :testResource.Id
        ];

        Map<String, List<String>> premiumOpPayToRole = skedUtils.getMapPremiumOpPayToRole();
        System.assertEquals(false, skedOperationRecordUtils.hasPremiumTagForRole('Driver', premiumOpPayToRole.get('Driver'), testResource, testOperationRecordStaff, System.today()));
        Test.stopTest();
    }
    
}