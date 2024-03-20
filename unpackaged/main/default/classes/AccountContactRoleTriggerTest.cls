@isTest
public class AccountContactRoleTriggerTest {
    
    @isTest
    static void testAccountContactRoleTrigger(){
        /*Test.enableChangeDataCapture();
          Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();

         Id MobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        Account mobileAcc = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            District_Manager__c = UserInfo.getUserId(),
        	BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420'
        );
       Contact contact = new Contact(
            firstname = 'Test Contact First 1',
            lastname = 'Test Contact Last 1',
            Email = 'testContact@gmail.com',
            Original_Service_Date__c = system.today().addDays(3),
           	Primary_Phone__c = 'Mobile Phone',
            MobilePhone = '888-888-8888',
        	MailingStreet = '2204 Westcrt ln, Apt 213',
        	MailingCity = 'Herndon',
        	MailingStateCode = 'MI',
        	MailingPostalCode = '48420'
        );
           
        	insert mobileAcc;
            System.debug('Ater mobile account is inserted '+mobileAcc.Id);
         contact.AccountId = mobileAcc.Id;
        	insert contact;
       
       
        Account acc = [select id from Account where name = 'Test Account 1' limit 1];
        Contact cntct = [select id from Contact where Email = 'testContact@gmail.com'];
        Test.startTest();
        insert(new account_service_role__c (Account__c = acc.id,contact__c=cntct.id));
        Test.getEventBus().deliver();
        //AccountContactRoleChangeEvent changeEvent = new AccountContactRoleChangeEvent(AccountId=acc.Id,ContactId=cntct.Id,Role='Account Contact');
        //insertAsync changeEvent;
      //Test.getEventBus().deliver();
       // insertAsync  changeEvent;
                Test.stopTest();
*/
    }

}