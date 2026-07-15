@isTest
private class skedOperationRecordStaffHander_Test {
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
        
        skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});
        
        sked_Operation_Record_Staff__c operationRecordStaff = [SELECT Id
                                                               FROM sked_Operation_Record_Staff__c
                                                               WHERE sked_Job_Allocation__c = :testJobAllocation.Id];
        operationRecordStaff.sked_Actual_Shift_Start__c = testDriveShift.sked_Start__c;
        operationRecordStaff.sked_Actual_Shift_End__c = testDriveShift.sked_Finish__c;
        update operationRecordStaff;

        sked_Staff_Meal_Rest_Break_Setting__c staffMealAndRestBreakSetting = new sked_Staff_Meal_Rest_Break_Setting__c(
            Name = 'Meal Break 1',
        	sked_Operation_Record_Staff__c = operationRecordStaff.Id,
            sked_Break_Type__c = 'Meal',
            sked_Actual_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Actual_End__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0))
        );
        insert staffMealAndRestBreakSetting;
       
        delete operationRecordStaff;
        
        Test.stopTest();
    }

    @isTest
    static void beforeInsert_volunteerResource_setsWorkdayIgnore() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c employeeResource = (sked__Resource__c) mapTestData.get('testResource1');

        sked__Resource__c volunteerResource = new sked__Resource__c(
            Name = 'Volunteer Test Resource',
            sked__Resource_Type__c = skedConstants.RESOURCE_TYPE_PERSON,
            sked__Category__c = BSF_WorkdayDirectSubmissionConfig.RESOURCE_CATEGORY_VOLUNTEER,
            sked__Is_Active__c = true,
            sked__Primary_Region__c = testRegion.Id,
            sked_Employee_ID__c = 'VOL123'
        );
        insert volunteerResource;

        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(14, 0, 0, 0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = false,
            sked_Order__c = 1,
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
            sked__Location__c = testDriveSite.Id,
            sked_Resource_Role__c = 'VP/HH',
            sked_VPHH_Quantity__c = 1,
            sked_APT_Quantity__c = 0,
            sked__Quantity__c = 1
        );
        insert testJob;

        sked_Operation_Record__c op = new sked_Operation_Record__c(
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Status__c = 'Not Submitted',
            sked_Submitted_By__c = employeeResource.Id
        );
        insert op;

        Test.startTest();
        sked_Operation_Record_Staff__c volunteerStaff = new sked_Operation_Record_Staff__c(
            sked_Operation_Record__c = op.Id,
            sked_Job__c = testJob.Id,
            sked_Resource__c = volunteerResource.Id,
            sked_Absent__c = false
        );
        insert volunteerStaff;
        Test.stopTest();

        volunteerStaff = [
            SELECT Id, sked_Workday_Submission_Status__c
            FROM sked_Operation_Record_Staff__c
            WHERE Id = :volunteerStaff.Id
        ];
        System.assertEquals(
            BSF_WorkdayDirectSubmissionConfig.STAFF_STATUS_IGNORE,
            volunteerStaff.sked_Workday_Submission_Status__c,
            'Volunteer resource staff should be stamped Ignore on create'
        );
    }
    
}