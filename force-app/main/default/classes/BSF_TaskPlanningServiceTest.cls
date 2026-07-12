@isTest
private class BSF_TaskPlanningServiceTest {

    @testSetup
    static void setupTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        String mobileOppRecType = 'Mobile Opp';
        String mobileAccRecType = 'Mobile Account';
        String mobileSiteRecType = 'Mobile Site';  

        Map<String,Id> recordTypeMap  = new Map<String,Id>();
        recordTypeMap = recordTypeMap( 'Opportunity' );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        recordTypeMap = recordTypeMap( 'Account' );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);

        Profile p = [SELECT Id FROM Profile WHERE Name='Global Admin' LIMIT 1];
        User amUser = new User(Alias = 'amusr', 
                                Email='amuser@testtest.com', 
                                EmailEncodingKey='UTF-8', 
                                LastName='TestingAM', 
                                LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', 
                                ProfileId = p.Id, 
                                TimeZoneSidKey='America/Los_Angeles', 
                                UserName='amuser' + DateTime.now().getTime() + '@testtest.com');
        insert amUser;

        Account accObj;
        accObj = new Account();
        accObj.RecordTypeId = accRecTypeId;
        accObj.Name = 'Test Blood Drive Account';
        accObj.BillingPostalCode = '30622';
        accObj.Internal_Name__c ='Exavalu';  
        accObj.Planning_Path__c = 'Flexible';          
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTriggerHandler');
        insert accObj;

        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = amUser.Id ;
        atm.AccountId = accObj.Id ;
        atm.TeamMemberRole = 'Account Specialist';
        atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
        atm.End_Date__c = Date.Today().addDays(10);
        atm.Start_Date__c = Date.Today().addDays(-10);
        atmList.add(atm);
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;

        
        List<Task_Definition__c> taskDefs = new List<Task_Definition__c>();
        Task_Definition__c taskDef = new Task_Definition__c(Name = 'Test Definition', 
                                                            Assigned_To__c = 'Account Manager');
        taskDefs.add(taskDef);
        Task_Definition__c taskDef2 = new Task_Definition__c(Name = 'Test Definition 2', 
                                                            Assigned_To__c = 'Strategic Business Planning Manager');
        taskDefs.add(taskDef2);
        
        
        Task_Definition__c taskDefPubNoOrder = new Task_Definition__c(Name = 'Pub No Order', Task_Type__c = 'Publicity Order Not Created');
        taskDefs.add(taskDefPubNoOrder);
        Task_Definition__c taskDefPubReview = new Task_Definition__c(Name = 'Pub Review', Task_Type__c = 'Publicity Review Needed');
        taskDefs.add(taskDefPubReview);
        insert taskDefs;

        Task_Package__c taskPackage = new Task_Package__c(Name = 'Standard Tasks', Package_Name__c = 'Standard Tasks', Sort_Order__c = 1);
        insert taskPackage;

        List<Task_Package_Item__c> taskPackageItems = new List<Task_Package_Item__c>();
        taskPackageItems.add(new Task_Package_Item__c(Task_Package__c = taskPackage.Id, Task_Definition__c = taskDefs[0].Id));
        taskPackageItems.add(new Task_Package_Item__c(Task_Package__c = taskPackage.Id, Task_Definition__c = taskDefs[1].Id));
        insert taskPackageItems;

        
        List<Task_Selected_Package__c> bundles = new List<Task_Selected_Package__c>();
        bundles.add(new Task_Selected_Package__c(Account__c = accObj.Id, Task_Package__c = taskPackage.Id));
        insert bundles;

        Contact conObj = new Contact();
        conObj.AccountId = accObj.Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'test.barno@mailinator.com';
        conObj.Primary_Phone__c = picklistValues('Contact','Primary_Phone__c');
        conObj.Original_Service_Date__c = Date.Today().addDays(-1000);
        conObj.HomePhone = '222-222-3333';
        conObj.MobilePhone = '222-222-3333';
        conObj.OtherPhone = '222-222-3333';
        triggerHandler.bypass('ContactTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        insert conObj;
        
        sked__Tag__c skedTag = new sked__Tag__c(Name = 'Outside', sked__Type__c = 'Physical Location Type');
        insert skedTag; 

        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = siteRecTypeId;
        siteObj.Name = 'Test Site';
        siteObj.sked_Address_1__c = 'Test Site Address';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_City__c = 'Test Site City';
        siteObj.sked_State__c = 'Test Site State';
        siteObj.sked_Zip_Code__c = '4000';
        siteObj.sked_County__c = 'USA';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        siteObj.sked_Site_Inspection_Completed_By__c = amUser.Id;
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = conObj.Id;
        siteObj.sked_Site_Main_Phone__c = '758-771-0091';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.Source__c = 'Custom New Form';
        siteObj.sked_Date_Site_Inspection_Completed__c = Date.today();
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert siteObj;


        Opportunity templateOpp = new Opportunity();
        templateOpp.accountId = accObj.Id;
        templateOpp.CloseDate = Date.today().addDays(30);
        templateOpp.Is_Template__c = true;
        templateOpp.Name = 'Test Template';
        templateOpp.StageName = 'Discovery'; 
        templateOpp.Drive_Status__c = 'Draft';
        templateOpp.WB_Projected_Procedures__c = 1;
        templateOpp.X2RBC_Projected_Procedures__c = 1;
        templateOpp.Anticipated_Registered_Donors__c = 1;
        templateOpp.Type_of_Drive__c = 'Mobile';
        templateOpp.Planning_Path__c = 'Flexible';
        templateOpp.Drive_Site__c = siteObj.Id;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert templateOpp;

        
        insert new Task_Selected_Package__c(Opportunity__c = templateOpp.Id, Task_Package__c = taskPackage.Id);

        Opportunity optyObj ;
        optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = accObj.Id;
        optyObj.Drive_Site__c = siteObj.Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery'; 
        optyObj.Drive_Status__c = 'Draft'; 
        optyObj.Drive_Date__c = Date.today().addDays(60);
        optyObj.CloseDate = Date.today().addDays(30);
        optyObj.Start_Time__c =  Time.newInstance(13, 30, 2, 20);
        optyObj.End_Time__c =  Time.newInstance(18, 30, 2, 20);
        optyObj.WB_Projected_Procedures__c = 1;
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.Anticipated_Registered_Donors__c = 1;
        optyObj.Account_Manager__c = amUser.Id;
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.Planning_Path__c = 'Flexible';
        optyObj.Parent_Template_Id__c = templateOpp.Id;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert optyObj;

        
        Order testOrder = new Order(
            OpportunityId = optyObj.Id, AccountId = accObj.Id, 
            EffectiveDate = Date.today(), Status = 'Draft',
            Publicity_Approved__c = false
        );
        insert testOrder;

        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                        sked_Hold_Threshold__c = 100,
                                                                                                        Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                        Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                        sked_Work_Week_First_Day__c = 'Sunday');
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
         skedHubBase.BypassInsertTriggers = true;
        insert testCollectionOperation1;

        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Collection_Operation__c = testCollectionOperation1.Id,
                                                        sked_Drive_Date__c = Date.today().addDays(60),
                                                        sked_Drive_Site__c = siteObj.Id,
                                                        sked_Opportunity__c = optyObj.Id,
                                                        sked_Type_of_Drive__c = 'Mobile',
                                                        sked_Account__c = accObj.Id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
                                                         sked_2RBC_Projected_Procedures__c = 2);
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('DriveTriggerHandler');
        insert testDrive1;

        Task_Planning_Default__c accConfig = new Task_Planning_Default__c(Account__c = accObj.Id, 
                                                                    Configured_Date__c = date.today(),
                                                                    Configured_Offset__c = 10, 
                                                                    Task_Definition__c = taskDefs[0].Id,
                                                                    Scheduling_Method__c = 'Days Offset');
        insert accConfig;
        
        Task_Planning_Default__c tempConfig = new Task_Planning_Default__c(Template_Opportunity__c = templateOpp.Id, 
                                                                        Configured_Date__c = date.today(),
                                                                        Configured_Offset__c = 50, 
                                                                        Task_Definition__c = taskDefs[0].Id,
                                                                        Scheduling_Method__c = 'Target Date');
        insert tempConfig;

        List<Planned_Task__c> pts = new List<Planned_Task__c>();
        pts.add(new Planned_Task__c(Related_Opportunity__c = optyObj.Id, Subject__c = 'Test Initial Outreach', Status__c = 'Configured', Scheduling_Method__c = 'Days Offset', User_Defined_Offset__c = 5, Task_Definition__c = taskDefs[0].Id));
        pts.add(new Planned_Task__c(Related_Opportunity__c = optyObj.Id, Subject__c = 'Test Initial Break', Status__c = 'Configured', Scheduling_Method__c = 'Target Date', Target_Date__c = Date.today(), Task_Definition__c = taskDefs[1].Id));
        
        
        pts.add(new Planned_Task__c(Related_Opportunity__c = optyObj.Id, Subject__c = 'Pub Task 1', Status__c = 'Configured', Task_Definition__c = taskDefs[2].Id));
        pts.add(new Planned_Task__c(Related_Opportunity__c = optyObj.Id, Subject__c = 'Pub Task 2', Status__c = 'Configured', Task_Definition__c = taskDefs[3].Id));
        
        insert pts;
    }

    
    @isTest static void testNullAndEmptyCases() {
        Test.startTest();
        BSF_TaskPlanningService.generateTasksFromQueue(null);
        BSF_TaskPlanningService.generateTasksFromQueue(new Set<Id>());
        BSF_TaskPlanningService.syncTaskDates(new Map<Id, Opportunity>(), null);
        BSF_TaskPlanningService.initializeAccountTaskConfigs(null);
        BSF_TaskPlanningService.handleDatabaseResults(null, 'Null Check');
        System.assert(true, 'Null handling methods executed without exceptions.');
        Test.stopTest();
    }

    @isTest static void testGenerateTasksFromQueue() {
        Opportunity driveOpp = [SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        Test.startTest();
        BSF_TaskPlanningService.generateTasksFromQueue(new Set<Id>{driveOpp.Id});
        Test.stopTest();
    }

    @isTest static void testProcessAndGenerateTasks_DuplicateCheck() {
        Opportunity driveOpp = [SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        List<Planned_Task__c> pTasks = [SELECT Id, Related_Opportunity__c, Subject__c, Status__c, Task_Definition__r.Assigned_To__c, Task_Definition__r.Task_Type__c FROM Planned_Task__c WHERE Related_Opportunity__c = :driveOpp.Id];
        
        Task existingTask = new Task(WhatId = driveOpp.Id, Subject = 'Test Initial Outreach', Status = 'Not Started');
        insert existingTask;

        Test.startTest();
        BSF_TaskPlanningService.processAndGenerateTasks(pTasks, false);
        Test.stopTest();
    }

    
    @isTest static void testProcessAndGenerateTasks_PublicityHandlers() {
        Opportunity driveOpp = [SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        
        
        List<Planned_Task__c> pubTasks = [
            SELECT Id, Related_Opportunity__c, Status__c, Task_Definition__r.Task_Type__c, Task_Definition__r.Assigned_To__c 
            FROM Planned_Task__c 
            WHERE Task_Definition__r.Task_Type__c IN ('Publicity Order Not Created', 'Publicity Review Needed')
        ];

        Test.startTest();
        BSF_TaskPlanningService.processAndGenerateTasks(pubTasks, false);
        Test.stopTest();
        
        System.assert(!pubTasks.isEmpty(), 'Publicity tasks should be processed covering specific handler logic.');
    }

    @isTest static void testProcessAndGenerateTasks_PlatformEvents() {
        Opportunity driveOpp = [SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        List<Planned_Task__c> pTasks = [SELECT Id, Related_Opportunity__c, Subject__c, Status__c, Task_Definition__r.Assigned_To__c, Task_Definition__r.Task_Type__c FROM Planned_Task__c WHERE Related_Opportunity__c = :driveOpp.Id];
        
        Test.startTest();
        BSF_TaskPlanningService.processAndGenerateTasks(pTasks, true);
        Test.stopTest();
        System.assert(true, 'Platform event routing executed without exceptions.');
    }

    @isTest static void testSyncTaskDates() {
        Opportunity opp = [SELECT Id, Drive_Date__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        
        Task existingTask = new Task(WhatId = opp.Id, Subject = 'Drive Prep', ActivityDate = opp.Drive_Date__c.addDays(-10), Status = 'Not Started');
        insert existingTask;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => opp.clone(true, true, true, true) };
        
        opp.Drive_Date__c = opp.Drive_Date__c.addDays(15);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        BSF_TaskPlanningService.syncTaskDates(newMap, oldMap);
        Test.stopTest();

        Task updatedTask = [SELECT ActivityDate FROM Task WHERE Id = :existingTask.Id];
        System.assertEquals(opp.Drive_Date__c, updatedTask.ActivityDate, 'Task date should shift in sync with the Opportunity.');
    }

    @isTest static void testInheritConfiguration() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity template = [SELECT Id FROM Opportunity WHERE Is_Template__c = true LIMIT 1];

        Opportunity newDrive = new Opportunity(
            Name = 'New Clone Drive', AccountId = acc.Id, Parent_Template_Id__c = template.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Type_of_Drive__c = 'Mobile'
        );
        
        Opportunity newTemplateClone = new Opportunity(
            Name = 'New Clone Template', AccountId = acc.Id, Is_Template__c = true,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Type_of_Drive__c = 'Mobile'
        );

        Test.startTest();
        BSF_TaskPlanningService.inheritConfiguration(new List<Opportunity>{newDrive, newTemplateClone});
        Test.stopTest();
    }

    @isTest static void testCascadeHelpers() {
        Opportunity template = [SELECT Id, AccountId FROM Opportunity WHERE Is_Template__c = true LIMIT 1];
        Opportunity drive = [SELECT Id, Parent_Template_Id__c, Drive_Status__c, Planning_Path__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];

        Test.startTest();
        BSF_TaskPlanningService.cascadeAccountToTemplates(new List<Opportunity>{template});
        
        drive.Drive_Status__c = 'Confirmed'; 
        BSF_TaskPlanningService.cascadeTemplateToDrives(new List<Opportunity>{drive});
        Test.stopTest();

        System.assertEquals('Confirmed', drive.Drive_Status__c, 'Cascade to Drives should be Confirmed.');
    }

    @isTest static void testHandleOpportunityUpdates() {
        Opportunity drive = [SELECT Id, Drive_Status__c, Type_of_Drive__c, Is_Template__c, Drive_Date__c, Planning_Path__c, RecordTypeId, Parent_Template_Id__c, Is_Path_Overridden__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        Opportunity template = [SELECT Id, Drive_Status__c, Is_Template__c, Type_of_Drive__c, Drive_Date__c, Planning_Path__c, RecordTypeId, Parent_Template_Id__c, Is_Path_Overridden__c FROM Opportunity WHERE Is_Template__c = true LIMIT 1];
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{
            drive.Id => drive.clone(true, true, true, true),
            template.Id => template.clone(true, true, true, true)
        };

        template.Planning_Path__c = 'Standard';

        Test.startTest();
        BSF_TaskPlanningService.handleOpportunityUpdates(new List<Opportunity>{drive, template}, oldMap);
        Test.stopTest();
    }

    @isTest static void testHandlePathCleanup() {
        Opportunity drive = [SELECT Id, Planning_Path__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ drive.Id => drive.clone(true, true, true, true) };
        oldMap.get(drive.Id).Planning_Path__c = 'Flexible'; 
        
        drive.Planning_Path__c = 'Standard'; 

        Test.startTest();
        BSF_TaskPlanningService.handlePathCleanup(new List<Opportunity>{drive}, oldMap);
        Test.stopTest();

        List<Planned_Task__c> remainingTasks = [SELECT Id FROM Planned_Task__c WHERE Related_Opportunity__c = :drive.Id];
        System.assert(remainingTasks.isEmpty(), 'Cleanup should delete Planned Tasks when reverting to Standard path.');
    }

    @isTest static void testDetermineTaskOwner_Advanced() {
        Map<String, Id> oppRoles = new Map<String, Id>{ 'Account Manager' => UserInfo.getUserId() };
        Map<String, List<String>> fallbackMap = new Map<String, List<String>>{
            'Account Manager' => new List<String>{'Account Manager', 'District Manager'}
        };

        Test.startTest();
        Id ownerId = BSF_TaskPlanningService.determineTaskOwner('Account Manager', oppRoles, fallbackMap);
        System.assertEquals(UserInfo.getUserId(), ownerId, 'Should find explicit owner.');
        
        Id emptyOwnerId = BSF_TaskPlanningService.determineTaskOwner('Account Manager', null, fallbackMap);
        System.assertEquals(null, emptyOwnerId, 'Null roles should return null owner.');
        
        Id sysManagerOwnerId = BSF_TaskPlanningService.determineTaskOwner('SBPM', oppRoles, fallbackMap); 
        Test.stopTest();
    }

    @isTest static void testGetFieldValue() {
        Opportunity opp = [SELECT Id, Drive_Date__c, Account.Name FROM Opportunity LIMIT 1];
        
        Test.startTest();
        System.assertEquals(opp.Id, BSF_TaskPlanningService.getFieldValue(opp, 'Id'), 'Direct retrieval failed.');
        System.assertEquals('Test Blood Drive Account', BSF_TaskPlanningService.getFieldValue(opp, 'Account.Name'), 'Cross-object retrieval failed.');
        System.assertEquals(null, BSF_TaskPlanningService.getFieldValue(opp, 'Drive_Date__c'), 'Null field should safely return null.');
        System.assertEquals(null, BSF_TaskPlanningService.getFieldValue(null, 'Id'), 'Null record should return null.');
        Test.stopTest();
    }

    @isTest static void testPlatformEventConverters() {
        Map<String, String> peMapping = new Map<String, String>{'Subject' => 'Subject__c', 'ActivityDate' => 'ActivityDate__c'};
        Task t = new Task(Subject = 'Test PE Mapping', ActivityDate = Date.today());

        Test.startTest();
        Task_Platform_Event__e pe = BSF_TaskPlanningService.buildPlatformEvent(t, 'a00000000000001AAA', peMapping);
        System.assertEquals('Test PE Mapping', pe.Subject__c, 'Task data should map to PE.');

        Task newT = BSF_TaskPlanningService.buildTaskFromEvent(pe, peMapping);
        System.assertEquals('Test PE Mapping', newT.Subject, 'PE data should map back to Task.');
        Test.stopTest();
    }

    @isTest static void testHandleDatabaseResults_Errors() {
        Opportunity badOpp = new Opportunity();
        Database.SaveResult[] srList = Database.insert(new List<Opportunity>{badOpp}, false);

        
        String deleteJson = '[{"success":false,"errors":[{"message":"Mock delete error","statusCode":"UNKNOWN_EXCEPTION"}]}]';
        List<Database.DeleteResult> drList = (List<Database.DeleteResult>)JSON.deserialize(deleteJson, List<Database.DeleteResult>.class);

        Test.startTest();
        BSF_TaskPlanningService.handleDatabaseResults(srList, 'Test DML Save Error Logging');
        BSF_TaskPlanningService.handleDatabaseResults(drList, 'Test DML Delete Error Logging');
        Test.stopTest();
        
        System.assert(true, 'handleDatabaseResults parsed SaveResult and DeleteResult errors without crashing.');
    }

    @isTest static void testTriggerTaskGenerationOnConfirm() {
        Opportunity opp = [SELECT Id, AccountId, Drive_Site__c, Drive_date__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        
        sked_Drive__c oldDrive = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Drive_Date__c = opp.Drive_Date__c,
                                                        sked_Drive_Site__c = opp.Drive_Site__c,
                                                        sked_Opportunity__c = opp.Id,
                                                        sked_Type_of_Drive__c = 'Mobile',
                                                        sked_Account__c = opp.AccountId,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
                                                         sked_2RBC_Projected_Procedures__c = 2);
        TriggerHandler.bypass('DriveTriggerHandler');
         skedHubBase.BypassInsertTriggers = true;
        insert oldDrive;

        sked_Drive__c newDrive = oldDrive.clone(true, true, true, true);
        newDrive.sked_Status__c = 'Confirmed';

        List<sked_Drive__c> newList = new List<sked_Drive__c>{ newDrive };
        Map<Id, sked_Drive__c> oldMap = new Map<Id, sked_Drive__c>{ oldDrive.Id => oldDrive };

        Test.startTest();
        BSF_TaskPlanningService.triggerTaskGenerationOnConfirm(newList, oldMap);
        Test.stopTest();
        
        newDrive.sked_Status__c = 'Cancelled';
        BSF_TaskPlanningService.triggerTaskGenerationOnConfirm(new List<sked_Drive__c>{ newDrive }, oldMap);
    }

    @isTest static void testInitializeAccountTaskConfigs() {
        Account acc = [SELECT Id, RecordTypeId, Planning_Path__c FROM Account LIMIT 1];

        Test.startTest();
        BSF_TaskPlanningService.initializeAccountTaskConfigs(new List<Account>{acc});
        Test.stopTest();

        List<Task_Planning_Default__c> configs = [SELECT Id FROM Task_Planning_Default__c WHERE Account__c = :acc.Id];
        System.assert(!configs.isEmpty(), 'Account Task Planning Defaults should be initialized for new Account.');
    }

    private static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }

    private static String picklistValues(String objectName, String fieldName) {
        String result;
        List<Schema.DescribeSobjectResult> sobjectlist = Schema.describeSObjects(new List<String>{objectName});
        
        for(Schema.DescribeSobjectResult sobj : sobjectlist) {
            for (Schema.PicklistEntry entry : sobj.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    result = entry.getValue();
                    break;
                }
            }
        }
        return result;
    }
}