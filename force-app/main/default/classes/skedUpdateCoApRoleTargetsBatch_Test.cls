@isTest(SeeAllData = false)
private class skedUpdateCoApRoleTargetsBatch_Test {

    @testSetup
    static void prepareTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testResource2 = (sked__Resource__c)mapTestData.get('testResource2');
        
        sked__Availability_Pattern_Resource__c testPatternResource1 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = DateTime.now()
        );
        insert testPatternResource1;
    }
    
    static testMethod void testBatchWithCoId() {
        Test.startTest();
        
        Biomed_Collection_Op_Center__c testCo = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1];
        Database.executeBatch(new skedNightlyUpdateCoApRoleTargetsBatch(new Set<Id>{testCo.Id}), 100);
        
        Test.stopTest();
        List<Collection_Operation_Availability__c> testCoAp = [SELECT Id FROM Collection_Operation_Availability__c];
        Assert.isTrue(testCoAp != null && !testCoAp.isEmpty());
    }
    
    static testMethod void testBatchScheduling() {
        Test.startTest();
       
        String jobID = System.schedule('Test Minimum Role Targets Batch', '0 0 0 ? * *', new skedNightlyUpdateCoApRoleTargetsBatch());
        
        Test.stopTest(); 
        Assert.isTrue(jobID != null);
    }
    
    static testMethod void testBatchRunWithExistingCoAp() {
        Test.startTest();
       
        Biomed_Collection_Op_Center__c testCo = [SELECT Id, Grand_Total_Needed_AP__c, Name FROM Biomed_Collection_Op_Center__c LIMIT 1];
        sked__Availability_Pattern__c testAp = [SELECT Id, Name FROM sked__Availability_Pattern__c LIMIT 1];
        
        skedHubBase.BypassUpdateTriggers = true;
        update new Biomed_Collection_Op_Center__c(Id = testCo.Id, Grand_Total_Needed_AP__c = 10);
        skedHubBase.BypassUpdateTriggers = false; 
        
        Collection_Operation_Availability__c testCoAp = new Collection_Operation_Availability__c(
        	Name = testCo.Name + ' ' + testAp.Name,
        	Collection_Operation__c = testCo.Id,
        	Availability_Pattern__c = testAp.Id,
        	Effective_Start_Date__c = system.today(),
        	Effective_End_Date__c = Date.newInstance(4000, 12, 30),
        	Total_Target_Fixed_Site__c = 5,
            Total_Target_Mobile__c = 5
        );
        insert testCoAp;
        
        Availability_Pattern_Role__c testApRole = new Availability_Pattern_Role__c(
        	Collection_Operation_Availability__c = testCoAp.Id,
        	Min_Nbr_of_Role__c = 1,
        	Role__c = '2RBC'
        );
        insert testApRole;
        
        Database.executeBatch(new skedNightlyUpdateCoApRoleTargetsBatch(new Set<Id>{testCo.Id}), 100);
        
        Test.stopTest();
        sked__Resource__c testResource = [SELECT Id, CO_AP_Status__c FROM sked__Resource__c LIMIT 1];
        Assert.isTrue(testResource.CO_AP_Status__c.equals('Processed'));
    }
}