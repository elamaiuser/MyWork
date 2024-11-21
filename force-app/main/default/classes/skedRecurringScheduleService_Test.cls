@isTest
private class skedRecurringScheduleService_Test {
    @isTest
    static void query_Test() {
        sked__Recurring_Schedule__c testSchedule = [SELECT Id FROM sked__Recurring_Schedule__c LIMIT 1][0];
        skedRecurringScheduleService.queryModel model = new skedRecurringScheduleService.queryModel();
        model.recordIds = new List<String>{testSchedule.Id};
        
        Test.startTest();
            skedRecurringScheduleService service = new skedRecurringScheduleService();
            List<sked__Recurring_Schedule__c> results = service.query(model);
        Test.stopTest();

        System.assert(!results.isEmpty());
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();    
    }
}