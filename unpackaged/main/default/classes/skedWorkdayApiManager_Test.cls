@isTest
private class skedWorkdayApiManager_Test {
    @isTest
    static void processTimeOffApproval_Test() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOApprovalMock());
        skedWorkdayApiManager.processTimeOffRequest ptoReq = new skedWorkdayApiManager.processTimeOffRequest();
        ptoReq.employeeId = '123123';
        ptoReq.comment = 'unit test';
        ptoReq.hoursRequested = '8.00';
        ptoReq.ptoDate = System.today().addDays(10);
        ptoReq.ptoEntryId = 'unit-test-id';
        ptoReq.ptoReason = skedConstants.WD_PTO_7_DAY_LAG_ID;
        
        Test.startTest(); 
            skedWorkdayApiManager.processTimeOffResponse ptoRes = skedWorkdayApiManager.processTimeOffApproval(ptoReq);
        Test.stopTest();

        System.assert(ptoRes.isSuccess);
    } 

    @isTest
    static void processTimeOff_Invalid_Test() {
        String testError = 'Test Error Response';
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOApprovalMock(testError));
        skedWorkdayApiManager.processTimeOffRequest ptoReq = new skedWorkdayApiManager.processTimeOffRequest();
        ptoReq.employeeId = '123123';
        ptoReq.comment = 'unit test';
        ptoReq.hoursRequested = '8.00';
        ptoReq.ptoDate = System.today().addDays(10);
        ptoReq.ptoEntryId = 'unit-test-id';
        ptoReq.ptoReason = skedConstants.WD_PTO_7_DAY_LAG_ID;
        
        Test.startTest(); 
            skedWorkdayApiManager.processTimeOffResponse ptoRes = skedWorkdayApiManager.processTimeOffApproval(ptoReq);
        Test.stopTest();

        System.assert(!ptoRes.isSuccess);
        System.assertEquals(testError, ptoRes.faultString);
    }

    @isTest
    static void getTimeOffReport_Test() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOReportMock());
        skedWorkdayApiManager.getTimeOffReportRequest ptoRepReq = new skedWorkdayApiManager.getTimeOffReportRequest();
        ptoRepReq.employeeId = '123123';
        ptoRepReq.selectedYear = System.today().year();

        Test.startTest();
            skedWorkdayApiManager.getTimeOffReportResponse ptoRepRes = skedWorkdayApiManager.getTimeOffReport(ptoRepReq);
        Test.stopTest();

        System.assert(!ptoRepRes.timeOffReports.isEmpty());
    }

    @isTest
    static void getTimeOffPlanBalances_Test() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOBalanceMock());
        skedWorkdayApiManager.getTimeOffPlanBalancesRequest ptoBalReq = new skedWorkdayApiManager.getTimeOffPlanBalancesRequest();
        ptoBalReq.employeeId = '123123';
        ptoBalReq.selectedYear = System.today().year();

        Test.startTest();
            skedWorkdayApiManager.getTimeOffPlanBalancesResponse ptoBalRes = skedWorkdayApiManager.getTimeOffPlanBalances(ptoBalReq);
        Test.stopTest();

        System.assertNotEquals(null, ptoBalRes.pto);
        System.assertNotEquals(null, ptoBalRes.floatingHoliday);
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }
}