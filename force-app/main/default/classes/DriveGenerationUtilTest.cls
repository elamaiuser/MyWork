@isTest
public class DriveGenerationUtilTest {
    
    @testSetup
    static void setupTestData() {
        // Create test data here if needed
        Calendar_Build_Log__c testLog = new Calendar_Build_Log__c(
            Name = 'Test Log',
            External_Id__c = '2024-08-29',
            Drive_Date__c = Date.today()
        );
        insert testLog;
        
        BSF_Error_Log__c testErrorLog = new BSF_Error_Log__c(
            Error_Description__c = 'Test Error',
            Object_RecordId__c = 'TestRecordId',
            Functionality__c = 'TestFunctionality'
        );
        insert testErrorLog;
    }
    
    @isTest
    static void testTimeConfigurationModelConstructor() {
        // Instantiate the TimeConfigurationModel
        DriveGenerationUtil.TimeConfigurationModel timeConfig = new DriveGenerationUtil.TimeConfigurationModel();
        
        // Assert that all fields are correctly initialized to their default values
        System.assertEquals(0, timeConfig.leadTime, 'Expected leadTime to be 0');
        System.assertEquals(0, timeConfig.setupTime, 'Expected setupTime to be 0');
        System.assertEquals(0, timeConfig.breakDownTime, 'Expected breakDownTime to be 0');
        System.assertEquals(0, timeConfig.wrapUpTime, 'Expected wrapUpTime to be 0');
        System.assertEquals(0, timeConfig.travelTime, 'Expected travelTime to be 0');
        System.assertEquals(0, timeConfig.travelTime2, 'Expected travelTime2 to be 0');
        System.assertEquals(0, timeConfig.siteLogisticsTo, 'Expected siteLogisticsTo to be 0');
        System.assertEquals(0, timeConfig.siteLogisticsBack, 'Expected siteLogisticsBack to be 0');
        System.assertEquals(0, timeConfig.travelTimeCoToSiteVariance, 'Expected travelTimeCoToSiteVariance to be 0');
        System.assertEquals(0, timeConfig.travelTimeSiteToCoVariance, 'Expected travelTimeSiteToCoVariance to be 0');
    }
    
    @isTest
    static void testTravelTimeSettingModelConstructor() {
        // Instantiate the TravelTimeSettingModel
        DriveGenerationUtil.TravelTimeSettingModel travelTimeSetting = new DriveGenerationUtil.TravelTimeSettingModel();
        
        // Assert that all fields are correctly initialized to their default values
        System.assertEquals(false, travelTimeSetting.isNoTravelTimeChecked, 'Expected isNoTravelTimeChecked to be FALSE');
        System.assertEquals(0, travelTimeSetting.travelTimeCOToSite, 'Expected travelTimeCOToSite to be 0');
        System.assertEquals(0, travelTimeSetting.travelTimeSiteToCO, 'Expected travelTimeSiteToCO to be 0');
        System.assertEquals(0, travelTimeSetting.resourceRoleGroupsNeededTravelTime.size(), 'Expected resourceRoleGroupsNeededTravelTime to be an empty list');
        System.assertEquals(0, travelTimeSetting.map_driveType_travelTimeIncludedFor.size(), 'Expected map_driveType_travelTimeIncludedFor to be an empty map');
        System.assertEquals('Drivers Only', travelTimeSetting.travelTimeIncludedForFixedSite, 'Expected travelTimeIncludedForFixedSite to be "Drivers Only"');
        System.assertEquals('All Roles', travelTimeSetting.travelTimeIncludedForMobile, 'Expected travelTimeIncludedForMobile to be "All Roles"');
    }
    
    @isTest
    static void testGetCalendarBuildLogRecord() {
        DriveGenerationUtil.CalendarBuildLogWrapper wrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(Date.today(), 'Calendar Build', 'Scheduled');
        wrapper.externalId = '2024-08-29';
        
        Test.startTest();
        List<sObject> result = DriveGenerationUtil.getCalendarBuildLogRecord(wrapper);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return one record');
        //System.assertEquals('Test Log', result[0].get('Name'), 'Should return the correct log');
    }
    
    @isTest
    static void testCaptureCbLogForCalendarBuild() {
        DriveGenerationUtil.CalendarBuildLogWrapper wrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(Date.today(), BSF_Constants.BATCH_CALENDAR_BUILD, 'Scheduled');
        wrapper.externalId = String.valueOf(Date.today().addYears(1));
        wrapper.eligibleFsOppCount = 10;
        wrapper.eligibleMobileOppCount = 5;
        wrapper.fsOpportunitiesCreated = 8;
        wrapper.mobileOpportunitiesCreated = 4;
        wrapper.fsOpportunitiesFailureCount = 2;
        wrapper.mobileOpportunitiesFailureCount = 1;
        wrapper.errorLogIdsCreatedDuringBatchRun = new Set<Id>{[SELECT Id FROM BSF_Error_Log__c LIMIT 1].Id};
        
        
        Test.startTest();
        DriveGenerationUtil.captureCbLogAndCbErrorLog(wrapper);
        Test.stopTest();
		
        // Verify Calendar Build Log was updated/created
        Calendar_Build_Log__c updatedLog = [SELECT Id, Name, CB_Batch_Status__c, CB_FS_Eligible_Opportunity_Count__c, CB_Mobile_Eligible_Opportunity_Count__c,
                                            CB_FS_Opportunities_Created__c,CB_Mobile_Opportunities_Created__c,
                                            CB_FS_Opportunities_Failure_Count__c,CB_Mobile_Opportunities_Failure_Count__c
                                            FROM Calendar_Build_Log__c WHERE External_Id__c = :wrapper.externalId];
        //System.assertEquals('Test Capture Log', updatedLog.Name, 'Log name should be updated');
        System.assertEquals('Completed', updatedLog.CB_Batch_Status__c, 'Batch status should be Completed');
        System.assertEquals(10, updatedLog.CB_FS_Eligible_Opportunity_Count__c, 'FS Eligible Opportunity Count should match');
        System.assertEquals(5, updatedLog.CB_Mobile_Eligible_Opportunity_Count__c, 'Mobile Eligible Opportunity Count should match');
        System.assertEquals(8, updatedLog.CB_FS_Opportunities_Created__c, 'FS Opportunities Created should match');
        System.assertEquals(4, updatedLog.CB_Mobile_Opportunities_Created__c, 'Mobile Opportunities Created should match');
        System.assertEquals(2, updatedLog.CB_FS_Opportunities_Failure_Count__c, 'FS Opportunities Failure Count should match');
        System.assertEquals(1, updatedLog.CB_Mobile_Opportunities_Failure_Count__c, 'Mobile Opportunities Failure Count should match');

        /*
        // Verify Calendar Build Error Log was created
        List<Calendar_Build_Error_Log__c> errorLogs = [SELECT Id FROM Calendar_Build_Error_Log__c WHERE Calendar_Build_Log__c = :testErrorLog.Id];
        System.assertEquals(1, errorLogs.size(), 'One error log should be created');
		*/
    }
    
    @isTest
    static void testCaptureCbLogForDriveGeneration() {
        DriveGenerationUtil.CalendarBuildLogWrapper wrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(Date.today(), BSF_Constants.BATCH_DRIVE_GENERATION, 'Scheduled');
        wrapper.externalId = String.valueOf(Date.today().addYears(1));
        wrapper.fsDriveGenerationCount = 15;
        wrapper.fsDriveGenerationFailureCount = 2;
        wrapper.mobileDriveGenerationCount = 10;
        wrapper.mobileDriveGenerationFailureCount = 1;

        Test.startTest();
        DriveGenerationUtil.captureCbLogAndCbErrorLog(wrapper);
        Test.stopTest();

        Calendar_Build_Log__c updatedLog = [SELECT Id, FS_Drive_Generation_Count__c, FS_Drive_Generation_Failure_Count__c, 
                                            Mobile_Drive_Generation_Count__c, Mobile_Drive_Generation_Failure_Count__c 
                                            FROM Calendar_Build_Log__c WHERE External_Id__c = :wrapper.externalId];
        
        System.assertEquals(15, updatedLog.FS_Drive_Generation_Count__c, 'FS Drive Generation Count should match');
        System.assertEquals(2, updatedLog.FS_Drive_Generation_Failure_Count__c, 'FS Drive Generation Failure Count should match');
        System.assertEquals(10, updatedLog.Mobile_Drive_Generation_Count__c, 'Mobile Drive Generation Count should match');
        System.assertEquals(1, updatedLog.Mobile_Drive_Generation_Failure_Count__c, 'Mobile Drive Generation Failure Count should match');
    }

    @isTest
    static void testCaptureCbLogForDriveStatusCorrection() {
        DriveGenerationUtil.CalendarBuildLogWrapper wrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(Date.today(), BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION, 'Scheduled');
        wrapper.externalId = String.valueOf(Date.today().addYears(1));
        wrapper.driveCount = 100;
        wrapper.finalStateDriveCount = 80;
        wrapper.OpenDriveCount = 20;
        wrapper.correctedDriveCount = 15;
        wrapper.opRecordCount = 150;
        wrapper.submittedOpRecordCount = 130;
        wrapper.notSubmittedOpRecordCount = 20;

        Test.startTest();
        DriveGenerationUtil.captureCbLogAndCbErrorLog(wrapper);
        Test.stopTest();

        Calendar_Build_Log__c updatedLog = [SELECT Id, Status_Correction_Batch_Drive_Count__c, Final_State_Drive_Count__c, 
                                            Open_Drive_Count__c, Corrected_Drive_Count__c, Op_Record_Count__c, 
                                            Submitted_Op_Record_Count__c, Not_Submitted_Op_Record_Count__c 
                                            FROM Calendar_Build_Log__c WHERE External_Id__c = :wrapper.externalId];
        
        System.assertEquals(100, updatedLog.Status_Correction_Batch_Drive_Count__c, 'Status Correction Batch Drive Count should match');
        System.assertEquals(80, updatedLog.Final_State_Drive_Count__c, 'Final State Drive Count should match');
        System.assertEquals(20, updatedLog.Open_Drive_Count__c, 'Open Drive Count should match');
        System.assertEquals(15, updatedLog.Corrected_Drive_Count__c, 'Corrected Drive Count should match');
        System.assertEquals(150, updatedLog.Op_Record_Count__c, 'Op Record Count should match');
        System.assertEquals(130, updatedLog.Submitted_Op_Record_Count__c, 'Submitted Op Record Count should match');
        System.assertEquals(20, updatedLog.Not_Submitted_Op_Record_Count__c, 'Not Submitted Op Record Count should match');
    }

    @isTest
    static void testCaptureCbLogForSysGenFS() {
        DriveGenerationUtil.CalendarBuildLogWrapper wrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(Date.today(), BSF_Constants.BATCH_SYS_GEN_FS, 'Scheduled');
        wrapper.externalId = String.valueOf(Date.today().addYears(1));
        wrapper.fsSysGenDrivesWithAllocResourceCount = 50;
        wrapper.fsSysGenDrivesWOAllocResourceCount = 10;
        wrapper.fsSysGenFailureCount = 5;

        Test.startTest();
        DriveGenerationUtil.captureCbLogAndCbErrorLog(wrapper);
        Test.stopTest();

        Calendar_Build_Log__c updatedLog = [SELECT Id, FS_Drives_with_Resource_Allocation__c, 
                                            FS_Drives_wo_Resource_Allocation__c, FS_Drives_Failed_Processing__c 
                                            FROM Calendar_Build_Log__c WHERE External_Id__c = :wrapper.externalId];
        
        System.assertEquals(50, updatedLog.FS_Drives_with_Resource_Allocation__c, 'FS Drives with Resource Allocation should match');
        System.assertEquals(10, updatedLog.FS_Drives_wo_Resource_Allocation__c, 'FS Drives without Resource Allocation should match');
        System.assertEquals(5, updatedLog.FS_Drives_Failed_Processing__c, 'FS Drives Failed Processing should match');
    }

    @isTest
    static void testCaptureCbLogForSysGenMobile() {
        DriveGenerationUtil.CalendarBuildLogWrapper wrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(Date.today(), BSF_Constants.BATCH_SYS_GEN_MOBILE, 'Scheduled');
        wrapper.externalId = String.valueOf(Date.today().addYears(1));
        wrapper.mobileSysGenDrivesWithAllocResourceCount = 40;
        wrapper.mobileSysGenDrivesWOAllocResourceCount = 8;
        wrapper.mobileSysGenFailureCount = 3;

        Test.startTest();
        DriveGenerationUtil.captureCbLogAndCbErrorLog(wrapper);
        Test.stopTest();

        Calendar_Build_Log__c updatedLog = [SELECT Id, Mobile_Drives_with_Resource_Allocation__c, 
                                            Mobile_Drives_wo_Resource_Allocation__c, Mobile_Drives_Failed_Processing__c 
                                            FROM Calendar_Build_Log__c WHERE External_Id__c = :wrapper.externalId];
        
        System.assertEquals(40, updatedLog.Mobile_Drives_with_Resource_Allocation__c, 'Mobile Drives with Resource Allocation should match');
        System.assertEquals(8, updatedLog.Mobile_Drives_wo_Resource_Allocation__c, 'Mobile Drives without Resource Allocation should match');
        System.assertEquals(3, updatedLog.Mobile_Drives_Failed_Processing__c, 'Mobile Drives Failed Processing should match');
    }
}