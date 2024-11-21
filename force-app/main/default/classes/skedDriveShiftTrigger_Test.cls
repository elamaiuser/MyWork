@isTest
public class skedDriveShiftTrigger_Test {
    
    static testmethod void testPendingAndApprove_ShiftTrade() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();

        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
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
        insert driveShift;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id
        );
        jobs.add(job);
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id
        );
        jobs.add(job2);
        insert jobs;

		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job1);
        sked__Job_Allocation__c testResource1_job2 = new sked__Job_Allocation__c(
        	sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job2);
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
            sked_Requesting_Staff_Drive_Shift__c = driveShift.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift.Id,
            sked_Trading_Staff_Drive__c = testDrive1.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource1_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id
        );
        insert driveShiftTrade;

        driveShiftTrade.sked_Reason_Approval_Required__c = skedConstants.DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_TAT_CONTENTION;
        driveShiftTrade.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_PENDING_APPROVAL;
        update driveShiftTrade;
        
        driveShiftTrade.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED;
        update driveShiftTrade;
        
        Test.stopTest();
    }
    
    static testmethod void testDeleteDriveShift() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();

        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
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
        insert driveShift;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id
        );
        jobs.add(job);
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(16),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id
        );
        jobs.add(job2);
        insert jobs;

		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job1);
        sked__Job_Allocation__c testResource1_job2 = new sked__Job_Allocation__c(
        	sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job2);
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
            sked_Requesting_Staff_Drive_Shift__c = driveShift.Id,
            sked_Requesting_Staff_Drive__c = testDrive1.Id,
            sked_Requesting_Staff_Job_Allocation__c = testResource1_job1.Id,
            sked_Requesting_Staff_Job__c = job.Id,
            sked_Requesting_Staff_Overnight__c = FALSE,
            sked_Requesting_Staff_Role_on_Drive__c = '2RBC',
            sked_Requesting_Staff__c = testResource1.Id,
            sked_Status__c = 'Submitted',
            sked_TAT_Time_Traded_Into_Requester__c = TRUE,
            sked_TAT_Time_Traded_Into_Trading__c = TRUE,
            sked_Trade_Requester_Notes__c = '',
            sked_TradingStaffTravelDistanceAfter__c = 1,
            sked_TradingStaffTravelDistanceBefore__c = 1,
            sked_TradingStaff_Scheduled_Hours_Before__c = 1,
            sked_Trading_Staff_Drive_Date__c = System.today(),
            sked_Trading_Staff_Drive_Name__c = '',
            sked_Trading_Staff_Drive_Shift__c = driveShift.Id,
            sked_Trading_Staff_Drive__c = testDrive1.Id,
            sked_Trading_Staff_Job_Allocation__c = testResource1_job2.Id,
            sked_Trading_Staff_Job__c = job2.Id,
            sked_Trading_Staff_Overnight__c = FALSE,
            sked_Trading_Staff_Role_on_Drive__c = '2RBC',
            sked_Trading_Staff_Scheduled_Hours_After__c = 1,
            sked_Trading_Staff__c = testResource2.Id
        );
        insert driveShiftTrade;
        
        delete driveShift;
        
        Test.stopTest();
    }

}