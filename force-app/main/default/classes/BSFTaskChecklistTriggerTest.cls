@isTest
private class BSFTaskChecklistTriggerTest {

    @isTest
    private static void testmethod1() {
        TriggerHandler.Bypass('AccountTriggerHandler');
        TriggerHandler.Bypass('OpportunityTriggerHandler');
        TriggerHandler.Bypass('SiteTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert DRD User
        User drdUser = (User)mapTestData.get('DRD_USER');
        System.runAs( new User(Id = UserInfo.getUserId())) {
            insert drdUser;
        }
               
        //insert mobile account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c = 'Test Account';
        insert testMobileAccount;
        
        // insert mobile site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
    	insert testMobileSite;
        
        // insert template
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert opportunity
		opportunity testMobileOpp =new opportunity();
		testMobileOpp.RecordTypeId = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId();        
        testMobileOpp.AccountId=testMobileAccount.Id;
        testMobileOpp.name='testOpp1';
        testMobileOpp.StageName= 'Closed';
        testMobileOpp.Parent_Template_Id__c=testTemplate.id;
        testMobileOpp.CloseDate= system.today().addDays(1); 
        testMobileOpp.Drive_Date__c = system.today();
        testMobileOpp.Accept_56_Day_Rule_Violation__c = true;
        testMobileOpp.Account_Manager__c = UserInfo.getUserId();
        testMobileOpp.Start_Time__c = System.now().Time();
		testMobileOpp.End_Time__c = System.now().Time()+1;
		testMobileOpp.Anticipated_Registered_Donors__c = 1;	
        insert testMobileOpp;
        
        Test.startTest();
        //insert Publicity Task
        Set<Id> taskIds = new Set<Id>();
        Task pdaTask = new Task(
        	Subject = BSF_Constants.POST_DRIVE_ANALYSIS_TASK,
            OwnerId = drdUser.Id,
            Priority = 'Normal',
            Status = 'Not Started',
            WhatId = testMobileOpp.Id
        );
        insert pdaTask;
        taskIds.add(pdaTask.Id);
        TaskChecklistController.getRelatedCheckistRecords(pdaTask.Id);

        Task rmTask = new Task(
        	Subject = BSF_Constants.RECRUITMENT_PLANNING_TASK,
            OwnerId = drdUser.Id,
            Priority = 'Normal',
            Status = 'Not Started',
            WhatId = testMobileOpp.Id
        );
        insert rmTask;
        TaskChecklistController.getRelatedCheckistRecords(rmTask.Id);
        List<BSF_Task_Checklist__c> checklists = [SELECT Id, 
                                                            Name, 
                                                            Unique_Name__c, 
                                                            Input_Long_Text_Area__c, 
                                                            Input_Short_Text_1__c, 
                                                            Input_Short_Text_2__c, 
                                                            Input_Checkbox__c, 
                                                            Picklist_Input_1__c, 
                                                            Picklist_Input_2__c, 
                                                            Input_Number__c, 
                                                            TaskLookup__c, 
                                                            TaskType__c, 
                                                            OpportunityLookup__c 
                                                        FROM BSF_Task_Checklist__c
                                                        WHERE TaskLookup__c IN (:pdaTask.Id, :rmTask.Id)];
        List<BSF_Task_Checklist__c> newChecklists = new List<BSF_Task_Checklist__c>();
        for(BSF_Task_Checklist__c tcl : checklists){
            tcl.Input_Checkbox__c  = true;
            tcl.Input_Long_Text_Area__c   = 'testQA';
            tcl.Picklist_Input_1__c  = 'Upgrade';
            tcl.Picklist_Input_2__c = 'Do Not Roll';
            newChecklists.add(tcl);
        }
        update newChecklists;
        
        List<Task> updateTaskList = new List<Task>();
        pdaTask.Status = 'Completed';
        updateTaskList.add(pdaTask);

        rmTask.Status = 'Completed';
        updateTaskList.add(rmTask);

        update updateTaskList;
        
        Test.stopTest();
    }
}