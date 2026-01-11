/**
 * This Class contains testMethods for AccountContactHistoryService
 * 
 * */
@isTest(SeeAllData = false)
private class Test_AccountContactHistoryService {
    
    @testSetup static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
       
        // insert Contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.Id;
        insert testContact;
    }
    
    @isTest static void testInsertAccountServiceRole() {
       	Test.startTest();
		
        Account_Service_Role__c serviceRole = new Account_Service_Role__c(
            Account_Service_Role__c='Blood Program Leader',
            Account__c = [SELECT Id FROM Account LIMIT 1].Id,
            Contact__c = [SELECT Id FROM Contact LIMIT 1].Id
        );
        insert serviceRole;
        
        //Inserting service role should have inserted account contact history
        List<Account_Contact_History__c> accountContactHistoryList  = [SELECT Id FROM Account_Contact_History__c];
        Assert.isTrue(accountContactHistoryList.size() == 2);
    	serviceRole.Start_Date__c = System.today();
        upsert serviceRole; //BPL->BPL should not cause any errors
        
        Test.stopTest();
    }
    
    @isTest static void testDeleteAccountServiceRole() {
        Test.startTest();
		
        Account_Service_Role__c serviceRole = new Account_Service_Role__c(
            Account_Service_Role__c='Blood Program Leader',
            Account__c = [SELECT Id FROM Account LIMIT 1].Id,
            Contact__c = [SELECT Id FROM Contact LIMIT 1].Id
        );
        insert serviceRole;
        delete serviceRole;
       
        List<Account_Contact_History__c> accountContactHistoryList  = [SELECT Id FROM Account_Contact_History__c];
        
        Test.stopTest();
        Assert.isTrue(accountContactHistoryList.size() == 3);
    }
    
    @isTest static void testAccountServiceRoleBPLValidation() {
        Test.startTest();
		
        Account testAccount = [SELECT Id, Account_Type_From_Lead__c FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Account_Service_Role__c serviceRole;
        serviceRole = new Account_Service_Role__c(
            Account_Service_Role__c='Blood Program Leader',
            Account__c = testAccount.Id,
            Contact__c = testContact.Id
        );
        insert serviceRole;
        
        serviceRole = new Account_Service_Role__c(
            Account_Service_Role__c='Blood Program Leader',
            Account__c = testAccount.Id,
            Contact__c = testContact.id
        );
        
        try {
            insert serviceRole;
        }
        catch(System.DmlException de) {
            Assert.isTrue(de.getMessage().contains(' Overlapping dates detected.'));
        }
        
        testAccount.Account_Type_From_Lead__c = 'Health';
        upsert testAccount;       
    }
}