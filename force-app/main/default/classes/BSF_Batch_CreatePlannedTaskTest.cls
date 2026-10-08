@IsTest
public class BSF_Batch_CreatePlannedTaskTest {

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
        
        Opportunity testMobileOpp3 = testMobileOpp1.clone();
        testMobileOpp3.Name = 'Test Opportunity 3';
        testMobileOpp3.Drive_Date__c = Date.today().addDays(10);

        insert new List<Opportunity>{
            testMobileOpp1,
            testMobileOpp2,
            testMobileOpp3
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
        
        sked_Drive__c testDrive3 = new sked_Drive__c(
            Name = 'Test Drive3',
            sked_Drive_Date__c = testMobileOpp3.Drive_Date__c,
            sked_Drive_Site__c = testMobileOpp3.Drive_Site__c,
            sked_Opportunity__c = testMobileOpp3.Id,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testMobileOpp3.AccountId,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Total_Products_Projected__c = 30,
            sked_2RBC_Projected_Procedures__c = 10,
            sked_WB_Projected_Procedures__c = 10
        );

        testDrives.add(testDrive3);

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
    static void BSF_Batch_CreatePlannedTask_Test() {

        List<Opportunity> opportunities = [
            SELECT Id,
                   Name,
                   Drive_Date__c,
                   DriveStatus__c,
                   Type_of_Drive__c,
                   Parent_Template_Id__c,
                   AccountId
            FROM Opportunity
            WHERE Name IN ('Test Opportunity 2')
        ];

        Assert.areEqual(1, opportunities.size(), 'Test Opportunity should exist.');

        Opportunity testOpp = opportunities[0];

        BSF_Batch_CreatePlannedTask.InputWrapper inputs =
            new BSF_Batch_CreatePlannedTask.InputWrapper();

        inputs.driveDate = Date.today().addDays(-10);

        inputs.opportunityIds = new Set<Id>{
            testOpp.Id
        };

        inputs.taskSubjects = new Set<String>{
            'Post-Drive Analysis - AM',
            'Post-Drive Analysis/Future Drive Planning - SBPM'
        };

        Test.startTest();

        Database.executeBatch(
            new BSF_Batch_CreatePlannedTask(inputs)
        );

        Test.stopTest();

        List<Task> createdTasks = [
            SELECT Id,
                   Subject,
                   ActivityDate,
                   Priority,
                   RecordTypeId,
                   WhatId,
                   Drive_Date__c,
                   Type
            FROM Task
            WHERE WhatId = :testOpp.Id
            AND Subject IN :inputs.taskSubjects
        ];

        Assert.areEqual(2, createdTasks.size(), 'Two planned tasks should have been created.');


        Set<String> subjects = new Set<String>();

        for (Task task : createdTasks) {

            subjects.add(task.Subject);

            Assert.areEqual(testOpp.Id, task.WhatId, 'Task should be related to the Opportunity.');

            Assert.areEqual(testOpp.Drive_Date__c, task.ActivityDate, 'Task ActivityDate should match Drive Date.');

            Assert.areEqual(testOpp.Drive_Date__c,  task.Drive_Date__c, 'Task Drive Date should match Opportunity Drive Date.');

            Assert.areEqual('High', task.Priority, 'Created task should have High priority.');

            Assert.areNotEqual(null, task.RecordTypeId, 'Task should have the General Task record type.');
        }

        Assert.isTrue(subjects.contains('Post-Drive Analysis - AM'), 'AM task should have been created.');

        Assert.isTrue(subjects.contains('Post-Drive Analysis/Future Drive Planning - SBPM'), 'SBPM task should have been created.');
    }

    @IsTest
    static void BSF_Batch_CreatePlannedTask_DuplicateTask_Test() {

        Opportunity testOpp = [
            SELECT Id, Drive_Date__c
            FROM Opportunity
            WHERE Name = 'Test Opportunity 2'
            LIMIT 1
        ];

        insert new Task(
            Subject = 'Post-Drive Analysis - AM',
            WhatId = testOpp.Id,
            ActivityDate = testOpp.Drive_Date__c,
            Priority = 'High'
        );


        BSF_Batch_CreatePlannedTask.InputWrapper inputs =
            new BSF_Batch_CreatePlannedTask.InputWrapper();

        inputs.driveDate = Date.today().addDays(-10);

        inputs.opportunityIds = new Set<Id>{
            testOpp.Id
        };

        inputs.taskSubjects = new Set<String>{
            'Post-Drive Analysis - AM',
            'Post-Drive Analysis/Future Drive Planning - SBPM'
        };


        Test.startTest();

        Database.executeBatch(
            new BSF_Batch_CreatePlannedTask(inputs)
        );

        Test.stopTest();


        List<Task> tasks = [
            SELECT Id, Subject, WhatId
            FROM Task
            WHERE WhatId = :testOpp.Id
            AND Subject IN :inputs.taskSubjects
        ];

        Assert.areEqual(2, tasks.size(), 'Existing task should not be duplicated.');


        Integer amCount = 0;
        Integer sbpmCount = 0;

        for (Task task : tasks) {

            if (task.Subject == 'Post-Drive Analysis - AM') {
                amCount++;
            }

            if (
                task.Subject ==
                'Post-Drive Analysis/Future Drive Planning - SBPM'
            ) {
                sbpmCount++;
            }
        }

        Assert.areEqual(1, amCount, 'AM task should exist only once.');

        Assert.areEqual(1, sbpmCount, 'SBPM task should have been created.');
    }


    @IsTest
    static void BSF_Batch_CreatePlannedTask_NoOpportunityFilter_Test() {

        BSF_Batch_CreatePlannedTask.InputWrapper inputs =
            new BSF_Batch_CreatePlannedTask.InputWrapper();

        inputs.driveDate = Date.today().addDays(-10);

        inputs.taskSubjects = new Set<String>{
            'Post-Drive Analysis - AM'
        };


        Test.startTest();

        Database.executeBatch(
            new BSF_Batch_CreatePlannedTask(inputs)
        );

        Test.stopTest();


        Assert.isTrue(true, 'Batch should complete successfully without Opportunity filter.');
    }


    @IsTest
    static void BSF_Batch_CreatePlannedTask_EmptySubjects_Test() {

        Opportunity testOpp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Test Opportunity 2'
            LIMIT 1
        ];

        BSF_Batch_CreatePlannedTask.InputWrapper inputs =
            new BSF_Batch_CreatePlannedTask.InputWrapper();

        inputs.driveDate = Date.today().addDays(-10);

        inputs.opportunityIds = new Set<Id>{
            testOpp.Id
        };

        inputs.taskSubjects = new Set<String>();


        Test.startTest();

        Database.executeBatch(
            new BSF_Batch_CreatePlannedTask(inputs)
        );

        Test.stopTest();


        List<Task> tasks = [
            SELECT Id
            FROM Task
            WHERE WhatId = :testOpp.Id
            AND Subject IN (
                'Post-Drive Analysis - AM',
                'Post-Drive Analysis/Future Drive Planning - SBPM'
            )
        ];


        Assert.areEqual(2,tasks.size());
    }
    
    @IsTest
    static void BSF_Batch_CreatePlannedTask_Exception_Test() {

        Opportunity testOpp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Test Opportunity 2'
            LIMIT 1
        ];

        BSF_Batch_CreatePlannedTask.InputWrapper inputs =
            new BSF_Batch_CreatePlannedTask.InputWrapper();

        inputs.driveDate = Date.today().addDays(-10);

        inputs.opportunityIds = new Set<Id>{
            testOpp.Id
        };

        inputs.taskSubjects = new Set<String>();


        Test.startTest();
		BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION = TRUE;
        Database.executeBatch(
            new BSF_Batch_CreatePlannedTask(inputs)
        );

        Test.stopTest();


        List<Task> tasks = [
            SELECT Id
            FROM Task
            WHERE WhatId = :testOpp.Id
            AND Subject IN (
                'Post-Drive Analysis - AM',
                'Post-Drive Analysis/Future Drive Planning - SBPM'
            )
        ];


        Assert.areEqual(2,tasks.size());
    }
}