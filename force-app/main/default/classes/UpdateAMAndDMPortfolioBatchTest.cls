@isTest
public with sharing class UpdateAMAndDMPortfolioBatchTest {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> siterecordTypeMap  = new Map<String,Id>();
    
    @isTest
    static void testUpdateAMAndDMOnAccountPortfolioBatch() {
        
        // create user 
        
        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        User DRDAMUser1 = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last one',
             Email = 'puser0001@amamama.com',
             Username = 'puser0001@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST1',
             Title = 'title1',
             Alias = 'alias1',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        User DRDAMUser2 = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last two',
             Email = 'puser0002@amamama.com',
             Username = 'puser0002@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST2',
             Title = 'title2',
             Alias = 'alias2',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        User DRDDMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        

        System.runAs( AdminUser ){
            insert DRDAMUser;
            insert DRDDMUser;
            insert DRDAMUser1;
            insert DRDAMUser2;
        }
        
        // create Account
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        //System.debug( 'recTypeId is ' + recTypeId );
        List<Account> mobileAccList = new List<Account>();
        
        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Nestle UK';
        accobj.BillingPostalCode = '30146';
		accobj.Internal_Name__c  =   accobj.Name+1;    
        mobileAccList.add(accobj);
        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Nestle USA';
        accobj.BillingPostalCode = '30146';  
        accobj.Internal_Name__c  =   accobj.Name+1;
        mobileAccList.add(accobj);
        
        insert mobileAccList;
        
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDDMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Is_Covering_Recruiter__c=true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        atmList.add(atm);
        
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser1.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Is_Covering_Recruiter__c=true;
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        atmList.add(atm);
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
       
        List<BSF_Portfolio__c> bParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bSupervisorParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bportfolioList = new List<BSF_Portfolio__c>();
        BSF_Portfolio__c bportfolio ;
        
        // create BSF Portfolio data
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Type__c = 'District Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        
        insert bParentportfolioList;
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
		
        insert bportfolio;
		
        // AM
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.BSF_Portfolio__c = bportfolio.Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Is_Covering_Recruiter__c=false;
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        insert atm;
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        // dm
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser2.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.BSF_Portfolio__c = bParentportfolioList[0].Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Is_Covering_Recruiter__c=false;
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        insert atm;
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');

        System.runAs( AdminUser ){
            test.startTest();
            String AMRole = 'Account Manager';
            String DMRole = 'District Manager';
            Date today = Date.today();
            Database.executeBatch(new UpdateAMAndDMOnAccountPortfolioBatch());
            test.stopTest();
        }
        
    }
    
    @isTest
    static void testUpdateAMAndDMOnOpportunityPortfolioBatch() {
        
        // create user 
        
        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        User DRDAMUser1 = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last one',
             Email = 'puser0001@amamama.com',
             Username = 'puser0001@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST1',
             Title = 'title1',
             Alias = 'alias1',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        User DRDAMUser2 = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last two',
             Email = 'puser0002@amamama.com',
             Username = 'puser0002@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST2',
             Title = 'title2',
             Alias = 'alias2',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        User DRDDMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        

        System.runAs( AdminUser ){
            insert DRDAMUser;
            insert DRDDMUser;
            insert DRDAMUser1;
            insert DRDAMUser2;
        }
        
        // create Account
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        //System.debug( 'recTypeId is ' + recTypeId );
        List<Account> mobileAccList = new List<Account>();
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Map<string, sObject> mapTestData = new Map<string, sObject>();
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        /***** First list ****/
        List<sObject> firstList = new List<sObject>();
        
        // Collection Operation - 1
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 300,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
            sked_Breakdown_Time_Threshold__c = 15,
            sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Travel_Time_Included_Fixed_Site__c = '	All Roles',
            sked_Unpaid_Lunch_Break_Duration__c = 30,
            sked_Lunch_Break__c = true
        );
        firstList.add(testCollectionOperation1);
        mapTestData.put('testCollectionOperation1', testCollectionOperation1);
        
        	// Collection Operation - 2
            Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 25,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
          	sked_Breakdown_Time_Threshold__c = 15,
          	sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
                sked_Lunch_Break__c = true,
          sked_Unpaid_Lunch_Break_Duration__c = 30
        );
        firstList.add(testCollectionOperation2);
        mapTestData.put('testCollectionOperation2', testCollectionOperation2);
        
        // Staffing Decision matrix - Mobile
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 36,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 1,
            sked_VP_HH_Capacity__c = 2.2,
           // sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 15,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix);
        
        // Staffing Decision matrix - fixed site
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_WB_Hourly_Capacity__c = 2.1,
            sked_Platelet_Hourly_Capacity__c = 0.67,
            sked_Plasma_Hourly_Capacity__c = 1.17,
            sked_2RBC_Hourly_Capacity__c = 1,
            sked_2RBC_Staff_Capacity__c = 1.6,
			sked_Charge_Capacity__c = 1.1,
			sked_Charge_Threshold__c = 36,
			sked_Driver_Capacity__c = 2.2,
			sked_Driver_Support_Capacity__c = 2.2,
			sked_Team_Supervisor_Threshold__c = 36,
			sked_VP_HH_Capacity__c = 2.2,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()
        );
        firstList.add(staffingDecisionMatrix2);
        
        // Lunch Break Setting
        sked_Lunch_Break_Setting__c lunchBreakSetting30 = new sked_Lunch_Break_Setting__c(
            sked_Maximum_Lunch_Break_Duration__c = '30'
        );
        firstList.add(lunchBreakSetting30);

        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Nestle UK';
        accobj.BillingPostalCode = '30146';
		accobj.Internal_Name__c  =   accobj.Name+1;    
        mobileAccList.add(accobj);
        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Nestle USA';
        accobj.BillingPostalCode = '30146';  
        accobj.Internal_Name__c  =   accobj.Name+1;
        mobileAccList.add(accobj);
        
        insert mobileAccList;
        
        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(usCitizenTag);
        mapTestData.put('usCitizenTag', usCitizenTag);
        
        sked__Tag__c spanishTag = new sked__Tag__c(
            Name = 'Spanish',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(spanishTag);
        mapTestData.put('spanishTag', spanishTag);
        
        sked__Tag__c liftGateTag = new sked__Tag__c(
            Name = 'Lift Gate',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(liftGateTag);
        mapTestData.put('liftGateTag', liftGateTag);
        
        
        sked__Tag__c personTag = new sked__Tag__c(
            Name = 'Sample Person Tag',
            sked_Resource_Type__c = 'Person'
        );
        firstList.add(personTag);
        mapTestData.put('personTag', personTag);
        
        sked__Tag__c vehicleTag = new sked__Tag__c(
            Name = 'Sample Vehicle Tag',
            sked_Resource_Type__c = 'Vehicle'
        );
        firstList.add(vehicleTag);
        mapTestData.put('vehicleTag', vehicleTag);
        
        sked__Tag__c equipmentTag = new sked__Tag__c(
            Name = 'Sample Equipment Tag',
            sked_Resource_Type__c = 'Equipment'
        );
        firstList.add(equipmentTag);        
        mapTestData.put('equipmentTag', equipmentTag);
        
        insert firstList;
        

        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDDMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Is_Covering_Recruiter__c=true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        atmList.add(atm);
        
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser1.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Is_Covering_Recruiter__c=true;
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        atmList.add(atm);
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
       
        List<BSF_Portfolio__c> bParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bSupervisorParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bportfolioList = new List<BSF_Portfolio__c>();
        BSF_Portfolio__c bportfolio ;
        
        // create BSF Portfolio data
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Type__c = 'District Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        
        insert bParentportfolioList;
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
		
        insert bportfolio;
		
        // AM
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.BSF_Portfolio__c = bportfolio.Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Is_Covering_Recruiter__c=false;
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        insert atm;
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        // dm
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser2.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.BSF_Portfolio__c = bParentportfolioList[0].Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Is_Covering_Recruiter__c=false;
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        insert atm;
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');

        List<sObject> secondList = new List<sObject>();

        Opportunity parentOpp = new Opportunity(
            AccountId = mobileAccList[0].Id,
            Name = 'parent',
            StageName = 'Discovery', 
            CloseDate = System.today(),
            Drive_Date__c = System.today(),
            Is_Template__c = TRUE,
            Source__c = 'Calendar Build'
        );
        secondList.add(parentOpp);
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        secondList.add(testRegion1);
        mapTestData.put('testRegion1', testRegion1);
       
        
        sked_Collection_Operation_SDM__c collectionOperationSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation2.Id,
            
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id
        );
        secondList.add(collectionOperationSdm);
        
        // fixed site
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id
        );
        secondList.add(collectionOperationSdm2);
        
        sked_Lunch_Break_Definition__c setting30definition1 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 10,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 2,
            sked_Min_Number_of_Staff__c = 0,
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition1);
        sked_Lunch_Break_Definition__c setting30definition4 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 15,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 16,
            sked_Min_Number_of_Staff__c = 9,
            
            sked_Slot_Reduction__c = 2
        );
        secondList.add(setting30definition4);
        
        sked_Lunch_Break_Definition__c setting30definition5 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 12,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 9,
            sked_Min_Number_of_Staff__c = 17,
            
            sked_Slot_Reduction__c = 6.67
        );
        secondList.add(setting30definition5);
        
        //  skedFixedSiteProcedureProjectionHandler.bypassInsertTrigger = true;
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection1 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = mobileAccList[0].Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'WB',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection1);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection2 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = mobileAccList[0].Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = '2RBC',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection2);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection3 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = mobileAccList[0].Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Platelet',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection3);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection4 = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = mobileAccList[0].Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Procedure_Type__c = 'Plasma',
            sked_Productive_Procedure_Goal__c = 5,
            sked_QNS__c = 25
        );
        secondList.add(fixedSiteProcedureProjection4);


        sked__Account_Tag__c fixedSiteAccountTag3 = new sked__Account_Tag__c(
            sked__Account__c = mobileAccList[0].Id,
            sked__Tag__c = vehicleTag.Id,
            sked__Required__c = false,
            sked_Minimum_Quantity__c = 1,
            sked__Weighting__c = 10
           // ,sked_Minimum_Quantity__c = 1
        );
        secondList.add(fixedSiteAccountTag3);
       
        insert secondList;

        System.runAs( AdminUser ){
            test.startTest();
            String AMRole = 'Account Manager';
            String DMRole = 'District Manager';
            Date today = Date.today();
            Database.executeBatch(new UpdateAMAndDMOnOpportunityPortfolioBatch());
            test.stopTest();
        }
        
    }
    //Method to get the map of recordType Name as key and recordTypeId as value 
    public static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
}