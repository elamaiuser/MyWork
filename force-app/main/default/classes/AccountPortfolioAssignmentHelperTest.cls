@isTest
public class AccountPortfolioAssignmentHelperTest  {

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
        
        //create users
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        Integer dmUserIndex = 0;
        Integer supIndex = 0;
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        for(BSF_Portfolio__c portfolio:portfolios){
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                }
                
                if(portfolio.Portfolio_Type__c == 'District Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                }
                
                if(portfolio.Portfolio_Type__c == 'Area Booking Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
					portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                }
            }else if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
                    if(supIndex > 0)
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                	supIndex++;
                }
            }else{
                portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
            }
        } 
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portAssigment;
        triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        System.debug('Portfolios have been assigned ');
        
        Test.startTest();
        
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        AccountPortfolioAssignmentHelper.processTaxonomyData(1001);
        //BSF_TestDataSetup datasetup = new BSF_TestDataSetup(true);
        //Map<string, sObject> mapTestData = datasetup.createAndInsertCommonObjects();
        
        Test.stopTest();
        //Account_Portfolio_Assignment__c ap = [select id from Account_Portfolio_Assignment__c limit 1];
        //system.assert(ap != null);
         
        
        
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
        
        //create users
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        Integer dmUserIndex = 0;
        Integer supIndex = 0;
        Integer ambIndex=0;
        Integer amIndex=0;
        Integer dmIndex=0;
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        for(BSF_Portfolio__c portfolio:portfolios){
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                    
                    if(amindex > 0){
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+250));
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+251 ,End_Date__c=defaultStartDate+350));
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                    }else{
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
                    }
                    amindex++;
                }
                
                if(portfolio.Portfolio_Type__c == 'District Manager'){
                    if(dmindex > 0){
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+250));
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+251 ,End_Date__c=defaultStartDate+350));
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                    }else{
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
                    }
                    dmindex++;
                }
                
                if(portfolio.Portfolio_Type__c == 'Area Booking Manager'){
                    if(ambIndex > 0){
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+250));
						portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+251 ,End_Date__c=defaultStartDate+350));
	                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                    }else{
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));    
                    }
                    ambIndex++;
                }
            }else if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
                    if(supIndex > 0)
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                	supIndex++;
                }
            }else{
                portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
            }
        } 
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portAssigment;
        triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        System.debug('Portfolios have been assigned ');
        
        Test.startTest();
        
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        AccountPortfolioAssignmentHelper.processTaxonomyData(1001);
        
        Test.stopTest();
    }
    
    @isTest static void testAccountPortfolioAssignment3(){
        
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
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','U',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
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
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                    
                    if(amindex > 0){
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex+1].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+250));
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex+2].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+251 ,End_Date__c=defaultStartDate+350));
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex+3].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                    }else{
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex+1].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
                    }
                    amindex++;
                }
                
                if(portfolio.Portfolio_Type__c == 'District Manager'){
                    if(dmindex > 0){
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex+4].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+250));
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex+5].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+251 ,End_Date__c=defaultStartDate+350));
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex+6].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                    }else{
                        portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex+4].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
                    }
                    dmindex++;
                }
                
                if(portfolio.Portfolio_Type__c == 'Area Booking Manager'){
                    if(ambIndex > 0){
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex+7].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+250));
						portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex+8].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+251 ,End_Date__c=defaultStartDate+350));
	                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex+9].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                    }else{
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex+7].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));    
                    }
                    ambIndex++;
                }
            }else if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex+10].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
                    if(supIndex > 0)
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex+11].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                	supIndex++;
                }
            }else{
                portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdOtherUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
            }
        } 
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portAssigment;
        triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        System.debug('Portfolios have been assigned ');
        
        Test.startTest();
        triggerHandler.bypass('AccountTeamMemberTriggerHandler');
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        AccountPortfolioAssignmentHelper.processTaxonomyData(1001);
        
        Test.stopTest();
    }
    
    @isTest static void C4(){
        //covers accountBasedPortfolioClass addition to account and AccountPortfolioAssignmentService class
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
        
       triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portAssigment;
        
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
         TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        Datetime myDT = System.today()+4;
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
        
        List<Account_Portfolio_Assignment__c> apaList = [select id,Start_Date__c,End_Date__c,BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Account_Based_Portfolio__c,BSF_Portfolio__r.Taxonomy_Type__c from Account_Portfolio_Assignment__c where Account__c=:account.id];
        for(Account_Portfolio_Assignment__c apa:apaList)
        {
            if(apa.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER && apa.BSF_Portfolio__r.Account_Based_Portfolio__c == true && apa.BSF_Portfolio__r.Taxonomy_Type__c != BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE)
            {
                system.debug(apa);
                apa.Start_Date__c=system.today();
                update apa;
                break;
            }
        }
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        Test.stopTest();
        Account_Portfolio_Assignment__c ap = [select id from Account_Portfolio_Assignment__c where BSF_Portfolio__r.Account_Based_Portfolio__c = true and account__c =:account.id and BSF_Portfolio__c =:accountPorfolio.id limit 1];
        system.assert(ap != null);
    }
    
    @isTest static void testAccountPortfolioAssignment5(){
        //covers CreateDefaultTerritory portfolio batch 
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
              }
        }
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        
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
        
        //List<Account_Portfolio_Assignment__c> apaList = [select id,Start_Date__c,End_Date__c,BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Taxonomy_Type__c,BSF_Portfolio__r.Account_Based_Portfolio__c from Account_Portfolio_Assignment__c where Account__c=:account.id];
        //system.debug('apaList:'+apaList);
        
        
        DefaultTerritoryPortfolioBatchScheduler acctSponsorRecognSch = new DefaultTerritoryPortfolioBatchScheduler(100);
 		System.schedule('Update Account Sponsor Recognition Batch1', '0 0 21 * * ?', acctSponsorRecognSch );
        CreateDefaultTerritoryPortfolioBatch defaultAccPortBatch  = new CreateDefaultTerritoryPortfolioBatch();
        Database.executeBatch(defaultAccPortBatch);

       
        Test.stopTest();
        Account_Portfolio_Assignment__c apassign = [select id,Start_Date__c,End_Date__c from Account_Portfolio_Assignment__c where Account__c=:account.id and BSF_Portfolio__r.Account_Based_Portfolio__c=true limit 1];
        apassign.End_Date__c = apassign.End_Date__c-1;
        update apassign;
        account a = [select Account_AM_Portfolio_Type__c from account where id =:account.id];
        
        
    }
    
    
    @isTest static void testAccountPortfolioAssignment6(){
        
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
        BSF_Portfolio__c portfolioSickle = null;
        BSF_Portfolio__c portfolioRelation = null;
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
            if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE && portfolio.Portfolio_Type__c == BSF_Constants.SICKLE_CELL_ACCOUNT_MANAGER){
                    portfolioSickle = portfolio;
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+350));
                   	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
               }
            else if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE && portfolio.Portfolio_Type__c == BSF_Constants.RELATIONSHIP_MANAGER)
            {
                portfolioRelation = portfolio;
                portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+350));
            }
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                    accountPorfolio = portfolio;
                }
                
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+350));
                   	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+351 ,End_Date__c=defaultEndDate));
                }
            }
        } 
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        
        Account account = [Select Id,BillingPostalCode,Account_AM_Portfolio_Type__c from Account where BillingPostalCode = '48420' limit 1];
        
            
        Datetime myDT = System.today()+4;
        AccountBasedPortfolioClass.AccountPortfolioWrapper accountPortfolioAssignment = new AccountBasedPortfolioClass.AccountPortfolioWrapper();
        accountPortfolioAssignment.selectedPortfolioType = BSF_Constants.SICKLE_CELL_ACCOUNT_MANAGER;
        accountPortfolioAssignment.accountRecid = account.id;
        accountPortfolioAssignment.Start_Date = myDT.format('yyyy-MM-dd');
        accountPortfolioAssignment.End_Date = myDT.addDays(200).format('yyyy-MM-dd');
        accountPortfolioAssignment.portfolioRecId  = portfolioSickle.Id; 
        accountPortfolioAssignment.selectedAccountbasedreason=new list<string>{'Hospital Partner'};
        List<AccountBasedPortfolioClass.AccountPortfolioWrapper> apwrp = new List<AccountBasedPortfolioClass.AccountPortfolioWrapper>();
        apwrp.add(accountPortfolioAssignment);
        String accportfoliodata = JSON.serialize(apwrp);
        AccountBasedPortfolioClass.createAccountPortfolioData(accportfoliodata);
       
        AccountBasedPortfolioClass.AccountPortfolioWrapper accountPortfolioAssignment2 = new AccountBasedPortfolioClass.AccountPortfolioWrapper();
        accountPortfolioAssignment2.selectedPortfolioType = BSF_Constants.RELATIONSHIP_MANAGER;
        accountPortfolioAssignment2.accountRecid = account.id;
        accountPortfolioAssignment2.Start_Date = myDT.format('yyyy-MM-dd');
        accountPortfolioAssignment2.End_Date = myDT.addDays(200).format('yyyy-MM-dd');
        accountPortfolioAssignment2.portfolioRecId  = portfolioRelation.Id;  
        accountPortfolioAssignment2.selectedAccountbasedreason=new list<string>{'Hospital Partner'};
        apwrp.clear();
        apwrp.add(accountPortfolioAssignment2);
        accportfoliodata = JSON.serialize(apwrp);
        AccountBasedPortfolioClass.createAccountPortfolioData(accportfoliodata);
        
        Test.stopTest();
    }
   
        @isTest static void testAccountPortfolioAssignment7(){
        
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
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portAssigment;
       triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        account.Account_AM_Portfolio_Type__c=false;
        update account;
        
        Datetime myStDT = date.newInstance(4000,12,31);
        Datetime myEtDT = myStDT+1;
        AccountBasedPortfolioClass.AccountPortfolioWrapper accountPortfolioAssignment = new AccountBasedPortfolioClass.AccountPortfolioWrapper();
        accountPortfolioAssignment.selectedPortfolioType = BSF_Constants.ACCOUNT_PORTFOLIO;
        accountPortfolioAssignment.accountRecid = account.id;
        accountPortfolioAssignment.Start_Date = myStDT.format('yyyy-MM-dd');
        accountPortfolioAssignment.End_Date = myEtDT.format('yyyy-MM-dd');
        accountPortfolioAssignment.portfolioRecId  = accountPorfolio.Id;  
            accountPortfolioAssignment.selectedAccountbasedreason=new list<string>{'Hospital Partner'};
        List<AccountBasedPortfolioClass.AccountPortfolioWrapper> apwrp = new List<AccountBasedPortfolioClass.AccountPortfolioWrapper>();
        apwrp.add(accountPortfolioAssignment);
        String accportfoliodata = JSON.serialize(apwrp);
        AccountBasedPortfolioClass.createAccountPortfolioData(accportfoliodata);
        Test.stopTest();
    }
    
    @isTest static void testAccountPortfolioAssignment8()
    {
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        
        List<id> idList = new List<id>();
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        idList.add(account.id);
        
        Test.startTest();
        AccountBasedPortfolioClass.getAccountInstance(account.id);
        AccountBasedPortfolioClass.getAccountInstances(idList);
        AccountBasedPortfolioClass.getNonGeoPortfolioData(BSF_Constants.ACCOUNT_MANAGER,idList);
        AccountBasedPortfolioClass.getNonGeoPortfolioData(BSF_Constants.NATIONAL_ACCOUNT_MANAGER,idList);
        AccountBasedPortfolioClass.getNonGeoPortfolioData(BSF_Constants.TAXO_BOOKING_SUPPORT_RECORD_TYPE,idList);
        AccountBasedPortfolioClass.getNonGeoPortfolioData(BSF_Constants.RELATIONSHIP_MANAGER,idList);
        AccountBasedPortfolioClass.getNonGeoPortfolioData(BSF_Constants.SICKLE_CELL_ACCOUNT_MANAGER,idList);
        AccountBasedPortfolioClass.getNonGeoPortfolioData(BSF_Constants.Booking_Support,idList);
        AccountBasedPortfolioClass.getNonGeoPortfolioData(BSF_Constants.FIXED_SITE,idList);
        AccountBasedPortfolioClass.getNonGeoPortfolioData(BSF_Constants.ACCOUNT_SPECIALIST,idList);
        Test.stopTest();
    }
    
     @isTest static void testAccountPortfolioAssignment9(){
        User DRDUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'drdmanageruser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert DRDUser;
         
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
        Profile drdProfile = null;
        //Profile drdManagerProfile = null;
        for(Profile pf:[SELECT Id,Name FROM Profile WHERE Name IN ('DRD Profile','DRD Manager')]){
            if(pf.Name == 'DRD Profile'){
                drdProfile = pf;
            }
            /*if(pf.Name == 'DRD Manager'){
                drdManagerProfile = pf;
            }*/
        }
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        //List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        //List<User> allUsers = new List<User>();
        //allUsers.addAll(drdUsers);
        
        insert drdUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        
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
                
                
            }
        } 
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
         Test.startTest();
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
         
        
         
        AccountTeamMember atm = new AccountTeamMember(AccountId=account.id, TeamMemberRole='Account Specialist', UserId=drduser.id,End_Date__c=system.today()+365, Start_Date__c=system.today()-5,Coverage_Reason__c='Vacant Territory');
        insert atm;
         
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        opportunity opp = new opportunity(
        Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            //Drive_Site__c = mobileSite.id,
            accountid= account.id);
         
        System.runAs( DRDUser ){
        insert opp;
        }
         
         Test.stopTest();
        skedHubBase.BypassInsertTriggers = false;
         skedHubBase.BypassUpdateTriggers = false;
    }
    
    @isTest static void testAccountPortfolioAssignment10(){
        User DRDUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'drdmanageruser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert DRDUser;
         
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
         
        
         
        AccountTeamMember atm = new AccountTeamMember(Is_Covering_Recruiter__c=false,AccountId=account.id, TeamMemberRole='District Manager', UserId=drduser.id,End_Date__c=system.today()+365, Start_Date__c=system.today()-5,coverage_reason__c='	Leave of Absence (LOA)');
        insert atm;
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
        Profile drdProfile = null;
        //Profile drdManagerProfile = null;
        for(Profile pf:[SELECT Id,Name FROM Profile WHERE Name IN ('DRD Profile','DRD Manager')]){
            if(pf.Name == 'DRD Profile'){
                drdProfile = pf;
            }
            /*if(pf.Name == 'DRD Manager'){
                drdManagerProfile = pf;
            }*/
        }
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        //List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        //List<User> allUsers = new List<User>();
        //allUsers.addAll(drdUsers);
        
        insert drdUsers;
        
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        
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
                
                
            }
        } 
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
		insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
         Test.startTest();
        
         
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        opportunity opp = new opportunity(
        Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            //Drive_Site__c = mobileSite.id,
            accountid= account.id);
         
        System.runAs( DRDUser ){
        TriggerHandler.bypass('OpportunityTriggerHandler');
            insert opp;
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
        }
         
         Test.stopTest();
        skedHubBase.BypassInsertTriggers = false;
         skedHubBase.BypassUpdateTriggers = false;
    }
    
    @isTest static void testAccountPortfolioAssignment11(){
         
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
        Profile drdProfile = null;
        //Profile drdManagerProfile = null;
        for(Profile pf:[SELECT Id,Name FROM Profile WHERE Name IN ('DRD Profile','DRD Manager')]){
            if(pf.Name == 'DRD Profile'){
                drdProfile = pf;
            }
            /*if(pf.Name == 'DRD Manager'){
                drdManagerProfile = pf;
            }*/
        }
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        //List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        //List<User> allUsers = new List<User>();
        //allUsers.addAll(drdUsers);
        
        insert drdUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        
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
                
                
            }
        } 
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
         
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        
        opportunity opp = new opportunity(
        Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            //Drive_Site__c = mobileSite.id,
            accountid= account.id);
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
         opp.Drive_Date__c =System.today()+1;
        opp.Drive_Date_Change_Reason__c = 'TEST';
         Test.startTest();
         update opp;
         Test.stopTest();
        skedHubBase.BypassInsertTriggers = false;
         skedHubBase.BypassUpdateTriggers = false;
    }
    @isTest static void testAccountPortfolioAssignment12(){
        
       
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
        Profile drdProfile = null;
        //Profile drdManagerProfile = null;
        for(Profile pf:[SELECT Id,Name FROM Profile WHERE Name IN ('DRD Profile','DRD Manager')]){
            if(pf.Name == 'DRD Profile'){
                drdProfile = pf;
            }
            /*if(pf.Name == 'DRD Manager'){
                drdManagerProfile = pf;
            }*/
        }
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        //List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        //List<User> allUsers = new List<User>();
        //allUsers.addAll(drdUsers);
        
        insert drdUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        
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
                
                
            }
        } 
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
         Test.startTest();
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        
        List<opportunity> oppList = new List<opportunity>();
         for(integer i=0;i<=11;i++)
         {
            opportunity opp1 = new opportunity(
            Name = 'Test Opportunity'+i,
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            accountid= account.id);
             oppList.add(opp1);
         }
         system.debug('10 opp insert'+oppList);
         insert oppList;
        
         
         Test.stopTest();
        skedHubBase.BypassInsertTriggers = false;
         skedHubBase.BypassUpdateTriggers = false;
    }
    @isTest static void testAccountPortfolioAssignment13(){
        
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
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        Integer dmUserIndex = 0;
        Integer supIndex = 0;
        List<Portfolio_Assignment__c> portAssigment = new List<Portfolio_Assignment__c>();
        for(BSF_Portfolio__c portfolio:portfolios){
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                }
                
                if(portfolio.Portfolio_Type__c == 'District Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=dmUsers[dmUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                }
                
                if(portfolio.Portfolio_Type__c == 'Area Booking Manager'){
                    portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
					portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                }
            }else if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE){
                if(portfolio.Portfolio_Type__c == 'Account Manager'){
                	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultStartDate+365));
                    if(supIndex > 0)
                    	portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Parent_Portfolio__c,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Parent_Portfolio__r.Portfolio_Type__c,Start_Date__c=defaultStartDate+366 ,End_Date__c=defaultEndDate));
                	supIndex++;
                }
            }else{
                portAssigment.add(new Portfolio_Assignment__c(BSF_Portfolio__c=portfolio.Id,User__c=drdUsers[drdUserIndex++].Id,Assignment_Type__c=portfolio.Portfolio_Type__c,Start_Date__c=defaultStartDate ,End_Date__c=defaultEndDate));
            }
        } 
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portAssigment;
        triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        System.debug('Portfolios have been assigned ');
        
        System.debug(' portfolios '+portfolios);
        
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        AccountPortfolioAssignmentHelper.processTaxonomyData(1001);
        TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        //List<Account_Portfolio_Assignment__c> apaList = [select id,Start_Date__c,End_Date__c,BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Taxonomy_Type__c,BSF_Portfolio__r.Account_Based_Portfolio__c from Account_Portfolio_Assignment__c where Account__c=:account.id];
        //system.debug('apaList:'+apaList);
        
        test.startTest();
        Account acc = [select id,BillingPostalCode from account where BillingPostalCode='48420'];
		list<Account_Portfolio_Assignment__c> existingAccPortAssg = [select id, Account__c from Account_Portfolio_Assignment__c where Account__c =:acc.id]; 
        system.debug('existingAccPortAssg'+existingAccPortAssg);
        acc.BillingPostalCode = '48421';
        update acc;
        test.stopTest();
        
    }
    
    @isTest static void testAccountPortfolioAssignment14(){
        //covers CreateDefaultTerritory portfolio batch 
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
              }
        }
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        //AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        //AccountPortfolioAssignmentHelper.processTaxonomyData(1001);
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48421' limit 1];
        
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
        
        //List<Account_Portfolio_Assignment__c> apaList = [select id,Start_Date__c,End_Date__c,BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Taxonomy_Type__c,BSF_Portfolio__r.Account_Based_Portfolio__c from Account_Portfolio_Assignment__c where Account__c=:account.id];
        //system.debug('apaList:'+apaList);
        
        
        
					
        account.BillingPostalCode = '48420';
        update account;
        Test.stopTest();
       
        
        
    }
    @isTest static void testAccountPortfolioAssignment15(){
        //covers CreateDefaultTerritory portfolio batch 
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
              }
        }
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        //AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        //AccountPortfolioAssignmentHelper.processTaxonomyData(1001);
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48421' limit 1];
        
        
        
        //List<Account_Portfolio_Assignment__c> apaList = [select id,Start_Date__c,End_Date__c,BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Taxonomy_Type__c,BSF_Portfolio__r.Account_Based_Portfolio__c from Account_Portfolio_Assignment__c where Account__c=:account.id];
        //system.debug('apaList:'+apaList);
        
        
        
					
        account.BillingPostalCode = '48420';
        update account;
        Test.stopTest();
       
        
        
    }
    
    @isTest static void testAccountPortfolioAssignment16(){
        //covers CreateDefaultTerritory portfolio batch 
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
              }
        }
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        //Account_Portfolio_Assignment__c ap = [select id,BSf_portfolio__c from Account_Portfolio_Assignment__c where (Account__c=:account.id and BSf_portfolio__r.Territory_Portfolio__c=true) limit 1];
        //system.debug('ap'+ap);
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
        
        //List<Account_Portfolio_Assignment__c> apaList = [select id,Start_Date__c,End_Date__c,BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Taxonomy_Type__c,BSF_Portfolio__r.Account_Based_Portfolio__c from Account_Portfolio_Assignment__c where Account__c=:account.id];
        //system.debug('apaList:'+apaList);
        
        
        /*DefaultTerritoryPortfolioBatchScheduler acctSponsorRecognSch = new DefaultTerritoryPortfolioBatchScheduler(100);
 		System.schedule('Update Account Sponsor Recognition Batch1', '0 0 21 * * ?', acctSponsorRecognSch );
        CreateDefaultTerritoryPortfolioBatch defaultAccPortBatch  = new CreateDefaultTerritoryPortfolioBatch();
        Database.executeBatch(defaultAccPortBatch);*/

       
        Test.stopTest();
        BSF_Portfolio__c bsfPort = [select id,Start_Date__c,End_Date__c from BSF_Portfolio__c where id=:accountPorfolio.Id  limit 1];
        bsfPort.End_Date__c = System.today().addDays(100);
        update bsfPort;
        //account a = [select Account_AM_Portfolio_Type__c from account where id =:account.id];
        //system.assert(a.Account_AM_Portfolio_Type__c);
        
    }
    
    @isTest static void testAccountPortfolioAssignment17()
    {
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        Account mobileAcc2 = new Account(
            id=account.id,
        	BillingStreet = 'PO BOX 2', 
        	BillingCity = 'COLUMBIAVILLE',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48421'
        );
        test.startTest();
        update mobileAcc2;
        test.stopTest();
    }
    
    @isTest static void testAccountPortfolioAssignment18()
    {
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        Account mobileAcc2 = new Account(
            id=account.id,
        	BillingStreet = 'PO BOX 2', 
        	BillingCity = 'COLUMBIAVILLE',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48421'
        );
        
        BSF_Portfolio__c portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c where Taxonomy_Type__c='Bio Account Portfolio' and Portfolio_Type__c='Account Manager'   limit 1];
            
        Datetime myDT = System.today();
        AccountBasedPortfolioClass.AccountPortfolioWrapper accountPortfolioAssignment = new AccountBasedPortfolioClass.AccountPortfolioWrapper();
        accountPortfolioAssignment.selectedPortfolioType = BSF_Constants.ACCOUNT_PORTFOLIO;
        accountPortfolioAssignment.accountRecid = account.id;
        accountPortfolioAssignment.Start_Date = myDT.format('yyyy-MM-dd');
        accountPortfolioAssignment.End_Date = myDT.addDays(200).format('yyyy-MM-dd');
        accountPortfolioAssignment.portfolioRecId  = portfolios.Id;  
        accountPortfolioAssignment.selectedAccountbasedreason=new list<string>{'Hospital Partner'};
        List<AccountBasedPortfolioClass.AccountPortfolioWrapper> apwrp = new List<AccountBasedPortfolioClass.AccountPortfolioWrapper>();
        apwrp.add(accountPortfolioAssignment);
        String accportfoliodata = JSON.serialize(apwrp);
        AccountBasedPortfolioClass.createAccountPortfolioData(accportfoliodata);
        List<Account_Portfolio_Assignment__c> AccPortfolioList =[SELECT Id,Account__c,Start_Date__c,End_Date__c,Portfolio_Type__c,BSF_Portfolio__c,BSF_Portfolio__r.Account_Based_Portfolio__c,BSF_Portfolio__r.Territory_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c,Bsf_Portfolio__r.Parent_Portfolio__c,
                                                                 Bsf_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,Bsf_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,Bsf_Portfolio__r.Portfolio_Code__c,BSF_Portfolio__r.Taxonomy_Type__c from Account_Portfolio_Assignment__c where Account__c=:account.id and BSF_portfolio__c=:portfolios.Id limit 1];
        DefaultTerritoryPortfolioBatchHelper.createDefaultTerritoryPortfolioRecords(AccPortfolioList);
        
        test.startTest();
        update mobileAcc2;
        test.stopTest();
    }
    
    static testMethod void testErrorMethod() {
        User DRDUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'drdmanageruser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert DRDUser;
         
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
        Profile drdProfile = null;
        for(Profile pf:[SELECT Id,Name FROM Profile WHERE Name IN ('DRD Profile','DRD Manager')]){
            if(pf.Name == 'DRD Profile'){
                drdProfile = pf;
            }
        }
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);        
        insert drdUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        BSF_Portfolio__c accountPorfolio = null;
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Code__c , Portfolio_Name__c ,Taxonomy_Type__c,Portfolio_Type__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c  FROM BSF_Portfolio__c];
        Integer drdUserIndex = 0;
        
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
                
                
            }
        } 
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
		 insert portAssigment;
 		 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');       
         AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        
         Test.startTest();
         List<Account_Portfolio_Assignment__c> accPortAssignment = [Select Id,BSF_Portfolio__c,Portfolio_Type__c from Account_Portfolio_Assignment__c];
         system.debug('accPortAssignment '+accPortAssignment);
         Database.DeleteResult[] drList = Database.Delete(accPortAssignment,false);
         AccountPortfolioAssignmentHelper helper = new AccountPortfolioAssignmentHelper();
        helper.insertErrors(drList , 'Error during deleteting default territory portfolio', 'test class');
         Test.stopTest();
          
    }
    
    @isTest static void testAccountPortfolioAssignment19(){
        //covers CreateDefaultTerritory portfolio batch 
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
              }
        }
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        //Account_Portfolio_Assignment__c ap = [select id,BSf_portfolio__c from Account_Portfolio_Assignment__c where (Account__c=:account.id and BSf_portfolio__r.Territory_Portfolio__c=true) limit 1];
        //system.debug('ap'+ap);
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
        account_portfolio_assignment__c apa = [select id from account_portfolio_assignment__c where account__c =:account.id and bsf_portfolio__c=:accountPorfolio.Id];
        delete apa;
       
        Test.stopTest();
        //BSF_Portfolio__c bsfPort = [select id,Start_Date__c,End_Date__c from BSF_Portfolio__c where id=:accountPorfolio.Id  limit 1];
        //bsfPort.End_Date__c = System.today().addDays(100);
        //update bsfPort;
        //account a = [select Account_AM_Portfolio_Type__c from account where id =:account.id];
        //system.assert(a.Account_AM_Portfolio_Type__c);
        
    }
    @isTest static void testAccountPortfolioAssignment20(){
        //covers CreateDefaultTerritory portfolio batch 
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
              }
        }
        
         triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
insert portAssigment;
 triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
       
        //AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        
        Account account = [Select Id,BillingPostalCode from Account where BillingPostalCode = '48420' limit 1];
        //Account_Portfolio_Assignment__c ap = [select id,BSf_portfolio__c from Account_Portfolio_Assignment__c where (Account__c=:account.id and BSf_portfolio__r.Territory_Portfolio__c=true) limit 1];
        //system.debug('ap'+ap);
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
        
        BSF_Batch_CreateDefaultPortfolioAssign batch = new BSF_Batch_CreateDefaultPortfolioAssign();
         database.executeBatch(batch);
        test.startTest();
        account_portfolio_assignment__c apa = [select id from account_portfolio_assignment__c where account__c =:account.id and bsf_portfolio__c=:accountPorfolio.Id];
        delete apa;
       
        Test.stopTest();
        //BSF_Portfolio__c bsfPort = [select id,Start_Date__c,End_Date__c from BSF_Portfolio__c where id=:accountPorfolio.Id  limit 1];
        //bsfPort.End_Date__c = System.today().addDays(100);
        //update bsfPort;
        //account a = [select Account_AM_Portfolio_Type__c from account where id =:account.id];
        //system.assert(a.Account_AM_Portfolio_Type__c);
        
    }
}