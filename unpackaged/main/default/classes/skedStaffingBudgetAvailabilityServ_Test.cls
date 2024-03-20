@isTest
private class skedStaffingBudgetAvailabilityServ_Test {
    @isTest
    static void staffingBudgetAvailabilityService_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        Biomed_Collection_Op_Center__c testCollectionOperation = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        
        sked_Staffing_Budget__c testStaffingBudget = (sked_Staffing_Budget__c) mapTestData.get('testStaffingBudget1');
        testStaffingBudget.sked_Biomed_Collection_Op_Center__c = testCollectionOperation.Id;
        update testStaffingBudget;

        sked__Availability__c testAvailability = new sked__Availability__c(
            sked__Resource__c = testResource.Id,
            sked__Type__c = 'PTO',
            sked__Is_Available__c = false,
            sked__Start__c = testDataFactory.summary.startDate.addDays(2),
            sked__Finish__c = testDataFactory.summary.startDate.addDays(2),
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED
        );
        insert testAvailability;

        skedStaffingBudgetAvailabilityService.queryModel model = new skedStaffingBudgetAvailabilityService.queryModel();
        model.availabilityStatuses = new List<String>{skedConstants.AVAILABILITY_STATUS_APPROVED};
        model.availabilityIds = new List<String>{testAvailability.Id};
        model.staffingBudgetIds = new List<String>{testStaffingBudget.Id};

        Test.startTest();
            skedStaffingBudgetAvailabilityService service = new skedStaffingBudgetAvailabilityService();
            List<sObject> results = service.query(model);
        Test.stopTest();

        System.assert(!results.isEmpty());
    }
}