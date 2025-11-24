@isTest
private class BSF_Batch_OpportunityTeamMember_Test {
    
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
            for(User testUser : testUsers) {
                testUser.isActive = true;
            } 
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
        
        //insert Opportnity team members
        List<OpportunityTeamMember> testTeamMembersList = new List<OpportunityTeamMember>();
        for(User testUser : testUsers) {
            testTeamMembersList.add(new OpportunityTeamMember(
                UserId = testUser.Id,
                Start_Date__c = system.today(),
                OpportunityAccessLevel = 'Edit',
                OpportunityId = testMobileOpp.Id
            ));
        }
        insert testTeamMembersList;
    }

    @isTest
    static void batchTest() {
        Test.startTest();
        BSF_Batch_OpportunityTeamMember batch = new BSF_Batch_OpportunityTeamMember(new List<OpportunityTeamMember>{[SELECT Id, opportunityId, UserId FROM OpportunityTeamMember LIMIT 1]},new List<OpportunityTeamMember>(),'Delete',false,0);
        Database.executeBatch(batch);
        Test.stopTest();
    }
}