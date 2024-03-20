@isTest
public class PortfolioAssignmentTriggerHandler_Test {
	@testSetup static void createData(){
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
        
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
    }
    
    public static List<User> populateUserFields(String firstName,String lastName,Id profileId,Integer count){
        List<User> users = new List<User>();
        for(Integer index=1;index<=count;index++){
            User user1 = new User(Alias = firstName+index, FirstName = firstName+index, Email=firstName+index+'.'+lastName+index+'@test.com',EmailEncodingKey='UTF-8', LastName=lastName+index, LanguageLocaleKey='en_US', 
            	LocaleSidKey='en_US', ProfileId = profileId, TimeZoneSidKey='America/Los_Angeles', UserName=firstName+index+'.'+lastName+index+'@test.com.tst1');
        	users.add(user1);
        }
        return users;
    }
    
    @isTest static void testAccountPortfolioAssignment1(){
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        
        Test.startTest();
        //create users
        List<User> users = new List<User>();
        Profile drdProfile = null;
        Profile drdManagerProfile = null;
        for(Profile pf:[SELECT Id,Name FROM Profile WHERE Name IN ('DRD Profile','DRD Manager')]){
            if(pf.Name == 'DRD Profile'){
                drdProfile = pf;
            }
            if(pf.Name == 'DRD Manager'){
                drdManagerProfile = pf;
            }
        }
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        Integer dmUserIndex = 0;
        Integer supIndex = 0;
        Integer ambIndex=0;
        Integer amIndex=0;
        Integer dmIndex=0;
        Integer drdOtherUserIndex = 15;
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        for(BSF_Portfolio__c portfolio:portfolios){
            System.debug('portfolio record is '+portfolio);
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                    accountPorfolio = portfolio;
                }
                
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+350));
                   	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                }
                
                if(portfolio.Portfolio_Type__c == 'District Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+350));
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                }
                
                if(portfolio.Portfolio_Type__c == 'Area Booking Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+350));
					portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                }
            }else if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
                }
            }else{
                portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdOtherUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
            }
        } 
        
        insert portAssigment;
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        
        List<Portfolio_Assignment__c> amUsers = [Select Id,Name,Start_Date__c,End_date__c from Portfolio_Assignment__c Where BSF_Portfolio__r.Portfolio_Code__c = 'HProdSED_755' 
                                                 						AND BSF_Portfolio__r.Taxonomy_Type__c = 'Bio Recruitment CD' AND BSF_Portfolio__r.Portfolio_type__c = 'Account Manager' AND BSF_Portfolio__r.Territory_Portfolio__c = TRUE];
        amUsers[0].End_date__c = amUsers[0].End_date__c +10;
        amUsers[1].Start_Date__c =  amUsers[1].Start_Date__c +10;   
        update amUsers;
        
        delete amUsers[1];
        
        Test.stopTest();
    }
    
    @isTest static void testAccountPortfolioAssignment2(){
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        
        Test.startTest();
        //create users
        List<User> users = new List<User>();
        Profile drdProfile = null;
        Profile drdManagerProfile = null;
        for(Profile pf:[SELECT Id,Name FROM Profile WHERE Name IN ('DRD Profile','DRD Manager')]){
            if(pf.Name == 'DRD Profile'){
                drdProfile = pf;
            }
            if(pf.Name == 'DRD Manager'){
                drdManagerProfile = pf;
            }
        }
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        Integer dmUserIndex = 0;
        Integer supIndex = 0;
        Integer ambIndex=0;
        Integer amIndex=0;
        Integer dmIndex=0;
        Integer drdOtherUserIndex = 15;
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        for(BSF_Portfolio__c portfolio:portfolios){
            System.debug('portfolio record is '+portfolio);
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                    accountPorfolio = portfolio;
                }
                
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+350));
                   	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                }
                
                if(portfolio.Portfolio_Type__c == 'District Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+350));
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                }
                
                if(portfolio.Portfolio_Type__c == 'Area Booking Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+350));
					portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                }
            }else if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
                }
            }else{
                portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdOtherUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
            }
        } 
        
        insert portAssigment;
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        List<Portfolio_Accounts_Processing__c> pt = [Select Id, Portfolio_progress_for_Accounts__c, Records_Processed__c, Portfolio_Assignment_Updated__c From Portfolio_Accounts_Processing__c LIMIT 1];
        if (pt.size() > 0) {
            pt[0].Portfolio_progress_for_Accounts__c = 3;
            pt[0].Records_Processed__c = 3;
            pt[0].Portfolio_Assignment_Updated__c = false;
            update pt;
        }
        List<Portfolio_Assignment__c> amUsers = [Select Id,Name,Start_Date__c,End_date__c from Portfolio_Assignment__c Where BSF_Portfolio__r.Portfolio_Code__c = 'HProdSED_755' 
                                                 						AND BSF_Portfolio__r.Taxonomy_Type__c = 'Bio Recruitment CD' AND BSF_Portfolio__r.Portfolio_type__c = 'Account Manager' AND BSF_Portfolio__r.Territory_Portfolio__c = TRUE];
        amUsers[0].End_date__c = amUsers[0].End_date__c +10;
        amUsers[1].Start_Date__c =  amUsers[1].Start_Date__c +10;   
        update amUsers;
        
        delete amUsers[1];
        
        Test.stopTest();
    }
}