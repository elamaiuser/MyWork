/*
* This Test class covering the following Classes
* DriveResourceAllocationBatch 
* */
/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 05/11/2023                  Krapy Tuli                HRP-10009
 * 06/22/2023                  Krapy Tuli                HRP-10212
 * 06/22/2023                  Krapy Tuli                HRP-10213
 * *
 *****************************************************************************
*/

@isTest
private class DriveResourceAllocationBatchTest {

    public static final string RESOURCE_TYPE_PERSON = 'Person';
    public static final string RESOURCE_TYPE_ASSET = 'Asset';
    public static final string DRIVE_STATUS_DRAFT = 'Draft';
    public static final string JOB_STATUS_PENDING_ALLOCATION = 'Pending Allocation';
    public static final string TAG_ROLE_STATUS_PENDING = 'Pending';
    public static final string AVAILABILITY_TYPE_PTO = 'PTO';
    public static final string LOCATION_RESOURCE_SCORE_DECLINED = 'Declined';
    public static final string JOB_ALLOCATION_STATUS_PENDING_DISPATCH = 'Pending Dispatch';
    
    @testSetup static void setup() {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Map<string, List<string>> mapResourceTypeCategories =
            skedPicklistFieldUtils.getMapDependentOptions(sked__Resource__c.sked__Resource_Type__c, sked__Resource__c.sked__Category__c);
        List<string> resourceCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_PERSON);
        List<string> assetCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_ASSET);
        List<string> resourceEmploymentTypes = skedUtils.getPickListValues('sked__Resource__c', 'sked__Employment_Type__c');
        List <sked__Resource__c> ResourceList = new List<sked__Resource__c>();       
        List <sked__Resource_Tag__c> resourceTags = new List <sked__Resource_Tag__c>();
        List<sked__Resource_Override__c> resourceOverRides = new List<sked__Resource_Override__c>();
        
        Account testAccount1 = new Account(
            Name = 'Test Account1',
            Internal_Name__c  = 'Test Internal Name 1',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1; 
        
        Account testAccount2 = new Account(
            Name = 'Test Account2',
            Internal_Name__c  = 'Test Internal Name 2',
            District_Manager__c = UserInfo.getUserId()
        );
        
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
            Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Maximum_Lunch_Break_Duration__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation2;        
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        sked__Region__c testRegion2 = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation2.Id
        );
        insert testRegion2;
        
        
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            Operation_Type__c = 'Integrated',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
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
        insert testLocation1; 
        
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery',
            CloseDate = system.today()+10,
            Is_template__c = TRUE
        );
        insert parentOpp;       
        
        sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive 1',
            sked_Day_of_Week__c = 'Monday',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = parentOpp.Id,
            sked_Drive_Date__c = system.today()+5,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 50,
            sked_Status__c = DRIVE_STATUS_DRAFT,
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 10           
        );
        insert testDrive1;
        
        sked_Drive__c testDrive2 = new sked_Drive__c(
            Name = 'Test Drive 2',
            sked_Day_of_Week__c = 'Monday',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = parentOpp.Id,
            sked_Drive_Date__c = system.today()+5,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount2.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 1000,
            sked_Status__c = DRIVE_STATUS_DRAFT,
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 10           
        );
        insert testDrive2;
        
          sked_Drive__c testDrive3 = new sked_Drive__c(
            Name = 'TestDrive3',
            sked_Day_of_Week__c = 'Monday',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = parentOpp.Id,
            sked_Drive_Date__c = system.today()+5,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount2.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 1000,
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 10,
            sked_Status__c = 'System Generated'
        );
        insert testDrive3;
        
         sked_Drive__c testDrive4 = new sked_Drive__c(
            Name = 'TestDrive3',
            sked_Day_of_Week__c = 'Monday',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = parentOpp.Id,
            sked_Drive_Date__c = system.today()+5,
            sked_Type_of_Drive__c = 'Fixed Site',
            sked_Account__c = testAccount2.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 1000,
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 10,
            sked_WB_Projected_Procedures__c = 2,
            sked_Status__c = 'Tentative'
        );
        insert testDrive4;
        
       sked_Operation_Drive_Limit__c skedDriveLimit =  new sked_Operation_Drive_Limit__c(
       sked_Type__c = 'DOT Limit',
       sked_Collection_Operation__c = testCollectionOperation1.Id,
       sked_Effective_Start_Date__c =  system.today(),
       sked_Days_of_Week__c ='Monday',
       sked_Effective_End_Date__c = null,
       sked_Quantity__c = 60
        );
        insert skedDriveLimit;
       sked_Operation_Drive_Limit__c skedDriveLimit2 =  new sked_Operation_Drive_Limit__c(
       sked_Type__c = '2RBC Limit',
       sked_Collection_Operation__c = testCollectionOperation1.Id,
       sked_Effective_Start_Date__c =  system.today(),
       sked_Days_of_Week__c ='Monday',
       sked_Effective_End_Date__c = null,
       sked_Quantity__c = 60
        );
        insert skedDriveLimit2;
        
       sked_Operation_Drive_Limit__c skedDriveLimit3 =  new sked_Operation_Drive_Limit__c(
       sked_Type__c = 'CDL Limit',
       sked_Collection_Operation__c = testCollectionOperation1.Id,
       sked_Effective_Start_Date__c =  system.today(),
       sked_Days_of_Week__c ='Monday',
       sked_Effective_End_Date__c = null,
       sked_Quantity__c = 60
        );
        insert skedDriveLimit3;
        
      sked__Job__c job1 = new sked__Job__c(
            sked__Quantity__c = 2,
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 60,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = 'Vehicle',
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION
        );
        insert job1;
        
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 60,
            sked_Drive__c = testDrive2.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 10,
            sked__Type__c = Constants.JOB_TYPE_VP_HH,
            sked_APT_Quantity__c = 10
        );
        insert job2;        
        sked__Job__c job3 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 60,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION
        );
        insert job3;
        
        sked__Job__c job4 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 60,
            sked_Drive__c = testDrive3.Id,
            sked_Asset_Type__c = 'Vehicle',
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 10,
            sked__Type__c = Constants.JOB_TYPE_VP_HH,
            sked_APT_Quantity__c = 10
        );
        insert job4;  
        
         sked__Job__c job5 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 60,
            sked_Drive__c = testDrive2.Id,
            sked_Asset_Type__c = null,
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 2,
            sked__Type__c = '2RBC',
            sked_APT_Quantity__c = 10
        );
        insert job5;  
        
         sked__Job__c job6 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 60,
            sked_Drive__c = testDrive2.Id,
            sked_Asset_Type__c = null,
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 1,
            sked__Type__c = '2RBC',
            sked_APT_Quantity__c = 10
        );
        insert job6;  
        
         sked__Job__c job7 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 60,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = null,
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 5,
            sked__Type__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_APT_Quantity__c = 10   
        );
        insert job7; 
        
         sked__Job__c job8 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 60,
            sked_Drive__c = testDrive3.Id,
            sked_Asset_Type__c = null,
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 3,
            sked__Type__c = Constants.JOB_TYPE_VP_HH,
            sked_APT_Quantity__c = 10
        );
        insert job8; 
        
        sked_Staffing_Constraint__c mobileStaffingConstraint = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Date_of_Constraint__c = testDrive2.sked_Drive_Date__c,
            sked_Drive_Type__c = 'Mobile',
            sked_Total_Staff_Constraints__c = 100 // HRP-10212
        );
        insert mobileStaffingConstraint;
        
        sked_Staffing_Constraint__c mobileStaffingConstraint1 = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Date_of_Constraint__c = testDrive2.sked_Drive_Date__c,
            sked_Drive_Type__c = 'Fixed Site',
            sked_Total_Staff_Constraints__c = 20
        );
        insert mobileStaffingConstraint1;
        
        sked__Tag__c driveTypeTagFixedSite2 = new sked__Tag__c(
            Name = 'Fixed Site',
            sked__Type__c = 'Physical Location Type'
        );
        insert driveTypeTagFixedSite2;
        
        sked__Tag__c driveTypeTagInside = new sked__Tag__c(
            Name = 'Inside',
            sked__Type__c = 'Physical Location Type'
        );
        insert driveTypeTagInside;       
        skedHubBase.BypassInsertTriggers = true; // DriveResourceAllocationBatch
        
        sked__Resource__c testResource1 = new sked__Resource__c(
            Name = 'Test Resource1',
            sked_DOT__c = true, // HRP-10212
            sked__Primary_Region__c = testRegion1.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '001',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Steve',
            sked_Last_Name__c = 'King',
            sked_Asset_Type__c = 'Vehicle',
            sked_ULID__c = '248ch40jgj3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = testLocation1.Id,
            sked_MigrationID__c = '25',
            sked_Mobile_Type__c = 'Inside',
            OwnerId = UserInfo.getUserId()
        );
        ResourceList.add(testResource1);       
        
        sked__Resource__c testResource2 = new sked__Resource__c(
            Name = 'Test Resource2',
            sked_DOT__c = true, // HRP-10212
            sked__Primary_Region__c = testRegion2.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = '2RBC',
            sked_Employee_ID__c = '005',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Steve',
            sked_Last_Name__c = 'King',
            sked_Asset_Type__c = 'Equipment',
            sked_Equipment_Subtype__c = '2RBC Asset',
            sked_ULID__c = '248ch45jgj3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = testLocation1.Id,
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        ResourceList.add(testResource2);
        sked__Resource__c testResource3 = new sked__Resource__c(
            Name = 'Test Resource2',
            sked_CDL__c = true, // HRP-10212
            sked__Primary_Region__c = testRegion1.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '005',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Steve',
            sked_Last_Name__c = 'King',
            sked_Asset_Type__c = 'Equipment',
            sked_Equipment_Subtype__c = '2RBC Asset', // DriveResourceAllocationBatch
            sked_ULID__c = '248ch3Fjgj3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = testLocation1.Id,
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        ResourceList.add(testResource3);
        sked__Resource__c testResource4 = new sked__Resource__c(
            Name = 'Test Resource2',
            sked_DOT__c =  true, // HRP-10212
            sked__Primary_Region__c = testRegion1.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '005',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Steve',
            sked_Last_Name__c = 'King',
            sked_Asset_Type__c = 'Equipment',
            sked_Equipment_Subtype__c = '2RBC Asset', // DriveResourceAllocationBatch
            sked_ULID__c = '248ch45jg3D3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = testLocation1.Id,
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        ResourceList.add(testResource4);
        

        
        // HRP-10212 and HRP-10213 start
        sked__Resource__c testResource5 = new sked__Resource__c(
            Name = 'Test Resource5',
            sked__Primary_Region__c = testRegion1.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '001',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Steve',
            sked_Last_Name__c = 'King',
            sked_Asset_Type__c = 'Vehicle',
            sked_ULID__c = '248ch40jgj4',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = testLocation1.Id,
            sked_MigrationID__c = '25',
            sked_Mobile_Type__c = 'Inside',
            OwnerId = UserInfo.getUserId()
        );
        ResourceList.add(testResource5);

        sked__Resource__c testResource6 = new sked__Resource__c(
            Name = 'Test Resource6',
            sked_CDL__c = true, // HRP-10212
            sked__Primary_Region__c = testRegion1.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '001',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Steve',
            sked_Last_Name__c = 'King',
            sked_Asset_Type__c = 'Vehicle',
            sked_ULID__c = '248ch40jgj9',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = testLocation1.Id,
            sked_MigrationID__c = '25',
            sked_Mobile_Type__c = 'Inside',
            OwnerId = UserInfo.getUserId()
        );
        ResourceList.add(testResource6);

        // HRP-10212 and HRP-10213 end
        insert ResourceList;  
        
         sked_Resource_Biomed_Collection_Op__c skdResource = new sked_Resource_Biomed_Collection_Op__c(
         sked_Biomed_Collection_Op_Center__c =  testCollectionOperation1.Id,
         sked_Resource__c = ResourceList[1].id,
         sked_Start_Date__c =  System.today()
        );
        // HRP-10212 and HRP-10213 start
        sked_Resource_Biomed_Collection_Op__c skdResource1 = new sked_Resource_Biomed_Collection_Op__c(
         sked_Biomed_Collection_Op_Center__c =  testCollectionOperation1.Id,
         sked_Resource__c = ResourceList[4].id,
         sked_Start_Date__c =  System.today()
        );
        // HRP-10212 and HRP-10213 end
        
        
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job1;
        
        sked__Job_Allocation__c testResource1_job2 = new sked__Job_Allocation__c(
            sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job2;
        
        sked__Job_Allocation__c testResource1_job3 = new sked__Job_Allocation__c(
            sked__Job__c = job3.Id,
            sked__Resource__c = testResource3.Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job3;
        sked__Job_Allocation__c testResource1_job4 = new sked__Job_Allocation__c(
            sked__Job__c = job4.Id,
            sked__Resource__c = testResource4.Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job4;
        
        sked__Job_Allocation__c testResource1_job5 = new sked__Job_Allocation__c(
            sked__Job__c = job8.Id,
            sked__Resource__c = testResource3.Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job5;
        
         //skedHubBase.BypassInsertTriggers = false;
        sked__Resource_Tag__c testResource1_testTag1 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource2.Id,
            sked__Tag__c = driveTypeTagFixedSite2.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        resourceTags.add(testResource1_testTag1);
        
        sked__Resource_Tag__c testResource1_testTag2 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource1.Id,
            sked__Tag__c = driveTypeTagFixedSite2.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        resourceTags.add(testResource1_testTag2);
        sked__Resource_Tag__c testResource1_testTag3 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource3.Id,
            sked__Tag__c = driveTypeTagFixedSite2.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        resourceTags.add(testResource1_testTag3);
        sked__Resource_Tag__c testResource1_testTag4 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource4.Id,
            sked__Tag__c = driveTypeTagFixedSite2.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        resourceTags.add(testResource1_testTag4);
        // HRP-10212 and HRP-10213 start
        sked__Resource_Tag__c testResource5_testTag3 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource5.Id,
            sked__Tag__c = driveTypeTagFixedSite2.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        resourceTags.add(testResource5_testTag3);
        // HRP-10212 and HRP-10213 end
        insert resourceTags;
        
        

        sked__Resource_Override__c sOverride = new sked__Resource_Override__c(
            sked_Collection_Operation__c= testCollectionOperation1.Id,
            sked__Resource__c = testResource2.Id,
            sked_Start_Date__c = system.today() + 5,
            sked__Start__c = Datetime.newInstance(2022, 7, 12, 12, 0, 0),
            sked_End_Date__c = System.today() + 5,
            sked__End__c = Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(20, 0, 0, 0),
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked_Timezone__c = 'America/Los_Angeles',
            sked_Travel_Back_Start__c = Datetime.newInstance(2022, 7, 21, 12, 0, 0) ,  
            sked_Travel_Back_Start_Date__c = Date.newInstance(2022,7,21),
            sked_Travel_Back_Start_Time__c = Time.newInstance(12, 45, 0, 0)  ,
            sked_Travel_Back_End__c =Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_Travel_Back_End_Date__c = Date.newInstance(2022, 7,30 ),
            sked_Travel_Back_End_Time__c = Time.newInstance(12, 15, 0, 0),
            sked_Travel_To_End__c = Datetime.newInstance(2022, 7, 31, 12, 0, 0),
            sked_Travel_To_End_Date__c = Date.newInstance(2022, 7, 30),
            sked_Travel_To_End_Time__c = Time.newInstance(12, 45, 0, 0),
            sked_Travel_To_Start__c = Datetime.newInstance(2022, 7, 27, 12, 0, 0),
            sked_Travel_To_Start_Date__c = Date.newInstance(2022, 7, 21),
            sked_Travel_To_Start_Time__c = Time.newInstance(12, 45, 0, 0) 
        );
        resourceOverRides.add(sOverride);
        
        sked__Resource_Override__c sOverride2 = new sked__Resource_Override__c(
            sked_Collection_Operation__c= testCollectionOperation1.Id,
            sked__Resource__c = testResource1.Id,
            sked_Start_Date__c = system.today() + 5,
            sked__Start__c = Datetime.newInstance(2022, 7, 12, 12, 0, 0),
            sked_End_Date__c = System.today() + 5,
            sked__End__c = Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(20, 0, 0, 0),
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked_Timezone__c = 'America/Los_Angeles',
            sked_Travel_Back_Start__c = Datetime.newInstance(2022, 7, 21, 12, 0, 0) ,  
            sked_Travel_Back_Start_Date__c = Date.newInstance(2022,7,21),
            sked_Travel_Back_Start_Time__c = Time.newInstance(12, 45, 0, 0)  ,
            sked_Travel_Back_End__c =Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_Travel_Back_End_Date__c = Date.newInstance(2022, 7,30 ),
            sked_Travel_Back_End_Time__c = Time.newInstance(12, 15, 0, 0),
            sked_Travel_To_End__c = Datetime.newInstance(2022, 7, 31, 12, 0, 0),
            sked_Travel_To_End_Date__c = Date.newInstance(2022, 7, 30),
            sked_Travel_To_End_Time__c = Time.newInstance(12, 45, 0, 0),
            sked_Travel_To_Start__c = Datetime.newInstance(2022, 7, 27, 12, 0, 0),
            sked_Travel_To_Start_Date__c = Date.newInstance(2022, 7, 21),
            sked_Travel_To_Start_Time__c = Time.newInstance(12, 45, 0, 0) 
        );
        resourceOverRides.add(sOverride2);
        // HRP-10212 and HRP-10213 start
        sked__Resource_Override__c sOverride3 = new sked__Resource_Override__c(
            sked_Collection_Operation__c= testCollectionOperation1.Id,
            sked__Resource__c = testResource5.Id,
            sked_Start_Date__c = system.today() + 5,
            sked__Start__c = Datetime.newInstance(2022, 7, 12, 12, 0, 0),
            sked_End_Date__c = System.today() + 5,
            sked__End__c = Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(20, 0, 0, 0),
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked_Timezone__c = 'America/Los_Angeles',
            sked_Travel_Back_Start__c = Datetime.newInstance(2022, 7, 21, 12, 0, 0) ,  
            sked_Travel_Back_Start_Date__c = Date.newInstance(2022,7,21),
            sked_Travel_Back_Start_Time__c = Time.newInstance(12, 45, 0, 0)  ,
            sked_Travel_Back_End__c =Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_Travel_Back_End_Date__c = Date.newInstance(2022, 7,30 ),
            sked_Travel_Back_End_Time__c = Time.newInstance(12, 15, 0, 0),
            sked_Travel_To_End__c = Datetime.newInstance(2022, 7, 31, 12, 0, 0),
            sked_Travel_To_End_Date__c = Date.newInstance(2022, 7, 30),
            sked_Travel_To_End_Time__c = Time.newInstance(12, 45, 0, 0),
            sked_Travel_To_Start__c = Datetime.newInstance(2022, 7, 27, 12, 0, 0),
            sked_Travel_To_Start_Date__c = Date.newInstance(2022, 7, 21),
            sked_Travel_To_Start_Time__c = Time.newInstance(12, 45, 0, 0) 
        );
        resourceOverRides.add(sOverride3);
        // HRP-10212 and HRP-10213 end
        insert resourceOverRides;
        
       /* sked__Account_Resource_Score__c a = new sked__Account_Resource_Score__c();
        a.sked__Resource__c = testResource2.Id;
        a.sked__Account__c = testAccount1.Id;
        a.sked__Blacklisted__c = false;
        a.sked_Account_Resource_Relationship__c = 'Preferred';
        accountScoreList.add(a);
        
        sked__Account_Resource_Score__c b = new sked__Account_Resource_Score__c();
        b.sked__Resource__c = testResource1.Id;
        b.sked__Account__c = testAccount1.Id;
        b.sked__Blacklisted__c = false;
        b.sked_Account_Resource_Relationship__c = 'Preferred';
        accountScoreList.add(b);
        
        insert accountScoreList;*/
    }
    static testmethod void testBatchMethod() {
        
        Test.startTest(); 
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;

        Map<string, List<string>> mapResourceTypeCategories =
            skedPicklistFieldUtils.getMapDependentOptions(sked__Resource__c.sked__Resource_Type__c, sked__Resource__c.sked__Category__c);
        List<string> resourceCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_PERSON);
        List<string> assetCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_ASSET);
        List<string> resourceEmploymentTypes = skedUtils.getPickListValues('sked__Resource__c', 'sked__Employment_Type__c');
        
         List <sked__Resource__c> resList = new List<sked__Resource__c>();
        
        resList = [Select Id,Name,sked_Asset_Type__c,sked_pres_donor_capacity__c From sked__Resource__c limit 2];
        List<sked__Job_Allocation__c> jobAllocationList = [SELECT Id, sked__Resource__c, sked__Job__c FROM sked__Job_Allocation__c];
        
        sked__Resource__c skdResEquipment = [select id,sked__Primary_Region__r.sked__Timezone__c from sked__Resource__c where sked_Asset_Type__c= 'Equipment' limit 1];

        sked__Tag__c skdTag = [SELECT Id FROM sked__Tag__c Where sked__Type__c = 'Physical Location Type' limit 1];
        Biomed_Collection_Op_Center__c collOpr = [SELECT Id, sked_Breakdown_Time_Threshold__c, sked_High_Drive_Productivity_Threshold__c,
                                                  sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Duration_Fixed_Site__c, sked_Lunch_Break_Duration_Mobile__c, 
                                                  sked_Maximum_Drive_End_Time__c, sked_Maximum_Shift_Length_Threshold__c, sked_Mid_Drive_Productivity_Threshold__c, 
                                                  sked_Minimum_Drive_Start_Time__c, sked_Setup_Time_Threshold__c, sked_Skip_Last_Appointment_For__c, sked_Unpaid_Lunch_Break_Duration__c
                                                  FROM Biomed_Collection_Op_Center__c limit 1];
        
        sked__Region__c skdRegion = [SELECT Id, sked__Timezone__c FROM sked__Region__c limit 1];
        
        sked__Location__c skdLocation = [SELECT Id, Name, sked_Collection_Operation__c, sked_Date_Site_Inspection_Completed__c, sked_Fixed_Site_Appointment_Pattern__c,
                                         sked_Physical_Location_Type__c, sked_Travel_Time_to_Staging_Location__c, sked_Timezone__c,
                                         sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c FROM sked__Location__c  limit 1];
        
        sked__Job__c  skdJob = [SELECT Id,sked_Drive__c,sked__Job_Status__c,sked__Type__c,sked__Quantity__c,sked_Asset_Type__c FROM sked__Job__c  WHERE sked__Job_Status__c=: JOB_STATUS_PENDING_ALLOCATION And sked_Asset_Type__c = 'Equipment' limit 1];
        sked_Drive__c skdDrive = [select Id, sked_Drive_Date__c,sked_Type_of_Drive__c, sked_Projected_Registered_Donors__c from sked_Drive__c limit 1];
        
        sked_Resource_Biomed_Collection_Op__c skdBioCollection = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c =skdResEquipment.Id,
            sked_Biomed_Collection_Op_Center__c = collOpr.Id,
            sked_Start_Date__c = system.today()+5,
            sked_End_Date__c = system.today()+10
        );
        insert skdBioCollection;    
        

        Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Maximum_Lunch_Break_Duration__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation2;
        
        sked__Resource_Override__c sOverride = new sked__Resource_Override__c(
            sked_Collection_Operation__c= testCollectionOperation2.Id,
            sked__Resource__c = skdResEquipment.Id,
            sked_Start_Date__c = system.today() + 6,
            sked__Start__c = Datetime.newInstance(2022, 7, 12, 12, 0, 0),
            sked_End_Date__c = System.today() + 4,
            sked__End__c = Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(20, 0, 0, 0),
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked_Timezone__c = 'America/Los_Angeles',
            sked_Travel_Back_Start__c = Datetime.newInstance(2022, 7, 21, 12, 0, 0) ,  
            sked_Travel_Back_Start_Date__c = Date.newInstance(2022,7,21),
            sked_Travel_Back_Start_Time__c = Time.newInstance(12, 45, 0, 0)  ,
            sked_Travel_Back_End__c =Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_Travel_Back_End_Date__c = Date.newInstance(2022, 7,30 ),
            sked_Travel_Back_End_Time__c = Time.newInstance(12, 15, 0, 0),
            sked_Travel_To_End__c = Datetime.newInstance(2022, 7, 31, 12, 0, 0),
            sked_Travel_To_End_Date__c = Date.newInstance(2022, 7, 30),
            sked_Travel_To_End_Time__c = Time.newInstance(12, 45, 0, 0),
            sked_Travel_To_Start__c = Datetime.newInstance(2022, 7, 27, 12, 0, 0),
            sked_Travel_To_Start_Date__c = Date.newInstance(2022, 7, 21),
            sked_Travel_To_Start_Time__c = Time.newInstance(12, 45, 0, 0) 
        );
        insert sOverride;
        
        /*sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = skdJob.Id,
            sked__Resource__c = skdResEquipment.Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job1;*/
        
        sked__Availability__c availability1 = new sked__Availability__c(
            sked__Resource__c = skdResEquipment.Id,
            sked__Is_Available__c = True,
            sked__Status__c = 'Pending',
            sked__Start__c = Datetime.newInstance(2022, 12, 1, 12, 30, 2),
            sked__Finish__c = Datetime.newInstance(2022, 12, 18, 12, 30, 2),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c = System.today()+7,
            sked_Finish_Date__c = System.today()+6,
            sked__Type__c = AVAILABILITY_TYPE_PTO
        );
        insert availability1;
        
       sked__Activity__c activity = new sked__Activity__c(
            sked__Resource__c = skdResEquipment.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = Datetime.newInstance(2022, 7, 27, 0, 0, 0),
            sked_Start_Date__c = System.today()+5,
            sked_End_Date__c = System.today()+5,
            sked__End__c = Datetime.newInstance(2022, 7, 27, 0, 0, 0),
            sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_Drive__c = skdDrive.Id,
            sked_Region__c = skdRegion.Id,
            sked_Is_Group_Activity__c = TRUE
        );
        insert activity;
        
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = activity.Id,
            sked__Resource__c = skdResEquipment.Id
        );
        insert skedActivityResource;    
        
       /* sked__Job_Allocation__c testResource1_job2 = new sked__Job_Allocation__c(
            sked__Job__c = skdJob.Id,
            sked__Resource__c = skdResEquipment.Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job2;*/
        
        sked__Activity__c activity2 = new sked__Activity__c(
            sked__Resource__c = skdResEquipment.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = Datetime.newInstance(2022, 7, 27, 0, 0, 0),
            sked_Start_Date__c = System.today()+5,
            sked_End_Date__c = System.today()+5,
            sked__End__c = Datetime.newInstance(2022, 7, 27, 0, 0, 0),
            sked_Collection_Operation__c = testCollectionOperation2.Id,
            sked_Drive__c = skdDrive.Id,
            sked_Region__c = skdRegion.Id,
            sked_Is_Group_Activity__c = TRUE
        );
        insert activity2;
        
        sked__Activity_Resource__c skedActivityResource2 = new sked__Activity_Resource__c(
            sked__Activity__c = activity.Id,
            sked__Resource__c = skdResEquipment.Id
        );
        insert skedActivityResource2; 
        
        sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
            sked__Job__c = skdJob.Id,
            sked__Tag__c = skdTag.Id
        );
        insert skedJobTag;
        
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrixList = new List<sked_Staffing_Decision_Matrix__c>();
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 1200,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 36,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get('Mobile').getRecordTypeId(),
            sked_VP_HH_Capacity__c = 2.2);
        staffingDecisionMatrixList.add(staffingDecisionMatrix);
        insert staffingDecisionMatrixList;
        
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMList = new List< sked_Collection_Operation_SDM__c>();
        sked_Collection_Operation_SDM__c collectionOperationSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collOpr.Id,
            sked_Effective_End_Date__c = System.today()+7, 
            sked_Effective_Start_Date__c = System.today()+4, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id,
            sked_MigrationID__c = '53243'
        );
        collectionOperationSDMList.add(collectionOperationSdm);
        insert collectionOperationSDMList; 
        
       Set<Id> drive = new Set<ID>{skdDrive.Id};
        DriveResourceAllocationBatch batch = new DriveResourceAllocationBatch(drive);
        Database.executeBatch(batch);
      //  DriveResourceAllocationBatch.staffingDecisionMatrix(collOpr.Id,skdDrive);
        Test.stopTest();        
    }
    
    static testmethod void testCalculateMethods()
    {
        
        test.startTest();  
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        Map<string, List<string>> mapResourceTypeCategories =
            skedPicklistFieldUtils.getMapDependentOptions(sked__Resource__c.sked__Resource_Type__c, sked__Resource__c.sked__Category__c);
        List<string> resourceCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_PERSON);
        List<string> assetCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_ASSET);
        List<string> resourceEmploymentTypes = skedUtils.getPickListValues('sked__Resource__c', 'sked__Employment_Type__c');
        
        List<sked__Resource__c> skdResEquipment = [select id,sked__Primary_Region__r.sked__Timezone__c from sked__Resource__c where sked_Asset_Type__c= 'Equipment' limit 1];
        sked__Job__c  skdJobVehicle = [SELECT Id,sked_Drive__c,sked__Job_Status__c,sked__Type__c,sked_Asset_Type__c FROM sked__Job__c  WHERE sked__Job_Status__c=: JOB_STATUS_PENDING_ALLOCATION And sked_Asset_Type__c = 'Vehicle' limit 1];
        sked__Tag__c skdTag = [SELECT Id FROM sked__Tag__c Where sked__Type__c = 'Physical Location Type' limit 1];
        Biomed_Collection_Op_Center__c collOpr = [SELECT Id, sked_Breakdown_Time_Threshold__c, sked_High_Drive_Productivity_Threshold__c,
                                                  sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Duration_Fixed_Site__c, sked_Lunch_Break_Duration_Mobile__c, 
                                                  sked_Maximum_Drive_End_Time__c, sked_Maximum_Shift_Length_Threshold__c, sked_Mid_Drive_Productivity_Threshold__c, 
                                                  sked_Minimum_Drive_Start_Time__c, sked_Setup_Time_Threshold__c, sked_Skip_Last_Appointment_For__c, sked_Unpaid_Lunch_Break_Duration__c
                                                  FROM Biomed_Collection_Op_Center__c limit 1];
        
        sked__Region__c skdRegion = [SELECT Id, sked__Timezone__c FROM sked__Region__c limit 1];
        
        sked__Location__c skdLocation = [SELECT Id, Name, sked_Collection_Operation__c, sked_Date_Site_Inspection_Completed__c, sked_Fixed_Site_Appointment_Pattern__c,
                                         sked_Physical_Location_Type__c, sked_Travel_Time_to_Staging_Location__c, sked_Timezone__c,
                                         sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c FROM sked__Location__c  limit 1];
        
        List<sked__Job__c> skdJobList = new List<sked__Job__c>();
        
        sked_Drive__c skdDrive = [SELECT Id, Name,sked_Status__c, sked_2RBC_Projected_Procedures__c, sked_Total_Products_Projected__c,
                                  sked_Drive_Site__c,sked_Collection_Operation__c,sked_End_Time__c, sked_Account__c,sked_Timezone__c,sked_Start_Time__c,
                                  sked_Projected_Registered_Donors__c,sked_Drive_Date__c,sked_Opportunity__c,sked_Type_of_Drive__c,sked_Maximum_Lunch_Break_Duration__c 
                                  from sked_Drive__c limit 1]; 
               
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = skdRegion.Id,
            sked__Duration__c = 500,
            sked_Drive__c = skdDrive.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 10,
            sked__Type__c = Constants.JOB_TYPE_DRIVER_SUPPORT,
            sked_APT_Quantity__c = 10
        );
        skdJobList.add(job1);   
        
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = skdRegion.Id,
            sked__Duration__c = 500,
            sked_Drive__c = skdDrive.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 10,
            sked__Type__c = 'Driver',
            sked_APT_Quantity__c = 10,
            sked_Resource_Role__c = Constants.PROCEDURE_TYPE_2RBC
        );
        skdJobList.add(job2);   
        
        sked__Job__c job3 = new sked__Job__c(
            sked__Region__c = skdRegion.Id,
            sked__Duration__c = 500,
            sked_Drive__c = skdDrive.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 30,
            sked__Type__c = Constants.JOB_TYPE_CHARGE,
            sked_APT_Quantity__c = 10
        );
        skdJobList.add(job3); 
        
        sked__Job__c job4 = new sked__Job__c(
            sked__Region__c = skdRegion.Id,
            sked__Duration__c = 500,
            sked_Drive__c = skdDrive.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 10,
            sked__Type__c = Constants.JOB_TYPE_VP_HH,
            sked_APT_Quantity__c = 10
        );
        skdJobList.add(job4);
        insert skdJobList;
        
        sked_Drive_Shift__c skdDriveShift = new sked_Drive_Shift__c(            
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = skdDrive.Id,
            sked_Drive_Date__c = System.today()+5,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Shadow_Drive_Shift__c = NULL,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_UFID__c = '123456',
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1,
            sked_2RBC_Projected_Procedures__c = 2
        );
        insert skdDriveShift;
        
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrixList = new List<sked_Staffing_Decision_Matrix__c>();
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 36,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 36,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get('Mobile').getRecordTypeId(),
            sked_VP_HH_Capacity__c = 2.2);
        staffingDecisionMatrixList.add(staffingDecisionMatrix);
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 1200,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 36,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get('Mobile').getRecordTypeId(),
            sked_VP_HH_Capacity__c = 2.2);
        staffingDecisionMatrixList.add(staffingDecisionMatrix2);
        
        insert staffingDecisionMatrixList;
        
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMList = new List< sked_Collection_Operation_SDM__c>();
        sked_Collection_Operation_SDM__c collectionOperationSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collOpr.Id,
            sked_Effective_End_Date__c = System.today()+7, 
            sked_Effective_Start_Date__c = System.today()+4, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id,
            sked_MigrationID__c = '53243'
        );
        collectionOperationSDMList.add(collectionOperationSdm);
        
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collOpr.Id,
            sked_Effective_End_Date__c = System.today()+7, 
            sked_Effective_Start_Date__c = System.today()+4, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id,
            sked_MigrationID__c = '53243'
        );
        collectionOperationSDMList.add(collectionOperationSdm2);
        
        insert collectionOperationSDMList; 
        DriveResourceAllocationBatch.filterResourceAvailability(skdResEquipment,skdDrive);
        DriveResourceAllocationBatch.driveStaffingComplementModel  test1 = new DriveResourceAllocationBatch.driveStaffingComplementModel();
        List<sked_Lunch_Break_Setting__c> lunchBreakSettings = [SELECT Id, Name, sked_Maximum_Lunch_Break_Duration__c,
                (SELECT Id, Name, sked_Lunch_Break_Duration__c,
                 sked_Lunch_Break_Setting__c, sked_Max_Number_of_Staff__c,
                 sked_Min_Number_of_Staff__c, sked_Slot_Reduction__c
                 FROM sked_Lunch_Break_Definitions__r)
                FROM sked_Lunch_Break_Setting__c];
            sked_Lunch_Break_Setting__c lunchBreakSetting = new sked_Lunch_Break_Setting__c();
            decimal coMaxLunchBreakDuration = skdDrive.sked_Maximum_Lunch_Break_Duration__c != NULL ? Decimal.valueOf(skdDrive.sked_Maximum_Lunch_Break_Duration__c) : 30;
            for (sked_Lunch_Break_Setting__c setting : lunchBreakSettings) {
                Decimal maximumLunchBreakDuration = setting.sked_Maximum_Lunch_Break_Duration__c != NULL ? decimal.valueOf(setting.sked_Maximum_Lunch_Break_Duration__c) : 30;
                if (maximumLunchBreakDuration == coMaxLunchBreakDuration) {
                    lunchBreakSetting = setting;
                    break;
                }
            }
        DriveResourceAllocationBatch.reCalculateStaffingComplement(5,skdDrive,skdDriveShift,skdJobList,test1,1);
        DriveResourceAllocationBatch.calculateDriveProductivityPlanned(skdDriveShift,skdDrive,skdJobList);
        DriveResourceAllocationBatch.calculateChargeQuantity(skdDriveShift,skdDrive,test1,lunchBreakSetting,1);
        test.stopTest();   
    }
    
   static testmethod void testResourceTypeVehicle(){
        
        test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
       // skedHubBase.BypassInsertTriggers = true;
        Map<string, List<string>> mapResourceTypeCategories =
            skedPicklistFieldUtils.getMapDependentOptions(sked__Resource__c.sked__Resource_Type__c, sked__Resource__c.sked__Category__c);
        List<string> resourceCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_PERSON);
        List<string> assetCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_ASSET);
        List<string> resourceEmploymentTypes = skedUtils.getPickListValues('sked__Resource__c', 'sked__Employment_Type__c');
        
        List <sked__Resource__c> resList = new List<sked__Resource__c>();
        
        resList = [Select Id,Name,sked_Asset_Type__c,sked_DOT__c,sked_CDL__c ,sked_pres_donor_capacity__c From sked__Resource__c limit 2];
        sked__Tag__c skdTag = [SELECT Id,sked__Type__c FROM sked__Tag__c Where Name = 'Fixed Site' limit 1];
        sked__Tag__c skdTagInside = [SELECT Id,sked__Type__c FROM sked__Tag__c Where Name = 'Inside' limit 1];
        Biomed_Collection_Op_Center__c collOpr = [SELECT Id, sked_Breakdown_Time_Threshold__c, sked_High_Drive_Productivity_Threshold__c,
                                                  sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Duration_Fixed_Site__c, sked_Lunch_Break_Duration_Mobile__c, 
                                                  sked_Maximum_Drive_End_Time__c, sked_Maximum_Shift_Length_Threshold__c, sked_Mid_Drive_Productivity_Threshold__c, 
                                                  sked_Minimum_Drive_Start_Time__c, sked_Setup_Time_Threshold__c, sked_Skip_Last_Appointment_For__c, sked_Unpaid_Lunch_Break_Duration__c
                                                  FROM Biomed_Collection_Op_Center__c limit 1];
        
        sked__Region__c skdRegion = [SELECT Id, sked__Timezone__c FROM sked__Region__c limit 1];
        sked__Location__c skdLocation = [SELECT Id, Name, sked_Collection_Operation__c, sked_Date_Site_Inspection_Completed__c, sked_Fixed_Site_Appointment_Pattern__c,
                                         sked_Physical_Location_Type__c, sked_Travel_Time_to_Staging_Location__c, sked_Timezone__c,
                                         sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c FROM sked__Location__c  limit 1];
        sked__Resource__c vehResource = [Select Id,Name,sked_Asset_Type__c,sked_DOT__c From sked__Resource__c Where sked_Asset_Type__c = 'Vehicle' LIMIT 1];
        sked__Resource__c eqResource = [Select Id,Name,sked_Asset_Type__c,sked_DOT__c From sked__Resource__c Where sked_Asset_Type__c = 'Equipment' LIMIT 1];
        sked__Job__c  skdJobEquipment = [SELECT Id,sked_Drive__c,sked__Job_Status__c,sked__Type__c,sked_Asset_Type__c FROM sked__Job__c  WHERE sked__Job_Status__c=: JOB_STATUS_PENDING_ALLOCATION And sked_Asset_Type__c = 'Equipment' limit 1];
        sked__Resource_Override__c vehOverride = [Select sked__Resource__c From sked__Resource_Override__c Where sked__Resource__c =: vehResource.Id limit 1]; 
        sked__Resource_Override__c eqOverride = [Select sked__Resource__c From sked__Resource_Override__c Where sked__Resource__c =:eqResource.Id limit 1];
        
        sked_Drive__c skdDrive = [SELECT Id, Name,sked_Status__c, sked_2RBC_Projected_Procedures__c, sked_Total_Products_Projected__c,
                                  sked_Drive_Site__c,sked_Drive_Site__r.sked_Physical_Location_Type__c,sked_Collection_Operation__c,sked_End_Time__c, sked_Account__c,sked_Timezone__c,sked_Start_Time__c,
                                  sked_Projected_Registered_Donors__c,sked_Drive_Date__c,sked_Opportunity__c,sked_Type_of_Drive__c ,sked_Maximum_Lunch_Break_Duration__c
                                  from sked_Drive__c LIMIT 1];
      sked__Job__c  skdJobVehicle = [SELECT Id,sked_Drive__c,sked__Job_Status__c,sked__Type__c,sked_Asset_Type__c FROM sked__Job__c  WHERE sked__Job_Status__c=: JOB_STATUS_PENDING_ALLOCATION And sked_Asset_Type__c = 'Vehicle'  AND sked_Drive__c =: skdDrive.id limit 1];

       
  
        sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
            sked__Job__c = skdJobVehicle.Id,
            sked__Tag__c = skdTagInside.Id
        );
        insert skedJobTag;
        
            sked__Job_Tag__c skedJobTag2 = new sked__Job_Tag__c(
            sked__Job__c = skdJobEquipment.Id,
            sked__Tag__c = skdTag.Id
        );
        insert skedJobTag2;
       
       sked__Resource_Tag__c testResource1_testTag1 = new sked__Resource_Tag__c(
            sked__Resource__c = vehResource.Id,
            sked__Tag__c = skdTagInside.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        insert testResource1_testTag1;
        sked__Resource_Tag__c testResource1_testTag2 = new sked__Resource_Tag__c(
            sked__Resource__c = eqResource.Id,
            sked__Tag__c = skdTag.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        insert testResource1_testTag2;
        
        sked__Job_Allocation__c testResource1_job2 = new sked__Job_Allocation__c(
            sked__Job__c = skdJobVehicle.Id,
            sked__Resource__c = resList[0].Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job2;
       sked__Job_Allocation__c testResource1_job3 = new sked__Job_Allocation__c(
            sked__Job__c = skdJobEquipment.Id,
            sked__Resource__c = resList[1].Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job3;
        
            sked_Resource_Biomed_Collection_Op__c skdBioCollection = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c =eqResource.Id,
            sked_Biomed_Collection_Op_Center__c = collOpr.Id,
            sked_Start_Date__c = system.today()+5,
            sked_End_Date__c = system.today()+10
        );
        insert skdBioCollection; 
        
        //For filter resource availability - false flag
        
        Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Maximum_Lunch_Break_Duration__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation2;
        
        sked__Resource__c newResource = new sked__Resource__c(
            Name = 'Test Resource1',
            sked__Primary_Region__c = skdRegion.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '001',
            sked_Title__c = 'Mr',
            sked_DOT__c = true,
            sked_First_Name__c = 'Steve',
            sked_Last_Name__c = 'King',
            sked_Asset_Type__c = 'Vehicle',
            sked_ULID__c = '248cwf0jgj3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_MigrationID__c = '25',
            sked_Mobile_Type__c = 'Inside',
            OwnerId = UserInfo.getUserId()
        );
        insert newResource;
       
       sked__Account_Resource_Score__c accountResScore = new sked__Account_Resource_Score__c();
        accountResScore.sked__Resource__c = newResource.Id;
        accountResScore.sked__Account__c = skdDrive.sked_Account__c;
        accountResScore.sked__Blacklisted__c = false;
        accountResScore.sked_Account_Resource_Relationship__c = 'Preferred';
        insert accountResScore;
       
        sked__Location_Resource_Score__c locationResourceScore2 = new sked__Location_Resource_Score__c(
            sked__Location__c = skdDrive.sked_Drive_Site__c,
            sked__Resource__c = newResource.Id,
            sked__Blacklisted__c = false,
            sked_Location_Resource_Relationship__c = LOCATION_RESOURCE_SCORE_DECLINED
        );
        insert locationResourceScore2;
       
        sked__Resource_Override__c sOverride = new sked__Resource_Override__c(
            sked_Collection_Operation__c= skdDrive.sked_Collection_Operation__c,
            sked__Resource__c = newResource.Id,
            sked_Start_Date__c = system.today()+5,
            sked__Start__c = Datetime.newInstance(2022, 7, 12, 12, 0, 0),
            sked_End_Date__c = system.today()+5,
            sked__End__c = Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(20, 0, 0, 0),
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked_Timezone__c = 'America/Los_Angeles',
            sked_Travel_Back_Start__c = Datetime.newInstance(2022, 7, 21, 12, 0, 0) ,  
            sked_Travel_Back_Start_Date__c = Date.newInstance(2022,7,21),
            sked_Travel_Back_Start_Time__c = Time.newInstance(12, 45, 0, 0)  ,
            sked_Travel_Back_End__c =Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_Travel_Back_End_Date__c = Date.newInstance(2022, 7,30 ),
            sked_Travel_Back_End_Time__c = Time.newInstance(12, 15, 0, 0),
            sked_Travel_To_End__c = Datetime.newInstance(2022, 7, 31, 12, 0, 0),
            sked_Travel_To_End_Date__c = Date.newInstance(2022, 7, 30),
            sked_Travel_To_End_Time__c = Time.newInstance(12, 45, 0, 0),
            sked_Travel_To_Start__c = Datetime.newInstance(2022, 7, 27, 12, 0, 0),
            sked_Travel_To_Start_Date__c = Date.newInstance(2022, 7, 21),
            sked_Travel_To_Start_Time__c = Time.newInstance(12, 45, 0, 0) 
        );
        insert sOverride;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = skdJobEquipment.Id,
            sked__Resource__c = eqResource.Id,
            sked__Status__c = JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job1;
        
        sked__Availability__c availability1 = new sked__Availability__c(
            sked__Resource__c = eqResource.Id,
            sked__Is_Available__c = True,
            sked__Status__c = 'Approved',
            sked__Start__c = Datetime.newInstance(2022, 12, 1, 12, 30, 2),
            sked__Finish__c = Datetime.newInstance(2022, 12, 18, 12, 30, 2),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c = System.today()+4,
            sked_Finish_Date__c = System.today()+6,
            sked__Type__c = AVAILABILITY_TYPE_PTO
        );
        insert availability1;  
        
        sked__Availability__c availability2 = new sked__Availability__c(
            sked__Resource__c = eqResource.Id,
            sked__Is_Available__c = True,
            sked__Status__c = 'Pending',
            sked__Start__c = Datetime.newInstance(2022, 12, 1, 12, 30, 2),
            sked__Finish__c = Datetime.newInstance(2022, 12, 18, 12, 30, 2),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c = System.today()+4,
            sked_Finish_Date__c = System.today()+6,
            sked__Type__c = AVAILABILITY_TYPE_PTO
        );
        insert availability2;       
        
       //For calculateChargeQuantity method
        sked_Drive_Shift__c skdDriveShift = new sked_Drive_Shift__c(            
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = skdDrive.Id,
            sked_Drive_Date__c = System.today()+5,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Shadow_Drive_Shift__c = NULL,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_UFID__c = '123456',
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert skdDriveShift;
        
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrixList = new List<sked_Staffing_Decision_Matrix__c>();
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 14.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 1200,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 20.2,
            sked_Team_Supervisor_Threshold__c = 36,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get('Mobile').getRecordTypeId(),
            sked_VP_HH_Capacity__c = 2.2);
        staffingDecisionMatrixList.add(staffingDecisionMatrix2);
        
        insert staffingDecisionMatrixList;
        
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMList = new List< sked_Collection_Operation_SDM__c>();
        
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collOpr.Id,
            sked_Effective_End_Date__c = System.today()+7, 
            sked_Effective_Start_Date__c = System.today()+4, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id,
            sked_MigrationID__c = '53243'
        );
       collectionOperationSDMList.add(collectionOperationSdm2);
       
       insert collectionOperationSDMList;
       
       
      Set<Id> drive = new Set<ID>{skdDrive.Id};
       
       DriveResourceAllocationBatch batch = new DriveResourceAllocationBatch(drive);
       Database.executeBatch(batch);
       batch.filterTags(resList, skdDrive);
       List<sked_Lunch_Break_Setting__c> lunchBreakSettings = [SELECT Id, Name, sked_Maximum_Lunch_Break_Duration__c,
       (SELECT Id, Name, sked_Lunch_Break_Duration__c,
       sked_Lunch_Break_Setting__c, sked_Max_Number_of_Staff__c,
       sked_Min_Number_of_Staff__c, sked_Slot_Reduction__c
       FROM sked_Lunch_Break_Definitions__r)
       FROM sked_Lunch_Break_Setting__c];
       sked_Lunch_Break_Setting__c lunchBreakSetting = new sked_Lunch_Break_Setting__c();
       decimal coMaxLunchBreakDuration = skdDrive.sked_Maximum_Lunch_Break_Duration__c != NULL ? Decimal.valueOf(skdDrive.sked_Maximum_Lunch_Break_Duration__c) : 30;
       for (sked_Lunch_Break_Setting__c setting : lunchBreakSettings) {
           Decimal maximumLunchBreakDuration = setting.sked_Maximum_Lunch_Break_Duration__c != NULL ? decimal.valueOf(setting.sked_Maximum_Lunch_Break_Duration__c) : 30;
                if (maximumLunchBreakDuration == coMaxLunchBreakDuration) {
                    lunchBreakSetting = setting;
                    break;
                }
            }
       
       DriveResourceAllocationBatch.driveStaffingComplementModel test1 = new DriveResourceAllocationBatch.driveStaffingComplementModel();
       test1.numberOfDrivers = 1;
       test1.numberOfDriverSupports=1;
       test1.numberOf2rbc = 1;
       test1.numberOfVphh = 1;
       DriveResourceAllocationBatch.calculateChargeQuantity(skdDriveShift,skdDrive,test1,lunchBreakSetting,1);
       Test.stopTest();  
   } 
    static testmethod void testResourceTypeVehicle2(){
        
        test.startTest();
         skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        //skedHubBase.BypassInsertTriggers = true;
        Map<string, List<string>> mapResourceTypeCategories =
            skedPicklistFieldUtils.getMapDependentOptions(sked__Resource__c.sked__Resource_Type__c, sked__Resource__c.sked__Category__c);
        List<string> resourceCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_PERSON);
        List<string> assetCategories = mapResourceTypeCategories.get(RESOURCE_TYPE_ASSET);
        List<string> resourceEmploymentTypes = skedUtils.getPickListValues('sked__Resource__c', 'sked__Employment_Type__c');
        
        List <sked__Resource__c> resList = new List<sked__Resource__c>();
        
        resList = [Select Id,Name,sked_Asset_Type__c,sked_DOT__c,sked_CDL__c ,sked_pres_donor_capacity__c From sked__Resource__c limit 2];
        sked__Tag__c skdTag = [SELECT Id,sked__Type__c FROM sked__Tag__c Where Name = 'Fixed Site' limit 1];
        sked__Tag__c skdTagInside = [SELECT Id,sked__Type__c FROM sked__Tag__c Where Name = 'Inside' limit 1];
        Biomed_Collection_Op_Center__c collOpr = [SELECT Id, sked_Breakdown_Time_Threshold__c, sked_High_Drive_Productivity_Threshold__c,
                                                  sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Duration_Fixed_Site__c, sked_Lunch_Break_Duration_Mobile__c, 
                                                  sked_Maximum_Drive_End_Time__c, sked_Maximum_Shift_Length_Threshold__c, sked_Mid_Drive_Productivity_Threshold__c, 
                                                  sked_Minimum_Drive_Start_Time__c, sked_Setup_Time_Threshold__c, sked_Skip_Last_Appointment_For__c, sked_Unpaid_Lunch_Break_Duration__c
                                                  FROM Biomed_Collection_Op_Center__c limit 1];
        
        sked__Region__c skdRegion = [SELECT Id, sked__Timezone__c FROM sked__Region__c limit 1];
        sked__Location__c skdLocation = [SELECT Id, Name, sked_Collection_Operation__c, sked_Date_Site_Inspection_Completed__c, sked_Fixed_Site_Appointment_Pattern__c,
                                         sked_Physical_Location_Type__c, sked_Travel_Time_to_Staging_Location__c, sked_Timezone__c,
                                         sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c FROM sked__Location__c  limit 1];
        sked__Resource__c vehResource = [Select Id,Name,sked_Asset_Type__c,sked_DOT__c From sked__Resource__c Where sked_Asset_Type__c = 'Vehicle' LIMIT 1];
        sked__Resource__c eqResource = [Select Id,Name,sked_Asset_Type__c,sked_DOT__c From sked__Resource__c Where sked_Asset_Type__c = 'Equipment' LIMIT 1];
        sked__Job__c  skdJobEquipment = [SELECT Id,sked_Drive__c,sked__Job_Status__c,sked__Type__c,sked_Asset_Type__c FROM sked__Job__c  WHERE sked__Job_Status__c=: JOB_STATUS_PENDING_ALLOCATION And sked_Asset_Type__c = 'Equipment' limit 1];
        sked__Resource_Override__c vehOverride = [Select sked__Resource__c From sked__Resource_Override__c Where sked__Resource__c =: vehResource.Id limit 1]; 
        sked__Resource_Override__c eqOverride = [Select sked__Resource__c From sked__Resource_Override__c Where sked__Resource__c =:eqResource.Id limit 1];
        
        sked_Drive__c skdDrive = [SELECT Id, Name,sked_Status__c, sked_2RBC_Projected_Procedures__c, sked_Total_Products_Projected__c,
                                  sked_Drive_Site__c,sked_Drive_Site__r.sked_Physical_Location_Type__c,sked_Collection_Operation__c,sked_End_Time__c, sked_Account__c,sked_Timezone__c,sked_Start_Time__c,
                                  sked_Projected_Registered_Donors__c,sked_Drive_Date__c,sked_Opportunity__c,sked_Type_of_Drive__c,sked_Maximum_Lunch_Break_Duration__c 
                                  from sked_Drive__c   LIMIT 1];
      sked__Job__c  skdJobVehicle = [SELECT Id,sked_Drive__c,sked__Job_Status__c,sked__Type__c,sked_Asset_Type__c FROM sked__Job__c  WHERE sked__Job_Status__c=: JOB_STATUS_PENDING_ALLOCATION And sked_Asset_Type__c = 'Vehicle'  AND sked_Drive__c =: skdDrive.id limit 1];

       
  
        sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
            sked__Job__c = skdJobVehicle.Id,
            sked__Tag__c = skdTagInside.Id
        );
        insert skedJobTag;
        
            sked__Job_Tag__c skedJobTag2 = new sked__Job_Tag__c(
            sked__Job__c = skdJobEquipment.Id,
            sked__Tag__c = skdTag.Id
        );
        insert skedJobTag2;
       
       sked__Resource_Tag__c testResource1_testTag1 = new sked__Resource_Tag__c(
            sked__Resource__c = vehResource.Id,
            sked__Tag__c = skdTagInside.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        insert testResource1_testTag1;
        sked__Resource_Tag__c testResource1_testTag2 = new sked__Resource_Tag__c(
            sked__Resource__c = eqResource.Id,
            sked__Tag__c = skdTag.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        insert testResource1_testTag2;
        
        sked__Job_Allocation__c testResource1_job2 = new sked__Job_Allocation__c(
            sked__Job__c = skdJobVehicle.Id,
            sked__Resource__c = resList[0].Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job2;
       sked__Job_Allocation__c testResource1_job3 = new sked__Job_Allocation__c(
            sked__Job__c = skdJobEquipment.Id,
            sked__Resource__c = resList[1].Id,
            sked__Status__c = 'Deleted',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job3;
        
            sked_Resource_Biomed_Collection_Op__c skdBioCollection = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c =eqResource.Id,
            sked_Biomed_Collection_Op_Center__c = collOpr.Id,
            sked_Start_Date__c = system.today()+5,
            sked_End_Date__c = system.today()+10
        );
        insert skdBioCollection; 
        
        //For filter resource availability - false flag
        
        Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Maximum_Lunch_Break_Duration__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation2;
        
        sked__Resource__c newResource = new sked__Resource__c(
            Name = 'Test Resource1',
            sked__Primary_Region__c = skdRegion.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '001',
            sked_Title__c = 'Mr',
            sked_DOT__c = true,
            sked_First_Name__c = 'Steve',
            sked_Last_Name__c = 'King',
            sked_Asset_Type__c = 'Vehicle',
            sked_ULID__c = '248cwf0jgj3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_MigrationID__c = '25',
            sked_Mobile_Type__c = 'Inside',
            OwnerId = UserInfo.getUserId()
        );
        insert newResource;
       
       sked__Account_Resource_Score__c accountResScore = new sked__Account_Resource_Score__c();
        accountResScore.sked__Resource__c = newResource.Id;
        accountResScore.sked__Account__c = skdDrive.sked_Account__c;
        accountResScore.sked__Blacklisted__c = false;
        accountResScore.sked_Account_Resource_Relationship__c = 'Preferred';
        insert accountResScore;
       
        sked__Location_Resource_Score__c locationResourceScore2 = new sked__Location_Resource_Score__c(
            sked__Location__c = skdDrive.sked_Drive_Site__c,
            sked__Resource__c = newResource.Id,
            sked__Blacklisted__c = false,
            sked_Location_Resource_Relationship__c = LOCATION_RESOURCE_SCORE_DECLINED
        );
        insert locationResourceScore2;
       
        sked__Resource_Override__c sOverride = new sked__Resource_Override__c(
            sked_Collection_Operation__c= skdDrive.sked_Collection_Operation__c,
            sked__Resource__c = newResource.Id,
            sked_Start_Date__c = system.today()+5,
            sked__Start__c = Datetime.newInstance(2022, 7, 12, 12, 0, 0),
            sked_End_Date__c = system.today()+5,
            sked__End__c = Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0),
            sked_Start_Time__c = Time.newInstance(20, 0, 0, 0),
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked_Timezone__c = 'America/Los_Angeles',
            sked_Travel_Back_Start__c = Datetime.newInstance(2022, 7, 21, 12, 0, 0) ,  
            sked_Travel_Back_Start_Date__c = Date.newInstance(2022,7,21),
            sked_Travel_Back_Start_Time__c = Time.newInstance(12, 45, 0, 0)  ,
            sked_Travel_Back_End__c =Datetime.newInstance(2022, 7, 30, 12, 0, 0),
            sked_Travel_Back_End_Date__c = Date.newInstance(2022, 7,30 ),
            sked_Travel_Back_End_Time__c = Time.newInstance(12, 15, 0, 0),
            sked_Travel_To_End__c = Datetime.newInstance(2022, 7, 31, 12, 0, 0),
            sked_Travel_To_End_Date__c = Date.newInstance(2022, 7, 30),
            sked_Travel_To_End_Time__c = Time.newInstance(12, 45, 0, 0),
            sked_Travel_To_Start__c = Datetime.newInstance(2022, 7, 27, 12, 0, 0),
            sked_Travel_To_Start_Date__c = Date.newInstance(2022, 7, 21),
            sked_Travel_To_Start_Time__c = Time.newInstance(12, 45, 0, 0) 
        );
        insert sOverride;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = skdJobEquipment.Id,
            sked__Resource__c = eqResource.Id,
            sked__Status__c = JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job1;
        
        sked__Availability__c availability1 = new sked__Availability__c(
            sked__Resource__c = eqResource.Id,
            sked__Is_Available__c = True,
            sked__Status__c = 'Approved',
            sked__Start__c = Datetime.newInstance(2022, 12, 1, 12, 30, 2),
            sked__Finish__c = Datetime.newInstance(2022, 12, 18, 12, 30, 2),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c = System.today()+4,
            sked_Finish_Date__c = System.today()+6,
            sked__Type__c = AVAILABILITY_TYPE_PTO
        );
        insert availability1;  
        
        sked__Availability__c availability2 = new sked__Availability__c(
            sked__Resource__c = eqResource.Id,
            sked__Is_Available__c = True,
            sked__Status__c = 'Pending',
            sked__Start__c = Datetime.newInstance(2022, 12, 1, 12, 30, 2),
            sked__Finish__c = Datetime.newInstance(2022, 12, 18, 12, 30, 2),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c = System.today()+4,
            sked_Finish_Date__c = System.today()+6,
            sked__Type__c = AVAILABILITY_TYPE_PTO
        );
        insert availability2;       
        
       //For calculateChargeQuantity method
        sked_Drive_Shift__c skdDriveShift = new sked_Drive_Shift__c(            
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = skdDrive.Id,
            sked_Drive_Date__c = System.today()+5,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Shadow_Drive_Shift__c = NULL,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_UFID__c = '123456',
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert skdDriveShift;
        
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrixList = new List<sked_Staffing_Decision_Matrix__c>();
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 14.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 1200,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 20.2,
            sked_Team_Supervisor_Threshold__c = 36,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get('Mobile').getRecordTypeId(),
            sked_VP_HH_Capacity__c = 2.2);
        staffingDecisionMatrixList.add(staffingDecisionMatrix2);
        
        insert staffingDecisionMatrixList;
        
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMList = new List< sked_Collection_Operation_SDM__c>();
        
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collOpr.Id,
            sked_Effective_End_Date__c = System.today()+7, 
            sked_Effective_Start_Date__c = System.today()+4, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id,
            sked_MigrationID__c = '53243'
        );
       collectionOperationSDMList.add(collectionOperationSdm2);
       
       insert collectionOperationSDMList;
       
       
      Set<Id> drive = new Set<ID>{skdDrive.Id};
       
       DriveResourceAllocationBatch batch = new DriveResourceAllocationBatch(drive);
       Database.executeBatch(batch);
       batch.remainingNoOfDOT = 2;
       batch.filterTags(resList, skdDrive);
       List<sked_Lunch_Break_Setting__c> lunchBreakSettings = [SELECT Id, Name, sked_Maximum_Lunch_Break_Duration__c,
       (SELECT Id, Name, sked_Lunch_Break_Duration__c,
        sked_Lunch_Break_Setting__c, sked_Max_Number_of_Staff__c,
        sked_Min_Number_of_Staff__c, sked_Slot_Reduction__c
        FROM sked_Lunch_Break_Definitions__r)
       FROM sked_Lunch_Break_Setting__c];
            sked_Lunch_Break_Setting__c lunchBreakSetting = new sked_Lunch_Break_Setting__c();
            decimal coMaxLunchBreakDuration = skdDrive.sked_Maximum_Lunch_Break_Duration__c != NULL ? Decimal.valueOf(skdDrive.sked_Maximum_Lunch_Break_Duration__c) : 30;
            for (sked_Lunch_Break_Setting__c setting : lunchBreakSettings) {
                Decimal maximumLunchBreakDuration = setting.sked_Maximum_Lunch_Break_Duration__c != NULL ? decimal.valueOf(setting.sked_Maximum_Lunch_Break_Duration__c) : 30;
                if (maximumLunchBreakDuration == coMaxLunchBreakDuration) {
                    lunchBreakSetting = setting;
                    break;
                }
            }
       
       DriveResourceAllocationBatch.driveStaffingComplementModel test1 = new DriveResourceAllocationBatch.driveStaffingComplementModel();
       test1.numberOfDrivers = 1;
       test1.numberOfDriverSupports=1;
       test1.numberOf2rbc = 1;
       test1.numberOfVphh = 1;
       DriveResourceAllocationBatch.calculateChargeQuantity(skdDriveShift, skdDrive, test1, lunchBreakSetting, 1);
       Test.stopTest();  
   } 
  
    static testmethod void testJobAllocResource()
    {
      test.startTest();
         skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        sked_Drive__c skdDrive = [SELECT Id, Name,sked_Status__c, sked_2RBC_Projected_Procedures__c, sked_Total_Products_Projected__c,
                                  sked_Drive_Site__c,sked_Collection_Operation__c,sked_End_Time__c, sked_Account__c,sked_Timezone__c,sked_Start_Time__c,
                                  sked_Projected_Registered_Donors__c,sked_Drive_Date__c,sked_Opportunity__c,sked_Type_of_Drive__c 
                                  from sked_Drive__c limit 1];
        sked__Location__c skdLocation = [SELECT Id, Name, sked_Collection_Operation__c, sked_Date_Site_Inspection_Completed__c, sked_Fixed_Site_Appointment_Pattern__c,
                                         sked_Physical_Location_Type__c, sked_Travel_Time_to_Staging_Location__c, sked_Timezone__c,
                                         sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c FROM sked__Location__c  limit 1];
        sked__Region__c skdRegion = [SELECT Id, sked__Timezone__c FROM sked__Region__c limit 1];
         Biomed_Collection_Op_Center__c collOpr = [SELECT Id, sked_Breakdown_Time_Threshold__c, sked_High_Drive_Productivity_Threshold__c,
                                                  sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Duration_Fixed_Site__c, sked_Lunch_Break_Duration_Mobile__c, 
                                                  sked_Maximum_Drive_End_Time__c, sked_Maximum_Shift_Length_Threshold__c, sked_Mid_Drive_Productivity_Threshold__c, 
                                                  sked_Minimum_Drive_Start_Time__c, sked_Setup_Time_Threshold__c, sked_Skip_Last_Appointment_For__c, sked_Unpaid_Lunch_Break_Duration__c
                                                  FROM Biomed_Collection_Op_Center__c limit 1];
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrixList = new List<sked_Staffing_Decision_Matrix__c>();
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 14.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 1200,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 20.2,
            sked_Team_Supervisor_Threshold__c = 36,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get('Mobile').getRecordTypeId(),
            sked_VP_HH_Capacity__c = 2.2);
        staffingDecisionMatrixList.add(staffingDecisionMatrix2);
        
        insert staffingDecisionMatrixList;
        
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMList = new List< sked_Collection_Operation_SDM__c>();
        
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collOpr.Id,
            sked_Effective_End_Date__c = System.today()+7, 
            sked_Effective_Start_Date__c = System.today()+4, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id,
            sked_MigrationID__c = '53243'
        );
       collectionOperationSDMList.add(collectionOperationSdm2);
       
       insert collectionOperationSDMList;

        Account acc = [Select Id From Account Limit 1];
        Opportunity opp = [Select Id From Opportunity Limit 1];
        sked__Tag__c skdTagInside = [SELECT Id,sked__Type__c FROM sked__Tag__c Where Name = 'Inside' limit 1];
        sked__Tag__c skdTag = [SELECT Id,sked__Type__c FROM sked__Tag__c Where Name = 'Fixed Site' limit 1];
         sked__Tag__c newdriveTypeTagFixedSite = new sked__Tag__c(
            Name = 'Fixed Site 1',
            sked__Type__c = 'Physical Location Type'
        );
        insert newdriveTypeTagFixedSite;
        
        //  sked_Drive__c testDrive2 = new sked_Drive__c(
        //     Name = 'Test Drive 2',
        //     sked_Collection_Operation__c = skdDrive.sked_Collection_Operation__c,
        //     sked_Drive_Site__c = skdLocation.Id,
        //     sked_Opportunity__c = opp.Id,
        //     sked_Drive_Date__c = skdDrive.sked_Drive_Date__c,
        //     sked_Type_of_Drive__c = 'Mobile',
        //     sked_Account__c = acc.Id,
        //     sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
        //     sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
        //     sked_Drive_Productivity_Planned__c = 0.8,
        //     sked_Projected_Registered_Donors__c = 1000,
        //     sked_Status__c = 'System Generated',
        //     sked_2RBC_Projected_Procedures__c = 2,
        //     sked_Total_Products_Projected__c = 10           
        // );
        // insert testDrive2; 
        
         sked__Tag__c driveTypeTagInside2 = new sked__Tag__c(
            Name = 'Inside 1',
            sked__Type__c = 'Physical Location Type'
        );
        insert driveTypeTagInside2;
           
         sked__Resource__c testResource1 = new sked__Resource__c(
            Name = 'Resource2',
            sked__Primary_Region__c = skdRegion.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '005',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Nora',
            sked_Last_Name__c = 'Queen',
            sked_Asset_Type__c = 'Vehicle',
            sked_ULID__c = '248chfhjgj3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = skdLocation.Id,
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        insert testResource1;
        
        sked__Resource__c testResource2 = new sked__Resource__c(
            Name = 'Resource2',
            sked__Primary_Region__c = skdRegion.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '005',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Nora',
            sked_Last_Name__c = 'Queen',
            sked_Asset_Type__c = 'Equipment',
            sked_Equipment_Subtype__c = '2RBC Asset', // DriveResourceAllocationBatch
            sked_ULID__c = '248cwi5jg3D3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = skdLocation.Id,
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        insert testResource2;
        
         sked__Location_Resource_Score__c locationResourceScore2 = new sked__Location_Resource_Score__c(
            sked__Location__c = skdDrive.sked_Drive_Site__c,
            sked__Resource__c = testResource2.Id,
            sked__Blacklisted__c = false,
            sked_Location_Resource_Relationship__c = 'Preferred'
        );
        insert locationResourceScore2;
        
          sked_Resource_Biomed_Collection_Op__c skdBioCollection = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c = testResource2.Id,
            sked_Biomed_Collection_Op_Center__c = collOpr.Id,
            sked_Start_Date__c = system.today()+5,
            sked_End_Date__c = system.today()+10
        );
        insert skdBioCollection;
        
        sked_Drive_Shift__c skdDriveShift = new sked_Drive_Shift__c(            
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = skdDrive.Id,
            sked_Drive_Date__c = System.today()+5,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Shadow_Drive_Shift__c = NULL,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_UFID__c = '123456',
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1,
            sked_2RBC_Projected_Procedures__c = 2
        );
        insert skdDriveShift;                   
       
        Decimal duration = skedDateTimeUtils.getDifferentMinutes(system.today(), system.today()+10);
        sked__Job__c job1 = new sked__Job__c( 
            sked__Region__c = skdRegion.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = duration,
            sked__Quantity__c = 2,
            sked_Drive__c = skdDrive.Id,
            sked_Asset_Type__c = Constants.JOB_TYPE_VEHICLE,
            sked_Drive_Shift__c = skdDriveShift.Id,
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION
        );
        insert job1;
        
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = skdRegion.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = duration,
            sked_Drive__c = skdDrive.Id,
            sked_Asset_Type__c = 'Equipment',
            sked_Equipment_Subtype__c = '2RBC Asset', // DriveResourceAllocationBatch
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 2,
            sked__Type__c = Constants.JOB_TYPE_VP_HH,
            sked_APT_Quantity__c = 1
        );
        insert job2;   
        
        sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
            sked__Job__c = job1.Id,
            sked__Tag__c = skdTagInside.Id
        );
        insert skedJobTag;
        
            sked__Job_Tag__c skedJobTag2 = new sked__Job_Tag__c(
            sked__Job__c = job2.Id,
            sked__Tag__c = skdTag.Id
        );
        insert skedJobTag2;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = job1.Id,
            sked_DOT__c = true,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = '	Pending Dispatch',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job1;
        
        sked__Job_Allocation__c testResource1_job2 = new sked__Job_Allocation__c(
            sked__Job__c = job2.Id,
            sked_CDL__c = true,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = '	Pending Dispatch',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job2;
        sked__Resource_Tag__c testResource1_testTag1 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource1.Id,
            sked__Tag__c = newdriveTypeTagFixedSite.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        insert testResource1_testTag1;
        sked__Resource_Tag__c testResource1_testTag2 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource2.Id,
            sked__Tag__c = driveTypeTagInside2.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        insert testResource1_testTag2;
        
        Set<Id> drive = new Set<ID>{skdDrive.Id};
        
        DriveResourceAllocationBatch batch = new DriveResourceAllocationBatch(drive);
        Database.executeBatch(batch);
        Test.stopTest();   
   } 
    
    static testmethod void testJobAllocation(){
         test.startTest();
         skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        sked_Drive__c skdDrive = [SELECT Id, Name,sked_Status__c, sked_2RBC_Projected_Procedures__c, sked_Total_Products_Projected__c,
                                  sked_Drive_Site__c,sked_Collection_Operation__c,sked_End_Time__c, sked_Account__c,sked_Timezone__c,sked_Start_Time__c,
                                  sked_Projected_Registered_Donors__c,sked_Drive_Date__c,sked_Opportunity__c,sked_Type_of_Drive__c 
                                  from sked_Drive__c limit 1];
        sked__Location__c skdLocation = [SELECT Id, Name, sked_Collection_Operation__c, sked_Date_Site_Inspection_Completed__c, sked_Fixed_Site_Appointment_Pattern__c,
                                         sked_Physical_Location_Type__c, sked_Travel_Time_to_Staging_Location__c, sked_Timezone__c,
                                         sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c FROM sked__Location__c  limit 1];
        sked__Region__c skdRegion = [SELECT Id, sked__Timezone__c FROM sked__Region__c limit 1];
         Biomed_Collection_Op_Center__c collOpr = [SELECT Id, sked_Breakdown_Time_Threshold__c, sked_High_Drive_Productivity_Threshold__c,
                                                  sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Duration_Fixed_Site__c, sked_Lunch_Break_Duration_Mobile__c, 
                                                  sked_Maximum_Drive_End_Time__c, sked_Maximum_Shift_Length_Threshold__c, sked_Mid_Drive_Productivity_Threshold__c, 
                                                  sked_Minimum_Drive_Start_Time__c, sked_Setup_Time_Threshold__c, sked_Skip_Last_Appointment_For__c, sked_Unpaid_Lunch_Break_Duration__c
                                                  FROM Biomed_Collection_Op_Center__c limit 1];
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrixList = new List<sked_Staffing_Decision_Matrix__c>();
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix2 = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 14.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 1200,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 20.2,
            sked_Team_Supervisor_Threshold__c = 36,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get('Mobile').getRecordTypeId(),
            sked_VP_HH_Capacity__c = 2.2);
        staffingDecisionMatrixList.add(staffingDecisionMatrix2);
        
        insert staffingDecisionMatrixList;
        
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMList = new List< sked_Collection_Operation_SDM__c>();
        
        sked_Collection_Operation_SDM__c collectionOperationSdm2 = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collOpr.Id,
            sked_Effective_End_Date__c = System.today()+7, 
            sked_Effective_Start_Date__c = System.today()+4, 
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix2.Id,
            sked_MigrationID__c = '53243'
        );
       collectionOperationSDMList.add(collectionOperationSdm2);
       
       insert collectionOperationSDMList;
       Account acc = [Select Id From Account Limit 1];
        Opportunity opp = [Select Id From Opportunity Limit 1];
        sked__Tag__c skdTagInside = [SELECT Id,sked__Type__c FROM sked__Tag__c Where Name = 'Inside' limit 1];
         sked__Tag__c newdriveTypeTagFixedSite = new sked__Tag__c(
            Name = 'Fixed Site 1',
            sked__Type__c = 'Physical Location Type'
        );
        insert newdriveTypeTagFixedSite;
        
         sked__Tag__c driveTypeTagInside2 = new sked__Tag__c(
            Name = 'Inside 1',
            sked__Type__c = 'Physical Location Type'
        );
        insert driveTypeTagInside2;
           
         sked__Resource__c testResource1 = new sked__Resource__c(
            Name = 'Resource2',
            sked__Primary_Region__c = skdRegion.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '005',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Nora',
            sked_Last_Name__c = 'Queen',
            sked_Asset_Type__c = 'Vehicle',
            sked_ULID__c = '248chfhjgj3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = skdLocation.Id,
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        insert testResource1;
        
        sked__Resource__c testResource2 = new sked__Resource__c(
            Name = 'Resource2',
            sked__Primary_Region__c = skdRegion.Id,
            RecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId(),
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = Constants.PROCEDURE_TYPE_2RBC,
            sked_Employee_ID__c = '005',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Nora',
            sked_Last_Name__c = 'Queen',
            sked_Asset_Type__c = 'Equipment',
            sked_Equipment_Subtype__c = '2RBC Asset', // DriveResourceAllocationBatch
            sked_ULID__c = '248cwi5jg3D3',
            sked_Pres_Donor_Capacity__c = 50,
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_Dedicated_to_Site__c = skdLocation.Id,
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        insert testResource2;
        
         sked__Location_Resource_Score__c locationResourceScore2 = new sked__Location_Resource_Score__c(
            sked__Location__c = skdDrive.sked_Drive_Site__c,
            sked__Resource__c = testResource2.Id,
            sked__Blacklisted__c = false,
            sked_Location_Resource_Relationship__c = 'Preferred'
        );
        insert locationResourceScore2;
        
          sked_Resource_Biomed_Collection_Op__c skdBioCollection = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c = testResource2.Id,
            sked_Biomed_Collection_Op_Center__c = collOpr.Id,
            sked_Start_Date__c = system.today()+5,
            sked_End_Date__c = system.today()+10
        );
        insert skdBioCollection;
        
        sked_Drive_Shift__c skdDriveShift = new sked_Drive_Shift__c(            
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = skdDrive.Id,
            sked_Drive_Date__c = System.today()+5,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Shadow_Drive_Shift__c = NULL,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_UFID__c = '123456',
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1,
            sked_2RBC_Projected_Procedures__c = 2
        );
        insert skdDriveShift;                   
       
         Decimal duration = skedDateTimeUtils.getDifferentMinutes(system.today(), system.today()+10);
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = skdRegion.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = duration,
            sked__Quantity__c = 1,
            sked_Drive__c = skdDrive.Id,
            sked_Asset_Type__c = 'Vehicle',
            sked_Drive_Shift__c = skdDriveShift.Id,
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION
        );
        insert job1;
        
        sked__Job__c job2 = new sked__Job__c(
            sked__Region__c = skdRegion.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = duration,
            sked_Drive__c = skdDrive.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Job_Status__c = JOB_STATUS_PENDING_ALLOCATION,
            sked__Quantity__c = 1,
            sked__Type__c = Constants.JOB_TYPE_VP_HH,
            sked_APT_Quantity__c = 1
        );
        insert job2;   
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
            sked__Job__c = job1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Status__c = '	Pending Dispatch',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job1;
        
        sked__Job_Allocation__c testResource1_job2 = new sked__Job_Allocation__c(
            sked__Job__c = job2.Id,
            sked__Resource__c = testResource2.Id,
            sked__Status__c = '	Pending Dispatch',
            sked_Start_Date__c = system.today()+5,
            sked_Set_End_Date__c = system.today()+5
        );
        insert testResource1_job2;
        sked__Resource_Tag__c testResource1_testTag1 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource1.Id,
            sked__Tag__c = newdriveTypeTagFixedSite.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        insert testResource1_testTag1;
        sked__Resource_Tag__c testResource1_testTag2 = new sked__Resource_Tag__c(
            sked__Resource__c = testResource2.Id,
            sked__Tag__c = driveTypeTagInside2.Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = TAG_ROLE_STATUS_PENDING
        );
        insert testResource1_testTag2;
        
        Set<Id> drive = new Set<ID>{skdDrive.Id};
        
        DriveResourceAllocationBatch batch = new DriveResourceAllocationBatch(drive);
        Database.executeBatch(batch);
        Test.stopTest();  
    }
    
    static testmethod void testBatchMethod1()
    {
         skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        
      sked_Drive__c skdDrive = [SELECT Id, sked_Day_of_Week__c, Name,sked_Status__c, sked_2RBC_Projected_Procedures__c, sked_Total_Products_Projected__c,
                                  sked_Drive_Site__c,sked_Drive_Site__r.sked_Physical_Location_Type__c,sked_Collection_Operation__c,sked_End_Time__c, sked_Account__c,sked_Timezone__c,sked_Start_Time__c,
                                  sked_Projected_Registered_Donors__c,sked_Drive_Date__c,sked_Opportunity__c,sked_Type_of_Drive__c 
                                  from sked_Drive__c WHERE sked_Status__c = 'Draft' LIMIT 1];  
        system.debug('skdDrive:: '+skdDrive);
       
        List<sked_Operation_Drive_Limit__c> operationalLimit = new List<sked_Operation_Drive_Limit__c>();
        
        sked_Operation_Drive_Limit__c oppLimit = new sked_Operation_Drive_Limit__c();
        oppLimit.sked_Collection_Operation__c = skdDrive.sked_Collection_Operation__c;
        oppLimit.sked_Days_of_Week__c = skdDrive.sked_Day_of_Week__c;
        oppLimit.sked_Effective_Start_Date__c = skdDrive.sked_Drive_Date__c.addDays(-10);
        oppLimit.sked_Effective_End_Date__c = skdDrive.sked_Drive_Date__c.addDays(10);
        oppLimit.sked_Quantity__c = 2;
        oppLimit.sked_Type__c = 'CDL Limit';
        operationalLimit.add(oppLimit);

        oppLimit = new sked_Operation_Drive_Limit__c();
        oppLimit.sked_Collection_Operation__c = skdDrive.sked_Collection_Operation__c;
        oppLimit.sked_Days_of_Week__c = skdDrive.sked_Day_of_Week__c;
        oppLimit.sked_Effective_Start_Date__c = skdDrive.sked_Drive_Date__c.addDays(-10);
        oppLimit.sked_Effective_End_Date__c = skdDrive.sked_Drive_Date__c.addDays(10);
        oppLimit.sked_Quantity__c = 2;
        oppLimit.sked_Type__c = 'DOT Limit';
        operationalLimit.add(oppLimit);

        oppLimit = new sked_Operation_Drive_Limit__c();
        oppLimit.sked_Collection_Operation__c = skdDrive.sked_Collection_Operation__c;
        oppLimit.sked_Days_of_Week__c = skdDrive.sked_Day_of_Week__c;
        oppLimit.sked_Effective_Start_Date__c = skdDrive.sked_Drive_Date__c.addDays(-10);
        oppLimit.sked_Effective_End_Date__c = skdDrive.sked_Drive_Date__c.addDays(10);
        oppLimit.sked_Quantity__c = 2;
        oppLimit.sked_Type__c = '2RBC Limit';
        operationalLimit.add(oppLimit);

        insert operationalLimit;
        system.debug('sked_Collection_Operation__c value :: '+skdDrive.sked_Collection_Operation__c);
        system.debug('sked_Effective_Start_Date__c value :: '+skdDrive.sked_Drive_Date__c.addDays(-10));
        system.debug('sked_Day_of_Week__c:: '+skdDrive.sked_Day_of_Week__c);
        operationalLimit = [SELECT Id, Name, sked_Collection_Operation__c, sked_Days_of_Week__c, sked_Effective_End_Date__c, sked_Effective_Start_Date__c, sked_Quantity__c, sked_Type__c, sked_MigrationID__c FROM sked_Operation_Drive_Limit__c
                                                                   Where (sked_Type__c =: Constants.OPERATION_DRIVE_2RBC_LIMIT OR sked_Type__c =: Constants.OPERATION_DRIVE_DOT_LIMIT OR sked_Type__c =: Constants.OPERATION_DRIVE_CDL_LIMIT) AND sked_Collection_Operation__c =: skdDrive.sked_Collection_Operation__c];
                                                                   system.debug('operationalLimit:: '+operationalLimit);
                                                                   for(sked_Operation_Drive_Limit__c skedOppLimit : operationalLimit){
                                                                    system.debug('skedOppLimit:: '+skedOppLimit);
                                                                   }
        
       Set<Id> drive = new Set<ID>{skdDrive.Id};
       DriveResourceAllocationBatch batch = new DriveResourceAllocationBatch(drive);
       Database.executeBatch(batch);
    }

    static testmethod void testBatchMethod2()
    {
        Test.startTest();
         skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        sked_Drive__c skdDrive = [SELECT Id, sked_Day_of_Week__c, Name,sked_Status__c, sked_2RBC_Projected_Procedures__c, sked_Total_Products_Projected__c,
                                    sked_Drive_Site__c,sked_Drive_Site__r.sked_Physical_Location_Type__c,sked_Collection_Operation__c,sked_End_Time__c, sked_Account__c,sked_Timezone__c,sked_Start_Time__c,
                                    sked_Projected_Registered_Donors__c,sked_Drive_Date__c,sked_Opportunity__c,sked_Type_of_Drive__c 
                                    from sked_Drive__c WHERE sked_Status__c = 'Draft' LIMIT 1];  
          system.debug('skdDrive:: '+skdDrive);

          List<sked_Operation_Drive_Limit__c> operationalLimit = new List<sked_Operation_Drive_Limit__c>();
          
          sked_Operation_Drive_Limit__c oppLimit = new sked_Operation_Drive_Limit__c();
          oppLimit.sked_Collection_Operation__c = skdDrive.sked_Collection_Operation__c;
          oppLimit.sked_Days_of_Week__c = skdDrive.sked_Day_of_Week__c;
          oppLimit.sked_Effective_Start_Date__c = skdDrive.sked_Drive_Date__c.addDays(-10);
          oppLimit.sked_Effective_End_Date__c = skdDrive.sked_Drive_Date__c.addDays(10);
          oppLimit.sked_Quantity__c = null;
          oppLimit.sked_Type__c = 'CDL Limit';
          operationalLimit.add(oppLimit);
  
          oppLimit = new sked_Operation_Drive_Limit__c();
          oppLimit.sked_Collection_Operation__c = skdDrive.sked_Collection_Operation__c;
          oppLimit.sked_Days_of_Week__c = skdDrive.sked_Day_of_Week__c;
          oppLimit.sked_Effective_Start_Date__c = skdDrive.sked_Drive_Date__c.addDays(-10);
          oppLimit.sked_Effective_End_Date__c = skdDrive.sked_Drive_Date__c.addDays(10);
          oppLimit.sked_Quantity__c = null;
          oppLimit.sked_Type__c = 'DOT Limit';
          operationalLimit.add(oppLimit);
  
          oppLimit = new sked_Operation_Drive_Limit__c();
          oppLimit.sked_Collection_Operation__c = skdDrive.sked_Collection_Operation__c;
          oppLimit.sked_Days_of_Week__c = skdDrive.sked_Day_of_Week__c;
          oppLimit.sked_Effective_Start_Date__c = skdDrive.sked_Drive_Date__c.addDays(-10);
          oppLimit.sked_Effective_End_Date__c = skdDrive.sked_Drive_Date__c.addDays(10);
          oppLimit.sked_Quantity__c = null;
          oppLimit.sked_Type__c = '2RBC Limit';
          operationalLimit.add(oppLimit);
  
          insert operationalLimit;
          system.debug('sked_Collection_Operation__c value :: '+skdDrive.sked_Collection_Operation__c);
        system.debug('sked_Effective_Start_Date__c value :: '+skdDrive.sked_Drive_Date__c.addDays(-10));
        system.debug('sked_Day_of_Week__c:: '+skdDrive.sked_Day_of_Week__c);

          operationalLimit = [SELECT Id, Name, sked_Collection_Operation__c, sked_Days_of_Week__c, sked_Effective_End_Date__c, sked_Effective_Start_Date__c, sked_Quantity__c, sked_Type__c, sked_MigrationID__c FROM sked_Operation_Drive_Limit__c
                                                                   Where (sked_Type__c =: Constants.OPERATION_DRIVE_2RBC_LIMIT OR sked_Type__c =: Constants.OPERATION_DRIVE_DOT_LIMIT OR sked_Type__c =: Constants.OPERATION_DRIVE_CDL_LIMIT) AND sked_Collection_Operation__c =: skdDrive.sked_Collection_Operation__c];
                                                                   system.debug('operationalLimit:: '+operationalLimit);
                                                                   for(sked_Operation_Drive_Limit__c skedOppLimit : operationalLimit){
                                                                    system.debug('skedOppLimit:: '+skedOppLimit);
                                                                   }
          
         Set<Id> drive = new Set<ID>{skdDrive.Id};
         DriveResourceAllocationBatch batch = new DriveResourceAllocationBatch(drive);
         Database.executeBatch(batch);
        Test.stopTest();
      }
}