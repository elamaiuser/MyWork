/**
* @description: This class is the test class for PersonalStaffScheduleReportController Apex class.
**/
@isTest 
public class PersonalStaffScheduleReportTest {
    @isTest 
    public static void testPersonalStaffScheduleReportController(){
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account testAccount1 = new Account(
            Name = 'Test Account1',
            Internal_Name__c  = 'Test Internal Name 1',
            District_Manager__c = UserInfo.getUserId()
        );
        TriggerHandler.bypass('AccountTriggerHandler');
        insert testAccount1; 
        System.assertNotEquals(null,testAccount1.Id, 'Account Not Inserted.');
        
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery',
            CloseDate = system.today()+10,
            Is_template__c = TRUE
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert parentOpp; 
        System.assertNotEquals(null,parentOpp.Id, 'Opportunity Not Inserted.');
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
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
        insert testCollectionOperation1; 
        System.assertNotEquals(null,testCollectionOperation1.Id, 'Coll opp Not Inserted.');
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
            Source__c = 'Custom New Form',
            sked_Address_1__c = 'test address',
            sked_City__c = 'test city',
            sked_County__c = 'test country',
            sked_State__c = 'test state',
            sked_Zip_Code__c = '532432',
            sked_Timezone__c = UserInfo.getTimezone().getID()
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert testLocation1; 
        System.assertNotEquals(null,testLocation1.Id, 'site Not Inserted.');
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        System.assertNotEquals(null,testRegion1.Id, 'region Not Inserted.');
            sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive 1',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = parentOpp.Id,
            sked_Drive_Date__c = system.today()+5,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 1000,
            sked_Status__c = 'System Generated',
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 10           
        );
        triggerHandler.bypass('DriveTriggerHandler');
        insert testDrive1;
        System.assertNotEquals(null,testDrive1.Id, 'drive Not Inserted.');
        RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType='sked__Resource__c' AND Name = 'Staff'];
        
        sked__Resource__c testResource1 = new sked__Resource__c(
            									recordTypeId = rt.Id,
                                                sked__Email__c = 'test12@yopmail.com',
                                                sked_Employee_ID__c = '12345',
                                                sked__Is_Active__c = true,
                                                sked_Title__c = 'Test',
                                                sked_First_Name__c = 'Barnojit',
                                                sked_Preferred_First_Name__c = 'Barnotest',
                                                sked_Last_Name__c = 'Testone',
                                                sked_ULID__c = 'ULID1234',
                                                sked__Category__c = 'Employee',
                                                sked_Employment_Status__c = 'Active',
                                                //sked_Timezone__c = 'America/Los_Angeles',
                                                sked__Primary_Region__c = testRegion1.Id,
                                                sked__Resource_Type__c = 'Person',
                                                sked_Primary_Phone_Type__c = 'Home Phone',
                                                sked_Home_Phone__c = '123-123-4321',
                                                sked__Primary_Phone__c = '123-123-4321',
                                                sked_Address_Referenced_for_Scheduling__c = 'Work',
                                                sked_Mobile_Type__c = 'Inside',
                                                sked_Work_Address_GeoLocation__Latitude__s = 34.280308,
                                                sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
                                                sked_Work_Country__c = 'USA',
                                                sked_Work_City__c = 'Sylmar',
                                                sked_Work_State__c = 'CA',
                                                sked_Work_Address_1__c = '11970 Gager St',
                                                sked_Work_Zip_Code__c = '91342',
                                                sked_Timezone__c = UserInfo.getTimezone().getID(),
                                                OwnerId = UserInfo.getUserId(),
                                                sked__User__c = UserInfo.getUserId()
            
        );
        insert testResource1;
        System.assertNotEquals(null,testResource1.Id, 'resource Not Inserted.');
        sked__Availability__c availability1 = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Is_Available__c = True,
            sked__Status__c = 'Pending',
            sked__Start__c = Datetime.newInstance(2022, 12, 1, 12, 30, 2),
            sked__Finish__c = Datetime.newInstance(2022, 12, 18, 12, 30, 2),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c = System.today(),
            sked_Finish_Date__c = System.today()+6,
            sked__Type__c = 'PTO'
        );
        insert availability1;
        System.assertNotEquals(null,availability1.Id, 'availability Not Inserted.');
        sked__Activity__c activity = new sked__Activity__c(
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = Datetime.newInstance(2022, 7, 27, 0, 0, 0),
            sked_Start_Date__c = System.today()+1,
            sked_End_Date__c = System.today()+5,
            sked__End__c = Datetime.newInstance(2022, 7, 27, 17, 15, 0),
            //sked_Start_Time__c = Time.newInstance(0, 0, 0, 0),
            //sked_End_Time__c = Time.newInstance(17, 15, 0, 0),
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive__c = testDrive1.Id,
            sked_Region__c = testRegion1.Id,
            sked__Address__c = 'Test Address',
            sked__Notes__c = 'Test notes',
            sked_Is_Group_Activity__c = TRUE
        );
        insert activity;
        System.assertNotEquals(null,activity.Id, 'activity Not Inserted.');
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = activity.Id,
            sked__Resource__c = testResource1.Id
        );
        insert skedActivityResource;
        System.assertNotEquals(null,skedActivityResource.Id, 'skedActivity Resource Not Inserted.');
        sked_Drive_Shift__c skdDriveShift = new sked_Drive_Shift__c( 
            Name = 'Shift1',
            sked_Donors_Scheduled__c = 1,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = System.today()+5,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 10,
            //sked_Lunch_Break_Start_Time__c = Time.newInstance(1, 0, 0, 0),
            //sked_Lunch_Break_End_Time__c =  Time.newInstance(20, 0, 0, 0),
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            //sked_Start_Time__c = Time.newInstance(12, 0, 0, 0),
           //sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_UFID__c = '123456',
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert skdDriveShift;
        System.assertNotEquals(null,skdDriveShift.Id, 'shift Not Inserted.');
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+6,
            sked__Duration__c = 8640,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 10,
            sked_Dual_Role__c = 'Apheresis',
            sked__Type__c = 'Driver Support',
            sked_Drive_Shift__c = skdDriveShift.Id,
            sked_APT_Quantity__c = 10
        );
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('JobTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        insert job1;
        System.assertNotEquals(null,job1.Id, 'job Not Inserted.');
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = 'Dispatched',
            sked_Start_Date__c = system.today(),
            sked_Set_End_Date__c = system.today()+5,
            //sked_Start_Time__c = Time.newInstance(0, 0, 0, 0),
            //sked_Set_End_Time__c = Time.newInstance(17, 20, 0, 0),
            sked_Additional_Roles__c = 'Charge - Special Collections'
        );
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('JobAllocationTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        insert testResource1_job1;
        System.assertNotEquals(null,testResource1_job1.Id, 'job alloc Not Inserted.');
        Test.startTest();
        PersonalStaffScheduleReportController personalStaffController = new PersonalStaffScheduleReportController();
        System.assertNotEquals(null,personalStaffController, 'page ref is null.');
        Test.stopTest();
    }
    @isTest 
    public static void testPersonalStaffScheduleReportControllerV2(){
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account testAccount1 = new Account(
            Name = 'Test Account1',
            Internal_Name__c  = 'Test Internal Name 1',
            District_Manager__c = UserInfo.getUserId()
        );
        TriggerHandler.bypass('AccountTriggerHandler');
        insert testAccount1; 
        System.assertNotEquals(null,testAccount1.Id, 'Account Not Inserted.');
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery',
            CloseDate = system.today()+10,
            Is_template__c = TRUE
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert parentOpp; 
        System.assertNotEquals(null,parentOpp.Id, 'opportunity Not Inserted.');
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
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
        insert testCollectionOperation1; 
        System.assertNotEquals(null,testCollectionOperation1.Id, 'coll opp Not Inserted.');
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
            Source__c = 'Custom New Form',
            sked_Address_1__c = 'test address',
            sked_City__c = 'test city',
            sked_County__c = 'test country',
            sked_State__c = 'test state',
            sked_Zip_Code__c = '532432',
            sked_Timezone__c = UserInfo.getTimezone().getID()
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert testLocation1; 
        System.assertNotEquals(null,testLocation1.Id, 'site Not Inserted.');
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        System.assertNotEquals(null,testRegion1.Id, 'region Not Inserted.');
            sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive 1',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = parentOpp.Id,
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
        triggerHandler.bypass('DriveTriggerHandler');
        insert testDrive1;
        System.assertNotEquals(null,testDrive1.Id, 'drive Not Inserted.');
        RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType='sked__Resource__c' AND Name = 'Staff'];
        
        sked__Resource__c testResource1 = new sked__Resource__c(
            									recordTypeId = rt.Id,
                                                sked__Email__c = 'test12@yopmail.com',
                                                sked_Employee_ID__c = '12345',
                                                sked__Is_Active__c = true,
                                                sked_Title__c = 'Test',
                                                sked_First_Name__c = 'Barnojit',
                                                sked_Preferred_First_Name__c = 'Barnotest',
                                                sked_Last_Name__c = 'Testone',
                                                sked_ULID__c = 'ULID1234',
                                                sked__Category__c = 'Employee',
                                                sked_Employment_Status__c = 'Active',
                                                //sked_Timezone__c = 'America/Los_Angeles',
                                                sked__Primary_Region__c = testRegion1.Id,
                                                sked__Resource_Type__c = 'Person',
                                                sked_Primary_Phone_Type__c = 'Home Phone',
                                                sked_Home_Phone__c = '123-123-4321',
                                                sked__Primary_Phone__c = '123-123-4321',
                                                sked_Address_Referenced_for_Scheduling__c = 'Work',
                                                sked_Mobile_Type__c = 'Inside',
                                                sked_Work_Address_GeoLocation__Latitude__s = 34.280308,
                                                sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
                                                sked_Work_Country__c = 'USA',
                                                sked_Work_City__c = 'Sylmar',
                                                sked_Work_State__c = 'CA',
                                                sked_Work_Address_1__c = '11970 Gager St',
                                                sked_Work_Zip_Code__c = '91342',
                                                sked_Timezone__c = UserInfo.getTimezone().getID(),
                                                OwnerId = UserInfo.getUserId(),
                                                sked__User__c = UserInfo.getUserId()
        );
        insert testResource1;
        System.assertNotEquals(null,testResource1.Id, 'resource Not Inserted.');
        sked__Availability__c availability1 = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Is_Available__c = True,
            sked__Status__c = 'Pending',
            sked__Start__c = Datetime.newInstance(2022, 12, 1, 12, 30, 2),
            sked__Finish__c = Datetime.newInstance(2022, 12, 18, 12, 30, 2),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c = System.today(),
            sked_Finish_Date__c = System.today()+6,
            sked__Type__c = 'PTO'
        );
        insert availability1;
        System.assertNotEquals(null,availability1.Id, 'availability Not Inserted.');
        sked__Activity__c activity = new sked__Activity__c(
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = Datetime.newInstance(2022, 7, 27, 0, 0, 0),
            sked_Start_Date__c = System.today()+1,
            sked_End_Date__c = System.today()+5,
            sked__End__c = Datetime.newInstance(2022, 7, 27, 17, 15, 0),
            sked_Start_Time__c = Time.newInstance(0, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 15, 0, 0),
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive__c = testDrive1.Id,
            sked_Region__c = testRegion1.Id,
            sked__Address__c = 'Test Address',
            sked__Notes__c = 'Test notes',
            sked_Is_Group_Activity__c = TRUE
        );
        insert activity;
        System.assertNotEquals(null,activity.Id, 'activity Not Inserted.');
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = activity.Id,
            sked__Resource__c = testResource1.Id
        );
        insert skedActivityResource;
        System.assertNotEquals(null,skedActivityResource.Id, 'skedActivity Resource Not Inserted.');
        sked_Drive_Shift__c skdDriveShift = new sked_Drive_Shift__c( 
            Name = 'Shift1',
            sked_Donors_Scheduled__c = 1,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = System.today()+5,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 10,
            sked_Lunch_Break_Start_Time__c = Time.newInstance(1, 0, 0, 0),
            sked_Lunch_Break_End_Time__c =  Time.newInstance(20, 0, 0, 0),
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Start_Time__c = Time.newInstance(12, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_UFID__c = '123456',
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert skdDriveShift;
        System.assertNotEquals(null,skdDriveShift.Id, 'shift Not Inserted.');
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+6,
            sked__Duration__c = 8640,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 10,
            sked_Dual_Role__c = 'Apheresis',
            sked__Type__c = 'Driver Support',
            sked_Drive_Shift__c = skdDriveShift.Id,
            sked_APT_Quantity__c = 10
        );
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('JobTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        insert job1;
        System.assertNotEquals(null,job1.Id, 'job Not Inserted.');
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = 'Dispatched',
            sked_Start_Date__c = system.today(),
            sked_Set_End_Date__c = system.today()+5,
            sked_Start_Time__c = Time.newInstance(0, 0, 0, 0),
            sked_Set_End_Time__c = Time.newInstance(17, 20, 0, 0),
            sked_Additional_Roles__c = 'Charge - Special Collections'
        );
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('JobAllocationTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        insert testResource1_job1;
        System.assertNotEquals(null,testResource1_job1.Id, 'job alloc Not Inserted.');
        Test.startTest();
        PersonalStaffScheduleReportController personalStaffController = new PersonalStaffScheduleReportController();
        System.assertNotEquals(null,personalStaffController, 'page ref is null.');
        Test.stopTest();
    }
    @isTest 
    public static void testPersonalStaffScheduleReportControllerV3(){
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account testAccount1 = new Account(
            Name = 'Test Account1',
            Internal_Name__c  = 'Test Internal Name 1',
            District_Manager__c = UserInfo.getUserId()
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        insert testAccount1; 
        System.assertNotEquals(null,testAccount1.Id, 'Account Not Inserted.');
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery',
            CloseDate = system.today()+10,
            Is_template__c = TRUE
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert parentOpp; 
        System.assertNotEquals(null,parentOpp.Id, 'opportunity Not Inserted.');
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
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
        insert testCollectionOperation1; 
        System.assertNotEquals(null,testCollectionOperation1.Id, 'coll opp Not Inserted.');
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
            Source__c = 'Custom New Form',
            sked_Address_1__c = 'test address',
            sked_City__c = 'test city',
            sked_County__c = 'test country',
            sked_State__c = 'test state',
            sked_Zip_Code__c = '532432',
            sked_Timezone__c = UserInfo.getTimezone().getID()
        );
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert testLocation1; 
        System.assertNotEquals(null,testLocation1.Id, 'site Not Inserted.');
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        System.assertNotEquals(null,testRegion1.Id, 'region Not Inserted.');
            sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive 1',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = parentOpp.Id,
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
        triggerHandler.bypass('DriveTriggerHandler');
        insert testDrive1;
        System.assertNotEquals(null,testDrive1.Id, 'drive Not Inserted.');
        RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType='sked__Resource__c' AND Name = 'Staff'];
        
        sked__Resource__c testResource1 = new sked__Resource__c(
            									recordTypeId = rt.Id,
                                                sked__Email__c = 'test12@yopmail.com',
                                                sked_Employee_ID__c = '12345',
                                                sked__Is_Active__c = true,
                                                sked_Title__c = 'Test',
                                                sked_First_Name__c = 'Barnojit',
                                                sked_Preferred_First_Name__c = 'Barnotest',
                                                sked_Last_Name__c = 'Testone',
                                                sked_ULID__c = 'ULID1234',
                                                sked__Category__c = 'Employee',
                                                sked_Employment_Status__c = 'Active',
                                                //sked_Timezone__c = 'America/Los_Angeles',
                                                sked__Primary_Region__c = testRegion1.Id,
                                                sked__Resource_Type__c = 'Person',
                                                sked_Primary_Phone_Type__c = 'Home Phone',
                                                sked_Home_Phone__c = '123-123-4321',
                                                sked__Primary_Phone__c = '123-123-4321',
                                                sked_Address_Referenced_for_Scheduling__c = 'Work',
                                                sked_Mobile_Type__c = 'Inside',
                                                sked_Work_Address_GeoLocation__Latitude__s = 34.280308,
                                                sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
                                                sked_Work_Country__c = 'USA',
                                                sked_Work_City__c = 'Sylmar',
                                                sked_Work_State__c = 'CA',
                                                sked_Work_Address_1__c = '11970 Gager St',
                                                sked_Work_Zip_Code__c = '91342',
                                                sked_Timezone__c = UserInfo.getTimezone().getID(),
                                                OwnerId = UserInfo.getUserId(),
                                                sked__User__c = UserInfo.getUserId()
        );
        insert testResource1;
        System.assertNotEquals(null,testResource1.Id, 'resource Not Inserted.');
        sked_Drive_Shift__c skdDriveShift = new sked_Drive_Shift__c( 
            Name = 'Shift1',
            sked_Donors_Scheduled__c = 1,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = System.today()+5,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 10,
            sked_Lunch_Break_Start_Time__c = Time.newInstance(1, 0, 0, 0),
            sked_Lunch_Break_End_Time__c =  Time.newInstance(20, 0, 0, 0),
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Start_Time__c = Time.newInstance(12, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_UFID__c = '123456',
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert skdDriveShift;
        System.assertNotEquals(null,skdDriveShift.Id, 'shift Not Inserted.');
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+6,
            sked__Duration__c = 8640,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 10,
            sked_Dual_Role__c = 'Apheresis',
            sked__Type__c = 'Driver Support',
            sked_Drive_Shift__c = skdDriveShift.Id,
            sked_APT_Quantity__c = 10
        );
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('JobTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        insert job1;
        System.assertNotEquals(null,job1.Id, 'job Not Inserted.');
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today()+1,
            sked__Finish__c = system.today()+5,
            sked__Duration__c = 5760,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 12,
            sked_Dual_Role__c = 'Apheresis',
            sked__Type__c = 'Driver Support',
            sked_Drive_Shift__c = skdDriveShift.Id,
            sked_APT_Quantity__c = 10
        );
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('JobTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        insert job2;
        System.assertNotEquals(null,job2.Id, 'job Not Inserted.');
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = 'Dispatched',
            sked_Start_Date__c = system.today()+2,
            sked_Set_End_Date__c = system.today()+4,
            sked_Start_Time__c = Time.newInstance(0, 0, 0, 0),
            sked_Set_End_Time__c = Time.newInstance(17, 20, 0, 0),
            sked_Additional_Roles__c = 'Charge - Special Collections'
        );
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('JobAllocationTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        insert testResource1_job1;
        System.assertNotEquals(null,testResource1_job1.Id, 'job alloc Not Inserted.');
        sked__Job_Allocation__c testResource1_job2 = new sked__Job_Allocation__c(
            sked__Job__c = job2.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = 'Confirmed',
            sked_Start_Date__c = system.today()+2,
            sked_Set_End_Date__c = system.today()+4,
            sked_Start_Time__c = Time.newInstance(5, 25, 0, 0),
            sked_Set_End_Time__c = Time.newInstance(17, 20, 0, 0),
            sked_Additional_Roles__c = 'Charge - Special Collections'
        );
        triggerHandler.bypass('OpportunityTriggerHandler');
        triggerHandler.bypass('JobAllocationTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        insert testResource1_job2;
        System.assertNotEquals(null,testResource1_job2.Id, 'job alloc Not Inserted.');
        Test.startTest();
        PersonalStaffScheduleReportController personalStaffController = new PersonalStaffScheduleReportController();
        System.assertNotEquals(null,personalStaffController, 'page ref is null.');
        Test.stopTest();
    }
}