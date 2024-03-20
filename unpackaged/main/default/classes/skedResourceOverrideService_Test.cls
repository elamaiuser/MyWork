@isTest
private class skedResourceOverrideService_Test {
    @isTest
    static void getResourceIds_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCo = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        sked__Resource_Override__c testResourceOverride = new sked__Resource_Override__c(
            sked__Resource__c = testResource.Id,
            sked_Collection_Operation__c = testCo.Id,
            sked__End__c = System.now().addHours(6),
            sked__Start__c = System.now().addHours(6),
            sked_Travel_To_Start__c = System.now().addMinutes(5),
            sked_Travel_To_End__c = System.now().addMinutes(5),
            sked_Travel_Back_Start__c = System.now().addMinutes(5),
            sked_Travel_Back_End__c = System.now().addMinutes(5),
            sked_End_Date__c = System.today(),
            sked_Start_Date__c = System.today(),
            sked_Travel_Back_End_Date__c = System.today(),
            sked_Travel_Back_Start_Date__c = System.today(),
            sked_Travel_To_End_Date__c = System.today(),
            sked_Travel_To_Start_Date__c = System.today(),
            sked_End_Time__c = System.now().time(),
            sked_Travel_Back_End_Time__c = System.now().addMinutes(5).time(),
            sked_Travel_Back_Start_Time__c = System.now().time(),
            sked_Travel_To_End_Time__c = System.now().addMinutes(5).time(),
            sked_Start_Time__c = System.now().time(),
            sked_Travel_To_Start_Time__c = System.now().addMinutes(5).time()
        );
        insert testResourceOverride;

        skedResourceOverrideService.queryModel query = new skedResourceOverrideService.queryModel();
        query.startTime = System.now();
        query.endTime = System.now().addHours(6);
        query.biomedCollectionOpIds = new List<String>();
        query.biomedCollectionOpIds.add(testCo.Id);

        Test.startTest();
            skedResourceOverrideService service = new skedResourceOverrideService();
            List<string> result = service.getResourceIds(query);
        Test.stopTest();

        //System.assertEquals(1, result.size());
        //System.assertEquals(testResource.Id, result[0]);
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }
}