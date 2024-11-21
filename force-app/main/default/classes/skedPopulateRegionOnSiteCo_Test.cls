@isTest
private class skedPopulateRegionOnSiteCo_Test {

    static testmethod void skedPopulateRegionOnSiteCo_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Test.startTest();
        
        Database.executeBatch(new skedPopulateRegionOnSiteCo_Batch(), 1);
        
        Test.stopTest();
    }
}