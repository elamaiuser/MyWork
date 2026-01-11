@isTest
private class BSF_Batch_OpportunitySplitDelete_Test {
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert DRD User
        User testDrdUser = (User)mapTestData.get('DRD_MANAGER_USER');
        system.runAs(new User(Id = UserInfo.getUserId())) {
        	insert testDrdUser;
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
        
        //insert opportunity team member
        OpportunityTeamMember testOppTeamMember = new OpportunityTeamMember(
            OpportunityId = testMobileOpp.Id,
            TeamMemberRole = 'District Manager',
            UserId = testDrdUser.Id,
            Start_Date__c = system.today()
        );
        insert testOppTeamMember;
        
        //insert opportunity split
        OpportunitySplit testOpsplit = new OpportunitySplit(
            OpportunityId = testMobileOpp.Id,
            Is_Covering_Incentive__c = false,
            SplitNote = 'test',
            Split_Amount__c = 20,
            Split_Reason__c = 'Coverage Vacancy',
            SplitOwnerId = testDrdUser.Id
        );
        insert testOpsplit;
    }
        
    @isTest static void test_oppSplitDelete() { 
        Test.startTest();
        List<OpportunitySplit> opsplits = [SELECT Id FROM OpportunitySplit];
        List<OpportunityTeamMember> otmList = [SELECT Id, opportunityId, userId FROM OpportunityTeamMember];
        
        BSF_Batch_OpportunitySplitDelete batchDelete = new BSF_Batch_OpportunitySplitDelete(opsplits , otmList);
        Database.executeBatch(batchDelete);
        
        Test.stopTest();       
    }
}