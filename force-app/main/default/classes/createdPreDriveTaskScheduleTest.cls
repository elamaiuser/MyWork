@isTest
public class createdPreDriveTaskScheduleTest {
    static testMethod void testBatch(){
        //Date next4Weeks = System.today().addDays(28);
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
     
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;
        
       	sked__Location__c site = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        site.Sponsor_Security_Form_Required__c = 'Pre-Drive';
        site.sked_Pre_Drive_Security_Due_Date__c='14';
        insert site;
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = site.Id;
        testMobileOpp.Drive_Date__c = System.Today().addDays(29);
        insert testMobileOpp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
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
            Source__c ='Custom New Form',
            Sponsor_Security_Form_Required__c = 'Pre-Drive',
            sked_Pre_Drive_Security_Due_Date__c='14'
        );
        
        insert mobileSite;
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Opportunity opp = new Opportunity();
            opp.AccountId = mobileAcc.id;
            opp.StageName = 'Complete';
        	opp.RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId();
            opp.Drive_Site__c = mobileSite.id;
			opp.Drive_Name__c = 'Name';
            opp.Drive_Date__c = System.today()+4;
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
        	TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
       /* try {
    	Opportunity op = [SELECT Id,Name FROM Opportunity
                                         WHERE drive_date__c >= today AND drive_date__c <: next4Weeks
                                         AND Drive_Site__r.Sponsor_Security_Form_Required__c includes ('Pre-Drive') Limit 1];	
        }
        catch (Exception e) {
           
       }  */
        Test.startTest();
        createdPreDriveTaskSchedule b = new createdPreDriveTaskSchedule();
        string sch = '0 0 2 * * ?';
        System.Schedule('TEST',sch,b);
        Test.stopTest();
    }
}