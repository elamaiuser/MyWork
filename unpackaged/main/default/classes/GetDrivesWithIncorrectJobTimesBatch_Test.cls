/* The following test class is covering the below apex class
 * GetDrivesWithIncorrectJobTimes
 * GetDrivesForDCRBatch
 * 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * *****************************************************************************************************************************
 * 4/19/2024                  Fitsum Worku            	Initial code creation
 * 
 * *****************************************************************************************************************************/
@isTest
public class GetDrivesWithIncorrectJobTimesBatch_Test {
    
    @isTest
    static void generateDriveTypeTag_FixedSite_WB_Test() {
      
        skedHubBase.setBypassAllTriggers(true);
        triggerHandler.bypass('TaskTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
		Triggerhandler.bypass('OpportunityTriggerhandler');
        triggerHandler.bypass('JobTriggerHandler');
		Triggerhandler.bypass('DriveTriggerService');
        
        /*Chapter for Site*/
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region'
        );
        insert testChapter;
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        sked__Location__c testLocation = new sked__Location__c(
            Name = 'Test Location 1',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId(),
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = System.Today(),
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 2,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 2',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Test Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4931',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET', 
            sked_City__c = 'Test City', 
            sked_County__c = 'Test', 
            sked_State__c = 'PA', 
            sked_Zip_Code__c = '18411', 
            Operation_Type__c = 'Non Integrated WB'
        );
        insert testLocation;
        
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 36.7450046,
            sked_Geolocation__Longitude__s = -121.4816244
        );
        insert testStagingLocation1;
        
        Account testAccount1 = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test Internal Name',
            APT_Required__c = FALSE,
            Type = skedConstants.ACCOUNT_TYPE_EDUCATION,
            Industry_Code__c = skedConstants.ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL
            //Contact_BPL__c = contactBPL.Id
        );
    	insert testAccount1;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = testAccount1.Id,
            Drive_Date__c = System.today().addDays(43),
            Drive_Site__c = testLocation.Id,
            StageName = 'Solicitation',
            CloseDate = System.today().addDays(43),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            //Split_Reason__c = 'RSMO Donations**'
            Accept_56_Day_Rule_Violation__c = true
        );
        insert testOpportunity;
        
        sked_Drive__c testDrive = new sked_Drive__c(
            Name = 'Test Drive',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Date__c = System.today().addDays(44),
            sked_Drive_Site__c = testLocation.Id,
            sked_Opportunity__c = testOpportunity.Id,
            sked_Type_of_Drive__c = 'Fixed Site',
            sked_Account__c = testAccount1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Total_Products_Projected__c = 30,
            sked_2RBC_Projected_Procedures__c = 10,
            sked_WB_Projected_Procedures__c = 10,
            sked_Plasma_Projected_Procedures__c = 10,
            sked_Staging_Location__c = testStagingLocation1.Id
        );
        insert testDrive;
        
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Location__c = testLocation.Id,
            sked__Region__c = testRegion1.Id,
            sked__Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador',
            sked_Setup_Time__c = 60,
            sked_Travel_Time2__c = 60
        );
        insert testJob;
        
        sked_Role_Time_Detail__c roleTimeDetail = new sked_Role_Time_Detail__c(
            sked_Drive_Type__c = 'Fixed Site',
            sked_Fixed_Site_Operation_Type__c = 'Non Integrated WB',
            sked_Type__c = 'Global',
            sked_Lead_Time__c = 10,
            sked_Breakdown_Time__c = 10,
            sked_Setup_Time__c = 12,
            sked_Wrap_up_Time__c = 10,
            sked_Resource_Role_Group__c = 'Driving Roles', 
            sked_Mobile_Type__c = 'Inside'
        );
        insert roleTimeDetail;
        
        sked_Role_Time_Variance__c roleTimeVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add',
            sked_Effective_End_Date__c = testDrive.sked_Drive_Date__c,
            sked_Effective_Start_Date__c = testDrive.sked_Drive_Date__c,
            sked_Location__c = testLocation.Id,
            sked_Variation_Amount__c = 15,
            sked_Variation_Type__c = 'Elevator',
            sked_Resource_Role_Group__c = 'Driving roles',
            sked_Variance_Applies_to__c = 'Lead Time;Setup Time;Breakdown Time;Wrap-up Time;Travel Time To;Travel Time From',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert roleTimeVariance;

 		Test.startTest();
			GetDrivesWithIncorrectJobTimesBatch batchJobs = new GetDrivesWithIncorrectJobTimesBatch();
        	Database.executeBatch(batchJobs);
        Test.stopTest();
    }
    
    @isTest
    static void generateDriveTypeTag_FixedSite_Integrated_WB_Test() {
        
        /*Chapter for Site*/
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region'
        );
        insert testChapter;
      
        skedHubBase.setBypassAllTriggers(true);
        triggerHandler.bypass('TaskTriggerHandler');
        triggerHandler.bypass('AccountTriggerHandler');
		Triggerhandler.bypass('OpportunityTriggerhandler');
        triggerHandler.bypass('JobTriggerHandler');
		Triggerhandler.bypass('DriveTriggerService');
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        sked__Location__c testLocation = new sked__Location__c(
            Name = 'Test Location 1',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Fixed Site').getRecordTypeId(),
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = System.Today(),
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 2,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 2',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Test Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4931',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Chapter__c = testChapter.Id,
            sked_Address_1__c = 'ABC STREET', 
            sked_City__c = 'Test City', 
            sked_County__c = 'Test', 
            sked_State__c = 'PA', 
            sked_Zip_Code__c = '18411', 
            Operation_Type__c = 'Integrated'
        );
        insert testLocation;
        
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 36.7450046,
            sked_Geolocation__Longitude__s = -121.4816244
        );
        insert testStagingLocation1;
        
        Account testAccount1 = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test Internal Name',
            APT_Required__c = FALSE,
            Type = skedConstants.ACCOUNT_TYPE_EDUCATION,
            Industry_Code__c = skedConstants.ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL
            //Contact_BPL__c = contactBPL.Id
        );
    	insert testAccount1;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = testAccount1.Id,
            Drive_Date__c = System.today().addDays(43),
            Drive_Site__c = testLocation.Id,
            StageName = 'Solicitation',
            CloseDate = System.today().addDays(43),
            //Parent_Template_Id__c = parentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            //Split_Reason__c = 'RSMO Donations**'
            Accept_56_Day_Rule_Violation__c = true
        );
        insert testOpportunity;
        
        sked_Drive__c testDrive = new sked_Drive__c(
            Name = 'Test Drive',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Date__c = System.today().addDays(44),
            sked_Drive_Site__c = testLocation.Id,
            sked_Opportunity__c = testOpportunity.Id,
            sked_Type_of_Drive__c = 'Fixed Site',
            sked_Account__c = testAccount1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Total_Products_Projected__c = 30,
            sked_2RBC_Projected_Procedures__c = 10,
            sked_WB_Projected_Procedures__c = 10,
            sked_Plasma_Projected_Procedures__c = 10,
            sked_Staging_Location__c = testStagingLocation1.Id
        );
        insert testDrive;
        
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Location__c = testLocation.Id,
            sked__Region__c = testRegion1.Id,
            sked__Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, Time.newInstance(20,0,0,0)),
            sked__Duration__c = 360,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador',
            sked_Setup_Time__c = 60,
            sked_Travel_Time2__c = 60
        );
        insert testJob;
        
        sked_Role_Time_Detail__c roleTimeDetail = new sked_Role_Time_Detail__c(
            sked_Drive_Type__c = 'Fixed Site',
            sked_Fixed_Site_Operation_Type__c = 'Non Integrated WB',
            sked_Type__c = 'Global',
            sked_Lead_Time__c = 10,
            sked_Breakdown_Time__c = 10,
            sked_Setup_Time__c = 12,
            sked_Wrap_up_Time__c = 10,
            sked_Resource_Role_Group__c = 'Driving Roles', 
            sked_Mobile_Type__c = 'Inside'
        );
        insert roleTimeDetail;
        
        sked_Role_Time_Variance__c roleTimeVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add',
            sked_Effective_End_Date__c = testDrive.sked_Drive_Date__c,
            sked_Effective_Start_Date__c = testDrive.sked_Drive_Date__c,
            sked_Location__c = testLocation.Id,
            sked_Variation_Amount__c = 15,
            sked_Variation_Type__c = 'Elevator',
            sked_Resource_Role_Group__c = 'Driving roles',
            sked_Variance_Applies_to__c = 'Lead Time;Setup Time;Breakdown Time;Wrap-up Time;Travel Time To;Travel Time From',
            sked_Days_Of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        );
        insert roleTimeVariance;

 		Test.startTest();
			GetDrivesForDCRBatch batchJobs = new GetDrivesForDCRBatch();
        	Database.executeBatch(batchJobs);
        Test.stopTest();
    }
}