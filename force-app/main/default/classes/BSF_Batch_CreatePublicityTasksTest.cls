/* The following class covers the below mentioned batch classes
 * BSF_Batch_CreatePublicityTasksOnOrders (Not needed)
 * BSF_Batch_CreatePublicityTasks (100%)
  
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ****************************************************************************************
 * 11/01/2024				  Priti Jana				Modified for HRP-12583
 ******************************************************************************************
 */

@isTest(SeeAllData = false)
public class BSF_Batch_CreatePublicityTasksTest
{
    public static String mobileOppRecType = 'Mobile Opp';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup
    public static void prepareDataSetup()
    {
        TriggerHandler.Bypass('AccountTriggerHandler');
        TriggerHandler.Bypass('OpportunityTriggerHandler');
        TriggerHandler.Bypass('SiteTriggerHandler');
        
        Task_Reassignment_Matrix__mdt publicityOrder = Task_Reassignment_Matrix__mdt.getInstance('Publicity_Order_Not_Created');
    	Date dateUntil = system.today() + Integer.valueof(publicityOrder.Creation_Date_Offset__c);
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert DRD User
        User drdUser = (User)mapTestData.get('DRD_USER');
        System.runAs( new User(Id = UserInfo.getUserId()))
        {
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
        recordTypeMap = recordTypeMap( 'Opportunity' );
		Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
		opportunity testMobileOpp =new opportunity();
		testMobileOpp.RecordTypeId = optyRecTypeId;        
        testMobileOpp.AccountId=testMobileAccount.Id;
        testMobileOpp.name='testOpp1';
        testMobileOpp.StageName= 'Closed';
        testMobileOpp.Parent_Template_Id__c=testTemplate.id;
        testMobileOpp.CloseDate= system.today().addDays(1); 
        testMobileOpp.Drive_Date__c = dateUntil;
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
    
    static testMethod void testBatchToCreateTasksForNoOrders() {
        Test.startTest();
        //BSF_Batch_CreatePublicityTasksOnOrders batchable = new BSF_Batch_CreatePublicityTasksOnOrders();
        
        BSF_Batch_CreatePublicityTasks batchable = new BSF_Batch_CreatePublicityTasks();
        Database.executeBatch(batchable);
        Test.stopTest();
        
        Integer createdTasksCount = [SELECT count() FROM Task WHERE Subject = 'Publicity Order Not Created'];
        Assert.isTrue(createdTasksCount == 1);
    }
    
    static testMethod void testBatchToCreateTasksForReview() {
        Test.startTest();
        Task_Reassignment_Matrix__mdt publicityReview = Task_Reassignment_Matrix__mdt.getInstance('Publicity_Review_Needed');
        
        Account testMobileAccount = [SELECT Id FROM Account LIMIT 1];
        Opportunity testMobileOpp = [SELECT Id, Drive_Date__c, Drive_Date_Change_Reason__c FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
        testMobileOpp.Drive_Date__c = system.today().addDays(Integer.valueof(publicityReview.Creation_Date_Offset__c));
        testMobileOpp.Drive_Date_Change_Reason__c = 'TEST';
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update testMobileOpp;
        TriggerHandler.clearAllBypasses();
        
         //insert orders
        List<Order> orderList = new List<Order>();
        
        Order testOrder;
        testOrder = new Order(EffectiveDate = system.today() , 
                                    Description = 'Test Order 1', 
                                    Publicity_Approved__c = false , 
                                    Status = 'Draft',
                                   	AccountId = testMobileAccount.Id,
                                   	OpportunityId = testMobileOpp.Id);
        
        orderList.add(testOrder);
        
        testOrder = new Order(EffectiveDate = system.today() , 
                                    Description = 'Test Order 2', 
                                    Publicity_Approved__c = false , 
                                    Status = 'Draft',
                                   	AccountId = testMobileAccount.Id,
                                   	OpportunityId = testMobileOpp.Id);
        
        orderList.add(testOrder);        
        insert orderList;
        
        //BSF_Batch_CreatePublicityTasksOnOrders batchable = new BSF_Batch_CreatePublicityTasksOnOrders();
        
        BSF_Batch_CreatePublicityTasks batchable = new BSF_Batch_CreatePublicityTasks();
        Database.executeBatch(batchable);
        Test.stopTest();
        
        Integer createdTasksCount = [SELECT count() FROM Task WHERE Subject = 'Publicity Review Needed'];
        Assert.isTrue(createdTasksCount == 2);
    }
    
    static testMethod void testBatchNotToCreateDuplicateTasks() {
        Test.startTest();
        Opportunity testMobileOpp = [SELECT Id, Drive_Date__c, Drive_Date_Change_Reason__c FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
        
        //insert Tasks
        List<Task> oppTasks = new List<Task>();
        Task t;
        t = new Task(
            subject = 'Publicity Review Needed', 
            Status = 'Not Started',
            Priority = 'High',
            WhatId = testMobileOpp.Id, 
            OwnerId = userInfo.getUserId()
        );
        oppTasks.add(t);
        
        t = new Task(
            subject = 'Publicity Order Not Created', 
            Status = 'Not Started',
            Priority = 'High',
            WhatId = testMobileOpp.Id, 
            OwnerId = userInfo.getUserId()
        );
        oppTasks.add(t);
        
        insert oppTasks;
        
        //BSF_Batch_CreatePublicityTasksOnOrders batchable = new BSF_Batch_CreatePublicityTasksOnOrders();
        BSF_Batch_CreatePublicityTasks batchable = new BSF_Batch_CreatePublicityTasks();
        Database.executeBatch(batchable);
        
        Integer taskCount = [SELECT Count() FROM Task];
        Assert.isTrue(taskCount == 2); // duplicate tasks didn't get created
        Test.stopTest();
    }
    
    static testMethod void testScheduleBatch() {
        Test.startTest();
        BSF_Batch_CreatePublicityTasks batchable = new BSF_Batch_CreatePublicityTasks();
        SchedulableContext scon;
        batchable.execute(scon);
        Test.stopTest();
    }

    //Method to get the map of recordType Name as key and recordTypeId as value 
    public static Map<String,Id> recordTypeMap(string obj) {
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null)
        {
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }

}