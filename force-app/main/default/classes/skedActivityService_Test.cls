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
        model.subQueryIndicator = skedSObjectType.ACTIVITY_RESOURCE | skedSObjectType.ACTIVITY_COLLECTION_OPERATION;
        model.territoryKeys = new List<String>{'testTerritoryKey'};
        model.biomedCollectionOpIds = new List<String>{testCo.Id};
        model.regionIds = new List<String>{testRegion.Id};
        model.resourceIds = new List<String>{testResource.Id};
        model.subTypes = new List<String>{'testSubType'};
        model.resourceCategories = new List<String>{'testCategory'};
        model.isGroupActivity = true;
        model.recurringScheduleIds = new List<String>{testCo.Id};
        model.activityTypes = new List<String>{'After Hours Call Out Management'};
        model.startTime = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 4, 0, 0);
        model.endTime = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 9, 0, 0);

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
    
    @isTest
    static void postSaveRecordTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCo1 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        Biomed_Collection_Op_Center__c testCo2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');
        sked_Territory__c testDistrict = (sked_Territory__c) mapTestData.get('testTerritory1');
        
        List<sked_Territory_Collection_Operation__c> testTerritoryColOpList = new List<sked_Territory_Collection_Operation__c>();        
        sked_Territory_Collection_Operation__c testTerritoryColOp;
        
        testTerritoryColOp = new sked_Territory_Collection_Operation__c(
        	sked_Territory__c = testDistrict.Id,
        	sked_Collection_Operation__c = testCo1.Id);
        testTerritoryColOpList.add(testTerritoryColOp);

        testTerritoryColOp = new sked_Territory_Collection_Operation__c(
        	sked_Territory__c = testDistrict.Id,
        	sked_Collection_Operation__c = testCo2.Id);
        testTerritoryColOpList.add(testTerritoryColOp);
        insert testTerritoryColOpList;
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked__Type__c = 'After Hours Call Out Management',
            sked__Start__c = system.now().addHours(9),
            sked__End__c = system.now().addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Drive_Types__c = 'Fixed Site;Mobile',
            sked_Is_Group_Activity__c = TRUE
        );
        insert testActivity;
        
        sked_Activity_Collection_Operation__c testActivityCO = new sked_Activity_Collection_Operation__c(
        	sked_Activity__c = testActivity.Id,
        	sked_Biomed_Collection_Operation__c = testCo1.Id,
        	sked_District__c = testDistrict.Id);
        insert testActivityCO;
        
        skedModels.activity testActivityModel = new skedModels.activity();
        testActivityModel.id = testActivity.Id;
        testActivityModel.biomedCollectionOpIds = new List<String>{testCo1.Id, testCo2.Id};
        testActivityModel.startDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        testActivityModel.endDate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
        
        Test.startTest();
        skedActivityService service = new skedActivityService();
        service.saveRecords(new List<skedModels.activity>{testActivityModel});
        Integer testActivityCoCount = [SELECT count() FROM sked_Activity_Collection_Operation__c WHERE sked_Activity__c =:testActivity.Id];
        Assert.isTrue(testActivityCoCount == 2);
        Test.stopTest();
        
    }
}