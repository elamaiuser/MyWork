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
        
        //insert DRD User
        User testDrdUser = (User)mapTestData.get('DRD_USER');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
    }
  
    @isTest static void findUser() {
        Test.startTest();
        User testDrdUser = [SELECT Id FROM User LIMIT 1];
  
        System.runAs(testDrdUser) {
            List<User> sobjectlist = GenericCustomLookup.findRecords('DRD', 'User', 'Name');
            Assert.isTrue(sobjectlist.size() > 1);
        }
        
        Test.stopTest();
    }   
}