/***
* HRP-1615->User: Managing Promotional Items Available to Drives
* 
* */
@isTest
public class TestPromotionService {
    
     @testSetup static void setUpData() {
         Account acc = new Account(name='Test Account');
         insert acc;
         acc.BillingStreet = '2204 Westcrt ln, Apt 213'; 
         acc.BillingCity = 'Herndon';
         acc.BillingStateCode = 'VA';
         acc.BillingPostalCode = '20170';
         Contact contact = new Contact (firstname='Test Contact First',lastname='TestContactLast');
         contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
         contact.MailingCity = 'Herndon';
         contact.MailingStateCode = 'VA';
         contact.MailingPostalCode = '20170';
         contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
         contact.AccountId = acc.id;
         contact.Email = 'testContact@gmail.com';
		 contact.Original_Service_Date__c = system.today().addDays(3);
         contact.Primary_Phone__c = 'Mobile Phone';
         contact.MobilePhone = '752-781-0090';
         insert contact;
            
        }
    
    @isTest
    public static void testPromotionEndDateChange(){
         sked__Tag__c skedTag = new sked__Tag__c();
			skedTag.sked__Type__c = 'Physical Location Type';
			skedTag.Name = 'Inside';
            insert skedTag;
            
        	sked__Location__c siteObj = new sked__Location__c();
            siteObj.Name = 'Test Site';
            siteObj.sked__Address__c = 'Test Site Address';
            siteObj.sked_Site_Building_Name__c = 'Test Site Building';
            siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
            siteObj.sked_Room_Name__c = 'Room 15';
            siteObj.sked_National_Name__c = 'AMERICA';
            siteObj.sked_Physical_Location_Type__c = 'Outside';
            siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
            siteObj.sked_Automation_Suitability__c = 'Suitable';
            siteObj.sked_Outside_stairs__c = 1;
            siteObj.sked_Inside_stairs__c = 2;
            siteObj.sked_Base_Description__c = 'test base description';
            siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
            siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Site_Main_Phone__c = '758-771-0091';
            siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
            siteObj.sked_Pay_for_Parking__c = 'Other';
            siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
            
            siteObj.sked_Address_1__c = 'Test Site Address 1';  
            siteObj.sked_County__c = 'USA';
            siteObj.sked_City__c = 'Aubum';
            siteObj.sked_State__c = 'Alabama';
            siteObj.sked_Zip_Code__c = '36801';
            siteObj.sked_Wireless_Policy__c = 'Accepted';
            siteObj.Source__c = 'Custom New Form';
        	insert siteObj;
        
            Opportunity opp = new Opportunity();
            Account acc = [select id from Account where name='Test Account' limit 1];
            opp.AccountId = acc.id;
             Account_Service_Role__c serviceRole = new Account_Service_Role__c();
             serviceRole.Account_Service_Role__c='Blood Program Leader';
             serviceRole.Account__c = acc.id; 
            serviceRole.Contact__c = [select id from Contact where firstname='Test Contact First' limit 1].id;
            insert serviceRole;

            opp.StageName = 'Draft';
            opp.Drive_Site__c = siteObj.id;
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
            opp.source__c = 'Adhoc';
			insert opp;
        
            Promotion__c promotion = new Promotion__c(Name='Test Promotion');
        	Date todayDate = Date.today();
        	promotion.Start_Date__c = todayDate;
        	promotion.End_Date__c = todayDate.addDays(10);
        	promotion.Supplier__c = 'Drive';
        	insert promotion;
        	Opportunity_Promotion__c oppPromo= new Opportunity_Promotion__c();
        	oppPromo.Blood_Drive_Opportunity__c = opp.id;
        	oppPromo.Promotion__c = promotion.id;
        	insert oppPromo;
        	Test.startTest(); //trigger end date change
        	Date endDate = promotion.End_Date__c;
        	promotion.End_Date__c =  endDate.addDays(-1);//make it one day less
			update  promotion;//this will trigger deletion of opportunity promotion  	
        	Test.stopTest();
        	List<Opportunity_Promotion__c> oppPromoList = [select id from Opportunity_Promotion__c];
            //System.assert(oppPromoList.size()<1);//There should not be any opportunity promotions
    }

}