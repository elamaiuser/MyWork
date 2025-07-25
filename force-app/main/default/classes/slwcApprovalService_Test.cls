@isTest
private class slwcApprovalService_Test {
    
    @isTest
    static void getApprovalHistoryList_Test() {
                skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;
        
        sked_Drive_Change_Request_Item__c testDriveChangeRequestItem = new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = testDcr.Id,
            sked_Old_Value__c = testLocation1.Id,
            sked_New_Value__c = testLocation1.Id,
            sked_Change_Reason__c = 'Test',
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Site__c',
            sked_Type__c = 'Change'
        );
        insert testDriveChangeRequestItem;

        testDcr.sked_Status__c = 'Submitted';
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        update testDcr;
        
        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
        model.action = 'Approved';
        model.recordId = testDcr.Id;
        model.comments = 'Testing';

		slwcAuraResult approvalHistory = slwcApprovalService.getApprovalHistoryList(testDcr.Id);
    }

    @isTest
    static void getCurrentApprovalData_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;

        testDcr.sked_Status__c = 'Submitted';
        update testDcr;
        
        
        slwcApprovalService.getCurrentApprovalDataRequestModel model = new slwcApprovalService.getCurrentApprovalDataRequestModel();
        model.recordIds = new List<String>{testDcr.Id};

        slwcAuraResult approvalData = slwcApprovalService.getCurrentApprovalData(model);
        Test.stopTest();
    }

    @isTest
    static void approveReject_DCR_Approve_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;

        testDcr.sked_Status__c = 'Submitted';
        update testDcr;
        
        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
        model.action = 'Approve';
        model.recordId = testDcr.Id;
        model.comments = 'Testing';

        slwcAuraResult approveRejectResult = slwcApprovalService.approveReject(model);

        Test.stopTest();
    }

    @isTest
    static void approveReject_SiteFeedback_Approve_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Location__c testDriveSite = (sked__Location__c)mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;

        sked_Site_Feedback__c testSiteFeedback = new sked_Site_Feedback__c(
            sked_Amount__c = 5,
            sked_Buffer_Type__c = 'Add',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Effective_End_Date__c = System.today().addDays(100),
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Job__c = testJob.Id,
            sked_MigrationID__c = 'test-migration-id',
            sked_Reason__c = 'testing',
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Site__c = testDriveSite.Id,
            sked_Status__c = skedConstants.DRIVE_STATUS_SUBMITTED,
            sked_Variance_Applies_To__c = 'Setup Time',
            sked_Variance_Type__c = 'Elevator',
            sked_Route_Approval_Request_To__c = 'Request DM evaluation'
        );
        insert testSiteFeedback;

        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
        model.action = 'Approve';
        model.recordId = testSiteFeedback.Id;
        model.comments = 'Testing';
        model.sObj = new sked_Site_Feedback__c(Id = testSiteFeedback.Id);

        slwcAuraResult approveRejectResult = slwcApprovalService.approveReject(model);

        Test.stopTest();
    }

    @isTest
    static void isPendingApproval_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;

        testDcr.sked_Status__c = 'Submitted';
        update testDcr;
        
        slwcApprovalService.isPendingApproval(testDcr.Id);
        Test.stopTest();
    }

    @isTest
    static void saveDesignatedApprover_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
                
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;

        testDcr.sked_Status__c = 'Submitted';
        update testDcr;
        
        slwcApprovalService.saveDesignatedApproverRequestModel model = new slwcApprovalService.saveDesignatedApproverRequestModel();
        model.approverId = UserInfo.getUserId();
        model.recordId = testDcr.Id;

        slwcAuraResult saveDesignatedApproverResult = slwcApprovalService.saveDesignatedApprover(model);
        Test.stopTest();
    }

    @isTest
    static void canApprove_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;

        testDcr.sked_Status__c = 'Submitted';
        update testDcr;
        
        slwcAuraResult canApproveResult = slwcApprovalService.canApprove(testDcr.Id);
        Test.stopTest();
    }

    @isTest
    static void removeWorkItems_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;

        testDcr.sked_Status__c = 'Submitted';
        update testDcr;
        
        slwcApprovalService.call('removeWorkItems', new Map<String, Object>{'param1' => JSON.serialize(new Set<Id>{testDcr.Id})});
        Test.stopTest();
    }

    @isTest
    static void withdraw_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;

        testDcr.sked_Status__c = 'Submitted';
        update testDcr;
        
        slwcApprovalService.withdrawRequestModel request = new slwcApprovalService.withdrawRequestModel();
        request.recordId = testDcr.Id;
        slwcApprovalService.withdraw(request);
        Test.stopTest();
    }

    @isTest
    static void getApprovalQueue_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        
        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        Group testGroup = slwcApprovalService.getApprovalQueue(opCenter.Name, skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS);
        Test.stopTest();
    }
    
    static testmethod void on_CM_RTV_Approved_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c)mapTestData.get('testLocation1');
        
        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;
        
        sked_Site_Feedback__c testSiteFeedback = new sked_Site_Feedback__c(
            sked_Amount__c = 5,
            sked_Buffer_Type__c = 'Add',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Effective_End_Date__c = System.today().addDays(100),
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Job__c = testJob.Id,
            sked_MigrationID__c = 'test-migration-id',
            sked_Reason__c = 'testing',
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Site__c = testDriveSite.Id,
            sked_Status__c = 'Not Submitted',
            sked_Variance_Applies_To__c = 'Setup Time',
            sked_Variance_Type__c = 'Elevator'
        );
        insert testSiteFeedback;
        
        testSiteFeedback.sked_Status__c = 'Submitted';
        testSiteFeedback.sked_Route_Approval_Request_To__c = skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_CM;
        update testSiteFeedback;
        
        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
        model.action = 'Approve';
        model.recordId = testSiteFeedback.Id;
        model.comments = 'Testing';
        model.sObj = new sked_Site_Feedback__c(Id = testSiteFeedback.Id);
        slwcAuraResult approveRejectResult = slwcApprovalService.approveReject(model);
        
        testSiteFeedback.sked_Status__c = 'Approved';
        update testSiteFeedback;
        
        Test.stopTest();
    }
    
    static testmethod void on_DM_RTV_Approved_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c)mapTestData.get('testLocation1');
        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );
        
        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;
        
        sked_Site_Feedback__c testSiteFeedback = new sked_Site_Feedback__c(
            sked_Amount__c = 5,
            sked_Buffer_Type__c = 'Add',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Effective_End_Date__c = System.today().addDays(100),
            sked_Effective_Start_Date__c = System.today().addDays(-10),
            sked_Job__c = testJob.Id,
            sked_MigrationID__c = 'test-migration-id',
            sked_Reason__c = 'testing',
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Site__c = testDriveSite.Id,
            sked_Status__c = skedConstants.SITE_FEEDBACK_STATUS_SUBMITTED,
        	sked_Route_Approval_Request_To__c = skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_DM,
            sked_Variance_Applies_To__c = 'Setup Time',
            sked_Variance_Type__c = 'Elevator'
        );
        insert testSiteFeedback;
        
        //testSiteFeedback.sked_Status__c = skedConstants.RTV_FEEDBACK_STATUS_WAITING_FOR_DM_APPROVAL;
        //testSiteFeedback.sked_Route_Approval_Request_To__c = skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_DM;
        //update testSiteFeedback;
        
        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
        model.action = 'Approve';
        model.recordId = testSiteFeedback.Id;
        model.comments = 'Testing';
        model.sObj = new sked_Site_Feedback__c(Id = testSiteFeedback.Id);
        slwcAuraResult approveRejectResult = slwcApprovalService.approveReject(model);
        
        testSiteFeedback.sked_Status__c = 'Approved';
        update testSiteFeedback;
        
        Test.stopTest();
    }
    
    static testmethod void on_APS_RTV_Approved_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c)mapTestData.get('testLocation1');
        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );
        
        Insert DRDAMUser;
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;
        
        Test.startTest();
        sked_Site_Feedback__c testSiteFeedback = new sked_Site_Feedback__c(
            sked_Amount__c = 5,
            sked_Buffer_Type__c = 'Add',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            sked_Effective_End_Date__c = System.today().addDays(100),
            sked_Effective_Start_Date__c = System.today().addDays(-10),
           
            sked_MigrationID__c = 'test-migration-id',
            sked_Reason__c = 'testing',
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Site__c = testDriveSite.Id,
            sked_Status__c = 'Submitted',
            sked_Route_Approval_Request_To__c = skedConstants.RTV_ROUTE_APPROVAL_REQUEST_TO_DM,
            sked_Variance_Applies_To__c = 'Setup Time',
            sked_Variance_Type__c = 'Elevator'
        );
        System.runAs(DRDAMUser){
        	insert testSiteFeedback;  
        }
        
        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
            model.action = 'Approve';
            model.recordId = testSiteFeedback.Id;
            model.comments = 'Testing';
            model.sObj = new sked_Site_Feedback__c(Id = testSiteFeedback.Id);
            slwcAuraResult approveRejectResult = slwcApprovalService.approveReject(model);
            
            testSiteFeedback.sked_Status__c = 'Approved';
            update testSiteFeedback;
        
        Test.stopTest();
    }
    
    static testmethod void cancelReject_Approve_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;
        
        sked_Drive_Change_Request_Item__c testDriveChangeRequestItem = new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = testDcr.Id,
            sked_Old_Value__c = testLocation1.Id,
            sked_New_Value__c = testLocation1.Id,
            sked_Change_Reason__c = 'Test',
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Site__c',
            sked_Type__c = 'Change'
        );
        insert testDriveChangeRequestItem;

        testDcr.sked_Status__c = 'Submitted';
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        update testDcr;
        
        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
        model.action = 'Reject';
        model.recordId = testDcr.Id;
        model.comments = 'Testing';

        slwcAuraResult approveRejectResult = slwcApprovalService.approveReject(model);
        Test.stopTest();
    }
    
    static testmethod void createRequestToSyncOppsWithDrives_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;
        
        sked_Drive_Change_Request_Item__c testDriveChangeRequestItem = new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = testDcr.Id,
            sked_Old_Value__c = testLocation1.Id,
            sked_New_Value__c = testLocation1.Id,
            sked_Change_Reason__c = 'Test',
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Site__c',
            sked_Type__c = 'Change'
        );
        insert testDriveChangeRequestItem;

        testDcr.sked_Status__c = 'Submitted';
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        update testDcr;
        
        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
        model.action = 'Approve';
        model.recordId = testDcr.Id;
        model.comments = 'Testing';

        slwcAuraResult approveRejectResult = slwcApprovalService.approveReject(model);
    }
    
    static testmethod void processDriveApproval_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        testDrive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        testDrive.sked_Approval_Status__c = 'Submitted';
        testDrive.sked_Pending_Action__c ='Drive Submission';
        testDrive.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        update testDrive;
        
        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
        model.action = 'Approve';
        model.recordId = testDrive.Id;
        model.comments = 'Testing';
        model.sObj = new sked_Drive__c(Id = testDrive.Id);

        slwcAuraResult approveRejectResult = slwcApprovalService.approveReject(model);
        
        Test.stopTest();
    }
    
}