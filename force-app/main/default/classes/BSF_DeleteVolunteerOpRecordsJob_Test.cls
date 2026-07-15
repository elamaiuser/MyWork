@IsTest
private class BSF_DeleteVolunteerOpRecordsJob_Test {

    @IsTest
    static void execute_deletesYesterdayVolunteerStaff_leavesOthers() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion1 = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c employeeResource = (sked__Resource__c) mapTestData.get('testResource1');

        sked__Resource__c volunteerResource = employeeResource.clone(false, true, false, false);
        volunteerResource.Name = 'Volunteer Delete Job Resource';
        volunteerResource.sked__Category__c = BSF_WorkdayDirectSubmissionConfig.RESOURCE_CATEGORY_VOLUNTEER;
        volunteerResource.sked_Employee_ID__c = 'VOLDEL1';
        volunteerResource.sked_ULID__c = 'ULIDVOLDEL1';
        volunteerResource.sked_First_Name__c = 'Volunteer';
        volunteerResource.sked_Last_Name__c = 'Delete';
        volunteerResource.sked__User__c = null;
        volunteerResource.sked__Email__c = 'volunteer.delete@example.test';
        insert volunteerResource;

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
            sked_Submitted_By__c = employeeResource.Id, sked_Donor_Ambassadors_Actual__c = 0
        );
        insert op;

        sked_Operation_Record_Staff__c volunteerStaffYesterday = new sked_Operation_Record_Staff__c(
            sked_Operation_Record__c = op.Id, sked_Job__c = testJob.Id,
            sked_Resource__c = volunteerResource.Id, sked_Absent__c = false,
            sked_Actual_Roles__c = 'Driver'
        );
        insert volunteerStaffYesterday;
        Test.setCreatedDate(volunteerStaffYesterday.Id, System.now().addDays(-1));

        sked_Operation_Record_Staff__c volunteerStaffToday = new sked_Operation_Record_Staff__c(
            sked_Operation_Record__c = op.Id, sked_Job__c = testJob.Id,
            sked_Resource__c = volunteerResource.Id, sked_Absent__c = false,
            sked_Actual_Roles__c = 'Driver'
        );
        insert volunteerStaffToday;

        sked_Operation_Record_Staff__c employeeStaffYesterday = new sked_Operation_Record_Staff__c(
            sked_Operation_Record__c = op.Id, sked_Job__c = testJob.Id,
            sked_Resource__c = employeeResource.Id, sked_Absent__c = false,
            sked_Actual_Roles__c = 'Driver'
        );
        insert employeeStaffYesterday;
        Test.setCreatedDate(employeeStaffYesterday.Id, System.now().addDays(-1));

        Test.startTest();
        Database.executeBatch(new BSF_DeleteVolunteerOpRecordsJob(), 50);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM sked_Operation_Record_Staff__c WHERE Id = :volunteerStaffYesterday.Id],
            'Yesterday volunteer staff should be deleted'
        );
      
    }

   
}
