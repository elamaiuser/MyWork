@isTest
private class skedOperationRecordHandler_Test {
    @isTest
    static void populateLastModifiedUser_Test() {
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
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;
        
        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            sked_Drive_Shift__c = testDriveShift.Id
        );
        
        insert testOperationRecord;
        
        Test.stopTest();
    }
    
    @isTest
    static void lockSubmittedRecord_Test() {
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
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;
        
        testResource.sked__User__c = UserInfo.getUserId();
        testResource.sked__Is_Active__c = true;
        update testResource;
        
        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Status__c = 'Not Submitted'
        );
        insert testOperationRecord;
        
        testOperationRecord.sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED;
        update testOperationRecord;
        
        Test.stopTest();
    }
    
    @isTest
    static void onSubmitted_Test() {
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
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;
        
        testResource.sked__User__c = UserInfo.getUserId();
        testResource.sked__Is_Active__c = true;
        testResource.sked_Home_State__c = 'CA';
        update testResource;
        
        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            sked_Drive__c = testDriveShift.sked_Drive__c,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Status__c = 'Not Submitted'
        );
        insert testOperationRecord;
        
        sked_Operation_Record_Staff__c testOperationRecordStaff = new sked_Operation_Record_Staff__c(
        	sked_Operation_Record__c = testOperationRecord.Id,
        	sked_Number_of_Rest_Breaks_Taken__c = 2,
            sked_Rest_Breaks_Earned__c = 3,
        	sked_Resource__c = testResource.Id,
        	sked_Job_Allocation__c = testJobAllocation.Id
        );
        insert testOperationRecordStaff;
        
        testOperationRecord.sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED;
        testOperationRecord.sked_Submitted_By__c = testResource.Id;
        update testOperationRecord;
        
        Test.stopTest();
    }
    
    @isTest
    static void captureOnCall_Test() {
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

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;
        
        skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});
        
        sked_Operation_Record_Staff__c operationRecordStaff = [SELECT Id, sked_Operation_Record__c
                                                               FROM sked_Operation_Record_Staff__c
                                                               WHERE sked_Job_Allocation__c = :testJobAllocation.Id];
        operationRecordStaff.sked_Actual_Shift_Start__c = testDriveShift.sked_Start__c.addMinutes(1);
        operationRecordStaff.sked_Actual_Shift_End__c = testDriveShift.sked_Finish__c.addMinutes(-1);
        operationRecordStaff.sked_Late_Arrival_Reasons__c = 'Personal';
        operationRecordStaff.sked_Early_Departure_Reasons__c = 'Personal';
        update operationRecordStaff;
        
        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            Id = operationRecordStaff.sked_Operation_Record__c,
            sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED
        );
        update testOperationRecord;
        
        Test.stopTest();
    }

    @isTest
    static void captureCallOuts_absent_createsCalloutAndPto() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        Test.startTest();

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(14, 0, 0, 0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;

        skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});

        sked_Operation_Record_Staff__c operationRecordStaff = [SELECT Id, sked_Operation_Record__c
                                                               FROM sked_Operation_Record_Staff__c
                                                               WHERE sked_Job_Allocation__c = :testJobAllocation.Id];
        operationRecordStaff.sked_Absent__c = TRUE;
        update operationRecordStaff;

        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            Id = operationRecordStaff.sked_Operation_Record__c,
            sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED
        );
        update testOperationRecord;

        Test.stopTest();

        List<sked__Availability__c> callouts = [SELECT Id, sked_Call_Out_Type__c, sked_Is_All_Day__c, sked_Custom_Status__c
                                                FROM sked__Availability__c
                                                WHERE sked__Resource__c = :testResource.Id
                                                AND sked_Call_Out_Type__c = :skedConstants.AVAILABILITY_CALLOUT_TYPE_CALL_OUT];
        System.assertEquals(1, callouts.size(), 'Expected 1 absent callout');
        System.assertEquals(TRUE, callouts[0].sked_Is_All_Day__c, 'Absent callout should be all-day');
        System.assertEquals(skedConstants.AVAILABILITY_STATUS_APPROVED, callouts[0].sked_Custom_Status__c, 'Callout should be Approved');

        List<sked__Availability__c> ptos = [SELECT Id, sked__Type__c, sked_Custom_Status__c, sked_Related_Call_Out__c
                                            FROM sked__Availability__c
                                            WHERE sked__Resource__c = :testResource.Id
                                            AND sked__Type__c = :skedConstants.AVAILABILITY_TYPE_PTO];
        System.assertEquals(1, ptos.size(), 'Expected 1 linked PTO');
        System.assertEquals(skedConstants.AVAILABILITY_STATUS_PENDING, ptos[0].sked_Custom_Status__c, 'PTO should be Pending');
        System.assertEquals(callouts[0].Id, ptos[0].sked_Related_Call_Out__c, 'PTO should link to the callout');
    }

    @isTest
    static void captureCallOuts_lateArrival_createsPto() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        Test.startTest();

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(14, 0, 0, 0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;

        skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});

        sked_Operation_Record_Staff__c operationRecordStaff = [SELECT Id, sked_Operation_Record__c
                                                               FROM sked_Operation_Record_Staff__c
                                                               WHERE sked_Job_Allocation__c = :testJobAllocation.Id];
        operationRecordStaff.sked_Actual_Shift_Start__c = testDriveShift.sked_Start__c.addMinutes(1);
        operationRecordStaff.sked_Late_Arrival_Reasons__c = 'Personal';
        update operationRecordStaff;

        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            Id = operationRecordStaff.sked_Operation_Record__c,
            sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED
        );
        update testOperationRecord;

        Test.stopTest();

        List<sked__Availability__c> callouts = [SELECT Id, sked_Call_Out_Type__c, sked_Custom_Status__c
                                                FROM sked__Availability__c
                                                WHERE sked__Resource__c = :testResource.Id
                                                AND sked_Call_Out_Type__c = :skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL];
        System.assertEquals(1, callouts.size(), 'Expected 1 late arrival callout');

        List<sked__Availability__c> ptos = [SELECT Id, sked_Custom_Status__c, sked_Related_Call_Out__c
                                            FROM sked__Availability__c
                                            WHERE sked__Resource__c = :testResource.Id
                                            AND sked__Type__c = :skedConstants.AVAILABILITY_TYPE_PTO];
        System.assertEquals(1, ptos.size(), 'Expected 1 linked PTO');
        System.assertEquals(skedConstants.AVAILABILITY_STATUS_PENDING, ptos[0].sked_Custom_Status__c, 'PTO should be Pending');
        System.assertEquals(callouts[0].Id, ptos[0].sked_Related_Call_Out__c, 'PTO should link to callout');
    }

    @isTest
    static void captureCallOuts_earlyDeparture_createsPto() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        Test.startTest();

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(14, 0, 0, 0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;

        skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});

        sked_Operation_Record_Staff__c operationRecordStaff = [SELECT Id, sked_Operation_Record__c
                                                               FROM sked_Operation_Record_Staff__c
                                                               WHERE sked_Job_Allocation__c = :testJobAllocation.Id];
        operationRecordStaff.sked_Actual_Shift_End__c = testDriveShift.sked_Finish__c.addMinutes(-1);
        operationRecordStaff.sked_Early_Departure_Reasons__c = 'Personal';
        update operationRecordStaff;

        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            Id = operationRecordStaff.sked_Operation_Record__c,
            sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED
        );
        update testOperationRecord;

        Test.stopTest();

        List<sked__Availability__c> callouts = [SELECT Id, sked_Call_Out_Type__c, sked_Custom_Status__c
                                                FROM sked__Availability__c
                                                WHERE sked__Resource__c = :testResource.Id
                                                AND sked_Call_Out_Type__c = :skedConstants.AVAILABILITY_CALLOUT_TYPE_EARLY_DEPARTURE];
        System.assertEquals(1, callouts.size(), 'Expected 1 early departure callout');

        List<sked__Availability__c> ptos = [SELECT Id, sked_Custom_Status__c, sked_Related_Call_Out__c
                                            FROM sked__Availability__c
                                            WHERE sked__Resource__c = :testResource.Id
                                            AND sked__Type__c = :skedConstants.AVAILABILITY_TYPE_PTO];
        System.assertEquals(1, ptos.size(), 'Expected 1 linked PTO');
        System.assertEquals(skedConstants.AVAILABILITY_STATUS_PENDING, ptos[0].sked_Custom_Status__c, 'PTO should be Pending');
        System.assertEquals(callouts[0].Id, ptos[0].sked_Related_Call_Out__c, 'PTO should link to callout');
    }

    @isTest
    static void captureTimeOffRequests_existingCalloutWithPto_updatesPto() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        Test.startTest();

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(14, 0, 0, 0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;

        skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});

        sked_Operation_Record_Staff__c operationRecordStaff = [SELECT Id, sked_Operation_Record__c
                                                               FROM sked_Operation_Record_Staff__c
                                                               WHERE sked_Job_Allocation__c = :testJobAllocation.Id];
        operationRecordStaff.sked_Actual_Shift_Start__c = testDriveShift.sked_Start__c.addMinutes(1);
        operationRecordStaff.sked_Late_Arrival_Reasons__c = 'Personal';
        update operationRecordStaff;

        sked__Availability__c existingCallout = new sked__Availability__c(
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_CALL_OUT,
            sked__Is_Available__c = FALSE,
            sked_Call_Out_Type__c = skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked__Resource__c = testResource.Id,
            sked_Call_Out_for_Job_Allocation__c = testJobAllocation.Id,
            sked_Call_Out_Reported__c = TRUE,
            sked__Start__c = testDriveShift.sked_Start__c,
            sked__Finish__c = testDriveShift.sked_Start__c.addMinutes(1)
        );
        insert existingCallout;

        sked__Availability__c existingPto = new sked__Availability__c(
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO,
            sked__Is_Available__c = FALSE,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_PENDING,
            sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PENDING,
            sked__Resource__c = testResource.Id,
            sked__Start__c = testDriveShift.sked_Start__c,
            sked__Finish__c = testDriveShift.sked_Start__c.addMinutes(1),
            sked_Related_Call_Out__c = existingCallout.Id
        );
        insert existingPto;

        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            Id = operationRecordStaff.sked_Operation_Record__c,
            sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED
        );
        update testOperationRecord;

        Test.stopTest();

        List<sked__Availability__c> callouts = [SELECT Id
                                                FROM sked__Availability__c
                                                WHERE sked__Resource__c = :testResource.Id
                                                AND sked__Type__c = :skedConstants.AVAILABILITY_TYPE_CALL_OUT];
        System.assertEquals(1, callouts.size(), 'Expected 1 callout, no duplicate created on re-upsert');

        List<sked__Availability__c> ptos = [SELECT Id, sked_Custom_Status__c, sked_Related_Call_Out__c
                                            FROM sked__Availability__c
                                            WHERE sked__Resource__c = :testResource.Id
                                            AND sked__Type__c = :skedConstants.AVAILABILITY_TYPE_PTO];
        System.assertEquals(1, ptos.size(), 'Expected 1 PTO, no duplicate created on re-upsert');
        System.assertEquals(skedConstants.AVAILABILITY_STATUS_PENDING, ptos[0].sked_Custom_Status__c, 'PTO should remain Pending');
    }

    @isTest
    static void captureTimeOffRequests_existingCalloutWithoutPto_insertsPto() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        Test.startTest();

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(14, 0, 0, 0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14, 0, 0, 0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20, 0, 0, 0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;

        skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});

        sked_Operation_Record_Staff__c operationRecordStaff = [SELECT Id, sked_Operation_Record__c
                                                               FROM sked_Operation_Record_Staff__c
                                                               WHERE sked_Job_Allocation__c = :testJobAllocation.Id];
        operationRecordStaff.sked_Actual_Shift_Start__c = testDriveShift.sked_Start__c.addMinutes(1);
        operationRecordStaff.sked_Late_Arrival_Reasons__c = 'Personal';
        update operationRecordStaff;

        sked__Availability__c existingCallout = new sked__Availability__c(
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_CALL_OUT,
            sked__Is_Available__c = FALSE,
            sked_Call_Out_Type__c = skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked__Resource__c = testResource.Id,
            sked_Call_Out_for_Job_Allocation__c = testJobAllocation.Id,
            sked_Call_Out_Reported__c = TRUE,
            sked__Start__c = testDriveShift.sked_Start__c,
            sked__Finish__c = testDriveShift.sked_Start__c.addMinutes(1)
        );
        insert existingCallout;

        sked_Operation_Record__c testOperationRecord = new sked_Operation_Record__c(
            Id = operationRecordStaff.sked_Operation_Record__c,
            sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED
        );
        update testOperationRecord;

        Test.stopTest();

        List<sked__Availability__c> ptos = [SELECT Id, sked_Custom_Status__c, sked_Related_Call_Out__c
                                            FROM sked__Availability__c
                                            WHERE sked__Resource__c = :testResource.Id
                                            AND sked__Type__c = :skedConstants.AVAILABILITY_TYPE_PTO];
        System.assertEquals(1, ptos.size(), 'Expected 1 PTO inserted for existing callout');
        System.assertEquals(skedConstants.AVAILABILITY_STATUS_PENDING, ptos[0].sked_Custom_Status__c, 'PTO should be Pending');
        System.assertNotEquals(null, ptos[0].sked_Related_Call_Out__c, 'PTO should be linked to callout');
    }

    @isTest
    static void validateCanDelete_Test() {
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

        System.runAs(new User(Id = UserInfo.getUserId())) {
            User testUser = new user(alias = 'testuser', email='test@testleton.com', emailencodingkey='UTF-8', firstName='test', lastname='testleton', 
                languagelocalekey='en_US', localesidkey='en_US', profileid = UserInfo.getProfileId(), country='United States',
                timezonesidkey='America/Los_Angeles', username='test@testleton.com');
            insert testUser;
        
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'sked_ARC_Lead_Resource' LIMIT 1];
    
            // Given mocked Permission Set assigned to user for test
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = ps.Id
            );
            insert psa;

            System.runAs(testUser) {
                Boolean caughtException = false;
                try {
                    delete testOperationRecord;
                } catch(Exception ex) {
                    caughtException = true;
                }
                System.assert(caughtException);
            }
        }

        Test.stopTest();
    }
}