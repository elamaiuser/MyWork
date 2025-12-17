/*
* This Test class covering following class
* AddTeamMemberToAccountExtension
*/

@isTest(SeeAllData=false)
private class AddTeamMemberToAccountExtensionTest {
    
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        insert testMobileAccount;
    }
    
    @isTest static void getSelectedRecords() {
     	Test.startTest();
            
        // setting visualforce page
        PageReference pageRef = Page.AddTeamMemberToAccountPage;      
        Test.setCurrentPage(pageRef);
        
        // Initialising StandardSetController Extension
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, OwnerId FROM Account LIMIT 2]));
        setCon.setSelected([SELECT Id, OwnerId FROM Account LIMIT 2]); // this method gives selected records
        
        AddTeamMemberToAccountExtension atmext = new AddTeamMemberToAccountExtension(setCon);
        
        List<Account> acclist = [SELECT Id, OwnerId FROM Account LIMIT 2];
        
        Assert.isTrue(1 == acclist.size());
        
        Test.stopTest();
    }
}