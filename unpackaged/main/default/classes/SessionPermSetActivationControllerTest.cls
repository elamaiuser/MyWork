/*
 * This Test class covering the following Classes
 * SessionPermSetActivationController, 
 * */
@isTest
public class SessionPermSetActivationControllerTest {

    @isTest static void deactivatesessionTest() {        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );        
        
        System.runAs( DRDAMUser ){
            SessionPermSetActivationController.deactivatesession();
        }
        
        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        System.runAs( AdminUser ){
			Test.startTest();
            SessionPermSetActivationController.deactivatesession();
            
			
			List<permissionset> permissionList = new List<permissionset>();
			String sessionPermSetId ;
			permissionList = [ select id from permissionset where name = 'AccessToBloodDriveSplit' ];
			if( !permissionList.isempty() ){
				sessionPermSetId = permissionList[0].Id ;
			}
			List<SessionPermSetActivation> sessionlist = new List<SessionPermSetActivation>();
			sessionlist = [SELECT Id
						   FROM SessionPermSetActivation
						   //WHERE AuthSessionId=:sessionId
						   WHERE PermissionSetId=:sessionPermSetId LIMIT 1]	;
			
		
		
		
            System.assert(sessionlist!= null);
			
			Test.stopTest();
        }
        
    } 
}