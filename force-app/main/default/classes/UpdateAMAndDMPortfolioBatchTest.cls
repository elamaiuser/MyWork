@isTest
public with sharing class UpdateAMAndDMPortfolioBatchTest {
    
    @testSetup
    static void prepareTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //Create DRD Users
        List<User> testUsers = new List<User>();
        testUsers.add((User)mapTestData.get('DRD_USER'));
        testUsers.add((User)mapTestData.get('DRD_MANAGER_USER'));
        User testDrdUser;
        
        testDrdUser = testUsers[1].clone();
        testDrdUser.LastName = 'LastTwo';
        testDrdUser.Email = 'puser0002@amamama.com';
        testDrdUser.Username = 'puser0002@amamama.com' + System.currentTimeMillis();
        testDrdUser.CompanyName = 'TEST2';
        testDrdUser.Title = 'title2';
        testDrdUser.Alias = 'alias2';
        testUsers.add(testDrdUser);
        
        testDrdUser = testUsers[1].clone();
        testDrdUser.LastName = 'LastOne';
        testDrdUser.Email = 'puser0001@amamama.com';
        testDrdUser.Username = 'puser0001@amamama.com' + System.currentTimeMillis();
        testDrdUser.CompanyName = 'TEST1';
        testDrdUser.Title = 'title1';
        testDrdUser.Alias = 'alias1';
        testUsers.add(testDrdUser);
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testUsers;
        } 
        
        //insert accounts
        List<Account> testAccounts = new List<Account>();
        Account testMobileAccount;
        testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        testMobileAccount.Phone = '1234567890' ;
        testMobileAccount.Type = 'Business';
        testAccounts.add(testMobileAccount);
        
        testMobileAccount = testAccounts[0].clone();
        testAccounts.add(testMobileAccount);
        insert testAccounts;
        
        // insert BSF Portfolio data
        List<BSF_Portfolio__c> bParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bportfolioList = new List<BSF_Portfolio__c>();
        
        BSF_Portfolio__c bportfolio ; 
        bportfolio = new BSF_Portfolio__c(
            Portfolio_Name__c = 'Non-Collection Area-54E',
            Portfolio_Code__c = 'Non-Collection Area-54E',
            Portfolio_Type__c = 'District Manager',
            Taxonomy_Type__c = 'Bio Account Portfolio',
            Account_Based_Portfolio__c = true
        );
        bParentportfolioList.add(bportfolio);
        insert bParentportfolioList;
        
        bportfolio = new BSF_Portfolio__c(
            Portfolio_Name__c = 'Non-Collection Area',
            Portfolio_Code__c = 'HProdSED_NCA',
            Portfolio_Type__c = 'Account Manager',
            Taxonomy_Type__c = 'Bio Account Portfolio',
            Parent_Portfolio__c = bParentportfolioList[0].Id,
            Account_Based_Portfolio__c = true
        );
        bportfolioList.add(bportfolio);
        insert bportfolioList;
        
        //insert account team members
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = testUsers[0].Id ;
        atm.AccountId = testAccounts[0].Id ;
        atm.TeamMemberRole = 'District Manager';
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().AddDays(2);
        atm.BSF_Portfolio__c = bportfolioList[0].Id;
        atmList.add(atm);
        
        atm = atmList[0].clone();
        atm.userId = testUsers[1].Id;
        atm.BSF_Portfolio__c = bParentportfolioList[0].Id;
        atmList.add(atm);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        insert atmList;
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert mobile opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
    }
    
    @isTest
    static void testUpdateAMAndDMOnAccountPortfolioBatch() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            Database.executeBatch(new UpdateAMAndDMOnAccountPortfolioBatch());
            Test.stopTest();
        } 
    }
    
    @isTest
    static void testUpdateAMAndDMOnOpportunityPortfolioBatch() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            Database.executeBatch(new UpdateAMAndDMOnOpportunityPortfolioBatch());
            Test.stopTest();
        }  
    }
}