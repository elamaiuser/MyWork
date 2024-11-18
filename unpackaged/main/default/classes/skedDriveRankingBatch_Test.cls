@isTest
private class skedDriveRankingBatch_Test {
    @isTest
    static void skedDriveRankingBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_Point__c = 5;
        testDrive.sked_Projected_Registered_Donors__c = 500;

        sked_Drive__c testDrive2 = testDrive.clone(false, false, false, false);
        testDrive2.sked_Point__c = 10;
        
        sked_Drive__c testDrive3 = testDrive.clone(false, false, false, false);
        testDrive3.sked_Projected_Registered_Donors__c = 600;
        
        upsert new List<sked_Drive__c>{testDrive, testDrive2, testDrive3};
            Database.executeBatch(new skedDriveRankingBatch(new List<sked_Drive__c>{testDrive}), 1);
        
        Test.stopTest();
    }

    @isTest
    static void skedDriveRankingBatch_AltConstructor_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_Point__c = 5;
        testDrive.sked_Projected_Registered_Donors__c = 500;
        
        sked_Drive__c testDrive2 = testDrive.clone(false, false, false, false);
        testDrive2.sked_Point__c = 10;
        
        sked_Drive__c testDrive3 = testDrive.clone(false, false, false, false);
        testDrive3.sked_Projected_Registered_Donors__c = 600;
        
        upsert new List<sked_Drive__c>{testDrive, testDrive2, testDrive3};
            
            String key = testDrive.sked_Collection_Operation__c + ':' + String.valueOf(testDrive.sked_Drive_Date__c);
        Database.executeBatch(new skedDriveRankingBatch(new Set<String>{key}), 1);
        
        Test.stopTest();
    }
    
    @isTest
    static void skedDriveRankingBatch_FsDriveConstructor_Test() {
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');
     
        Test.startTest();
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        CreateSkedDrive.createDrives(new List<Opportunity>{fixOpportunity});
        List<sked_Drive__c> fixedSiteDriveCreated = [SELECT Id , sked_Opportunity__c, sked_Type_of_Drive__c 
                                                     FROM sked_Drive__c 
                                                     WHERE sked_Opportunity__c = :fixOpportunity.Id];
        
        //Call the batch
        Database.executeBatch(new skedDriveRankingBatch('Manual', '', System.today(), fixedSiteDriveCreated), 1);
        Test.stopTest();
    }
}