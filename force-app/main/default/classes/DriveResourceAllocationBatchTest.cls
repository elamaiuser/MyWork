/*
* This Test class covering the following Classes
* DriveResourceAllocationBatch (86%)
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
     
        Test.startTest();
        skedHubBase.BypassInsertTriggers = false;
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        CreateSkedDrive.createDrives(new List<Opportunity>{fixOpportunity});
        sked_Drive__c fsDrive = [SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c, (SELECT Id, sked__Region__c, sked__Region__r.sked_Biomed_Collection_Op_Center__c FROM sked_jobs__r) FROM sked_Drive__c WHERE sked_Opportunity__c = :fixOpportunity.Id LIMIT 1];
        List<sked__Resource__c> resourceList = getResources();
        for(sked__Resource__c res : resourceList) {
            res.sked__Primary_Region__c = fsDrive.sked_jobs__r[0].sked__Region__c;
        }
        insert resourceList;
        List<sked__Resource__c> testResourceList = [SELECT ID, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c FROM sked__Resource__c WHERE sked_Asset_Type__c = 'Equipment'];
        fsDrive.sked_Collection_Operation__c = testResourceList[0].sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
        TriggerHandler.bypass('DriveTriggerHandler');
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
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        Test.startTest();
        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassInsertTriggers = false;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        
        GenerateMobileDrive.generateDrives(config);
        
        skedHubBase.BypassInsertTriggers = TRUE;
        skedHubBase.BypassUpdateTriggers = TRUE;
        sked_Drive__c mobileDrive = [SELECT Id , sked_Opportunity__c, sked_Day_of_Week__c, sked_Projected_Registered_Donors__c, sked_Collection_Operation__c, sked_Drive_Date__c FROM sked_Drive__c where sked_Opportunity__c IN :config.oppIds LIMIT 1];
        sked__Job__c vehicleJob = [SELECT Id, sked__Quantity__c, sked__Start__c, sked__Finish__c, sked__Region__c, sked_Start_Time__c, sked_Finish_Time__c FROM sked__Job__c WHERE sked_Asset_Type__c = 'Vehicle' AND sked_Drive__c =:mobileDrive.Id LIMIT 1];
		
        sked_Staffing_Constraint__c mobileStaffingConstraint = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = mobileDrive.sked_Collection_Operation__c,
            sked_Date_of_Constraint__c = mobileDrive.sked_Drive_Date__c,
            sked_Drive_Type__c = 'Mobile',
            sked_Total_Staff_Constraints__c = 100 // HRP-10212,HRP-10213
        );
        insert mobileStaffingConstraint;
        List<sked__Resource__c> testResourceList = [SELECT ID, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, sked_Pres_Donor_Capacity__c FROM sked__Resource__c WHERE sked_Asset_Type__c = 'Vehicle' and sked__Is_Active__c = TRUE];
        
        // Reducing pres donor capacity to get into recalculation logic
        for(sked__Resource__c res : testResourceList) {
            res.sked_Pres_Donor_Capacity__c = 100;
        }
        testResourceList[0].sked_CDL__c = TRUE;
        testResourceList[1].sked_DOT__c = TRUE;
        update testResourceList;
        
        List<sked_Operation_Drive_Limit__c> odlList = new List<sked_Operation_Drive_Limit__c>();
        sked_Operation_Drive_Limit__c skedDriveLimit;
        skedDriveLimit =  new sked_Operation_Drive_Limit__c(
                                   sked_Type__c = 'DOT Limit',
                                   sked_Collection_Operation__c = mobileDrive.sked_Collection_Operation__c,
                                   sked_Effective_Start_Date__c =  mobileDrive.sked_Drive_Date__c,
                                   sked_Days_of_Week__c =  mobileDrive.sked_Day_of_Week__c,
                                   sked_Effective_End_Date__c = mobileDrive.sked_Drive_Date__c,
                                   sked_Quantity__c = 60
        );
       	odlList.add(skedDriveLimit);
       	skedDriveLimit =  new sked_Operation_Drive_Limit__c(
                                   sked_Type__c = '2RBC Limit',
                                   sked_Collection_Operation__c = mobileDrive.sked_Collection_Operation__c,
                                   sked_Effective_Start_Date__c =  mobileDrive.sked_Drive_Date__c,
                                   sked_Days_of_Week__c =  mobileDrive.sked_Day_of_Week__c,
                                   sked_Effective_End_Date__c = mobileDrive.sked_Drive_Date__c,
                                   sked_Quantity__c = 60
        );
        odlList.add(skedDriveLimit);
        
        skedDriveLimit =  new sked_Operation_Drive_Limit__c(
                                   sked_Type__c = 'CDL Limit',
                                   sked_Collection_Operation__c = mobileDrive.sked_Collection_Operation__c,
                                   sked_Effective_Start_Date__c =  mobileDrive.sked_Drive_Date__c,
                                   sked_Days_of_Week__c = mobileDrive.sked_Day_of_Week__c,
                                   sked_Effective_End_Date__c = mobileDrive.sked_Drive_Date__c,
                                   sked_Quantity__c = 60
        );
        odlList.add(skedDriveLimit);
        Database.SaveResult[] result = Database.insert(odlList, false);
        
        List<sked_Operation_Drive_Limit_Override__c> odlOverrideList = new List<sked_Operation_Drive_Limit_Override__c>();
        sked_Operation_Drive_Limit_Override__c odlOverride;
        
        odlOverride = new sked_Operation_Drive_Limit_Override__c(sked_Date__c = mobileDrive.sked_Drive_Date__c, sked_Quantity__c = 10, sked_Operation_Drive_Limit__c = result[0].getId());
        odlOverrideList.add(odlOverride);
        
        odlOverride = new sked_Operation_Drive_Limit_Override__c(sked_Date__c = mobileDrive.sked_Drive_Date__c, sked_Quantity__c = 10, sked_Operation_Drive_Limit__c = result[1].getId());
        odlOverrideList.add(odlOverride);
        
        //odlOverride = new sked_Operation_Drive_Limit_Override__c(sked_Date__c = mobileDrive.sked_Drive_Date__c, sked_Quantity__c = 10, sked_Operation_Drive_Limit__c = result[2].getId());
        //odlOverrideList.add(odlOverride);
        
        insert odlOverrideList;
        
        //Execute the batch
        DriveResourceAllocationBatch driveResourceAllocationBatchTest = new DriveResourceAllocationBatch(BSF_Constants.RUN_TYPE_SCHEDULED, 'Calendar Build', 'Mobile', NULL, new Set<Id>());
        Database.executeBatch(driveResourceAllocationBatchTest, 1);
        Test.stopTest();
    }    
}