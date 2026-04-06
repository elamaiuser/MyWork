@isTest
private class BSF_TemplateTaskPlanningCascadeBatchTest {

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
        Task_Definition__c taskDef = new Task_Definition__c(Name = 'Test Definition', Assigned_To__c = 'Account Manager', Category__c = 'Standard', Scheduling_Method__c = 'Days Offset', Due_Date_Offset__c = 10);
        taskDefs.add(taskDef);
        Task_Definition__c taskDef2 = new Task_Definition__c(Name = 'Test Definition 2', Assigned_To__c = 'Strategic Business Planning Manager', Category__c = 'Standard', Scheduling_Method__c = 'Target Date');
        taskDefs.add(taskDef2);
        
        Task_Definition__c taskDefPubNoOrder = new Task_Definition__c(Name = 'Pub No Order', Task_Type__c = 'Publicity Order Not Created', Category__c = 'Standard');
        taskDefs.add(taskDefPubNoOrder);
        Task_Definition__c taskDefPubReview = new Task_Definition__c(Name = 'Pub Review', Task_Type__c = 'Publicity Review Needed', Category__c = 'Flexible');
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
        templateOpp.Is_Path_Overridden__c = false;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert templateOpp;

        
        Task_Planning_Default__c tempConfig = new Task_Planning_Default__c(Template_Opportunity__c = templateOpp.Id, 
                                                                        Configured_Date__c = date.today(),
                                                                        Configured_Offset__c = 50, 
                                                                        Task_Definition__c = taskDefs[0].Id,
                                                                        Scheduling_Method__c = 'Target Date',
                                                                        Task_Package__c = taskPackage.Id);
        insert tempConfig;

        
        Opportunity optyObj = new Opportunity();
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
        optyObj.Is_Path_Overridden__c = false;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert optyObj;
        
    }
    

    @isTest
    static void testBatchExecution_DraftDrive() {
        
        Opportunity template = [SELECT Id FROM Opportunity WHERE Is_Template__c = TRUE LIMIT 1];
        Opportunity drive = [SELECT Id, Drive_Status__c FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
        
        System.assertEquals('Draft', drive.Drive_Status__c, 'Drive should be in Draft status.');

        Test.startTest();
        
        BSF_TemplateTaskPlanningCascadeBatch batch = new BSF_TemplateTaskPlanningCascadeBatch(new Set<Id>{template.Id});
        Database.executeBatch(batch);
        Test.stopTest(); 

        
        List<Planned_Task__c> generatedQueueItems = [SELECT Id, Task_Definition__c FROM Planned_Task__c WHERE Related_Opportunity__c = :drive.Id];
        System.assert(!generatedQueueItems.isEmpty(), 'Planned Tasks should have been cascaded down from the Template to the Drive.');
        
        
        List<Task> actualTasks = [SELECT Id FROM Task WHERE WhatId = :drive.Id];
        System.assert(actualTasks.isEmpty(), 'Actual Tasks should NOT be generated for Draft drives.');
    }

    @isTest
    static void testBatchExecution_ConfirmedDrive() {
        
        Opportunity template = [SELECT Id FROM Opportunity WHERE Is_Template__c = TRUE LIMIT 1];
        Opportunity drive = [SELECT Id, Drive_Status__c, Planning_Path__c FROM Opportunity WHERE Is_Template__c = FALSE LIMIT 1];
        
        
        TriggerHandler.bypass('OpportunityTriggerHandler'); 
        drive.Drive_Status__c = 'Confirmed';
        update drive;

        Test.startTest();
        BSF_TemplateTaskPlanningCascadeBatch batch = new BSF_TemplateTaskPlanningCascadeBatch(new Set<Id>{template.Id});
        Database.executeBatch(batch);
        Test.stopTest();

        
        List<Planned_Task__c> generatedQueueItems = [SELECT Id, Status__c FROM Planned_Task__c WHERE Related_Opportunity__c = :drive.Id];
        System.assert(!generatedQueueItems.isEmpty(), 'Planned Tasks should have been cascaded down.');
        
        
        
        Boolean containsProcessed = false;
        for(Planned_Task__c pt : generatedQueueItems) {
            if(pt.Status__c == 'Processed') {
                containsProcessed = true;
            }
        }
        System.assert(containsProcessed, 'The batch should have triggered Task Generation, marking the Planned Task as Processed.');
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