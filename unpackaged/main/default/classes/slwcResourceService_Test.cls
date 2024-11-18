@isTest
private class slwcResourceService_Test {
    
    static testmethod void getResourceData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        Test.startTest();
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        insert testJobAllocation;
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = System.now().addHours(8),
            sked__End__c = System.now().addHours(9),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert testActivity;
        
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = testActivity.Id,
            sked__Resource__c = testResource.Id
        );
        insert testActivityResource;
        
        Biomed_Collection_Op_Center__c testCo = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        
        List<String> dates = new List<String>();
        Date startDate = System.today();
        Date endDate = System.today().addDays(10);
        
        while (startDate < endDate) {
            dates.add('' + startDate.year() + '-' + startDate.month() + '-' + startDate.day());
            startDate = startDate.addDays(1);
        }
        dates.add('' + endDate.year() + '-' + endDate.month() + '-' + endDate.day());
        
        slwcResourceService.getResourceDataRequestModel model = new slwcResourceService.getResourceDataRequestModel();
        model.collectionOperationIds = new List<String>{testCo.Id};
            model.inputDates = dates;
        model.pageSize = 50;
        model.pageNo = 1;
        
        slwcAuraResult result = slwcResourceService.getResourceData(model);
        
        Test.stopTest();
    }
    
    static testmethod void saveCallOut_Job_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        Test.startTest();

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11).addMinutes(15),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(11).addMInutes(30),
            sked__Duration__c = 15,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
        	sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED,
            sked_Roles_Assignment_Str__c = '2RBC',
            sked_Additional_Roles__c = '2RBC Sign-off'
        );
        insert testJobAllocation;
        
        slwcResourceService.saveCallOutRequestModel model = new slwcResourceService.saveCallOutRequestModel();
        model.jobId = testJob.Id;
        model.resourceId = testResource.Id;
        model.callOutNotes = 'Testing Notes';
        model.callOutReason = 'Testing';
        model.callOutReported = true;
        model.callOutType = 'Call Out';
        model.usePtoForCallOut = false;
        model.hasTimeOffPlans = false;
        slwcResourceService.saveCallOut(model);
        
        sked__Availability__c callOutAvail = [SELECT Id, sked_Custom_Status__c
                                              FROM sked__Availability__c
                                              WHERE sked_Call_Out_for_Job_Allocation__c = :testJobAllocation.Id];
        slwcResourceService.saveCallOutRequestModel modelToUpdate = new slwcResourceService.saveCallOutRequestModel();
        modelToUpdate.id = callOutAvail.Id;
        modelToUpdate.callOutNotes = 'Testing Notes';
        modelToUpdate.callOutReason = 'Testing';
        modelToUpdate.callOutReported = true;
        modelToUpdate.callOutType = 'Call Out';
        model.usePtoForCallOut = false;
        model.hasTimeOffPlans = false;
        slwcResourceService.saveCallOut(modelToUpdate);
        
        Test.stopTest();
    }
    
    static testmethod void saveCallOut_Activity_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        Test.startTest();

        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = System.now().addHours(8),
            sked__End__c = System.now().addHours(9),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert testActivity;

        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = testActivity.Id,
            sked__Resource__c = testResource.Id
        );
        insert testActivityResource;
        
        slwcResourceService.saveCallOutRequestModel model = new slwcResourceService.saveCallOutRequestModel();
        model.activityId = testActivityResource.sked__Activity__c;
        model.resourceId = testActivityResource.sked__Resource__c;
        model.callOutNotes = 'Testing Notes';
        model.callOutReason = 'Testing';
        model.callOutReported = true;
        model.callOutType = 'Call Out';
        model.usePtoForCallOut = false;
        model.hasTimeOffPlans = false;
        slwcAuraResult result = slwcResourceService.saveCallOut(model);
        
        Test.stopTest();
    }
    
}