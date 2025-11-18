@isTest 
private class CreateSkedFixedSiteDriveBatchTest {
    
    @testSetup
    static void prepareTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        GenerateDriveTestData.setupData();
    }
    
    @isTest
    private static void testSkedFixedSiteBatch() {
        Test.startTest();
                   
        Id batchJobId = Database.executeBatch(new CreateSkedFixedSiteDriveBatch([SELECT Id, RecordTypeId FROM Opportunity]),200);
        Test.stopTest();   
    }
}