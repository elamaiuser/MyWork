/*
* This Test class covering the following Classes
* DriveResourceAllocationBatch (81%)
* */
/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 05/11/2023                  Krapy Tuli                HRP-10009
 * 06/22/2023                  Krapy Tuli                HRP-10212
 * 06/22/2023                  Krapy Tuli                HRP-10213
 * 09/03/2024				   Priti Jana				 Restrutured to remove redundant complexity and increase code coverage
 * 01/23/2025				   Priti Jana				 Fixed errors for 2.1 Rel
 * 07/09/2025				   Priti Jana			     Restructured test method for mobile drive allocation
 *****************************************************************************
*/

@isTest(SeeAllData = false)
private class DriveResourceAllocationBatchTest {
    
    private static List<sked__Resource__c> getResources() {
        List<sked__Resource__c> testResourceList = new List<sked__Resource__c>();
        sked__Resource__c testResource1 = new sked__Resource__c(
            Name = 'Test Resource1',
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
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        testResourceList.add(testResource1);
        
        sked__Resource__c testResource2 = new sked__Resource__c(
            Name = 'Test Resource2',
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
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        testResourceList.add(testResource2);
        
        sked__Resource__c testResource3 = new sked__Resource__c(
            Name = 'Test Resource3',
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
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            sked_MigrationID__c = '5',
            OwnerId = UserInfo.getUserId(),
            sked__UniqueKey__c = '53565'
        );
        testResourceList.add(testResource3);
        return testResourceList;
    }    
    
    static testmethod void testFSDriveResourceAllocation() {
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');
        
        skedHubBase.BypassInsertTriggers = false;
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('JobTriggerHandler');
        TriggerHandler.bypass('JobAllocationTriggerHandler');
        
        Test.startTest();
        CreateSkedDrive.createDrives(new List<Opportunity>{fixOpportunity});
        sked_Drive__c fsDrive = [SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c, (SELECT Id, sked__Region__c, sked__Region__r.sked_Biomed_Collection_Op_Center__c FROM sked_jobs__r) FROM sked_Drive__c WHERE sked_Opportunity__c = :fixOpportunity.Id LIMIT 1];
        
        List<sked__Resource__c> resourceList = getResources();
        for(sked__Resource__c res : resourceList) {
            res.sked__Primary_Region__c = fsDrive.sked_jobs__r[0].sked__Region__c;
        }
        insert resourceList;
        List<sked__Resource__c> testResourceList = [SELECT ID, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c FROM sked__Resource__c WHERE sked_Asset_Type__c = 'Equipment'];
        fsDrive.sked_Collection_Operation__c = testResourceList[0].sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;        
        update fsDrive;
        
        sked__Job__c equipmentJob = [SELECT Id, sked__Quantity__c, sked__Start__c, sked__Finish__c, sked__Region__c, sked_Start_Time__c, sked_Finish_Time__c FROM sked__Job__c WHERE sked_Asset_Type__c = 'Equipment' AND sked_Drive__c =:fsDrive.Id LIMIT 1];
        
        sked__Activity__c activity = new sked__Activity__c(
            sked__Resource__c = testResourceList[1].Id,
            sked__Type__c = 'Administration',
            sked__Start__c = equipmentJob.sked__Start__c.addHours(2),
            sked_Start_Date__c = fsDrive.sked_Drive_Date__c,
            sked_End_Date__c = fsDrive.sked_Drive_Date__c.addDays(5),
            sked__End__c = equipmentJob.sked__Finish__c.addHours(-2),
            sked_Collection_Operation__c = fsDrive.sked_Collection_Operation__c,
            sked_Drive__c = fsDrive.Id,
            sked_Region__c = equipmentJob.sked__Region__c,
            sked_Is_Group_Activity__c = TRUE
        );
        insert activity;
        
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = activity.Id,
            sked__Resource__c = testResourceList[2].Id
        );
        insert skedActivityResource; 
        
        sked__Resource_Override__c resOverride = new sked__Resource_Override__c(
            sked_Collection_Operation__c= fsDrive.sked_Collection_Operation__c,
            sked__Resource__c = testResourceList[3].Id,
            sked_Start_Date__c = fsDrive.sked_Drive_Date__c,
            sked__Start__c = equipmentJob.sked__Start__c.addHours(-2),
            sked_End_Date__c = fsDrive.sked_Drive_Date__c.addDays(1),
            sked__End__c = equipmentJob.sked__Finish__c.addHours(-2),
            sked_End_Time__c = Time.newInstance(equipmentJob.sked__Finish__c.hour(), equipmentJob.sked__Finish__c.minute(), equipmentJob.sked__Finish__c.second(), equipmentJob.sked__Finish__c.millisecond()).addHours(-2),
            sked_Start_Time__c = Time.newInstance(equipmentJob.sked__Start__c.hour(), equipmentJob.sked__Start__c.minute(), equipmentJob.sked__Start__c.second(), equipmentJob.sked__Start__c.millisecond()).addHours(2),
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked_Timezone__c = 'America/Los_Angeles'           
        );
        insert resOverride;
        
        List<sked__Tag__c> tagList = [SELECT Id FROM sked__Tag__c WHERE Name = 'Fixed Site' OR Name = 'Inside' OR Name = 'Equipment'];
        List <sked__Resource_Tag__c> resourceTags = new List <sked__Resource_Tag__c>();
        sked__Resource_Tag__c testResource1_testTag1 = new sked__Resource_Tag__c(
            sked__Resource__c = testResourceList[3].Id,
            sked__Tag__c = tagList[0].Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = 'Active'
        );
        resourceTags.add(testResource1_testTag1);
        
        sked__Resource_Tag__c testResource1_testTag2 = new sked__Resource_Tag__c(
            sked__Resource__c = testResourceList[3].Id,
            sked__Tag__c = tagList[1].Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = 'Active'
        );
        resourceTags.add(testResource1_testTag2);
        
        sked__Resource_Tag__c testResource1_testTag3 = new sked__Resource_Tag__c(
            sked__Resource__c = testResourceList[3].Id,
            sked__Tag__c = tagList[2].Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = 'Active'
        );
        resourceTags.add(testResource1_testTag3);
        
        sked__Resource_Tag__c testResource2_testTag1 = new sked__Resource_Tag__c(
            sked__Resource__c = testResourceList[4].Id,
            sked__Tag__c = tagList[0].Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = 'Active'
        );
        resourceTags.add(testResource2_testTag1);
        
        sked__Resource_Tag__c testResource2_testTag2 = new sked__Resource_Tag__c(
            sked__Resource__c = testResourceList[4].Id,
            sked__Tag__c = tagList[1].Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = 'Active'
        );
        resourceTags.add(testResource2_testTag2);
        
        sked__Resource_Tag__c testResource2_testTag3 = new sked__Resource_Tag__c(
            sked__Resource__c = testResourceList[4].Id,
            sked__Tag__c = tagList[2].Id,
            sked_Expiry_Date__c = system.today().addYears(1),
            sked_Start_Date__c = system.today(),
            sked_Role_Status__c = 'Active'
        );
        resourceTags.add(testResource2_testTag3);
        insert resourceTags;
        
        DriveResourceAllocationBatch driveResourceAllocationBatchTest = new DriveResourceAllocationBatch(BSF_Constants.RUN_TYPE_SCHEDULED, 'Calendar Build', 'Fixed Site', NULL, new Set<Id>());
        Database.executeBatch(driveResourceAllocationBatchTest, 1);
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
    
    static testmethod void testMobileDriveResourceAllocation() {      
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        Opportunity testMobileOpp1 = (Opportunity)mapTestData.get('testOpportunity');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('JobTriggerHandler');
        TriggerHandler.bypass('JobAllocationTriggerHandler');
        
        List<sked__Tag__c> testTags = [SELECT Id, Name FROM sked__Tag__c WHERE Name IN ('Mobile', 'Vehicle', 'Inside', 'Equipment')];
        List<sked__Resource__c> testResourceList = [SELECT ID, sked_Asset_Type__c, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, sked_Pres_Donor_Capacity__c FROM sked__Resource__c WHERE sked_Asset_Type__c != null and sked__Is_Active__c = TRUE];
    
        testResourceList[0].sked_CDL__c = TRUE;
        testResourceList[1].sked_DOT__c = TRUE;
        update testResourceList;
        
        List<sked__Resource_Tag__c> testResourceTags = new List<sked__Resource_Tag__c>();
        for(sked__Resource__c testResource : testResourceList) {
            for(sked__Tag__c testTag : testTags) {
                if(testResource.sked_Asset_Type__c != testTag.Name && !new List<String>{'Mobile','Inside'}.contains(testTag.Name)) continue;
                testResourceTags.add(new sked__Resource_Tag__c(
                    sked__Resource__c = testResource.Id,
                    sked__Tag__c = testTag.Id,
                    sked_Expiry_Date__c = system.today().addYears(5),
                    sked_Start_Date__c = system.today().addYears(-1),
                    sked_Role_Status__c = 'Active'
                ));
            }
        }
        insert testResourceTags;
        
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Sys_Gen_Batch_Mobile__c.intValue();
        Test.setCreatedDate(testDrive1.Id, System.today().addDays(-numOfDays));

        testMobileOpp1.Source__c = 'Calendar Build';
        update new Opportunity(
        	Id = testDrive1.sked_Opportunity__c,
            Anticipated_Registered_Donors__c = 50,
            AnticipatedRegisterDonorChangeReason__c = 'TEST',
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1830',
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            Start_Time__c = Time.newInstance(5, 0, 0, 0), 
            Type_of_Drive__c = 'Mobile',
            Source__c = 'Calendar Build',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId(),
            //Parent_Template_Id__c = parentOpp.Id,
            Call_List_Recipient_Exist__c = false,
            Red_Cross_Volunteer_Required__c = true,
            Red_Cross_Volunteer_Quantity__c = 1,
            Slot_Generator__c = 110,
            Slot_Generator_Change_Reason__c = 'TEST',
            APT_Quantity__c = 0,
            APT_Required__c = false 
        );
        
        Test.startTest();
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert driveShift;
        skedHubBase.BypassInsertTriggers = false;
        
        List<sked__Job__c> jobs = new List<sked__Job__c>();
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Resource_Role__c = 'Driver',
            sked__Quantity__c = 1,
            sked_Travel_Time__c = 45,
            sked_Travel_Time2__c = 45
        );
        jobs.add(job);
        
        sked__Job__c driverSupportJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Resource_Role__c = 'Driver Support',
            sked__Quantity__c = 1,
            sked_Travel_Time__c = 45,
            sked_Travel_Time2__c = 45
        );
        jobs.add(driverSupportJob);
        
        sked__Job__c x2rbcJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked__Quantity__c = 1,
            sked_Travel_Time__c = 45,
            sked_Travel_Time2__c = 45
        );
        jobs.add(x2rbcJob);
        
        sked__Job__c vpHhJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Resource_Role__c = Constants.JOB_TYPE_VP_HH,
            sked__Quantity__c = 1,
            sked_APT_Quantity__c = 0,
            sked_Travel_Time__c = 45,
            sked_Travel_Time2__c = 45
        );
        jobs.add(vpHhJob);
        
        sked__Job__c chargeJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Resource_Role__c = 'Charge',
            sked__Quantity__c = 1,
            sked_Travel_Time__c = 45,
            sked_Travel_Time2__c = 45
        );
        jobs.add(chargeJob);
        
        sked__Job__c equipmentJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Asset_Type__c = 'Equipment',
            sked__Quantity__c = 1
        );
        jobs.add(equipmentJob);
        
        sked__Job__c vehicleJob = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Shift__c = driveShift.Id,
            sked_Asset_Type__c = 'Vehicle',
            sked__Quantity__c = 1
        );
        jobs.add(vehicleJob);
        insert jobs;
        
        sked_Staffing_Constraint__c mobileStaffingConstraint = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = testDrive1.sked_Collection_Operation__c,
            sked_Date_of_Constraint__c = testDrive1.sked_Drive_Date__c,
            sked_Drive_Type__c = 'Mobile',
            sked_Total_Staff_Constraints__c = 100 // HRP-10212,HRP-10213
        );
        insert mobileStaffingConstraint;
        
        
        
        List<sked_Operation_Drive_Limit__c> odlList = new List<sked_Operation_Drive_Limit__c>();
        sked_Operation_Drive_Limit__c skedDriveLimit;
        skedDriveLimit =  new sked_Operation_Drive_Limit__c(
                                   sked_Type__c = 'DOT Limit',
                                   sked_Collection_Operation__c = testDrive1.sked_Collection_Operation__c,
                                   sked_Effective_Start_Date__c =  testDrive1.sked_Drive_Date__c,
                                   sked_Days_of_Week__c =  testDrive1.sked_Day_of_Week__c,
                                   sked_Effective_End_Date__c = testDrive1.sked_Drive_Date__c,
                                   sked_Quantity__c = 60
        );
       	odlList.add(skedDriveLimit);
       	skedDriveLimit =  new sked_Operation_Drive_Limit__c(
                                   sked_Type__c = '2RBC Limit',
                                   sked_Collection_Operation__c = testDrive1.sked_Collection_Operation__c,
                                   sked_Effective_Start_Date__c =  testDrive1.sked_Drive_Date__c,
                                   sked_Days_of_Week__c =  testDrive1.sked_Day_of_Week__c,
                                   sked_Effective_End_Date__c = testDrive1.sked_Drive_Date__c,
                                   sked_Quantity__c = 60
        );
        odlList.add(skedDriveLimit);
        
        skedDriveLimit =  new sked_Operation_Drive_Limit__c(
                                   sked_Type__c = 'CDL Limit',
                                   sked_Collection_Operation__c = testDrive1.sked_Collection_Operation__c,
                                   sked_Effective_Start_Date__c =  testDrive1.sked_Drive_Date__c,
                                   sked_Days_of_Week__c = testDrive1.sked_Day_of_Week__c,
                                   sked_Effective_End_Date__c = testDrive1.sked_Drive_Date__c,
                                   sked_Quantity__c = 60
        );
        odlList.add(skedDriveLimit);
        Database.SaveResult[] result = Database.insert(odlList, false);
        
        List<sked_Operation_Drive_Limit_Override__c> odlOverrideList = new List<sked_Operation_Drive_Limit_Override__c>();
        sked_Operation_Drive_Limit_Override__c odlOverride;
        
        odlOverride = new sked_Operation_Drive_Limit_Override__c(sked_Date__c = testDrive1.sked_Drive_Date__c, sked_Quantity__c = 10, sked_Operation_Drive_Limit__c = result[0].getId());
        odlOverrideList.add(odlOverride);
        
        odlOverride = new sked_Operation_Drive_Limit_Override__c(sked_Date__c = testDrive1.sked_Drive_Date__c, sked_Quantity__c = 10, sked_Operation_Drive_Limit__c = result[1].getId());
        odlOverrideList.add(odlOverride);
        
        insert odlOverrideList;
        
        //Execute the batch
        DriveResourceAllocationBatch driveResourceAllocationBatchTest = new DriveResourceAllocationBatch(BSF_Constants.RUN_TYPE_SCHEDULED, 'Calendar Build', 'Mobile', NULL, new Set<Id>());
        Database.executeBatch(driveResourceAllocationBatchTest, 1);
        //TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
    
     static testMethod void testScheduledRunException() {
        Test.startTest();
        BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION = TRUE;
        DriveResourceAllocationBatch driveResourceAllocationBatchTest = new DriveResourceAllocationBatch(BSF_Constants.RUN_TYPE_SCHEDULED, 'Calendar Build', 'Fixed Site', System.today(), new Set<Id>());
        Database.executeBatch(driveResourceAllocationBatchTest, 1);
        Test.stopTest();
    }
}