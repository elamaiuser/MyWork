@isTest
private class skedLexResourceController_Test {
    @isTest
    static void getResourceTemplates_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();   
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        List<sked__Availability_Template__c> result = skedLexResourceController.getResourceTemplates(testResource1.Id);
        
        Test.stopTest();
    }

    @isTest
    static void getPatternResources_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();   
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        
        sked__Availability_Pattern_Resource__c testPatternResource = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = System.today().addDays(-1)
        );
        insert testPatternResource;
        
        Test.startTest();
        
        List<sked__Availability_Pattern_Resource__c> patternResources = skedLexResourceController.getPatternResources(testResource1.Id);
        
        Test.stopTest();
    }
    
}