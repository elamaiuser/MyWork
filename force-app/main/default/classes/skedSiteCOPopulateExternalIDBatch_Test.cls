@isTest
private class skedSiteCOPopulateExternalIDBatch_Test {

    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked_Site_Collection_Operation__c testSiteCO = (sked_Site_Collection_Operation__c)mapTestData.get('testLocation1_testCollectionOperation1');
        testSiteCO.sked_External_ID__c = NULL;
        update testSiteCO;
        
        Test.startTest();
        
        Database.executeBatch(new skedSiteCOPopulateExternalIDBatch(), 200);
        
        Test.stopTest();
    }
    
}