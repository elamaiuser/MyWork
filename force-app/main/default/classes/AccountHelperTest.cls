/***
* Name: AccountHelperTest
* Description:  Test Class for AccountHelper
* Author: Anil K
* Date: 11/21/2022
* 
* */

@isTest
public class AccountHelperTest {
 public  static Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();

    @isTest
    public static void testCleanBillingAddress(){
        
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
        

       insert mobileAcc;
    }

}