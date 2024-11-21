/* The following test class is covering the below mentioned apex class
 * OpportunityLinkedDriveController
 * */

@isTest(SeeAllData=false)
public class OpportunityLinkedDriveController_Test {
    
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String fixedOppRecType = 'Mobile Opp';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @isTest static void testAllMethodsOfOpportunityLinkedDriveCont()
    {
        /*User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             FirstName='SystemAdmin',
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             FirstName = 'Amy',
             LastName = 'Brown',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
             
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        
        // create account
        recordTypeMap = recordTypeMap( 'Account' );
		Id recTypeId = recordTypeMap.get(mobileAccRecType);
		List<Account> mobileAccList = new List<Account>();
		Account accobj;
		accobj = new Account();
		accobj.RecordTypeId = recTypeId;
		accobj.Name = 'Exavalu';
        accobj.Internal_Name__c = 'Exavalu';
		accobj.BillingPostalCode = '30146';
		mobileAccList.add(accobj);
		insert mobileAccList;
        
        Contact contact = new Contact (firstname='Test Contact First',lastname='Test Contact Last');
        contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact.Email = 'testContact@gmail.com';
        contact.Original_Service_Date__c = system.today().addDays(3);
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
        contact.MailingCity = 'Herndon';
        contact.MailingStateCode = 'VA';
        contact.MailingPostalCode = '20170';
        contact.MailingStreet = '2204 Westcourt Ln,Apt 218'; 
        contact.AccountId = mobileAccList[0].id;
        contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '888-888-8888';
        insert contact;
        
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        insert atmList;
		
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
        
        Linked_Opportunity_Drives__c linkedDrives = new Linked_Opportunity_Drives__c();
        linkedDrives.Linked_Drive_Type__c = 'Single Drive';
        insert linkedDrives;
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.AccountId = mobileAccList[0].id;
        opp.StageName = 'Committed';
        opp.Linked_Opportunity_Drives__c = null;
        opp.Drive_Site__c = site.id;
		opp.Drive_Name__c = 'Test Drive 1';
        opp.Drive_Date__c = System.today();
        opp.Type_of_Drive__c = 'Mobile';
        opp.CloseDate = System.today().addDays(-20);
        opp.Call_List_Recipient_Exist__c = true;
        Time startTime = Time.newInstance(10, 0, 0, 0);
        opp.Start_Time__c = startTime;
        Time endTime = Time.newInstance(15, 30, 0, 0);
        opp.End_Time__c = endTime;
        opp.Flow_Start_Time_Field__c = '1000';
		opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Flow_End_Time_Field__c = '1530';
        opp.WB_Projected_Procedures__c = 4;
        opp.X2RBC_Projected_Procedures__c = 2;
        opp.Name = 'Test Opportunity 1';
        opp.Anticipated_Registered_Donors__c =25;
        oppList.add(opp);
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = mobileAccList[0].id;
        opp1.StageName = 'Committed';
        opp1.Drive_Site__c = site.id;
		opp1.Drive_Name__c = 'Test Drive 2';
        opp1.Drive_Date__c = opp.Drive_Date__c;
        opp1.Type_of_Drive__c = 'Mobile';
        opp1.Linked_Opportunity_Drives__c = linkedDrives.id;
        opp1.CloseDate = System.today().addDays(-20);
        opp1.Call_List_Recipient_Exist__c = true;
        Time startTime1 = Time.newInstance(10, 0, 0, 0);
        opp1.Start_Time__c = startTime1;
        Time endTime1 = Time.newInstance(15, 30, 0, 0);
        opp1.End_Time__c = endTime1;
        opp1.Flow_Start_Time_Field__c = '1000';
		opp1.Accept_56_Day_Rule_Violation__c = true;
        opp1.Flow_End_Time_Field__c = '1530';
        opp1.WB_Projected_Procedures__c = 4;
        opp1.X2RBC_Projected_Procedures__c = 2;
        opp1.Name = 'Test Opportunity 2';
        opp1.Anticipated_Registered_Donors__c =25;
        oppList.add(opp1);
        
        Opportunity opp2 = new Opportunity();
        opp2.AccountId = mobileAccList[0].id;
        opp2.StageName = 'Committed';
        opp2.Drive_Site__c = site.id;
		opp2.Drive_Name__c = 'Test Drive 3';
        opp2.Drive_Date__c = system.today().addDays(1);
        opp2.Type_of_Drive__c = 'Mobile';
        //opp2.Linked_Opportunity_Drives__c = linkedDrives.id;
        opp2.CloseDate = System.today().addDays(-20);
        opp2.Call_List_Recipient_Exist__c = true;
        Time startTime2 = Time.newInstance(6, 0, 0, 0);
        opp2.Start_Time__c = startTime2;
        Time endTime2 = Time.newInstance(8, 0, 0, 0);
        opp2.End_Time__c = endTime2;
        opp2.Flow_Start_Time_Field__c = '1000';
		opp2.Accept_56_Day_Rule_Violation__c = true;
        opp2.Flow_End_Time_Field__c = '1530';
        opp2.WB_Projected_Procedures__c = 4;
        opp2.X2RBC_Projected_Procedures__c = 2;
        opp2.Name = 'Test Opportunity 3';
        opp2.Anticipated_Registered_Donors__c =25;
        oppList.add(opp2);
        
        Opportunity opp3 = new Opportunity();
        opp3.AccountId = mobileAccList[0].id;
        opp3.StageName = 'Committed';
        opp3.Drive_Site__c = site.id;
		opp3.Drive_Name__c = 'Test Drive 4';
        opp3.Drive_Date__c = system.today()-2;
        opp3.Type_of_Drive__c = 'Mobile';
        //opp3.Linked_Opportunity_Drives__c = linkedDrives.id;
        opp3.CloseDate = System.today().addDays(-20);
        opp3.Call_List_Recipient_Exist__c = true;
        Time startTime3 = Time.newInstance(6, 0, 0, 0);
        opp3.Start_Time__c = startTime3;
        Time endTime3 = Time.newInstance(8, 0, 0, 0);
        opp3.End_Time__c = endTime3;
        opp3.Flow_Start_Time_Field__c = '1000';
		opp3.Accept_56_Day_Rule_Violation__c = true;
        opp3.Flow_End_Time_Field__c = '1530';
        opp3.WB_Projected_Procedures__c = 4;
        opp3.X2RBC_Projected_Procedures__c = 2;
        opp3.Name = 'Test Opportunity 4';
        opp3.Anticipated_Registered_Donors__c =25;
        oppList.add(opp3);
        
        Opportunity opp4 = new Opportunity();
        opp4.AccountId = mobileAccList[0].id;
        opp4.StageName = 'Committed';
        opp4.Drive_Site__c = site.id;
		opp4.Drive_Name__c = 'Test Drive 5';
        opp4.Drive_Date__c = system.today()+1;
        opp4.Type_of_Drive__c = 'Mobile';
        opp4.Linked_Opportunity_Drives__c = null;
        opp4.CloseDate = System.today().addDays(-20);
        opp4.Call_List_Recipient_Exist__c = true;
        Time startTime4 = Time.newInstance(6, 0, 0, 0);
        opp4.Start_Time__c = startTime4;
        Time endTime4 = Time.newInstance(8, 0, 0, 0);
        opp4.End_Time__c = endTime4;
        opp4.Flow_Start_Time_Field__c = '1000';
		opp4.Accept_56_Day_Rule_Violation__c = true;
        opp4.Flow_End_Time_Field__c = '1530';
        opp4.WB_Projected_Procedures__c = 4;
        opp4.X2RBC_Projected_Procedures__c = 2;
        opp4.Name = 'Test Opportunity 4';
        opp4.Anticipated_Registered_Donors__c =25;       
        oppList.add(opp4);
           
        insert oppList;
      
        Test.startTest();
        
        List<Opportunity> fetchSingleDayDriveSuccess = OpportunityLinkedDriveController.fetchAllSingleDayDrives(oppList[0].id);
       
        List<Opportunity> singleDayLinkedDriveList = OpportunityLinkedDriveController.fetchSingleDayLinkedDrives(linkedDrives.id);
        
        String testDeLinkSingleDayDrive = OpportunityLinkedDriveController.deLinkSingleDayDrives(linkedDrives.id);
        system.assertEquals('Sucess - Linked Drive created Sucessfully', testDeLinkSingleDayDrive);
        
        String testCreateDrives1 = OpportunityLinkedDriveController.createSingleDayLinkedDrives(oppList[0].id , oppList[1].id); // for same day linked drives time overlapping
        system.assertEquals('Error: Same Day Linked Drives Opportunities cannot overlap in time', testCreateDrives1);
        
        String testCreateDrives2 = OpportunityLinkedDriveController.createSingleDayLinkedDrives(oppList[0].id , oppList[2].id); // for linked opportunity drives for opp1 == null
        system.assertEquals('Sucess - Linked Drive created Sucessfully', testCreateDrives2);
        
        //String testCreateDrives3 = OpportunityLinkedDriveController.createSingleDayLinkedDrives(oppList[0].id , oppList[4].id); // for linked opportunity drives for opp1 == null
        //system.assertEquals('Sucess - Linked Drive created Sucessfully', testCreateDrives3);
        
        List<Opportunity> fetchMultiDayDrives1 = OpportunityLinkedDriveController.fetchAllMultiDayDrives(oppList[0].id); // for linked opp drives == null
        List<Opportunity> fetchMultiDayDrives2 = OpportunityLinkedDriveController.fetchAllMultiDayDrives(oppList[1].id); // for linked opp drives != null
        
        List<Opportunity> fetchMultiDayLinkedDrives = OpportunityLinkedDriveController.fetchMultiDayLinkedDrives(linkedDrives.Id); // fetching multi-day linked drives
        
        String multiDayDriveDeLinked = OpportunityLinkedDriveController.deLinkMultiDayDrives(oppList[0].id, oppList[1].id); // multi day linked drives - de-linked successfully
        system.assertEquals('Success - Drive de-linked Sucessfully', multiDayDriveDeLinked);
        
        //String createMultiDayLinkedDriveError =  OpportunityLinkedDriveController.createMultiDayLinkedDrives(oppList[0].id, oppList[2].id); // creating multi-day linked drives- date overlapping
        //system.assertEquals('Error: Date overlap between the drives', createMultiDayLinkedDriveError);
        
        String createMultiDayLinkedDriveSuccess =  OpportunityLinkedDriveController.createMultiDayLinkedDrives(oppList[0].id, oppList[3].id); // creating multi-day linked drives- Drive dates must be consecutive
        system.assertEquals('Error: Drive Dates must be consecutive days', createMultiDayLinkedDriveSuccess);
        
        String createMultiDayLinkedDriveSuccess2 =  OpportunityLinkedDriveController.createMultiDayLinkedDrives(oppList[1].id, oppList[4].id); // creating multi-day linked drives- linked successfully
        system.assertEquals('Success - Drive linked Sucessfully', createMultiDayLinkedDriveSuccess2);
 		
        Test.stopTest();
    }
    
    //Method to get the map of recordType Name as key and recordTypeId as value for account records
    public static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;*/
    }

}