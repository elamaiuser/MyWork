@isTest
private class slwcAccountService_Test {
    @isTest
    static void searchMarket_Test() {
        List<AggregateResult> result = slwcAccountService.searchMarket('test-market');
        System.assert(!result.isEmpty());
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 

        Account testAccount1 = (Account)mapTestData.get('testAccount1');
        testAccount1.Market__c = 'test-market';
        update testAccount1;
    }
}