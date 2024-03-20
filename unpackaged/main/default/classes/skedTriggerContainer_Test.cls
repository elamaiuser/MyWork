@isTest
private class skedTriggerContainer_Test {
    @isTest
    static void skedTriggerContainer_Test() {

    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }
}