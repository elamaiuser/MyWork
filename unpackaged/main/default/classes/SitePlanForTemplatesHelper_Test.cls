@isTest
public class SitePlanForTemplatesHelper_Test {
    @testSetup 
    public static void prepareDataset(){
        
        // create account       		
		List<Account> mobileAccList = new List<Account>();        
        Account accobj = new Account();
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30622';        
        mobileAccList.add(accobj);
        insert mobileAccList;
        
        //create contact
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        Contact.Email = 'testContact@gmail.com';
        contact.Original_Service_Date__c = system.today().addDays(3);
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact.MailingCity = 'Herndon';
        contact.MailingStateCode = 'VA';
        contact.MailingPostalCode = '20170';
        contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
        contact.AccountId = mobileAccList[0].id;
        insert contact;
        
        // create site 
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
        site.sked_Wireless_Policy__c = 'Accepted';
        site.sked_Site_Inspection_Completed_By__c = UserInfo.getUserId();
        site.sked_Room_Size__c = '801-1200 Sq. Ft.';
        site.sked_Staff_Personal_Parking_Directions__c = 'test';
        site.sked_Address_1__c = 'test';
        site.sked_Outside_stairs__c = 10;
        site.sked_County__c = 'test';
        site.sked_State__c = 'test';
        site.sked_Zip_Code__c = 'test123';
        site.sked_City__c = 'test';
        site.sked_Inside_stairs__c = 10;
        site.sked_Base_Description__c = 'test';
        site.sked_ARC_Vehicle_Parking_Directions__c = 'test';
        site.sked_Directions_From_CollectionOperation__c = 'test';
        site.sked_Start_Date__c = System.today();
        site.sked_End_Date__c = System.today()+5;
        site.Source__c = 'Custom New Form';
        insert site;
    }
    @isTest static void validateSitePlan() {
        
        List<Account> accList = [select Id , Name from Account where Name = 'Exavalu'];
        List<sked__Location__c> sites = [select Id from sked__Location__c where Source__c = 'Custom New Form' ];
        system.debug('Site List - '+sites);
        
        // create opportunity
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Opportunity opp = new Opportunity();
        opp.AccountId = accList[0].id;
        opp.StageName = 'Committed';
        opp.Drive_Site__c = sites[0].id;
		opp.Drive_Name__c = 'Test Drive 1';
        opp.Drive_Date__c = System.today();
        opp.CloseDate = System.today();
        opp.Call_List_Recipient_Exist__c = true;
        Time startTime = Time.newInstance(10, 0, 0, 0);
        opp.Start_Time__c = startTime;
        Time endTime = Time.newInstance(15, 30, 0, 0);
        opp.Flow_Start_Time_Field__c = '1000';
		opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Flow_End_Time_Field__c = '1530';
        opp.WB_Projected_Procedures__c = 4;
        opp.X2RBC_Projected_Procedures__c = 2;
        opp.Name = 'Test Opportunity 1';
        opp.Anticipated_Registered_Donors__c =25;
        opp.Is_Template__c = true;
		insert opp;
        Test.startTest();
        SitePlanForTemplatesHelper.SitePlanForTemplatesHelper(sites[0].Id);
        Test.stopTest();
        
    }

}