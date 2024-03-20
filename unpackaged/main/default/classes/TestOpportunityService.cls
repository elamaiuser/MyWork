/**
 * This Class contains testMethods for OpportunityService
 * 
 * */
@isTest
public class TestOpportunityService {
    
        /*@testSetup static void setUpData() {
              Account acc = new Account(name='Test Account');
        insert acc;
         acc.BillingStreet = '2204 Westcrt ln, Apt 213'; 
         acc.BillingCity = 'Herndon';
         acc.BillingStateCode = 'VA';
         acc.BillingPostalCode = '20170';
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
         contact.MailingCity = 'Herndon';
         contact.MailingStateCode = 'VA';
         contact.MailingPostalCode = '20170';
         contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
         contact.AccountId = acc.id;
         contact.Original_Service_Date__c=system.today();
         contact.Primary_Phone__c='Mobile Phone';
        insert contact;
            
        }
    
        @isTest static void testValidBPLForOpportunity(){
            
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
			
            opp.Flow_Start_Time_Field__c = '1000';

            opp.Flow_End_Time_Field__c = '1530';
            opp.WB_Projected_Procedures__c = 4;
            opp.X2RBC_Projected_Procedures__c = 2;
            opp.Name = 'Test Opportunity';
            opp.Anticipated_Registered_Donors__c =25;
			insert opp;
            serviceRole.Account_Service_Role__c='Account Contact';
        
            try{
                 opp.StageName ='Closed';
                 Date tday = System.today();
            	 tday.addDays(-2);

                 upsert serviceRole;

                 upsert opp;
                 System.assert(false,'Should have hit valid BPL Error');
            }Catch(System.DmlException e){
                //System.assert(e.getMessage().contains('Oh, we have hit a snag. An Active BPL is required to move this Drive to Closed Stage'));
            }
            
             try{
                 upsert serviceRole;
                 opp.StageName ='Draft';
                 opp.Online_Donor_Message__c = 'test$';
                 upsert opp;
                 
                 System.assert(false,'Should have hit Error for containing capital letters in Online Donor Message');
            }Catch(System.DmlException e){
                System.assert(e.getMessage().contains('The Online Donor message should not contain capital letters and/or special characters'));
                System.debug('Catch Message '+e.getMessage());
            }
        }*/
    
    @isTest static void testCancelTasksForCancelledOpportunities(){
            
            /*sked__Tag__c skedTag = new sked__Tag__c();
			skedTag.sked__Type__c = 'Physical Location Type';
			skedTag.Name = 'Inside';
            insert skedTag;
            sked__Location__c site = new sked__Location__c();
            site.Name = 'testSite';
            site.sked_Floor_Description__c = 'test Floor';
            site.sked_Room_Name__c = 'test Room';
            site.sked_National_Name__c = 'test National Name';
            site.sked_Automation_Suitability__c = 'Suitable';
            site.sked_Site_Main_Phone__c = '999-999-9999';
            site.sked_Site_Building_Name__c = 'test Building';
            site.sked_Physical_Location_Type__c = 'Inside';
            site.sked_Pay_for_Parking__c = 'Other';
            site.sked_Pay_for_Parking_Details__c = 'Other';
            site.Source__c='Custom New Form';
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
			//opp.Flow_Start_Time_Field__c = '10:00 AM';
            opp.Flow_Start_Time_Field__c = '1000';

            opp.Flow_End_Time_Field__c = '1530';
            //opp.Flow_End_Time_Field__c = '3:30 PM';

            //opp.End_Time__c = endTime;
            opp.WB_Projected_Procedures__c = 4;
            opp.X2RBC_Projected_Procedures__c = 2;
            opp.Name = 'Test Opportunity';
            opp.Anticipated_Registered_Donors__c =25;
			insert opp;
            Task t = new Task();
            t.subject = 'Security Information Completion';
            t.priority = 'High';
            t.whatId = opp.id;
            insert t;
            serviceRole.Account_Service_Role__c='Account Contact';
        
            try{
                 opp.StageName ='Cancelled';
                 Date tday = System.today();
            	 tday.addDays(-2);

                 serviceRole.End_Date__c = tday;
                 serviceRole.Account_Service_End_Reason__c = 'Other';
                 upsert serviceRole;

                 upsert opp;
                 List<Task> taskList = [select id, Status, whatId from task ];
                 System.assert(taskList != null ,'Task list should not be empty');
                 System.assert(taskList.get(0).status == 'Cancelled' ,'Task should be in cancelled status');

            }Catch(System.DmlException e){
               // System.assert(e.getMessage().contains('Oh, we have hit a snag. An Active BPL is required to move this Drive to Closed Stage'));
            }*/
        }
    
    
    



}