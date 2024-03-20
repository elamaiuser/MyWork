@isTest
public class MarketingProgramUserFilterTest {
	@isTest
    Public static void TestMarketingProgramUserFilter(){
        List<User> UserList=new List<User>();
        User u=new User();
        u.LastName='user12312';
        u.FirstName='user22123';
        u.Username='john@acme16.com';
        u.Email='abc@gmail3413.com';
        u.Alias='alias2';
        u.TimeZoneSidKey='America/New_York';
        u.LocaleSidKey='en_US';
        u.EmailEncodingKey='ISO-8859-1';
        u.ProfileId='00eo0000000rmqFAAQ';
        u.LanguageLocaleKey ='en_US';
        u.IsActive=false;
        UserList.add(u);
        
        User u1=new User();
        u1.LastName='user123122';
        u1.FirstName='user22123';
        u1.Username='john@acme13.com';
        u1.Email='abc@gmail3213.com';
        u1.Alias='alias3';
        u1.TimeZoneSidKey='America/New_York';
        u1.LocaleSidKey='en_US';
        u1.EmailEncodingKey='ISO-8859-1';
        u1.ProfileId='00eo0000000rmqFAAQ';
        u1.LanguageLocaleKey ='en_US';
        u1.IsActive=false;
        UserList.add(u1);
        insert UserList;
        
        Test.startTest();
        MarketingProgramUserFilter.getAccountMarketingProgramsAvailableToCurrentUser();
        Test.stopTest();
    }
}