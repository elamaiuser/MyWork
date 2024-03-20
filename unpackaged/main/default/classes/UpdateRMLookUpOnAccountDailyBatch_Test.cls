@isTest
public class UpdateRMLookUpOnAccountDailyBatch_Test 
{
    @testSetup
    public static void testSetup()
    {
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        
        String firstName = 'User';
        String LastName = '1';
        
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; 
        
        
        User user1 = new User(Alias = firstName, FirstName = firstName, Email=firstName+'.'+lastName+'@test.com',EmailEncodingKey='UTF-8', LastName=lastName, LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = drdProfile.id, TimeZoneSidKey='America/Los_Angeles', UserName=firstName+'.'+lastName+'@test.com.tst1');
        
        
        insert user1;
        
        User u =[select id from user limit 1];
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                      Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
                                      RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
                                      FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        
        Portfolio_assignment__c portfolioAssign = new Portfolio_assignment__c();
        for(BSF_Portfolio__c portfolio:portfolios)
        {
            if(portfolio.Portfolio_Type__c == BSF_Constants.RELATIONSHIP_MANAGER)
            {
                portfolioAssign.BSF_Portfolio__c=portfolio.id;
                portfolioAssign.User__c=u.Id;
                portfolioAssign.Assignment_Type__c=portfolio.Portfolio_Type__c;
                portfolioAssign.Start_Date__c=system.today();
                portfolioAssign.End_Date__c=system.today()+365;
            }
        }
        insert portfolioAssign;
        
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();    
        List<Account> accList = new List<Account>();        
        Account acc = new Account(
            name = 'Test Account 1',
            RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
            BillingCity = 'Herndon',
            BillingStateCode = 'MI',
            BillingPostalCode = '48421'
        );
        
        Account acc1 = new Account(
            name = 'Test Account 2',
            RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
            BillingCity = 'Herndon',
            BillingStateCode = 'MI',
            BillingPostalCode = '48421'
        );
        
        accList.add(acc);
        accList.add(acc1);
        insert accList;
    }
    
    @isTest
    public static void ScheduleClass_Test()
    {
        Test.StartTest();
		UpdateRMOnAccountDailyBatchScheduler testsche = new UpdateRMOnAccountDailyBatchScheduler(200);
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
		Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class');
    }
    @isTest
    public static void testMethod1()
    {
        Test.startTest();
        
        BSF_Portfolio__c bsfPortfolio = [Select Id  FROM BSF_Portfolio__c where Portfolio_Type__c =:BSF_Constants.RELATIONSHIP_MANAGER];
        List<Account> acountsList =[select id from account];
        
        List<Account_Portfolio_Assignment__c> apaList = new List<Account_Portfolio_Assignment__c>();
        for(account ac:acountsList)
        {
            Account_Portfolio_Assignment__c apa = new Account_Portfolio_Assignment__c();
            apa.Account__c = ac.id;
            apa.BSF_Portfolio__c = bsfPortfolio.id;
            apa.Start_Date__c = system.today();
            apa.End_Date__c = system.today()+365;
            apaList.add(apa);    
        }
        
        insert apaList;
        
        
        UpdateRMLookUpOnAccountDailyBatch batch = new UpdateRMLookUpOnAccountDailyBatch();
        Database.executeBatch(batch);
        Test.stopTest();            
        
        List<Account> updatedAccount = [Select Relationship_Manager__c from account where Relationship_Manager__c != null];
        system.debug('updatedAccount: '+updatedAccount);
        system.assertNotEquals(null,updatedAccount[0].Relationship_Manager__c);
    }
}