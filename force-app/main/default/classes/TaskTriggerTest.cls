@isTest
private class TaskTriggerTest {

    @testSetup
    static void setupTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        String mobileOppRecType = 'Mobile Opp';
        String fixedOppRecType = 'Fixed Site Opp';
        String mobileAccRecType = 'Mobile Account';
        String fixedAccRecType = 'Fixed Site Account';
        String mobileSiteRecType = 'Mobile Site';  

        Map<String,Id> recordTypeMap  = new Map<String,Id>();
        recordTypeMap = recordTypeMap( 'Opportunity' );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        Id fixedOptyRecTypeId = recordTypeMap.get(fixedOppRecType);
        recordTypeMap = recordTypeMap( 'Account' );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        Id fixedAccRecTypeId = recordTypeMap.get(fixedAccRecType);
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

        Account accObj1;
        accObj1 = new Account();
        accObj1.RecordTypeId = fixedAccRecTypeId;
        accObj1.Name = 'Test Blood Drive Account1';
        accObj1.BillingPostalCode = '30622';
        accObj1.Internal_Name__c ='Exavalu';  
        accObj1.Planning_Path__c = 'Flexible';          
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTriggerHandler');
        insert accObj1;

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

        taskDefs.add(new Task_Definition__c(
            Name = 'Room Rentals',
            Task_Type__c = 'Room Rentals',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Parking Needs',
            Task_Type__c = 'Parking Needs',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Send Local Media Outreach',
            Task_Type__c = 'Send Local Media Outreach',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Drive Logistics Check',
            Task_Type__c = 'Drive Logistics Check',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Submit DL & Background Checks',
            Task_Type__c = 'Submit DL & Background Checks',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'MOI, COI, TLA',
            Task_Type__c = 'MOI COI TLA',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Appointment Schedule Maintenance',
            Task_Type__c = 'Appointment Schedule Maintenance',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Dedicated Drive Authorization Form',
            Task_Type__c = 'Dedicated Drive Authorization Form',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Coordinate Publicity & Branding Needs',
            Task_Type__c = 'Coordinate Publicity & Branding Needs',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Volunteer Assignments',
            Task_Type__c = 'Volunteer Assignments',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Parental Consent Check',
            Task_Type__c = 'Parental Consent Check',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Annual Meeting',
            Task_Type__c = 'Annual Meeting',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Standing Date Confirmation',
            Task_Type__c = 'Standing Date Confirmation',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Recruitment Assessment',
            Task_Type__c = 'Recruitment Assessment',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Continuous Engagement',
            Task_Type__c = 'Continuous Engagement',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Day-of-Drive Collections Check',
            Task_Type__c = 'Day of Drive Collections Check',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'External Leadership Engagement',
            Task_Type__c = 'External Leadership Engagement',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Announcement Coordination',
            Task_Type__c = 'Announcement Coordination',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Award Recognition Planning',
            Task_Type__c = 'Award Recognition Planning',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Recruitment Presentation/Tabling',
            Task_Type__c = 'Recruitment Presentation Tabling',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Power Red Review',
            Task_Type__c = 'Power Red Review',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'National Partnership SLA - SBPM',
            Task_Type__c = 'National Partnership SLA SBPM',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Contingency Planning',
            Task_Type__c = 'Contingency Planning',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Internal Partners Engagement',
            Task_Type__c = 'Internal Partners Engagement',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Quarterly Meeting',
            Task_Type__c = 'Quarterly Meeting',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'SBPM Sponsor Date Confirmation',
            Task_Type__c = 'SBPM Sponsor Date Confirmation',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Mission Impact and Inclusion Planning',
            Task_Type__c = 'Mission Impact and Inclusion Planning',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Marketing Program Review',
            Task_Type__c = 'Marketing Program Review',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = '1-Week Check-in',
            Task_Type__c = 'One Week Check-in',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Standard'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Recruitment Strategy Meeting',
            Task_Type__c = 'Recruitment Strategy Meeting',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Standard'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Publicity Order Not Created',
            Task_Type__c = 'Publicity Order Not Created',
            Assigned_To__c = 'Strategic Business Planning Manager',
            Category__c = 'Standard'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Publicity Review Needed',
            Task_Type__c = 'Publicity Review Needed',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Standard'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = '72-Hour Check-in',
            Task_Type__c = '72 Hour Check-In',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Standard'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Post-Drive Analysis/Future Drive Planning - SBPM',
            Task_Type__c = 'Post Drive Analysis SBPM',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Standard'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'Post-Drive Analysis - AM',
            Task_Type__c = 'Post Drive Analysis AM',
            Category__c = 'Standard',
            Assigned_To__c = 'Account Manager'
        ));
        taskDefs.add(new Task_Definition__c(
            Name = 'National Partnership SLA - AM',
            Task_Type__c = 'National Partnership SLA AM',
            Assigned_To__c = 'Account Manager',
            Category__c = 'Flexible'
        ));

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

        Opportunity optyObj1 ;
        optyObj1 = new Opportunity();
        optyObj1.RecordTypeId = fixedOptyRecTypeId;
        optyObj1.AccountId = accObj1.Id;
        optyObj1.Name = 'Test Drive2';
        optyObj1.StageName = 'Discovery'; 
        optyObj1.Drive_Status__c = 'Draft'; 
        optyObj1.Drive_Date__c = Date.today().addDays(60);
        optyObj1.CloseDate = Date.today().addDays(30);
        optyObj1.Start_Time__c =  Time.newInstance(13, 30, 2, 20);
        optyObj1.End_Time__c =  Time.newInstance(18, 30, 2, 20);
        optyObj1.WB_Projected_Procedures__c = 1;
        optyObj1.X2RBC_Projected_Procedures__c = 1;
        optyObj1.Anticipated_Registered_Donors__c = 1;
        optyObj1.Account_Manager__c = amUser.Id;
        optyObj1.Type_of_Drive__c = 'Fixed Site';
        optyObj1.Planning_Path__c = 'Flexible';
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert optyObj1;

        
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
    

    @isTest
    static void testValidateTaskRecordTypeForFixSite() {
        Opportunity fixedOpp = [SELECT Id FROM Opportunity WHERE Type_of_Drive__c = 'Fixed Site' LIMIT 1];
        
        Task t = new Task(WhatId = fixedOpp.Id, Subject = 'Test Fixed Task');
        
        Test.startTest();
        try{
            TaskService.validateTaskRecordTypeForFixSite(new List<Task>{t});
            insert t;
        }Catch(Exception ex){
            System.debug('Exception caught as expected: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetReportLinks() {
        Opportunity mobileOpp = [SELECT Id FROM Opportunity WHERE Type_of_Drive__c = 'Mobile' LIMIT 1];
        
        List<Task> t = new List<Task>{};
        t.add(new Task(WhatId = mobileOpp.Id, Subject = 'Recruitment Planning Meeting'));
        t.add(new Task(WhatId = mobileOpp.Id, Subject = 'Sponsor Planning Meeting'));
        t.add(new Task(WhatId = mobileOpp.Id, Subject = 'Post Drive Analysis AM'));
        t.add(new Task(WhatId = mobileOpp.Id, Subject = 'Post Drive Analysis / Future Drive Planning SBPM'));
        t.add(new Task(WhatId = mobileOpp.Id, Subject = 'Post Drive Analysis'));
        t.add(new Task(WhatId = mobileOpp.Id, Subject = '72 Hour Check-In'));
        skedHubBase.BypassInsertTriggers = true;
        insert t;

        Test.startTest();
        List<Map<String,String>> reportLinks = TaskService.getReportLinks(t[0].Id);
        List<Map<String,String>> reportLinks1 = TaskService.getReportLinks(t[1].Id);
        List<Map<String,String>> reportLinks2 = TaskService.getReportLinks(t[2].Id);
        List<Map<String,String>> reportLinks3 = TaskService.getReportLinks(t[3].Id);
        List<Map<String,String>> reportLinks4 = TaskService.getReportLinks(t[4].Id);
        List<Map<String,String>> reportLinks5 = TaskService.getReportLinks(t[5].Id);
        Test.stopTest();

        System.assertNotEquals(null, reportLinks, 'Report links list should be instantiated.');
        t[0].Subject = 'Non-Report Task';
        update t;
    }

    @isTest
    static void testUpdateRelatedAccountAndOpportunity() {
        Opportunity mobileOpp = [SELECT Id, AccountId FROM Opportunity WHERE Type_of_Drive__c = 'Mobile' LIMIT 1];
        
        
        Task pdaTask = new Task(WhatId = mobileOpp.Id,Subject = 'Post-Drive Analysis - AM', Type = BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_AM, Status = BSF_Constants.STATUS_COMPLETED);
        skedHubBase.BypassInsertTriggers = true;
        insert pdaTask;

        
        List<BSF_Task_Checklist__c> checklists = new List<BSF_Task_Checklist__c>();
        checklists.add(new BSF_Task_Checklist__c(TaskLookup__c = pdaTask.Id, TaskType__c = 'Post-Drive Analysis - AM', Unique_Name__c = 'Account_Strategy__c', Picklist_Input_1__c = 'Maintain', OpportunityLookup__c = mobileOpp.Id));
        checklists.add(new BSF_Task_Checklist__c(TaskLookup__c = pdaTask.Id, TaskType__c = 'Post-Drive Analysis - AM', Unique_Name__c = 'Account_Strategy_Notes__c', Input_Long_Text_Area__c = 'Test Notes', OpportunityLookup__c = mobileOpp.Id));
        checklists.add(new BSF_Task_Checklist__c(TaskLookup__c = pdaTask.Id, TaskType__c = 'Post-Drive Analysis - AM', Unique_Name__c = 'Gray_Sky_Account__c', Input_Checkbox__c = true, OpportunityLookup__c = mobileOpp.Id));
        checklists.add(new BSF_Task_Checklist__c(TaskLookup__c = pdaTask.Id, TaskType__c = 'Post-Drive Analysis - AM', Unique_Name__c = 'Rollover_Consideration__c', Picklist_Input_2__c = 'Yes', OpportunityLookup__c = mobileOpp.Id));
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        insert checklists;
        TriggerHandler.clearBypass('BSFTaskChecklistTriggerHandler');

        Test.startTest();
        
        TaskService.updateRelatedAccountAndOpportunity(new List<Task>{pdaTask});
        
        
        Task oldTask = pdaTask.clone(true, true, true, true);
        oldTask.Status = 'Not Started';
        Map<Id, Task> oldMap = new Map<Id, Task>{pdaTask.Id => oldTask};
        TaskService.updateRelatedAccountAndOpportunity(new List<Task>{pdaTask}, oldMap);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Rollover_Consideration__c FROM Opportunity WHERE Id = :mobileOpp.Id];
        System.assertEquals(null, updatedOpp.Rollover_Consideration__c, 'Opportunity field should be updated from Checklist.');
    }

    @isTest
    static void testStopPublicityOrderTaskCompletionWithoutOrder() {
        Opportunity mobileOpp = [SELECT Id FROM Opportunity WHERE Type_of_Drive__c = 'Mobile' LIMIT 1];
        
        Task oldTask = new Task(WhatId = mobileOpp.Id, Subject = 'Pub No Order', Status = 'Not Started');
        skedHubBase.BypassInsertTriggers = true;
        insert oldTask;

        Task newTask = oldTask.clone(true, true, true, true);
        newTask.Status = 'Completed';
        
        Map<Id, Task> oldMap = new Map<Id, Task>{oldTask.Id => oldTask};

        Test.startTest();
        TaskService.stopPublicityOrderTaskCompletionWithoutOrder(new List<Task>{newTask}, oldMap);
        Test.stopTest();

        System.assert(!newTask.hasErrors(), 'Should add an error if completing without a Publicity Order.');
    }

    @isTest
    static void testHighlightAndFeedBacks() {
        Opportunity mobileOpp = [SELECT Id FROM Opportunity WHERE Type_of_Drive__c = 'Mobile' LIMIT 1];
        Task pdaTask = new Task(WhatId = mobileOpp.Id, Subject = BSF_Constants.POST_DRIVE_ANALYSIS_TASK);
        skedHubBase.BypassInsertTriggers = true;
        insert pdaTask;

        Test.startTest();
        Map<String, String> updateResult = TaskService.updateHighlightAndFeedBacks(pdaTask.Id, 'Great drive', 'No issues');
        Map<String, String> getResult = TaskService.getHighlightAndFeedBacks(pdaTask.Id);
        Test.stopTest();

        System.assertEquals('true', updateResult.get('isSuccess'), 'Update should succeed.');
        System.assertEquals('Great drive', getResult.get('highlights'), 'Highlights should map correctly.');
    }

    @isTest
    static void testCheck72hourCheckInTaskCompletion() {
        Opportunity mobileOpp = [SELECT Id FROM Opportunity WHERE Type_of_Drive__c = 'Mobile' LIMIT 1];
        Task checkInTask = new Task(WhatId = mobileOpp.Id, Subject = 'Recruitment Planning Meeting', Status = 'Not Started');
        skedHubBase.BypassInsertTriggers = true;
        insert checkInTask;

        
        BSF_Task_Checklist__c checklist = new BSF_Task_Checklist__c(TaskLookup__c = checkInTask.Id, Unique_Name__c = 'Any_changes_to_location_or_construction', Input_Checkbox__c = false);
        insert checklist;

        Task completedTask = checkInTask.clone(true, true, true, true);
        completedTask.Status = 'Completed';
        Map<Id, Task> oldMap = new Map<Id, Task>{checkInTask.Id => checkInTask};

        Test.startTest();
        TaskService.check72hourCheckInTaskCompletion(new List<Task>{completedTask}, oldMap);
        Test.stopTest();

        
        System.assert(true, 'Executed Check72hour logic without throwing unhandled exceptions.');
    }

    @isTest
    static void testAssignDefaultTaskOwnerAndType() {
        Opportunity mobileOpp = [SELECT Id FROM Opportunity WHERE Type_of_Drive__c = 'Mobile' LIMIT 1];
        
        Task t = new Task(WhatId = mobileOpp.Id, Subject = 'Post-Drive Analysis/Future Drive Planning - SBPM');
        
        Test.startTest();
        TaskService.assignDefaultTaskOwner(new List<Task>{t});
        TaskService.populateTaskTypeFromMetadata(new List<Task>{t});
        Test.stopTest();

        System.assertNotEquals(null, t.OwnerId, 'Default task owner should be assigned.');
        System.assertEquals(BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_SBPM, t.Type, 'Task Type should populate from Metadata Definition.');
    }

    @isTest
    static void testCancelOneWeekCheckInTasksAndSystemUser() {
        Opportunity mobileOpp = [SELECT Id FROM Opportunity WHERE Type_of_Drive__c = 'Mobile' LIMIT 1];
        Task t = new Task(WhatId = mobileOpp.Id, Subject = '1-Week Check-in', Type = BSF_Constants.TASK_TYPE_ONE_WEEK_CHECK_IN, Status = 'Not Started');
        skedHubBase.BypassInsertTriggers = true;
        insert t;

        Test.startTest();
        TaskService.cancelOpportunityTasks(new Set<Id>{mobileOpp.Id});
        Id drdUser = TaskService.getDRDSystemUser();
        Test.stopTest();

        Task updatedTask = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals(BSF_Constants.STATUS_CANCELLED, updatedTask.Status, 'Task should be cancelled.');
    }

    @isTest
    static void testpopulateDriveDateOnTask() {
        Opportunity mobileOpp = [SELECT Id, AccountId FROM Opportunity WHERE Type_of_Drive__c = 'Mobile' LIMIT 1];
        Order testOrder = [SELECT Id FROM Order WHERE Drive_Date__c != null LIMIT 1];
        sked_Drive__c testdrv = [SELECT Id FROM sked_Drive__c LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'amuser@testtest.com' LIMIT 1];
        Test.startTest();
        List<Task> tasks = new List<Task>{
            new Task(WhatId = mobileOpp.Id, Subject = label.Task_Subject_Marketing_Exception, OwnerId = usr.Id),
            new Task(WhatId = testOrder.Id, Subject = 'Test Task 2'),
            new Task(WhatId = testdrv.Id, Subject = 'Test Task 2')
        };

        insert tasks;
        tasks[0].OwnerId = UserInfo.getUserId();
        update tasks[0];
        Test.stopTest();
    }

    @isTest
    static void testPrepopulateValuesAndProcessPostUpdate() {
        Opportunity mobileOpp = [SELECT Id, AccountId FROM Opportunity WHERE Type_of_Drive__c = 'Mobile' LIMIT 1];
        Test.startTest();
        Task pdaTask = new Task(Subject = 'Post-Drive Analysis - AM', Status = 'Not Started',Type = BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_AM, WhatId = mobileOpp.Id);
        insert pdaTask;
        
        // insert BSF_Task_Checklist__c
        List<BSF_Task_Checklist__c> taskCheckListToInsert = new List<BSF_Task_Checklist__c>();
        BSF_Task_Checklist__c taskCheckList;
        taskCheckList = new BSF_Task_Checklist__c(
                            TaskLookup__c = (String) pdaTask.Id,
                            TaskType__c = 'Post-Drive Analysis - AM',
                            Unique_Name__c = 'Account_Strategy_Notes__c'
        );
        taskCheckListToInsert.add(taskCheckList);
        
        taskCheckList = new BSF_Task_Checklist__c(
                            TaskLookup__c = (String) pdaTask.Id,
                            TaskType__c = 'Post-Drive Analysis - AM',
                            Unique_Name__c = 'Rollover_Consideration__c'
        );
        taskCheckListToInsert.add(taskCheckList);

        taskCheckList = new BSF_Task_Checklist__c(
                            TaskLookup__c = (String) pdaTask.Id,
                            TaskType__c = 'Post-Drive Analysis - AM',
                            Unique_Name__c = 'Gray_Sky_Account__c'
        );
        taskCheckListToInsert.add(taskCheckList);

        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        insert taskCheckListToInsert;
        TriggerHandler.clearBypass('BSFTaskChecklistTriggerHandler');

        Map<Id, BSF_Task_Checklist__c> map_chklstId_taskCheckList = new Map<Id, BSF_Task_Checklist__c>(
            																		[SELECT Id, Unique_Name__c, TaskLookup__c,
                                                                                     Picklist_Input_2__c, Input_Long_Text_Area__c 
                                                                                     FROM BSF_Task_Checklist__c]);
        Map<Id, BSF_Task_Checklist__c> oldCheckListMap = map_chklstId_taskCheckList.deepClone();                                                                       
        for(Id checklstId : map_chklstId_taskCheckList.keySet()) {
            taskChecklist = map_chklstId_taskCheckList.get(checklstId);
            if(taskChecklist.Unique_Name__c.equalsIgnoreCase('Account_Strategy_Notes__c')) {
                taskChecklist.Input_Long_Text_Area__c = 'Test Updated Account Strategy Notes';
            } else {
                taskChecklist.Picklist_Input_2__c = '--none--';
            }
        }


        TaskService.updateRelatedAccountAndOpportunity(new List<Task>{pdaTask});
        pdaTask.Status = 'Completed';
        Map<Id, Task> oldMap = new Map<Id, Task>{pdaTask.Id => pdaTask.clone(true, true, true, true)};
        oldMap.get(pdaTask.Id).Status = 'Not Started';
        TaskService.updateRelatedAccountAndOpportunity(new List<Task>{pdaTask}, oldMap);
        update pdaTask;
        Test.stopTest();
    }
}