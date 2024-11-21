@isTest
private class RemoveSkedLicenseBatchTest {

    @testSetup
    static void setupTestData() {
        // Create inactive users 
        List<User> inActiveUserList = new List<User>();
        
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Global Admin'];
        for (Integer i = 0; i < 2; i++) {

         User user = new User(
            firstName = 'test1',
            lastName = 'test2',
            profileId = prof.id,
            Username  = 'test@test.com'+UserInfo.getOrganizationId()+i,
            email = 'test@CAt.com',
            MobilePhone = '125-(455)-7890',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Alias = 'test',
            IsActive = false

         );
         
         inActiveUserList.add(user);

       }
      
        insert inActiveUserList;

        // Create UserPackageLicense records assigning sked package for inactive users 
        List<UserPackageLicense> userPackageLicenses = new List<UserPackageLicense>();
        Id packageLicenseId = '0505c000000kBuqAAE';
        for (User user : inActiveUserList) {
            userPackageLicenses.add(new UserPackageLicense(
                UserId = user.Id,
                PackageLicenseId = packageLicenseId
            ));
        }
        insert userPackageLicenses;
    }

    @isTest
    static void testBatch() {
        // Start the batch job
        Test.startTest();
        RemoveSkedLicenseForInactiveUsersBatch batchInstance = new RemoveSkedLicenseForInactiveUsersBatch();
        batchInstance.execute(null);
        Test.stopTest();
		//Assert all records are deleted
        System.assertEquals(0, [SELECT count() FROM UserPackageLicense WHERE PackageLicenseId = '0505c000000kBuqAAE' and userid in(select id from user where firstName='test1' and lastName='test2')]);
    }
}