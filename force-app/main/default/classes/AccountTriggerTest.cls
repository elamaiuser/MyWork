/* This Test class covers the following Classes
*  AccountTriggerHandler
*  AccountService
* */

/* 
 * Modification Log 
 * Date					      Developer Name			            Comments
 * *************************************************************************************************************
 * 12/6/2023				   Priti Jana			Replaced all System.Assert with new Assert class
 * 1/19/2024				   Priti Jana			Fixed all existing errors
 * 2/20/2024				   Priti Jana			Fixed all existing errors, added new test method (HRP-9520)
 * *************************************************************************************************************/

@isTest
public class AccountTriggerTest
{
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String fixedOppRecType = 'Fixed Site Opp';
    public static String mobileSiteRecType = 'Mobile Site';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Account' );       
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        
        recordTypeMap = recordTypeMap( 'Opportunity' );        
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        Id fixedoptyRecTypeId = recordTypeMap.get(fixedOppRecType);
        
        List<ARC_Market_Mapping__c> mmapList = new List<ARC_Market_Mapping__c>();
        ARC_Market_Mapping__c mmap ;
        
        mmap = new ARC_Market_Mapping__c();
        mmap.Zip_Code__c = '30622';
        mmap.Market__c = 'Alpharetta';
        mmapList.add(mmap);
        
        mmap = new ARC_Market_Mapping__c();
        mmap.Zip_Code__c = '30146';
        mmap.Market__c = 'Marietta GA FS';
        mmapList.add(mmap);
        
        mmap = new ARC_Market_Mapping__c();
        mmap.Zip_Code__c = '30147';
        mmap.Market__c = 'Stone Mountain';
        mmapList.add(mmap);
        
        insert mmapList;
        
        Map <String,Schema.RecordTypeInfo> recordTypesadjustment = Taxonomy__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id RecTypeIdTax = recordTypesadjustment.get('Bio Recruitment CD').getRecordTypeId();        
        Date startDate1 = System.today().addMonths(-6);
        Date endDate1   = System.today().addMonths(4);    
        Date startDate2 = System.today().addMonths(2);
        Date endDate2   = System.today().addMonths(6);        
        
        List<Taxonomy__c> taxList = new List<Taxonomy__c>();
        Taxonomy__c tax1 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',
                                           DRD_Territory_Code__c='HProdSEMR_1836',DRD_Territory_Name__c='Detroit South 05',  
                                           DS_Region_Code__c='13Z18Z', DS_Region_Name__c='Michigan',   End_Date__c = endDate1,
                                           RecordTypeId=RecTypeIdTax, Start_Date__c=startDate1, Team_Code__c='MICH_Detroit S',
                                           Team_Name__c='MICH_Detroit S',Type__c='Bio Recruitment',  Version_Key__c=108.0, Zip_Code__c='30622');
        
        taxList.add(tax1);        
        insert taxList;
        BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        DMPortfolio.External_Key__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c+'_'+taxList[0].Start_Date__c;
        DMPortfolio.External_Key_BackEnd__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c;
        
        insert DMPortfolio;
        
        /*BSF_Portfolio__c AMPortfolio = new BSF_Portfolio__c();
        AMPortfolio.Portfolio_Code__c = 'HProdSEMR_1836';
        AMPortfolio.Portfolio_Name__c = 'Detroit South 05';
        AMPortfolio.Portfolio_Type__c = 'Account Manager';
        AMPortfolio.Account_Based_Portfolio__c = false;
        AMPortfolio.Parent_Portfolio__c=DMPortfolio.id;
        AMPortfolio.Territory_Portfolio__c = true;
        AMPortfolio.External_Key__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c+'_'+taxList[0].Start_Date__c;
        AMPortfolio.External_Key_BackEnd__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c;
        insert AMPortfolio;*/
       
        
        BSF_Portfolio__c DMPortfolio1 = new BSF_Portfolio__c();
        DMPortfolio1.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio1.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio1.Portfolio_Type__c = 'District Manager';
        DMPortfolio1.Account_Based_Portfolio__c = false;
        DMPortfolio1.Territory_Portfolio__c = true;
        DMPortfolio1.Taxonomy_Type__c=BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE;      
        insert DMPortfolio1;
        
        //Portfolio_Assignment__c am = new Portfolio_Assignment__c(BSF_Portfolio__c=DMPortfolio.Id,User__c=userInfo.getUserId(),Start_Date__c=startDate1 ,End_Date__c=endDate1,Assignment_Type__c='District Manager');
        
        //insert am;
        List<Account> mobileAccList = new List<Account>();
        
        Account accobj;
        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30622';
        
        Account acc1=new Account();
        acc1.name='testAcct01';
        acc1.RecordTypeId = recTypeId;
        acc1.BillingPostalCode = '30623';
        acc1.Days_of_Week_Declined__c ='Monday;Tuesday';
        
        mobileAccList.add(accobj);
        mobileAccList.add(acc1);
        
        insert mobileAccList;
        
        Contact conObj = new Contact();
        conObj.AccountId = acc1.Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
		conObj.OtherCity = 'Ashburn';
        conObj.OtherCountryCode ='US';
        conObj.OtherPostalCode = '20148';
        conObj.OtherStateCode = 'VA';
        conObj.OtherStreet = '23070 Learning Cir';
        conObj.Email = 'testContact@gmail.com';
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        insert conObj;
        
        List<Opportunity> oppsobjlist = new List<Opportunity>();
        Opportunity optyObj ; // = new Opportunity();
        optyObj = new Opportunity();
        optyObj.RecordTypeId = fixedoptyRecTypeId;
        optyObj.AccountId = acc1.Id;
        // optyObj.Drive_Site__c = [SELECT Id FROM sked__Location__c WHERE Name = 'Test Site'].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today()+1;
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.WB_Projected_Procedures__c = 1;
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.Anticipated_Registered_Donors__c = 1;
        
        oppsobjlist.add( optyObj );
		
		optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = acc1.Id;
        // optyObj.Drive_Site__c = [SELECT Id FROM sked__Location__c WHERE Name = 'Test Site'].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today()+2;
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.WB_Projected_Procedures__c = 1;
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.Anticipated_Registered_Donors__c = 1;
        
        oppsobjlist.add( optyObj );
        
        optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = acc1.Id;
        //optyObj.Drive_Site__c = [SELECT Id FROM sked__Location__c WHERE Name = 'Test Site'].Id;
        optyObj.Name = 'Test Drive2';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today();
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.WB_Projected_Procedures__c = 1;
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.Anticipated_Registered_Donors__c = 1;
        
        oppsobjlist.add( optyObj );        
        insert oppsobjlist;
        
    }
    
    @isTest static void testPopulateMarketOnAccount()
    {
                
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
        
        
        System.runAs( AdminUser )
        {
            insert DRDAMUser;
        }
        
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);       
        List<Account> mobileAccList = new List<Account>();
        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';        
        accobj.BillingStreet = '1023 Baker Stret';
        accobj.ShippingStreet = '1023 Baker Stret';
		accobj.ShippingPostalCode = '30146';
        mobileAccList.add(accobj);      
        List<Account> accUpdateList = [ SELECT Id, BillingPostalCode,ShippingPostalCode, Market__c FROM Account where Name = 'Exavalu'];
        accUpdateList[0].BillingPostalCode = '30147';       
        accUpdateList[0].ShippingPostalCode = '30147';       
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = accUpdateList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c=System.today();
        atm.End_Date__c=System.today();
         atm.Coverage_Reason__c='Vacant Territory';
        atmList.add(atm);
        insert atmList;
               
        System.runAs( DRDAMUser )
        {
            test.startTest();
            
            insert mobileAccList;            
            Account acc = [ select Id, Market__c from Account where id =: mobileAccList[0].Id ];           
            update accUpdateList;
            Account accupdated = [ select Id, Market__c from Account where id =: accUpdateList[0].Id ];
        }   
        
        delete atmList;
        test.stopTest();
    }
    
    
    @isTest static void testvalidationForDaysOfWeekDeclined()
    {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        Account acc= [select Id,Name,Days_of_Week_Declined__c from Account where Name='testAcct01'];
        list<Opportunity> oppList=[select id,Day_of_Week__c from Opportunity where name='Test Drive'];
        system.debug('oppList### '+oppList);
        acc.Days_of_Week_Declined__c ='Wednesday;Thursday;Monday;Tuesday';
        acc.Account_Strategy_Notes__c='test';
        acc.National_Name__c='test';
        acc.account_type_from_lead__c='test';
        test.startTest();
        update acc;        		
        test.stopTest();  
        
		Account resultAccount = [SELECT Id, Days_of_Week_Declined__c FROM Account WHERE Id = :acc.Id];        
		Assert.areEqual('Monday;Tuesday;Wednesday;Thursday', resultAccount.Days_of_Week_Declined__c);
        
    }
    
     @isTest static void testRestrictAccountDeletionForOtherUsers() {   
         
         Test.startTest();
         TriggerHandler.bypass('AccountTriggerHandler');
         
         BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
         Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
         
         User testDRDUser = (User)mapTestData.get('DRD_USER');
         testDRDUser.IsActive = true;
         System.runAs(new User(Id = UserInfo.getUserId())) {
             insert testDRDUser;
         }
         
         Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
         insert testMobileAccount;
         TriggerHandler.clearBypass('AccountTriggerHandler');
         
         System.runAs(testDRDUser) {
              try {
            	delete testMobileAccount;
            } catch (DmlException e) {
                Assert.isTrue(e.getMessage().contains('You are not authorized to Delete or Merge Accounts'));
            }
         }
        Test.stopTest();       
    }
       
    @isTest
    static void testAddressUpdationUnsuccessNotifyByTask()
    { 
        Test.startTest();
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;
        Contact conObj = (Contact)mapTestData.get('CONTACT');
        conObj.AccountId = testMobileAccount.Id;
        insert conObj;

        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Map<String, Map<Id, String>> accountManagerIds = new Map<String, Map<Id, String>>();
        Map<Id, String> accountIdUserIdMap = new Map<Id, String>();
        accountIdUserIdMap.put(testMobileAccount.Id, testUser.Id);
        accountManagerIds.put('Account', accountIdUserIdMap);

        Map<Id, String> contactIdAccountIdMap = new Map<Id, String>();
        contactIdAccountIdMap.put(conObj.Id, testMobileAccount.Id);

        
       	accountService.addressUpdationunsucessnotifyByTask(accountManagerIds, contactIdAccountIdMap);
        Test.stopTest();

        List<Task> accountTasks = [SELECT Id, Subject, WhatId, WhoId, OwnerId, Status FROM Task WHERE WhatId = :testMobileAccount.Id AND Subject = :System.Label.InvalidAccountAddressTaskSubject];
        Assert.areEqual(1, accountTasks.size(), 'There should be one task for the Account');
        Assert.areEqual(testUser.Id, accountTasks[0].OwnerId, 'Task OwnerId should be the same as the Account Manager Id');
        Assert.areEqual('Not Started', accountTasks[0].Status, 'Task status should be "Not Started"');

        List<Task> contactTasks = [SELECT Id, Subject, WhatId, WhoId, OwnerId, Status FROM Task WHERE WhoId = :conObj.Id AND Subject = :System.Label.InvalidContactAddressTaskSubject];
        Assert.areEqual('Not Started', contactTasks[0].Status, 'Task status should be "Not Started"');
    }
    
    public static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    } 
    /*
   @isTest
    public static void testPopulateAccountTeamMembersByPortfolio() {
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        Account testMobileAccount1 = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount1;

        // Create a taxonomy record
        Map <String,Schema.RecordTypeInfo> recordTypesadjustment = Taxonomy__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id RecTypeIdTax = recordTypesadjustment.get('Bio Recruitment CD').getRecordTypeId();        
        Date startDate1 = System.today().addMonths(-6);
        Date endDate1   = System.today().addMonths(4);    
        Date startDate2 = System.today().addMonths(2);
        Date endDate2   = System.today().addMonths(6);        
        
        List<Taxonomy__c> taxList = new List<Taxonomy__c>();
        Taxonomy__c tax1 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',
                                           DRD_Territory_Code__c='HProdSEMR_1836',DRD_Territory_Name__c='Detroit South 05',  
                                           DS_Region_Code__c='13Z18Z', DS_Region_Name__c='Michigan',   End_Date__c = endDate1,
                                           RecordTypeId=RecTypeIdTax, Start_Date__c=startDate1, Team_Code__c='MICH_Detroit S1',
                                           Team_Name__c='MICH_Detroit S1',Type__c='Bio Recruitment',  Version_Key__c=108.0, Zip_Code__c='30622');
        
        taxList.add(tax1);        
        insert taxList;
		BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        
        insert DMPortfolio;
        
        
        BSF_Portfolio__c ABMPortfolio = new BSF_Portfolio__c();
        ABMPortfolio.Portfolio_Code__c = 'NA_Detorit_ABM_1';
        ABMPortfolio.Portfolio_Name__c = 'NA_Detorit_ABM_1';
        ABMPortfolio.Portfolio_Type__c = 'Area Booking Manager';
        ABMPortfolio.Account_Based_Portfolio__c = false;
        ABMPortfolio.Territory_Portfolio__c = true;
        ABMPortfolio.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager' limit 1].Id; 
        
        insert ABMPortfolio;
        
        BSF_Portfolio__c AMPortfolioWithABM = new BSF_Portfolio__c();
        AMPortfolioWithABM.Portfolio_Name__c = 'Detroit South 05';
        AMPortfolioWithABM.Portfolio_Code__c = 'HProdSEMR_1836';
        AMPortfolioWithABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithABM.Territory_Portfolio__c = true;
        AMPortfolioWithABM.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithABM.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager'].Id; 
        
        insert AMPortfolioWithABM;
        
        BSF_Portfolio__c AMPortfolioWithoutABM = new BSF_Portfolio__c();
        AMPortfolioWithoutABM.Portfolio_Name__c = 'Detroit South 07';
        AMPortfolioWithoutABM.Portfolio_Code__c = 'HProdSEMR_1837';
        AMPortfolioWithoutABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithoutABM.Territory_Portfolio__c = true;
        AMPortfolioWithoutABM.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithoutABM.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager'].Id; 
        
        insert AMPortfolioWithoutABM;
        
        //insert Sickle Cell Account Manager
        BSF_Portfolio__c sickleCellAM = new BSF_Portfolio__c();
        sickleCellAM.Portfolio_Name__c ='SAM Test Data 1';
        sickleCellAM.Portfolio_Code__c ='SAM Test Data 1';
        sickleCellAM.Account_Based_Portfolio__c = true;
        sickleCellAM.Portfolio_Type__c = 'Sickle Cell Account Manager';
        
        insert sickleCellAM;
        /*
		BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S1';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S1';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        DMPortfolio.External_Key__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c+'_'+taxList[0].Start_Date__c;
        DMPortfolio.External_Key_BackEnd__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c;
        
        insert DMPortfolio;
		
        //Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile'];
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        //List<User> drdUsers = populateUserFields('DRD','Manager',drdManagerProfile.Id,1);
        //system.debug('drdUsers@@ '+drdUsers);
        List<user> users = new List<user>();
        User u1 = new User(Alias = 'usr1', Email='drduser1@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = drdManagerProfile.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser1@test.com.tst1');
        users.add(u1);
        
        list<Portfolio_Assignment__c> paList=new list<Portfolio_Assignment__c>();
        Portfolio_Assignment__c am = new Portfolio_Assignment__c(BSF_Portfolio__c=DMPortfolio.Id,User__c=users[0].id,Start_Date__c=startDate1 ,End_Date__c=endDate1,Assignment_Type__c='District Manager');
        //insert am;
        paList.add(am);
        insert paList;
	
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = userInfo.getUserId() ;
        atm.AccountId = testMobileAccount1.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        AccountTeammember atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = userInfo.getUserId() ;
        atm2.AccountId = testMobileAccount1.Id ;
        atm2.TeamMemberRole = 'Account Manager';
        atm2.Start_Date__c = System.today().addDays(-1);
        atm2.End_Date__c = System.today().addDays(10);
        atm2.Is_Covering_Recruiter__c = false;
        atm2.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm2);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
      
        List<Account_Portfolio_Assignment__c> accPortfolioAssignemnetList = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c accPortfolio1 = new Account_Portfolio_Assignment__c();
        accPortfolio1.BSF_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Type__c = 'Account Manager' AND Portfolio_Code__c = 'HProdSEMR_1836'].Id;
        accPortfolio1.Account__c = [SELECT Id FROM Account WHERE Name = 'Test Account 1'].Id;
        accPortfolio1.Start_Date__c = SYstem.today();
        accPortfolio1.End_Date__c = System.today() +5;
        
        accPortfolioAssignemnetList.add(accPortfolio1);
        
        Account_Portfolio_Assignment__c accPortfolio2 = new Account_Portfolio_Assignment__c();
        accPortfolio2.BSF_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Type__c = 'Account Manager' AND Portfolio_Code__c = 'HProdSEMR_1837'].Id;
        accPortfolio2.Account__c = [SELECT Id FROM Account WHERE Name = 'Test Account 2'].Id;
        accPortfolio2.Start_Date__c = SYstem.today();
        accPortfolio2.End_Date__c = System.today() +5;
        
        accPortfolioAssignemnetList.add(accPortfolio2);
        
        Account_Portfolio_Assignment__c accPortfolio3 = new Account_Portfolio_Assignment__c();
        accPortfolio3.BSF_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Type__c = 'Sickle Cell Account Manager' AND Portfolio_Code__c = 'SAM Test Data 1'].Id;
        accPortfolio3.Account__c = [SELECT Id FROM Account WHERE Name = 'Test Account 3'].Id;
        accPortfolio3.Start_Date__c = SYstem.today();
        accPortfolio3.End_Date__c = System.today() +5;
        
        accPortfolioAssignemnetList.add(accPortfolio3);
        
        Insert accPortfolioAssignemnetList;
    
        
        Map<Id, Account_Portfolio_Assignment__c> accIdAccPortfolioMap = new Map<Id, Account_Portfolio_Assignment__c>();

        for (Account_Portfolio_Assignment__c apa : accPortfolioAssignemnetList) {
            accIdAccPortfolioMap.put(apa.Id, apa);
        }

        // Call the method to test
        AccountService.populateAccountTeamMembersByPortfolio(testMobileAccount1, taxList[0], 'Test Portfolio', paList, atmList, atmList[0], 'calledFromBatch', accIdAccPortfolioMap);
    
	}
	*/
    
    @isTest
    static void testUpdateOpportunitiesForInternalNameChangeAsync() {
        
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        //TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;
        
		sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;

        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;  
        
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
        
        TriggerHandler.clearAllBypasses();
        
        testMobileAccount.Internal_Name__c = 'Changed Test';
        update testMobileAccount;
        Test.stopTest();
        
        Assert.isTrue([SELECT Id, Internal_Name__c FROM Account WHERE Id = :testMobileAccount.Id LIMIT 1].Internal_Name__c.contains('Changed Test'));
		
    }
	
    //test method for HRP-10085 ***starts here***
    @isTest
    static void testUpdateTemplatesForAccountNameChange() {
       	
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c = 'Test One Account';
        insert testMobileAccount; 
 
		sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;

        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;  
        
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
      
    	Test.startTest();

        testMobileAccount.Name = 'New Acc Name';
        TriggerHandler.clearAllBypasses();
        update testMobileAccount;
        
        Test.stopTest();
        
        Assert.isTrue([SELECT Id, Name FROM Account WHERE Id = :testMobileAccount.Id LIMIT 1].Name.contains('New Acc Name'));
    }
    
    @isTest
    static void testupdateDrivesForAccountNameChange() {
       	
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c = 'Test One Account';
        insert testMobileAccount; 
 
		sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;

        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;  
        
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;

        sked_Drive__c testDriveOnCalendar = new sked_Drive__c(
            Name = testMobileOpp.Name,
            sked_Opportunity__c = testMobileOpp.Id,
            sked_Zip_Code__c = '181124',
            sked_Account__c = testMobileAccount.Id,
            sked_Drive_Site__c = testMobileSite.Id,
            sked_Total_Procedures_Projected__c = testMobileOpp.Total_Projected_Procedures__c,
            sked_Drive_Productivity_Planned__c = 24,
            sked_2RBC_Projected_Procedures__c = 1);
        insert testDriveOnCalendar;
        
        Test.startTest();
        
        testMobileAccount.Name = 'New Acc Name';
        TriggerHandler.clearAllBypasses();
        update testMobileAccount;
        
        Test.stopTest();
        
         Assert.isTrue([SELECT Id, Name FROM sked_Drive__c WHERE Id = :testDriveOnCalendar.Id LIMIT 1].Name.contains('New Acc Name'));
    }
    
    //Test method for HRP-10085 ***ends here***
    @isTest static void testValidationForDaysOfWeekDeclined3()
    {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        
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
        
        
        System.runAs( new User (Id= UserInfo.getUserId()) ){
            insert DRDAMUser;
        }
        
        test.startTest();
        Account acc= [select Id,Name,Days_of_Week_Declined__c,Account_Strategy_Notes__c,National_Name__c,account_type_from_lead__c from Account where Name='testAcct01'];
        acc.Days_of_Week_Declined__c = 'Sunday;Monday';
        acc.Account_Strategy_Notes__c='test';
        //acc.National_Name__c='test one';
        acc.account_type_from_lead__c='test';
        acc.National_Name_Status__c = System.Label.Second_Review_Pending;
        update acc;

        Opportunity opportunities= [select Id,Name,Drive_Date__c from Opportunity where AccountId=:acc.Id LIMIT 1];
        opportunities.Drive_Date__c = Date.Today().addDays(3);
        opportunities.Drive_Date_Change_Reason__c = 'TEST';
        TriggerHandler.bypass('OpportunityTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        update opportunities;
        Date dt = opportunities.Drive_Date__c;
        DateTime myDateTime = (DateTime) dt;
        String dayOfWeek = myDateTime.format('EEEE');
        System.debug('dayOfWeek  : '+dayOfWeek); 
        
        acc.Days_of_Week_Declined__c ='Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday';
        acc.Account_Strategy_Notes__c='test';
        //acc.National_Name__c='test two';
        acc.account_type_from_lead__c='test';
        acc.National_Name_Status__c = System.Label.Review_Completed;

        TriggerHandler.clearAllBypasses();
        system.runAs(DRDAMUser)
        {
            try{
                skedHubBase.BypassInsertTriggers = true;
        		skedHubBase.BypassUpdateTriggers = true;
                TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
                update acc; 
            }catch(Exception ex) {
                Assert.isTrue(ex.getMessage().contains(System.Label.NationalNameCannotBeUpdatedAfterReview));
            }
           
        }   
        TriggerHandler.clearAllBypasses();
        test.stopTest();
    }
    
    static testmethod void testPopulateMarketOnAccount1()
    {
        Test.startTest();
        Account acc = [select Id from Account where BillingPostalCode = '30622'];
        acc.BillingPostalCode = '30146';
        update acc;
        
        Account afterUpdateObj = [select Id, Market__c from Account where Id =:acc.Id];
        
        Assert.areEqual('Marietta GA FS',afterUpdateObj.Market__c);
        Test.stopTest();
        
    }
    
    static testMethod void testOtherMethods2()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
      	Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        Test.startTest();
        
        // Mobile Account
        Account mobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        mobileAccount.Use_this_as_mailing_address__c = TRUE;
        mobileAccount.Account_Type_From_Lead__c = 'Business';
        insert mobileAccount;
        
        mobileAccount.Account_Type_From_Lead__c = 'Civic / Community';
        Update mobileAccount;
        
        Account afterUpdateObj = [select Id, Type,Account_Type_From_Lead__c from Account where Id =:mobileAccount.Id];
        Assert.areEqual('Business', afterUpdateObj.Type);
        
        afterUpdateObj.ShippingPostalCode = '90888';
        Update afterUpdateObj;
        Test.stopTest();
    }
    
    static testMethod void testValidationDaysofWeekDeclined4()
    {
        Test.startTest();
        Account accObj = [select Id from Account where BillingPostalCode = '30622'];
        accObj.Days_of_Week_Declined__c = 'Monday;Tuesday';
        accObj.Days_of_Week_Preferred__c = 'Monday';
       try
        {
        	update accObj;
        }catch(Exception ex)
        {
            Assert.isTrue(ex.getMessage().contains('Day of Week Declined and Days of Week Preferred not have same value'));
        }
        Test.stopTest();
        
    }
    
    static testMethod void testBlankNationalName()
    {
        Test.startTest();
        Account acc = new Account(name = 'Test Account 3',Internal_Name__c = 'Test',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Mobile Account').getRecordTypeId());
        TriggerHandler.bypass('AccountTriggerHandler');
        insert acc;
        TriggerHandler.clearAllBypasses();
        
        acc.National_Name__c = 'Test1';
        update acc;
        
        Account afterUpdateAcc = [Select Id, National_Name_Initial_Review_Date__c, National_Name_Status__c from Account where Id=:acc.Id];
        
        Assert.areEqual('Initial Review Pending',afterUpdateAcc.National_Name_Status__c);
        Test.stopTest();
        
    }
    
    
    static testMethod void testPopulateAccountTeamMembersByPortfolio1()
    {        
        Test.startTest();
        
        Account accObj = [Select Id from Account where Name='testAcct01' limit 1];

        // Create a taxonomy record
        Map <String,Schema.RecordTypeInfo> recordTypesadjustment = Taxonomy__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id RecTypeIdTax = recordTypesadjustment.get('Bio Recruitment CD').getRecordTypeId();        
        Date startDate1 = System.today().addMonths(-6);
        Date endDate1   = System.today().addMonths(4);    
        Date startDate2 = System.today().addMonths(2);
        Date endDate2   = System.today().addMonths(6);        
        
        List<Taxonomy__c> taxList = new List<Taxonomy__c>();
        Taxonomy__c tax1 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',
                                           DRD_Territory_Code__c='HProdSEMR_1836',DRD_Territory_Name__c='Detroit South 05',  
                                           DS_Region_Code__c='13Z18Z', DS_Region_Name__c='Michigan',   End_Date__c = endDate1,
                                           RecordTypeId=RecTypeIdTax, Start_Date__c=startDate1, Team_Code__c='MICH_Detroit S1',
                                           Team_Name__c='MICH_Detroit S1',Type__c='Bio Recruitment',  Version_Key__c=108.0, Zip_Code__c='48420');
        
        taxList.add(tax1);        
        insert taxList;
		BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit SM TEST';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit SM TEST';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        
        insert DMPortfolio;
        
        BSF_Portfolio__c AMPortfolioWithoutABM = new BSF_Portfolio__c();
        AMPortfolioWithoutABM.Portfolio_Name__c = 'Detroit South 07';
        AMPortfolioWithoutABM.Portfolio_Code__c = 'HProdSEMR_1837';
        AMPortfolioWithoutABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithoutABM.Territory_Portfolio__c = true;
        AMPortfolioWithoutABM.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithoutABM.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'MICH_Detroit SM TEST' AND Portfolio_Type__c = 'District Manager'].Id; 
        
        insert AMPortfolioWithoutABM;
        
		
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
       
        List<user> users = new List<user>();
        User u1 = new User(Alias = 'usr1', Email='drduser1@test.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = drdManagerProfile.Id, TimeZoneSidKey='America/Los_Angeles', UserName='drduser1@test.com.tst1');
        users.add(u1);
        
        system.runAs(new User(Id = UserInfo.getUserId()))
        {
        	insert users;
        }
        
        list<Portfolio_Assignment__c> paList=new list<Portfolio_Assignment__c>();
        Portfolio_Assignment__c am = new Portfolio_Assignment__c(BSF_Portfolio__c=DMPortfolio.Id,User__c=users[0].id,Start_Date__c=startDate1 ,End_Date__c=endDate1,Assignment_Type__c='District Manager');
        paList.add(am);
        insert paList;
	
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = userInfo.getUserId() ;
        atm.AccountId = accObj.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        AccountTeammember atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = users[0].Id ;
        atm2.AccountId = accObj.Id ;
        atm2.TeamMemberRole = 'Account Manager';
        atm2.Start_Date__c = System.today().addDays(-1);
        atm2.End_Date__c = System.today().addDays(10);
        atm2.Is_Covering_Recruiter__c = false;
        atm2.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm2);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
      
        List<Account_Portfolio_Assignment__c> accPortfolioAssignemnetList = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c accPortfolio1 = new Account_Portfolio_Assignment__c();
        accPortfolio1.BSF_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Type__c = 'Account Manager' AND Portfolio_Code__c = 'HProdSEMR_1837'].Id;
        accPortfolio1.Account__c = accObj.Id;
        accPortfolio1.Start_Date__c = SYstem.today();
        accPortfolio1.End_Date__c = System.today() +5;
        
        accPortfolioAssignemnetList.add(accPortfolio1);
       
        Insert accPortfolioAssignemnetList;        
        Map<Id, Account_Portfolio_Assignment__c> accIdAccPortfolioMap = new Map<Id, Account_Portfolio_Assignment__c>();

        for (Account_Portfolio_Assignment__c apa : accPortfolioAssignemnetList) {
            accIdAccPortfolioMap.put(apa.Id, apa);
        }
        // Call the method to test
        AccountService.populateAccountTeamMembersByPortfolio(accObj, taxList[0], 'Account Manager', paList, atmList, null, 'Called from AccountPortfolioAssignmentService', accIdAccPortfolioMap);
        AccountService.populateAccountTeamMembersByPortfolio(accObj, taxList[0], 'Account Manager', paList, atmList, null, 'ghy', accIdAccPortfolioMap);
        Test.stopTest();
    
	}
    
    // New Test Method for HRP - 9520
    static testmethod void testSetBusinessPlanningDateAndUserMethod() {
        
        Test.startTest();
        Account acc = [select Id, Business_Planning_Completed_By__c, Business_Planning_Completed__c, Business_Planning_Completed_Date__c from Account where BillingPostalCode = '30622'];
        acc.Business_Planning_Completed__c = TRUE ;
        update acc;
        
        Account afterUpdateObj = [select Id, Business_Planning_Completed_By__c, Business_Planning_Completed_Date__c from Account where Id =:acc.Id];
        
        Assert.areEqual(system.today(),afterUpdateObj.Business_Planning_Completed_Date__c);
        Assert.areEqual(UserInfo.getUserId() ,afterUpdateObj.Business_Planning_Completed_By__c);
        Test.stopTest();
    }
    
    static testmethod void testReturnStatements()
    {
        Test.startTest();
        AccountService.updateTemplateBloodDriveOpportunitiesForAccountNameChange(null,null);
        AccountService.updateDivesOnCalenderForAccountInternalNameChange(null,null);
        AccountService.setBusinessPlanningDateAndUser(null,null);
        Test.stopTest();
    }
    
}