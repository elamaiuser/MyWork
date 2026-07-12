@isTest
private class BSF_TaskPlanningWizardControllerTest {

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
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert templateOpp;

        insert new Task_Selected_Package__c(Opportunity__c = templateOpp.Id, Task_Package__c = taskPackage.Id);

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
                                                                    Configured_Offset__c = -5, // Negative for Post Drive check
                                                                    Task_Definition__c = taskDefs[0].Id,
                                                                    Scheduling_Method__c = 'Days Offset',
                                                                    Task_Package__c = taskPackage.Id);
        insert accConfig;
        
        Task_Planning_Default__c tempConfig = new Task_Planning_Default__c(Template_Opportunity__c = templateOpp.Id, 
                                                                        Configured_Date__c = date.today(),
                                                                        Configured_Offset__c = 50, 
                                                                        Task_Definition__c = taskDefs[0].Id,
                                                                        Scheduling_Method__c = 'Target Date',
                                                                        Task_Package__c = taskPackage.Id);
        insert tempConfig;

        List<Planned_Task__c> pts = new List<Planned_Task__c>();
        pts.add(new Planned_Task__c(Related_Opportunity__c = optyObj.Id, Subject__c = 'Test Initial Outreach', Status__c = 'Configured', Scheduling_Method__c = 'Days Offset', User_Defined_Offset__c = 5, Task_Definition__c = taskDefs[0].Id, Task_Package__c = taskPackage.Id));
        pts.add(new Planned_Task__c(Related_Opportunity__c = optyObj.Id, Subject__c = 'Test Initial Break', Status__c = 'Configured', Scheduling_Method__c = 'Target Date', Target_Date__c = Date.today(), Task_Definition__c = taskDefs[1].Id, Task_Package__c = taskPackage.Id));
        insert pts;
    }

    @isTest
    static void testGetTaskBundles_Account() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        BSF_TaskPlanningWizardController.InitData result = BSF_TaskPlanningWizardController.getTaskBundles(acc.Id);
        Test.stopTest();

        System.assertEquals('Account', result.objectApiName, 'Incorrect Object API Name returned.');
        System.assertEquals('Flexible', result.currentPath, 'Planning Path should be Flexible.');
        System.assertNotEquals(null, result.packages, 'Packages should be returned.');
        System.assert(!result.packages.isEmpty(), 'At least one package should exist.');
        
        Boolean hasSavedState = false;
        for (BSF_TaskPlanningWizardController.PackageGroupWrapper pkg : result.packages) {
            for (BSF_TaskPlanningWizardController.TaskItemWrapper task : pkg.tasks) {
                if (task.isChecked) {
                    hasSavedState = true;
                    if(task.userOffset == 5) { 
                        System.assertEquals(true, task.isPostDrive, 'Negative offsets should flag isPostDrive.');
                    }
                }
            }
        }
        System.assert(hasSavedState, 'Account configuration saved state was not mapped to wrappers.');
    }

    @isTest
    static void testGetTaskBundles_Drive() {
        Opportunity drive = [SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1];

        Test.startTest();
        BSF_TaskPlanningWizardController.InitData result = BSF_TaskPlanningWizardController.getTaskBundles(drive.Id);
        Test.stopTest();

        System.assertEquals('Opportunity', result.objectApiName);
        System.assertEquals('Draft', result.driveStatus);
    }

    @isTest
    static void testSaveTaskPlans_RevertToStandard() {
        Opportunity template = [SELECT Id, Planning_Path__c FROM Opportunity WHERE Is_Template__c = true LIMIT 1];
        System.assertEquals('Flexible', template.Planning_Path__c);

        Test.startTest();
        BSF_TaskPlanningWizardController.saveTaskPlans(template.Id, '[]', new List<String>(), 'Standard');
        Test.stopTest();

        Opportunity updatedTemplate = [SELECT Planning_Path__c FROM Opportunity WHERE Id = :template.Id];
        System.assertEquals('Standard', updatedTemplate.Planning_Path__c, 'Path should be updated to Standard.');

        List<Task_Planning_Default__c> stdConfigs = [SELECT Id, Scheduling_Method__c FROM Task_Planning_Default__c WHERE Template_Opportunity__c = :template.Id];
        System.assert(!stdConfigs.isEmpty(), 'Standard configurations should be re-inserted.');
    }

    @isTest
    static void testSaveTaskPlans_FlexibleAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Task_Definition__c def = [SELECT Id FROM Task_Definition__c LIMIT 1];
        Task_Package__c pkg = [SELECT Id FROM Task_Package__c LIMIT 1];

        List<BSF_TaskPlanningWizardController.SavePayload> payloadList = new List<BSF_TaskPlanningWizardController.SavePayload>();
        BSF_TaskPlanningWizardController.SavePayload sp = new BSF_TaskPlanningWizardController.SavePayload();
        sp.definitionId = def.Id;
        sp.schedulingMethod = 'Days Offset';
        sp.userOffset = 15;
        sp.packageId = pkg.Id;
        payloadList.add(sp);

        String jsonString = JSON.serialize(payloadList);
        List<String> packageIds = new List<String>{pkg.Id};

        Test.startTest();
        BSF_TaskPlanningWizardController.saveTaskPlans(acc.Id, jsonString, packageIds, 'Flexible');
        Test.stopTest();

        List<Task_Planning_Default__c> updatedConfigs = [SELECT Id, Configured_Offset__c FROM Task_Planning_Default__c WHERE Account__c = :acc.Id];
        System.assert(!updatedConfigs.isEmpty(), 'Account flexible config was not saved.');
        System.assertEquals(15, updatedConfigs[0].Configured_Offset__c, 'User defined offset was not saved correctly.');
    }

    @isTest
    static void testSaveTaskPlans_FlexibleDrive() {
        Opportunity drive = [SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        Task_Definition__c def = [SELECT Id FROM Task_Definition__c LIMIT 1];
        Task_Package__c pkg = [SELECT Id FROM Task_Package__c LIMIT 1];

        List<BSF_TaskPlanningWizardController.SavePayload> payloadList = new List<BSF_TaskPlanningWizardController.SavePayload>();
        
        BSF_TaskPlanningWizardController.SavePayload sp1 = new BSF_TaskPlanningWizardController.SavePayload();
        sp1.definitionId = def.Id;
        sp1.schedulingMethod = 'Target Date';
        sp1.userDate = String.valueOf(Date.today().addDays(5));
        sp1.packageId = pkg.Id;
        payloadList.add(sp1);

        String jsonString = JSON.serialize(payloadList);

        Test.startTest();
        BSF_TaskPlanningWizardController.saveTaskPlans(drive.Id, jsonString, new List<String>(), 'Flexible');
        Test.stopTest();

        List<Planned_Task__c> updatedQueue = [SELECT Id, Target_Date__c FROM Planned_Task__c WHERE Related_Opportunity__c = :drive.Id AND Status__c = 'Configured'];
        System.assert(!updatedQueue.isEmpty(), 'Planned Tasks were not saved to queue.');
        System.assertEquals(Date.today().addDays(5), updatedQueue[0].Target_Date__c, 'Target date mapping failed.');
    }

    @isTest
    static void testSaveTaskPlans_ConfirmedDriveValidation() {
        Opportunity drive = [SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        drive.Drive_Status__c = 'Confirmed';
        update drive;

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            BSF_TaskPlanningWizardController.saveTaskPlans(drive.Id, '[]', new List<String>(), 'Flexible');
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Confirmed drives should block task planning saves.');
    }

    @isTest
    static void testTaskItemWrapperCompareTo() {
        BSF_TaskPlanningWizardController.TaskItemWrapper t1 = new BSF_TaskPlanningWizardController.TaskItemWrapper();
        t1.defaultOffset = 10;
        t1.subject = 'A';

        BSF_TaskPlanningWizardController.TaskItemWrapper t2 = new BSF_TaskPlanningWizardController.TaskItemWrapper();
        t2.defaultOffset = 5;
        t2.subject = 'B';
        
        BSF_TaskPlanningWizardController.TaskItemWrapper t3 = new BSF_TaskPlanningWizardController.TaskItemWrapper();
        t3.defaultOffset = 10;
        t3.subject = 'Z';

        Test.startTest();
        System.assertEquals(-1, t1.compareTo(t2), 'T1 offset is larger, should sort higher (descending).');
        System.assertEquals(1, t2.compareTo(t1), 'T2 offset is smaller, should sort lower.');
        System.assertEquals(-25, t1.compareTo(t3), 'Offsets are equal, should sort alphabetically by Subject.');
        Test.stopTest();
    }

    @isTest
    static void testSaveTaskPlans_TemplateNoPathChange() {
        Opportunity template = [SELECT Id, Planning_Path__c FROM Opportunity WHERE Is_Template__c = true LIMIT 1];
        Task_Definition__c def = [SELECT Id FROM Task_Definition__c LIMIT 1];
        Task_Package__c pkg = [SELECT Id FROM Task_Package__c LIMIT 1];

        List<BSF_TaskPlanningWizardController.SavePayload> payloadList = new List<BSF_TaskPlanningWizardController.SavePayload>();
        BSF_TaskPlanningWizardController.SavePayload sp = new BSF_TaskPlanningWizardController.SavePayload();
        sp.definitionId = def.Id;
        sp.schedulingMethod = 'Days Offset';
        sp.userOffset = 10;
        sp.packageId = pkg.Id;
        payloadList.add(sp);

        String jsonString = JSON.serialize(payloadList);
        List<String> packageIds = new List<String>{pkg.Id};

        Test.startTest();
        BSF_TaskPlanningWizardController.saveTaskPlans(template.Id, jsonString, packageIds, 'Flexible');
        Test.stopTest();

        List<Task_Planning_Default__c> updatedConfigs = [SELECT Id FROM Task_Planning_Default__c WHERE Template_Opportunity__c = :template.Id];
        System.assert(!updatedConfigs.isEmpty(), 'Template flexible config should be saved.');
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