@isTest
private class skedUpdateJobTimeVarianceBatch_Test {
    @isTest
    static void skedUpdateJobTimeVarianceBatch_Start_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();

        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Account testAccount = (Account) mapTestData.get('testAccount1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        Test.startTest();
            testDrive.sked_Drive_Date__c = System.today().addDays(1);
            update testDrive;

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
                sked_Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
                sked_Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
                sked_Order__c = 1,
                sked_Sign_Up_Reduction__c = 0,
                sked_Staff_Setup__c = 1,
                sked_Vehicles_Needed__c = 1,
                sked_Volunteer_Setup__c = 1
            );
            insert testDriveShift;

            sked__Job__c testJob = new sked__Job__c(
                sked__Location__c = testDriveSite.Id,
                sked__Region__c = testRegion.Id,
                sked__Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
                sked__Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
                sked__Duration__c = 360,
                sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
                sked_Drive__c = testDrive.Id,
                sked_Drive_Shift__c = testDriveShift.Id,
                sked_Resource_Role__c = '2RBC',
                sked_Volunteer_Role__c = 'Donor Ambassador',
                sked_Setup_Time__c = 60,
                sked_Travel_Time2__c = 60
            );
            sked__Job__c testAssetJob = new sked__Job__c(
                sked__Location__c = testDriveSite.Id,
                sked__Region__c = testRegion.Id,
                sked__Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
                sked__Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
                sked__Duration__c = 360,
                sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
                sked_Drive__c = testDrive.Id,
                sked_Drive_Shift__c = testDriveShift.Id,
                sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE
            );
            insert new List<sObject>{testJob, testAssetJob};

            DateTime driveDate = DateTime.newInstance(testDrive.sked_Drive_Date__c, testDrive.sked_Start_Time__c);
            driveDate = skedDateTimeUtils.toTimezone(driveDate, testDriveSite.sked_Timezone__c);
            string driveWeekday = driveDate.format('EEEE');
            List<skedRoleTimeVarianceAdjustment> adjustments = new List<skedRoleTimeVarianceAdjustment> {
                new skedRoleTimeVarianceAdjustment(
                    System.today().addDays(-10),
                    System.today().addDays(100),
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME,
                    15,
                    'Staff roles',
                    testDriveSite.Id,
                    driveWeekday
                ),
                new skedRoleTimeVarianceAdjustment(
                    System.today().addDays(-10),
                    System.today().addDays(100),
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_TRAVEL_TIME_FROM,
                    -30,
                    'Staff roles',
                    testDriveSite.Id,
                    driveWeekday
                )
            };

            Database.executeBatch(new skedUpdateJobTimeVarianceBatch(adjustments));
        Test.stopTest();

        testJob = [SELECT Id, sked_Setup_Time__c, sked_Travel_Time2__c, sked__Start__c, sked__Finish__c FROM sked__Job__c LIMIT 1][0];
        testAssetJob = [SELECT Id, sked__Start__c, sked__Finish__c, sked_Drive__r.sked_Min_Shift_Start__c, sked_Drive__r.sked_Max_Shift_End__c FROM sked__Job__c WHERE Id = :testAssetJob.Id][0];
        System.assertEquals(75, testJob.sked_Setup_Time__c);
        System.assertEquals(30, testJob.sked_Travel_Time2__c);
        System.assertEquals(345, skedDateTimeUtils.getDifferentMinutes(testJob.sked__Start__c, testJob.sked__Finish__c));
        System.assertEquals(testAssetJob.sked_Drive__r.sked_Min_Shift_Start__c, testAssetJob.sked__Start__c);
        System.assertEquals(testAssetJob.sked_Drive__r.sked_Max_Shift_End__c, testAssetJob.sked__Finish__c);
    }

    @isTest
    static void skedUpdateJobTimeVarianceBatch_Finish_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();

        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Account testAccount = (Account) mapTestData.get('testAccount1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        Test.startTest();
            testDrive.sked_Drive_Date__c = System.today().addDays(1);
            update testDrive;

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
                sked_Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
                sked_Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
                sked_Order__c = 1,
                sked_Sign_Up_Reduction__c = 0,
                sked_Staff_Setup__c = 1,
                sked_Vehicles_Needed__c = 1,
                sked_Volunteer_Setup__c = 1
            );
            insert testDriveShift;

            sked__Job__c testJob = new sked__Job__c(
                sked__Location__c = testDriveSite.Id,
                sked__Region__c = testRegion.Id,
                sked__Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
                sked__Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
                sked__Duration__c = 60,
                sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
                sked_Drive__c = testDrive.Id,
                sked_Drive_Shift__c = testDriveShift.Id,
                sked_Resource_Role__c = '2RBC',
                sked_Volunteer_Role__c = 'Donor Ambassador',
                sked_Setup_Time__c = 60,
                sked_Travel_Time2__c = 60
            );
            insert testJob;

            DateTime driveDate = DateTime.newInstance(testDrive.sked_Drive_Date__c, testDrive.sked_Start_Time__c);
            driveDate = skedDateTimeUtils.toTimezone(driveDate, testDriveSite.sked_Timezone__c);
            string driveWeekday = driveDate.format('EEEE');
            skedRoleTimeVarianceAdjustment adjustment = new skedRoleTimeVarianceAdjustment(
                System.today().addDays(-10),
                System.today().addDays(100),
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_TRAVEL_TIME_FROM,
                15,
                'Staff roles',
                testDriveSite.Id,
                driveWeekday
            );

            Database.executeBatch(new skedUpdateJobTimeVarianceBatch(new List<skedRoleTimeVarianceAdjustment>{adjustment}));
        Test.stopTest();

        testJob = [SELECT Id, sked_Travel_Time2__c FROM sked__Job__c LIMIT 1][0];
        System.assertEquals(75, testJob.sked_Travel_Time2__c);
    }
}