@isTest
private class OpportunitySplitTriggerTest {
    
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //Create DRD Users
        List<User> testUsers = new List<User>();
        testUsers.add((User)mapTestData.get('DRD_USER'));
        testUsers.add((User)mapTestData.get('DRD_MANAGER_USER'));
        system.runAs(new User(Id = UserInfo.getUserId())) {
            for(User testUser : testUsers) {
                testUser.IsActive = true;
            }
        	insert testUsers;   
        }
        
        //insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        insert testMobileAccount;
        
        //insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.Id;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert mobile opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
      
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = testUsers[0].Id ;
        atm.AccountId = testMobileAccount.Id ;
        atm.TeamMemberRole = 'Account Specialist';
        atm.End_Date__c = Date.Today().addDays(10);
        atm.Start_Date__c = Date.Today().addDays(-10);
        atm.Coverage_Reason__c = 'Vacant Territory';      
        atmList.add(atm);
        
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = UserInfo.getUserId();
        atm.AccountId = testMobileAccount.Id ;
        atm.TeamMemberRole = 'Recruiter';
        atm.End_Date__c = Date.Today().addDays(10);
        atm.Start_Date__c = Date.Today().addDays(-10);
        atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        insert atmList;

        List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
        
        BSF_Portfolio__c Portland_OR_AM_01 = new BSF_Portfolio__c();			
        Portland_OR_AM_01.Name='Portland OR AM 01';
        Portland_OR_AM_01.Account_Based_Portfolio__c= true;			
        Portland_OR_AM_01.External_Key__c='Account_BD36_21E_NW_Portland OR_Portland OR ABM 01 03 07 08_Portland OR AM 01';
        Portland_OR_AM_01.Portfolio_Code__c='Portland OR AM 01';
        Portland_OR_AM_01.Portfolio_Name__c='Portland OR AM 01';
        Portland_OR_AM_01.Portfolio_Type__c='Account Manager';
        Portland_OR_AM_01.Taxonomy_Type__c='Account Specialist';
        Portland_OR_AM_01.Territory_Portfolio__c=false;			
        bsfPortf.add(Portland_OR_AM_01);
        
        BSF_Portfolio__c Greater_Alleghenies_DRA_01 = new BSF_Portfolio__c();
        Greater_Alleghenies_DRA_01.Name='Greater Alleghenies DRA 01';
        Greater_Alleghenies_DRA_01.Account_Based_Portfolio__c = true;
        Greater_Alleghenies_DRA_01.External_Key__c='Booking Support_BD32_27E_Greater Alleghenies DRA 01';
        Greater_Alleghenies_DRA_01.Portfolio_Code__c='Greater Alleghenies DRA 01';
        Greater_Alleghenies_DRA_01.Portfolio_Name__c='Greater Alleghenies DRA 01';
        Greater_Alleghenies_DRA_01.Portfolio_Type__c=BSF_Constants.Booking_Support;
        Greater_Alleghenies_DRA_01.Taxonomy_Type__c='Bio Booking Support';
        Greater_Alleghenies_DRA_01.Territory_Portfolio__c= false;
        bsfPortf.add(Greater_Alleghenies_DRA_01);
        
        BSF_Portfolio__c American_Red_Cross = new BSF_Portfolio__c();
        American_Red_Cross.Name='American Red Cross';
        American_Red_Cross.Account_Based_Portfolio__c=true;
        American_Red_Cross.External_Key__c='National Account_1';
        American_Red_Cross.Portfolio_Code__c='1';
        American_Red_Cross.Portfolio_Name__c='American Red Cross';
        American_Red_Cross.Portfolio_Type__c='National Account Manager';
        American_Red_Cross.Taxonomy_Type__c='National Account Manager Portfolio';
        American_Red_Cross.Territory_Portfolio__c=false;
        bsfPortf.add(American_Red_Cross);
        
        BSF_Portfolio__c Sickle_Cell_AM_04 = new BSF_Portfolio__c();
        Sickle_Cell_AM_04.Name='Sickle Cell AM 04';
        Sickle_Cell_AM_04.Account_Based_Portfolio__c=true;
        Sickle_Cell_AM_04.External_Key__c='Sickle Cell_53E_SAM04';
        Sickle_Cell_AM_04.Portfolio_Code__c='SAM04';
        Sickle_Cell_AM_04.Portfolio_Name__c='Sickle Cell AM 04';
        Sickle_Cell_AM_04.Portfolio_Type__c='District Manager';
        Sickle_Cell_AM_04.Taxonomy_Type__c='Bio Sickle Cell Portfolio';
        Sickle_Cell_AM_04.Territory_Portfolio__c=false;
        bsfPortf.add(Sickle_Cell_AM_04);
        insert bsfPortf;
			
        List<Portfolio_Assignment__c> portfAssignList = new List<Portfolio_Assignment__c>();
        
        Portfolio_Assignment__c assign1 = new Portfolio_Assignment__c();
        assign1.Assignment_Type__c = 'District Manager';
        assign1.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
        assign1.End_Date__c = Date.Today().addDays(10);
        assign1.Start_Date__c = Date.Today().addDays(-10);
        assign1.User__c = testUsers[1].Id;
        portfAssignList.add(assign1);
        
        Portfolio_Assignment__c assign2 = new Portfolio_Assignment__c();
        assign2.Assignment_Type__c = 'District Manager';
        assign2.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
        assign2.End_Date__c = Date.Today().addDays(10);
        assign2.Start_Date__c = Date.Today().addDays(-10);
        assign2.User__c = testUsers[1].Id;
        portfAssignList.add(assign2);
        insert portfAssignList;
  
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
  }
    
    /*@isTest static void allowSpecificProfileUsers() {        
          
      Id adminprofileid = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id ;
	  User adminuser = [ select Id from User where ProfileId =: adminprofileid and isActive = true limit 1];
      
      System.runAs( adminuser ){
        List<Opportunity> opps = new List<Opportunity>();
        opps = [ select Id from Opportunity limit 20];
        
        List<OpportunitySplit> opsplits = new List<OpportunitySplit>();                
        OpportunitySplit opsplit;
                
        opsplit = new OpportunitySplit();
        opsplit.OpportunityId = opps[0].Id;
        opsplit.Is_Covering_Incentive__c = false;
        opsplit.SplitNote = 'test';
        opsplit.Split_Amount__c = 20;
        opsplit.Split_Reason__c = 'Coverage Vacancy';
        opsplit.SplitOwnerId = adminuser.Id;
        opsplits.add( opsplit );
        
        opsplit = new OpportunitySplit();
        opsplit.OpportunityId = opps[1].Id;
        opsplit.Is_Covering_Incentive__c = false;
        opsplit.SplitNote = 'test';
        opsplit.Split_Amount__c = 20;
        opsplit.Split_Reason__c = 'Coverage Vacancy';
        opsplit.SplitOwnerId = adminuser.Id;
        opsplits.add( opsplit );
                
            try{
                insert opsplits[0];
            }catch(Exception e){
                String exceptionmsg = 'Only Account Specialist or District Manager is allowed to edit and apply. Currently there are no Account Specialist avaialble in Account Team';
                String exceptionmsg2 = 'Only Account Specialist and District Managers are allowed to edit Opportunity Split';
               System.debug( 'exc msg=>' + e.getMessage() );
                String excmsg = e.getMessage();
                System.assert( excmsg.contains( exceptionmsg2 ) );
            }
                
            try{
                insert opsplits[1];
            }catch(Exception e){
                String exceptionmsg = 'Only Account Specialist or District Manager is allowed to edit and apply. Currently there are no Account Specialist avaialble in Account Team';
                String exceptionmsg2 = 'Only Account Specialist and District Managers are allowed to edit Opportunity Split';
               // System.debug( 'exc msg=>' + e.getMessage() );
                String excmsg = e.getMessage();
                System.assert( excmsg.contains( exceptionmsg ) );
            }
      
      }
            
    }*/
	
	@isTest static void addTeamMemberPortfolioTest() {
		Test.startTest();

		User drduser = [SELECT Id FROM User WHERE LastName = 'DRDManagerLastName' and IsActive = true LIMIT 1];

		System.runAs(drduser) {
            List<Account_Portfolio_Assignment__c> aps = new List<Account_Portfolio_Assignment__c>();
            Account_Portfolio_Assignment__c apAssignment1 = new Account_Portfolio_Assignment__c();
            
            apAssignment1.account__c = [SELECT Id FROM Account LIMIT 1].Id;
            apAssignment1.BSF_Portfolio__c = [SELECT Id FROM BSF_Portfolio__c LIMIT 1].Id;
            aps.add(apAssignment1);

            OpportunitySplit opsplit = new OpportunitySplit();
			opsplit.OpportunityId = [SELECT Id FROM Opportunity WHERE Is_template__c = false LIMIT 1].Id;
			opsplit.Is_Covering_Incentive__c = false;
			opsplit.SplitNote = 'test';
			opsplit.Split_Amount__c = 20;
			opsplit.Split_Reason__c = 'Coverage Vacancy';
			opsplit.SplitOwnerId = drduser.Id;
			insert opsplit;
		}
	}
}