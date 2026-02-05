@isTest
private class slwcDriveShiftTradeService_Test {

    static testmethod void testTradeDriveShift() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        skedHubBase.setBypassAllTriggers(true);
        sked_Drive__c testDrive2 = testDrive1.clone();
        insert testDrive2;
        
        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
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
        driveShifts.add(driveShift1);
        
        sked_Drive_Shift__c driveShift2 = driveShift1.clone();
        driveShifts.add(driveShift2);
        
        insert driveShifts;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job1);
        
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Shift__c = driveShift2.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job2);
        insert jobs;
        
		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Guarded__c = true
        );
        jobAllocations.add(testResource1_job1);
        sked__Job_Allocation__c testResource2_job2 = new sked__Job_Allocation__c(
        	sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Guarded__c = true
        );
        jobAllocations.add(testResource2_job2);
        insert jobAllocations;
        
        skedHubBase.setBypassAllTriggers(false);
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        slwcDriveShiftTradeService.validateShiftTradesRequestModel validateRequest = new slwcDriveShiftTradeService.validateShiftTradesRequestModel();
        slwcDriveShiftTradeService.driveShiftTradeModel request = new slwcDriveShiftTradeService.driveShiftTradeModel();
        validateRequest.shiftTrades = new List<slwcDriveShiftTradeService.driveShiftTradeModel>{request};
        request.requestingStaffId = testResource1.Id;
        request.requestingStaffJobAllocationId = testResource1_job1.Id;
        request.requestingStaffTradingType = 'Drive Shift';
        request.tradingStaffId = testResource2.Id;
        request.tradingStaffJobAllocationId = testResource2_job2.Id;
        request.tradingStaffTradingType = 'Drive Shift';
        slwcAuraResult validateResult = slwcDriveShiftTradeService.validateShiftTrades(validateRequest);
        System.assertNotEquals(null, validateResult, 'Validate result should not be null');

        sked_Drive_Shift_Trade__c driveShiftTrade = new sked_Drive_Shift_Trade__c(
            sked_APS_Notes__c = 'note',
            sked_Auto_process_Complete__c = TRUE,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Contact_Method__c = 'Email',
            sked_Date_Trade_Approved__c = System.now(),
            sked_Denied_Reason__c = '',
            sked_GuaranteedMinHrsForfeited_Requester__c = TRUE,
            sked_GuaranteedMinHrsForfeited_Trading__c = TRUE,
            sked_Reason_Approval_Required__c = '',
            sked_Reason_For_Trade__c = 'n/a',
            sked_RequestingStaffScheduledHoursAfter__c = 1,
            sked_RequestingStaffScheduledHoursBefore__c = 1,
            sked_RequestingStaffTravelDistanceAfter__c = 1,
            sked_RequestingStaffTravelDistanceBefore__c = 1,
            sked_Requesting_Staff_Drive_Date__c = System.today(),
            sked_Requesting_Staff_Drive_Name__c = '',
            sked_Requesting_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Trading_Staff_Drive__c = testDrive1.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );
        
        sked_Drive_Shift_Trade__c duplicateRequest = new sked_Drive_Shift_Trade__c(
            sked_APS_Notes__c = 'note',
            sked_Auto_process_Complete__c = TRUE,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Contact_Method__c = 'Email',
            sked_Date_Trade_Approved__c = System.now(),
            sked_Denied_Reason__c = '',
            sked_GuaranteedMinHrsForfeited_Requester__c = TRUE,
            sked_GuaranteedMinHrsForfeited_Trading__c = TRUE,
            sked_Reason_Approval_Required__c = '',
            sked_Reason_For_Trade__c = 'n/a',
            sked_RequestingStaffScheduledHoursAfter__c = 1,
            sked_RequestingStaffScheduledHoursBefore__c = 1,
            sked_RequestingStaffTravelDistanceAfter__c = 1,
            sked_RequestingStaffTravelDistanceBefore__c = 1,
            sked_Requesting_Staff_Drive_Date__c = System.today(),
            sked_Requesting_Staff_Drive_Name__c = '',
            sked_Requesting_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Trading_Staff_Drive__c = testDrive1.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );
        insert new List<SObject> {driveShiftTrade, duplicateRequest};
        Test.stopTest();

        driveShiftTrade.sked_Reason_Approval_Required__c = skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_TAT_CONTENTION;
        driveShiftTrade.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_PENDING_APPROVAL;
        update driveShiftTrade;

        driveShiftTrade.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED;
        update driveShiftTrade;

        // Verify the trade was updated
        sked_Drive_Shift_Trade__c updatedTrade = [SELECT Id, sked_Status__c FROM sked_Drive_Shift_Trade__c WHERE Id = :driveShiftTrade.Id];
        System.assertEquals(skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED, updatedTrade.sked_Status__c, 'Trade status should be Approved');
    }

    static testmethod void testAutoProcessRequest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        skedHubBase.setBypassAllTriggers(true);
        sked_Resource_Hours_Record__c rhr1 = new sked_Resource_Hours_Record__c();
		rhr1.sked_Resource__c = testResource1.id;
		rhr1.sked_Start_Date__c = testDataFactory.summary.startDate;
		rhr1.sked_End_Date__c = testDataFactory.summary.startDate.addDays(7);

        sked_Resource_Hours_Record__c rhr2 = new sked_Resource_Hours_Record__c();
		rhr2.sked_Resource__c = testResource2.id;
		rhr2.sked_Start_Date__c = testDataFactory.summary.startDate;
		rhr2.sked_End_Date__c = testDataFactory.summary.startDate.addDays(7);
		insert new List<SObject> {rhr1, rhr2};

        sked_Resource_Hours_Record_Detail__c rhrd1 = new sked_Resource_Hours_Record_Detail__c();
        rhrd1.sked_Resource_Hours_Record__c = rhr1.id;
        rhrd1.sked_Duration__c = 35;

        sked_Resource_Hours_Record_Detail__c rhrd2 = new sked_Resource_Hours_Record_Detail__c();
        rhrd2.sked_Resource_Hours_Record__c = rhr2.id;
        rhrd2.sked_Duration__c = 36;
        insert new List<sObject>{rhrd1, rhrd2};

        sked_Drive__c testDrive2 = testDrive1.clone();
        insert testDrive2;
        
        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
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
        driveShifts.add(driveShift1);
        
        sked_Drive_Shift__c driveShift2 = driveShift1.clone();
        driveShifts.add(driveShift2);
        
        insert driveShifts;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job1);
        
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Shift__c = driveShift2.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job2);
        insert jobs;
        
		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_GeoService_Travel_Distance_To__c = 5,
            sked_GeoService_Travel_Distance_Back__c = 6,
            sked_Travel_Time_To__c = 7,
            sked_Travel_Time_Back__c = 8
        );
        jobAllocations.add(testResource1_job1);
        sked__Job_Allocation__c testResource2_job2 = new sked__Job_Allocation__c(
        	sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_GeoService_Travel_Distance_To__c = 5,
            sked_GeoService_Travel_Distance_Back__c = 6,
            sked_Travel_Time_To__c = 7,
            sked_Travel_Time_Back__c = 8
        );
        jobAllocations.add(testResource2_job2);
        insert jobAllocations;
        

        sked_Drive_Shift_Trade__c driveShiftTrade = new sked_Drive_Shift_Trade__c(
            sked_APS_Notes__c = 'note',
            sked_Auto_process_Complete__c = TRUE,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Contact_Method__c = 'Email',
            sked_Date_Trade_Approved__c = System.now(),
            sked_Denied_Reason__c = '',
            sked_GuaranteedMinHrsForfeited_Requester__c = TRUE,
            sked_GuaranteedMinHrsForfeited_Trading__c = TRUE,
            sked_Reason_Approval_Required__c = '',
            sked_Reason_For_Trade__c = 'n/a',
            sked_RequestingStaffScheduledHoursAfter__c = 1,
            sked_RequestingStaffScheduledHoursBefore__c = 1,
            sked_RequestingStaffTravelDistanceAfter__c = 1,
            sked_RequestingStaffTravelDistanceBefore__c = 1,
            sked_Requesting_Staff_Drive_Date__c = System.today(),
            sked_Requesting_Staff_Drive_Name__c = '',
            sked_Requesting_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Trading_Staff_Drive__c = testDrive1.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );

        insert new List<SObject> {driveShiftTrade};
        skedHubBase.setBypassAllTriggers(false);
        Test.stopTest();

        skedHubBase.setBypassAllTriggers(true);
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        slwcDriveShiftTradeService.driveShiftTradeModel request = new slwcDriveShiftTradeService.driveShiftTradeModel();
        request.requestingStaffId = testResource1.Id;
        request.requestingStaffJobAllocationId = testResource1_job1.Id;
        request.requestingStaffTradingType = 'Drive Shift';
        request.tradingStaffId = testResource2.Id;
        request.tradingStaffJobAllocationId = testResource2_job2.Id;
        request.tradingStaffTradingType = 'Drive Shift';
        request.id = driveShiftTrade.Id;
        slwcAuraResult result = slwcDriveShiftTradeService.autoProcessRequest(request);
        skedHubBase.setBypassAllTriggers(false);
        System.assertEquals(true, result.success);
    }

    static testmethod void testAutoProcessRequestDuplicateTrades() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        skedHubBase.setBypassAllTriggers(true);
        sked_Resource_Hours_Record__c rhr1 = new sked_Resource_Hours_Record__c();
		rhr1.sked_Resource__c = testResource1.id;
		rhr1.sked_Start_Date__c = testDataFactory.summary.startDate;
		rhr1.sked_End_Date__c = testDataFactory.summary.startDate.addDays(7);

        sked_Resource_Hours_Record__c rhr2 = new sked_Resource_Hours_Record__c();
		rhr2.sked_Resource__c = testResource2.id;
		rhr2.sked_Start_Date__c = testDataFactory.summary.startDate;
		rhr2.sked_End_Date__c = testDataFactory.summary.startDate.addDays(7);
		insert new List<SObject> {rhr1, rhr2};

        sked_Resource_Hours_Record_Detail__c rhrd1 = new sked_Resource_Hours_Record_Detail__c();
        rhrd1.sked_Resource_Hours_Record__c = rhr1.id;
        rhrd1.sked_Duration__c = 35;

        sked_Resource_Hours_Record_Detail__c rhrd2 = new sked_Resource_Hours_Record_Detail__c();
        rhrd2.sked_Resource_Hours_Record__c = rhr2.id;
        rhrd2.sked_Duration__c = 36;
        insert new List<sObject>{rhrd1, rhrd2};

        sked_Drive__c testDrive2 = testDrive1.clone();
        insert testDrive2;
        
        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
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
        driveShifts.add(driveShift1);
        
        sked_Drive_Shift__c driveShift2 = driveShift1.clone();
        driveShifts.add(driveShift2);
        
        insert driveShifts;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job1);
        
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Shift__c = driveShift2.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job2);
        insert jobs;
        
		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job1);
        sked__Job_Allocation__c testResource2_job2 = new sked__Job_Allocation__c(
        	sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource2_job2);
        insert jobAllocations;

        sked_Drive_Shift_Trade__c driveShiftTrade = new sked_Drive_Shift_Trade__c(
            sked_APS_Notes__c = 'note',
            sked_Auto_process_Complete__c = TRUE,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Contact_Method__c = 'Email',
            sked_Date_Trade_Approved__c = System.now(),
            sked_Denied_Reason__c = '',
            sked_GuaranteedMinHrsForfeited_Requester__c = TRUE,
            sked_GuaranteedMinHrsForfeited_Trading__c = TRUE,
            sked_Reason_Approval_Required__c = '',
            sked_Reason_For_Trade__c = 'n/a',
            sked_RequestingStaffScheduledHoursAfter__c = 1,
            sked_RequestingStaffScheduledHoursBefore__c = 1,
            sked_RequestingStaffTravelDistanceAfter__c = 1,
            sked_RequestingStaffTravelDistanceBefore__c = 1,
            sked_Requesting_Staff_Drive_Date__c = System.today(),
            sked_Requesting_Staff_Drive_Name__c = '',
            sked_Requesting_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Trading_Staff_Drive__c = testDrive1.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );
        
        sked_Drive_Shift_Trade__c duplicateRequest = new sked_Drive_Shift_Trade__c(
            sked_APS_Notes__c = 'note',
            sked_Auto_process_Complete__c = TRUE,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Contact_Method__c = 'Email',
            sked_Date_Trade_Approved__c = System.now(),
            sked_Denied_Reason__c = '',
            sked_GuaranteedMinHrsForfeited_Requester__c = TRUE,
            sked_GuaranteedMinHrsForfeited_Trading__c = TRUE,
            sked_Reason_Approval_Required__c = '',
            sked_Reason_For_Trade__c = 'n/a',
            sked_RequestingStaffScheduledHoursAfter__c = 1,
            sked_RequestingStaffScheduledHoursBefore__c = 1,
            sked_RequestingStaffTravelDistanceAfter__c = 1,
            sked_RequestingStaffTravelDistanceBefore__c = 1,
            sked_Requesting_Staff_Drive_Date__c = System.today(),
            sked_Requesting_Staff_Drive_Name__c = '',
            sked_Requesting_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Trading_Staff_Drive__c = testDrive1.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );
        insert new List<SObject> {driveShiftTrade, duplicateRequest};
        skedHubBase.setBypassAllTriggers(false);
        Test.stopTest();

        skedHubBase.setBypassAllTriggers(true);
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        slwcDriveShiftTradeService.driveShiftTradeModel request = new slwcDriveShiftTradeService.driveShiftTradeModel();
        request.requestingStaffId = testResource1.Id;
        request.requestingStaffJobAllocationId = testResource1_job1.Id;
        request.requestingStaffTradingType = 'Drive Shift';
        request.tradingStaffId = testResource2.Id;
        request.tradingStaffJobAllocationId = testResource2_job2.Id;
        request.tradingStaffTradingType = 'Drive Shift';
        request.id = driveShiftTrade.Id;
        slwcAuraResult result = slwcDriveShiftTradeService.autoProcessRequest(request);
        skedHubBase.setBypassAllTriggers(false);
        System.assertEquals(true, result.success);
    }
    
    static testmethod void testTradeNCE() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');

        Test.startTest();
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked_Drive__c testDrive2 = testDrive1.clone();
        insert testDrive2;

        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');

        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');

        List<sked__Activity__c> activities = new List<sked__Activity__c>();
        sked__Activity__c skedGroupActivity1 = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = activityTypes.get(0),
        	sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE
        );
        activities.add(skedGroupActivity1);

        sked__Activity__c skedGroupActivity2 = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = activityTypes.get(0),
        	sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE
        );
        activities.add(skedGroupActivity2);

        insert activities;

        List<sked__Activity_Resource__c> activityResources = new List<sked__Activity_Resource__c>();
        sked__Activity_Resource__c skedActivityResource1 = new sked__Activity_Resource__c(
        	sked__Activity__c = skedGroupActivity1.Id,
            sked__Resource__c = testResource1.Id
        );
        activityResources.add(skedActivityResource1);

        sked__Activity_Resource__c skedActivityResource2 = new sked__Activity_Resource__c(
        	sked__Activity__c = skedGroupActivity2.Id,
            sked__Resource__c = testResource2.Id
        );
        activityResources.add(skedActivityResource2);

        insert activityResources;

        sked_Drive_Shift_Trade__c driveShiftTrade = new sked_Drive_Shift_Trade__c(
            sked_APS_Notes__c = 'note',
            sked_Auto_process_Complete__c = TRUE,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Contact_Method__c = 'Email',
            sked_Date_Trade_Approved__c = System.now(),
            sked_Denied_Reason__c = '',
            sked_GuaranteedMinHrsForfeited_Requester__c = TRUE,
            sked_GuaranteedMinHrsForfeited_Trading__c = TRUE,
            sked_Reason_Approval_Required__c = '',
            sked_Reason_For_Trade__c = 'n/a',
            sked_RequestingStaffScheduledHoursAfter__c = 1,
            sked_RequestingStaffScheduledHoursBefore__c = 1,
            sked_RequestingStaffTravelDistanceAfter__c = 1,
            sked_RequestingStaffTravelDistanceBefore__c = 1,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_NCE__c = skedGroupActivity1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Activity',
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_NCE__c = skedGroupActivity2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Activity'
        );
        insert driveShiftTrade;

        driveShiftTrade.sked_Reason_Approval_Required__c = skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_TAT_CONTENTION;
        driveShiftTrade.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_PENDING_APPROVAL;
        update driveShiftTrade;

        driveShiftTrade.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED;
        update driveShiftTrade;

        // Verify the trade was updated
        sked_Drive_Shift_Trade__c updatedTrade = [SELECT Id, sked_Status__c FROM sked_Drive_Shift_Trade__c WHERE Id = :driveShiftTrade.Id];
        System.assertEquals(skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED, updatedTrade.sked_Status__c, 'Trade status should be Approved');

        Test.stopTest();
    }

    static testmethod void testPerformShiftTrades() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        skedHubBase.setBypassAllTriggers(true);
        sked_Drive__c testDrive2 = testDrive1.clone();
        insert testDrive2;

        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
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
        driveShifts.add(driveShift1);

        sked_Drive_Shift__c driveShift2 = driveShift1.clone();
        driveShifts.add(driveShift2);

        insert driveShifts;

        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job1);

        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Shift__c = driveShift2.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job2);
        insert jobs;

		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Guarded__c = true
        );
        jobAllocations.add(testResource1_job1);
        sked__Job_Allocation__c testResource2_job2 = new sked__Job_Allocation__c(
        	sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Guarded__c = true
        );
        jobAllocations.add(testResource2_job2);
        insert jobAllocations;

        sked_Drive_Shift_Trade__c driveShiftTrade = new sked_Drive_Shift_Trade__c(
            sked_APS_Notes__c = 'note',
            sked_Auto_process_Complete__c = TRUE,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Contact_Method__c = 'Email',
            sked_Date_Trade_Approved__c = System.now(),
            sked_Denied_Reason__c = '',
            sked_GuaranteedMinHrsForfeited_Requester__c = TRUE,
            sked_GuaranteedMinHrsForfeited_Trading__c = TRUE,
            sked_Reason_Approval_Required__c = '',
            sked_Reason_For_Trade__c = 'n/a',
            sked_RequestingStaffScheduledHoursAfter__c = 1,
            sked_RequestingStaffScheduledHoursBefore__c = 1,
            sked_RequestingStaffTravelDistanceAfter__c = 1,
            sked_RequestingStaffTravelDistanceBefore__c = 1,
            sked_Requesting_Staff_Drive_Date__c = System.today(),
            sked_Requesting_Staff_Drive_Name__c = '',
            sked_Requesting_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED,
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift2.Id,
            sked_Trading_Staff_Drive__c = testDrive2.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );
        insert driveShiftTrade;

        skedHubBase.setBypassAllTriggers(false);

        // Test performShiftTrades
        Set<Id> tradeIds = new Set<Id>{driveShiftTrade.Id};
        slwcDriveShiftTradeService.performShiftTrades(tradeIds);

        Test.stopTest();

        // Verify job allocations were updated
        List<sked__Job_Allocation__c> updatedAllocations = [
            SELECT Id, sked__Status__c, sked__Resource__c, sked_Drive_Shift_Trade__c
            FROM sked__Job_Allocation__c
            WHERE sked__Job__c IN :jobs
        ];

        System.assertEquals(4, updatedAllocations.size(), 'Should have 4 job allocations (2 deleted, 2 new)');

        // Verify trade was marked as processed
        sked_Drive_Shift_Trade__c processedTrade = [SELECT Id, sked_Status__c FROM sked_Drive_Shift_Trade__c WHERE Id = :driveShiftTrade.Id];
        System.assertNotEquals(null, processedTrade, 'Trade should exist');
    }

    static testmethod void testCreateShiftTradeAPIData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        skedHubBase.setBypassAllTriggers(true);
        sked_Drive__c testDrive2 = testDrive1.clone();
        insert testDrive2;

        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0))
        );
        driveShifts.add(driveShift1);

        sked_Drive_Shift__c driveShift2 = driveShift1.clone();
        driveShifts.add(driveShift2);

        insert driveShifts;

        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job1);

        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Shift__c = driveShift2.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job2);
        insert jobs;

        List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job1);

        sked__Job_Allocation__c testResource2_job2 = new sked__Job_Allocation__c(
            sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource2_job2);
        insert jobAllocations;

        sked_Drive_Shift_Trade__c driveShiftTrade = new sked_Drive_Shift_Trade__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Requesting_Staff_Drive_Date__c = System.today(),
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );
        insert driveShiftTrade;

        skedHubBase.setBypassAllTriggers(false);

        // Test createShiftTradeAPIData
        Set<Id> tradeIds = new Set<Id>{driveShiftTrade.Id};
        slwcDriveShiftTradeService.createShiftTradeAPIData(tradeIds, 'test@example.com');

        Test.stopTest();

        // Verify API data records were created
        List<sked_Trade_API_Data__c> apiDataRecords = [
            SELECT Id, sked_Resource__c, sked_From_Resource__c, sked_Time_Entry_Code__c, sked_Approver_Email__c
            FROM sked_Trade_API_Data__c
        ];

        System.assertEquals(2, apiDataRecords.size(), 'Should create 2 API data records');
        System.assertEquals('Traded Shift', apiDataRecords[0].sked_Time_Entry_Code__c, 'Time entry code should be Traded Shift');
        System.assertEquals('test@example.com', apiDataRecords[0].sked_Approver_Email__c, 'Approver email should match');
    }

    static testmethod void testCallableInterface() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        skedHubBase.setBypassAllTriggers(true);

        sked_Drive__c testDrive2 = testDrive1.clone();
        insert testDrive2;

        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0))
        );
        driveShifts.add(driveShift1);

        sked_Drive_Shift__c driveShift2 = driveShift1.clone();
        driveShifts.add(driveShift2);
        insert driveShifts;

        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift1.Id
        );
        jobs.add(job1);

        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Shift__c = driveShift2.Id
        );
        jobs.add(job2);
        insert jobs;

        List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job1);

        sked__Job_Allocation__c testResource2_job2 = new sked__Job_Allocation__c(
            sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource2_job2);
        insert jobAllocations;

        sked_Drive_Shift_Trade__c driveShiftTrade = new sked_Drive_Shift_Trade__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Requesting_Staff_Drive_Date__c = System.today(),
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );
        insert driveShiftTrade;

        skedHubBase.setBypassAllTriggers(false);

        // Test Callable interface - performShiftTrades
        Callable service = (Callable) Type.forName('slwcDriveShiftTradeService').newInstance();
        Set<Id> tradeIds = new Set<Id>{driveShiftTrade.Id};
        Map<String, Object> params1 = new Map<String, Object>{
            'param1' => JSON.serialize(tradeIds)
        };
        Object result1 = service.call('performShiftTrades', params1);
        System.assertNotEquals(null, result1, 'Should return a result');

        // Test Callable interface - createShiftTradeAPIData
        Map<String, Object> params2 = new Map<String, Object>{
            'param1' => JSON.serialize(tradeIds),
            'param2' => JSON.serialize('test@example.com')
        };
        Object result2 = service.call('createShiftTradeAPIData', params2);
        System.assertNotEquals(null, result2, 'Should return a result');

        Test.stopTest();
    }
    
    static testmethod void testResourceOverrideAndRequiredTags() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        Biomed_Collection_Op_Center__c testCollectionOperation2 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation2');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Tag__c testTag2RBC = (sked__Tag__c)mapTestData.get('testTag2RBC');

        Test.startTest();
        skedHubBase.setBypassAllTriggers(true);

        // Create Resource Override for testResource1 to test getRecordCOIdFromResource
        sked__Resource_Override__c testResourceOverride = new sked__Resource_Override__c(
            sked__Resource__c = testResource1.Id,
            sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked__End__c = testDataFactory.summary.endTime,
            sked__Start__c = testDataFactory.summary.startTime,
            sked_Start_Date__c = testDataFactory.summary.startTime.date(),
            sked_Start_Time__c = testDataFactory.summary.startTime.time(),
            sked_End_Date__c = testDataFactory.summary.endTime.date(),
            sked_End_Time__c = testDataFactory.summary.endTime.time()
        );
        insert testResourceOverride;

        sked_Drive__c testDrive2 = testDrive1.clone();
        insert testDrive2;

        List<sked_Drive_Shift__c> driveShifts = new List<sked_Drive_Shift__c>();
        sked_Drive_Shift__c driveShift1 = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(testDrive1.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(testDrive1.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        driveShifts.add(driveShift1);

        sked_Drive_Shift__c driveShift2 = driveShift1.clone();
        driveShifts.add(driveShift2);

        insert driveShifts;

        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = DateTime.newInstance(testDrive1.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(testDrive1.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job1);

        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = DateTime.newInstance(testDrive1.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(testDrive1.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive2.Id,
            sked_Drive_Shift__c = driveShift2.Id,
            sked_Resource_Role__c = '2RBC'
        );
        jobs.add(job2);
        insert jobs;

        // Add job tags to test requiredTagChecking
        sked__Job_Tag__c jobTag1 = new sked__Job_Tag__c(
            sked__Job__c = job1.Id,
            sked__Tag__c = testTag2RBC.Id
        );
        insert jobTag1;

		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_GeoService_Travel_Distance_To__c = 5,
            sked_GeoService_Travel_Distance_Back__c = 6,
            sked_Travel_Time_To__c = 7,
            sked_Travel_Time_Back__c = 8,
            sked_Roles_Assignment_Str__c = '2RBC'
        );
        jobAllocations.add(testResource1_job1);
        sked__Job_Allocation__c testResource2_job2 = new sked__Job_Allocation__c(
        	sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_GeoService_Travel_Distance_To__c = 5,
            sked_GeoService_Travel_Distance_Back__c = 6,
            sked_Travel_Time_To__c = 7,
            sked_Travel_Time_Back__c = 8,
            sked_Roles_Assignment_Str__c = '2RBC'
        );
        jobAllocations.add(testResource2_job2);
        insert jobAllocations;

        sked_Resource_Hours_Record__c rhr1 = new sked_Resource_Hours_Record__c();
		rhr1.sked_Resource__c = testResource1.id;
		rhr1.sked_Start_Date__c = testDataFactory.summary.startDate;
		rhr1.sked_End_Date__c = testDataFactory.summary.startDate.addDays(7);

        sked_Resource_Hours_Record__c rhr2 = new sked_Resource_Hours_Record__c();
		rhr2.sked_Resource__c = testResource2.id;
		rhr2.sked_Start_Date__c = testDataFactory.summary.startDate;
		rhr2.sked_End_Date__c = testDataFactory.summary.startDate.addDays(7);
		insert new List<SObject> {rhr1, rhr2};

        sked_Resource_Hours_Record_Detail__c rhrd1 = new sked_Resource_Hours_Record_Detail__c();
        rhrd1.sked_Resource_Hours_Record__c = rhr1.id;
        rhrd1.sked_Duration__c = 35;

        sked_Resource_Hours_Record_Detail__c rhrd2 = new sked_Resource_Hours_Record_Detail__c();
        rhrd2.sked_Resource_Hours_Record__c = rhr2.id;
        rhrd2.sked_Duration__c = 36;
        insert new List<sObject>{rhrd1, rhrd2};

        sked_Drive_Shift_Trade__c driveShiftTrade = new sked_Drive_Shift_Trade__c(
            sked_APS_Notes__c = 'note',
            sked_Auto_process_Complete__c = FALSE,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Contact_Method__c = 'Email',
            sked_Date_Trade_Approved__c = System.now(),
            sked_Denied_Reason__c = '',
            sked_GuaranteedMinHrsForfeited_Requester__c = FALSE,
            sked_GuaranteedMinHrsForfeited_Trading__c = FALSE,
            sked_Reason_Approval_Required__c = '',
            sked_Reason_For_Trade__c = 'n/a',
            sked_RequestingStaffScheduledHoursAfter__c = 1,
            sked_RequestingStaffScheduledHoursBefore__c = 1,
            sked_RequestingStaffTravelDistanceAfter__c = 1,
            sked_RequestingStaffTravelDistanceBefore__c = 1,
            sked_Requesting_Staff_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_Requesting_Staff_Drive_Name__c = '',
            sked_Requesting_Staff_Drive_Shift__c = driveShift1.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job1.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Requesting_Staff_Trading_Type__c = 'Drive Shift',
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = FALSE,
            sked_TAT_Time_Traded_Into_Trading__c = FALSE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift2.Id,
            sked_Trading_Staff_Drive__c = testDrive2.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource2_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id,
            sked_Trading_Staff_Trading_Type__c = 'Drive Shift'
        );
        insert driveShiftTrade;

        skedHubBase.setBypassAllTriggers(false);
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);

        // Call autoProcessRequest which will trigger both getRecordCOIdFromResource and requiredTagChecking
        slwcDriveShiftTradeService.driveShiftTradeModel request = new slwcDriveShiftTradeService.driveShiftTradeModel();
        request.id = driveShiftTrade.Id;
        request.requestingStaffId = testResource1.Id;
        request.requestingStaffJobAllocationId = testResource1_job1.Id;
        request.requestingStaffTradingType = 'Drive Shift';
        request.tradingStaffId = testResource2.Id;
        request.tradingStaffJobAllocationId = testResource2_job2.Id;
        request.tradingStaffTradingType = 'Drive Shift';

        slwcAuraResult result = slwcDriveShiftTradeService.autoProcessRequest(request);

        Test.stopTest();

        System.assertEquals(true, result.success);
    }

}