@isTest
private class skedPendingPTOsController_Test {
    @isTest
    static void skedPendingPTOsController_Test() {
        List<sked__Availability__c> testAvailabilities = [SELECT Id FROM sked__Availability__c];
        for (sked__Availability__c testAvailability : testAvailabilities) {
            testAvailability.sked__Status__c = skedConstants.AVAILABILITY_STATUS_PENDING;
            testAvailability.sked_Custom_Status__c = null;
            testAvailability.sked__Is_Available__c = false;
        }
        update testAvailabilities;

        Test.startTest();
            skedPendingPTOsController ptoController = new skedPendingPTOsController();
        Test.stopTest();

        System.assert(!ptoController.Unavailabilities.isEmpty());
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
    }
}