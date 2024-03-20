@isTest
private class skedRegionService_Test {
    @isTest
    static void query_Test() {
        Biomed_Collection_Op_Center__c testCo = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        skedRegionService.queryModel model = new skedRegionService.queryModel();
        model.biomedCollectionOpId = testCo.Id;
        model.timezoneSidId = UserInfo.getTimeZone().getID();

        Test.startTest();
        skedRegionService service = new skedRegionService();
            List<sked__Region__c> regions = service.query(model);
        Test.stopTest();

        System.assert(!regions.isEmpty());
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }
}