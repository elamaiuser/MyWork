@isTest
public class AccountPortfolioAssignmentBatch_Test {
    @isTest
    Public static void TestMethod1()
    {
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        
        Date stDate = system.today()-100;
        Date enDate = system.today()+365;
        
        BSF_Batch_BSFPortfolio batch = new BSF_Batch_BSFPortfolio(stDate,True);
        database.executeBatch(batch);
        
        BSF_Batch_BSFPortfolio batchV1 = new BSF_Batch_BSFPortfolio('Testbatch',1000,stDate,enDate,True);
        database.executeBatch(batchV1);
        
        BSF_Batch_BSFPortfolio batchV2 = new BSF_Batch_BSFPortfolio('Testbatch',1000,Null,Null,True);
        String chron = '0 0 23 * * ?';        
         String jobid = System.schedule('testScheduledApex', chron, batchV2);
        //database.executeBatch(batchV2);
    }
    
     @isTest
    Public static void TestMethod2()
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
        	BillingPostalCode = '48420',
            Account_AM_Portfolio_Type__c = FALSE
        );
        Account mobileAcc2 = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48421',
            Account_AM_Portfolio_Type__c = FALSE
        );
        accList.add(mobileAcc1);
        accList.add(mobileAcc2);
        insert accList;
        
        
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name = :BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE];
        
         TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        
        //create users
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = AccountPortfolioAssignmentHelperTest.populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = AccountPortfolioAssignmentHelperTest.populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Start_date__c,End_Date__c,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        Integer dmUserIndex = 0;
        Integer supIndex = 0;
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        for(BSF_Portfolio__c portfolio:portfolios){
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=portfolio.start_Date__c ,End_Date__c=portfolio.start_Date__c+10));
                	}
                
                if(portfolio.Portfolio_Type__c == 'District Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=portfolio.start_Date__c ,End_Date__c=portfolio.start_Date__c+10));
                	}
                
                if(portfolio.Portfolio_Type__c == 'Area Booking Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=portfolio.start_Date__c ,End_Date__c=portfolio.start_Date__c+10));
					}
            }
            else{
                portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=portfolio.start_Date__c ,End_Date__c=portfolio.End_Date__c));
            }
        } 
        //TriggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portAssigment;
        //TriggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        
        List<Account_Portfolio_Assignment__C> assngList =[select id from Account_Portfolio_Assignment__c where account__c=:mobileAcc1.id];
        delete assngList;
        system.debug('assngList: '+ assngList);
        accList.get(0).Account_AM_Portfolio_Type__c = false;
        accList.get(1).Account_AM_Portfolio_Type__c = false;
        update accList;
        
        test.startTest();
        //BSF_Batch_AccountPortfolioAssignment_V2 batchV2 = new BSF_Batch_AccountPortfolioAssignment_V2(1000,null);
       // database.executeBatch(batchV2);
       // \
       // 
       BSF_Batch_AccountPortfolioAssignment batch = new BSF_Batch_AccountPortfolioAssignment(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxonomies[0].Version_Key__c,null,null);
       database.executeBatch(batch);
        BSF_Batch_AccountPortfolioAssignment batch1 = new BSF_Batch_AccountPortfolioAssignment(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxonomies[0].Version_Key__c,null,null,true);
       database.executeBatch(batch1);  
       //
        BSF_Batch_AccountPortfolioAssignment batch2 = new BSF_Batch_AccountPortfolioAssignment(null,null,null,null,true);
       database.executeBatch(batch2);  
        //batch2.finish(null);
       
        test.stopTest();
      //  system.assert(!([select id from Account_Portfolio_Assignment__C where account__c=:mobileAcc1.id].isEmpty()));
    }
}