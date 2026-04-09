/* Description : This test class covers below classes and triggers : 
 * UpdateTaskChecklistEventHandler -> 95%
 * UpdateTaskChecklistEventTrigger -> 100%
 *************************************************************************/

@isTest(SeeAllData = false)
private class UpdateTaskChecklistEventTrigger_Test {

    @testSetup static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        testMobileAccount.Account_Strategy__c = 'Maintain';
        testMobileAccount.Account_Strategy_Notes__c = 'Test Account Strategy'; 
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
        mobileOpportunityRecord.Rollover_Consideration__c = 'Do Not Roll';
        insert mobileOpportunityRecord;
        
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
        
        TriggerHandler.clearAllBypasses();
    }
    
    static testMethod void taskChecklistEventHandlerTest() {
        Test.startTest();
        Task pdaTask = [SELECT Id FROM Task WHERE Subject = :BSF_Constants.POST_DRIVE_ANALYSIS_TASK LIMIT 1];
        
        // insert BSF_Task_Checklist__c
        List<BSF_Task_Checklist__c> taskCheckListToInsert = new List<BSF_Task_Checklist__c>();
        BSF_Task_Checklist__c taskCheckList;
        taskCheckList = new BSF_Task_Checklist__c(
                            TaskLookup__c = (String) pdaTask.Id,
                            TaskType__c = BSF_Constants.POST_DRIVE_ANALYSIS_TASK,
                            Unique_Name__c = 'Updated_Anticipated_Donors'
        );
        taskCheckListToInsert.add(taskCheckList);
        
        taskCheckList = new BSF_Task_Checklist__c(
                            TaskLookup__c = (String) pdaTask.Id,
                            TaskType__c = BSF_Constants.POST_DRIVE_ANALYSIS_TASK,
                            Unique_Name__c = 'Highlights_and_Feedback'
        );
        taskCheckListToInsert.add(taskCheckList);
        insert taskCheckListToInsert;
        
        List<Update_Task_Checklist__e> testEvents = new List<Update_Task_Checklist__e>();
        Update_Task_Checklist__e testEvent;
        testEvent = new Update_Task_Checklist__e();
        testEvent.Task_Id__c = pdaTask.Id;
        testEvent.CheckList_Name__c = 'Updated_Anticipated_Donors';
        testEvent.Field_Api_Name__c = 'Input_Checkbox__c';
        testEvent.Value__c = 'true';
        testEvents.add(testEvent);  
        
        testEvent = new Update_Task_Checklist__e();
        testEvent.Task_Id__c = pdaTask.Id;
        testEvent.CheckList_Name__c = 'Highlights_and_Feedback';
        testEvent.Field_Api_Name__c = 'Input_Long_Text_Area__c';
        testEvent.Value__c = 'TEST';
        testEvents.add(testEvent);  
        
        if(!testEvents.isEmpty()){
            List<Database.SaveResult> testResults = EventBus.publish(testEvents);
        }
        
        Test.stopTest();
    }
}