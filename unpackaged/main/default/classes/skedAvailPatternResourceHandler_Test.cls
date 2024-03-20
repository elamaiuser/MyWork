@isTest
private class skedAvailPatternResourceHandler_Test {
    @isTest
    static void skedAvailabilityPatternResourceHandler_Test() {
        sked__Availability_Pattern_Resource__c testPatternResource = [SELECT Id, sked__Start__c FROM sked__Availability_Pattern_Resource__c LIMIT 1][0];
        
        Test.startTest();
            testPatternResource.sked__Start__c = System.today().addDays(20);
            update testPatternResource;
        Test.stopTest();
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');

        sked__Availability_Pattern_Resource__c testPatternResource1 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = System.today().addDays(10)
        );
        insert testPatternResource1;
    }
}