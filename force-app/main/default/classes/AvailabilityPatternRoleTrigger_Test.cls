@isTest(SeeAllData = false)
private class AvailabilityPatternRoleTrigger_Test {

    @testSetup
    static void prepareTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');

        sked__Availability_Pattern_Resource__c testPatternResource = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = testDataFactory.summary.startTime.addDays(1)
        );
        insert testPatternResource;
        
        Collection_Operation_Availability__c testCoAp = new Collection_Operation_Availability__c(
        	Name = testCollectionOperation1.Name + ' ' + testWeeklyPattern1.Name,
        	Collection_Operation__c = testCollectionOperation1.Id,
        	Availability_Pattern__c = testWeeklyPattern1.Id,
        	Effective_Start_Date__c = system.today(),
        	Effective_End_Date__c = Date.newInstance(4000, 12, 30),
        	Total_Target__c = 5
        );
        insert testCoAp;
        
        Availability_Pattern_Role__c testApRole = new Availability_Pattern_Role__c(
        	Collection_Operation_Availability__c = testCoAp.Id,
        	Min_Nbr_of_Role__c = 1,
        	Role__c = '2RBC'
        );
        insert testApRole;
    }
    
    static testMethod void testUpdateResource() {
        Test.startTest();
        
        Availability_Pattern_Role__c testApRole = [SELECT Id, Min_Nbr_of_Role__c FROM Availability_Pattern_Role__c LIMIT 1];
        testApRole.Min_Nbr_of_Role__c = 2;
        update testApRole;
        
        Test.stopTest();
        
        sked__Resource__c testResource = [SELECT Id, CO_AP_Status__c FROM sked__Resource__c LIMIT 1];
        Assert.isTrue(testResource.CO_AP_Status__c != null);
    }
}