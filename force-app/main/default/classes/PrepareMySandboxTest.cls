@isTest
class PrepareMySandboxTest {
    

    @isTest
    static void testMySandboxPrep() {
       
        List<User>allUsers = new List<User>();
        String adminProfileId;
        
         adminProfileId = [select Id from Profile where Name = 'System Administrator'].id;
        
        for (Integer i = 0; i < 3; i++){
            
            User testUser = new User();
                testUser.Username = 'name.lname@redcross.org.biomed' +i;
                testUser.Email = 'name.lname@redcross.org.invalid';
                testUser.LastName = 'testLName';
                testUser.FirstName = 'tstFName';
                testUser.Alias = 'sv';
                testUser.ProfileID = adminProfileId;
                testUser.LocaleSidKey = 'en_US';
                testUser.LanguageLocaleKey = 'en_US';
                testUser.TimeZoneSidKey = 'America/Los_Angeles';
                testUser.EmailEncodingKey='UTF-8';
                testUser.IsActive = true;
           
            allUsers.add(testUser);            
        }
        insert allUsers;
        system.debug(allUsers);
       

        Test.startTest();

        Test.testSandboxPostCopyScript(
            new PrepareMySandbox(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());

        Test.stopTest();
            
       
        List<User>updatedAdminList = [select id, name, email from User where Profile.Name = 'System Administrator' and IsActive = true and Email like '%redcross.org.invalid' and LastName Like 'testLName'];
        System.debug('Updated Admin List' + updatedAdminList);
        System.assertEquals(0,updatedAdminList.size());
        
    }
    
}