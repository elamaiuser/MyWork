@isTest
public class PowerBIProxyController_test 
{
    @testSetup static void setUpData() 
    {
        Account testAccount1 = new Account(
            Name = 'Test Account1',
            Internal_Name__c  = 'Test Internal Name 1',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1; 
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Maximum_Lunch_Break_Duration__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation1;     
        
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            // sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = system.today(),
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
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
            Source__c = 'Custom New Form',sked_Address_1__c = 'test address',
			sked_City__c = 'test city',
			sked_County__c = 'test country',
			sked_State__c = 'test state',
			sked_Zip_Code__c = '532432',
            sked_Timezone__c = UserInfo.getTimezone().getID()
        );
        triggerHandler.bypass('SiteTriggerHandler');
        insert testLocation1; 
        
       
        
         opportunity opp = new opportunity(
        Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            //Drive_Site__c = mobileSite.id,
            accountid= testAccount1.id);
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive 1',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = opp.Id,
            sked_Drive_Date__c = system.today()+5,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 1000,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 10           
        );
        insert testDrive1;
        
        sked__Job__c job3 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 60,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION
        );
        triggerHandler.bypass('JobTriggerHandler');
        insert job3;
    }
    
    @isTest
	public static void testMethod1()
    {
        Test.startTest();
        PageReference pageRef = Page.StagingSheetReport;
        Test.setCurrentPage(pageRef);
        PowerBIProxyController controller = new PowerBIProxyController();
        controller.jid=string.valueof([select id from sked__Job__c where sked_Asset_Type__c='Equipment' limit 1].id);
        controller.redirect();
        test.stopTest();
    }
    
    @isTest
	public static void testMethod2()
    {
        Test.startTest();
        PageReference pageRef = Page.WeeklyStaffingRoleReport;
        Test.setCurrentPage(pageRef);
        PowerBIProxyController controller = new PowerBIProxyController();
        controller.jid=string.valueof([select id from sked__Job__c where sked_Asset_Type__c='Equipment' limit 1].id);
        controller.redirect();
        test.stopTest();
    }
    @isTest
	public static void testMethod3()
    {
        Test.startTest();
        PageReference pageRef = Page.MOEStagingSheetReport;
        Test.setCurrentPage(pageRef);
        PowerBIProxyController controller = new PowerBIProxyController();
        controller.jid=string.valueof([select id from sked__Job__c where sked_Asset_Type__c='Equipment' limit 1].id);
        controller.redirect();
        test.stopTest();
    }
}