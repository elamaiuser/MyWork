@isTest
private class skedSObjectUtils_Test {
    @isTest
    static void getRecordIds_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        List<sked__Tag__c> tags = [SELECT Id, Name FROM sked__Tag__c]; 
        Set<Id> recordIds = skedSObjectUtils.getRecordIds(tags);
        System.assertEquals(recordIds.size(), tags.size());
    }
}