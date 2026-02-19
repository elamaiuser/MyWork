@isTest
private class DMBellNotificationATMBatchHelperTest {
    
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, sObject> mapTestData = testDataSetup.createAndInsertCommonObjects();
        
        User testDRDUser = (User)mapTestData.get('DRD_MANAGER_USER');
        testDRDUser.IsActive = true;
        
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDRDUser;
        }
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c = 'TEST';
        testMobileAccount.District_Manager__c = testDRDUser.Id;
        insert testMobileAccount;
        
        AccountTeamMember testAccTeamMember = new AccountTeamMember(
        	CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'District Manager',
            Start_Date__c = System.today(),
            End_Date__c = System.today() + 3,
            Is_Covering_Recruiter__c = false,
            UserId = testDRDUser.Id,
            AccountId = testMobileAccount.Id
        );
        insert testAccTeamMember;   
    }
    
    static testMethod void test() {
        Test.startTest();
        
        List<AccountTeamMember> atmList = [SELECT Id FROM AccountTeamMember WHERE Account.Internal_Name__c = 'TEST'];
        
        DMBellNotificationATMExpiryBatchSchedule amExpBellNotificationSch = new DMBellNotificationATMExpiryBatchSchedule(100);
		System.schedule('Test Notify DM 4 AM Expiry Batch', '0 30 0 * * ?', amExpBellNotificationSch );
        
        
        DMBellNotificationForATMExpiryBatch batchInstance = new DMBellNotificationForATMExpiryBatch();
        Id jobId = Database.executeBatch(batchInstance);
        
        Test.stopTest();
        Assert.isTrue(jobId != null);
    }
}