/* Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 01/17/2024				  Priti Jana				Fixed the test class, used new ASSERT class and increased code coverage
 * 11/06/2024				  Priti Jana				Added new test method for HRP-9815
 *************************************************************************************************************************************************
*/

@isTest
private class DriveTriggerServiceTest
{
    static String id_site = '';
    static String id_site1 = '';
    static String Id_opp = '';
    static String Id2_opp = '';
    static String Id_CollectionOperation = '';
    static String id_acc = '';
    static String id2_acc = '';
    
    private static void prepareDataset()
    {
        String rolename = 'West_BDM';
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
        
        User AdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'adminuser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        
        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
            LastName = 'last',
            Email = 'DRDProfile000@amamama.com',
            Username = 'drduser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
       
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        System.runAs( AdminUser ){
            List<Account> mobileAccList = new List<Account>();            
            Account accObj;            
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu';
            accObj.BillingPostalCode = '30622';
		    accObj.Internal_Name__c ='Exavalu';
            mobileAccList.add(accobj); 
            
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu2';
            accObj.Internal_Name__c ='Exavalu2';
            accObj.BillingPostalCode = '30623';            
            mobileAccList.add(accobj); 
            
            // Military Account
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu3';
            accObj.Internal_Name__c ='Exavalu3';
            accObj.BillingPostalCode = '30624';  
            accObj.Type = 'Military';
            mobileAccList.add(accobj); 
            
            
            TriggerHandler.bypass('AccountTriggerHandler');
            insert mobileAccList;
            
            id_acc = mobileAccList[0].Id;
            id2_acc = mobileAccList[2].Id;
            
            List<AccountTeammember> atmList = new List<AccountTeammember>();
            AccountTeammember atm;
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = DRDAMUser.Id ;
            atm.AccountId = mobileAccList[0].Id ;
            atm.TeamMemberRole = 'Account Specialist';
            atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = AdminUser.Id ;
            atm.AccountId = mobileAccList[0].Id ;
            atm.TeamMemberRole = 'Recruiter';
            atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = AdminUser.Id ;
            atm.AccountId = mobileAccList[1].Id ;
            atm.TeamMemberRole = 'Recruiter';
            atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            
            insert atmList;
                        
            Contact conObj = new Contact();
            conObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
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
            TriggerHandler.bypass('ContactTriggerHandler');
            insert conObj;
            
            sked__Tag__c skedTag = new sked__Tag__c();
            skedTag.Name = 'Outside';
            skedTag.sked__Type__c = 'Physical Location Type'; 
            
            insert skedTag; 
            
            
            sked__Location__c siteObj = new sked__Location__c();
            siteObj.RecordTypeId =  Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId();
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
            siteObj.sked_Site_Inspection_Completed_By__c = [SELECT Id FROM USER WHERE Email = 'DRDProfile000@amamama.com' ].Id;
            siteObj.sked_Automation_Suitability__c = 'Suitable';
            siteObj.sked_Outside_stairs__c = 1;
            siteObj.sked_Inside_stairs__c = 2;
            siteObj.sked_Base_Description__c = 'test base description';
            siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
            siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Site_Contact__c = [SELECT Id FROM Contact WHERE FirstName = 'Test' AND LastName = 'Contact' ].Id;
            siteObj.sked_Site_Main_Phone__c = '758-771-0091';
            siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
            siteObj.sked_Pay_for_Parking__c = 'Other';
            siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
            siteObj.sked_Wireless_Policy__c = 'Accepted';
            siteObj.Source__c = 'Custom New Form';
            siteObj.Operation_type__c = 'Integrated';
            siteObj.sked_Date_Site_Inspection_Completed__c=system.today();
            insert siteObj;
            id_site = siteObj.Id;
            
            sked__Location__c siteObj1 = new sked__Location__c();
            siteObj1.RecordTypeId =  Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId();
            siteObj1.Name = 'Test Site';
            siteObj1.sked_Address_1__c = 'Test Site Address';
            siteObj1.sked__Address__c = 'Test Site Address';
            siteObj1.sked_City__c = 'Test Site City';
            siteObj1.sked_State__c = 'Test Site State';
            siteObj1.sked_Zip_Code__c = '4000';
            siteObj1.sked_County__c = 'USA';
            siteObj1.sked_Site_Building_Name__c = 'Test Site Building';
            siteObj1.sked_Floor_Description__c = 'Test Site Floor Description';
            siteObj1.sked_Room_Name__c = 'Room 15';
            siteObj1.sked_National_Name__c = 'AMERICA';
            siteObj1.sked_Physical_Location_Type__c = 'Outside';
            siteObj1.sked_Site_Inspection_Completed_By__c = [SELECT Id FROM USER WHERE Email = 'DRDProfile000@amamama.com' ].Id;
            siteObj1.sked_Automation_Suitability__c = 'Suitable';
            siteObj1.sked_Outside_stairs__c = 1;
            siteObj1.sked_Inside_stairs__c = 2;
            siteObj1.sked_Base_Description__c = 'test base description';
            siteObj1.sked_Travel_Time_to_Staging_Location__c = 45;
            siteObj1.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
            siteObj1.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
            siteObj1.sked_Site_Contact__c = [SELECT Id FROM Contact WHERE FirstName = 'Test' AND LastName = 'Contact' ].Id;
            siteObj1.sked_Site_Main_Phone__c = '758-771-0091';
            siteObj1.sked_Directions_From_CollectionOperation__c = 'Test Direction';
            siteObj1.sked_Pay_for_Parking__c = 'Other';
            siteObj1.sked_Pay_for_Parking_Details__c = 'Test Pay';
            siteObj1.sked_Wireless_Policy__c = 'Accepted';
            siteObj1.Source__c = 'Custom New Form';
            //siteObj1.Operation_type__c = 'Integrated';
            siteObj1.sked_Date_Site_Inspection_Completed__c=system.today();
            insert siteObj1;
            id_site1 = siteObj1.Id;
            
            List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
            
            BSF_Portfolio__c Portland_OR_AM_01 = new BSF_Portfolio__c();			
            Portland_OR_AM_01.Name='Portland OR AM 01';
            Portland_OR_AM_01.Account_Based_Portfolio__c= true;			
            Portland_OR_AM_01.External_Key__c='Account_BD36_21E_NW_Portland OR_Portland OR ABM 01 03 07 08_Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Code__c='Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Name__c='Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Type__c='Account Manager';
            Portland_OR_AM_01.Taxonomy_Type__c='Bio Account Portfolio';
            Portland_OR_AM_01.Territory_Portfolio__c=false;			
            bsfPortf.add(Portland_OR_AM_01);
            
            BSF_Portfolio__c Greater_Alleghenies_DRA_01 = new BSF_Portfolio__c();
            Greater_Alleghenies_DRA_01.Name='Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Account_Based_Portfolio__c = true;
            Greater_Alleghenies_DRA_01.External_Key__c='Booking Support_BD32_27E_Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Portfolio_Code__c='Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Portfolio_Name__c='Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Portfolio_Type__c='Booking Support';
            Greater_Alleghenies_DRA_01.Taxonomy_Type__c='Bio Booking Support';
            Greater_Alleghenies_DRA_01.Territory_Portfolio__c= false;
            bsfPortf.add(Greater_Alleghenies_DRA_01);
            
            BSF_Portfolio__c American_Red_Cross = new BSF_Portfolio__c();
            American_Red_Cross.Name='American Red Cross';
            American_Red_Cross.Account_Based_Portfolio__c=true;
            American_Red_Cross.External_Key__c='National Account_1';
            American_Red_Cross.Portfolio_Code__c='1';
            American_Red_Cross.Portfolio_Name__c='American Red Cross';
            American_Red_Cross.Portfolio_Type__c='National Account Manager';
            American_Red_Cross.Taxonomy_Type__c='National Account Manager Portfolio';
            American_Red_Cross.Territory_Portfolio__c=false;
            bsfPortf.add(American_Red_Cross);
            
            BSF_Portfolio__c Sickle_Cell_AM_04 = new BSF_Portfolio__c();
            Sickle_Cell_AM_04.Name='Sickle Cell AM 04';
            Sickle_Cell_AM_04.Account_Based_Portfolio__c=true;
            Sickle_Cell_AM_04.External_Key__c='Sickle Cell_53E_SAM04';
            Sickle_Cell_AM_04.Portfolio_Code__c='SAM04';
            Sickle_Cell_AM_04.Portfolio_Name__c='Sickle Cell AM 04';
            Sickle_Cell_AM_04.Portfolio_Type__c='District Manager';
            Sickle_Cell_AM_04.Taxonomy_Type__c='Bio Sickle Cell Portfolio';
            Sickle_Cell_AM_04.Territory_Portfolio__c=false;
            bsfPortf.add(Sickle_Cell_AM_04);
            
            insert bsfPortf;
            
            List<Portfolio_Assignment__c> portfAssignList = new List<Portfolio_Assignment__c>();
            
            Portfolio_Assignment__c assign1 = new Portfolio_Assignment__c();
            assign1.Assignment_Type__c = 'District Manager';
            assign1.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
            assign1.End_Date__c = Date.Today().addDays(10);
            assign1.Start_Date__c = Date.Today().addDays(-10);
            assign1.User__c = DRDAMUser.Id;
            portfAssignList.add(assign1);
            
            Portfolio_Assignment__c assign2 = new Portfolio_Assignment__c();
            assign2.Assignment_Type__c = 'District Manager';
            assign2.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
            assign2.End_Date__c = Date.Today().addDays(10);
            assign2.Start_Date__c = Date.Today().addDays(-10);
            assign2.User__c = DRDAMUser.Id;
            portfAssignList.add(assign2);
            
            insert portfAssignList;
            
            List<Opportunity> oppsobjlist = new List<Opportunity>();
            Opportunity optyObj ; // = new Opportunity();
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
            optyObj.Drive_Site__c = siteObj.Id;
            optyObj.Name = 'Test Drive';
            optyObj.StageName = 'Discovery'; 
            //optyObj.Drive_Status__c = 'Draft'; 
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c =  Time.newInstance(13, 30, 2, 20);
            optyObj.End_Time__c =  Time.newInstance(18, 30, 2, 20);
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            
            oppsobjlist.add( optyObj );
            
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu3'].Id;
            optyObj.Drive_Site__c = id_site;
            optyObj.Name = 'Test Drive2';
            optyObj.StageName = 'Discovery';
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c = Time.newInstance(13, 30, 2, 20);
            optyObj.End_Time__c = Time.newInstance(18, 30, 2, 20);
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            
            oppsobjlist.add( optyObj );
            
            /*optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu3'].Id;
            optyObj.Drive_Site__c = siteObj.Id;
            optyObj.Name = 'Test Drive3';
            optyObj.StageName = 'Discovery';
            optyObj.Drive_Status__c = 'Draft'; 
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c = Time.newInstance(13, 30, 2, 20);
            optyObj.End_Time__c = Time.newInstance(18, 30, 2, 20);
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            
            oppsobjlist.add( optyObj);*/
            
            insert oppsobjlist;
            Id_opp = oppsobjlist[0].Id;
            Id2_opp = oppsobjlist[1].Id;
            
            // Opportunity contact Role
            List<OpportunityContactRole> oppConRoleList = new List<OpportunityContactRole>();
            OpportunityContactRole oppConRole1 = new OpportunityContactRole();
            oppConRole1.OpportunityId = Id_opp;
            oppConRole1.ContactId = conObj.Id;
            oppConRole1.Role = 'Whom to Meet';
           
            oppConRoleList.add(oppConRole1);
            
            OpportunityContactRole oppConRole2 = new OpportunityContactRole();
            oppConRole2.OpportunityId = Id_opp;
            oppConRole2.ContactId = conObj.Id;
            oppConRole2.Role = 'Primary Contact';
            oppConRoleList.add(oppConRole2);
            
            OpportunityContactRole oppConRole3 = new OpportunityContactRole();
            oppConRole3.OpportunityId = Id2_opp;
            oppConRole3.ContactId = conObj.Id;
            oppConRole3.Role = 'Primary Contact';
            oppConRoleList.add(oppConRole3);
            
             TriggerHandler.bypass('OpportunityContactRoleTriggerHandler');
             insert oppConRoleList;
            

            Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                        sked_Hold_Threshold__c = 100,
                                                                                                        Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                        Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                        sked_Work_Week_First_Day__c = 'Sunday');
            insert testCollectionOperation1;
            Id_CollectionOperation = testCollectionOperation1.Id;
        }        
        
    }
    @isTest
    static void testmethod1()
    {        
        Test.startTest();
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        prepareDataset();
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = id_site,
                                                        sked_Opportunity__c = Id_opp,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = id_acc,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_2RBC_Projected_Procedures__c = 20,
                                                     	sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED);
            insert testDrive1;
        Test.stopTest();
    }
    
    @isTest
    static void testmethod2()
    {
        String id_Drive = '';
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        prepareDataset();
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = id_site,
                                                        sked_Opportunity__c = Id_opp,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = id_acc,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_2RBC_Projected_Procedures__c = 20,
                                                     	sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE);
        insert testDrive1;
        id_Drive = testDrive1.Id;
        Test.startTest();
        sked_Drive__c testDrive2 = new sked_Drive__c(Id = id_Drive,
                                                        Name = 'Test Drive',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = id_site,
                                                        sked_Opportunity__c = Id_opp,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = id_acc,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_2RBC_Projected_Procedures__c = 20,
                                                     	sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED);
         
         update testDrive2;
        TriggerHandler.clearAllBypasses();
        TriggerHandler.clearBypass('AccountTriggerHandler');
        Test.stopTest();
    }
    
   // Below testMethods were added to increase code coverage - Priti --> 1/17/2024
   
    static testmethod void testReturnStatements()
    {
        Test.startTest();
        DriveTriggerService.populateDriveWorksheetData(null);
        DriveTriggerService.populateAMAndDM(null);
        Test.stopTest();
    }
    
   	static testMethod void testCheckMilitaryAuthSetting()
    {        
        String id_Drive = '';
        Test.startTest();
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        prepareDataset();
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive1',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = id_site,
                                                        sked_Opportunity__c = Id_opp,
                                                        sked_Type_of_Drive__c = 'Mobile',
                                                        sked_Account__c = id2_acc,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 20,
                                                        sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = 'Draft');

        insert testDrive1;
        
        try{
            testDrive1.sked_Status__c = 'Tentative';
            update testDrive1;
        }catch(Exception ex)
        {
            Assert.isTrue(ex.getMessage().contains(Custom_Messages__mdt.getInstance('Military_Auth_Setting').value__c));
        }
        Test.stopTest();        
        
    }
    
    @isTest
    static void testDriveDeletionOnlyByAdmins()
    {
        String id_Drive = '';
        Test.startTest();
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        prepareDataset();
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive1',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = id_site,
                                                        sked_Opportunity__c = Id_opp,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = id_acc,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 20,
                                                        sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE);
		List<sked_Drive__c> driveList = new  List<sked_Drive__c>();
        driveList.add(testDrive1);
        insert driveList;
        
        try{
          Delete driveList;  
        } Catch(Exception ex)
        {
           Assert.isTrue(ex.getMessage().contains(System.Label.CannotDeleteRecordExceptSystemAdmin)); //NEW ASSERT Class 
        }
        Test.stopTest();
        
        TriggerHandler.clearAllBypasses();
    }
    
    static testMethod void testValidateOpportunityMethod1()
    {
        Test.startTest();
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        prepareDataset();
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive1',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = id_site,
                                                        sked_Opportunity__c = Id_opp,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = id_acc,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 20,
                                                        sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT);
        insert testDrive1;
        testDrive1.sked_Opportunity__c = id2_opp;
        try{
            update testDrive1;
        }catch(Exception ex){
            Assert.isTrue(ex.getMessage().contains('BDO can not be changed/removed.'));
        }
           
        Test.stopTest();
    }
    
    static testMethod void testValidateOpportunityMethod2()
    {
        Test.startTest();
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        prepareDataset();
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive1',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = id_site,
                                                        sked_Opportunity__c = Id_opp,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = id_acc,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 20,
                                                        sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT);
        insert testDrive1;
        
        sked_Drive__c testDrive2 = new sked_Drive__c(Name = 'Test Drive2',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = id_site,
                                                        sked_Opportunity__c = Id_opp,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = id_acc,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 20,
                                                        sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT);
        
        try{
            insert testDrive2;
        }catch(Exception ex){
            Assert.isTrue(ex.getMessage().contains('DOC has been generated for this BDO.'));
        }
           
        Test.stopTest();
    }
    
    static testMethod void testCheckAccept56DaysVoilationMethod()
    {
        Test.startTest();
        
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId =  testMobileAccount.Id;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
         // insert Mobile Opp 1
        Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(55),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp1;
        
        // insert Mobile Opp 2
        Opportunity testMobileOpp2 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp2;
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive2',
                                                        
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = testMobileSite.Id,
                                                        sked_Opportunity__c = testMobileOpp2.Id,
                                                        sked_Type_of_Drive__c = 'Mobile',
                                                        sked_Account__c = testMobileAccount.Id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 20,
                                                        sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = 'Draft');
        
        insert testDrive1;
        
        try{
            testDrive1.sked_Status__c = 'Confirmed';
            update testDrive1;
        }catch(Exception ex)
        {            
            //Assert.isFalse(ex.getMessage().contains('This drive date violates the 56 day rule. Please change the drive date.'));
        }
        
        Test.stopTest();        
    }
    
    static testMethod void testValidateSiteMandatoryFields()
    {
        Test.startTest();
        
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId =  testMobileAccount.Id;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        //testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        // insert Mobile Opp
        Opportunity testMobileOpp2 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp2;
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive1',                                                       
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = testMobileSite.Id,
                                                        sked_Opportunity__c = testMobileOpp2.Id,
                                                        sked_Type_of_Drive__c = 'Mobile',
                                                        sked_Account__c = testMobileAccount.Id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 20,
                                                        sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT);
        
        insert testDrive1;
        
        try{
            testDrive1.sked_Status__c = 'Confirmed';
            update testDrive1;
        }catch(Exception ex)
        {            
            Assert.isTrue(ex.getMessage().contains('Please populate below site mandatory fields before moving this Mobile drive'));
        }
        
        Test.stopTest();        
        
    }
    
    //Method to get the map of recordType Name as key and recordTypeId as value 
    private static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
    //Method to get the one picklist value of the Sobject field
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
    static testMethod void testValidateSiteMandatoryFields1()
    {
        Test.startTest();
        
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId =  testMobileAccount.Id;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        //testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        // insert Mobile Opp
        Opportunity testMobileOpp2 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp2.AccountId = testMobileAccount.Id;
        testMobileOpp2.Drive_Site__c = testMobileSite.Id;
        testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp2;
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive1',                                                       
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = testMobileSite.Id,
                                                        sked_Opportunity__c = testMobileOpp2.Id,
                                                        sked_Type_of_Drive__c = 'Mobile',
                                                        sked_Account__c = testMobileAccount.Id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 20,
                                                        sked_WB_Projected_Procedures__c = 20,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT);
        
        insert testDrive1;
        Map<Id,sked_Drive__c> ddmap = new Map<Id,sked_Drive__c>(new List<sked_Drive__c>{testDrive1});
        ddmap.get(testDrive1.Id).sked_Opportunity__c = null;
        
        try{
            DriveTriggerService.validateOpportunity(ddmap, new List<sked_Drive__c>{testDrive1});
        }catch(Exception ex)
        {            
            //Assert.isTrue(ex.getMessage().contains('Please populate below site mandatory fields before moving this Mobile drive'));
        }
        
        Test.stopTest();        
    }  
    
    // Test method added for HRP-9815
    static testMethod void updateDrdRepOnOpRecordUponOwnerChange_Test() {

        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);

        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Test.startTest();
        GenerateMobileDrive.generateDrives(config);
        
        sked_Drive__c drive = [Select Id , sked_WB_Projected_Procedures__c, sked_Drive_Owner__c, Account_Manager__c,
                               sked_Account__c, sked_Collection_Operation__c, sked_Primary_Contact__c,
                               sked_Drive_Site__c, sked_Drive_Site__r.sked_Site_Contact__c, District_Manager__c,
                               (SELECT Id FROM sked_Drive_Shifts__r)
                               FROM sked_Drive__c 
                               WHERE sked_Opportunity__c IN :config.oppIds LIMIT 1];
        
        sked_Operation_Record__c newOperation = new sked_Operation_Record__c(
                            sked_Account__c = drive.sked_Account__c,
                            sked_Collection_Operation__c = drive.sked_Collection_Operation__c,
                            sked_Donor_Ambassadors_Requested__c = 0,
                            sked_Drive__c = drive.Id,
                            sked_Drive_Shift__c = drive.sked_Drive_Shifts__r[0].Id,
                            sked_Drive_Site__c = drive.sked_Drive_Site__c,
                            sked_Primary_Contact__c = drive.sked_Primary_Contact__c,
                            sked_Site_Contact__c = drive.sked_Drive_Site__r.sked_Site_Contact__c,
                            sked_Unique_Key__c = drive.sked_Drive_Shifts__r[0].Id
                        );
        insert newOperation;
        
        // Generate Op Records
        //List<sked_Operation_Record__c> operationRecords = skedOperationRecordService.generateOperationRecords(new Set<Id>{mobileDriveCreated[0].Id});
        
        drive.District_Manager__c = UserInfo.getUserId();
        drive.sked_WB_Projected_Procedures__c = 12;
        skedHubBase.BypassUpdateTriggers = TRUE;
        update drive;
        skedHubBase.BypassUpdateTriggers = FALSE;
        
        Test.stopTest();
    }
    
}