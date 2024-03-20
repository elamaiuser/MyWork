@isTest
public class BloodDriveInvokable_Test 
{
    static String Id_CollectionOperation = '';
    public static Map<String,Id> siterecordTypeMap  = new Map<String,Id>();
    public static String mobileSiteRecType = 'Mobile Site'; 
 @testSetup
 public static void setupMethod()
    {
       Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Map <String,Schema.RecordTypeInfo> recordTypesSite = sked__Location__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id MobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        Account mobileAcc = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            District_Manager__c = UserInfo.getUserId(),
        	BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420'
        );
        
        insert mobileAcc;
        
            }
    
    @isTest
    public static void Test_method()
    {
        TriggerHandler.bypass('AccountTriggerHandler');
         Account acc = [select id,account_status__c from account  LIMIT 1];
         acc.District_Manager__c = userinfo.getUserId();
         update acc;
        
        List<Account> AccList = new List<Account>();
        
        Account accobj;        
        accobj = new Account();
       // accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';
        accobj.Internal_Name__c = 'Exavalu';       
        AccList.add(accobj);
        insert AccList;

        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = AccList[0].Id ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
		conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conlist.add(conObj);
        insert conlist;
         
        TriggerHandler.bypass('OpportunityTriggerHandler');
         Opportunity opp = new Opportunity();
            opp.AccountId = acc.Id;
            opp.StageName = 'Closed';
        	opp.RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId();
            //opp.Drive_Site__c = SiteId;
			opp.Drive_Name__c = 'Test_Name';
            opp.Drive_Date__c = System.today();
            opp.CloseDate = opp.Drive_Date__c-1;
            Time startTime = Time.newInstance(10, 0, 0, 0);
            opp.Start_Time__c = startTime;
            Time endTime = Time.newInstance(15, 30, 0, 0);
            opp.Flow_Start_Time_Field__c = '1000';
            opp.Flow_End_Time_Field__c = '1530';
            opp.WB_Projected_Procedures__c = 4;
            opp.X2RBC_Projected_Procedures__c = 2;
            opp.Name = 'Test Opportunity';
            opp.Anticipated_Registered_Donors__c =25;
            opp.Accept_56_Day_Rule_Violation__c =true;
            opp.Drive_Status__c='Tentative';
			insert opp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
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
        );
        
       
            insert DRDAMUser;
        
        
        Id siteRecTypeId = siterecordTypeMap.get(mobileSiteRecType);
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
        sked__Location__c siteObj = new sked__Location__c();
        //siteObj.RecordTypeId = siteRecTypeId;
        siteObj.Name = 'Test Site';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
        siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = conlist[0].Id;
        siteObj.sked_Site_Main_Phone__c = '999-999-9999';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.source__c='Custom New Form';
        siteObj.sked_Address_1__c='Test Site Address';
        siteObj.sked_City__c='Test site city';
        siteObj.sked_County__c='AMERICA';
        siteObj.sked_State__c='test state';
        siteObj.sked_Wireless_Policy__c='Accepted';
        siteObj.sked_Zip_Code__c='94608';
        skedlocationlist.add(siteObj);
        triggerHandler.bypass('SiteTriggerHandler');
        insert skedlocationlist;
        
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                        sked_Hold_Threshold__c = 100,
                                                                                                        Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                        Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                        sked_Work_Week_First_Day__c = 'Sunday');
            insert testCollectionOperation1;
        	Id_CollectionOperation = testCollectionOperation1.Id;
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = skedlocationlist[0].id,
                                                        sked_Opportunity__c = opp.id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = AccList[0].id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 2,
                                                     	sked_WB_Projected_Procedures__c = 2,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED);
        insert testDrive1;
        
        List<id> oppid = new List<id>();
        oppid.add(opp.id);
        
        Test.StartTest();
		BloodDriveInvokable.sendNotificationToDMForBloodDrive(oppid);
		Test.stopTest();
        
        //system.assert(contrg.CronJobDetail.Name == 'Test schedule class');

        
    }
    
    
}