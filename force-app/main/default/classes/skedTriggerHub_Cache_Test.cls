@isTest
private class skedTriggerHub_Cache_Test {
    
    static testmethod void getAutoProcessUserFromCache() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Test.startTest();
        
        User testUser = skedTriggerHub_Cache.getAutoProcessUserFromCache();
        sked__Resource__c testResource = skedTriggerHub_Cache.getCurrentUserResource();
        User loginUser = skedTriggerHub_Cache.loginUser;
        boolean isAdmin = skedTriggerHub_Cache.isAdminUser;
        skedTriggerHub_Cache.setIsAdminUser(FALSE);
        skedTriggerHub_Cache.getProfileForId(loginUser.ProfileId);
        skedTriggerHub_Cache.getPermissionSetsForUser(loginUser.Id);
        
        Test.stopTest();
    }
    
}