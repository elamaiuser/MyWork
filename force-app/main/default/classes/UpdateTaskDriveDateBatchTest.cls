@isTest(SeeAllData = FALSE)
public class UpdateTaskDriveDateBatchTest {
    @TestSetup
    static void updateTaskDrive() { 
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site 1
        sked__Location__c testMobileSite1 = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite1;
        
        Test.startTest();
        // insert template 1 - PLT - Inside
        Opportunity testTemplate1 = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate1.AccountId = testMobileAccount.Id;
        testTemplate1.Drive_Site__c = testMobileSite1.Id;
        testTemplate1.Type = 'Inside';
        insert testTemplate1;
        
        // insert mobile opp
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite1.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate1.Id;
        testMobileOpp.Open_to_Public__c = 'Yes';
        testMobileOpp.Security_Escort_Name__c = 'TEST';
        //testMobileOpp.Web_Sched_Offset_from_CO_Global_Settings__c = True;
        oppList.add(testMobileOpp);
        triggerHandler.bypass('OpportunityTriggerHandler');
        insert oppList;
        
        sked_Drive__c drives = new sked_Drive__c();
        drives.sked_Opportunity__c = oppList[0].Id;
        drives.sked_Account__c = testMobileAccount.Id;
        drives.sked_Drive_Date__c=oppList[0].Drive_Date__c;
        drives.sked_2RBC_Projected_Procedures__c = 20;
        drives.sked_WB_Projected_Procedures__c = 20;
        insert drives;
        
         Order testOrder = new Order(
            AccountId = testMobileAccount.ID,
            Name = 'Test Order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Order_Due_Date__c = Date.today().addDays(15), // Order Due Date is 15 days from today
            Publicity_Approved__c = false,
            Publicity_Submitted__c = false,
            OpportunityId = oppList[0].Id
        );
        triggerHandler.bypass('OrderTriggerHandler');
        insert testOrder;
        
        List<Task> allTask = new List<Task>();
        Task task1 = new Task(Subject = 'Test Task 1', WhatId = oppList[0].Id, Drive_Date__c = null);
        Task task2 = new Task(Subject = 'Test Task 2', WhatId = testOrder.Id, Drive_Date__c = null);
        Task task3 = new Task(Subject = 'Test Task 3', WhatId = drives.Id, Drive_Date__c = null);
        allTask.add(task1);
        allTask.add(task2);
        allTask.add(task3);
        
        insert allTask;   
    }
     @IsTest
    static void testBatchExecution1() {
        
        Test.startTest();
        UpdateTaskDriveDateBatch batch = new UpdateTaskDriveDateBatch();
        Database.executeBatch(batch,200);        
        Test.stopTest();
        
        Task updatedTask1 = [SELECT WhatId, Drive_Date__c FROM Task WHERE Subject = 'Test Task 1' LIMIT 1];
        Task updatedTask2 = [SELECT WhatId, Drive_Date__c FROM Task WHERE Subject = 'Test Task 2' LIMIT 1];
        Task updatedTask3 = [SELECT WhatId, Drive_Date__c FROM Task WHERE Subject = 'Test Task 3' LIMIT 1];
        
        System.assertEquals(updatedTask1.Drive_Date__c, [SELECT Drive_Date__c FROM Opportunity WHERE Id = :updatedTask1.WhatId].Drive_Date__c);
        System.assertEquals(updatedTask2.Drive_Date__c, [SELECT Drive_Date__c FROM Order WHERE Id = :updatedTask2.WhatId].Drive_Date__c);
        System.assertEquals(updatedTask3.Drive_Date__c, [SELECT sked_Drive_Date__c FROM sked_Drive__c WHERE Id = :updatedTask3.WhatId].sked_Drive_Date__c);
    }
}