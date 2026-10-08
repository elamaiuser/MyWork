@IsTest
public class BSF_Batch_CreatePstDriveAnalysisTaskTest {
    @testSetup
    static void setupTestData() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        skedHubBase.setBypassAllTriggers(true);
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId =  testMobileAccount.Id;
        insert testContact;
        
        // insert Mobile Site
        //sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        sked__Location__c testMobileSite = new sked__Location__c(
            Name = 'Test Mobile Location',
            RecordTypeId=  sked__Location__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('sked_Mobile_Site').getRecordTypeId(),  
            sked_TimeZone__c = 'America/New_York',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA, 27560',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Address_1__c = 'Test Address', 
            sked_City__c = 'city', 
            sked_County__c = 'United States', 
            sked_State__c = 'Texas', 
            sked_Zip_Code__c = '27560',
            Source__c ='Custom New Form'
        );
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        List<Opportunity> testOpps = new List<Opportunity>();
        // insert Mobile Opps
        Opportunity testMobileOpp1 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
        testOpps.add(testMobileOpp1);
        
         // insert Mobile Opp 2
        Opportunity testMobileOpp2 = testMobileOpp1.clone();
        testMobileOpp2.name = 'Test Opportunity 2';
        testOpps.add(testMobileOpp2);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert testOpps;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        
        TriggerHandler.bypass('TaskTriggerHandler');
        List<sked_Drive__c> testDrive = new List<sked_Drive__c>();
        //insert DOC
        sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive1',
            sked_Drive_Date__c = system.today(),
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
        testDrive.add(testDrive1);
        
        //insert DOC
        sked_Drive__c testDrive2 = new sked_Drive__c(
            Name = 'Test Drive2',
            sked_Drive_Date__c = system.today(),
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
        testDrive.add(testDrive2);
        insert testDrive;
        TriggerHandler.clearBypass('TaskTriggerHandler');
        
        List<Task_Definition__c > taskDefinitionListToInsert = new List<Task_Definition__c >();
        
        taskDefinitionListToInsert.add(new Task_Definition__c (Name = 'Post-Drive Analysis - AM', 
                                                               Assigned_To__c = 'Account Manager', 
                                                               Task_Type__c = 'Post Drive Analysis AM' ));
        
        taskDefinitionListToInsert.add(new Task_Definition__c (Name = 'Post-Drive Analysis/Future Drive Planning - SBPM', 
                                                               Assigned_To__c = 'Strategic Business Planning Manager', 
                                                               Task_Type__c = 'Post Drive Analysis SBPM' ));
        
        insert taskDefinitionListToInsert;
        List<Task_Definition__c> taskDefList = [SELECT Name, Task_Type__c, Assigned_To__c FROM Task_Definition__c WHERE Task_Type__c LIKE '%Post%' ];
        System.debug('taskDefList==> '+taskDefList);
    }
    
    @isTest
    static void createPostDriveAnalysisTask_Test(){
        List<sked_Drive__c> driveList = [SELECT Id, sked_Status__c  FROM sked_Drive__c WHERE Name LIKE 'Test Drive%' AND sked_Status__c !='Complete' LIMIT 2];
        for(sked_Drive__c dr: driveList){
            dr.sked_Status__c = 'Complete';
        }
        
        TriggerHandler.bypass('DriveTriggerHandler');
        update driveList;
        TriggerHandler.clearBypass('DriveTriggerHandler');
        
        List<Task> tasksCreatedWithFlow = [SELECT Id, Subject, Drive_Date__c, ActivityDate,  Status, CreatedDate, LastModifiedDate, LastModifiedBy.Name,  Type, WhatId   FROM Task];
    	delete tasksCreatedWithFlow;
        
        Map<String, String> subjectVsTypeMap = new Map<String, String>{'Post-Drive Analysis/Future Drive Planning - SBPM' => 'Post Drive Analysis SBPM',  'Post-Drive Analysis - AM' => 'Post Drive Analysis AM' };
        Test.startTest();
            List<String> patterns = new List<String>{
                'Post Drive Analysis',
                'Post-Drive Analysis'
            };
            Database.executeBatch(new BSF_Batch_CreatePostDriveAnalysisTask(subjectVsTypeMap, patterns, Date.newInstance(2026,07,13)));
        Test.stopTest();
        
        List<Task> tasks = [SELECT Id, Subject, Drive_Date__c, ActivityDate,  Status, CreatedDate, LastModifiedDate, LastModifiedBy.Name,  Type, WhatId   FROM Task];
        System.debug('tasks=> '+tasks);
        Assert.areEqual(4, tasks.size());
    }
    
    @isTest
    static void createPostDriveAnalysisTask_Test2(){
        List<sked_Drive__c> driveList = [SELECT Id, sked_Status__c  FROM sked_Drive__c WHERE Name LIKE 'Test Drive%' AND sked_Status__c !='Complete' LIMIT 2];
        for(sked_Drive__c dr: driveList){
            dr.sked_Status__c = 'Complete';
        }
        
        TriggerHandler.bypass('DriveTriggerHandler');
        update driveList;
        TriggerHandler.clearBypass('DriveTriggerHandler');
        
        List<Task> tasksCreatedWithFlow = [SELECT Id, Subject, Drive_Date__c, ActivityDate,  Status, CreatedDate, LastModifiedDate, LastModifiedBy.Name,  Type, WhatId FROM Task WHERE Subject ='Post-Drive Analysis - AM'];
    	delete tasksCreatedWithFlow;
        
        Map<String, String> subjectVsTypeMap = new Map<String, String>{'Post-Drive Analysis/Future Drive Planning - SBPM' => 'Post Drive Analysis SBPM',  'Post-Drive Analysis - AM' => 'Post Drive Analysis AM' };
        Test.startTest();
            List<String> patterns = new List<String>{
                'Post Drive Analysis',
                'Post-Drive Analysis'
            };
            Database.executeBatch(new BSF_Batch_CreatePostDriveAnalysisTask(subjectVsTypeMap, patterns, Date.newInstance(2026,07,13)));
        Test.stopTest();
        
        List<Task> tasks = [SELECT Id, Subject, Drive_Date__c, ActivityDate,  Status, CreatedDate, LastModifiedDate, LastModifiedBy.Name,  Type, WhatId FROM Task];
        System.debug('tasks=> '+tasks);
        Assert.areEqual(4, tasks.size());
    }
    
    @isTest
    static void createPostDriveAnalysisTask_Test3(){
        Test.startTest();
            List<String> patterns = new List<String>();
        	Map<String, String> subjectVsTypeMap = new Map<String, String>{'Post-Drive Analysis/Future Drive Planning - SBPM' => 'Post Drive Analysis SBPM',  'Post-Drive Analysis - AM' => 'Post Drive Analysis AM' };
            Database.executeBatch(new BSF_Batch_CreatePostDriveAnalysisTask(subjectVsTypeMap, null, Date.newInstance(2026,07,13)));
        Test.stopTest();
    }
}