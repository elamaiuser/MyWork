@isTest
private class BSF_BatchTaskSyncTest {
    @testSetup static void prepareTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('SiteCollectionOperationTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert DRD Users
        List<User> testUsers = new List<User>();
        testUsers.add((User)mapTestData.get('DRD_USER'));
        testUsers.add((User)mapTestData.get('DRD_MANAGER_USER'));
        system.runAs(new User(Id = UserInfo.getUserId())) {
        	insert testUsers;
        }
        
        //insert Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        //insert CO
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP');
        insert testCo;
        
        //insert Site CO
        sked_Site_Collection_Operation__c testSiteCo = new sked_Site_Collection_Operation__c(
        	sked_Collection_Operation__c = testCo.Id,
        	sked_Site__c = testMobileSite.Id,
        	sked_Start_Date__c = System.today(),
        	sked_End_Date__c = Date.newInstance(4000, 12, 31)
        );
        insert testSiteCo;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert mobile opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;

        //insert opp team member
        OpportunityTeamMember testoppteammem = new OpportunityTeamMember(
            OpportunityId = testMobileOpp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = BSF_Constants.DISTRICT_MANAGER
        );
        insert testoppteammem;

        //insert tasks
        List<Task> testTasks = new List<Task>();
        Task testTask;
        testTask = new Task(
        	WhatId = testMobileOpp.Id,
        	Status = 'Not Started',
        	Subject = 'Recruitment Task - System Generated'
        );
        testTasks.add(testTask);
        
        testTask = new Task(
            WhatId = testMobileOpp.Id,
            Status = 'Not Started',
            Subject = 'Request for Marketing Exception'
        );
        testTasks.add(testTask);
        insert testTasks;
        
        TriggerHandler.clearAllBypasses();
        skedHubBase.BypassInsertTriggers = false; 
        skedHubBase.BypassUpdateTriggers = false;
    }
    
    private static void createGroupAndMembers(String coName, List<User> testUsers) {
        system.runAs(new User(Id = UserInfo.getUserId())) {
            Group q = new Group(
                name = coName + ': DMDCR',
                type = skedConstants.GROUP_TYPE_QUEUE
            );
            insert q;
            
            List<GroupMember> testGroupMembers = new List<GroupMember>();
            for(Integer i = 0; i < testUsers.size(); i++) {
                testGroupMembers.add(new GroupMember(
                    GroupId = q.Id,
                    UserOrGroupId = testUsers[i].Id
             	));
            }
            insert testGroupMembers;
            
            QueuesObject testQueue = new QueueSObject(QueueID = q.id, SobjectType = 'Task');
            insert testQueue;
        }
    }
    
    @isTest static void testMethod1() {
        Test.startTest();
      	
        String coName = [SELECT Id, sked_collection_operation__r.Name FROM sked_Site_Collection_Operation__c LIMIT 1].sked_collection_operation__r.Name;
        List<User> testUsers = [SELECT Id FROM User WHERE Profile.Name LIKE '%DRD%' LIMIT 2];
        createGroupAndMembers(coName, testUsers);
        
        BSF_BatchTaskSync taskbatchInstance = new BSF_BatchTaskSync();
        DataBase.executeBatch(taskbatchInstance); 
        
        Test.stopTest();
    }
    
    @isTest static void testMethod2() {
        Test.startTest();
        
        String coName = [SELECT Id, sked_collection_operation__r.Name FROM sked_Site_Collection_Operation__c LIMIT 1].sked_collection_operation__r.Name;
        List<User> testUsers = [SELECT Id FROM User WHERE Profile.Name LIKE '%DRD%' LIMIT 2];
        createGroupAndMembers(coName, testUsers);
        
        Task testTask = [SELECT Id FROM Task WHERE Subject = 'Request for Marketing Exception' LIMIT 1];
        
        BSF_BatchTaskSync taskbatchInstance = new BSF_BatchTaskSync(null, new List<Id>{testTask.Id});
        DataBase.executeBatch(taskbatchInstance);
        
        Test.stopTest();           
    }
    
    @isTest static void testMethod3() {
        Test.startTest();
        
        String coName = [SELECT Id, sked_collection_operation__r.Name FROM sked_Site_Collection_Operation__c LIMIT 1].sked_collection_operation__r.Name;
        List<User> testUsers = [SELECT Id FROM User WHERE Profile.Name LIKE '%DRD%' LIMIT 2];
        createGroupAndMembers(coName, testUsers);
        
        Opportunity mobileOpportunity = [SELECT Id FROM Opportunity WHERE Is_Template__c = false AND RecordType.Name = 'Mobile Opp' LIMIT 1];
        Task testTask = [SELECT Id FROM Task WHERE Subject != 'Request for Marketing Exception' LIMIT 1];
        
        BSF_BatchTaskSync taskbatchInstance = new BSF_BatchTaskSync(new List<Id>{mobileOpportunity.Id}, new List<Id>{testTask.Id});
        DataBase.executeBatch(taskbatchInstance);
        
        Test.stopTest();         
    }
    
    @isTest static void testMethod4() { 
        Test.startTest();
        
        String coName = [SELECT Id, sked_collection_operation__r.Name FROM sked_Site_Collection_Operation__c LIMIT 1].sked_collection_operation__r.Name;
        List<User> testUsers = [SELECT Id FROM User WHERE Profile.Name LIKE '%DRD%' LIMIT 2];
        createGroupAndMembers(coName, testUsers);
        
        Opportunity mobileOpportunity = [SELECT Id FROM Opportunity WHERE Is_Template__c = false AND RecordType.Name = 'Mobile Opp' LIMIT 1];
        
        BSF_BatchTaskSync taskbatchInstance = new BSF_BatchTaskSync(new List<Id>{mobileOpportunity.Id}, null);
        DataBase.executeBatch(taskbatchInstance); 
        
        Test.stopTest(); 
    }
    
    @isTest static void testMethod5_scheduleLogic() {
        Test.startTest();
        
        String coName = [SELECT Id, sked_collection_operation__r.Name FROM sked_Site_Collection_Operation__c LIMIT 1].sked_collection_operation__r.Name;
        List<User> testUsers = [SELECT Id FROM User WHERE Profile.Name LIKE '%DRD%' LIMIT 2];
        createGroupAndMembers(coName, testUsers);
        
        SchedulableContext sc = null;
        BSF_BatchTaskSync taskbatchInstance = new BSF_BatchTaskSync();
        taskbatchInstance.execute(sc);
        
        Test.stopTest();
    }  
}