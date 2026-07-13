@isTest
public class BSF_Batch_UpdateAccountStatus_Test 
{
   
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
        
         sked__Location__c mobileSite = new sked__Location__c(
            Name = 'Test Mobile Location',
            RecordTypeId=  recordTypesSite.get('Mobile Site').getRecordTypeId(),  
            sked_TimeZone__c = 'America/New_York',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA, 27560',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = Date.today().addDays(-1),
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Inside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4321',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Address_1__c = 'Test Address', 
            sked_City__c = 'city', 
            sked_County__c = 'United States', 
            sked_State__c = 'Texas', 
            sked_Zip_Code__c = '27560',
            Source__c ='Custom New Form'
        );
        
        insert mobileSite;
        
    }
    
    @isTest
    Public static void Test_Schedule_Class()
    {
        Test.StartTest();
		BSF_Batch_UpdateAccountStatusScheduler testsche = new BSF_Batch_UpdateAccountStatusScheduler(200);
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
		Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class');
    }
    
    @isTest
    Public static void Test_Schedule_ClassUpdateAccountStatusInactive_Scheduler()
    {
        Test.StartTest();
		UpdateAccountStatusInactive_Scheduler testsche = new UpdateAccountStatusInactive_Scheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
		Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class');
    }
    
    @isTest
    Public static void Test_Account_Active()
    {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account acc = [select id,account_status__c from account  where name ='Test Account 1'];
        acc.account_status__c = 'Inactive';
        Update acc;
        
       
        BSF_Batch_UpdateAccountStatus_Test.createOpportunity (acc.id,'Closed','Test_Account_Active',2);
        BSF_Batch_UpdateAccountStatus_Test.createOpportunity (acc.id,'Closed','Test_Account_Active',0);
      
        
        test.startTest();
        BSF_Batch_UpdateAccountStatus batch = new BSF_Batch_UpdateAccountStatus ();
        database.executeBatch(batch);
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        test.stopTest();
        Account UpdatedAcc = [select id,account_status__c from account where id=:acc.id];
        
        system.assert(UpdatedAcc.Account_Status__c == 'Active');
    }
    
    @isTest
    Public static void Test_Account_Lapsed()
    {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account acc = [select id,account_status__c from account  LIMIT 1];
        acc.account_status__c = 'Inactive';
        Update acc;
        
        
        BSF_Batch_UpdateAccountStatus_Test.createOpportunity (acc.id,'Closed','Test_Account_Lapsed',800);
       
        test.startTest();
        BSF_Batch_UpdateAccountStatus batch = new BSF_Batch_UpdateAccountStatus ();
        database.executeBatch(batch);
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        test.stopTest();
        
        Account UpdatedAcc = [select id,account_status__c from account where id=:acc.id];
        system.assert(UpdatedAcc.Account_Status__c == 'Lapsed');
    }
    
    @isTest
    Public static void Test_Account_Inactive()
    {
		TriggerHandler.bypass('OpportunityTriggerHandler');
        Account acc = [select id,account_status__c from account  LIMIT 1];
        acc.account_status__c = 'Active';
        Update acc;
        
        
        BSF_Batch_UpdateAccountStatus_Test.createOpportunity (acc.id,'Closed','Test_Account_Inactive',600);
        
        test.startTest();
        BSF_Batch_UpdateAccountStatus batch = new BSF_Batch_UpdateAccountStatus ();
        database.executeBatch(batch);
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        test.stopTest();
        
        Account UpdatedAcc = [select id,account_status__c from account where id=:acc.id];
        system.assert(UpdatedAcc.Account_Status__c == 'Inactive');
    }
    
    @isTest
    Public static void Test_Account_Reactivate()
    {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account acc = [select id,account_status__c from account  LIMIT 1];
        acc.account_status__c = 'Defunct';
        Update acc;
        
        BSF_Batch_UpdateAccountStatus_Test.createOpportunity (acc.id,'Discovery','Test_Account_Reactivate',0);
        
        Opportunity opp = [select Id,Drive_Date__c,AccountId,StageName from opportunity where accountId=:acc.id];
        opp.AccountId =acc.id;
        opp.StageName = 'Discovery';
        update opp;
        
        test.startTest();
        BSF_Batch_UpdateAccountStatus batch = new BSF_Batch_UpdateAccountStatus ();
        database.executeBatch(batch);
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        test.stopTest();
        
        Account UpdatedAcc = [select id,account_status__c from account where id=:acc.id];
        system.assert(UpdatedAcc.Account_Status__c == 'Reactivate');
    }
    
    @isTest
    Public static void Test_Account_BSF_Batch_UpdateAccountStatusInactive()
    {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account acc = [select id,account_status__c from account  LIMIT 1];
        acc.account_status__c = 'Active';
        Update acc;
        
        List<Opportunity> oppList = [select Id,Drive_Date__c,AccountId,StageName from opportunity];
        delete oppList;
        BSF_Batch_UpdateAccountStatus_Test.createOpportunity (acc.id,'Closed','Test_Account_Inactive',600);
        
        test.startTest();
        BSF_Batch_UpdateAccountStatusInactive batch = new BSF_Batch_UpdateAccountStatusInactive ();
        database.executeBatch(batch);
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        test.stopTest();
        
        Account UpdatedAcc = [select id,account_status__c from account where id=:acc.id];
        system.assert(UpdatedAcc.Account_Status__c == 'Inactive');
    }
    
    @isTest
    Public static void Test_Account_BSF_Batch_UpdateAccountStatusInactive2()
    {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account acc = [select id,account_status__c from account  LIMIT 1];
        acc.account_status__c = 'Active';
        Update acc;
        
        BSF_Batch_UpdateAccountStatus_Test.createOpportunity (acc.id,'Complete','Test_Account_Inactive',-5);
        BSF_Batch_UpdateAccountStatus_Test.createOpportunity (acc.id,'Complete','Test_Account_Inactive',-5);
        
        test.startTest();
        BSF_Batch_UpdateAccountStatusInactive batch = new BSF_Batch_UpdateAccountStatusInactive ();
        database.executeBatch(batch);
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        test.stopTest();
        
        Account UpdatedAcc = [select id,account_status__c from account where id=:acc.id];
        system.assert(UpdatedAcc.Account_Status__c == 'Active');
    }
    
    @isTest
    Public static void Test_Account_BSF_Batch_UpdateAccountStatusInactive_Schedule_Class()
    {
        Test.StartTest();
        TriggerHandler.bypass('OpportunityTriggerHandler');
		BSF_Batch_UpdateAccountStatusInactive testsche = new BSF_Batch_UpdateAccountStatusInactive();
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
		Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class');
    }
    
    public static Opportunity createOpportunity (id accId,String Stage,String Name, Integer driveDateOffset)
    {
           Opportunity opp = new Opportunity();
            opp.AccountId = accId;
            opp.StageName = Stage;
        	opp.RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId();
            //opp.Drive_Site__c = SiteId;
			opp.Drive_Name__c = Name;
            opp.Drive_Date__c = System.today()-driveDateOffset;
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
            opp.Drive_Status__c='Complete';
			insert opp; 
        return opp;
    }
}