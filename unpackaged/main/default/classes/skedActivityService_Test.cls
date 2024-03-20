@isTest
private class skedActivityService_Test {
    @isTest
    static void getQueryConditionsTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        skedActivityService.queryModel model = new skedActivityService.queryModel();
        model.subQueryIndicator = skedSObjectType.ACTIVITY_RESOURCE;
        model.territoryKeys = new List<String>{'testTerritoryKey'};
        model.biomedCollectionOpIds = new List<String>{testCo.Id};
        model.regionIds = new List<String>{testRegion.Id};
        model.resourceIds = new List<String>{testResource.Id};
        model.subTypes = new List<String>{'testSubType'};
        model.resourceCategories = new List<String>{'testCategory'};
        model.isGroupActivity = true;
        model.recurringScheduleIds = new List<String>{testCo.Id};

        Test.startTest();
        skedActivityService activityService = (skedActivityService)skedServiceFactory.instance.resolve('sked__Activity__c');
        List<sked__Activity__c> result = (List<sked__Activity__c>)activityService.query(model);

        Date startDate = System.today();
        model.startDate = '' + startDate.year() + '-' + startDate.month() + '-' + startDate.day();
        result = (List<sked__Activity__c>)activityService.query(model);

        model.startDate = null;
        model.endDate = '' + startDate.year() + '-' + startDate.month() + '-' + startDate.day();
        result = (List<sked__Activity__c>)activityService.query(model);

        model.startDate =  '' + startDate.year() + '-' + startDate.month() + '-' + startDate.day();
        result = (List<sked__Activity__c>)activityService.query(model);
        Test.stopTest();
    }
}