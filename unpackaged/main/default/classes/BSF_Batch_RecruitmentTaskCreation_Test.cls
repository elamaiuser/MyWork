/* Description : This test class covers BSF_Batch_RecruitmentTaskCreation (88%) and BSF_TaskTestBatch (100%)
   
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************
 * 11/01/2024				  Priti Jana				Created for HRP-?
 *************************************************************************************
*/

@isTest
public class BSF_Batch_RecruitmentTaskCreation_Test {
    
    @testSetup
    private static void prepareDataSetup() {
        TriggerHandler.Bypass('AccountTriggerHandler');
        TriggerHandler.Bypass('OpportunityTriggerHandler');
        TriggerHandler.Bypass('SiteTriggerHandler');
        
        Task_Reassignment_Matrix__mdt recruitmentTask = Task_Reassignment_Matrix__mdt.getInstance('Recruitment_Task');
    	Date driveDate = system.today().addDays(Integer.valueOf(recruitmentTask.Creation_Date_Offset__c));
        
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
        testMobileOpp.Drive_Date__c = driveDate;
        testMobileOpp.Accept_56_Day_Rule_Violation__c = true;
        testMobileOpp.Account_Manager__c = UserInfo.getUserId();
        testMobileOpp.Start_Time__c = System.now().Time();
		testMobileOpp.End_Time__c = System.now().Time()+1;
		testMobileOpp.Anticipated_Registered_Donors__c = 1;	
        insert testMobileOpp;
        
        // insert team member
        OpportunityTeamMember oppTeammember = new OpportunityTeamMember(OpportunityId = testMobileOpp.Id, 
                                                                        Start_Date__c = system.today(), 
                                                                        TeamMemberRole = 'District Manager',
                                                                        OpportunityAccessLevel = 'Edit',
                                                                        UserId = drdUser.Id);
        insert oppTeammember;
        
    }
    
    static testMethod void testCreateTasks() {
        Test.startTest();
        BSF_Batch_RecruitmentTaskCreation batchInstance = new BSF_Batch_RecruitmentTaskCreation();
        Database.executeBatch(batchInstance);
        Test.stopTest();
        
        Integer createdTasksCount = [SELECT count() FROM Task WHERE Subject = 'Recruitment Planning Meeting'];
        Assert.isTrue(createdTasksCount == 1);
    }
    
    static testMethod void testScheduleBatch() {
        Test.startTest();
        BSF_Batch_RecruitmentTaskCreation batchable = new BSF_Batch_RecruitmentTaskCreation();
        SchedulableContext scon;
        batchable.execute(scon);
        Test.stopTest();
    }
    
    static testMethod void testRecruitmentTaskSubjectChangeBatch() {
        Test.startTest();
        Opportunity testMobileOpp = [SELECT Id FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
        
        Task t = new Task(
            subject = 'Recruitment Task - System Generated', 
            Status = 'Not Started',
            Priority = 'High',
            WhatId = testMobileOpp.Id, 
            OwnerId = userInfo.getUserId()
        );
        insert t;
        
        BSF_TaskTestBatch batchInstance = new BSF_TaskTestBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();
        
        Task recruitmentTask = [SELECT Id, Subject FROM Task LIMIT 1];
        Assert.isTrue(recruitmentTask.Subject.equalsIgnoreCase('Recruitment Planning Meeting'));
    }

}