/* This test class covers BSF_Batch_UpdateSpecialCircumstanceOnOpp
 * Code Coverage: 94%
 * CreatedBy: Priti Jana
 * CreatedDate: 7/10/2025
 */

@isTest
private class BSF_Batch_UpdateSpecialCircumstance_Test {
    
    @testSetup
    private static void prepareTestData() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        skedHubBase.setBypassAllTriggers(true);
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId =  testMobileAccount.Id;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        // insert Mobile Opps
        Opportunity testMobileOpp1 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp1;
        
         // insert Mobile Opp 2
        Opportunity testMobileOpp2 = testMobileOpp1.clone();
        testMobileOpp2.name = 'Test Opportunity 2';
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert testMobileOpp2;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
    }
    
    static testMethod void batchConstructor1_test() {
        Test.startTest();
        Id testAccountId = [SELECT Id FROM Account LIMIT 1].Id;
        BSF_Batch_UpdateSpecialCircumstanceOnOpp testBatchInstance = new BSF_Batch_UpdateSpecialCircumstanceOnOpp('Addition', new List<Id>{testAccountId});
        Database.executeBatch(testBatchInstance, 200);
        Test.stopTest();
    }
    
    static testMethod void batchConstructor2_test() {
        Test.startTest();
        List<Opportunity> testOpportunityList = [SELECT Id, AccountId, Special_Circumstances__c FROM Opportunity];
        BSF_Batch_UpdateSpecialCircumstanceOnOpp testBatchInstance = new BSF_Batch_UpdateSpecialCircumstanceOnOpp('Removal', testOpportunityList);
        Database.executeBatch(testBatchInstance, 200);
        Test.stopTest();
    }
    
    static testMethod void batchConstructor3_test() {
        Test.startTest();
        BSF_Batch_UpdateSpecialCircumstanceOnOpp testBatchInstance = new BSF_Batch_UpdateSpecialCircumstanceOnOpp('Removal', '');
        Database.executeBatch(testBatchInstance, 200);
        Test.stopTest();
    }
    
    static testMethod void flagRemovalUponDriveCompletion_test() {
        Test.startTest();
        Opportunity testMobileOpp = [SELECT Id, Drive_Site__c, AccountId, Special_Circumstances__c FROM Opportunity WHERE Special_Circumstances__c = null LIMIT 1];
        testMobileOpp.Special_Circumstances__c = 'First Time Drive';
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        update testMobileOpp;
        
        //insert DOC
        sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive',
            sked_Drive_Date__c = system.today(),
            sked_Drive_Site__c = testMobileOpp.Drive_Site__c,
            sked_Opportunity__c = testMobileOpp.Id,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testMobileOpp.AccountId,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Total_Products_Projected__c = 30,
            sked_2RBC_Projected_Procedures__c = 10,
            sked_WB_Projected_Procedures__c = 10
        );
        insert testDrive1;
        
        testDrive1.sked_Status__c = 'Complete';
        update testDrive1;
        
        TriggerHandler.clearAllBypasses();
        
        Test.stopTest();
    }
}