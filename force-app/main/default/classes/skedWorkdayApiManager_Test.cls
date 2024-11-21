@isTest
private class skedWorkdayApiManager_Test {
    @isTest
    static void enterTimeOff_Test() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOApprovalMock());
        skedWorkdayEnterTimeOffRequest ptoReq = new skedWorkdayEnterTimeOffRequest();
        skedWorkdayEnterTimeOffRequest.skedWorkdayTimeOffEntry timeOffEntry = new skedWorkdayEnterTimeOffRequest.skedWorkdayTimeOffEntry();
        ptoReq.employeeId = '123123';
        timeOffEntry.comment = 'unit test';
        timeOffEntry.hoursRequested = 8.00;
        timeOffEntry.ptoDate = System.today().addDays(10);
        timeOffEntry.ptoEntryId = 'unit-test-id';
        timeOffEntry.timeOffType = 'PTO';
        timeOffEntry.ptoReason = 'PTO - 7 Day Lag - Time Off - Planned';
        ptoReq.timeOffEntries.add(timeOffEntry);
        
        Test.startTest(); 
            skedWorkdayEnterTimeOffResponse ptoRes = skedWorkdayApiManager.enterTimeOff(ptoReq);
        Test.stopTest();

        System.assert(ptoRes.isSuccess, ptoRes);
    } 

    @isTest
    static void processTimeOff_Invalid_Test() {
        String testError = 'Test Error Response';
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOApprovalMock(testError));
        skedWorkdayEnterTimeOffRequest ptoReq = new skedWorkdayEnterTimeOffRequest();
        skedWorkdayEnterTimeOffRequest.skedWorkdayTimeOffEntry timeOffEntry = new skedWorkdayEnterTimeOffRequest.skedWorkdayTimeOffEntry();
        ptoReq.employeeId = '123123';
        timeOffEntry.comment = 'unit test';
        timeOffEntry.hoursRequested = 8.00;
        timeOffEntry.ptoDate = System.today().addDays(10);
        timeOffEntry.ptoEntryId = 'unit-test-id';
        timeOffEntry.ptoReason = 'Planned';
        timeOffEntry.timeOffType = 'PTO';
        ptoReq.timeOffEntries.add(timeOffEntry);
        
        Test.startTest(); 
            skedWorkdayEnterTimeOffResponse ptoRes = skedWorkdayApiManager.enterTimeOff(ptoReq);
        Test.stopTest();

        System.assert(!ptoRes.isSuccess);
    }

    @isTest
    static void adjustTimeOff_Test() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOAdjustmentMock());
        skedWorkdayAdjustTimeOffRequest adjustPtoReq = new skedWorkdayAdjustTimeOffRequest();
        skedWorkdayAdjustTimeOffRequest.skedWorkdayAdjustTimeOffEntry adjustPtoEntry = new skedWorkdayAdjustTimeOffRequest.skedWorkdayAdjustTimeOffEntry();
        adjustPtoReq.employeeId = '123123';
        adjustPtoEntry.comment = 'unit test';
        adjustPtoEntry.adjustment = -8.00;
        adjustPtoEntry.ptoEntryId = 'unit-test-id';
        adjustPtoReq.adjustTimeOffEntries.add(adjustPtoEntry);
        
        Test.startTest(); 
            skedWorkdayAdjustTimeOffResponse ptoRes = skedWorkdayApiManager.adjustTimeOff(adjustPtoReq);
        Test.stopTest();

        System.assert(ptoRes.isSuccess, ptoRes);
    } 

    @isTest
    static void adjustTimeOff_Invalid_Test() {
        String testError = 'Test Error Response';
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOAdjustmentMock(testError));
        skedWorkdayAdjustTimeOffRequest adjustPtoReq = new skedWorkdayAdjustTimeOffRequest();
        skedWorkdayAdjustTimeOffRequest.skedWorkdayAdjustTimeOffEntry adjustPtoEntry = new skedWorkdayAdjustTimeOffRequest.skedWorkdayAdjustTimeOffEntry();
        adjustPtoReq.employeeId = '123123';
        adjustPtoEntry.comment = 'unit test';
        adjustPtoEntry.adjustment = -8.00;
        adjustPtoEntry.ptoEntryId = 'unit-test-id';
        adjustPtoReq.adjustTimeOffEntries.add(adjustPtoEntry);
        
        Test.startTest(); 
            skedWorkdayAdjustTimeOffResponse ptoRes = skedWorkdayApiManager.AdjustTimeOff(adjustPtoReq);
        Test.stopTest();

        System.assert(!ptoRes.isSuccess);
    }

    @isTest
    static void getTimeOffPlanBalances_Test() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOBalanceMock());
        skedWorkdayGetPlanBalanceRequest ptoBalReq = new skedWorkdayGetPlanBalanceRequest();
        ptoBalReq.employeeId = '123123';
        ptoBalReq.selectedDate = System.today();

        Test.startTest();
            skedWorkdayGetPlanBalanceResponse ptoBalRes = skedWorkdayApiManager.getTimeOffPlanBalances(ptoBalReq);
        Test.stopTest();

        Assert.isNotNull(ptoBalRes.timeOffPlansByLabel);
        Assert.isNotNull(ptoBalRes.totalBalance);
    }

    @isTest
    static void importReportedTimeBlocks_Test() {
        sked__Resource__c testResource = [SELECT Id, sked_Employee_Id__c FROM sked__Resource__c LIMIT 1][0];

        Test.setMock(HttpCalloutMock.class, new skedImportReportedTimeBlocksMock());
        List<skedWorkdayImportTimeBlockRequest> requests = new List<skedWorkdayImportTimeBlockRequest>();
        requests.add(new skedWorkdayImportTimeBlockRequest(
            testResource.Id,
            testResource.sked_Employee_Id__c,
            'Traded Shift',
            'jkittridge@skedulo.com',
            1,
            System.today().addDays(-1)
        ));

        Test.startTest();
            skedWorkdayImportTimeBlockResponse timeBlockRes = skedWorkdayApiManager.ImportReportedTimeBlocks(requests);
        Test.stopTest();
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }
}