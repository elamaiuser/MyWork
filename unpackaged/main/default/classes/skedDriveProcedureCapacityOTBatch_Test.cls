@isTest
private class skedDriveProcedureCapacityOTBatch_Test {
    static testmethod void skedDriveProcedureCapacityOneTimeBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c mobileTestDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        
        Test.startTest();
        
        sked_Drive__c fixedSiteTestDrive = mobileTestDrive.clone(false, false, false, false);
        fixedSiteTestDrive.sked_Type_of_Drive__c = 'Fixed Site';
        fixedSiteTestDrive.sked_MigrationID__c = 'migration-id-2';
        fixedSiteTestDrive.sked_Plasma_Projected_Procedures__c = 10;
        fixedSiteTestDrive.sked_Platelet_Projected_Procedures__c = 10;
        insert fixedSiteTestDrive;

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = fixedSiteTestDrive.Id,
            sked_Drive_Date__c = fixedSiteTestDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(fixedSiteTestDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(fixedSiteTestDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 6,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1,
            sked_Platelet_Rounds__c = 2
        );
        insert testDriveShift;
        
        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(fixedSiteTestDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(fixedSiteTestDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = fixedSiteTestDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = 'Apheresis',
            sked__Quantity__c = 5
        );

        sked__Job__c testJob2 = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(fixedSiteTestDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(fixedSiteTestDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = fixedSiteTestDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = 'Apheresis Charge',
            sked__Quantity__c = 1
        );
        insert new List<sked__Job__c>{testJob1, testJob2};
        
        Database.executeBatch(new skedDriveProcedureCapacityOneTimeBatch(new Set<Id>{fixedSiteTestDrive.Id}));
        
        Test.stopTest();

        fixedSiteTestDrive = [SELECT Id, sked_Procedure_Capacity__c FROM sked_Drive__c WHERE Id = :fixedSiteTestDrive.Id LIMIT 1];
        testDriveShift = [SELECT Id, sked_Staff_Setup__c FROM sked_Drive_Shift__c WHERE Id = :testDriveShift.Id LIMIT 1];
        testJob1 = [SELECT Id, sked__Quantity__c FROM sked__Job__c WHERE Id = :testJob1.Id LIMIT 1];
        System.assertEquals(40, fixedSiteTestDrive.sked_Procedure_Capacity__c);
        System.assertEquals(8, testDriveShift.sked_Staff_Setup__c);
        System.assertEquals(7, testJob1.sked__Quantity__c);
    }
}