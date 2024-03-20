@isTest
private class skedResourceTagService_Test {
    @isTest
    static void getResourceIdsByTagIds_Test() {
        List<sked__Tag__c> tags = [SELECT Id FROM sked__Tag__c];
        List<String> tagIds = new List<String>();
        for (sked__Tag__c tag : tags) {
            tagIds.add(tag.Id);
        }

        Test.startTest();
            skedResourceTagService service = new skedResourceTagService();
            List<String> resourceIds = service.getResourceIdsByTagIds(tagIds);
        Test.stopTest();

        System.assert(!resourceIds.isEmpty());
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }
}