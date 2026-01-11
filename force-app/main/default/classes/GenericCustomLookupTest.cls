/*
 * This Test class covering following class
 * GenericCustomLookup
 */

@isTest(SeeAllData=false)
private class GenericCustomLookupTest {
    
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('UserTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //Admin User
        User testAdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'testingLast',
            Email = 'adminuser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true
        );
        
        //insert DRD User
        User testDRDUser = (User)mapTestData.get('DRD_USER');
       	testDRDUser.IsActive = true;
        
        system.runAs(testAdminUser) {
            insert testDRDUser;
        }
    }
  
    @isTest static void findUser() {
        Test.startTest();
        User testDrdUser = [SELECT Id FROM User WHERE LastName = 'DRDLastName' AND Profile.Name = 'DRD Profile' LIMIT 1];
        
        System.runAs(testDrdUser) {
            List<User> sobjectlist = GenericCustomLookup.findRecords('DRD', 'User', 'Name');
            Assert.isTrue(sobjectlist.size() > 1);
        }
        
        Test.stopTest();
    }   
}