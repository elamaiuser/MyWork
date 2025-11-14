@isTest
private class skedFsppHandler_Test {
    
    @testSetup
    static void prepareTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        Account testAccount1 = (Account)mapTestData.get('testAccount1');
          
        Opportunity testOpp1 = new Opportunity(
            Name = 'Test Drive',
            AccountId = testAccount1.Id,
            Drive_Date__c = system.today().addDays(10),
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Drive_Site__c = testLocation1.Id,
            StageName = 'Solicitation',
            CloseDate = system.today(),
            Online_Scheduling_Enabled__c = 'No',
            Accept_56_Day_Rule_Violation__c = true,
            Slot_Generator__c = 130
        );
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert testOpp1;
    }
    
    static testmethod void mainTest_insert() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        List<sked_Fixed_Site_Procedure_Projection__c> testFsppList = new List<sked_Fixed_Site_Procedure_Projection__c>();
        
        sked_Fixed_Site_Procedure_Projection__c fspp;
        fspp = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = testAccount.Id,
            sked_Deferral__c = 5,
            sked_QNS__c = 5,
            sked_Productive_Procedure_Goal__c = 10,
            sked_Procedure_Type__c = '2RBC',
            sked_Effective_Start_Date__c = system.today().addDays(-14),
            sked_Effective_End_Date__c = system.today().addDays(14)
        );
        testFsppList.add(fspp);
        
        fspp = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = testAccount.Id,
            sked_Deferral__c = 5,
            sked_QNS__c = 5,
            sked_Productive_Procedure_Goal__c = 10,
            sked_Procedure_Type__c = '2RBC'
        );
        testFsppList.add(fspp);
        
        fspp = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = testAccount.Id,
            sked_Deferral__c = 5,
            sked_QNS__c = 5,
            sked_Productive_Procedure_Goal__c = 10,
            sked_Procedure_Type__c = '2RBC',
            sked_Effective_End_Date__c = system.today().addDays(14)
        );
        testFsppList.add(fspp);
        
        fspp = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = testAccount.Id,
            sked_Deferral__c = 5,
            sked_QNS__c = 5,
            sked_Productive_Procedure_Goal__c = 10,
            sked_Procedure_Type__c = '2RBC',
            sked_Effective_Start_Date__c = system.today().addDays(-14)
        );
        testFsppList.add(fspp);
        
        insert testFsppList;
        
        List<sked_Fixed_Site_Procedure_Projection__c> testUpdatedFspps = [SELECT Id,
                                                                          sked_Impact_Drives__c 
                                                                          FROM sked_Fixed_Site_Procedure_Projection__c];
        Assert.isTrue(testUpdatedFspps[testUpdatedFspps.size() - 1].sked_Impact_Drives__c == true);

        Test.stopTest();
    }
    
    static testmethod void mainTest_update() {
        Test.startTest();
        Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        sked_Fixed_Site_Procedure_Projection__c fspp = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = testAccount1.Id,
            sked_Deferral__c = 5,
            sked_QNS__c = 5,
            sked_Productive_Procedure_Goal__c = 10,
            sked_Procedure_Type__c = '2RBC',
            sked_Effective_Start_Date__c = system.today().addDays(-14),
            sked_Effective_End_Date__c = system.today().addDays(14)
        );
        skedHubBase.BypassInsertTriggers = true;
        insert fspp;
        skedHubBase.BypassInsertTriggers = false;
        
        Assert.isTrue(fspp.sked_Impact_Drives__c == false);
        
        fspp.sked_Productive_Procedure_Goal__c = fspp.sked_Productive_Procedure_Goal__c + 10;
        update fspp;
        
        sked_Fixed_Site_Procedure_Projection__c testUpdatedFspp = [SELECT Id, 
                                                                   sked_Impact_Drives__c 
                                                                   FROM sked_Fixed_Site_Procedure_Projection__c
                                                                   WHERE Id =:fspp.Id];
		Assert.isTrue(testUpdatedFspp.sked_Impact_Drives__c == true);
        
        Test.stopTest();
    }

}