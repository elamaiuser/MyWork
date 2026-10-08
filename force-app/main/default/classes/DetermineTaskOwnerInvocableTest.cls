@IsTest
public class DetermineTaskOwnerInvocableTest {

    @testSetup
    static void setupTestData() {

        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, SObject> mapTestData =
            testDataSetup.createAndInsertCommonObjects();

        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');

        skedHubBase.setBypassAllTriggers(true);

        // Account
        Account testMobileAccount =
            (Account) mapTestData.get('MOBILE_ACCOUNT');

        testMobileAccount.Internal_Name__c = 'TEST ACCOUNT 1';
        insert testMobileAccount;


        // Contact
        Contact testContact =
            (Contact) mapTestData.get('CONTACT');

        testContact.AccountId = testMobileAccount.Id;
        insert testContact;

        // Site
        sked__Location__c testMobileSite =
            (sked__Location__c) mapTestData.get('MOBILE_SITE');

        insert testMobileSite;

        // Template Opportunity
        Opportunity testTemplate =
            (Opportunity) mapTestData.get('MOBILE_TEMPLATE_OPP');

        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;

        insert testTemplate;

        // Mobile Opportunities
        Opportunity testMobileOpp1 =
            (Opportunity) mapTestData.get('MOBILE_OPP');

        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;

        testMobileOpp1.Drive_Date__c = Date.today().addDays(-5);


        Opportunity testMobileOpp2 = testMobileOpp1.clone();
        testMobileOpp2.Name = 'Test Opportunity 2';
        testMobileOpp2.Drive_Date__c = Date.today().addDays(-3);

        insert new List<Opportunity>{
            testMobileOpp1,
            testMobileOpp2
        };

        // Drives
        List<sked_Drive__c> testDrives = new List<sked_Drive__c>();

        sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive1',
            sked_Drive_Date__c = testMobileOpp1.Drive_Date__c,
            sked_Drive_Site__c = testMobileOpp1.Drive_Site__c,
            sked_Opportunity__c = testMobileOpp1.Id,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testMobileOpp1.AccountId,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Total_Products_Projected__c = 30,
            sked_2RBC_Projected_Procedures__c = 10,
            sked_WB_Projected_Procedures__c = 10
        );

        testDrives.add(testDrive1);


        sked_Drive__c testDrive2 = new sked_Drive__c(
            Name = 'Test Drive2',
            sked_Drive_Date__c = testMobileOpp2.Drive_Date__c,
            sked_Drive_Site__c = testMobileOpp2.Drive_Site__c,
            sked_Opportunity__c = testMobileOpp2.Id,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testMobileOpp2.AccountId,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Total_Products_Projected__c = 30,
            sked_2RBC_Projected_Procedures__c = 10,
            sked_WB_Projected_Procedures__c = 10
        );

        testDrives.add(testDrive2);

        insert testDrives;

        // Task Definitions
        List<Task_Definition__c> taskDefinitions =
            new List<Task_Definition__c>();

        Task_Definition__c amDefinition = new Task_Definition__c(
            Name = 'Post-Drive Analysis - AM',
            Assigned_To__c = 'Account Manager',
            Task_Type__c = 'Post Drive Analysis AM'
        );

        Task_Definition__c sbpmDefinition = new Task_Definition__c(
            Name = 'Post-Drive Analysis/Future Drive Planning - SBPM',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Task_Type__c = 'Post Drive Analysis SBPM'
        );

        taskDefinitions.add(amDefinition);
        taskDefinitions.add(sbpmDefinition);

        insert taskDefinitions;

        // Task Planning Defaults
        List<Task_Planning_Default__c> planningDefaults =
            new List<Task_Planning_Default__c>();

        planningDefaults.add(
            new Task_Planning_Default__c(
                Template_Opportunity__c = testTemplate.Id,
                Task_Definition__c = amDefinition.Id
            )
        );

        planningDefaults.add(
            new Task_Planning_Default__c(
                Template_Opportunity__c = testTemplate.Id,
                Task_Definition__c = sbpmDefinition.Id
            )
        );

        insert planningDefaults;


        skedHubBase.setBypassAllTriggers(false);

        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearBypass('ContactTriggerHandler');
        TriggerHandler.clearBypass('SiteTriggerHandler');
        TriggerHandler.clearBypass('OpportunitySplitTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('TaskTriggerHandler');
    }

    @IsTest
    static void testAssignTaskOwner() {

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        // Create Task Definition used by the invocable.
        Task_Definition__c taskDefinition = new Task_Definition__c(
            Name = 'Post-Drive Analysis - AM',
            Task_Type__c = 'Post Drive Analysis AM',
            Assigned_To__c = 'Account Manager'
        );
        insert taskDefinition;

        Task testTask = new Task(
            Subject = 'Post-Drive Analysis - AM',
            Type = 'Post Drive Analysis AM',
            WhatId = opp.Id
        );

        DetermineTaskOwnerInvocable.InputWrapper input =
            new DetermineTaskOwnerInvocable.InputWrapper();

        input.tasks = new List<Task>{ testTask };
        input.taskTypes = new List<String>{ 'Post Drive Analysis AM'};

        Test.startTest();

        DetermineTaskOwnerInvocable.assignTaskOwner(
            new List<DetermineTaskOwnerInvocable.InputWrapper>{ input }
        );

        Test.stopTest();

        Task insertedTask = [
            SELECT Id, OwnerId, WhatId, Type
            FROM Task
            WHERE Subject = 'Post-Drive Analysis - AM'
            LIMIT 1
        ];

        Assert.areEqual(opp.Id, insertedTask.WhatId);
        Assert.areEqual('Post Drive Analysis AM', insertedTask.Type);
        Assert.isNotNull(insertedTask.OwnerId);
    }

    @IsTest
    static void testCreateOwnerHierarchy() {

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        Test.startTest();

        DetermineTaskOwnerInvocable.TaskHierarchyContext context =
            DetermineTaskOwnerInvocable.createOwnerkHierarchy(
                new Set<Id>{ opp.Id }
            );

        Test.stopTest();

        System.assertNotEquals(null, context);
        System.assertNotEquals(null, context.roleHierarchyMap);
        System.assertNotEquals(null, context.fallbackHierarchyMap);
    }

    @IsTest
    static void testTaskWithoutOpportunity() {

        Task testTask = new Task(
            Subject = 'Post-Drive Analysis - AM',
            Type = 'Post Drive Analysis AM'
        );

        DetermineTaskOwnerInvocable.InputWrapper input =
            new DetermineTaskOwnerInvocable.InputWrapper();

        input.tasks = new List<Task>{ testTask };
        input.taskTypes = new List<String>{ 'Post Drive Analysis AM'};

        Test.startTest();

        DetermineTaskOwnerInvocable.assignTaskOwner(
            new List<DetermineTaskOwnerInvocable.InputWrapper>{ input }
        );

        Test.stopTest();

        List<Task> insertedTasks = [
            SELECT Id, OwnerId
            FROM Task
            WHERE Subject = 'Post-Drive Analysis - AM'
            LIMIT 1
        ];

        Assert.areEqual(0, insertedTasks.size());
    }
}