@IsTest
private class DefaultTerritoryPortfolioBatch_Test {

    //Test Data Setup
    @testSetup
    static void setupData() {

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
            name = 'Test Account 2',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = 'PO BOX 1', 
        	BillingCity = 'COLUMBIAVILLE',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48421'
        );
        accList.add(mobileAcc1);
        accList.add(mobileAcc2);
        insert accList;
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
    }

    @isTest static void batchTest1()
     {
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
         
         BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        for(BSF_Portfolio__c portfolio:portfolios)
        {
            System.debug('portfolio record is '+portfolio);
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                    accountPorfolio = portfolio;
                }
            }
        }
         
         Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
         TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        //Datetime myDT = System.today()+4;
        Datetime myDT = System.today();
        AccountBasedPortfolioClass.AccountPortfolioWrapper accountPortfolioAssignment = new AccountBasedPortfolioClass.AccountPortfolioWrapper();
        accountPortfolioAssignment.selectedPortfolioType = BSF_Constants.ACCOUNT_PORTFOLIO;
        accountPortfolioAssignment.accountRecid = account.id;
        accountPortfolioAssignment.Start_Date = myDT.format('yyyy-MM-dd');
        accountPortfolioAssignment.End_Date = myDT.addDays(200).format('yyyy-MM-dd');
        accountPortfolioAssignment.portfolioRecId  = accountPorfolio.Id;  
        accountPortfolioAssignment.selectedAccountbasedreason=new list<string>{'Hospital Partner'};
        List<AccountBasedPortfolioClass.AccountPortfolioWrapper> apwrp = new List<AccountBasedPortfolioClass.AccountPortfolioWrapper>();
        apwrp.add(accountPortfolioAssignment);
        String accportfoliodata = JSON.serialize(apwrp);
        AccountBasedPortfolioClass.createAccountPortfolioData(accportfoliodata);
        
        Test.startTest();
         CreateDefaultTerritoryPortfolioBatch batch = new CreateDefaultTerritoryPortfolioBatch();
         database.executeBatch(batch);
        Test.stopTest();

        Account updatedAccount = [ SELECT Account_AM_Portfolio_Type__c FROM Account WHERE Id = :account.Id];
        System.assertEquals(false,updatedAccount.Account_AM_Portfolio_Type__c,'Account_AM_Portfolio_Type__c not set to true');
         
    }

    @isTest static void batchTest2()
     {
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
         
         BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        for(BSF_Portfolio__c portfolio:portfolios)
        {
            System.debug('portfolio record is '+portfolio);
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                    accountPorfolio = portfolio;
                }
            }
        }
         
         Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
         TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        //Datetime myDT = System.today()-4;
        Datetime myEndDateTime = System.today()+1;
        AccountBasedPortfolioClass.AccountPortfolioWrapper accountPortfolioAssignment = new AccountBasedPortfolioClass.AccountPortfolioWrapper();
        accountPortfolioAssignment.selectedPortfolioType = BSF_Constants.ACCOUNT_PORTFOLIO;
        accountPortfolioAssignment.accountRecid = account.id;
        accountPortfolioAssignment.Start_Date = myEndDateTime.addDays(-200).format('yyyy-MM-dd');
        accountPortfolioAssignment.End_Date = myEndDateTime.format('yyyy-MM-dd');
        accountPortfolioAssignment.portfolioRecId  = accountPorfolio.Id;  
        accountPortfolioAssignment.selectedAccountbasedreason=new list<string>{'Hospital Partner'};
        List<AccountBasedPortfolioClass.AccountPortfolioWrapper> apwrp = new List<AccountBasedPortfolioClass.AccountPortfolioWrapper>();
        apwrp.add(accountPortfolioAssignment);
        String accportfoliodata = JSON.serialize(apwrp);
        AccountBasedPortfolioClass.createAccountPortfolioData(accportfoliodata);
         
        Test.startTest();
        CreateDefaultTerritoryPortfolioBatch batch = new CreateDefaultTerritoryPortfolioBatch();
        database.executeBatch(batch);
        Test.stopTest();    
        
        Account updatedAccount = [ SELECT Account_AM_Portfolio_Type__c FROM Account WHERE Id = :account.Id];
        System.assertEquals(false,updatedAccount.Account_AM_Portfolio_Type__c,'Account_AM_Portfolio_Type__c must be FALSE when portfolio end date is today');
    }

    /* =========================
       Scheduler Coverage Test
    ========================= */
       
    @IsTest
    static void testSchedulerExecution() {

        Test.startTest();

        String jobId = System.schedule(
            'Test DefaultTerritoryPortfolioBatch Scheduler',
            '0 0 0 1 1 ? 2099',
            new DefaultTerritoryPortfolioBatchScheduler(50)
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'Scheduler job should be created successfully'
        );
    }
}