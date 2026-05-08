@IsTest
private class BSF_WorkdayOpsRecordDirectService_Test {
    private static String lastRequestBody;

    /**
     * Simple HttpCalloutMock that can serve both the Employee Report (GET) and
     * Import_Reported_Time_Blocks (POST) calls used by the direct service.
     */
    private class WorkdayHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            // Employee Report – GET with format=json
            if (req.getMethod() == 'GET') {
                res.setStatusCode(200);
                // real style payload with one Report_Entry row.
                String body = '{"Report_Entry":[{"Employee_ID":"123","TZ_Reference_id":"US/Eastern"}]}';
                res.setBody(body);
                res.setStatus('OK');
                return res;
            }

            // Import_Reported_Time_Blocks – POST SOAP envelope
            if (req.getMethod() == 'POST') {
                res.setStatusCode(200);
                res.setStatus('OK');
                String body =
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:bsvc="urn:com.workday/bsvc">' +
                        '<soapenv:Body>' +
                            '<bsvc:Put_Import_Process_Response>' +
                                '<bsvc:Import_Process_Reference>' +
                                    '<bsvc:ID>WID-123</bsvc:ID>' +
                                '</bsvc:Import_Process_Reference>' +
                            '</bsvc:Put_Import_Process_Response>' +
                        '</soapenv:Body>' +
                    '</soapenv:Envelope>';
                res.setBody(body);
                return res;
            }

            res.setStatusCode(400);
            res.setStatus('Bad Request');
            res.setBody('Unexpected HTTP method in mock: ' + req.getMethod());
            return res;
        }
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkdayWithLog_parsesResponse() {
        Test.setMock(HttpCalloutMock.class, new WorkdayHttpMock());

        Date driveDate = Date.today();
        List<String> empIds = new List<String>{ '123' };

        Test.startTest();
        BSF_WorkdayOpsRecordDirectService.EmployeeReportResult result =
            BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkdayWithLog(
                'https://example.workday.com/ccx/service/customreport',
                'Start_Date',
                'End_Date',
                'Worker',
                empIds,
                driveDate
            );
        Test.stopTest();

        System.assertEquals(200, result.statusCode, 'Expected 200 from mock Employee Report');
        System.assertEquals('US/Eastern', result.employeeIdToTimezone.get('123'));
        System.assertNotEquals(null, result.requestUrl, 'Request URL should be logged');
        System.assert(result.requestUrl.contains('format=json'));
    }

    @IsTest
    static void submitTimeBlocksToWorkday_successParsesImportProcessId() {
        Test.setMock(HttpCalloutMock.class, new WorkdayHttpMock());

        skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType block =
            new skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType();
        block.Worker_Reference = new skedWorkdayTimeTrackingBsvc.WorkerObjectType();
        block.Worker_Reference.ID = new List<skedWorkdayTimeTrackingBsvc.WorkerObjectIDType>();
        skedWorkdayTimeTrackingBsvc.WorkerObjectIDType workerId =
            new skedWorkdayTimeTrackingBsvc.WorkerObjectIDType();
        workerId.type_x = 'Employee_ID';
        workerId.input = '123';
        block.Worker_Reference.ID.add(workerId);
        block.Date_x = Date.today();
        block.Time_Entry_Code_Reference = new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType();
        block.Time_Entry_Code_Reference.ID = new List<skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType>();
        skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType timeCode =
            new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType();
        timeCode.type_x = 'Time_Code_Reference_ID';
        timeCode.input = 'Time Worked';
        block.Time_Entry_Code_Reference.ID.add(timeCode);

        List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> blocks =
            new List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType>{ block };

        // Provide a single dateTimeFormats map to exercise XML override logic.
        Map<String, String> dtMap = new Map<String, String>{
            'In_Date_Time' => '2026-01-01T08:00:00-05:00',
            'Out_Date_Time' => '2026-01-01T16:00:00-05:00'
        };
        List<Map<String, String>> formats = new List<Map<String, String>>{ dtMap };

        Test.startTest();
        skedWorkdayImportTimeBlockResponse resp =
            BSF_WorkdayOpsRecordDirectService.submitTimeBlocksToWorkday(blocks, formats);
        Test.stopTest();

        System.assertEquals(true, resp.isSuccess, 'Expected Import to succeed in mock');
        System.assertEquals(200, resp.statusCode);
        System.assertEquals('WID-123', resp.importProcessId, 'Should parse Import_Process_Reference WID');
        System.assertNotEquals(null, resp.request, 'SOAP request should be captured on the response object');
        System.assertNotEquals(null, resp.fullSoapRequestXml, 'Full SOAP XML should be available for file logging');
        System.assert(
            resp.fullSoapRequestXml.contains('Import_Reported_Time_Blocks'),
            'Full SOAP should contain Import_Reported_Time_Blocks'
        );
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkdayWithLog_earlyReturnWhenEndpointBlank() {
        BSF_WorkdayOpsRecordDirectService.EmployeeReportResult result =
            BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkdayWithLog(
                '', 'Start', 'End', 'Worker', new List<String>{ '123' }, Date.today()
            );
        System.assertEquals(0, result.statusCode);
        System.assertEquals(true, result.employeeIdToTimezone.isEmpty());
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkdayWithLog_earlyReturnWhenDriveDateNull() {
        BSF_WorkdayOpsRecordDirectService.EmployeeReportResult result =
            BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkdayWithLog(
                'https://example.com', 'Start', 'End', 'Worker', new List<String>{ '123' }, null
            );
        System.assertEquals(0, result.statusCode);
        System.assertEquals(true, result.employeeIdToTimezone.isEmpty());
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkdayWithLog_parsesBareArrayResponse() {
        Test.setMock(HttpCalloutMock.class, new EmployeeReportMock());
        BSF_WorkdayOpsRecordDirectService.EmployeeReportResult result =
            BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkdayWithLog(
                'https://example.com/report', 'Start', 'End', null, new List<String>(), Date.today()
            );
        System.assertEquals(200, result.statusCode);
        System.assertEquals('US/Pacific', result.employeeIdToTimezone.get('999'));
    }

    @IsTest
    static void submitTimeBlocksToWorkday_emptyBlocksReturnsFailure() {
        skedWorkdayImportTimeBlockResponse resp =
            BSF_WorkdayOpsRecordDirectService.submitTimeBlocksToWorkday(new List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType>(), null);
        System.assertEquals(false, resp.isSuccess);
        System.assert(resp.message.contains('No time blocks'));
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkdayWithLog_singleReportEntryMap() {
        Test.setMock(HttpCalloutMock.class, new SingleReportEntryMock());
        Test.startTest();
        BSF_WorkdayOpsRecordDirectService.EmployeeReportResult result =
            BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkdayWithLog(
                'https://example.com', 'Start', 'End', 'Worker', new List<String>{ '111' }, Date.today()
            );
        Test.stopTest();
        System.assertEquals(200, result.statusCode);
        System.assertEquals('America/Chicago', result.employeeIdToTimezone.get('111'));
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkdayWithLog_noReportEntryKey() {
        Test.setMock(HttpCalloutMock.class, new NoReportEntryMock());
        Test.startTest();
        BSF_WorkdayOpsRecordDirectService.EmployeeReportResult result =
            BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkdayWithLog(
                'https://example.com', 'Start', 'End', null, new List<String>(), Date.today()
            );
        Test.stopTest();
        System.assertEquals(200, result.statusCode);
        System.assertEquals(true, result.employeeIdToTimezone.isEmpty());
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkdayWithLog_tzFallbackToPacific() {
        Test.setMock(HttpCalloutMock.class, new BlankTimezoneMock());
        Test.startTest();
        BSF_WorkdayOpsRecordDirectService.EmployeeReportResult result =
            BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkdayWithLog(
                'https://example.com', 'Start', 'End', null, new List<String>(), Date.today()
            );
        Test.stopTest();
        System.assertEquals(200, result.statusCode);
        System.assertEquals('America/Los_Angeles', result.employeeIdToTimezone.get('555'));
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkdayWithLog_non200ReturnsEmpty() {
        Test.setMock(HttpCalloutMock.class, new Non200Mock());
        Test.startTest();
        BSF_WorkdayOpsRecordDirectService.EmployeeReportResult result =
            BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkdayWithLog(
                'https://example.com', 'Start', 'End', null, new List<String>(), Date.today()
            );
        Test.stopTest();
        System.assertEquals(500, result.statusCode);
        System.assertEquals(true, result.employeeIdToTimezone.isEmpty());
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkday_mapVersion() {
        Test.setMock(HttpCalloutMock.class, new WorkdayHttpMock());
        Test.startTest();
        Map<String, String> result = BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkday(
            'https://example.com/report', 'Start', 'End', 'Worker',
            new List<String>{ '123' }, Date.today()
        );
        Test.stopTest();
        System.assertEquals('US/Eastern', result.get('123'));
    }

    @IsTest
    static void getEmployeesWithoutTimeInWorkday_urlWithExistingQuery() {
        Test.setMock(HttpCalloutMock.class, new WorkdayHttpMock());
        Test.startTest();
        Map<String, String> result = BSF_WorkdayOpsRecordDirectService.getEmployeesWithoutTimeInWorkday(
            'https://example.com?existing=1', 'Start', 'End', 'Worker',
            new List<String>{ '123' }, Date.today()
        );
        Test.stopTest();
        System.assert(result.containsKey('123'));
    }

    private class EmployeeReportMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"Employee_ID":"999","TZ_Reference_Id":"US/Pacific"}]');
            return res;
        }
    }

    private class SingleReportEntryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Report_Entry":{"Employee_ID":"111","TZ_Reference_Id":"America/Chicago"}}');
            return res;
        }
    }

    private class NoReportEntryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Other_Key":[]}');
            return res;
        }
    }

    private class BlankTimezoneMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Report_Entry":[{"Employee_ID":"555"}]}');
            return res;
        }
    }

    private class Non200Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Server Error');
            return res;
        }
    }

    private class CaptureImportRequestMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'POST') {
                lastRequestBody = req.getBody();
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody(
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:bsvc="urn:com.workday/bsvc">' +
                        '<soapenv:Body>' +
                            '<bsvc:Put_Import_Process_Response>' +
                                '<bsvc:Import_Process_Reference>' +
                                    '<bsvc:ID>WID-456</bsvc:ID>' +
                                '</bsvc:Import_Process_Reference>' +
                            '</bsvc:Put_Import_Process_Response>' +
                        '</soapenv:Body>' +
                    '</soapenv:Envelope>'
                );
                return res;
            }
            res.setStatusCode(400);
            res.setStatus('Bad Request');
            res.setBody('Unexpected method: ' + req.getMethod());
            return res;
        }
    }

    @IsTest
    static void submitTimeBlocksToWorkday_appliesFormatsOnlyToTimeWorkedBlocks() {
        lastRequestBody = null;
        Test.setMock(HttpCalloutMock.class, new CaptureImportRequestMock());

        skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType base1 =
            new skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType();
        base1.Worker_Reference = new skedWorkdayTimeTrackingBsvc.WorkerObjectType();
        base1.Worker_Reference.ID = new List<skedWorkdayTimeTrackingBsvc.WorkerObjectIDType>();
        skedWorkdayTimeTrackingBsvc.WorkerObjectIDType base1WorkerId =
            new skedWorkdayTimeTrackingBsvc.WorkerObjectIDType();
        base1WorkerId.type_x = 'Employee_ID';
        base1WorkerId.input = '1001';
        base1.Worker_Reference.ID.add(base1WorkerId);
        base1.Date_x = Date.newInstance(2026, 4, 10);
        base1.Time_Entry_Code_Reference = new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType();
        base1.Time_Entry_Code_Reference.ID = new List<skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType>();
        skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType base1Code =
            new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType();
        base1Code.type_x = 'Time_Code_Reference_ID';
        base1Code.input = 'Time Worked';
        base1.Time_Entry_Code_Reference.ID.add(base1Code);
        base1.In_Date_Time = DateTime.newInstanceGmt(2026, 4, 10, 11, 24, 0);
        base1.Out_Date_Time = DateTime.newInstanceGmt(2026, 4, 10, 18, 52, 0);

        skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType premium =
            new skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType();
        premium.Worker_Reference = new skedWorkdayTimeTrackingBsvc.WorkerObjectType();
        premium.Worker_Reference.ID = new List<skedWorkdayTimeTrackingBsvc.WorkerObjectIDType>();
        skedWorkdayTimeTrackingBsvc.WorkerObjectIDType premiumWorkerId =
            new skedWorkdayTimeTrackingBsvc.WorkerObjectIDType();
        premiumWorkerId.type_x = 'Employee_ID';
        premiumWorkerId.input = '1002';
        premium.Worker_Reference.ID.add(premiumWorkerId);
        premium.Date_x = Date.newInstance(2026, 4, 10);
        premium.Time_Entry_Code_Reference = new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType();
        premium.Time_Entry_Code_Reference.ID = new List<skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType>();
        skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType premiumCode =
            new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType();
        premiumCode.type_x = 'Time_Code_Reference_ID';
        premiumCode.input = 'Charge';
        premium.Time_Entry_Code_Reference.ID.add(premiumCode);
        premium.Quantity = 1;

        skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType base2 =
            new skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType();
        base2.Worker_Reference = new skedWorkdayTimeTrackingBsvc.WorkerObjectType();
        base2.Worker_Reference.ID = new List<skedWorkdayTimeTrackingBsvc.WorkerObjectIDType>();
        skedWorkdayTimeTrackingBsvc.WorkerObjectIDType base2WorkerId =
            new skedWorkdayTimeTrackingBsvc.WorkerObjectIDType();
        base2WorkerId.type_x = 'Employee_ID';
        base2WorkerId.input = '1003';
        base2.Worker_Reference.ID.add(base2WorkerId);
        base2.Date_x = Date.newInstance(2026, 4, 10);
        base2.Time_Entry_Code_Reference = new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType();
        base2.Time_Entry_Code_Reference.ID = new List<skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType>();
        skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType base2Code =
            new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType();
        base2Code.type_x = 'Time_Code_Reference_ID';
        base2Code.input = 'Time Worked';
        base2.Time_Entry_Code_Reference.ID.add(base2Code);
        base2.In_Date_Time = DateTime.newInstanceGmt(2026, 4, 11, 12, 0, 0);
        base2.Out_Date_Time = DateTime.newInstanceGmt(2026, 4, 11, 20, 0, 0);

        List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> blocks =
            new List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType>{ base1, premium, base2 };
        List<Map<String, String>> formats = new List<Map<String, String>>{
            new Map<String, String>{
                'In_Date_Time' => '2026-04-10T06:24:00-05:00',
                'Out_Date_Time' => '2026-04-10T13:52:00-05:00'
            },
            new Map<String, String>{
                'In_Date_Time' => '2026-04-11T07:00:00-05:00',
                'Out_Date_Time' => '2026-04-11T15:00:00-05:00'
            }
        };

        Test.startTest();
        skedWorkdayImportTimeBlockResponse resp =
            BSF_WorkdayOpsRecordDirectService.submitTimeBlocksToWorkday(blocks, formats);
        Test.stopTest();

        System.assertEquals(true, resp.isSuccess, 'Expected Import to succeed in mock');
        System.assertNotEquals(null, lastRequestBody, 'Request body should be captured');
        System.assert(lastRequestBody.contains('<ID bsvc:type="Time_Code_Reference_ID">Charge</ID>'),
            'Premium block should remain in the payload');
        System.assert(lastRequestBody.contains('<In_Date_Time>2026-04-10T06:24:00-05:00</In_Date_Time>'),
            'First Time Worked block should get first override');
        System.assert(lastRequestBody.contains('<Out_Date_Time>2026-04-10T13:52:00-05:00</Out_Date_Time>'),
            'First Time Worked block should get first out override');
        System.assert(lastRequestBody.contains('<In_Date_Time>2026-04-11T07:00:00-05:00</In_Date_Time>'),
            'Second Time Worked block should get second override even after premium block');
        System.assert(lastRequestBody.contains('<Out_Date_Time>2026-04-11T15:00:00-05:00</Out_Date_Time>'),
            'Second Time Worked block should get second out override even after premium block');
    }
}