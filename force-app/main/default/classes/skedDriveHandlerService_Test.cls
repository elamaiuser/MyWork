@isTest(SeeAllData = false)
private class skedDriveHandlerService_Test {
	
    static testMethod void testCascadeCancelEvents() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        Account testAccount1 = (Account)mapTestData.get('testAccount1');
        Time_Block__c testTimeBlock = (Time_Block__c)mapTestData.get('testTimeBlock1');
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Set<string> coNames = new Set<string>();
            coNames.add(testCollectionOperation1.Name);
            skedBiomedCollectionOpHandler.createQueues(coNames);
        }
        
        Test.startTest();

        List<sObject> firstList = new List<sObject>();
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
            sked_Volunteer_Setup__c = 1,
            sked_Time_Block__c = testTimeBlock.Id
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
        insert jobs;

		List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        jobAllocations.add(testResource1_job1);
        insert jobAllocations;
        
        skedHC__Exception__c testException = new skedHC__Exception__c(
            sked_Drive__c = testDrive1.Id,
            sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT,
            skedHC__Exception__c = 'Non-working time',
            skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN,
            skedHC__Job__c = job.Id,
            skedHC__Job_Allocation__c = testResource1_job1.Id
        );
        insert testException;
        
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED;
        update testDrive1;
        
        testDrive1.sked_Pending_Action__c = 'Cancel In Process';
        testDrive1.sked_Route_Approval_Request_To__c = 'Request APS exception';
        testDrive1.sked_Approval_Status__c = 'Submitted';
        update testDrive1;
        
        skedDriveHandlerService.cascadeCancelEvents(new Set<Id>{testDrive1.Id}, new Set<Id>{testDrive1.sked_Opportunity__c});
        
        Test.stopTest();
        Assert.isTrue([SELECT Id, sked__Job_Status__c FROM sked__Job__c LIMIT 1].sked__Job_Status__c == 'Cancelled');
    
    }
    
    static testmethod void testCascadeCompleteEvents() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        sked_Drive__c testDrive1 = (sked_Drive__c) mapTestData.get('testDrive1');

        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive1.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Status__c = 'Pending';
        insert testDcr;
        
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_COMPLETE;
        skedHubBase.BypassUpdateTriggers = true;
        update testDrive1;
        skedHubBase.BypassUpdateTriggers = false;
        
        skedDriveHandlerService.cascadeCompleteEvents(new Set<Id>{testDrive1.Id});
        
        Test.stopTest();
        Assert.isTrue(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED == [SELECT Id, sked_Status__c FROM sked_Drive_Change_Request__c WHERE Id = :testDcr.Id LIMIT 1].sked_Status__c);
    }
}