@isTest
private class skedAvailabilityService_Test {
    @isTest
    static void skedAvailabilityService_NoConflicts_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCollectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        
        sked_Staffing_Budget__c testStaffingBudget = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = System.today(),
            sked_Bidding_Start_Date__c = System.today().addYears(1),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation.id,
            sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT,
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = System.today(),
            sked_Total_Slots__c = 100
        );
        insert testStaffingBudget;

        sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCo1 = new sked_Staffing_Budget_Collection_Op__c(
            sked_Staffing_Budget__c = testStaffingBudget.Id,
            sked_Biomed_Collection_Operation__c = testCollectionOperation.Id
        );
        insert testStaffingBudgetCo1;

        skedModels.staffingBudget testStaffingBudgetModel = new skedModels.staffingBudget();
        testStaffingBudgetModel.id = testStaffingBudget.Id;
        testStaffingBudgetModel.approvedSlots = 10;
        testStaffingBudgetModel.totalSlots = 100;
        testStaffingBudgetModel.availableSlots = 50;
        testStaffingBudgetModel.roles = new List<string>();
        testStaffingBudgetModel.roles.add('Driver');
        testStaffingBudgetModel.driveTypes = new List<String>();
        testStaffingBudgetModel.driveTypes.add('Mobile');
        testStaffingBudgetModel.driveTypes.add('Fixed Site');
        testStaffingBudgetModel.biomedCollectionOpId = testCollectionOperation.Id;
        testStaffingBudgetModel.requestType = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT;
        testStaffingBudgetModel.biddingStartDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        testStaffingBudgetModel.biddingEndDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();

        sked__Availability__c testAvailability1 = new sked__Availability__c(
        	sked__Resource__c = testResource.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = 'Pending',
            sked__Start__c = System.now(),
            sked__Finish__c = System.now().addHours(1),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Staffing_Budget__c = testStaffingBudget.Id,
            sked_Custom_Status__c = 'Pending',
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO
        );
        insert testAvailability1;

        skedModels.availability testAvailability1Model = new skedModels.availability();
        testAvailability1Model.id = testAvailability1.Id;
        testAvailability1Model.resourceId = testResource.Id;
        testAvailability1Model.isAvailable = false;
        testAvailability1Model.status = 'Pending';
        testAvailability1Model.staffingBudget = testStaffingBudgetModel;
        testAvailability1Model.eventType = skedConstants.AVAILABILITY_TYPE_PTO;
        testAvailability1Model.bypassAutoApprovalProcess = false;
        testAvailability1Model.start = System.now();
        testAvailability1Model.finish = System.now().addHours(12);

        sked__Availability__c testAvailability2 = new sked__Availability__c(
        	sked__Resource__c = testResource.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = 'Pending',
            sked__Start__c = System.now(),
            sked__Finish__c = System.now().addhours(1),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Staffing_Budget__c = testStaffingBudget.Id,
            sked_Custom_Status__c = 'Pending',
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO
        );
        insert testAvailability2;

        skedModels.availability testAvailability2Model = new skedModels.availability();
        testAvailability2Model.id = testAvailability2.Id;
        testAvailability2Model.resourceId = testResource.Id;
        testAvailability2Model.isAvailable = false;
        testAvailability2Model.status = 'Pending';
        testAvailability2Model.staffingBudget = testStaffingBudgetModel;
        testAvailability2Model.eventType = skedConstants.AVAILABILITY_TYPE_PTO;
        testAvailability2Model.bypassAutoApprovalProcess = false;
        testAvailability2Model.start = System.now();
        testAvailability2Model.finish = System.now().addHours(1);

        skedAvailabilityService testService = new skedAvailabilityService();
        testService.requireConflictValidation = true;

        Test.startTest();
            skedDataService.saveResult result = testService.saveRecords(new List<skedModels.availability>{testAvailability1Model, testAvailability2Model});
        Test.stopTest();
    }

    @isTest
    static void saveUnavailability_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCollectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        
        sked_Staffing_Budget__c testStaffingBudget = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = System.today(),
            sked_Bidding_Start_Date__c = System.today().addYears(1),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation.id,
            sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT,
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = System.today(),
            sked_Total_Slots__c = 100
        );
        insert testStaffingBudget;

        sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCo1 = new sked_Staffing_Budget_Collection_Op__c(
            sked_Staffing_Budget__c = testStaffingBudget.Id,
            sked_Biomed_Collection_Operation__c = testCollectionOperation.Id
        );
        insert testStaffingBudgetCo1;

        sked__Availability__c testAvailability1 = new sked__Availability__c(
        	sked__Resource__c = testResource.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = 'Pending',
            sked__Start__c = System.now(),
            sked__Finish__c = System.now().addhours(1),
            sked_Bypass_Auto_Approval_Process__c = FALSE,
            sked_Staffing_Budget__c = testStaffingBudget.Id,
            sked_Custom_Status__c = 'Pending',
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO
        );
        insert testAvailability1;

        skedModels.availability testAvailability1Model = new skedModels.availability();
        testAvailability1Model.id = testAvailability1.Id;
        testAvailability1Model.resourceId = testResource.Id;
        testAvailability1Model.isAvailable = false;
        testAvailability1Model.status = 'Pending';
        testAvailability1Model.eventType = skedConstants.AVAILABILITY_TYPE_PTO;
        testAvailability1Model.bypassAutoApprovalProcess = false;
        testAvailability1Model.start = System.now().addDays(5);
        testAvailability1Model.finish = System.now().addDays(5).addHours(12);


        Test.startTest();
            skedAvailabilityService service = new skedAvailabilityService();
            service.saveUnavailability(new List<skedModels.availability>{testAvailability1Model});
        Test.stopTest();
    }

    @isTest
    static void getQueryConditions_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCollectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        sked__Region__c testRegion = [SELECT Id FROM sked__Region__c LIMIT 1][0];

        sked_Staffing_Budget__c testStaffingBudget = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = System.today(),
            sked_Bidding_Start_Date__c = System.today().addYears(1),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation.id,
            sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT,
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = System.today(),
            sked_Total_Slots__c = 100
        );
        insert testStaffingBudget;

        sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCo1 = new sked_Staffing_Budget_Collection_Op__c(
            sked_Staffing_Budget__c = testStaffingBudget.Id,
            sked_Biomed_Collection_Operation__c = testCollectionOperation.Id
        );
        insert testStaffingBudgetCo1;

        skedAvailabilityService.queryModel model = new skedAvailabilityService.queryModel();
        model.availabilityStatuses = new List<String>{skedConstants.AVAILABILITY_STATUS_APPROVED};
        model.biomedCollectionOpIds = new List<String>{testCollectionOperation.Id};
        model.isAvailable = true;
        model.isException = false;
        model.regionIds = new List<String>{testRegion.Id};
        model.resourceCategories = new List<String>{skedConstants.RESOURCE_TYPE_PERSON};
        model.roles = new List<String>{'2RBC'};
        model.statuses = new List<String>{skedConstants.AVAILABILITY_STATUS_APPROVED};

        Test.startTest();
            skedAvailabilityService service = new skedAvailabilityService();
            service.query(model);
        Test.stopTest();
    }
    
    //----------//HRP-16778-----------start
    @isTest
    static void getQueryConditions_Test2() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCollectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        sked__Region__c testRegion = [SELECT Id FROM sked__Region__c LIMIT 1][0];

        sked_Staffing_Budget__c testStaffingBudget = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = System.today(),
            sked_Bidding_Start_Date__c = System.today().addYears(1),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation.id,
            sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT,
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = System.today(),
            sked_Total_Slots__c = 100
        );
        insert testStaffingBudget;

        sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCo1 = new sked_Staffing_Budget_Collection_Op__c(
            sked_Staffing_Budget__c = testStaffingBudget.Id,
            sked_Biomed_Collection_Operation__c = testCollectionOperation.Id
        );
        insert testStaffingBudgetCo1;

        skedAvailabilityService.queryModel model = new skedAvailabilityService.queryModel();
        model.availabilityStatuses = new List<String>{skedConstants.AVAILABILITY_STATUS_APPROVED};
        model.biomedCollectionOpIds = new List<String>{testCollectionOperation.Id};
        model.isAvailable = true;
        model.isCalloutRelated = true;
        model.regionIds = new List<String>{testRegion.Id};
        model.resourceCategories = new List<String>{skedConstants.RESOURCE_TYPE_PERSON};
        model.roles = new List<String>{'2RBC'};
        model.statuses = new List<String>{skedConstants.AVAILABILITY_STATUS_APPROVED};

        Test.startTest();
            skedAvailabilityService service = new skedAvailabilityService();
            service.query(model);
        	model.isException = false;
        	model.isCalloutRelated = null;
        	service.query(model);
        Test.stopTest();
    }
    //----------//HRP-16778-----------end
    
    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

    }
}