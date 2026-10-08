@isTest(SeeAllData = false)
private class skedAPResourceTrigger_Test {
    
    @testSetup
    static void prepareTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        
        Collection_Operation_Availability__c testCoAp = new Collection_Operation_Availability__c(
        	Name = testCollectionOperation1.Name + ' ' + testWeeklyPattern1.Name,
        	Collection_Operation__c = testCollectionOperation1.Id,
        	Availability_Pattern__c = testWeeklyPattern1.Id,
        	Effective_Start_Date__c = system.today(),
        	Effective_End_Date__c = Date.newInstance(4000, 12, 30),
        	Total_Target__c = 5
        );
        insert testCoAp;
        
        sked__Availability_Pattern_Resource__c testPatternResource1 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = testDataFactory.summary.startTime.addDays(1)
        );
        sked__Availability_Pattern_Resource__c testPatternResource2 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource2.Id, 
            sked__Start__c = testDataFactory.summary.startTime.addDays(1)
        );
        insert new List<sked__Availability_Pattern_Resource__c>{testPatternResource1, testPatternResource2};
    }
    
    static testMethod void testEndApResourceFunctionality() {
        Test.startTest();
        
        List<sked__Availability_Pattern_Resource__c> testApResources = [SELECT Id, sked__Start__c, sked_End_Date__c FROM sked__Availability_Pattern_Resource__c];
        testApResources[0].sked_End_Date__c = testApResources[0].sked__Start__c.date().addDays(2);
        update testApResources[0];
        
        Test.stopTest();
        sked__Resource__c testResource = [SELECT Id, CO_AP_Status__c FROM sked__Resource__c LIMIT 1];
        Assert.isTrue(testResource.CO_AP_Status__c != null);
    }
}