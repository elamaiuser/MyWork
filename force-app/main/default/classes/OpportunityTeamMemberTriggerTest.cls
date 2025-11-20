@isTest
private class OpportunityTeamMemberTriggerTest {
    
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
        atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
        atm.End_Date__c = Date.Today().addDays(10);
        atm.Start_Date__c = Date.Today().addDays(-10);
        atmList.add(atm);
        
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = UserInfo.getUserId();
        atm.AccountId = testMobileAccount.Id ;
        atm.TeamMemberRole = 'Recruiter';
        atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
        atm.End_Date__c = Date.Today().addDays(10);
        atm.Start_Date__c = Date.Today().addDays(-10);
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
        Portland_OR_AM_01.Taxonomy_Type__c='Bio Account Portfolio';
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
    }
    
    @isTest
    private static void testTrigger1() {
        User usr = [SELECT Id FROM USER WHERE LastName = 'DRDLastName' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        
        Test.startTest();
            OpportunityTeamMember otm = new OpportunityTeamMember();
            otm.OpportunityAccessLevel = 'Edit';
            otm.userId = usr.Id;
            otm.OpportunityId = opp.Id;
            otm.TeamMemberRole = 'Account Manager';
            otm.Start_Date__c = System.today();
            insert otm;
        Test.stopTest();
        List<Team_Member_History__c> testTeamMemberHistory = [SELECT Id FROM Team_Member_History__c];
        Assert.isTrue(!testTeamMemberHistory.isEmpty()); 
    }

    //Method to get the one picklist value of the Sobject field
    private static String picklistValues(String objectName, String fieldName) {
        String result;

        List<Schema.DescribeSobjectResult> sobjectlist = Schema.describeSObjects(new List<String>{objectName});
        
        for(Schema.DescribeSobjectResult sobj : sobjectlist) {
            for (Schema.PicklistEntry entry : sobj.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    result = entry.getValue();
                    break;
                }
            }
        }
        return result;
    }
}