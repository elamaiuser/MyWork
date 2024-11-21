@isTest
public class AccTeamSyncPortfolio_Test 
{
     @testSetup
	public static void setup()
    {
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
    
    @isTest 
    static void batchTest()
     {
         
         
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
         //create users
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile'];
         
        List<User> drdUsers = AccountPortfolioAssignmentHelperTest.populateUserFields('DRD','User',drdProfile.Id,60);
         insert drdUsers;
        BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Date defaultStartDate = System.today();
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
         
         
         Integer drdUserIndex = 0;
        Integer dmUserIndex = 0;
        Integer supIndex = 0;
         
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        for(BSF_Portfolio__c portfolio:portfolios)
        {
            
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                }
        }
        }
            triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
             insert portAssigment;
         	triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        Portfolio_Assignment__c pa = [select id,User__c,BSF_Portfolio__c from Portfolio_Assignment__c where BSF_Portfolio__r.Portfolio_Type__c='Account Manager' and BSF_Portfolio__r.Account_Based_Portfolio__c=true and User__c!=null Limit 1];
            system.debug('Portfolio_Assignment__c'+pa);
         Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
         
        Date myDT = System.today();
         account_portfolio_assignment__c apa = new account_portfolio_assignment__c();
         apa.start_date__c=myDT;
         apa.End_Date__c=myDT.addDays(200);
         apa.Account__c = account.id;
         apa.BSF_Portfolio__c=pa.BSF_Portfolio__c;
          insert apa;
        
         
         Test.startTest();
         BSF_Batch_AccTeamSyncPortfolio batch = new BSF_Batch_AccTeamSyncPortfolio();
         database.executeBatch(batch);
         Test.stopTest();
         
         AccountTeamMember atm = [Select id,UserId,Accountid from AccountTeamMember where accountId=:account.id and TeamMemberRole='Account Manager' Limit 1];
         system.assert(atm.userid==pa.user__c);
         
     }
    
    @isTest 
    static void scheduleTest()
     {
         BSF_Batch_AccTeamSyncPortfolioScheduler schedule = new BSF_Batch_AccTeamSyncPortfolioScheduler();
         BSF_Batch_AccTeamSyncPortfolioScheduler schedule1 = new BSF_Batch_AccTeamSyncPortfolioScheduler(300);
         Test.StartTest();
		String sch = '0 0 23 * * ?';
		system.schedule('BSF_Batch_AccTeamSyncAccPortfolio', sch, schedule );
        Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'BSF_Batch_AccTeamSyncAccPortfolio'];
        system.assert(contrg.CronJobDetail.Name == 'BSF_Batch_AccTeamSyncAccPortfolio');
     }
}