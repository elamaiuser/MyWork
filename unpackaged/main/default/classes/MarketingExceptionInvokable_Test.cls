/*
 * This Test class covering the following Classes
 * MarketingExceptionInvokable 
 * 
*/
@isTest
public class MarketingExceptionInvokable_Test {

    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Fixed Site Account';
    public static String fixedOppRecType = 'Fixed Site Opp';
    public static String taskRecType = '72 Hour Check In'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static List<Id> taskIds = new List<Id>();

    @testSetup
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Account' );
    }

    public static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }

    @isTest static void TestUpdateBloodDrive() {

        // create user 

        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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

        //UserRole urole  = [select id from userrole where developername =: rolename ];

        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            //UserRoleId = urole.Id
        );

        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
		
        // create acount
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        List<Account> mobileAccList = new List<Account>();
        Account accobj;
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';
        mobileAccList.add(accobj);
        insert mobileAccList;
		
        // create contact
        Contact contact = new Contact (firstname='Test Contact First',lastname='TestContactLast');
        contact.MailingStreet = '1104 Westcrt ln, Apt 213';
        contact.MailingCity = 'iamndon';
        contact.MailingStateCode = 'VA';
        contact.MailingPostalCode = '20170';
        contact.MailingStreet = '2204 Westcourt Ln,Apt 218';
        contact.Email = 'testContact@gmail.com';
		contact.Original_Service_Date__c = system.today().addDays(3);
		contact.Primary_Phone__c = 'Mobile Phone';
        contact.MobilePhone = '752-781-0090';
        contact.AccountId = mobileAccList[0].id;
        insert contact;

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
        atm.Coverage_Reason__c='Leave of Absence (LOA)';
        atmList.add(atm);
        insert atmList;
		
        // create sked location
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
		
        // create opportunity
        TriggerHandler.bypass('OpportunityTriggerHandler');
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.AccountId = mobileAccList[0].id;
        opp.StageName = 'Committed';
        opp.Drive_Site__c = site.id;
        opp.Drive_Name__c = 'Test Drive 1';
        opp.Drive_Date__c = System.today().addDays(10);
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
        opp.Template_Status__c='Active';
        opp.Send_Emails__c = false;
        opp.Send_Mailers__c = false;
        opp.Web_Scheduling_Enabled__c  = false;
        opp.Publish_to_Call_Center__c = false;
        oppList.add(opp);
		insert oppList ;
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = mobileAccList[0].id;
        opp1.StageName = 'Withdrawn';
        opp1.Drive_Site__c = site.id;
        opp1.Drive_Name__c = 'Test Drive 2';
        opp1.Drive_Date__c = System.today().addDays(30);
        opp1.CloseDate = System.today();
        opp1.Call_List_Recipient_Exist__c = true;
        Time startTime1 = Time.newInstance(10, 0, 0, 0);
        opp1.Start_Time__c = startTime1;
        Time endTime1 = Time.newInstance(15, 30, 0, 0);
        opp1.Flow_Start_Time_Field__c = '1000';
        opp1.Accept_56_Day_Rule_Violation__c = true;
        opp1.Flow_End_Time_Field__c = '1530';
        opp1.WB_Projected_Procedures__c = 4;
        opp1.X2RBC_Projected_Procedures__c = 2;
        opp1.Name = 'Test Opportunity 2';
        opp1.Anticipated_Registered_Donors__c = 25;
        opp1.Send_Emails__c = true;
        opp1.Send_Mailers__c = true;
        opp1.Web_Scheduling_Enabled__c  = false;
        opp1.Publish_to_Call_Center__c = false;
        opp1.Is_Template__c = true;
        opp1.Parent_Template_Id__c = oppList[0].id;        
        insert opp1;
		
        // create task
        recordTypeMap = recordTypeMap( 'Task' );
        Id taskrecTypeId = recordTypeMap.get(taskRecType);
        List<Task> taskList = new List<Task>();
        Task t1 = new Task();
        t1.OwnerId = UserInfo.getUserId();
        t1.RecordTypeId = taskrecTypeId;
        t1.whatId = oppList[0].Id;
        t1.Publish_to_Call_Center__c = true;
        t1.Send_Emails__c = true;
        t1.Send_Mailers__c = true;
        t1.Web_Scheduling_Enabled__c = true;
        t1.Subject='Call';
        t1.Status='Not Started';
        t1.Priority='Normal';
        taskList.add(t1);

        Test.startTest();
            
            try{
                insert taskList;
                taskIds.add(taskList[0].Id);
                MarketingExceptionInvokable.updateBloodDrive(taskIds);
            }catch(Exception e)
            {}
        Test.stopTest();       

    }
}