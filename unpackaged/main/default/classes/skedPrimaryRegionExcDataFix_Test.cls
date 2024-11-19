@isTest
private class skedPrimaryRegionExcDataFix_Test {
    @isTest
    static void skedPrimaryRegionExcDataFix_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Region__c testRegion2 = (sked__Region__c) mapTestData.get('testRegion2');

        skedHC__Exception__c testException = new skedHC__Exception__c();
        testException.skedHC__Exception__c = 'Test Resource has Primary Region changed from ' + testRegion.Id + ' to ' + testRegion2.Id;
        insert testException;

        Test.startTest();
            Database.executeBatch(new skedPrimaryRegionExcDataFixBatch());
        Test.stopTest();

        testException = [SELECT Id, skedHC__Exception__c FROM skedHC__Exception__c WHERE Id = :testException.Id];
        Assert.isTrue(testException.skedHC__Exception__c.contains(testRegion.Name));
        Assert.isTrue(testException.skedHC__Exception__c.contains(testRegion2.Name));
    }
}