@isTest
private class skedNotificationGenerationBatch_Test {

    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testAsset = (sked__Resource__c)mapTestData.get('testVehicle1');

        System.runAs(new User(Id = UserInfo.getUserId())){
            Set<string> coNames = new Set<string>();
            coNames.add(testCollectionOperation1.Name);
            skedBiomedCollectionOpHandler.createQueues(coNames);

            String dcrApprovalQueueName = testCollectionOperation1.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS;
            Group dcrApprovalQueue = [SELECT Id FROM Group WHERE Name = :dcrApprovalQueueName];
            insert new GroupMember(UserOrGroupId = UserInfo.getUserId(), GroupId = dcrApprovalQueue.Id);
        }
        
        skedHubBase.setBypassAllTriggers(true);
        testDrive1.sked_Drive_Date__c = system.today().addDays(30);
        testDrive1.sked_Approval_Status__c = 'Approved';
        testDrive1.sked_Submitted_By__c = UserInfo.getUserId();
        testDrive1.sked_Drive_Owner__c = UserInfo.getUserId();
        update testDrive1;
        
        List<sked_Drive__c> newRecords = new List<sked_Drive__c>();
        sked_Drive__c newTestDrive1 = new sked_Drive__c(
        	Id = testDrive1.Id,
            Name = testDrive1.Name,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_WB_Projected_Procedures__c = testDrive1.sked_WB_Projected_Procedures__c + 10
        );
        newRecords.add(newTestDrive1);
        
        Map<Id, sked_Drive__c> oldMap = new Map<Id, sked_Drive__c>();
        oldMap.put(testDrive1.Id, testDrive1);
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testDrive1.Id);

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(1),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED
        );
        insert testJobAllocation1;

        sked__Job_Allocation__c oldTestJobAllocation1 = new sked__Job_Allocation__c(
            Id = testJobAllocation1.Id,
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED
        );

        skedHC__Exception__c testEx = new skedHC__Exception__c(
            sked_Drive__c = testDrive1.Id,
            skedHC__Resource__c = testAsset.Id,
            skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
        );
        insert testEx;


        Map<String, sked_Notification_Setting__mdt> mapCMD = sked_Notification_Setting__mdt.getAll();

        skedHubBase.setBypassAllTriggers(false);
        
        skedNotificationGenerationBatch skedNotificationGenerationBatchTest = new skedNotificationGenerationBatch(
            new List<sked_Notification_Setting__mdt> {
                mapCMD.get('sked_Linked_Drive_Removal_Email'),
                mapCMD.get('sked_Drive_Resourcing_Exception_SF_Push'),
                mapCMD.get('sked_Job_Allocation_OneOff')
            },
            new Map<Id, skedNotificationGenerationBatch.notificationSettingRecordData> {
                mapCMD.get('sked_Linked_Drive_Removal_Email').Id => new skedNotificationGenerationBatch.notificationSettingRecordData(
                    new Set<Id>(recordIds),
                    newRecords,
                    oldMap
                ),
                mapCMD.get('sked_Drive_Resourcing_Exception_SF_Push').Id => new skedNotificationGenerationBatch.notificationSettingRecordData(
                    new Set<Id>{testEx.Id},
                    new List<skedHC__Exception__c>{testEx},
                    new Map<Id, skedHC__Exception__c>{testEx.Id => testEx}
                ),
                mapCMD.get('sked_Job_Allocation_OneOff').Id => new skedNotificationGenerationBatch.notificationSettingRecordData(
                    new Set<Id>{testJobAllocation1.Id},
                    new List<sked__Job_Allocation__c>{testJobAllocation1},
                    new Map<Id, sked__Job_Allocation__c>{testJobAllocation1.Id => oldTestJobAllocation1}
                )
            }
        );
        skedNotificationGenerationBatchTest.start(null);
        skedNotificationGenerationBatchTest.execute(null, new List<sked_Notification_Setting__mdt>{mapCMD.get('sked_Linked_Drive_Removal_Email')});
        skedNotificationGenerationBatchTest.execute(null, new List<sked_Notification_Setting__mdt>{mapCMD.get('sked_Drive_Resourcing_Exception_SF_Push')});
        skedNotificationGenerationBatchTest.execute(null, new List<sked_Notification_Setting__mdt>{mapCMD.get('sked_Job_Allocation_OneOff')});
        skedNotificationGenerationBatchTest.finish(null);
        
        Test.stopTest();
    }

    static testmethod void testScheduleBatch() {
        new skedNotificationGenerationBatch(new List<sked_Notification_Setting__mdt>(), null).execute();
        new skedNotificationGenerationBatch(new List<sked_Notification_Setting__mdt>(), null).execute(null);
    }
    
    static testmethod void testDriveDcrQueueTargetDestination() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Set<string> coNames = new Set<string>();
            coNames.add(testCollectionOperation1.Name);
            skedBiomedCollectionOpHandler.createQueues(coNames);
        }
        
        Test.startTest();
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testDrive1.Id);
        
        List<SObject> newRecords = new List<SObject>();
        newRecords.add(testDrive1);
        
        skedNotificationBatchBase.driveDcrQueueTargetDestination cmp = new skedNotificationBatchBase.driveDcrQueueTargetDestination();
        cmp.process(recordIds, newRecords);
        
        Test.stopTest();
    }

    static testmethod void testOnCallSupervisorTargetDestination() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c) mapTestData.get('testResource1');

        sked_Drive_Shift__c testDriveShift1 = new sked_Drive_Shift__c(
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
        insert testDriveShift1;
        
        sked__Activity__c testOnCallEvent = new sked__Activity__c(
            sked__Start__c = testDrive1.sked_Drive_Date__c,
            sked__End__c = testDrive1.sked_Drive_Date__c,
            sked__Type__c = skedConstants.ACTIVITY_TYPE_AFTER_HOURS_CALL_OUT_MANAGEMENT,
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Is_Group_Activity__c = true
        );
        insert testOnCallEvent;

        sked__Activity_Resource__c testOnCallSupervisor = new sked__Activity_Resource__c(
            sked__Activity__c = testOnCallEvent.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testOnCallSupervisor;

        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob1;

        sked__Job_Allocation__c testJobAllocation1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED
        );
        insert testJobAllocation1;

        Test.startTest();
        
        slwcResourceService.saveCallOutRequestModel model = new slwcResourceService.saveCallOutRequestModel();
        model.jobId = testJob1.Id;
        model.resourceId = testResource1.Id;
        model.callOutNotes = 'Testing Notes';
        model.callOutReason = 'Testing';
        model.callOutReported = true;
        model.callOutType = 'Call Out';
        model.usePtoForCallOut = false;
        model.hasTimeOffPlans = false;
        slwcResourceService.saveCallOut(model);

        skedNotificationBatchBase.onCallSupervisorTargetDestination cmp = new skedNotificationBatchBase.onCallSupervisorTargetDestination();
        cmp.process(new Set<Id>{testJobAllocation1.Id}, null);

        Test.stopTest();
    }

    static testmethod void testDriveLeadCalloutTargetDestination() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c) mapTestData.get('testResource1');

        sked_Drive_Shift__c testDriveShift1 = new sked_Drive_Shift__c(
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
        insert testDriveShift1;

        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        sked__Job__c testJob2 = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift1.Id,
            sked_Resource_Role__c = 'Drive Lead'
        );
        insert new List<sked__Job__c>{testJob1, testJob2};

        sked__Job_Allocation__c testJobAllocation1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED
        );
        sked__Job_Allocation__c testJobAllocation2 = new sked__Job_Allocation__c(
            sked__Job__c = testJob2.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED
        );
        insert new List<sked__Job_Allocation__c>{testJobAllocation1, testJobAllocation2};

        Test.startTest();
        
        slwcResourceService.saveCallOutRequestModel model = new slwcResourceService.saveCallOutRequestModel();
        model.jobId = testJob1.Id;
        model.resourceId = testResource1.Id;
        model.callOutNotes = 'Testing Notes';
        model.callOutReason = 'Testing';
        model.callOutReported = true;
        model.callOutType = 'Call Out';
        model.usePtoForCallOut = false;
        model.hasTimeOffPlans = false;
        slwcResourceService.saveCallOut(model);
        
        sked__Availability__c callOutAvailForJA1 = [SELECT Id
                                                    FROM sked__Availability__c
                                                    WHERE sked_Call_Out_for_Job_Allocation__c = :testJobAllocation1.Id];

        skedNotificationBatchBase.driveLeadCalloutEmailTargetDestination cmp = new skedNotificationBatchBase.driveLeadCalloutEmailTargetDestination();
        cmp.process(new Set<Id>{callOutAvailForJA1.Id}, null);
        skedNotificationBatchBase.driveLeadCalloutOneOffTargetDestination cmp2 = new skedNotificationBatchBase.driveLeadCalloutOneOffTargetDestination();
        cmp.process(new Set<Id>{callOutAvailForJA1.Id}, null);

        Test.stopTest();
    }

    static testmethod void testApsSchedulersCallOutTargetDestination() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c) mapTestData.get('testResource1');

        System.runAs(new User(Id = UserInfo.getUserId())){
            Set<string> coNames = new Set<string>();
            coNames.add(testCollectionOperation1.Name);
            skedBiomedCollectionOpHandler.createQueues(coNames);

            String paApprovalQueueName = testCollectionOperation1.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_SHIFT_TRADES;
            Group paApprovalQueue = [SELECT Id FROM Group WHERE Name = :paApprovalQueueName];
            insert new GroupMember(UserOrGroupId = UserInfo.getUserId(), GroupId = paApprovalQueue.Id);
        }

        sked_Drive_Shift__c testDriveShift1 = new sked_Drive_Shift__c(
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
        insert testDriveShift1;

        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift1.Id,
            sked_Resource_Role__c = '2RBC'
        );
        sked__Job__c testJob2 = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift1.Id,
            sked_Resource_Role__c = 'Drive Lead'
        );
        insert new List<sked__Job__c>{testJob1, testJob2};

        sked__Job_Allocation__c testJobAllocation1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED
        );
        sked__Job_Allocation__c testJobAllocation2 = new sked__Job_Allocation__c(
            sked__Job__c = testJob2.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED
        );
        insert new List<sked__Job_Allocation__c>{testJobAllocation1, testJobAllocation2};

        Test.startTest();
        
        slwcResourceService.saveCallOutRequestModel model = new slwcResourceService.saveCallOutRequestModel();
        model.jobId = testJob1.Id;
        model.resourceId = testResource1.Id;
        model.callOutNotes = 'Testing Notes';
        model.callOutReason = 'Testing';
        model.callOutReported = true;
        model.callOutType = 'Call Out';
        model.usePtoForCallOut = false;
        model.hasTimeOffPlans = false;
        slwcResourceService.saveCallOut(model);

        skedNotificationBatchBase.apsSchedulersCallOutTargetDestination cmp = new skedNotificationBatchBase.apsSchedulersCallOutTargetDestination();
        cmp.process(new Set<Id>{testJobAllocation1.Id}, null);

        Test.stopTest();

    }
    
    static testmethod void testResourceAllocationDriveLeadOneOffTargetDestination() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        List<sObject> secondList = new List<sObject>();
        sked__Job__c job = new sked__Job__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Resource_Role__c = 'Charge',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked__Region__c = testRegion1.Id
        );
        secondList.add(job);
        insert secondList;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testVehicle1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED
        );
        insert testResource1_job1;
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testResource1_job1.Id);
        
        List<SObject> newRecords = new List<SObject>();
        newRecords.add(testResource1_job1);
        
        skedNotificationBatchBase.resourceAllocationDriveLeadOneOffTargetDestination cmp = new skedNotificationBatchBase.resourceAllocationDriveLeadOneOffTargetDestination();
        cmp.process(recordIds, newRecords);
        
        Test.stopTest();
    }

    static testmethod void testResourceAllocationDriveLeadEmailTargetDestination() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        List<sObject> secondList = new List<sObject>();
        sked__Job__c job = new sked__Job__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Resource_Role__c = 'Charge',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked__Region__c = testRegion1.Id
        );
        secondList.add(job);
        insert secondList;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testVehicle1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED
        );
        insert testResource1_job1;
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testResource1_job1.Id);
        
        List<SObject> newRecords = new List<SObject>();
        newRecords.add(testResource1_job1);
        
        skedNotificationBatchBase.resourceAllocationDriveLeadEmailTargetDestination cmp = new skedNotificationBatchBase.resourceAllocationDriveLeadEmailTargetDestination();
        cmp.process(recordIds, newRecords);
        
        Test.stopTest();
    }
    
    static testmethod void testLogisticChangeRender() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        testDrive1.sked_Drive_Date__c = system.today().addDays(30);
        update testDrive1;
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testDrive1.Id);
        
        List<sked_Drive__c> newRecords = new List<sked_Drive__c>();
        sked_Drive__c newTestDrive1 = new sked_Drive__c(
        	Id = testDrive1.Id,
            Name = testDrive1.Name,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_WB_Projected_Procedures__c = testDrive1.sked_WB_Projected_Procedures__c + 10
        );
        newRecords.add(newTestDrive1);
        
        Map<Id, sked_Drive__c> oldMap = new Map<Id, sked_Drive__c>();
        oldMap.put(testDrive1.Id, testDrive1);
        
        skedNotificationBatchBase.logisticChangeRender cmp = new skedNotificationBatchBase.logisticChangeRender();
        cmp.process(recordIds, newRecords, oldMap);
        
        Test.stopTest();
    }
    
    static testmethod void testDriveShiftTradeExceptionRender() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        
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
            sked_Reason_Approval_Required__c = 'Requesting User has a TAT Contention',
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
        insert driveShiftTrade;

        testResource1_job1.sked_Drive_Shift_Trade__c = driveShiftTrade.Id;
        testResource2_job2.sked_Drive_Shift_Trade__c = driveShiftTrade.Id;
        update jobAllocations;

        skedHC__Exception__c testException = new skedHC__Exception__c(
            sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_TURNAROUND_TIME_VIOLATION,
            skedHC__Job_Allocation__c = testResource1_job1.Id
        );
        insert testException;

        
        skedNotificationBatchBase.driveShiftTradeExceptionRender cmp = new skedNotificationBatchBase.driveShiftTradeExceptionRender();
        cmp.process(new Set<Id>{testException.Id}, null, null);

        testException.skedHC__Job_Allocation__c = testResource2_job2.Id;
        update testException;

        driveShiftTrade.sked_Reason_Approval_Required__c = 'Trading User has a TAT Contention';
        update driveShiftTrade;

        cmp.process(new Set<Id>{testException.Id}, null, null);
        
        Test.stopTest();
    }

    static testmethod void testDriveShiftTradeOvertimeExceptionRender() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        
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
            sked_Reason_Approval_Required__c = 'Requesting User exceeds Max Hours per week',
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
        insert driveShiftTrade;

        testResource1_job1.sked_Drive_Shift_Trade__c = driveShiftTrade.Id;
        testResource2_job2.sked_Drive_Shift_Trade__c = driveShiftTrade.Id;
        update jobAllocations;

        
        skedNotificationBatchBase.driveShiftTradeOvertimeExceptionRender cmp = new skedNotificationBatchBase.driveShiftTradeOvertimeExceptionRender();
        cmp.process(new Set<Id>{testResource1_job1.Id, testResource2_job2.Id}, null, null);

        driveShiftTrade.sked_Reason_Approval_Required__c = 'Trading User exceeds Max Hours per week';
        update driveShiftTrade;

        cmp.process(new Set<Id>{testResource1_job1.Id, testResource2_job2.Id}, null, null);
        
        Test.stopTest();
    }
}