/**
 * This Class contains testMethods for AccountContactHistoryService
 * 
 * */
@isTest(SeeAllData = false)
public class Test_AccountContactHistoryService {
    
    
    @testSetup static void setUpData() {
        
        Account acc = new Account(name='Test Account');
        insert acc;
         acc.BillingStreet = '2204 Westcrt ln, Apt 213'; //misspell street
         acc.BillingCity = 'Herndon';
         acc.BillingStateCode = 'VA';
         acc.BillingPostalCode = '20170';
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; //misspell street
         contact.MailingCity = 'Herndon';
         contact.MailingStateCode = 'VA';
         contact.MailingPostalCode = '20170';
         contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
        contact.AccountId = acc.id;
        contact.Email = 'testContact@gmail.com';
		contact.Original_Service_Date__c = system.today().addDays(3);
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
        insert contact;
        
    }
    
    @isTest static void testInsertAccountServiceRole(){
       
		Account accObj = [select id, Account_Type_From_Lead__c from Account where name='Test Account' limit 1];
        Contact conObj = [select id from Contact where firstname='Test Contact First' limit 1];
        
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = accObj.id;
        serviceRole.Contact__c = conObj.id;
        insert serviceRole;
        
        //Inserting service role should have inserted account contact history
        List<Account_Contact_History__c> accountContactHistoryList  = [select id from Account_Contact_History__c];
        for(Account_Contact_History__c history:accountContactHistoryList){
                    System.debug('accountContactHistory->'+history);

        }
        System.debug('accountContactHistoryList size->'+accountContactHistoryList.size());
        System.assert(accountContactHistoryList.size() ==2);//two account service roles will be created 1. by default from process builder and 2. from this method
    	serviceRole.Start_Date__c = System.today();
        upsert serviceRole;//BPL->BPL should not cause any errors
    }
    
    @isTest static void testDeleteAccountServiceRole(){
        Account accObj = [select id, Account_Type_From_Lead__c from Account where name='Test Account' limit 1];
        Contact conObj = [select id from Contact where firstname='Test Contact First' limit 1];
        
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = accObj.id;
        serviceRole.Contact__c = conObj.id;
        insert serviceRole;
        delete serviceRole;

        //Inserting and deleting service role should have inserted two records in account contact history, one for delete and one for insert
        // One extra record will also be created for Account Contact History as one account service role will be created by default from process builder
        List<Account_Contact_History__c> accountContactHistoryList  = [select id from Account_Contact_History__c];
        System.debug('accountContactHistoryList size->'+accountContactHistoryList.size());

        System.assert(accountContactHistoryList.size() ==3); // count will be 3
    }
    
    
        @isTest static void testAccountServiceRoleBPLValidation(){
        Account accObj = [select id, Account_Type_From_Lead__c from Account where name='Test Account' limit 1];
        Contact conObj = [select id, firstname from Contact where firstname='Test Contact First' limit 1];
            
        Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';  
        serviceRole.Account__c = accObj.id;
        serviceRole.Contact__c = conObj.id;
        insert serviceRole;
            
        Account_Service_Role__c serviceRole2 = new Account_Service_Role__c();
        serviceRole2.Account_Service_Role__c='Blood Program Leader';//Assigning second contact with same role with trigger error
        serviceRole2.Account__c = accObj.id;
        serviceRole2.Contact__c = conObj.id;
            try{
               insert serviceRole2;
               System.assert(true == false, 'Error should have been raised');
            }
            catch(System.DmlException de){
                System.assert(de.getMessage().contains('Account associated with this Account Service Role already has Valid BPL, only maximum of one valid BPL can be present'));
            }
         accObj.Account_Type_From_Lead__c = 'Health';
         upsert accObj;  
            
        //Inserting and deleting service role should have inserted two records in account contact history, one for delete and one for insert
        
            
            
    }


}