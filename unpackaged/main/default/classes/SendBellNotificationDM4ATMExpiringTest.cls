@isTest
public class SendBellNotificationDM4ATMExpiringTest {
	static testMethod void test(){
        
        customNotificationType cn=[select id from CustomNotificationType where developername='Account_Custom_Notification'];
        User u1=new User();
        u1.LastName='user1234';
        u1.FirstName='user2222';
        u1.Username='john@acme15.com';
        u1.Email='abc@gmail324.com';
        u1.Alias='aliass';
        u1.TimeZoneSidKey='America/New_York';
        u1.LocaleSidKey='en_US';
        u1.EmailEncodingKey='ISO-8859-1';
        u1.ProfileId='00eo0000000rmqFAAQ';
        u1.LanguageLocaleKey ='en_US';
        insert u1;
        
        Account a=new Account();
        a.name='account';
        a.District_Manager__c=u1.id;
        insert a;
        
        contact c=new contact();
        c.AccountId=a.Id;
        c.FirstName='contact1';
        c.LastName='contact2';
        c.Email = 'testContact@gmail.com';
		c.Original_Service_Date__c = system.today().addDays(3);
		c.Primary_Phone__c = 'Mobile Phone';
        c.MobilePhone = '752-781-0090';
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
        	bsf_constants.isTeamMemberCreatedFromBackend = true;
        	insert atmList;
            bsf_constants.isTeamMemberCreatedFromBackend = false;
        Test.startTest();
        BellNotificationDM4ATMExpiryScheduler amExpBellNotificationSch = new BellNotificationDM4ATMExpiryScheduler(100);
		System.schedule('Notify DM 4 AM Expiry Batch1', '0 30 0 * * ?', amExpBellNotificationSch );
        
        SendBellNotificationDM4ATMExpiring3days sbn= new SendBellNotificationDM4ATMExpiring3days();
        Id batchJobId = Database.executeBatch(sbn, 200);
        Test.stopTest();
    }
}