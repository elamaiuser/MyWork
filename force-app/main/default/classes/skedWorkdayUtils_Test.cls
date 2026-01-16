@isTest
private class skedWorkdayUtils_Test {
    @isTest
    static void publishWorkdayApprovalsEvent_Test() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOApprovalMock());
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();
        skedSetting.instance.Admin.workdayIntegration = true;

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource.Id,
            sked__Is_Available__c = false,
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_PENDING,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Time_Off_Reason_Code__c = 'pto-test'
        );
        insert testAvailability;

        Test.startTest();
            testAvailability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PROCESSING_APPROVAL;
            update testAvailability;
        Test.stopTest();
    }

    @isTest
    static void publishWorkdayAdjustmentsEvent_Test() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOAdjustmentMock());
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();
        skedSetting.instance.Admin.workdayIntegration = true;

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource.Id,
            sked__Is_Available__c = false,
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Time_Off_Reason_Code__c = 'pto-test',
            sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_SUCCESS
        );
        insert testAvailability;

        Test.startTest();
            testAvailability.sked__Finish__c = testDataFactory.summary.startTime.addHours(4);
            testAvailability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PROCESSING_ADJUSTMENT;
            update testAvailability;
        Test.stopTest();
    }

    @isTest
    static void publishWorkdayCancellationEvent_Test() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOAdjustmentMock());
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();
        skedSetting.instance.Admin.workdayIntegration = true;

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource.Id,
            sked__Is_Available__c = false,
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Time_Off_Reason_Code__c = 'pto-test',
            sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_SUCCESS
        );
        insert testAvailability;

        Test.startTest();
            testAvailability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_PROCESSING_CANCELLATION;
            update testAvailability;
        Test.stopTest();
    }

    @isTest
    static void publishWorkdayCancellationEvent_Test_Deletion() {
        Test.setMock(HttpCalloutMock.class, new skedWorkdayPTOAdjustmentMock());
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();
        skedSetting.instance.Admin.workdayIntegration = true;

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource.Id,
            sked__Is_Available__c = false,
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(2),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Time_Off_Reason_Code__c = 'pto-test',
            sked_Workday_Sync_Status__c = skedConstants.AVAILABILITY_WORKDAY_SYNC_STATUS_SUCCESS
        );
        insert testAvailability;

        Test.startTest();
            delete testAvailability;
        Test.stopTest();
    }

    @TestSetup
    static void makeData(){
        sked_Event_Type_Setting__c pto = new sked_Event_Type_Setting__c(
            Name = 'PTO',
            sked_Item__c = 'PTO',
            sked_Integrated_with_Workday__c = true,
            sked_Category__c = 'availability'
        );
        insert pto;
    }
    @isTest
static void verifyUnavailabilityBalance_Test() {
    Test.setMock(HttpCalloutMock.class, new skedWorkdayGetPlanBalancesMock());
    skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
    Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();
    skedSetting.instance.Admin.workdayIntegration = true;

    sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

    Test.startTest();
        skedWorkdayUtils.verifyUnavailabilityBalance(
            testResource,
            Date.today(),
            120,
            skedConstants.UNAVAILABILITY_TYPE_PTO
        );
    Test.stopTest();
}

private class skedWorkdayGetPlanBalancesMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<wd:Report_Data xmlns:wd="urn:com.workday.report/Web_Services_Time_Off_Balances_Skedulo">' +
            '  <wd:Report_Entry>' +
            '    <wd:Eligible_Time_Off_Plans_for_Worker_group>' +
            '      <wd:time_off_plan wd:Descriptor="PTO - 7 Day Lag">' +
            '        <wd:ID wd:type="WID">8a81de01e08310a6d89d396076d2dfa9</wd:ID>' +
            '        <wd:ID wd:type="Absence_Plan_ID">PTO - 7 Day Lag</wd:ID>' +
            '      </wd:time_off_plan>' +
            '      <wd:balance>202.46</wd:balance>' +
            '    </wd:Eligible_Time_Off_Plans_for_Worker_group>' +
            '    <wd:All_Eligible_Time_Offs_for_Worker_group>' +
            '      <wd:plan wd:Descriptor="PTO - 7 Day Lag">' +
            '        <wd:ID wd:type="WID">8a81de01e08310a6d89d396076d2dfa9</wd:ID>' +
            '        <wd:ID wd:type="Absence_Plan_ID">PTO - 7 Day Lag</wd:ID>' +
            '      </wd:plan>' +
            '      <wd:Time_Off_Reasons wd:Descriptor="Planned">' +
            '        <wd:ID wd:type="WID">e865d498431c010203429a881a350002</wd:ID>' +
            '        <wd:ID wd:type="Time_Off_Reason_ID">Planned - PTO - 7 Day Lag - Time Off</wd:ID>' +
            '      </wd:Time_Off_Reasons>' +
            '      <wd:Time_Off_Reasons wd:Descriptor="Unplanned">' +
            '        <wd:ID wd:type="WID">e865d498431c010203429a881a350003</wd:ID>' +
            '        <wd:ID wd:type="Time_Off_Reason_ID">Unplanned - PTO - 7 Day Lag - Time Off</wd:ID>' +
            '      </wd:Time_Off_Reasons>' +
            '    </wd:All_Eligible_Time_Offs_for_Worker_group>' +
            '  </wd:Report_Entry>' +
            '</wd:Report_Data>'
        );
        return res;
    }
}

}