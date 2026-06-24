@isTest
private class  assignResourcesToUsersBasedOnConfigTest {
    @testSetup
    static void setupTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Profile p1 = [SELECT Id FROM Profile WHERE Name='Global Admin' LIMIT 1];
        User amUser = new User(Alias = 'amusr', 
                                Email='amuser@testtest.com', 
                                EmailEncodingKey='UTF-8', 
                                LastName='TestingAM', 
                                LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', 
                                ProfileId = p1.Id, 
                                TimeZoneSidKey='America/Los_Angeles', 
                                UserName='amuser' + DateTime.now().getTime() + '@testtest.com');
        insert amUser;

    }
    @isTest
    static void testTriggerAndEventHandler() {
        User targetUser = [SELECT Id, Profile.Name FROM User WHERE Email = 'amuser@testtest.com' LIMIT 1];
        
        Test.startTest();
        AssignResourcesToUserEvent__e evt = new AssignResourcesToUserEvent__e(
            UserId__c             = targetUser.Id,
            UserProfile__c        = targetUser.Profile.Name,
            Old_User_Profile__c   = '',
            skipUserRoleUpdate__c = false
        );
        
        Database.SaveResult sr = EventBus.publish(evt);
        Test.stopTest();
        
        System.assertEquals(true, sr.isSuccess(), 'Platform Event should publish successfully.');
    }
}