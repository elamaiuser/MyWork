/*
* This Test class covering following class
* AddTeamMemberToOpportunity
*/  

@isTest(SeeAllData=false)
private class AddTeamMemberToOpportunityTest {
    
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
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
        	insert testUsers;   
        }
        
        //insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        insert testMobileAccount;
        
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
    }
      
    @isTest static void addOpportunityTeamMemberTest() {
        Test.startTest();
        
        List<String> selectedIdsList = new List<String>();
        selectedIdsList.add([SELECT Id FROM Opportunity WHERE Is_Template__c = false LIMIT 1].Id);
        
        AddTeamMemberToOpportunity.AddTeamMember  testOppTeamMember = new AddTeamMemberToOpportunity.AddTeamMember();
        testOppTeamMember.userId = [SELECT Id FROM User WHERE Profile.Name = 'DRD Manager' LIMIT 1].Id;
        testOppTeamMember.teamRole = 'Account Manager';
        testOppTeamMember.bloodDriveAccessLevel = 'Edit';
        
        String otmJson = JSON.serialize(testOppTeamMember);
        
        AddTeamMemberToOpportunity.addOpportunityTeamMember( otmJson, selectedIdsList);
        
        Test.stopTest();
        
        Integer oppTeamMemberItemCount = [SELECT count() FROM OpportunityTeamMember]; 
        Assert.isTrue(oppTeamMemberItemCount != 0);
    }
}