@isTest
private class slwcAvailabilityService_Test {
    
    @isTest
    static void getUnavailabilityStatistic_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        slwcAvailabilityService.getUnavailabilityStatistic(testResource.Id, '2024-12-01', true);
    }
}