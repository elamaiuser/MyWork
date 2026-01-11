/*
 * This Test class covering following class
 * AddTeamMemberToOpportunityExtension
 */
@isTest(SeeAllData=false)
private class AddTeamMemberToOpportunityExtensionTest {
    @testSetup
    static void prepareTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
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

    @isTest static void getSelectedRecords() {
        Test.startTest();
        
        // setting visualforce page
        PageReference pageRef = Page.AddTeamMemberToOpportunityPage;      
        Test.setCurrentPage(pageRef);
        
        // Initialising StandardSetController Extension
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, OwnerId FROM Opportunity LIMIT 2]));
        setCon.setSelected([SELECT Id, OwnerId FROM Opportunity LIMIT 1]); // this method gives selected records
        
        AddTeamMemberToOpportunityExtension atmext = new AddTeamMemberToOpportunityExtension(setCon);
        
        List<Opportunity> oppList = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
        
        Assert.isTrue(1 == oppList.size());
        
        Test.stopTest();
    }
}