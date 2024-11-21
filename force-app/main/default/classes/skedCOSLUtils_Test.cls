@isTest
private class skedCOSLUtils_Test {
    @isTest
    static void generateCOSLForCurrentCOAddress_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();

        delete [SELECT Id FROM sked_Staging_Location__c];

        Test.startTest();
        skedCOSLUtils.generateCOSLForCurrentCOAddress();
        Test.stopTest();
    }

    @isTest
    static void getCoslsByCoIds_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        List<skedCOSLUtils.CoslQueryModel> coslQueryModels = new List<skedCOSLUtils.CoslQueryModel>();
        coslQueryModels.add(new skedCOSLUtils.CoslQueryModel(
            testCo.Id,
            skedConstants.EARLIEST_START_DATE,
            skedConstants.LATEST_END_DATE
        ));

        Test.startTest();
        skedCOSLUtils.getCoslsByCoIds(coslQueryModels);
        Test.stopTest();
    }
}