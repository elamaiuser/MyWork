/*
* This Test class covering the following Classes
* AccountBasedPortfolioClass 
* */
/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 4/18/2023                  Ankit Kundu            Logic for HRP-9654[Newly add Account Based Reason Field ]
 * *
 *****************************************************************************
*/
 
@isTest
    public class AccountBasedPortfolioClass_Test {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> siterecordTypeMap  = new Map<String,Id>();
    
    @isTest static void method1() {
        
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
             LocaleSidKey = 'en_US'
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
             LocaleSidKey = 'en_US'
        );
        

        System.runAs( AdminUser ){
            insert DRDAMUser;
            insert DRDDMUser;
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
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        
        atmList.add(atm);
        
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = mobileAccList[1].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        
        atmList.add(atm);
        
        
        insert atmList;
        
        
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
		
		bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-56E';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA2';
        bportfolio.Portfolio_Type__c = 'Account Portfolio';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
		
		bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-57E';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA3';
        bportfolio.Portfolio_Type__c = 'Sickle Cell Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Sickle Cell Portfolio';
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
		
		//For Supervisor
		bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Supervisor Test 001';
        bportfolio.Portfolio_Code__c = 'Supervisor Test 001';
        bportfolio.Portfolio_Type__c = 'Supervisor';
        bportfolio.Taxonomy_Type__c = 'Bio Recruitment Supervisor';
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bSupervisorParentportfolioList.add( bportfolio );
        
        insert bSupervisorParentportfolioList;
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Recruitment Supervisor';
        bportfolio.Parent_Portfolio__c = bSupervisorParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
        
        insert bportfolioList;
        
        // create Portfolio Assignment data
        List<Portfolio_Assignment__c> passignmentdatas = new List<Portfolio_Assignment__c>();
        Portfolio_Assignment__c passign ;
        
        passign = new Portfolio_Assignment__c();
        passign.BSF_Portfolio__c  = bParentportfolioList[0].Id;
        passign.Assignment_Type__c  = 'District Manager';
        passign.User__c  = DRDAMUser.Id;
        passign.Start_Date__c  = System.today().addDays(5);
        passign.End_Date__c  = System.today().addDays(10);
        
        passignmentdatas.add( passign );
        
		
        passign = new Portfolio_Assignment__c();
        passign.BSF_Portfolio__c  = bportfolioList[0].Id;
		passign.Assignment_Type__c  = 'Account Manager';
        passign.User__c  = DRDDMUser.Id;
        passign.Start_Date__c  = System.today().addDays(5);
		passign.End_Date__c  = System.today().addDays(10);
        passignmentdatas.add( passign );
		
		passign = new Portfolio_Assignment__c();
        passign.BSF_Portfolio__c  = bportfolioList[1].Id;
		passign.Assignment_Type__c  = 'Account Portfolio';
        passign.User__c  = DRDDMUser.Id;
        passign.Start_Date__c  = System.today().addDays(5);
        passign.End_Date__c  = System.today().addDays(10);
        passignmentdatas.add( passign );
		
		passign = new Portfolio_Assignment__c();
        passign.BSF_Portfolio__c  = bportfolioList[2].Id;
		passign.Assignment_Type__c  = 'Sickle Cell Account Manager';
        passign.User__c  = DRDDMUser.Id;
        passign.Start_Date__c  = System.today().addDays(5);
        passign.End_Date__c  = System.today().addDays(10);
        passignmentdatas.add( passign );
		
        
        //For Supervisor
        passign = new Portfolio_Assignment__c();
        passign.BSF_Portfolio__c  = bSupervisorParentportfolioList[0].Id;
		passign.Assignment_Type__c  = 'Supervisor';
        passign.User__c  = DRDDMUser.Id;
        passign.Start_Date__c  = System.today().addDays(5);
        passign.End_Date__c  = System.today().addDays(10);
        passignmentdatas.add( passign );
		
        
        insert passignmentdatas;
        
        List<Account_Portfolio_Assignment__c> apassignmentlist = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c apassign ;
        
        apassign = new Account_Portfolio_Assignment__c();
        apassign.Account__c = mobileAccList[0].Id;
        apassign.BSF_Portfolio__c = bportfolioList[0].Id;
        apassign.Start_Date__c = System.today()-5;
        apassign.End_Date__c = System.today();
        
        apassignmentlist.add( apassign );
        
        insert apassignmentlist;
        
        apassign = apassignmentlist[0];
        Map<Id,Account_Portfolio_Assignment__c> apMap = new Map<Id,Account_Portfolio_Assignment__c>();
        apMap.put(apassign.Id,apassign);
		
		List<AccountBasedPortfolioClass.AccountPortfolioWrapper> apwAccountPortfoliolist = new List<AccountBasedPortfolioClass.AccountPortfolioWrapper>();
        List<AccountBasedPortfolioClass.AccountPortfolioWrapper> apwSickleCelllist = new List<AccountBasedPortfolioClass.AccountPortfolioWrapper>();
        List<AccountBasedPortfolioClass.AccountPortfolioWrapper> apwlist = new List<AccountBasedPortfolioClass.AccountPortfolioWrapper>();
        AccountBasedPortfolioClass.AccountPortfolioWrapper apw = new AccountBasedPortfolioClass.AccountPortfolioWrapper();
        List<string> selectedAccountBaseReason = new List<string>{'Hospital Partner','Education Segment'};
        apw.accountRecid = mobileAccList[0].Id;
        apw.portfolioRecId = bportfolioList[0].Id;
        apw.selectedPortfolioType = 'Account Portfolio';
        apw.Start_Date = String.valueOf(System.today().addDays(5));
        apw.End_Date = String.valueOf(System.today().addDays(10) );
        apw.selectedAccountbasedreason = selectedAccountBaseReason;
        apwAccountPortfoliolist.add(apw);
		
		apw = new AccountBasedPortfolioClass.AccountPortfolioWrapper();
        apw.accountRecid = mobileAccList[0].Id;
        apw.portfolioRecId = bportfolioList[0].Id;
        apw.selectedPortfolioType = 'Sickle Cell Account Manager';
        apw.Start_Date = String.valueOf(System.today().addDays(5));
        apw.End_Date = String.valueOf(System.today().addDays(10) );
        apw.selectedAccountbasedreason = selectedAccountBaseReason;
        apwSickleCelllist.add(apw);
        
        List<id> accidList= new List<id>{mobileAccList[0].Id};
        
        System.runAs( AdminUser ){
            test.startTest();
            AccountBasedPortfolioClass.isAllowedForNonGeographicData();
            AccountBasedPortfolioClass.getAccountInstance( mobileAccList[0].Id );
            try
            {
                AccountBasedPortfolioClass.getAccountInstances( new List<Id>{ mobileAccList[0].Id } );
            }
            catch(exception e)
            {
                system.debug('The Exception is covered'+e.getMessage());
            }
            AccountBasedPortfolioClass.getNonGeoPortfolioData( 'Account Portfolio',accidList);
            AccountBasedPortfolioClass.getNonGeoPortfolioData( 'Sickle Cell Account Manager',accidList);
            
           // AccountBasedPortfolioClass.createAccountPortfolioData(JSON.serialize(apw.selectedAccountbasedreason));
            AccountBasedPortfolioClass.createAccountPortfolioData( JSON.serialize(apwAccountPortfoliolist) );
            AccountBasedPortfolioClass.createAccountPortfolioData( JSON.serialize(apwSickleCelllist) );
            
            //Run the AccountPortfolioAssignmentService class
            //AccountPortfolioAssignmentService.createDefaultTerritoryRecords(apassignmentlist,apMap,apMap);
            
            apassignmentlist = [ select Id from Account_Portfolio_Assignment__c];
            //System.assertEquals( 4, apassignmentlist.size() );
            
            
            // setting visualforce page
            PageReference pageRef = Page.MassAssignAccountBasedPortfolio;      
            Test.setCurrentPage(pageRef);
            
            // Initialising StandardSetController Extension
            ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, OwnerId FROM Account LIMIT 2]));
            setCon.setSelected([SELECT Id, OwnerId FROM Account LIMIT 2]); // this method gives selected records
            
            MassAssignAccountBasedPortfolioClass atmext = new MassAssignAccountBasedPortfolioClass(setCon);
            
            
            test.stopTest();
        }
        
    }
        
        @istest
        static void startDatePastAllowedTest()
        {
            system.assert(AccountBasedPortfolioClass.startDatePastAllowed());
        }

         /*@istest
        static void isAllowedToCreateTeamMembersTest()
        {
            User DRDAMUser = new User(
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
             LocaleSidKey = 'en_US'
             
        );
            
            insert DRDAMUser;
        
          Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        
        Account mobileAcc1 = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420',
            District_Manager__c = userinfo.getUserId()
        );
            insert mobileAcc1;
        
            string accid = mobileAcc1.id+';';
        	 System.runAs( DRDAMUser ){	
            system.assert(!AccountBasedPortfolioClass.isAllowedToCreateTeamMembers(accid));
             }
        }*/
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

    @isTest
    static void testGetBaseURLandFormattedDate() {
        Test.startTest();

        String url = AccountBasedPortfolioClass.getBaseURLExternalform();
        System.assert(url != null, 'Expected getBaseURLExternalform() to return a non-null URL');

        String formatted = AccountBasedPortfolioClass.getFormattedDate(Date.today());
        System.assertEquals(
            String.valueOf(Date.today()).substring(0,10),
            formatted,
            'Expected formatted date to match today\'s date'
        );

        String emptyDate = AccountBasedPortfolioClass.getFormattedDate(null);
        System.assertEquals(
            '',
            emptyDate,
            'Expected getFormattedDate(null) to return empty string'
        );

        Test.stopTest();
    }
    @isTest
    static void testGetNonGeoPortfolioData_OtherTypes() {
        // Create sample Account
        Account acc = new Account(Name = 'RelTestAcc', BillingPostalCode = '12345');
        insert acc;

        // Create Fixed Site portfolio with valid fields and future End_Date
        BSF_Portfolio__c fixedSitePort = new BSF_Portfolio__c(
            Portfolio_Name__c = 'FixedSitePortfolio',
            Portfolio_Code__c = 'FX123',
            Portfolio_Type__c = 'Fixed Site',
            Taxonomy_Type__c = 'Bio Fixed Sites',
            Account_Based_Portfolio__c = true,
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(10)
        );
        insert fixedSitePort;

        // Create Relationship Manager portfolio with valid data
        BSF_Portfolio__c rmPort = new BSF_Portfolio__c(
            Portfolio_Name__c = 'RM Portfolio',
            Portfolio_Code__c = 'RM123',
            Portfolio_Type__c = 'Relationship Manager',
            Taxonomy_Type__c = 'Bio Relationship Manager Portfolio',
            Account_Based_Portfolio__c = true,
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(10)
        );
        insert rmPort;

        Test.startTest();

        // Call for Fixed Site
        List<AccountBasedPortfolioClass.BSFPortfolioWrapper> fixedResult =
            AccountBasedPortfolioClass.getNonGeoPortfolioData('Fixed Site', new List<Id>{acc.Id});
        System.assert(
            fixedResult != null,
            'Expected non-null portfolio list for Fixed Site type (check End_Date__c condition)'
        );

        // Call for Relationship Manager
        List<AccountBasedPortfolioClass.BSFPortfolioWrapper> rmResult =
            AccountBasedPortfolioClass.getNonGeoPortfolioData('Relationship Manager', new List<Id>{acc.Id});
        System.assert(
            rmResult != null,
            'Expected non-null portfolio list for Relationship Manager type (check End_Date__c condition)'
        );

        Test.stopTest();
    }
    @isTest
    static void testCreateAccountTeamData_RM() {
        // Create test Account
        Account acc = new Account(Name = 'RM Account', BillingPostalCode = '12345');
        insert acc;

        BSF_Portfolio__c bsfPort = new BSF_Portfolio__c(
            Portfolio_Name__c = 'RM Portfolio Test',
            Portfolio_Code__c = 'RM001',
            Portfolio_Type__c = 'Relationship Manager',
            Taxonomy_Type__c = 'Bio Relationship Manager Portfolio',
            Account_Based_Portfolio__c = true,
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(10)
        );
        insert bsfPort;

        // Create Portfolio Assignment
        Portfolio_Assignment__c pa = new Portfolio_Assignment__c(
            BSF_Portfolio__c = bsfPort.Id,
            Assignment_Type__c = 'Relationship Manager',
            User__c = UserInfo.getUserId(),
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(5)
        );
        insert pa;

        // Create Account Portfolio Assignment
        Account_Portfolio_Assignment__c apa = new Account_Portfolio_Assignment__c(
            Account__c = acc.Id,
            BSF_Portfolio__c = bsfPort.Id,
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(5)
        );
        insert apa;

        Map<Id, Account_Portfolio_Assignment__c> apMap = new Map<Id, Account_Portfolio_Assignment__c>{ acc.Id => apa };

        Test.startTest();
        AccountBasedPortfolioClass.createAccountTeamData(
            new List<Id>{ acc.Id },
            apMap,
            bsfPort.Id,
            'Relationship Manager',
            Date.today(),
            Date.today().addDays(5),
            bsfPort
        );
        Test.stopTest();

        // Assert that Relationship_Manager__c field was updated
        acc = [SELECT Relationship_Manager__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(
            null,
            acc.Relationship_Manager__c,
            'Expected Relationship_Manager__c to be updated after createAccountTeamData()'
        );
    }   
    
}