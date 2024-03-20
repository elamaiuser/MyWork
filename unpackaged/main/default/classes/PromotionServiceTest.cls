/***
* HRP-1615->User: Managing Promotional Items Available to Drives
* 
* */
@isTest
private class PromotionServiceTest {
    //public static String emails = Userinfo.getUserEmail();
    private static List<String> toAddress = new List<String>();
    private static List<String> promoId = new List<Id>();
    
     @testSetup 
     static void setUpData() {
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
         contact.Email = 'testContact@gmail.com';
		 contact.Original_Service_Date__c = system.today().addDays(3);
		 contact.Primary_Phone__c = 'Mobile Phone';
         contact.MobilePhone = '752-781-0090';
         contact.AccountId = acc.id;
         insert contact;
            
        }
    
    @isTest
    public static void testPromotionEndDateChange1(){
        insertPromotionData();
        List<Promotion__c> promoList1 = [select id , End_Date__c, Name from Promotion__c];
        Test.startTest(); //trigger end date change
        Date endDate = promoList1[0].End_Date__c;
        promoList1[0].End_Date__c =  endDate.addDays(-1);//make it one day less
        update promoList1;//this will trigger deletion of opportunity promotion 
        Test.stopTest();
        List<Opportunity_Promotion__c> oppPromoList = [select id , Name from Opportunity_Promotion__c];
        System.assertEquals(1, oppPromoList.size() );//There should not be any opportunity promotions
        /*toAddress.add(emails);
        promoId.add(oppPromoList[0].Name);
        PromotionService.sendEmail(toAddress, promoId);*/
        	
    }
    @isTest
    public static void testPromotionEndDateChange2(){
        insertPromotionData();
        List<Promotion__c> promoList1 = [select id , End_Date__c, Name from Promotion__c];
        Test.startTest(); //trigger end date change
        Date endDate = promoList1[0].End_Date__c;
        promoList1[0].End_Date__c =  endDate.addDays(-26);//make it one day less
        update promoList1;//this will trigger deletion of opportunity promotion 
        Test.stopTest();
        List<Opportunity_Promotion__c> oppPromoList = [select id , Name from Opportunity_Promotion__c];
        System.assertEquals(0, oppPromoList.size() );//There should not be any opportunity promotions
        /*toAddress.add(emails);
        promoId.add(oppPromoList[0].Name);
        PromotionService.sendEmail(toAddress, promoId);*/
        	
    }
    private static void insertPromotionData(){
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
        site.sked_Site_Main_Phone__c = '202-201-2122' ;
        site.sked_Site_Building_Name__c = 'test Building';
        site.sked_Physical_Location_Type__c = 'Inside';
        site.sked_Pay_for_Parking__c = 'Other';
        site.sked_Pay_for_Parking_Details__c = 'Other';
        site.sked_Wireless_Policy__c = 'Accepted';
        site.source__c='Custom New Form';
        site.sked_Address_1__c='Test Site Address';
        site.sked_City__c='Test site city';
        site.sked_County__c='AMERICA';
        site.sked_State__c='test state';
        site.sked_Wireless_Policy__c='Accepted';
        site.sked_Zip_Code__c='94608';
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
        opp.Drive_Date__c = System.today().addDays( 12 );
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
    
    
        List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
        OpportunityTeamMember otm;
        otm = new OpportunityTeamMember();
        otm.OpportunityAccessLevel = 'Edit';
        otm.userId = Userinfo.getUserId() ;
        //otm.User.Email = '';
        //otm.User.Email = 'ab12@gmail.com';
        system.debug('Mail'+Userinfo.getUserEmail());
        otm.OpportunityId = opp.Id;
        otm.TeamMemberRole = 'Account Manager';
        otm.Start_Date__c = System.today();
        otmList.add(otm);
        insert otmList;
    
    
        Promotion__c promotion = new Promotion__c(Name='Test Promotion');
        Date todayDate = Date.today();
        promotion.Start_Date__c = todayDate;
        promotion.End_Date__c = todayDate.addDays(28);
        promotion.Supplier__c = 'Drive';
        insert promotion;
        //Opportunity_Promotion__c oppPromo= new Opportunity_Promotion__c(Name='Test Opp Promo');
        Opportunity_Promotion__c oppPromo= new Opportunity_Promotion__c();
        oppPromo.Blood_Drive_Opportunity__c = opp.id;
        oppPromo.Promotion__c = promotion.id;
        insert oppPromo;
    }

}