/* Description : This test class covers BSF_TaskCreationBatch 
 * Current Test Coverage : 100%
   
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 10/30/2024				  Priti Jana				Created for HRP-5337
 *************************************************************************************************************************************************
*/

@isTest
public class BSF_TaskCreationBatch_Test {

    @testSetup static void prepareTestData() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        // insert Mobile Opp
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.StageName = 'Discovery';
        mobileOpportunityRecord.AccountId = testMobileAccount.Id;
        mobileOpportunityRecord.Drive_Site__c = testMobileSite.Id;
        mobileOpportunityRecord.Parent_Template_Id__c = testTemplate.Id;
        mobileOpportunityRecord.Procedure_Projections_Template__c = 10;
        mobileOpportunityRecord.Drive_Date__c = Date.Today().addDays(30);
        mobileOpportunityRecord.CloseDate = System.today();
        mobileOpportunityRecord.Start_Time__c = System.now().Time();
        mobileOpportunityRecord.End_Time__c = System.now().Time() + 1;
        mobileOpportunityRecord.Anticipated_Registered_Donors__c = 1;  
        mobileOpportunityRecord.X2RBC_Projected_Procedures__c = 1;
        mobileOpportunityRecord.WB_Projected_Procedures__c = 2;
        mobileOpportunityRecord.Source__c = 'Adhoc';
        mobileOpportunityRecord.Slot_Generator__c = 130;
        mobileOpportunityRecord.Slot_Generator_Change_Reason__c = 'System Generated Value';
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert mobileOpportunityRecord;
        TriggerHandler.clearAllBypasses();
    }
    
    static testMethod void testBatchExecutionForAllOpps() {
        Test.startTest();
        Opportunity mobileOpp = [SELECT Id, Name, Drive_Date__c, WB_Projected_Procedures__c, Source__c FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
        BSF_TaskCreationBatch taskCreationBatchInstance = new BSF_TaskCreationBatch(TRUE);
        Database.executeBatch(taskCreationBatchInstance);
        Test.stopTest();
        
        List<Task> sponsorPlanningTaskList = [SELECT Id, Subject FROM Task WHERE WhatId = :mobileOpp.Id];
        Assert.areEqual(1, sponsorPlanningTaskList.size());
        Assert.areEqual('Sponsor Planning Meeting', sponsorPlanningTaskList[0].Subject);
    }
    
    static testMethod void testBatchExecutionForSpecificOpp() {
        Test.startTest();
        Opportunity mobileOpp = [SELECT Id, Name, Drive_Date__c, WB_Projected_Procedures__c, Source__c FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
        Date nextNDays = Date.today().addDays(Integer.ValueOf(label.SponsorPlanningMeetingTaskThresholdDays));
        mobileOpp.Drive_Date__c = nextNDays;
        mobileOpp.Drive_Date_Change_Reason__c = 'Test Specific Task Creation';
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update mobileOpp;
        TriggerHandler.clearAllBypasses();
        
        BSF_TaskCreationBatch taskCreationBatchInstance = new BSF_TaskCreationBatch();
        Database.executeBatch(taskCreationBatchInstance);
        Test.stopTest();
        
        List<Task> sponsorPlanningTaskList = [SELECT Id, Subject FROM Task WHERE WhatId = :mobileOpp.Id];
        Assert.areEqual(1, sponsorPlanningTaskList.size());
        Assert.areEqual('Sponsor Planning Meeting', sponsorPlanningTaskList[0].Subject);
    }
    
    static testMethod void testSchdulableBatchExecution() {
        Test.startTest();
        BSF_TaskCreationBatch taskCreationBatchInstance = new BSF_TaskCreationBatch();
        SchedulableContext scon;
        taskCreationBatchInstance.execute(scon);
        Test.stopTest();
    }
}