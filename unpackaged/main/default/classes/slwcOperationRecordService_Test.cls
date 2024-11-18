@isTest
private class slwcOperationRecordService_Test {
    
    static testmethod void generateOperationRecords_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData(); 
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        
        slwcOperationRecordService.generateOperationRecordsRequest req = new slwcOperationRecordService.generateOperationRecordsRequest();
        req.driveId = testDrive.Id;
        
        Test.startTest();
        
        slwcOperationRecordService.generateOperationRecords(req);
        
        Test.stopTest();
    }
    
    static testmethod void submitOperationRecord_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData(); 
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        skedHubBase.setBypassAllTriggers(true);
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
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob;
        
        slwcOperationRecordService.generateOperationRecordsRequest req = new slwcOperationRecordService.generateOperationRecordsRequest();
        req.driveId = testDrive.Id;
        
        sked_Operation_Record__c testOpRecord = new sked_Operation_Record__c(
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id
        );
        
        insert testOpRecord;
        
        sked_Operation_Record_Staff__c testOpRecordStaff = new sked_Operation_Record_Staff__c(
            sked_Notes_Comments__c = 'Testing',
            sked_Added_Staff__c = true,
            sked_Actual_Shift_Start__c = system.now(),
            sked_Actual_Shift_End__c = system.now().addDays(20),
            sked_No_Meal__c = true,
            sked_Premiums_Op_Pay__c = '2RBC',
            sked_Absent__c = true,
            sked_Operation_Record__c = testOpRecord.Id,
            sked_Job__c = testJob.Id,
            sked_Actual_Roles__c = '2RBC',
            sked_Resource__c = testResource.Id
        );
        insert testOpRecordStaff;	
        skedHubBase.setBypassAllTriggers(false);
        
        Test.startTest();
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        slwcOperationRecordService.submitOpsRecordRequest submitReq = new slwcOperationRecordService.submitOpsRecordRequest();
        submitReq.operationRecordId = testOpRecord.Id;
        
        slwcAuraResult result = slwcOperationRecordService.submitOperationRecord(submitReq);
        
        Test.stopTest();
    }
    
    static testmethod void submitOperationRecord_TestError() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData(); 
        
        skedHubBase.setBypassAllTriggers(true);
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
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
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob;
        
        slwcOperationRecordService.generateOperationRecordsRequest req = new slwcOperationRecordService.generateOperationRecordsRequest();
        req.driveId = testDrive.Id;
        
        sked_Operation_Record__c testOpRecord = new sked_Operation_Record__c(
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id
        );
        
        insert testOpRecord;
        
        sked_Operation_Record_Staff__c testOpRecordStaff = new sked_Operation_Record_Staff__c(
            sked_Notes_Comments__c = 'Testing',
            sked_Added_Staff__c = true,
            sked_Actual_Shift_Start__c = system.now(),
            sked_Actual_Shift_End__c = system.now().addDays(20),
            sked_No_Meal__c = true,
            sked_Premiums_Op_Pay__c = '2RBC',
            sked_Absent__c = true,
            sked_Operation_Record__c = testOpRecord.Id,
            sked_Job__c = testJob.Id,
            sked_Actual_Roles__c = '2RBC',
            sked_Resource__c = testResource.Id
        );
        insert testOpRecordStaff;	
        skedHubBase.setBypassAllTriggers(false);
        
        Test.startTest();
        skedMockTest mockTest = new skedMockTest();
        mockTest.statusCode = 500;
        mockTest.isErrorMode = TRUE;
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        slwcOperationRecordService.submitOpsRecordRequest submitReq = new slwcOperationRecordService.submitOpsRecordRequest();
        submitReq.operationRecordId = testOpRecord.Id;
        
        slwcAuraResult result = slwcOperationRecordService.submitOperationRecord(submitReq);
        
        Test.stopTest();
    }
    
    static testmethod void getResourceData_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData(); 

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

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
        
        Biomed_Collection_Op_Center__c collectionOp = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        
        slwcOperationRecordService.getResourceDataRequestModel req = new slwcOperationRecordService.getResourceDataRequestModel();
        req.inputDate = '' + System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        req.driveShiftId = testDriveShift.Id;
        req.roles = new List<String>();
        req.roles.add('2RBC');
        req.queryText = 'Test Resource';
        
        slwcAuraResult result = slwcOperationRecordService.getResourceData(req);
        
        Test.stopTest();
    }
    
    static testmethod void populateExternalIds_Test() {
        slwcOperationRecordService.populateExternalIdsRequest request = new slwcOperationRecordService.populateExternalIdsRequest();
        slwcOperationRecordService.populateExternalIds(request);
    }
    static testmethod void submitOperationRecord_TestSuccess() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData(); 
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        skedHubBase.setBypassAllTriggers(true);

        testDrive.sked_Status__c = 'Confirmed';
        triggerHandler.bypass('DriveTriggerHandler');
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
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob;
        
        slwcOperationRecordService.generateOperationRecordsRequest req = new slwcOperationRecordService.generateOperationRecordsRequest();
        req.driveId = testDrive.Id;
        
        sked_Operation_Record__c testOpRecord = new sked_Operation_Record__c(
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id
        );
        
        insert testOpRecord;
        
        sked_Operation_Record_Staff__c testOpRecordStaff = new sked_Operation_Record_Staff__c(
            sked_Notes_Comments__c = 'Testing',
            sked_Added_Staff__c = true,
            sked_Actual_Shift_Start__c = system.now(),
            sked_Actual_Shift_End__c = system.now().addDays(20),
            sked_No_Meal__c = true,
            sked_Premiums_Op_Pay__c = '2RBC',
            sked_Absent__c = true,
            sked_Operation_Record__c = testOpRecord.Id,
            sked_Job__c = testJob.Id,
            sked_Actual_Roles__c = '2RBC',
            sked_Resource__c = testResource.Id
        );
        insert testOpRecordStaff;	
        skedHubBase.setBypassAllTriggers(false);
        
        Test.startTest();
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        skedSetting.instance.Admin.enableOperationRecordLog = true;
        skedSetting.instance.Email.bitTechnicalSupport = 'test.test@test.test';
        skedSetting.instance.Email.bhqApsStaffSchedulingManagers = 'test.test1@test.test';
        skedSetting.instance.Email.bhqApsStaffSchedulingTimekeeping = 'test.test2@test.test';
        skedSetting.instance.Email.apsDirectors = 'test.test3@test.test';
        skedSetting.instance.Email.bhqCollectionsPlanningScheduling = 'test.test4@test.test';
        slwcOperationRecordService.submitOpsRecordRequest submitReq = new slwcOperationRecordService.submitOpsRecordRequest();
        submitReq.operationRecordId = testOpRecord.Id;
        
        slwcAuraResult result = slwcOperationRecordService.submitOperationRecord(submitReq);
        
        Test.stopTest();
    }
}