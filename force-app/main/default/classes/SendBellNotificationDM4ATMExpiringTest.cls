@isTest
public class SendBellNotificationDM4ATMExpiringTest {
    
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('UserTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert DRD User
        User testDRDUser = (User)mapTestData.get('DRD_MANAGER_USER');
        testDRDUser.IsActive = true;
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDRDUser;
        }
         
        // insert Mobile Account
        List<Account> accListToInsert = new List<Account>();
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        testMObileAccount.District_Manager__c = testDRDUser.Id;
        insert testMobileAccount;
        
        // insert AccountTeamMembers
        AccountTeamMember testAccTeamMember = new AccountTeamMember(
        	AccountId = testMobileAccount.Id,
        	UserId = testDRDUser.Id,
        	TeamMemberRole = 'District Manager',
        	Start_Date__c = system.today(),
        	End_Date__c = system.today().addDays(3),
        	Is_Covering_Recruiter__c = false,
            CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit'
        );
        
        bsf_constants.isTeamMemberCreatedFromBackend = true;
        insert testAccTeamMember;
        bsf_constants.isTeamMemberCreatedFromBackend = false;
    }
    
	static testMethod void batchTest() {
        Test.startTest();
        
        BellNotificationDM4ATMExpiryScheduler amExpBellNotificationSch = new BellNotificationDM4ATMExpiryScheduler(100);
		System.schedule('Notify DM 4 AM Expiry Batch Test', '0 30 0 * * ?', amExpBellNotificationSch);
        
        SendBellNotificationDM4ATMExpiring3days batchInstance = new SendBellNotificationDM4ATMExpiring3days();
        Database.executeBatch(batchInstance);
        
        Test.stopTest();
        
        List<BSF_Custom_Notification__c> testBsfCustomNotificationRecord = [SELECT Id FROM BSF_Custom_Notification__c WHERE Category__c = 'AccountTeamMemberExpiry'];
        Assert.isTrue(testBsfCustomNotificationRecord != null && !testBsfCustomNotificationRecord.isEmpty());
    }
}