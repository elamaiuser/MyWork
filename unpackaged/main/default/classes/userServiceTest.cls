@isTest
public class userServiceTest {
    
    @testSetup static void testSetup(){  
		
        List<User> userList = new List<User>();
        
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Global Admin'];
        
        User user = new User(
            firstName = 'test1',
            lastName = 'test2',
            profileId = prof.id,
            Username  = 'test@CAt.com'+UserInfo.getOrganizationId(),
            email = 'test@CAt.com',
            MobilePhone = '125-(455)-7890',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Alias = 'test'
        );
        userList.add(user);
        
        User user2 = new User(
            LastName = 'user2',
            FirstName = 'user3',
            Username = 'johnCENA@acme1.com',
            Email = 'abc@gmail1.com',
            MobilePhone = '123-(456)-7890',
            Phone = '74483939',
            Alias = 'alias2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = prof.id,
            LanguageLocaleKey ='en_US'
        );
        userList.add(user2);
        
        insert userList;
          
    }
    
    static testMethod void testMobilePhoneFormat(){
        List<User> userList = [Select Id, Name, Phone, MobilePhone FROM User];
        Test.startTest();
        	userService.formatMobilePhone(UserList);
        Test.stopTest();
    }
    
    @isTest
    static void testPermissionSetAssignment() {
        
        User userRec = [Select Id, FirstName, CompanyName, Profile.Name From User Where FirstName = 'test1'][0];
        userRec.CompanyName = 'RC';
        update userRec;
       
        Test.startTest();
        	
        	List<User> usersLst = [Select Id, FirstName, CompanyName, Profile.Name From User Where FirstName = 'test1'];
            List<AssignResourcesToUserEvent__e> asrEvents = new List<AssignResourcesToUserEvent__e>();
            For(User u : usersLst) {
                AssignResourcesToUserEvent__e asrEvent = new AssignResourcesToUserEvent__e();
                asrEvent.UserId__c = u.Id;
                asrEvents.add(asrEvent);
            }
            if(asrEvents != null && asrEvents.size() > 0) {
                EventBus.publish(asrEvents);
            }

        Test.stopTest();
        
        List<PermissionSetAssignment> psaLst = [Select Id, AssigneeId, PermissionSetId From PermissionSetAssignment Where AssigneeId = :userRec.Id];
        system.debug('psaLst: ' + psaLst + ' -- ' + userRec.Profile.Name);
        system.assertNotEquals(0, psaLst.size());
    }
}