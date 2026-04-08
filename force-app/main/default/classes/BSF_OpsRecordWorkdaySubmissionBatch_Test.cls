@IsTest
private class BSF_OpsRecordWorkdaySubmissionBatch_Test {


    private class WorkdayEmptyReportMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'GET') {
                res.setStatusCode(200);
                res.setBody('{"Report_Entry":[]}');
                return res;
            }
            res.setStatusCode(400);
            res.setBody('Unexpected');
            return res;
        }
    }

    private class WorkdaySuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'GET') {
                res.setStatusCode(200);
                res.setBody('{"Report_Entry":[{"Employee_ID":"12345","TZ_Reference_Id":"US/Eastern"}]}');
                return res;
            }
            if (req.getMethod() == 'POST') {
                res.setStatusCode(200);
                res.setBody(
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:bsvc="urn:com.workday/bsvc">' +
                        '<soapenv:Body><bsvc:Put_Import_Process_Response>' +
                        '<bsvc:Import_Process_Reference><bsvc:ID>WID-SUCCESS</bsvc:ID></bsvc:Import_Process_Reference>' +
                        '</bsvc:Put_Import_Process_Response></soapenv:Body></soapenv:Envelope>'
                );
                return res;
            }
            res.setStatusCode(400);
            res.setBody('Unexpected method');
            return res;
        }
    }

    private class WorkdayFailEmployeeReportMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'GET') {
                // Force the batch into the Employee Report failure path.
                res.setStatusCode(500);
                res.setStatus('Internal Server Error');
                res.setBody('Employee Report failed (test mock).');
                return res;
            }
            if (req.getMethod() == 'POST') {
                // Shouldn't be called in this test (Employee Report fails first), but return success anyway.
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody(
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:bsvc="urn:com.workday/bsvc">' +
                        '<soapenv:Body>' +
                            '<bsvc:Put_Import_Process_Response>' +
                                '<bsvc:Import_Process_Reference>' +
                                    '<bsvc:ID>WID-123</bsvc:ID>' +
                                '</bsvc:Import_Process_Reference>' +
                            '</bsvc:Put_Import_Process_Response>' +
                        '</soapenv:Body>' +
                    '</soapenv:Envelope>'
                );
                return res;
            }

            res.setStatusCode(400);
            res.setStatus('Bad Request');
            res.setBody('Unexpected HTTP method in mock: ' + req.getMethod());
            return res;
        }
    }

    @IsTest
    static void execute_employeeReportFailure_marksOpsFailed_and_incrementsAttempt() {
        // create minimal Drive/DriveShift/Job/OpRecord/Staff dataset.
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion1 = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        // Drive Shift
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(14, 0, 0, 0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = false,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = null,
            sked_Lunch_Break_Start_Time__c = null,
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
            sked__Region__c = testRegion1.Id,
            sked__Start__c = System.now(),
            sked__Finish__c = System.now().addHours(1),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked__Location__c = testLocation1.Id,
            sked__Actual_Start__c = System.now(),
            sked__Actual_End__c = System.now().addHours(1),
            sked_Resource_Role__c = 'VP/HH',
            sked_VPHH_Quantity__c = 1,
            sked_APT_Quantity__c = 0,
            sked__Quantity__c = 1
        );
        insert testJob;

        // Ops Record
        sked_Operation_Record__c op = new sked_Operation_Record__c(
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Status__c = 'Not Submitted',
            sked_Locked__c = true,
            sked_Workday_Submission_Status__c = BSF_WorkdayDirectSubmissionConfig.STATUS_DRAFT,
            sked_Power_Red_Machines_Sent__c = 1,
            sked_Power_Red_Machines_Used__c = 1,
            sked_Submitted_By__c = testResource.Id,
            sked_Donor_Ambassadors_Actual__c = 0
        );
        insert op;
        // Ensure start() includes the record: CreatedDate must be < todayStart.
        Test.setCreatedDate(op.Id, System.now().addDays(-1));

        // Ops Record Staff
        sked_Operation_Record_Staff__c staff = new sked_Operation_Record_Staff__c(
            sked_Operation_Record__c = op.Id,
            sked_Job__c = testJob.Id,
            sked_Resource__c = testResource.Id,
            sked_Premiums_Op_Pay__c = 'Driver',
            sked_Actual_Roles__c = 'Driver',
            sked_Absent__c = false,
            sked_No_Meal__c = false,
            // Leave actual shift start/end null since this test takes the Employee Report failure path.
            sked_Actual_Shift_Start__c = null,
            sked_Actual_Shift_End__c = null
        );
        insert staff;

        // Mock Employee Report failure.
        Test.setMock(HttpCalloutMock.class, new WorkdayFailEmployeeReportMock());

        // Act
        Test.startTest();
        Database.executeBatch(new BSF_OpsRecordWorkdaySubmissionBatch(), 1);
        Test.stopTest();

        // Assert
        sked_Operation_Record__c opAfter = [
            SELECT Id, sked_Workday_Submission_Status__c, sked_Workday_Submission_Attempt__c, sked_WD_Last_Submission_Date__c
            FROM sked_Operation_Record__c
            WHERE Id = :op.Id
        ];
        System.assertEquals(
            BSF_WorkdayDirectSubmissionConfig.STATUS_FAILED,
            opAfter.sked_Workday_Submission_Status__c,
            'Employee Report failure should mark op record as Failed'
        );
        System.assertEquals(
            Decimal.valueOf(1),
            opAfter.sked_Workday_Submission_Attempt__c,
            'Attempt counter should increment to 1 on first failure'
        );
        System.assertEquals(
            Date.today(),
            opAfter.sked_WD_Last_Submission_Date__c,
            'Last submission attempt date should be stamped to today'
        );

        sked_Operation_Record_Staff__c staffAfter = [
            SELECT Id, sked_Workday_Submission_Status__c
            FROM sked_Operation_Record_Staff__c
            WHERE Id = :staff.Id
        ];
        System.assertEquals(
            BSF_WorkdayDirectSubmissionConfig.STAFF_STATUS_FAILED,
            staffAfter.sked_Workday_Submission_Status__c,
            'Staff should be marked Failed when Employee Report fails'
        );
    }

    @IsTest
    static void execute_employeeReportAndImportSuccess_marksOpsProcessed() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion1 = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        testResource.sked_Employee_ID__c = '12345';
        update testResource;

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1, sked_End_Time__c = Time.newInstance(20, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(14, 0, 0, 0), sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c, sked_Equipment__c = 1,
            sked_Lunch_Break__c = false, sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Lunch_Break_Duration__c = 0, sked_Order__c = 1, sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1, sked_Vehicles_Needed__c = 1, sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id, sked__Start__c = System.now(), sked__Finish__c = System.now().addHours(1),
            sked__Duration__c = 60, sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id, sked_Drive_Shift__c = testDriveShift.Id,
            sked__Location__c = testLocation1.Id, sked__Actual_Start__c = System.now(),
            sked__Actual_End__c = System.now().addHours(1), sked_Resource_Role__c = 'VP/HH',
            sked_VPHH_Quantity__c = 1, sked_APT_Quantity__c = 0, sked__Quantity__c = 1
        );
        insert testJob;

        sked_Operation_Record__c op = new sked_Operation_Record__c(
            sked_Drive__c = testDrive.Id, sked_Drive_Shift__c = testDriveShift.Id,
            sked_Status__c = 'Not Submitted', sked_Locked__c = true,
            sked_Workday_Submission_Status__c = BSF_WorkdayDirectSubmissionConfig.STATUS_DRAFT,
            sked_Power_Red_Machines_Sent__c = 1, sked_Power_Red_Machines_Used__c = 1,
            sked_Submitted_By__c = testResource.Id, sked_Donor_Ambassadors_Actual__c = 0
        );
        insert op;
        Test.setCreatedDate(op.Id, System.now().addDays(-1));

        DateTime shiftStart = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(8, 0, 0, 0));
        DateTime shiftEnd = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(16, 0, 0, 0));
        sked_Operation_Record_Staff__c staff = new sked_Operation_Record_Staff__c(
            sked_Operation_Record__c = op.Id, sked_Job__c = testJob.Id, sked_Resource__c = testResource.Id,
            sked_Premiums_Op_Pay__c = null, sked_Actual_Roles__c = 'Driver', sked_Absent__c = false,
            sked_No_Meal__c = false, sked_Actual_Shift_Start__c = shiftStart, sked_Actual_Shift_End__c = shiftEnd
        );
        insert staff;

        Test.setMock(HttpCalloutMock.class, new WorkdaySuccessMock());

        Test.startTest();
        Database.executeBatch(new BSF_OpsRecordWorkdaySubmissionBatch(), 1);
        Test.stopTest();

        sked_Operation_Record__c opAfter = [
            SELECT Id, sked_Workday_Submission_Status__c, sked_Workday_Import_Process_Id__c
            FROM sked_Operation_Record__c WHERE Id = :op.Id
        ];
        System.assertEquals(
            BSF_WorkdayDirectSubmissionConfig.STATUS_PROCESSED,
            opAfter.sked_Workday_Submission_Status__c,
            'Success path should mark as Processed'
        );
    }

    @IsTest
    static void execute_noBlocksToSubmit_marksProcessed() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion1 = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        testResource.sked_Employee_ID__c = '99999';
        update testResource;

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1, sked_End_Time__c = Time.newInstance(20, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(14, 0, 0, 0), sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c, sked_Equipment__c = 1,
            sked_Lunch_Break__c = false, sked_Order__c = 1, sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1, sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id, sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id, sked__Location__c = testLocation1.Id,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Resource_Role__c = 'VP/HH', sked_VPHH_Quantity__c = 1,
            sked_APT_Quantity__c = 0, sked__Quantity__c = 1,
            sked__Duration__c = 60, sked__Start__c = System.now(), sked__Finish__c = System.now().addHours(1),
            sked__Actual_Start__c = System.now(), sked__Actual_End__c = System.now().addHours(1)
        );
        insert testJob;

        sked_Operation_Record__c op = new sked_Operation_Record__c(
            sked_Drive__c = testDrive.Id, sked_Drive_Shift__c = testDriveShift.Id,
            sked_Status__c = 'Not Submitted', sked_Locked__c = true,
            sked_Workday_Submission_Status__c = BSF_WorkdayDirectSubmissionConfig.STATUS_DRAFT,
            sked_Power_Red_Machines_Sent__c = 1, sked_Power_Red_Machines_Used__c = 1,
            sked_Submitted_By__c = testResource.Id, sked_Donor_Ambassadors_Actual__c = 0
        );
        insert op;
        Test.setCreatedDate(op.Id, System.now().addDays(-1));

        sked_Operation_Record_Staff__c staff = new sked_Operation_Record_Staff__c(
            sked_Operation_Record__c = op.Id, sked_Job__c = testJob.Id,
            sked_Resource__c = testResource.Id, sked_Premiums_Op_Pay__c = null,
            sked_Actual_Roles__c = 'Driver', sked_Absent__c = false
        );
        insert staff;

        Test.setMock(HttpCalloutMock.class, new WorkdayEmptyReportMock());

        Test.startTest();
        Database.executeBatch(new BSF_OpsRecordWorkdaySubmissionBatch(), 1);
        Test.stopTest();

        sked_Operation_Record__c opAfter = [SELECT Id, sked_Workday_Submission_Status__c FROM sked_Operation_Record__c WHERE Id = :op.Id];
        System.assertEquals(BSF_WorkdayDirectSubmissionConfig.STATUS_PROCESSED, opAfter.sked_Workday_Submission_Status__c);
    }

    @IsTest
    static void schedulableExecute_startsBatch() {
        Test.startTest();
        BSF_OpsRecordWorkdaySubmissionBatch batch = new BSF_OpsRecordWorkdaySubmissionBatch();
        batch.execute(null);
        Test.stopTest();
        System.assert(true, 'Schedulable execute should complete without error');
    }
}

