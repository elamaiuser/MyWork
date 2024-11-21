@isTest
private class skedCustomAvailabilityHandler_Test {
    @isTest
    static void skedCustomAvailabilityHandler_Test() {
        sked_Custom_Availability__c testCustomAvailability = [SELECT Id, sked_Start__c FROM sked_Custom_Availability__c LIMIT 1][0];
        
        Test.startTest();
            testCustomAvailability.sked_Start__c = System.today().addDays(20);
            update testCustomAvailability;
        Test.stopTest();
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked_Custom_Availability__c testCustomAvailability = new sked_Custom_Availability__c(
            sked_Type__c = 'Volunteer',
            sked_Status__c = 'Approved',
            sked_Notes__c = 'Test Custom Availability',
            sked_Resource__c = testResource1.Id,
            sked_Start__c = System.today().addDays(5),
            sked_Finish__c = System.today().addDays(10)
        );
        insert testCustomAvailability;
    }
}