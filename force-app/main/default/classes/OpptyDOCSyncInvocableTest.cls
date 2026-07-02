@isTest
private class OpptyDOCSyncInvocableTest {
	@testSetup 
    static void prepareTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        Opportunity testOpp = (Opportunity) mapTestData.get('testOpportunity');
        
        testDrive.sked_Number_of_2RBC_Assets__c = 1;
        
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('DriveTriggerHandler');
        update testDrive;
        skedHubBase.BypassUpdateTriggers = false;
        triggerHandler.clearAllBypasses();
    }
    
    @isTest
    private static void updateOpptyTest(){
        sked_Drive__c testDrive = [Select Id, sked_Number_of_2RBC_Assets__c, sked_Opportunity__c FROM sked_Drive__c WHERE Name = 'Test Drive' LIMIT 1];
        
        OpptyDOCSyncInvocable.InputWrapper syncInputs = new OpptyDOCSyncInvocable.InputWrapper();
        syncInputs.Id = testDrive.sked_Opportunity__c;
        syncInputs.X2RBCAssets = String.valueOf(testDrive.sked_Number_of_2RBC_Assets__c);
        
        Test.startTest();
        OpptyDOCSyncInvocable.updateOppty(new List<OpptyDOCSyncInvocable.InputWrapper>{syncInputs});
        Test.stopTest();
        
        Opportunity testOpp = [Select Id, Number_of_2RBC_Assets__c FROM Opportunity WHERE Id =: testDrive.sked_Opportunity__c LIMIT 1];
        
        Assert.areEqual(testDrive.sked_Number_of_2RBC_Assets__c, testOpp.Number_of_2RBC_Assets__c);
        
    }
    
    @isTest
    private static void updateOpptyUpdateExceptionTest(){
        sked_Drive__c testDrive = [Select Id, sked_Number_of_2RBC_Assets__c, sked_Opportunity__c FROM sked_Drive__c WHERE Name = 'Test Drive' LIMIT 1];
        
        OpptyDOCSyncInvocable.InputWrapper syncInputs = new OpptyDOCSyncInvocable.InputWrapper();
        //syncInputs.Id = testDrive.sked_Opportunity__c;
        syncInputs.X2RBCAssets = String.valueOf(testDrive.sked_Number_of_2RBC_Assets__c);
        
        Test.startTest();
        OpptyDOCSyncInvocable.updateOppty(new List<OpptyDOCSyncInvocable.InputWrapper>{syncInputs});
        Test.stopTest();
    }
    
    @isTest
    private static void updateOpptyRunTimeExceptionTest(){
        sked_Drive__c testDrive = [Select Id, sked_Number_of_2RBC_Assets__c, sked_Opportunity__c FROM sked_Drive__c WHERE Name = 'Test Drive' LIMIT 1];
        
        OpptyDOCSyncInvocable.InputWrapper syncInputs = new OpptyDOCSyncInvocable.InputWrapper();
        syncInputs.Id = testDrive.sked_Opportunity__c;
        syncInputs.X2RBCAssets = String.valueOf(testDrive.sked_Number_of_2RBC_Assets__c);
        BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION = true;
        
        Test.startTest();
        OpptyDOCSyncInvocable.updateOppty(new List<OpptyDOCSyncInvocable.InputWrapper>{syncInputs});
        Test.stopTest();
    }
}