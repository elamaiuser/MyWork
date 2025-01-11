@isTest
public class BSF_Batch_TemplateOrderExpirationTest {
    
    @testSetup
    static void setup() {
        // Create a test user
        User drdUser = new User(
            FirstName = 'DRD',
            LastName = 'System',
            Username = 'drdsystem@test.com',
            Email = 'drdsystem@test.com',
            Alias = 'drdsys',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert drdUser;
        
        // Create custom metadata record for Task Reassignment Matrix
      /*  Task_Reassignment_Matrix__mdt matrix = new Task_Reassignment_Matrix__mdt(
            MasterLabel = 'Template_Order_Task',
            Category__c = 'TaskCategory',
            Creation_Date_Offset__c = '10',
            Due_Date_Offset__c = '5',
            Task_Subject__c = 'Template Order Expiration',
            Description__c = 'This is a test description',
            Assigned_To__c = 'Account Manager'
        );
        insert matrix;
*/
        
        // Create an Account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        // Create an Opportunity with Is_Template__c = TRUE
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Is_Template__c = TRUE,
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        // Create an Order related to the Opportunity
        Order testOrder = new Order(
            Name = 'Test Order',
            OpportunityId = testOpportunity.Id,
            EndDate = Date.today().addDays(15),
            Order_Due_Date__c = Date.today().addDays(20)
        );
        insert testOrder;
        
        // Create Account Team Member
        AccountTeamMember teamMember = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = drdUser.Id,
            TeamMemberRole = 'Account Manager',
            is_covering_recruiter__c = false,
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(20)
        );
        insert teamMember;
    }

    @isTest
    static void testBatchExecution() {
        
        Task_Reassignment_Matrix__mdt mdtDriveCompletion = Task_Reassignment_Matrix__mdt.getInstance('Template_Order_Task');
        Integer numOfDays = mdtDriveCompletion?.Creation_Date_Offset__c.intValue();
        // Start the test, this will run the batch
        Test.startTest();
        
        // Instantiate the batch class
        BSF_Batch_TemplateOrderExpiration batch = new BSF_Batch_TemplateOrderExpiration();
        
        // Execute the batch
        Database.executeBatch(batch);

        Test.stopTest();

        // Query for created tasks
        List<Task> tasks = [SELECT Id, Subject, Description, Priority, Status, RecordTypeId, OwnerId
                            FROM Task
                            WHERE Subject = 'Template Order Expiration'];

        // Assert that a task was created
        System.assertEquals(1, tasks.size(), 'One task should be created.');
        System.assertEquals('Template Order Expiration', tasks[0].Subject, 'Task subject should match.');
        System.assertEquals('high', tasks[0].Priority, 'Task priority should be high.');
        System.assertEquals('Not Started', tasks[0].Status, 'Task status should be Not Started.');
        
        // Verify the OwnerId assignment
        Task task = tasks[0];
        AccountTeamMember atm = [SELECT UserId FROM AccountTeamMember WHERE AccountId = :task.WhatId LIMIT 1];
        System.assertEquals(atm.UserId, task.OwnerId, 'Task should be assigned to the Account Manager.');
    }
    
    @isTest
    static void testNoTasksCreated() {
        // Update Opportunity Is_Template__c to FALSE
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        testOpp.Is_Template__c = FALSE;
        update testOpp;
        
        // Start the test
        Test.startTest();
        
        // Instantiate the batch class
        BSF_Batch_TemplateOrderExpiration batch = new BSF_Batch_TemplateOrderExpiration();
        
        // Execute the batch
        Database.executeBatch(batch);

        Test.stopTest();

        // Query for created tasks
        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE Subject = 'Template Order Expiration'];
        
        // Assert that no tasks were created
        System.assertEquals(0, tasks.size(), 'No tasks should be created.');
    }
}