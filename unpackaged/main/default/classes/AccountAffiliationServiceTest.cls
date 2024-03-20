@isTest
public class AccountAffiliationServiceTest {
    @testSetup
    public static void DataSetup(){
        Test.startTest();   
        
        List<Account> accList = new List<Account>();
        Account acc = new account(name='testAccount',IsPumpedItUpCurrent__c = true);
        Account acc1 = new account(name='testAccount1',IsPremierCurrent__c = true);
        accList.add(acc);
        accList.add(acc1);
        insert accList; 
        
        Id RccognitionId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Sponsor Recognition').getRecordTypeId();
        list<Marketing_Program__c> mpclist = new list<Marketing_Program__c>();
        Marketing_Program__c mp = new Marketing_Program__c(Name = label.Premier_Bonus_Current, 
                                                            Scope__c = 'account' ,
                                                            RecordTypeId=RccognitionId,Drive_Type__c = 'N/A',External_Name__c = 'Test Account Marketing Program');
        mpclist.add(mp);
        Marketing_Program__c mp1 = new Marketing_Program__c(Name = label.PremierCurrent, 
                                                                Scope__c = 'account',
                                                                RecordTypeId=RccognitionId,Drive_Type__c = 'N/A',External_Name__c = 'Test Account Marketing Program1');
        mpclist.add(mp1);

        insert mpclist;
        
        List<Account_Marketing_Program__c> newAmpList = new List<Account_Marketing_Program__c>();
        Account_Marketing_Program__c amp = new Account_Marketing_Program__c(Account__c =acc.Id, Marketing_Program__c = mp.Id, Account_Affiliation_External_Key__c =String.valueOf(System.now()+100));
        Account_Marketing_Program__c amp1 = new Account_Marketing_Program__c(Account__c =acc1.Id, Marketing_Program__c = mp1.Id, Account_Affiliation_External_Key__c=String.valueOf(System.now()+200));
        newAmpList.add(amp);
        newAmpList.add(amp1);
        insert newAmpList;
        System.debug('Account_Affiliation_External_Key__c is -> '+[Select Account_Affiliation_External_Key__c from Account_Marketing_Program__c]);
        test.stopTest();
        
        
    } 
   @isTest
    public static void AccountFlagForPumpItUpCurrent(){
        list<Account_Marketing_Program__c> NewList = [SELECT Id, Name,Marketing_Program__c,Account__c,
                                                      Start_Date__c, End_Date__c, Date_Assigned__c,Marketing_Program__r.RecordType.Name,Marketing_Program__r.Name,
                                                      Date_Removed__c from Account_Marketing_Program__c where Marketing_Program__r.RecordType.Name='Sponsor Recognition'
                                                      AND Marketing_Program__r.Name in ('Pump It Up Current','Premier Current')];
		system.assert( NewList != null );
      AccountAffiliationService.AccountFlagForPumpItUpCurrent(NewList, 'Insert');  
    }  
    @isTest
    public static void createHistoryOnAccAffiliationTest(){
        list<Account_Marketing_Program__c> ampList = [SELECT Id, Name,Marketing_Program__c,Account__c,CreatedDate,
                                                      Start_Date__c, End_Date__c, Date_Assigned__c,Assigned_By__c,
                                                      Date_Removed__c,Removed_By__c from Account_Marketing_Program__c];
		system.assert( ampList != null );
        AccountAffiliationService.createHistoryOnAccAffiliation(ampList, 'Insert');
        
        Database.Update(ampList);
        AccountAffiliationService.createHistoryOnAccAffiliation(ampList, 'Update');
        
        Database.Delete(ampList);
        AccountAffiliationService.createHistoryOnAccAffiliation(ampList, 'Delete'); 
        
        
        
        
    }
}