@isTest
private class BSFTaskChecklistTriggerTest {
    
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

        Map<String, Map<String, Task_Checklist_Setting__mdt>> metadataMap = BSFTaskChecklistTriggerHandler.getMetaDataMap();
        List<String> taskTypesList = new List<String>{BSF_Constants.TASK_TYPE_RECRUITMENT_STRATEGY_MEETING,
                                                        BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_AM,
                                                        BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_SBPM,
                                                        BSF_Constants.TASK_TYPE_72_HOUR_CHECK_IN};
        List<Task_Definition__c> taskDefs = new List<Task_Definition__c>();
        Integer sortOrder = 0;
        for(String subject : metadataMap.keySet()){
            String AssignedTo = (Math.mod(sortOrder,2) == 0) ? 'Account Manager' : 'Strategic Business Planning Manager';
            String taskType = taskTypesList.get(Math.mod(sortOrder,4));
            Task_Definition__c taskDef = new Task_Definition__c(Name = subject, 
                                                                    Assigned_To__c = AssignedTo,
                                                                    Task_Type__c = taskType);
            taskDefs.add(taskDef);
            sortOrder++;
        }
        insert taskDefs;

        Task_Package__c taskPackage = new Task_Package__c(Name = 'Standard Tasks', Package_Name__c = 'Standard Tasks', Sort_Order__c = 1);
        insert taskPackage;

        List<Task_Package_Item__c> taskPackageItems = new List<Task_Package_Item__c>();
        for(Task_Definition__c taskDef : taskDefs){
            taskPackageItems.add(new Task_Package_Item__c(Task_Package__c = taskPackage.Id, Task_Definition__c = taskDef.Id));
        }
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

        Map<String, String> subjectToTypeMap = new Map<String, String>();
        for(Task_Definition__c def :
            [
                SELECT Name, 
                    Task_Type__c 
                FROM Task_Definition__c
                WHERE Task_Type__c != null
            ]
        ){
            subjectToTypeMap.put(def.Name, def.Task_Type__c);
        }
        List<Task> tasksToInsert = new List<Task>();
        for(String subject : subjectToTypeMap.keySet()){
            Task t = new Task(Subject = subject, WhatId = optyObj.Id,
                            Status = 'Not Started', Priority = 'Normal',
                            Type = subjectToTypeMap.get(subject));
            tasksToInsert.add(t);
        }
        Database.insert(tasksToInsert, false);
    }

    @isTest
    private static void testmethod1() {
        TriggerHandler.Bypass('OpportunityTriggerHandler');
        Map<String, Map<String, Task_Checklist_Setting__mdt>> metadataMap = BSFTaskChecklistTriggerHandler.getMetaDataMap();
        Map<Id,Task> pdaTask = new Map<Id,Task>([SELECT Id FROM Task WHERE Subject IN : metadataMap.keySet()]);

        for(Id taskId : pdaTask.keySet()){
            TaskChecklistController.getRelatedCheckistRecords(taskId);
        }
        
        Test.startTest();
        
        
        List<BSF_Task_Checklist__c> checklists = [SELECT Id, 
                                                            Name, 
                                                            Unique_Name__c, 
                                                            Input_Long_Text_Area__c, 
                                                            Input_Short_Text_1__c, 
                                                            Input_Short_Text_2__c, 
                                                            Input_Checkbox__c, 
                                                            Picklist_Input_1__c, 
                                                            Picklist_Input_2__c, 
                                                            Input_Number__c, 
                                                            TaskLookup__c, 
                                                            TaskType__c, 
                                                            OpportunityLookup__c 
                                                        FROM BSF_Task_Checklist__c
                                                        WHERE TaskLookup__c IN :pdaTask.keySet()];
        List<BSF_Task_Checklist__c> newChecklists = new List<BSF_Task_Checklist__c>();
        for(BSF_Task_Checklist__c tcl : checklists){
            tcl.Input_Checkbox__c  = true;
            tcl.Input_Long_Text_Area__c   = 'testQA';
            tcl.Picklist_Input_1__c  = 'Upgrade';
            tcl.Picklist_Input_2__c = 'Do Not Roll';
            tcl.Input_Short_Text_1__c = 'test1';
            tcl.Input_Short_Text_2__c = 'test2';
            tcl.Input_Number__c = 1;
            newChecklists.add(tcl);
        }
        update newChecklists;
        
        List<Task> updateTaskList = new List<Task>();
        for(Id taskId : pdaTask.keySet()){
            task t = new Task(Id = taskId, Status = 'Completed');
            updateTaskList.add(t);
        }
        update updateTaskList;
        
        Test.stopTest();
        
        Task pdaTaskPostUpdate = [SELECT Id, Status FROM Task WHERE id = :updateTaskList[0].Id LIMIT 1];
        
        Assert.areEqual('Completed', pdaTaskPostUpdate.Status);
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