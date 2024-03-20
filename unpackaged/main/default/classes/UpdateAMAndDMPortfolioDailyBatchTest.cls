@isTest
public class UpdateAMAndDMPortfolioDailyBatchTest {
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
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
    static void testMethod1() {
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
            LocaleSidKey = 'en_US'
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

        List<BSF_Portfolio__c> bParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bportfolioList = new List<BSF_Portfolio__c>();
        BSF_Portfolio__c bportfolio ;
        
        // create BSF Portfolio data
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Type__c = 'District Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        
        insert bParentportfolioList;
        system.debug('bParentportfolioList value :: '+bParentportfolioList[0].id);
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Recruitment CD';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
		
        insert bportfolio;

        system.debug('bParentportfolioList value :: '+bportfolio.id);

        List<Account_Portfolio_Assignment__c> apassignmentlist = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c apassign ;
        
        apassign = new Account_Portfolio_Assignment__c();
        apassign.Account__c = mobileAccList[0].Id;
        apassign.BSF_Portfolio__c = bportfolio.Id;
        apassign.Start_Date__c = System.today()-5;
        apassign.End_Date__c = System.today()+5;
        
        apassignmentlist.add( apassign );
        
        insert apassignmentlist;

        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(bParentportfolioList[0].Id, yesterday);     
        Test.setCreatedDate(bportfolio.Id, yesterday);
        Test.setCreatedDate(apassignmentlist[0].Id, yesterday);

        List<Account_Portfolio_Assignment__c> apassignmentlist1 = [SELECT Account__c, CreatedDate, BSF_Portfolio__r.Taxonomy_Type__c, BSF_Portfolio__r.Portfolio_Type__c FROM Account_Portfolio_Assignment__c where BSF_Portfolio__r.Portfolio_Type__c = 'Account Manager' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN ('Bio Recruitment CD','Bio Account Portfolio') AND (CreatedDate = yesterday or LastModifiedDate = yesterday)];
        system.debug('apassignmentlist1 value :: '+apassignmentlist1);
        system.debug('yesterday value :: '+yesterday);
            test.startTest();
        	String cronExpr = '0 0 0 15 3 ? 2022';
			System.schedule('UpdateAMAndDMPortfDailyBatchScheduler_' + String.valueOf(Datetime.now()), 
            '0 0 0 * * ?', new UpdateAMAndDMPortfDailyBatchScheduler());
            test.stopTest();

    }

    @isTest
    static void testMethod2() {
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
            LocaleSidKey = 'en_US'
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

        List<BSF_Portfolio__c> bParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bportfolioList = new List<BSF_Portfolio__c>();
        BSF_Portfolio__c bportfolio ;
        
        // create BSF Portfolio data
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Type__c = 'District Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        insert bParentportfolioList;
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54EA';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54EA';
        bportfolio.Portfolio_Type__c = 'Account Specialist';
        bportfolio.Taxonomy_Type__c = 'Account Specialist';
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        insert bportfolio;
        
        system.debug('bParentportfolioList value :: '+bParentportfolioList[0].id);
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Recruitment CD';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Parent_Portfolio__c = bParentportfolioList[1].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
		
        insert bportfolio;

        system.debug('bParentportfolioList value :: '+bportfolio.id);

        List<Account_Portfolio_Assignment__c> apassignmentlist = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c apassign ;
        
        apassign = new Account_Portfolio_Assignment__c();
        apassign.Account__c = mobileAccList[0].Id;
        apassign.BSF_Portfolio__c = bportfolio.Id;
        apassign.Start_Date__c = System.today()-5;
        apassign.End_Date__c = System.today()+5;
        
        apassignmentlist.add( apassign );
        
        insert apassignmentlist;

        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(bParentportfolioList[0].Id, yesterday);     
        Test.setCreatedDate(bportfolio.Id, yesterday);
        Test.setCreatedDate(apassignmentlist[0].Id, yesterday);

        List<Account_Portfolio_Assignment__c> apassignmentlist1 = [SELECT Account__c, CreatedDate, BSF_Portfolio__r.Taxonomy_Type__c, BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c FROM Account_Portfolio_Assignment__c where BSF_Portfolio__r.Portfolio_Type__c = 'Account Manager' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN ('Bio Recruitment CD','Bio Account Portfolio') AND (CreatedDate = yesterday or LastModifiedDate = yesterday)];
        system.debug('apassignmentlist1 value :: '+apassignmentlist1);
        system.debug('check condition value ::1 '+apassignmentlist1[0].BSF_Portfolio__r.Portfolio_Type__c);
        system.debug('check condition value ::2 '+apassignmentlist1[0].BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c);
        system.debug('check condition value ::3 '+apassignmentlist1[0].BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c);
        system.debug('yesterday value :: '+yesterday);
            test.startTest();
            Database.executeBatch(new UpdateAMAndDMPortfolioDailyBatch());
            test.stopTest();

    }
        
	@isTest
    static void testMethod3() {
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
            LocaleSidKey = 'en_US'
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

        List<BSF_Portfolio__c> bParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bportfolioList = new List<BSF_Portfolio__c>();
        BSF_Portfolio__c bportfolio ;
        
        // create BSF Portfolio data
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Type__c = 'District Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        
        insert bParentportfolioList;
        system.debug('bParentportfolioList value :: '+bParentportfolioList[0].id);
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Recruitment CD';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
		
        insert bportfolio;

        system.debug('bParentportfolioList value :: '+bportfolio.id);
        
        // create Contact
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
		conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conlist.add(conObj);
        insert conlist;
        
        
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
        sked__Location__c siteObj = new sked__Location__c();
        //siteObj.RecordTypeId = siteRecTypeId;
        siteObj.Name = 'Test Site';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
        siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = conlist[0].Id;
        siteObj.sked_Site_Main_Phone__c = '999-999-9999';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.source__c='Custom New Form';
        siteObj.sked_Address_1__c='Test Site Address';
        siteObj.sked_City__c='Test site city';
        siteObj.sked_County__c='AMERICA';
        siteObj.sked_State__c='test state';
        siteObj.sked_Wireless_Policy__c='Accepted';
        siteObj.sked_Zip_Code__c='94608';
        skedlocationlist.add(siteObj);
        insert skedlocationlist;
        
        
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity optyObj = new Opportunity();
        //optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = mobileAccList[0].Id;
        optyObj.Drive_Site__c = skedlocationlist[0].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Status__c='Confirmed';
        optyObj.Drive_Date__c = System.today();
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.Anticipated_Registered_Donors__c = 1;   
        // fields to calculate Total Products projected
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        
        opplist.add(optyObj);       
        insert opplist;
        

        List<Account_Portfolio_Assignment__c> apassignmentlist = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c apassign ;
        
        apassign = new Account_Portfolio_Assignment__c();
        apassign.Account__c = mobileAccList[0].Id;
        apassign.BSF_Portfolio__c = bportfolio.Id;
        apassign.Start_Date__c = System.today()-5;
        apassign.End_Date__c = System.today()+5;
        
        apassignmentlist.add( apassign );
        
        insert apassignmentlist;

        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(bParentportfolioList[0].Id, yesterday);     
        Test.setCreatedDate(bportfolio.Id, yesterday);
        Test.setCreatedDate(apassignmentlist[0].Id, yesterday);
        
        

        List<Account_Portfolio_Assignment__c> apassignmentlist1 = [SELECT Account__c, CreatedDate, BSF_Portfolio__r.Taxonomy_Type__c, BSF_Portfolio__r.Portfolio_Type__c FROM Account_Portfolio_Assignment__c where BSF_Portfolio__r.Portfolio_Type__c = 'Account Manager' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN ('Bio Recruitment CD','Bio Account Portfolio') AND (CreatedDate = yesterday or LastModifiedDate = yesterday)];
        system.debug('apassignmentlist1 value :: '+apassignmentlist1);
        system.debug('yesterday value :: '+yesterday);
            test.startTest();
            Database.executeBatch(new UpdateAMAndDMPortfolioDailyBatch());
            test.stopTest();

    }
    
    @isTest
    static void testMethod4() {
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
            LocaleSidKey = 'en_US'
           
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

        // create Contact
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
		conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conlist.add(conObj);
        insert conlist;
        
        
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
        sked__Location__c siteObj = new sked__Location__c();
        //siteObj.RecordTypeId = siteRecTypeId;
        siteObj.Name = 'Test Site';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
        siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = conlist[0].Id;
        siteObj.sked_Site_Main_Phone__c = '999-999-9999';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.source__c='Custom New Form';
        siteObj.sked_Address_1__c='Test Site Address';
        siteObj.sked_City__c='Test site city';
        siteObj.sked_County__c='AMERICA';
        siteObj.sked_State__c='test state';
        siteObj.sked_Wireless_Policy__c='Accepted';
        siteObj.sked_Zip_Code__c='94608';
        skedlocationlist.add(siteObj);
        insert skedlocationlist;
        
        
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity optyObj = new Opportunity();
        //optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = mobileAccList[0].Id;
        optyObj.Drive_Site__c = skedlocationlist[0].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Status__c='Confirmed';
        optyObj.Drive_Date__c = System.today();
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.Anticipated_Registered_Donors__c = 1;   
        // fields to calculate Total Products projected
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        
        opplist.add(optyObj);       
        insert opplist;
        

        List<BSF_Portfolio__c> bParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bportfolioList = new List<BSF_Portfolio__c>();
        BSF_Portfolio__c bportfolio ;
        
        // create BSF Portfolio data
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Type__c = 'District Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        insert bParentportfolioList;
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54EA';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54EA';
        bportfolio.Portfolio_Type__c = 'Account Specialist';
        bportfolio.Taxonomy_Type__c = 'Account Specialist';
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        insert bportfolio;
        
        system.debug('bParentportfolioList value :: '+bParentportfolioList[0].id);
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Recruitment CD';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Parent_Portfolio__c = bParentportfolioList[1].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
		
        insert bportfolio;

        system.debug('bParentportfolioList value :: '+bportfolio.id);

        List<Account_Portfolio_Assignment__c> apassignmentlist = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c apassign ;
        
        apassign = new Account_Portfolio_Assignment__c();
        apassign.Account__c = mobileAccList[0].Id;
        apassign.BSF_Portfolio__c = bportfolio.Id;
        apassign.Start_Date__c = System.today()-5;
        apassign.End_Date__c = System.today()+5;
        
        apassignmentlist.add( apassign );
        
        insert apassignmentlist;

        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(bParentportfolioList[0].Id, yesterday);     
        Test.setCreatedDate(bportfolio.Id, yesterday);
        Test.setCreatedDate(apassignmentlist[0].Id, yesterday);

        List<Account_Portfolio_Assignment__c> apassignmentlist1 = [SELECT Account__c, CreatedDate, BSF_Portfolio__r.Taxonomy_Type__c, BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c FROM Account_Portfolio_Assignment__c where BSF_Portfolio__r.Portfolio_Type__c = 'Account Manager' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN ('Bio Recruitment CD','Bio Account Portfolio') AND (CreatedDate = yesterday or LastModifiedDate = yesterday)];
        system.debug('apassignmentlist1 value :: '+apassignmentlist1);
        system.debug('check condition value ::1 '+apassignmentlist1[0].BSF_Portfolio__r.Portfolio_Type__c);
        system.debug('check condition value ::2 '+apassignmentlist1[0].BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c);
        system.debug('check condition value ::3 '+apassignmentlist1[0].BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c);
        system.debug('yesterday value :: '+yesterday);
            test.startTest();
            Database.executeBatch(new UpdateAMAndDMPortfolioDailyBatch());
            test.stopTest();

    }
    
    @isTest
    static void testMethod5() {
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
            LocaleSidKey = 'en_US'
        
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

        List<BSF_Portfolio__c> bParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bportfolioList = new List<BSF_Portfolio__c>();
        BSF_Portfolio__c bportfolio ;
        
        // create BSF Portfolio data
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Type__c = 'District Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        
        insert bParentportfolioList;
        system.debug('bParentportfolioList value :: '+bParentportfolioList[0].id);
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Recruitment CD';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );
		
        insert bportfolio;

        system.debug('bParentportfolioList value :: '+bportfolio.id);

        List<Account_Portfolio_Assignment__c> apassignmentlist = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c apassign ;
        
        apassign = new Account_Portfolio_Assignment__c();
        apassign.Account__c = mobileAccList[0].Id;
        apassign.BSF_Portfolio__c = bportfolio.Id;
        apassign.Start_Date__c = System.today()-5;
        apassign.End_Date__c = System.today()+5;
        
        apassignmentlist.add( apassign );
        
        apassign = new Account_Portfolio_Assignment__c();
        
        apassign = new Account_Portfolio_Assignment__c();
        apassign.Account__c = mobileAccList[0].Id;
        apassign.BSF_Portfolio__c = bportfolio.Id;
        apassign.Start_Date__c = System.today()-10;
        apassign.End_Date__c = System.today()-6;
        
        apassignmentlist.add( apassign );
        
        apassign = new Account_Portfolio_Assignment__c();
        
        apassign = new Account_Portfolio_Assignment__c();
        apassign.Account__c = mobileAccList[0].Id;
        apassign.BSF_Portfolio__c = bportfolio.Id;
        apassign.Start_Date__c = System.today()-15;
        apassign.End_Date__c = System.today()-11;
        
        apassignmentlist.add( apassign );
        
        insert apassignmentlist;

        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(bParentportfolioList[0].Id, yesterday);     
        Test.setCreatedDate(bportfolio.Id, yesterday);
        Test.setCreatedDate(apassignmentlist[0].Id, yesterday);
        Test.setCreatedDate(apassignmentlist[1].Id, yesterday);
        Test.setCreatedDate(apassignmentlist[2].Id, yesterday);

        List<Account_Portfolio_Assignment__c> apassignmentlist1 = [SELECT Account__c, CreatedDate, BSF_Portfolio__r.Taxonomy_Type__c, BSF_Portfolio__r.Portfolio_Type__c FROM Account_Portfolio_Assignment__c where BSF_Portfolio__r.Portfolio_Type__c = 'Account Manager' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN ('Bio Recruitment CD','Bio Account Portfolio') AND (CreatedDate = yesterday or LastModifiedDate = yesterday)];
        system.debug('apassignmentlist1 value :: '+apassignmentlist1);
        system.debug('yesterday value :: '+yesterday);
            test.startTest();
            Database.executeBatch(new UpdateAMAndDMPortfolioDailyBatch());
            test.stopTest();

    }

}