@isTest
public class MassAssignAccBasedPortfolioClass_Test 
{
    @testSetup
    public static void testSetupMethod()
    {
        list<user> userList = new list<user>();
        User nonEligibleUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'nonEligibleUser',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );
        userList.add(nonEligibleUser);
        
        User nonEligibleDRDUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'nonEligibleDRDUser',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );
        userList.add(nonEligibleDRDUser);
        
        insert userList;
        
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Account mobileAcc1 = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420'
        );
        Account mobileAcc2 = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48421'
        );
        accList.add(mobileAcc1);
        accList.add(mobileAcc2);
        insert accList;
    }
	@isTest
    public static void testMethod1()
    {
        
        List<account> accountList = [select id from account];
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(accountList);
        
        List<account> accountListSelected = [select id from account Limit 1];
        setCon.setSelected(accountListSelected);
        
        test.startTest();
        MassAssignAccountBasedPortfolioClass massAssignController = new MassAssignAccountBasedPortfolioClass(setCon);
        test.stopTest();
    }
    
    @isTest
    public static void testMethod2()
    {
        user nonEligibleUser = [select id from user where LastName = 'nonEligibleUser'];
        List<account> accountList = [select id from account];
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(accountList);
        
        List<account> accountListSelected = [select id from account limit 1];
        setCon.setSelected(accountListSelected);
        
        System.runAs(nonEligibleUser)
        {
        test.startTest();
        MassAssignAccountBasedPortfolioClass massAssignController = new MassAssignAccountBasedPortfolioClass(setCon);
        test.stopTest();
        }
    }
     @isTest
    public static void testMethod3()
    {
        user nonEligibleDRDUser = [select id from user where LastName = 'nonEligibleDRDUser'];
        
        List<account> accountList = [select id from account];
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(accountList);
        
        List<account> accountListSelected = [select id from account limit 1];
        setCon.setSelected(accountListSelected);
        
        System.runAs(nonEligibleDRDUser)
        {
        test.startTest();
        MassAssignAccountBasedPortfolioClass massAssignController = new MassAssignAccountBasedPortfolioClass(setCon);
        test.stopTest();
        }
    }
}