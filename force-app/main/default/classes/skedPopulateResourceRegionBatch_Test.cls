@isTest
private class skedPopulateResourceRegionBatch_Test {
    @isTest
    static void skedPopulateResourceRegionBatch_Test() {
        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCo = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c LIMIT 1][0];

        testResource.sked_Collection_Operation_Name_Staging__c = testCo.Name;
        update testResource;

        Test.startTest();
            Database.executeBatch(new skedPopulateResourceRegionBatch(new Set<Id>{testResource.Id}));
        Test.stopTest();
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
    }
}