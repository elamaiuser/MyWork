@isTest
public class DMBellNotificationATMBatchHelperTest {
    
    static testMethod void test(){
        
        customNotificationType cn=[select id from CustomNotificationType where developername='Account_Custom_Notification'];
        
        Account a=new Account();
        a.name='account';
        a.District_Manager__c=[select id , name from user limit 1].id;
        insert a;
        
        contact c=new contact();
        c.AccountId=a.Id;
        c.FirstName='contact1';
        c.Email='abcd@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact2';
        c.Phone='7474749';
        insert c;
        
        List<User> userList=new List<User>();
        User u=new User();
        u.LastName='user123';
        u.FirstName='user222';
        u.Username='john@acme5.com';
        u.Email='abc@gmail34.com';
        u.Alias='alias';
        u.TimeZoneSidKey='America/New_York';
        u.LocaleSidKey='en_US';
        u.EmailEncodingKey='ISO-8859-1';
        u.ProfileId='00eo0000000rmqFAAQ';
        u.LanguageLocaleKey ='en_US';
        userList.add(u);
        insert u;
        List<User> ListUser=[select id,name from user limit 1];
        
       List<AccountTeamMember> atmList=new List<AccountTeamMember>();
        AccountTeamMember atm =new AccountTeamMember(AccountAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'Account Manager',
            Start_Date__c = System.today(),
            End_Date__c = System.today()+3,
            Coverage_Reason__c = '');
        	atm.UserId = u.Id;
            atm.AccountId = a.Id;
        	atmList.add(atm);
        	 BSF_Constants.isTeamMemberCreatedFromBackend = true;
        	insert atmList;
            BSF_Constants.isTeamMemberCreatedFromBackend = false;
        Test.startTest();
        DMBellNotificationATMExpiryBatchSchedule amExpBellNotificationSch = new DMBellNotificationATMExpiryBatchSchedule(100);
		System.schedule('Notify DM 4 AM Expiry Batch1', '0 30 0 * * ?', amExpBellNotificationSch );
        
        
        DMBellNotificationForATMExpiryBatch ba= new DMBellNotificationForATMExpiryBatch();
        Id jobid= Database.executeBatch(ba,5);
        DMBellNotificationATMExpiryBatchHelper.SendBellNotificationToDM(atmList);
        Test.stopTest();
    }
}