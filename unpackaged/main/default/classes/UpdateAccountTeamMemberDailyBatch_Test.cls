@isTest
public class UpdateAccountTeamMemberDailyBatch_Test {
    public static String rolename = 'West_BDM';
    
    @testSetup
    public static void testSetup()
    {
        //create account
        List<Account> mobileAccList = new List<Account>();        
        Account accobj = new Account();
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';
		mobileAccList.add(accobj);
        Account accobj1 = new Account();
        accobj1.Name = 'TEsdt';
        accobj1.BillingPostalCode = '30146';        
        mobileAccList.add(accobj1);
		insert mobileAccList;
    }
    
    @isTest
    Public static void Test_Schedule_Class()
    {
        Test.StartTest();
		AccountTeamMemberDailyBatchScheduler testsche = new AccountTeamMemberDailyBatchScheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
        UpdateATMDailyBatchScheduler testsche1 = new UpdateATMDailyBatchScheduler(200);
		String sch1 = '0 0 23 * * ?';
		system.schedule('Test schedule class1', sch1, testsche1 );
		Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class');
    }
    
    @isTest
    public static void testUpdateAccTeamMember1 ()
    {
        List<Account> mobileAccList = [select id from account where name IN('Exavalu','TEsdt')];
        system.debug('mobileAccList'+mobileAccList.size());
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
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
		
		integer i =0;
        // insert Account Team and add DRDAMUser
		List<AccountTeammember> atmList = new List<AccountTeammember>();
        for(account acc : mobileAccList)
        {
            boolean coverage =true;
        
            if (i==1)
            {
                coverage =false;
            }
		AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = acc.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = coverage;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        AccountTeammember atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = AdminUser.Id ;
        atm2.AccountId = acc.Id ;
        atm2.TeamMemberRole = 'Account Manager';
        atm2.Start_Date__c = System.today().addDays(-1);
        atm2.End_Date__c = System.today().addDays(10);
        atm2.Is_Covering_Recruiter__c = coverage;
        atm2.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm2);
            i++;
        }
        
        
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        AccountTeammember ateam = [select Is_Covering_Recruiter__c from AccountTeammember where accountid=:mobileAccList[0].id limit 1];
        system.debug('ateam'+ateam);
        System.runAs( DRDAMUser){
            Test.startTest();
            UpdateAccountTeamMemberDailyBatch batchUpdate = new UpdateAccountTeamMemberDailyBatch();
            database.executeBatch(batchUpdate);
            Test.stopTest();
        }
    }
	
    @isTest static void testUpdateAccTeamMember2 ()
    {
        List<Account> mobileAccList = [select id from account where name = 'Exavalu' or name = 'TEsdt'];
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
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
		
		integer i =0;
        // insert Account Team and add DRDAMUser
		List<AccountTeammember> atmList = new List<AccountTeammember>();
        for(account acc : mobileAccList)
        {
            boolean coverage =true;
        
            if (i==1)
            {
                coverage =false;
            }
		AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = acc.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = coverage;
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        
        AccountTeammember atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = AdminUser.Id ;
        atm2.AccountId = acc.Id ;
        atm2.TeamMemberRole = 'Account Manager';
        atm2.Start_Date__c = System.today().addDays(-1);
        atm2.End_Date__c = System.today().addDays(10);
        atm2.Is_Covering_Recruiter__c = coverage;
        atm2.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm2);
            i++;
        }
        
        
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        AccountTeammember ateam = [select Is_Covering_Recruiter__c from AccountTeammember where accountid=:mobileAccList[0].id limit 1];
        system.debug('ateam'+ateam);
        System.runAs( DRDAMUser){
            Test.startTest();
            UpdateAccountTeamMemberDailyBatch batchUpdate = new UpdateAccountTeamMemberDailyBatch();
            database.executeBatch(batchUpdate);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testUpdateAccTeamMember3 ()
    {
        Account acc = [select id from account Limit 1];
       
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
       
        id prfId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id;
        list<user> userList = new list<user>();
        for(integer i = 0;i<4;i++)
        {
            User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last'+i,
             Email = 'puser'+i+'000@amamama.com',
             Username = 'puser000'+i+'@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST'+i,
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );       
            userList.add(DRDAMUser);
        }
        
        
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
        
        System.runAs( AdminUser ){
            insert userList;
        }
		
		
        // insert Account Team and add DRDAMUser
		List<AccountTeammember> atmList = new List<AccountTeammember>();
        
		AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = userList[0].Id ;
        atm.AccountId = acc.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        AccountTeammember atm1 = new AccountTeammember();
        atm1.AccountAccessLevel = 'Edit';
        atm1.CaseAccessLevel = 'Edit';
        atm1.OpportunityAccessLevel = 'Edit';
        atm1.userId = AdminUser.Id ;
        atm1.AccountId = acc.Id ;
        atm1.TeamMemberRole = 'Account Manager';
        atm1.Start_Date__c = System.today().addDays(-1);
        atm1.End_Date__c = System.today().addDays(10);
        atm1.is_Covering_Recruiter__c = true;
        atm1.coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm1);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        atmList.clear();
        
		AccountTeammember atm2;
        atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = userList[1].Id ;
        atm2.AccountId = acc.Id ;
        atm2.TeamMemberRole = 'District Manager';
        atm2.Start_Date__c = System.today().addDays(-10);
        atm2.End_Date__c = System.today().addDays(6);
        atm2.Is_Covering_Recruiter__c = false;
        atm2.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm2);
        
        AccountTeammember atm3 = new AccountTeammember();
        atm3.AccountAccessLevel = 'Edit';
        atm3.CaseAccessLevel = 'Edit';
        atm3.OpportunityAccessLevel = 'Edit';
        atm3.userId = userList[2].Id ;
        atm3.AccountId = acc.Id ;
        atm3.TeamMemberRole = 'Account Manager';
        atm3.Start_Date__c = System.today().addDays(-1);
        atm3.End_Date__c = System.today().addDays(10);
        atm3.Is_Covering_Recruiter__c = false;
        atm3.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm3);
            
        
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        
        System.runAs( userList[2]){
            Test.startTest();
            UpdateAccountTeamMemberDailyBatch batchUpdate = new UpdateAccountTeamMemberDailyBatch();
            database.executeBatch(batchUpdate);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void AccountTeamMemberHelperTest1 ()
    {
        List<Account> mobileAccList = [select id from account where name IN('Exavalu','TEsdt')];
        system.debug('mobileAccList'+mobileAccList.size());
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
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
		
		integer i =0;
        // insert Account Team and add DRDAMUser
		List<AccountTeammember> atmList = new List<AccountTeammember>();
        for(account acc : mobileAccList)
        {
            boolean coverage =true;
        
            if (i==1)
            {
                coverage =false;
            }
		AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = acc.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = coverage;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        AccountTeammember atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = AdminUser.Id ;
        atm2.AccountId = acc.Id ;
        atm2.TeamMemberRole = 'Account Manager';
        atm2.Start_Date__c = System.today().addDays(-1);
        atm2.End_Date__c = System.today().addDays(10);
        atm2.Is_Covering_Recruiter__c = coverage;
        atm2.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm2);
            i++;
        }
        
        
        
        
        insert atmList;
        
        AccountTeammember ateam = [select Is_Covering_Recruiter__c from AccountTeammember where accountid=:mobileAccList[0].id limit 1];
        system.debug('ateam'+ateam);
        
            Test.startTest();
            AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[0].Id});
            AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[1].Id});
            Test.stopTest();
        
    }
    
    @isTest static void AccountTeamMemberHelperTest2 ()
    {
        List<Account> mobileAccList = [select id from account where name = 'Exavalu' or name = 'TEsdt'];
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
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
		
		integer i =0;
        // insert Account Team and add DRDAMUser
		List<AccountTeammember> atmList = new List<AccountTeammember>();
        for(account acc : mobileAccList)
        {
            boolean coverage =true;
        
            if (i==1)
            {
                coverage =false;
            }
		AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = acc.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = coverage;
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        
        AccountTeammember atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = AdminUser.Id ;
        atm2.AccountId = acc.Id ;
        atm2.TeamMemberRole = 'Account Manager';
        atm2.Start_Date__c = System.today().addDays(-1);
        atm2.End_Date__c = System.today().addDays(10);
        atm2.Is_Covering_Recruiter__c = coverage;
        atm2.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm2);
            i++;
        }
        
        
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        AccountTeammember ateam = [select Is_Covering_Recruiter__c from AccountTeammember where accountid=:mobileAccList[0].id limit 1];
        system.debug('ateam'+ateam);
        
            Test.startTest();
            AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[0].Id});
            AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[1].Id});
            Test.stopTest();
        
    }
    
     @isTest
    public static void AccountTeamMemberHelperTest3 ()
    {
        Account acc = [select id from account Limit 1];
       
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
       
        id prfId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id;
        list<user> userList = new list<user>();
        for(integer i = 0;i<4;i++)
        {
            User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last'+i,
             Email = 'puser'+i+'000@amamama.com',
             Username = 'puser000'+i+'@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST'+i,
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );       
            userList.add(DRDAMUser);
        }
        
        
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
        
        System.runAs( AdminUser ){
            insert userList;
        }
		
		
        // insert Account Team and add DRDAMUser
		List<AccountTeammember> atmList = new List<AccountTeammember>();
        
		AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = userList[0].Id ;
        atm.AccountId = acc.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        AccountTeammember atm1 = new AccountTeammember();
        atm1.AccountAccessLevel = 'Edit';
        atm1.CaseAccessLevel = 'Edit';
        atm1.OpportunityAccessLevel = 'Edit';
        atm1.userId = AdminUser.Id ;
        atm1.AccountId = acc.Id ;
        atm1.TeamMemberRole = 'Account Manager';
        atm1.Start_Date__c = System.today().addDays(-1);
        atm1.End_Date__c = System.today().addDays(10);
        atm1.is_Covering_Recruiter__c = true;
        atm1.coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm1);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        atmList.clear();
        
		AccountTeammember atm2;
        atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = userList[1].Id ;
        atm2.AccountId = acc.Id ;
        atm2.TeamMemberRole = 'District Manager';
        atm2.Start_Date__c = System.today().addDays(-10);
        atm2.End_Date__c = System.today().addDays(6);
        atm2.Is_Covering_Recruiter__c = false;
        atm2.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm2);
        
        AccountTeammember atm3 = new AccountTeammember();
        atm3.AccountAccessLevel = 'Edit';
        atm3.CaseAccessLevel = 'Edit';
        atm3.OpportunityAccessLevel = 'Edit';
        atm3.userId = userList[2].Id ;
        atm3.AccountId = acc.Id ;
        atm3.TeamMemberRole = 'Account Manager';
        atm3.Start_Date__c = System.today().addDays(-1);
        atm3.End_Date__c = System.today().addDays(10);
        atm3.Is_Covering_Recruiter__c = false;
        atm3.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm3);
            
        
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        
        System.runAs( userList[2]){
            Test.startTest();
             AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[0].Id});
            AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[1].Id});
            Test.stopTest();
        }
    }
    
     @isTest
    public static void AccountTeamMemberHelperTest4 ()
    {
        Account acc = [select id from account Limit 1];
        
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
       
        id prfId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id;
        list<user> userList = new list<user>();
        for(integer i = 0;i<4;i++)
        {
            User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last'+i,
             Email = 'puser'+i+'000@amamama.com',
             Username = 'puser000'+i+'@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST'+i,
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );       
            userList.add(DRDAMUser);
        }
        
        
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
        
        System.runAs( AdminUser ){
            insert userList;
        }
		
		
        // insert Account Team and add DRDAMUser
		List<AccountTeammember> atmList = new List<AccountTeammember>();
        
		AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = userList[0].Id ;
        atm.AccountId = acc.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        AccountTeammember atm1 = new AccountTeammember();
        atm1.AccountAccessLevel = 'Edit';
        atm1.CaseAccessLevel = 'Edit';
        atm1.OpportunityAccessLevel = 'Edit';
        atm1.userId = AdminUser.Id ;
        atm1.AccountId = acc.Id ;
        atm1.TeamMemberRole = 'Account Manager';
        atm1.Start_Date__c = System.today().addDays(-10);
        atm1.End_Date__c = System.today().addDays(10);
        atm1.is_Covering_Recruiter__c = false;
        //atm1.coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm1);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        atmList.clear();
        
		AccountTeammember atm2;
        atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = userList[1].Id ;
        atm2.AccountId = acc.Id ;
        atm2.TeamMemberRole = 'District Manager';
        atm2.Start_Date__c = System.today().addDays(-10);
        atm2.End_Date__c = System.today().addDays(6);
        atm2.Is_Covering_Recruiter__c = false;
        atm2.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm2);
        
        AccountTeammember atm3 = new AccountTeammember();
        atm3.AccountAccessLevel = 'Edit';
        atm3.CaseAccessLevel = 'Edit';
        atm3.OpportunityAccessLevel = 'Edit';
        atm3.userId = userList[2].Id ;
        atm3.AccountId = acc.Id ;
        atm3.TeamMemberRole = 'Account Manager';
        atm3.Start_Date__c = System.today().addDays(-1);
        atm3.End_Date__c = System.today().addDays(-10);
        atm3.Is_Covering_Recruiter__c = true;
        atm3.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm3);
            
        
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        
        System.runAs( userList[2]){
            Test.startTest();
             AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[0].Id});
            AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[1].Id});
            Test.stopTest();
        }
    }
    @isTest
    public static void AccountTeamMemberHelperTest5 ()
    {
        Account acc = [select id from account Limit 1];
        
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
       
        id prfId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id;
        list<user> userList = new list<user>();
        for(integer i = 0;i<4;i++)
        {
            User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last'+i,
             Email = 'puser'+i+'000@amamama.com',
             Username = 'puser000'+i+'@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST'+i,
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );       
            userList.add(DRDAMUser);
        }
        
        
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
        
        System.runAs( AdminUser ){
            insert userList;
        }
		
		
        // insert Account Team and add DRDAMUser
		List<AccountTeammember> atmList = new List<AccountTeammember>();
        
		AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = userList[0].Id ;
        atm.AccountId = acc.Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        AccountTeammember atm1 = new AccountTeammember();
        atm1.AccountAccessLevel = 'Edit';
        atm1.CaseAccessLevel = 'Edit';
        atm1.OpportunityAccessLevel = 'Edit';
        atm1.userId = AdminUser.Id ;
        atm1.AccountId = acc.Id ;
        atm1.TeamMemberRole = 'Account Manager';
        atm1.Start_Date__c = System.today().addDays(-10);
        atm1.End_Date__c = System.today().addDays(-2);
        atm1.is_Covering_Recruiter__c = false;
        //atm1.coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm1);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        atmList.clear();
        
		AccountTeammember atm2;
        atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = userList[1].Id ;
        atm2.AccountId = acc.Id ;
        atm2.TeamMemberRole = 'District Manager';
        atm2.Start_Date__c = System.today().addDays(-10);
        atm2.End_Date__c = System.today().addDays(6);
        atm2.Is_Covering_Recruiter__c = false;
        atm2.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm2);
        
        AccountTeammember atm3 = new AccountTeammember();
        atm3.AccountAccessLevel = 'Edit';
        atm3.CaseAccessLevel = 'Edit';
        atm3.OpportunityAccessLevel = 'Edit';
        atm3.userId = userList[2].Id ;
        atm3.AccountId = acc.Id ;
        atm3.TeamMemberRole = 'Account Manager';
        atm3.Start_Date__c = System.today().addDays(-1);
        atm3.End_Date__c = System.today().addDays(-10);
        atm3.Is_Covering_Recruiter__c = true;
        atm3.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm3);
            
        
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        
        System.runAs( userList[2]){
            Test.startTest();
             AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[0].Id});
            AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{atmList[1].Id});
            Test.stopTest();
        }
    }
}