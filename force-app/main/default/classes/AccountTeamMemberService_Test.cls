@isTest
public class AccountTeamMemberService_Test {

    @testSetup static void createData(){
        skedHubBase.BypassInsertTriggers = true;
        //TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        TriggerHandler.clearBypass('OpportunityHandler');
        //TriggerHandler.clearBypass('AccountTriggerHandler');
        skedHubBase.BypassInsertTriggers = false;
        
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
    }
    
    
    public static List<User> populateUserFields(String firstName,String lastName,Id profileId,Integer count){
        List<User> users = new List<User>();
        for(Integer index=1;index<=count;index++){
            User user1 = new User(Alias = firstName+index, FirstName = firstName+index, Email=firstName+index+'.'+lastName+index+'@test.com',EmailEncodingKey='UTF-8', LastName=lastName+index, LanguageLocaleKey='en_US', 
            	LocaleSidKey='en_US', ProfileId = profileId, TimeZoneSidKey='America/Los_Angeles', UserName=firstName+index+'.'+lastName+index+'@test.com.tst1',CommunityNickname=firstName+index+'.'+lastName+index+'@test.com.tst1');
        	users.add(user1);
        }
        return users;
    }
    
    public static Portfolio_Assignment__c portfolioAssignments(BSF_Portfolio__c bsfPortfolio,user u)
    {
        Portfolio_Assignment__c portfolioAssignment= new Portfolio_Assignment__c();
        portfolioAssignment.Assignment_Type__c =bsfPortfolio.Portfolio_Type__c;
        portfolioAssignment.BSF_Portfolio__c =bsfPortfolio.id;
        portfolioAssignment.User__c = u.Id;
        portfolioAssignment.Start_Date__c = system.today()-10;
        portfolioAssignment.End_Date__c = system.today()+100;
         
        return portfolioAssignment;
    }
    @isTest static void testAccountTeamMemberService1(){
        Opportunity mobileOpportunity = [Select Id,Name,AccountId,Drive_Date__c FROM Opportunity Where Is_Template__c = FALSE AND RecordType.DeveloperName = 'Mobile_Opp' Limit 1];
        Account act = new Account(Id=mobileOpportunity.AccountId,BillingPostalCode='48420');
        TriggerHandler.bypass('AccountTriggerHandler');
        update act;
       TriggerHandler.clearBypass('AccountTriggerHandler');
        
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('UserTriggerHandler');
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
        BSF_Portfolio__c accountPorfolio = null;
        
        for(BSF_Portfolio__c portfolio:portfolios){
            if(portfolio.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                if(portfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE){
                    accountPorfolio = portfolio;
                }
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
        
        BSF_Constants.skipPortfolioAssignmentTrigger = true;
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portAssigment;
        triggerHandler.clearbypass('PortfolioAssignmentTriggerHandler');
        
        
        Test.startTest();
		AccountPortfolioAssignmentHelper.processTaxonomyData(1000);
        triggerHandler.bypass('UserTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
         TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Datetime myDT = System.today()+4;
        AccountBasedPortfolioClass.AccountPortfolioWrapper accountPortfolioAssignment = new AccountBasedPortfolioClass.AccountPortfolioWrapper();
        accountPortfolioAssignment.selectedPortfolioType = BSF_Constants.ACCOUNT_PORTFOLIO;
        accountPortfolioAssignment.accountRecid = mobileOpportunity.AccountId;
        accountPortfolioAssignment.Start_Date = myDT.format('yyyy-MM-dd');
        accountPortfolioAssignment.End_Date = myDT.addDays(200).format('yyyy-MM-dd');
        accountPortfolioAssignment.portfolioRecId  = accountPorfolio.Id;  
        List<AccountBasedPortfolioClass.AccountPortfolioWrapper> apwrp = new List<AccountBasedPortfolioClass.AccountPortfolioWrapper>();
        apwrp.add(accountPortfolioAssignment);
        String accportfoliodata = JSON.serialize(apwrp);
        try{
          AccountBasedPortfolioClass.createAccountPortfolioData(accportfoliodata);  
        }catch(Exception ex)
        {
            
        }
        
        
        /*User dmuser = [Select Id,Name from User Where Id In (Select UserId from AccountTeamMember Where AccountId = :mobileOpportunity.AccountId AND TeamMemberRole = 'District Manager') limit 1];
        List<AccountTeamMember> coveringRecruiterList = new List<AccountTeamMember>();
        AccountTeamMember coveringRecruiter1 = new AccountTeamMember(AccountId=mobileOpportunity.AccountId,Coverage_Reason__c='Leave of Absence (LOA)',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-1].Id);
        coveringRecruiter1.Is_Covering_Recruiter__c = true;
        coveringRecruiter1.Start_Date__c = System.today()-2;
        coveringRecruiter1.End_Date__c = System.today()+30;
        AccountTeamMember coveringRecruiter2 = new AccountTeamMember(AccountId=mobileOpportunity.AccountId,Coverage_Reason__c='Vacant Territory',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-2].Id);
        coveringRecruiter2.Is_Covering_Recruiter__c = true;
        coveringRecruiter2.Start_Date__c = System.today()+50;
        coveringRecruiter2.End_Date__c = System.today()+100;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
        
        coveringRecruiterList.add(coveringRecruiter1);
        coveringRecruiterList.add(coveringRecruiter2);
        
        insert coveringRecruiterList;
        
        coveringRecruiter1.Start_Date__c = System.today()+50;
        coveringRecruiter1.End_Date__c = System.today()+100;
        coveringRecruiter2.Start_Date__c = System.today()-2;
        coveringRecruiter2.End_Date__c = System.today()+30;
        update coveringRecruiterList;
        
        System.runAs(dmuser){
            coveringRecruiter2.Is_Covering_Recruiter__c = false;
            database.update(coveringRecruiterList,false);
        }
        
		
        //AccountTeamMemberHelper.getAccountTeamMembers(new List<Id>{mobileOpportunity.AccountId});
*/
        
        Test.stopTest();
    }
    
    @isTest static void testAccountTeamMemberService2(){
        Opportunity mobileOpportunity = [Select Id,Name,AccountId,Drive_Date__c FROM Opportunity Where Is_Template__c = FALSE AND RecordType.DeveloperName = 'Mobile_Opp' Limit 1];
        Account act = new Account(Id=mobileOpportunity.AccountId,BillingPostalCode='48420');
        TriggerHandler.bypass('AccountTriggerHandler');
        update act;
       TriggerHandler.clearBypass('AccountTriggerHandler');
        
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('UserTriggerHandler');
        //create users
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        insert drdUsers;
        insert dmUsers;
        
        test.startTest();
         List<AccountTeamMember> coveringRecruiterList = new List<AccountTeamMember>();
        AccountTeamMember atm1 = new AccountTeamMember(AccountId=mobileOpportunity.AccountId,TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-1].Id);
        
        atm1.Start_Date__c = System.today()-2;
        atm1.End_Date__c = System.today()+30;
        AccountTeamMember atm2 = new AccountTeamMember(AccountId=mobileOpportunity.AccountId,TeamMemberRole='District Manager',UserId=dmUsers[dmUsers.size()-1].Id);
        
        atm2.Start_Date__c = System.today()+50;
        atm2.End_Date__c = System.today()+100;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = true;
        
        coveringRecruiterList.add(atm1);
        coveringRecruiterList.add(atm2);
        
        insert coveringRecruiterList;
        
        atm2.End_Date__c=System.today()+101;
        update atm2;
        
        
        test.stopTest();
        
    }
    
    @isTest
    public static void testMethodAccTeam()
    {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        list<opportunity> opportunityList = new list<opportunity>();
        
        
       Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(55),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
        opportunityList.add(testMobileOpp1);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opportunityList;
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        List<AccountTeamMember> coveringRecruiterList = new List<AccountTeamMember>();
        AccountTeamMember coveringRecruiter1 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Leave of Absence (LOA)',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-1].Id);
        coveringRecruiter1.Is_Covering_Recruiter__c = true;
        coveringRecruiter1.Start_Date__c = System.today()-2;
        coveringRecruiter1.End_Date__c = System.today()+30;
        AccountTeamMember coveringRecruiter2 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Vacant Territory',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-2].Id);
        coveringRecruiter2.Is_Covering_Recruiter__c = true;
        coveringRecruiter2.Start_Date__c = System.today()+50;
        coveringRecruiter2.End_Date__c = System.today()+100;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
        
        coveringRecruiterList.add(coveringRecruiter1);
        coveringRecruiterList.add(coveringRecruiter2);
        test.startTest();
        insert coveringRecruiterList;
        test.stopTest();
    }
    
    @isTest
    public static void testMethodDelAccTeam()
    {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        list<opportunity> opportunityList = new list<opportunity>();
        
        
       Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(55),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
       opportunityList.add(testMobileOpp1);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opportunityList;
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        List<AccountTeamMember> coveringRecruiterList = new List<AccountTeamMember>();
        AccountTeamMember coveringRecruiter1 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Leave of Absence (LOA)',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-1].Id);
        coveringRecruiter1.Is_Covering_Recruiter__c = true;
        coveringRecruiter1.Start_Date__c = System.today()-2;
        coveringRecruiter1.End_Date__c = System.today()+30;
        AccountTeamMember coveringRecruiter2 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Vacant Territory',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-2].Id);
        coveringRecruiter2.Is_Covering_Recruiter__c = true;
        coveringRecruiter2.Start_Date__c = System.today()+50;
        coveringRecruiter2.End_Date__c = System.today()+100;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
        
        coveringRecruiterList.add(coveringRecruiter1);
        coveringRecruiterList.add(coveringRecruiter2);
        test.startTest();
        insert coveringRecruiterList;
        
        delete coveringRecruiterList;
        test.stopTest();
    }
    
    @isTest
    public static void testMethodPortAccTeam()
    {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        list<opportunity> opportunityList = new list<opportunity>();
        
        
       Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(55),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
       opportunityList.add(testMobileOpp1);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opportunityList;
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Taxonomy_type__c=BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE;
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        
        insert DMPortfolio;
        
        
        BSF_Portfolio__c ABMPortfolio = new BSF_Portfolio__c();
        ABMPortfolio.Portfolio_Code__c = 'NA_Detorit_ABM_1';
        ABMPortfolio.Portfolio_Name__c = 'NA_Detorit_ABM_1';
        ABMPortfolio.Portfolio_Type__c = BSF_Constants.AREA_BOOKING_MANAGER;
        ABMPortfolio.Account_Based_Portfolio__c = false;
        ABMPortfolio.Territory_Portfolio__c = true;
        ABMPortfolio.Taxonomy_type__c=BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE;
        ABMPortfolio.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager'].Id; 
        
        insert ABMPortfolio;
        
        BSF_Portfolio__c AMPortfolioWithABM = new BSF_Portfolio__c();
        AMPortfolioWithABM.Portfolio_Name__c = 'Detroit South 05';
        AMPortfolioWithABM.Portfolio_Code__c = 'HProdSEMR_1836';
        AMPortfolioWithABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithABM.Territory_Portfolio__c = true;
        AMPortfolioWithABM.Taxonomy_type__c=BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE;
        AMPortfolioWithABM.Portfolio_Type__c = BSF_Constants.ACCOUNT_MANAGER;
        AMPortfolioWithABM.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c =:BSF_Constants.AREA_BOOKING_MANAGER].Id; 
        
        insert AMPortfolioWithABM;
        
        BSF_Portfolio__c AMPortfolioWithoutABM = new BSF_Portfolio__c();
        AMPortfolioWithoutABM.Portfolio_Name__c = 'Detroit South 07';
        AMPortfolioWithoutABM.Portfolio_Code__c = 'HProdSEMR_1837';
        AMPortfolioWithoutABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithoutABM.Territory_Portfolio__c = true;
        AMPortfolioWithoutABM.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithoutABM.Parent_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c WHERE Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager'].Id; 
        
        insert AMPortfolioWithoutABM;
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
        List<Portfolio_Assignment__c> portfolioAssignmentList = new List<Portfolio_Assignment__c>();
        portfolioAssignmentList.add(portfolioAssignments(DMPortfolio,dmUsers[0]));
        portfolioAssignmentList.add(portfolioAssignments(ABMPortfolio,drdUsers[1]));
        portfolioAssignmentList.add(portfolioAssignments(AMPortfolioWithABM,drdUsers[2]));
        portfolioAssignmentList.add(portfolioAssignments(AMPortfolioWithoutABM,drdUsers[3]));
        
        
        
        List<Account_Portfolio_Assignment__c> accPortfolioAssignemnetList = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c accPortfolio1 = new Account_Portfolio_Assignment__c();
        accPortfolio1.BSF_Portfolio__c =AMPortfolioWithABM.id;
        accPortfolio1.Account__c = testMobileAccount.Id;
        accPortfolio1.Start_Date__c = SYstem.today();
        accPortfolio1.End_Date__c = System.today() +100;
        
        accPortfolioAssignemnetList.add(accPortfolio1);
        
        insert accPortfolioAssignemnetList;
        test.StartTest();
        system.debug('testMobileAccount.Id '+testMobileAccount.Id);
        
        TriggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portfolioAssignmentList;
        TriggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
        system.debug('portfolioAssignmentList '+portfolioAssignmentList);
        AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(new list<id>{testMobileAccount.Id},null,new Set<id>(),new map<id,list<accountTeamMember>> (),new map<id,list<accountTeamMember>> ());
        
        
        AccountTeamMember atm = [select id from accountTeamMember where accountId=:testMobileAccount.Id limit 1];
        
        bsf_constants.isTeamMemberCreatedFromBackend=false;
        delete atm;
        test.stopTest();
    }
    
    @isTest 
    static void testdetermineTaskOwner(){
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        list<opportunity> opportunityList = new list<opportunity>();
        
        
       Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(55),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
        opportunityList.add(testMobileOpp1);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opportunityList;
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        Task testTask = new Task(
            WhatId = testMobileAccount.Id,
            Subject = Task_Reassignment_Matrix__mdt.getInstance('Renew_Military_MoA').Task_Subject__c,         
            Status = 'Not Started'
        );
        
        insert testTask;
        
        
        List<AccountTeamMember> coveringRecruiterList = new List<AccountTeamMember>();
        AccountTeamMember coveringRecruiter1 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Leave of Absence (LOA)',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-1].Id);
        coveringRecruiter1.Is_Covering_Recruiter__c = true;
        coveringRecruiter1.Start_Date__c = System.today()-2;
        coveringRecruiter1.End_Date__c = System.today()+30;
        AccountTeamMember coveringRecruiter2 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Vacant Territory',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-2].Id);
        coveringRecruiter2.Is_Covering_Recruiter__c = true;
        coveringRecruiter2.Start_Date__c = System.today()+50;
        coveringRecruiter2.End_Date__c = System.today()+100;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
        
        coveringRecruiterList.add(coveringRecruiter1);
        coveringRecruiterList.add(coveringRecruiter2);
        test.startTest();
        insert coveringRecruiterList;
        test.stopTest();
        
        
    }
}