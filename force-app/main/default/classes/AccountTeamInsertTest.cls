@isTest
public class AccountTeamInsertTest 
{
    @isTest
    public static void testAccountTeamInsertTest()
    {
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Map <String,Schema.RecordTypeInfo> recordTypesSite = sked__Location__c.sObjectType.getDescribe().getRecordTypeInfosByName();
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
        
        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' ,
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
            isActive = true
             
        );
        list<user> userList = new list<user>();
        Id PrflId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id;
        
        for(integer i=0;i<=5;i++)
        {
            User u = new User(
                ProfileId = PrflId ,
                LastName = 'last'+i,
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama'+i+'.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                isActive=true
                //userType='Salesforce'
            );
            userList.add(u);
        }
        System.runAs( AdminUser )
        {
            insert userList;
        }
    
	 List<AccTeamFromPortfolioAssignmentService__e> accTeamEveList = new List<AccTeamFromPortfolioAssignmentService__e>();
     
        
    integer i = 0;
    for(user u :  [select id,isActive from user where ProfileId = :PrflId])
    {
        AccTeamFromPortfolioAssignmentService__e accPortEve = new AccTeamFromPortfolioAssignmentService__e();
        accPortEve.AccountId__c = mobileAcc.id;
        accPortEve.UserId__c =u.id;
        accPortEve.Start_Date__c = system.today() +i;
        accPortEve.End_Date__c = accPortEve.Start_Date__c +i-1;
        accPortEve.AccountAccessLevel__c ='Edit';
        accPortEve.CaseAccessLevel__c='Edit';
        accPortEve.OpportunityAccessLevel__c='Edit';
        accPortEve.TeamMemberRole__c= bsf_constants.ACCOUNT_MANAGER;
        accPortEve.BSF_Portfolio__c=null;
        accTeamEveList.add(accPortEve);
        i=i+31;
    }
        test.startTest();
        EventBus.publish(accTeamEveList);
        Test.stopTest();
    }
}