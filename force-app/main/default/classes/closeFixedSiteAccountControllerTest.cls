/* The following test class covers below mentioned apex classes
 * closeFixedSiteAccountController
 
@Created : 2/26/2024  Priti Jana
****************************************************************************************************/

@isTest(SeeAllData = False)
public class closeFixedSiteAccountControllerTest {
    
    @testSetup
    static void prepareDataSet() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        List<Account> accList = new List<Account>();
        
        // Account Preparation
        Account testFixedAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        insert testFixedAccount;
        
        // insert FS Location
        sked__Location__c testSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        insert testSite;
        
        //insert Fixed Opp 1
        Opportunity testFixedOpp = (Opportunity)mapTestData.get('FIXED_OPP');
        testFixedOpp.accountId = testFixedAccount.Id;
        testFixedOpp.Drive_Site__c = testSite.Id;
        testFixedOpp.Online_Scheduling_Enabled__c = 'Yes';
        insert testFixedOpp;
     }
    
    static testmethod void testFetchAccountDetailsMethod() {
        Test.startTest();
        Account fsAcc = [SELECT Id, Name, Account_status__c, Closure_Reason__c, Defunct_Effective_Date__c FROM Account LIMIT 1];
        Account returnedAcc = closeFixedSiteAccountController.fetchFSAccountDetails(String.valueOf(fsAcc.Id));
        Assert.isTrue(returnedAcc.Account_status__c != BSF_Constants.ACCOUNT_STATUS_CLOSED);                                                                                   
        Test.stopTest();
    }
    
    static testmethod void testCancelOppsMethods() {
        Test.startTest();
        Account fsAcc = [SELECT Id, Name, Account_status__c, Closure_Reason__c, Defunct_Effective_Date__c FROM Account LIMIT 1];
        Integer oppListCount = closeFixedSiteAccountController.getTotalNonCancelledFutureOpportunities(String.valueOf(fsAcc.Id), system.today().addDays(-2));
        closeFixedSiteAccountController.cancelOpportunitiesOnFSAccountClosure(String.valueOf(fsAcc.Id), system.today().addDays(-2), 'TEST');
        Assert.isTrue(oppListCount > 0);                                                                                   
        Test.stopTest();
    }
    
    static testmethod void testCloseFSAccountMethod() {
        Test.startTest();
        Account fsAcc = [SELECT Id, Name, Account_status__c, Closure_Reason__c, Defunct_Effective_Date__c FROM Account LIMIT 1];
        String result = closeFixedSiteAccountController.closeFSAccount(String.valueOf(fsAcc.Id),system.today().addDays(-2), 'TEST');
        Assert.isTrue(result == String.valueOf(Custom_Messages__mdt.getInstance('FS_Account_Closure_Msg').Value__c));                                                                                   
        Test.stopTest();
    }

}