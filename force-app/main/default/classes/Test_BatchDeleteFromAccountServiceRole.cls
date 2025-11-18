@isTest
public class Test_BatchDeleteFromAccountServiceRole {
    
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert DRD User
        User testDrdUser = (User)mapTestData.get('DRD_USER');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
 	   	//insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        testMobileAccount.Phone = '1234567890' ;
        testMobileAccount.Type = 'Business';
        testMobileAccount.Account_Manager__c = testDrdUser.Id;
        insert testMobileAccount;
        
        //insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.Id ;
        insert testContact;
        
        // insert account service role
        Account_Service_Role__c accConObj = new Account_Service_Role__c(
            Account__c = testMobileAccount.Id,
            Contact__c = testContact.Id,
            Account_Service_Role__c = 'Account Contact',
            End_Date__c = System.today().addDays(-1),
            Account_Service_End_Reason__c = 'No longer volunteering for ARC',
            Start_Date__c = system.today().addDays(-3)
        );
        insert accConObj;
    }
    
    @isTest
    static void test_BSF_BatchDeleteFromAccountServiceRole_schedule() {
        Test.startTest();
        
        BSF_BatchDeleteFromAccountServiceRole batchable = new BSF_BatchDeleteFromAccountServiceRole();
        String sch = '0 0 1 * * ?';
        system.schedule('Test Scheduler batch', sch, batchable);
        Test.stopTest();
        
        Assert.isTrue([SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name = 'Test Scheduler batch'].size() == 1);
    }
}