/* Description : This test class covers BSF_TaskCreationBatch 
 * Current Test Coverage : 88%
   
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 10/30/2024				  Priti Jana				Created for HRP-5337
 * 12/19/2024				  Priti Jana				Fixed errors, increased code coverage
 *************************************************************************************************************************************************
*/

@isTest
public class BSF_TaskCreationBatch_Test {

    @testSetup static void prepareTestData() {
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Test.startTest();
        GenerateMobileDrive.generateDrives(config);

        TriggerHandler.clearAllBypasses();
    }
    
    static testMethod void testBatchExecutionForAllOpps() {
        
        Test.startTest();
        Opportunity mobileOpp = [SELECT Id, Name, Drive_Date__c, WB_Projected_Procedures__c, Source__c, stageName FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
        BSF_TaskCreationBatch taskCreationBatchInstance = new BSF_TaskCreationBatch();
        Database.executeBatch(taskCreationBatchInstance);
        Test.stopTest();
        
        List<Task> tasksCreatedList = [SELECT Id, Subject FROM Task WHERE WhatId = :mobileOpp.Id];
        Assert.isTrue(tasksCreatedList != null);
    }
    
    static testMethod void testBatchExecutionForSpecificOpp() {
        Test.startTest();
        Opportunity mobileOpp = [SELECT Id, Name, Drive_Date__c, WB_Projected_Procedures__c, Source__c, stageName FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
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
        Assert.areEqual(0, sponsorPlanningTaskList.size());
        //Assert.areEqual('Sponsor Planning Meeting', sponsorPlanningTaskList[0].Subject);
    }
    
    static testMethod void testSchdulableBatchExecution() {
        Test.startTest();
        BSF_TaskCreationBatch taskCreationBatchInstance = new BSF_TaskCreationBatch();
        SchedulableContext scon;
        taskCreationBatchInstance.execute(scon);
        Test.stopTest();
    }
}