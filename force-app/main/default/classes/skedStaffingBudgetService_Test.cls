@isTest
private class skedStaffingBudgetService_Test {
    @isTest
    static void preSaveRecord_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCollectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        
        sked_Staffing_Budget__c testStaffingBudget = [
            SELECT Id, sked_Approved_Slots_Rollup__c, sked_Bidding_End_Date__c, sked_Bidding_Start_Date__c, 
            sked_Biomed_Collection_Op_Center__c, sked_Pending_Slots_Rollup__c, sked_Request_Type__c, 
            sked_Roles__c, sked_Staffing_Budget_Date__c, sked_Total_Slots__c, sked_Wait_List_Slots_Rollup__c
            FROM sked_Staffing_Budget__c LIMIT 1
        ][0];
        
        skedModels.staffingBudget testStaffingBudgetModel = new skedModels.staffingBudget();
        testStaffingBudgetModel.id = testStaffingBudget.Id;
        testStaffingBudgetModel.totalSlots = 100;
        testStaffingBudgetModel.staffingBudgetDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        testStaffingBudgetModel.roles = new List<String>();
        testStaffingBudgetModel.roles.add('2RBC');
        testStaffingBudgetModel.driveTypes = new List<String>();
        testStaffingBudgetModel.driveTypes.add('Mobile');
        testStaffingBudgetModel.driveTypes.add('Fixed Site');
        testStaffingBudgetModel.collectionOperationIds = new List<String>();
        testStaffingBudgetModel.collectionOperationIds.add(testCollectionOperation.Id);
        testStaffingBudgetModel.siteIds = new List<String>();
        testStaffingBudgetModel.requestType = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT;
        testStaffingBudgetModel.biddingStartDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        testStaffingBudgetModel.biddingEndDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        
        Test.startTest();
        skedStaffingBudgetService service = new skedStaffingBudgetService();
        service.saveRecords(new List<skedModels.staffingBudget>{testStaffingBudgetModel});
        Test.stopTest();
    }
    
    @isTest
    static void getQueryConditions_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCollectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        
        skedStaffingBudgetService.queryModel query = new skedStaffingBudgetService.queryModel();
        query.roles = new List<String>();
        query.roles.add('2RBC');
        query.startDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        query.endDate = System.today().addDays(100).year() + '-' + System.today().addDays(100).month() + '-' + System.today().addDays(100).day();
        query.biomedCollectionOpIds = new List<String>();
        query.biomedCollectionOpIds.add(testCollectionOperation.Id);
        query.excludeEmptySlots = true;
        query.requestTypes = new List<String>();
        query.requestTypes.add(skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT);
        query.subQueryIndicator = skedSObjectType.AVAILABILITY | skedSObjectType.STAFFING_BUDGET_AVAILABILITY;
        
        Test.startTest();
        
        skedStaffingBudgetService service = new skedStaffingBudgetService();
        service.query(query);
        
        Test.stopTest();
    }
    
    @isTest
    static void verifyStaffingBudget_Test() {
        sked__Resource__c testResource = [SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c FROM sked__Resource__c LIMIT 1][0];
        
        Date startDate = System.today();
        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'Available',
            sked__Is_Available__c = TRUE,
            sked__Start__c = startDate,
            sked__Finish__c = startDate,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED
        );
        insert testAvailability;
        
        skedModels.availability testAvailabilityModel = new skedModels.availability();
        testAvailabilityModel.startDate = startDate.year() + '-' + startDate.month() + '-' + startDate.day();
        
        List<skedModels.availability> testAvailabilityModels = new List<skedModels.availability>();
        testAvailabilityModels.add(testAvailabilityModel);
        
        Test.startTest();
        skedStaffingBudgetService service = new skedStaffingBudgetService();
        service.verifyStaffingBudget(testResource.Id, testAvailabilityModels);
        Test.stopTest();
    }

    @isTest
    static void verifyStaffingBudget_Test_VerifySick() {
        sked__Resource__c testResource = [SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c FROM sked__Resource__c LIMIT 1][0];
        
        Date startDate = System.today();
        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'Sick',
            sked__Is_Available__c = FALSE,
            sked__Start__c = startDate,
            sked__Finish__c = startDate,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED
        );
        insert testAvailability;
        
        skedModels.availability testAvailabilityModel = new skedModels.availability();
        testAvailabilityModel.startDate = startDate.year() + '-' + startDate.month() + '-' + startDate.day();
        testAvailabilityModel.eventType = skedConstants.AVAILABILITY_TYPE_SICK;
        
        List<skedModels.availability> testAvailabilityModels = new List<skedModels.availability>();
        testAvailabilityModels.add(testAvailabilityModel);
        
        Test.startTest();
        skedStaffingBudgetService service = new skedStaffingBudgetService();
        service.verifyStaffingBudget(testResource.Id, testAvailabilityModels);

        Test.stopTest();
    }

    @isTest
    static void verifyStaffingBudget_Test_VerifyPTO() {
        sked__Resource__c testResource = [SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c FROM sked__Resource__c LIMIT 1][0];
        
        Date startDate = System.today();
        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'PTO',
            sked__Is_Available__c = FALSE,
            sked__Start__c = startDate,
            sked__Finish__c = startDate,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED
        );
        insert testAvailability;
        
        skedModels.availability testAvailabilityModel = new skedModels.availability();
        testAvailabilityModel.startDate = startDate.year() + '-' + startDate.month() + '-' + startDate.day();
        testAvailabilityModel.eventType = skedConstants.AVAILABILITY_TYPE_PTO;
        
        List<skedModels.availability> testAvailabilityModels = new List<skedModels.availability>();
        testAvailabilityModels.add(testAvailabilityModel);
        
        Test.startTest();
        skedStaffingBudgetService service = new skedStaffingBudgetService();
        service.verifyStaffingBudget(testResource.Id, testAvailabilityModels);

        Test.stopTest();
    }
    
    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Resource__c testResource = (sked__Resource__c)mapTestData.get('testResource1');
        Biomed_Collection_Op_Center__c testCollectionOperation = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        
        sked_Staffing_Budget__c testStaffingBudget = new sked_Staffing_Budget__c(
            sked_Bidding_End_Date__c = System.today(),
            sked_Bidding_Start_Date__c = System.today(),
            sked_Request_Type__c = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT,
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = System.today(),
            sked_Total_Slots__c = 100
        );
        insert testStaffingBudget;

        sked_Staffing_Budget_Collection_Op__c testStaffingBudgetCollectionOp = new sked_Staffing_Budget_Collection_Op__c(
            sked_Staffing_Budget__c = testStaffingBudget.Id,
            sked_Biomed_Collection_Operation__c = testCollectionOperation.id
        );
        insert testStaffingBudgetCollectionOp;
    }
    
    @isTest
    static void postSaveRecord_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCollectionOperation = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        sked__Location__c testLocation = [SELECT Id FROM sked__Location__c LIMIT 1];
        
        sked_Staffing_Budget__c testStaffingBudget = [
            SELECT Id, sked_Approved_Slots_Rollup__c, sked_Bidding_End_Date__c, sked_Bidding_Start_Date__c, 
            sked_Biomed_Collection_Op_Center__c, sked_Pending_Slots_Rollup__c, sked_Request_Type__c, 
            sked_Roles__c, sked_Staffing_Budget_Date__c, sked_Total_Slots__c, sked_Wait_List_Slots_Rollup__c
            FROM sked_Staffing_Budget__c LIMIT 1
        ][0];
        
        skedModels.staffingBudget testStaffingBudgetModel = new skedModels.staffingBudget();
        testStaffingBudgetModel.id = testStaffingBudget.Id;
        testStaffingBudgetModel.totalSlots = 100;
        testStaffingBudgetModel.staffingBudgetDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        testStaffingBudgetModel.roles = new List<String>();
        testStaffingBudgetModel.roles.add('2RBC');
        testStaffingBudgetModel.driveTypes = new List<String>();
        testStaffingBudgetModel.driveTypes.add('Mobile');
        testStaffingBudgetModel.driveTypes.add('Fixed Site');
        testStaffingBudgetModel.collectionOperationIds = new List<String>();
        testStaffingBudgetModel.siteIds = new List<String>{testLocation.Id};
        testStaffingBudgetModel.requestType = skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT;
        testStaffingBudgetModel.biddingStartDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        testStaffingBudgetModel.biddingEndDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        
        Test.startTest();
        skedStaffingBudgetService service = new skedStaffingBudgetService();
        service.saveRecords(new List<skedModels.staffingBudget>{testStaffingBudgetModel});
        Test.stopTest();
    }
}