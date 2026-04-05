@isTest(SeeAllData = false)
private class BsfPortfolioSyncHelper_Test {
    
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
		TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        User testDrdUser = (User)mapTestData.get('DRD_MANAGER_USER');
        testDrdUser.IsActive = true;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c = 'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        List<AccountTeamMember> testAccTeamMembers = new List<AccountTeamMember>();
        AccountTeamMember testAccTeamMember;
        testAccTeamMember = new AccountTeamMember(
        	AccountAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'Account Manager',
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            AccountId = testMobileAccount.Id,
            UserId = UserInfo.getUserId(),
            Is_Covering_Recruiter__c = false
        );
        testAccTeamMembers.add(testAccTeamMember);
        
        testAccTeamMember = new AccountTeamMember(
        	AccountAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'District Manager',
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            AccountId = testMobileAccount.Id,
            UserId = [SELECT Id FROM User WHERE Profile.Name = 'DRD Manager' AND IsActive = true LIMIT 1].Id,
            Is_Covering_Recruiter__c = false
        );
        testAccTeamMembers.add(testAccTeamMember);
        insert testAccTeamMembers;
    }
    
    static testMethod void accIdexistingUserIdMap_test() {
        Test.startTest();
        Id testMobileAccountId = [SELECT Id FROM Account WHERE Internal_Name__c = 'TEST ACCOUNT 1' LIMIT 1].Id;
        Map<Id,List<Id>> testAccExistingUserMap = BsfPortfolioSyncHelper.accIdexistingUserIdMap(new Set<Id>{testMobileAccountId});
        Test.stopTest();
        
        Assert.isTrue(testAccExistingUserMap != null && !testAccExistingUserMap.isEmpty());
    }

}