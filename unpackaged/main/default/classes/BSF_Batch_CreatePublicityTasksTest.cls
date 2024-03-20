/* The following class covers the below mentioned batch class
 * BSF_Batch_CreatePublicityTasksOnOrders
 * */

@isTest(SeeAllData = false)
public class BSF_Batch_CreatePublicityTasksTest
{
    public static String mobileOppRecType = 'Mobile Opp';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup
    public static void prepareDataSetup()
    {
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
        testMobileOpp.Drive_Date__c = system.today().addDays(10);
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
        
        //insert orders
        List<Order> orderList = new List<Order>();
        
        Order testOrder;
        testOrder = new Order(EffectiveDate = system.today() , 
                                    Description = 'Test Order', 
                                    Publicity_Approved__c = false , 
                                    Status = 'Draft',
                                   	AccountId = testMobileAccount.Id,
                                   	OpportunityId = testMobileOpp.Id);
        
        orderList.add(testOrder);
        
        testOrder = new Order(EffectiveDate = system.today() , 
                                    Description = 'Test Order', 
                                    Publicity_Approved__c = false , 
                                    Status = 'Draft',
                                   	AccountId = testMobileAccount.Id,
                                   	OpportunityId = testMobileOpp.Id);
        
        orderList.add(testOrder);        
        insert orderList;
        
    }
    
    static testMethod void testBatchToCreateTasks()
    {
        Test.startTest();
        BSF_Batch_CreatePublicityTasksOnOrders batchable = new BSF_Batch_CreatePublicityTasksOnOrders();
        Database.executeBatch(batchable);
        Test.stopTest();
        
        List<Task> createdTask = new List<Task>([select Id from Task where subject like '%publicity review needed']);
        system.assert(createdTask.size()==2 , true);
    }
    
    static testMethod void testBatchNotToCreateDuplicateTasks()
    {
        List<Order> orderList = new List<Order>([select id , OpportunityId from Order]);
        Task t = new Task(subject = 'Publicity Review Needed', Status = 'Not Started',Priority = 'High',WhatId = orderList[0].Id, OwnerId = userInfo.getUserId());
        insert t;
        
        Test.startTest();
        
        BSF_Batch_CreatePublicityTasksOnOrders batchable = new BSF_Batch_CreatePublicityTasksOnOrders();
        Database.executeBatch(batchable);
        
        Test.stopTest();
        
        List<Task> createdTask = new List<Task>([select Id from Task where subject like '%publicity review needed' and whatId =:orderList[0].Id]);
        system.assertEquals(1 , createdTask.size()); // duplicate task won't be created for the first order
    }
    
    
    
    //Method to get the map of recordType Name as key and recordTypeId as value 
    public static Map<String,Id> recordTypeMap(string obj)
    {
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