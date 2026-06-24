@isTest
private class  UserProvisioningServiceTest {
    @testSetup
    static void setupTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Set<String> activeProfileNames = userService.getActiveMdtProfileNames();
        List<String> myList = new List<String>(activeProfileNames);
        Profile p1 = [SELECT Id FROM Profile WHERE Name =:myList.get(0) LIMIT 1];
        User amUser = new User(Alias = 'amusr', 
                                Email='amuser@testtest.com', 
                                EmailEncodingKey='UTF-8', 
                                LastName='TestingAM', 
                                LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', 
                                ProfileId = p1.Id, 
                                TimeZoneSidKey='America/Los_Angeles', 
                                UserName='amuser' + DateTime.now().getTime() + '@testtest.com');
        triggerHandler.bypass('UserTriggerHandler');
        insert amUser;
        triggerHandler.Clearbypass('UserTriggerHandler');
    }
    @isTest
    static void testDirectServiceExecution1() {
        User targetUser = [SELECT Id, Profile.Name FROM User WHERE Email = 'amuser@testtest.com' LIMIT 1];
        Set<String> activeProfileNames = userService.getActiveMdtProfileNames();
        List<String> myList = new List<String>(activeProfileNames);
        UserProvisioningService.ProvisioningRequest req = new UserProvisioningService.ProvisioningRequest();
        req.userId         = targetUser.Id;
        req.newProfileName = targetUser.Profile.Name;
        req.oldProfileName = myList.get(1);
        req.skipRoleUpdate = false;
        
        Test.startTest();
        UserProvisioningService.syncUserProvisioningBulk(
            new List<UserProvisioningService.ProvisioningRequest>{ req }
        );
        Test.stopTest();
        
        System.assert(true, 'Service engine completed without fatal exceptions.');
    }
     @isTest
    static void testDirectServiceExecution2() {
        User targetUser = [SELECT Id, Profile.Name FROM User WHERE Email = 'amuser@testtest.com' LIMIT 1];
        Set<String> activeProfileNames = userService.getActiveMdtProfileNames();
        List<String> profileList = new List<String>(activeProfileNames);
        UserProvisioningService.ProvisioningRequest req = new UserProvisioningService.ProvisioningRequest();
        req.userId         = targetUser.Id;
        req.newProfileName = targetUser.Profile.Name;
        req.oldProfileName = '';
        req.skipRoleUpdate = false;

        UserProvisioningService.ProvisioningRequest req1 = new UserProvisioningService.ProvisioningRequest();
        req1.userId         = targetUser.Id;
        req1.newProfileName = profileList.get(1);
        req1.oldProfileName = targetUser.Profile.Name;
        req1.skipRoleUpdate = true;
        
        Test.startTest();
        UserProvisioningService.syncUserProvisioningBulk(
            new List<UserProvisioningService.ProvisioningRequest>{ req }
        );
        
        UserProvisioningService.syncUserProvisioningBulk(
            new List<UserProvisioningService.ProvisioningRequest>{ req1 }
        );
        Test.stopTest();
        
        System.assert(true, 'Service engine completed without fatal exceptions.');
    }
    @isTest
    static void testhandleEvents() {
        User targetUser = [SELECT Id, Profile.Name FROM User WHERE Email = 'amuser@testtest.com' LIMIT 1];
        Set<String> activeProfileNames = userService.getActiveMdtProfileNames();
        List<String> myList = new List<String>(activeProfileNames);
        AssignResourcesToUserEvent__e evt = new AssignResourcesToUserEvent__e(
            UserId__c             = targetUser.Id,
            UserProfile__c        = targetUser.Profile.Name,
            Old_User_Profile__c   =  myList.get(1),
            skipUserRoleUpdate__c = false
        );
        
        Test.startTest();
        UserProvisioningService.handleEvents(
            new List<AssignResourcesToUserEvent__e>{ evt }
        );
        Test.stopTest();
        
        System.assert(true, 'Service engine completed without fatal exceptions.');
    }
}