/* Description : This test class covers TaskChecklistController 
 * Current Test Coverage : 94%
   
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 10/30/2024				  Priti Jana				Created for HRP-?
 *************************************************************************************************************************************************
*/

@isTest
public class TaskChecklistController_Test {
    
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
        
        // Create Tasks
        List<Task> oppTasks = new List<Task>();
        Task recruitmentTask = new Task(
        	Subject = BSF_Constants.RECRUITMENT_PLANNING_TASK,
        	WhatId = mobileOpportunityRecord.Id,
        	ActivityDate = System.Today(),
        	Status = 'Not Started',
        	Priority = 'Normal'
        );
        oppTasks.add(recruitmentTask);
        
        Task pdaTask = new Task(
        	Subject = BSF_Constants.POST_DRIVE_ANALYSIS_TASK,
        	WhatId = mobileOpportunityRecord.Id,
        	ActivityDate = System.Today(),
        	Status = 'Not Started',
        	Priority = 'Normal'
        );
        oppTasks.add(pdaTask);
        
        insert oppTasks;
        
        // insert BSF_Task_Checklist__c
        List<BSF_Task_Checklist__c> taskCheckList = new List<BSF_Task_Checklist__c>();
        BSF_Task_Checklist__c taskCheckList1 = new BSF_Task_Checklist__c(
        	TaskLookup__c = (String) oppTasks[0].Id,
        	TaskType__c = BSF_Constants.RECRUITMENT_PLANNING_TASK,
        	Unique_Name__c = 'Inform_BPL_Checklist'
        );
        BSF_Task_Checklist__c taskCheckList2 = new BSF_Task_Checklist__c(
        	OpportunityLookup__c = (String) mobileOpportunityRecord.Id,
        	TaskType__c = BSF_Constants.POST_DRIVE_ANALYSIS_TASK,
        	Unique_Name__c = 'Review_Data'
        );
        taskCheckList.add(taskCheckList1);
        taskCheckList.add(taskCheckList2);
        insert taskCheckList;  
    }

    static testMethod void testCheckEditAccess() {
        Test.startTest();
        Boolean hasEditAccess = TaskChecklistController.checkEditAccess();
        Assert.areEqual(TRUE, hasEditAccess);
        Test.stopTest();
    }
    
    static testmethod void testGetRelatedCheckistRecordsForOpp() {
        Test.startTest();
        Opportunity mobileOpp = [SELECT Id FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
        Map<String, TaskChecklistController.CheckListWrapper> map_chklstUniqueName_checklistWrapper;
        try{
            map_chklstUniqueName_checklistWrapper = TaskChecklistController.getRelatedCheckistRecords((String) mobileOpp.Id);
        } catch (Exception e) {
            System.debug('Error occurred while fetching checklist records for opportunity: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
        Test.stopTest();
        Assert.isNotNull(map_chklstUniqueName_checklistWrapper);
    }
    
    static testmethod void testGetRelatedCheckistRecordsForTask() {
        Test.startTest();
        Task recruitmentTask = [SELECT Id FROM Task WHERE Subject = :BSF_Constants.POST_DRIVE_ANALYSIS_TASK LIMIT 1];
        Map<String, TaskChecklistController.CheckListWrapper> map_chklstUniqueName_checklistWrapper = TaskChecklistController.getRelatedCheckistRecords((String) recruitmentTask.Id);
        Test.stopTest();
        Assert.isNotNull(map_chklstUniqueName_checklistWrapper);
    }
    
    static testMethod void testUpdateTaskChecklist() {
        Test.startTest();
        BSF_Task_Checklist__c taskCheckList = [SELECT Id, Picklist_Input_2__c FROM BSF_Task_Checklist__c WHERE TaskType__c = :BSF_Constants.POST_DRIVE_ANALYSIS_TASK LIMIT 1];
        String jsonString = '[{"Id":"'+(String) taskCheckList.Id+'","Picklist_Input_2__c":"Do Not Roll"}]';
        Map<String, String> map_successMsg_successDetails = TaskChecklistController.updateTaskChecklist(jsonString);
        Test.stopTest();
        Assert.areEqual('Checklist has been successfully saved.', map_successMsg_successDetails.get('message'));
    }
}