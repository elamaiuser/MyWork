@isTest
public class InactiveUserLookUpControllerTest {
	@isTest
    Public static void TestInactiveUserLookUp(){
        User u=new User();
        u.LastName='user1232';
        u.FirstName='user2223';
        u.Username='john@acme6.com';
        u.Email='abc@gmail343.com';
        u.Alias='alias1';
        u.TimeZoneSidKey='America/New_York';
        u.LocaleSidKey='en_US';
        u.EmailEncodingKey='ISO-8859-1';
        u.ProfileId='00eo0000000rmqFAAQ';
        u.LanguageLocaleKey ='en_US';
        u.IsActive=false;
        insert u;
        
       Test.startTest();
        InactiveUserLookUpController.findRecords('user2223', 'User', 'LastName');
        Test.stopTest();
        
    }
}