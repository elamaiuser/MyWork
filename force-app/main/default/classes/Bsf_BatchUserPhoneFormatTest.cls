@isTest
private class Bsf_BatchUserPhoneFormatTest {
    
    static testMethod void test(){
        User u=new User();
        u.LastName='user2';
        u.FirstName='user3';
        u.Username='test'+UserInfo.getOrganizationId()+'@gmail.com';
        u.Email='abc@gmail1.com';
        u.MobilePhone='123-(456)-7890';
        u.Phone='74483939';
        u.Alias='alias2';
        u.TimeZoneSidKey='America/New_York';
        u.LocaleSidKey='en_US';
        u.EmailEncodingKey='ISO-8859-1';
        u.ProfileId=[select Id, Name from Profile where Id in (select ProfileId from User where Id = :Userinfo.getUserId())].Id;
        u.LanguageLocaleKey ='en_US';
        userService.runUser=false;
         insert u;   
        
        
        system.debug('u2'+u);
        user u1 =[select id,LastName,name,MobilePhone from user where LastName='user2'];
        system.debug('u1.MobilePhone'+u1.MobilePhone+u1.LastName);
        
        
        Test.startTest();
        
        Bsf_BatchUserPhoneFormat ba= new Bsf_BatchUserPhoneFormat();
        Id jobid= Database.executeBatch(ba);
        Test.stopTest();
    }
}