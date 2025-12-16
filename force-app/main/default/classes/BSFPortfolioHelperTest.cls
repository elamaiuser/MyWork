@isTest
public class BSFPortfolioHelperTest {

    @testSetup static void createData(){
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Account mobileAcc1 = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420',
            Internal_Name__c='Test Account'
        );
        triggerhandler.bypass('AccountTriggerHandler');
        insert mobileAcc1;
        triggerHandler.clearBypass('AccountTriggerHandler');
    }
    
    @isTest static void testPortfolioGeneration(){
        Test.startTest();
        BSFPortfolioHelper.processTaxonomyData(1002,BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE);
        Test.stopTest();
    }
    
    @isTest static void testPortfolioGeneration1(){     
        /*BSFPortfolioHelper.processTaxonomyData(1000,BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1001,BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1002,BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1316,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(13161,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(999,BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE);    
        BSFPortfolioHelper.processTaxonomyData(694,BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1317,BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE);*/
        TriggerHandler.bypass('TaskTriggerHandler');
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Test.startTest();
        update portfolios[0];
        
        delete portfolios[0];
        
        Test.stopTest();
    }
    
    @isTest static void testPortfolioGeneration2(){
        
        Test.startTest();
        
        /*BSFPortfolioHelper.processTaxonomyData(1000,BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1001,BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1002,BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1316,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(13161,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(999,BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE);    
        BSFPortfolioHelper.processTaxonomyData(694,BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1317,BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE);*/
        
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c,
        									Zip_Code__c FROM Taxonomy__c WHERE RecordType.Name IN('Bio Recruitment CD','Bio Account Portfolio')]; 
        
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        
        account acc = [select id from account Limit 1];
        bsf_portfolio__c bsf  = [select id,start_date__c,End_date__c from bsf_Portfolio__c where Portfolio_type__c ='Account Manager' and Taxonomy_Type__c='Bio Recruitment CD' limit 1];
        
        Date mydt = system.today();
        account_portfolio_Assignment__c aplist= new account_portfolio_Assignment__c(account__c=acc.id,BSF_Portfolio__c=bsf.id,start_date__c =bsf.Start_Date__c,end_date__c = bsf.End_Date__c) ;
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        insert aplist;
        
        bsf.End_Date__c = system.today().addDays(10);
        update bsf;

        Test.stopTest();
    }
    
    @isTest static void testPortfolioGeneration3() {

        User AdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'    
        );
        
        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
            LastName = 'last',
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

        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        Test.startTest();
        
        /*BSFPortfolioHelper.processTaxonomyData(1000,BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1001,BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1002,BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1316,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(13161,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(999,BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE);    
        BSFPortfolioHelper.processTaxonomyData(694,BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1317,BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE);*/
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c,
        									Zip_Code__c FROM Taxonomy__c WHERE RecordType.Name IN('Bio Recruitment CD','Bio Account Portfolio')]; 
        
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        
        account acc = [select id from account Limit 1];
        bsf_portfolio__c bsf  = [select id,start_date__c,End_date__c,parent_Portfolio__c from bsf_Portfolio__c where Portfolio_type__c ='Account Manager' and Taxonomy_Type__c='Bio Recruitment CD' limit 1];
        bsf_portfolio__c bsfDm  = [select id,start_date__c,End_date__c,parent_Portfolio__c from bsf_Portfolio__c where id=:bsf.parent_Portfolio__c limit 1];
        Portfolio_assignment__c ps = new Portfolio_assignment__c(user__c=DRDAMUser.id,bsf_portfolio__c = bsfDm.id,start_date__c=bsfDm.Start_Date__c,end_date__c=bsfDm.End_Date__c,Assignment_Type__c='Area Booking Manager');
        insert ps;
        
        Date mydt = system.today();
        account_portfolio_Assignment__c aplist= new account_portfolio_Assignment__c(account__c=acc.id,BSF_Portfolio__c=bsf.id,start_date__c =bsf.Start_Date__c,end_date__c = bsf.End_Date__c) ;
        AccountTeamMember atm = new AccountTeamMember(accountId=acc.id,userid=DRDAMUser.id,bsf_portfolio__c = bsfDm.id,start_date__c=bsfDm.Start_Date__c,end_date__c=bsfDm.End_Date__c,TeamMemberRole='Area Booking Manager',is_covering_recruiter__c=false);
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        insert aplist;
        
        triggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert atm;
        bsfDm.End_Date__c = system.today().addDays(10);
        update bsfDm;

        Test.stopTest();
    }
    
    @isTest static void testPortfolioGeneration4(){
        
        User AdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US' 
        );
        
        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
            LastName = 'last',
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

        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        Test.startTest();
        
        /*BSFPortfolioHelper.processTaxonomyData(1000,BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1001,BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1002,BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1316,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(13161,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(999,BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE);    
        BSFPortfolioHelper.processTaxonomyData(694,BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE);
        BSFPortfolioHelper.processTaxonomyData(1317,BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE);*/
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c,
        									Zip_Code__c FROM Taxonomy__c WHERE RecordType.Name IN('Bio Recruitment CD','Bio Account Portfolio')]; 
        
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        
        account acc = [select id from account Limit 1];
        bsf_portfolio__c bsf  = [select id,start_date__c,End_date__c,parent_Portfolio__c,portfolio_code__c from bsf_Portfolio__c where Portfolio_type__c =:BSF_Constants.ACCOUNT_SPECIALIST and Taxonomy_Type__c=:BSF_Constants.ACCOUNT_SPECIALIST limit 1];
        bsf_portfolio__c DMBSf  = [select id,start_date__c,End_date__c,parent_Portfolio__c from bsf_Portfolio__c where Portfolio_Code__c=:bsf.Portfolio_Code__c limit 1];
        Portfolio_assignment__c ps = new Portfolio_assignment__c(user__c=DRDAMUser.id,bsf_portfolio__c = bsf.id,start_date__c=bsf.Start_Date__c,end_date__c=bsf.End_Date__c,Assignment_Type__c=BSF_Constants.ACCOUNT_SPECIALIST);
        insert ps;
        Date mydt=system.today();
        account_portfolio_Assignment__c aplist= new account_portfolio_Assignment__c(account__c=acc.id,BSF_Portfolio__c=bsf.id,start_date__c =bsf.Start_Date__c,end_date__c = bsf.End_Date__c) ;    
        insert aplist;
    
        DMBSf.End_Date__c = system.today().addDays(10);
        update DMBSf;

        Test.stopTest();
    }
}