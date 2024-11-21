@isTest
private class slwcDriveService_Test {
    
    static testmethod void testDispatchDrives() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testVehicle1 = (sked__Resource__c) mapTestData.get('testVehicle1');
        
        Test.startTest();
        
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
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
        insert testDriveShift;
        
        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC'
        );
        sked__Job__c testVehicleJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Asset_Type__c = 'Vehicle'
        );
        
        insert new List<SObject>{testJob1,testVehicleJob1};
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob1.Id,
            sked__Resource__c = testResource1.Id
        );
        sked__Job_Allocation__c testVehicleJobAllocation1 = new sked__Job_Allocation__c(
            sked__Job__c = testVehicleJob1.Id,
            sked__Resource__c = testVehicle1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED,
            sked_Roles_Assignment_Str__c = '2RBC'
        );
        
        insert new List<SObject>{testResource1_job1,testVehicleJobAllocation1};
        
        slwcDriveService.dispatchDrivesRequestModel request = new slwcDriveService.dispatchDrivesRequestModel();
        request.driveIds = new List<string>();
        request.driveIds.add(testDrive1.Id);
        request.resend = true;
        slwcDriveService.dispatchDrives(request);
        
        Test.stopTest();
    }
    
    static testmethod void testCaptureDriveImpact() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
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
        insert testDriveShift;
        
        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob1;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob1.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testResource1_job1;
        
        sked_Drive_Change_Request__c testDriveChangeRequest1 = new sked_Drive_Change_Request__c(
            sked_Drive__c = testDrive1.Id,
            sked_Description__c = 'Testing'
        );
        
        insert testDriveChangeRequest1;
        
        slwcDriveService.driveChangeRequestModel capRec = new slwcDriveService.driveChangeRequestModel();
        capRec.id = testDriveChangeRequest1.Id;
        capRec.driveId = testDrive1.Id;
        
        slwcDriveService.driveChangeRequestItemModel newItem = new slwcDriveService.driveChangeRequestItemModel();
        newItem.objectApiName = 'sked_Drive__c';
        newItem.fieldApiName = 'sked_Drive_Dispatched__c';
        newItem.oldValue = 'Unchecked';
        newItem.newValue = 'Checked';
        
        slwcDriveService.driveChangeRequestItemModel newItem1 = new slwcDriveService.driveChangeRequestItemModel();
        newItem1.objectApiName = 'sked_Drive__c';
        newItem1.fieldApiName = 'sked_Drive_Productivity_Planned__c';
        newItem1.oldValue = '0.7351446718419196';
        newItem1.newValue = '0.6351446718419196';
        
        capRec.driveChangeRequestItems = new List<slwcDriveService.driveChangeRequestItemModel>();
        capRec.driveChangeRequestItems.add(newItem);
        capRec.driveChangeRequestItems.add(newItem1);
        
        /* Test case 1: process change requests for the first time */
        slwcDriveService.captureDriveImpact(capRec);
        
        /* Test case 2: process again & check the change requests are updated & not created as new ones. And also use oppid, instead of driveId and it should have same behavior*/
        capRec.driveId = null;
        capRec.opportunityId = testDrive1.sked_Opportunity__c;
        newItem1.oldValue = '0.6351446718419196';
        newItem1.newValue = '0.8351446718419196';
        slwcDriveService.captureUserChangeDriveChangeRequests(new List<slwcDriveService.driveChangeRequestModel>{capRec});
        
        Test.stopTest();
    }   
    
    static testmethod void searchDriveSite_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');
        
        Test.startTest();
        
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
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
        insert testDriveShift;
        
        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob1;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob1.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testResource1_job1;
        
        Date currentDate = system.today();
        
        slwcDriveService.searchDriveSiteRequestModel testDriveSiteRequestModel = new slwcDriveService.searchDriveSiteRequestModel();
        testDriveSiteRequestModel.collectionOperationId = testCollectionOperation1.Id;
        testDriveSiteRequestModel.queryText = testLocation1.Name;
        testDriveSiteRequestModel.inputDate = JSON.serialize(currentDate).replace('"', '');
        
        slwcAuraResult result = slwcDriveService.searchDriveSite(testDriveSiteRequestModel);
        
        Test.stopTest();
    }
    
    static testmethod void populateNextPreviousDrive_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
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
        
        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob1;
        
        sked_Drive__c testPreviousDrive = testDrive.clone(false, false, false, false);
        testPreviousDrive.sked_Drive_Date__c = testDrive.sked_Drive_Date__c.addDays(-1);
        insert testPreviousDrive;
        
        sked_Drive__c testNextDrive = testDrive.clone(false, false, false, false);
        testNextDrive.sked_Drive_Date__c = testDrive.sked_Drive_Date__c.addDays(1);
        insert testNextDrive;
        
        testDrive.sked_Previous_Drive__c = testPreviousDrive.Id;
        testDrive.sked_Next_Drive__c = testNextDrive.Id;
        
        slwcDriveService.populateNextPreviousDrive(new List<sked_Drive__c>{testDrive});
        
        Test.stopTest();
    }
    
    static testmethod void updateDriveStatuses_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
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
        insert testDriveShift;
        
        sked__Job__c testJob1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob1;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = testJob1.Id,
            sked__Resource__c = testResource1.Id
        );
        insert testResource1_job1;
        
        slwcDriveService.driveModel testDriveModel = new slwcDriveService.driveModel();
        testDriveModel.id = testDrive1.Id;
        testDriveModel.status = skedConstants.DRIVE_STATUS_CANCEL;
        
        slwcDriveService.updateDriveStatusRequestModel model = new slwcDriveService.updateDriveStatusRequestModel();
        model.drives = new List<slwcDriveService.driveModel>();
        model.drives.add(testDriveModel);
        
        slwcDriveService.updateDriveStatuses(model);
        
        Test.stopTest();
    }
    
    static testmethod void getTerritoryKeys_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        
        Test.startTest();
        
        slwcDriveService.getTerritoryKeysRequestModel request = new slwcDriveService.getTerritoryKeysRequestModel();
        request.collectionOperationId = testCollectionOperation1.Id;
        request.startDate = testDataFactory.summary.startDate;
        request.endDate = testDataFactory.summary.endDate;
        
        slwcDriveService.getTerritoryKeys(request);
        
        Test.stopTest();
    }
    
    static testmethod void validateDraftDrive_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        
        Test.startTest();
        
        slwcDriveService.validateDraftDriveRequestModel model = new slwcDriveService.validateDraftDriveRequestModel();
        model.driveId = testDrive1.Id;
        
        slwcDriveService.validateDraftDrive(model);
        
        Test.stopTest();
    }
    
    static testmethod void testCaptureNonUserChangeDCRs() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');

        slwcDriveService.captureNonUserChangeDCRsModel request = new slwcDriveService.captureNonUserChangeDCRsModel();
        request.driveChangeRequestType = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTD_CHANGE;
        request.fieldApiName = 'sked_Role_Time_Detail_Changed__c';
        request.fieldLabel = 'Role Time Detail Changed';
        request.fieldType = 'Boolean';
        request.impactedDrives =new List<sked_Drive__c>{testDrive};
        slwcDriveService.skedCaptureNonUserChangeDCRs(request);

        request.driveChangeRequestType = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTV_CHANGE;
        request.fieldApiName = 'sked_Role_Time_Variance_Changed__c';
        request.fieldLabel = 'Role Time Variance Changed';
        slwcDriveService.skedCaptureNonUserChangeDCRs(request);
    }
}