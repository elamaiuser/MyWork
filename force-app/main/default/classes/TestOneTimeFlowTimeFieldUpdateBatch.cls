@isTest
public class TestOneTimeFlowTimeFieldUpdateBatch {

     
    
    @isTest static void testFlowStartTime(){
          Account acc1 = new Account(name='Test Account');
          acc1.BillingStreet = '2204 Westcrt ln, Apt 213'; 
          acc1.BillingCity = 'Herndon';
          acc1.BillingStateCode = 'VA';
          acc1.BillingPostalCode = '20170';
          insert acc1;
         
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.Email = 'testContact@gmail.com';
        contact.Original_Service_Date__c = system.today().addDays(3);
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact.MailingCity = 'Herndon';
        contact.MailingStateCode = 'VA';
        contact.MailingPostalCode = '20170';
        contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
        contact.AccountId = acc1.id;
        contact.Primary_Phone__c ='Mobile Phone';
        contact.Original_Service_Date__c = system.today();
        insert contact;
            
            sked__Tag__c skedTag = new sked__Tag__c();
			skedTag.sked__Type__c = 'Physical Location Type';
			skedTag.Name = 'Inside';
            insert skedTag;
            sked__Location__c site = new sked__Location__c();
            site.Name = 'testSite';
            site.sked_Floor_Description__c = 'test Floor';
            site.sked_Room_Name__c = 'test Room';
            site.sked_National_Name__c = 'test National Name';
            site.sked_Automation_Suitability__c = 'Suitable';
            site.sked_Site_Main_Phone__c = '2022012122';
            site.sked_Site_Building_Name__c = 'test Building';
            site.sked_Physical_Location_Type__c = 'Inside';
            site.sked_Pay_for_Parking__c = 'Other';
            site.sked_Pay_for_Parking_Details__c = 'Other';
            site.Source__c='Custom New Form';
            site.sked_Site_Main_Phone__c = '098-765-4321';
            site.sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions';
            site.sked_Travel_Time_to_Staging_Location__c = 15;
            site.sked_Wireless_Policy__c = 'Accepted';
            site.sked_Address_1__c = 'Test Address';
            site.sked_City__c = 'city';
            site.sked_County__c = 'United States';
            site.sked_State__c = 'Texas';
            site.sked_Zip_Code__c = '27560';

            insert site;
            
            Opportunity opp = new Opportunity();
            Account acc = [select id from Account where name='Test Account' limit 1];
            opp.AccountId = acc.id;
             Account_Service_Role__c serviceRole = new Account_Service_Role__c();
             serviceRole.Account_Service_Role__c='Blood Program Leader';
             serviceRole.Account__c = acc.id; 
            serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
            insert serviceRole;

            opp.StageName = 'Draft';
            opp.Drive_Site__c = site.id;
			opp.Drive_Name__c = 'Test Drive';
            opp.Drive_Date__c = System.today();
            opp.CloseDate = System.today();
            Time startTime = Time.newInstance(10, 0, 0, 0);
            System.debug('startTime->'+startTime);
            opp.Start_Time__c = startTime;
            Time endTime = Time.newInstance(15, 30, 0, 0);
            System.debug('endTime->'+endTime);
           opp.End_Time__c = endTime;
			//opp.Flow_Start_Time_Field__c = '10:00 AM';
            //opp.Flow_Start_Time_Field__c = '1000';

            //opp.Flow_End_Time_Field__c = '1530';
            //opp.Flow_End_Time_Field__c = '3:30 PM';

            //opp.End_Time__c = endTime;
            opp.WB_Projected_Procedures__c = 4;
            opp.X2RBC_Projected_Procedures__c = 2;
            opp.Name = 'Test Opportunity';
            opp.Anticipated_Registered_Donors__c =25;
            opp.Flow_End_Time_Field__c=null;
			insert opp;
            /*String query = 'select id,Flow_Start_Time_Field__c, Start_Time__c, End_Time__c, Flow_End_Time_Field__c from opportunity where ( (Flow_Start_Time_Field__c=null and  Start_Time__c != null) or (Flow_End_Time_Field__c=null and End_Time__c != null)) limit 1';	
			Opportunity opp1 = (Opportunity)Database.query(query);
           System.assert(opp1 !=null, 'Flow end time should not be populated');*/

            Test.startTest();
		    OneTimeFlowTimeFieldUpdateBatch oneTimeFlowTimeFieldUpdateBatch = new oneTimeFlowTimeFieldUpdateBatch();
            Database.executeBatch(oneTimeFlowTimeFieldUpdateBatch);
            Test.stopTest();
         	Opportunity opp2 =[select id,Flow_End_Time_Field__c from opportunity where id=:opp.id limit 1];
			System.assert(opp2.Flow_End_Time_Field__c!=null, 'Flow end time should be populated');
            
    	
        }
    
    @isTest static void testOneTimeEmailBatch(){
         User drdUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com.invalid',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            isActive=true, 
            UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'WEST_BDM'].Id
        );
        Database.SaveResult sr = Database.insert(drdUser, false);
        System.debug('User inserted->'+sr);
             String query = 'select username, email from user where email like \'%.invalid%\' and isActive=true limit 1';	
		User usr = (User)Database.query(query);
        
        
         Test.startTest();
		    OneTimeEmailUpdateBatch OneTimeEmailUpdateBatch = new OneTimeEmailUpdateBatch();
            Database.executeBatch(OneTimeEmailUpdateBatch,1);
         
    
            Test.stopTest();
         	User u =[select id,Email from user where id=:drdUser.id limit 1];
        	String newEmail = u.email;
			System.assert(newEmail.contains('invalid')==false, 'Email should not have invalid');
        
    }
    
}