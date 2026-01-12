@isTest
public class UpdateDrivesVehicleAllocationFieldsTest {
	@istest
    public static void updateDriveFieldsTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);

        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Test.startTest();
        GenerateMobileDrive.generateDrives(config);
        
        List<sked_Drive__c> driveList = [SELECT Id, sked_Drive_Date__c, sked_Type_of_Drive__c, sked_No_of_Allocated_Buses__c, sked_No_of_Allocated_CDL__c, sked_No_of_Allocated_DOT__c, sked_Vehicle_Types__c, sked_Vehicle_Capacity__c, (SELECT Id, sked_Drive__c,sked__Type__c,sked__Quantity__c, sked_Resource_Role__c, sked_Asset_Type__c FROM sked_Jobs__r where sked__Type__c = 'Vehicle') FROM sked_Drive__c WHERE sked_Opportunity__c IN: config.oppIds];
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ',
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE,
            	sked_DOT__c = TRUE,
            	sked__Category__c = 'Bus'
            );
        insert testVehicle;
        List<sked__Job__c> Jobs = driveList[0].sked_Jobs__r;
        sked__Job_Allocation__c jobAllocation = new sked__Job_Allocation__c (
        	sked__Job__c = Jobs[0].Id,
			sked__Resource__c =   testVehicle.Id          
        );
        insert jobAllocation;
        
        UpdateDrivesVehicleAllocationFieldsBatch batch1 = new UpdateDrivesVehicleAllocationFieldsBatch('Mobile');
        Database.executeBatch(batch1, 100);
        
        skedSetting.instance.Admin.migrationMode = FALSE;

        skedHubBase.BypassInsertTriggers = FALSE;
        skedHubBase.BypassUpdateTriggers = FALSE;
        Test.stopTest();
    }
    
    @istest
    public static void unitTestToUpdateDriveMultipleVehicleAllocationTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);

        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Test.startTest();
        GenerateMobileDrive.generateDrives(config);
        
        
        List<sked_Drive__c> driveList = [SELECT Id, sked_Drive_Date__c, sked_Type_of_Drive__c, sked_No_of_Allocated_Buses__c, sked_No_of_Allocated_CDL__c, sked_No_of_Allocated_DOT__c, sked_Vehicle_Types__c, sked_Vehicle_Capacity__c, (SELECT Id, sked_Drive__c,sked__Type__c,sked__Quantity__c, sked_Resource_Role__c, sked_Asset_Type__c FROM sked_Jobs__r where sked__Type__c = 'Vehicle') FROM sked_Drive__c WHERE sked_Opportunity__c IN: config.oppIds];
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ',
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE,
            	sked_DOT__c = TRUE,
            	sked__Category__c = 'Bus'
            );
        insert testVehicle;
        
        sked__Resource__c testVehicle1 = new sked__Resource__c(
                Name = 'Test Vehicle 1',
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 25,
                sked__Is_Active__c = TRUE,
            	sked_CDL__c = TRUE,
            	sked__Category__c = 'Truck'
            );
        insert testVehicle1;
        
        List<sked__Job__c> Jobs = driveList[0].sked_Jobs__r;
        List<sked__Job_Allocation__c> jobAllocationList = new List<sked__Job_Allocation__c>();
        sked__Job_Allocation__c jobAllocation = new sked__Job_Allocation__c (
        	sked__Job__c = Jobs[0].Id,
			sked__Resource__c = testVehicle.Id          
        );
        jobAllocationList.add(jobAllocation);
        
        sked__Job_Allocation__c jobAllocation1 = new sked__Job_Allocation__c (
        	sked__Job__c = Jobs[0].Id,
			sked__Resource__c = testVehicle1.Id          
        );
        jobAllocationList.add(jobAllocation1);
        
        insert jobAllocationList;
        
        UpdateDrivesVehicleAllocationFieldsBatch batch1 = new UpdateDrivesVehicleAllocationFieldsBatch('Mobile');
        Database.executeBatch(batch1, 100);
        
        skedSetting.instance.Admin.migrationMode = FALSE;

        skedHubBase.BypassInsertTriggers = FALSE;
        skedHubBase.BypassUpdateTriggers = FALSE;
        Test.stopTest();
    }
    
    @istest
    public static void unitTestForCustomDateConstructorTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);

        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Test.startTest();
        GenerateMobileDrive.generateDrives(config);
        List<sked_Drive__c> driveList = [SELECT Id, sked_Drive_Date__c, sked_Type_of_Drive__c, sked_No_of_Allocated_Buses__c, sked_No_of_Allocated_CDL__c, sked_No_of_Allocated_DOT__c, sked_Vehicle_Types__c, sked_Vehicle_Capacity__c, (SELECT Id, sked_Drive__c,sked__Type__c,sked__Quantity__c, sked_Resource_Role__c, sked_Asset_Type__c FROM sked_Jobs__r where sked__Type__c = 'Vehicle') FROM sked_Drive__c WHERE sked_Opportunity__c IN: config.oppIds];
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ',
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE,
            	sked_DOT__c = TRUE,
            	sked__Category__c = 'Bus'
            );
        insert testVehicle;
        List<sked__Job__c> Jobs = driveList[0].sked_Jobs__r;
        List<sked__Job_Allocation__c> jobAllocationList = new List<sked__Job_Allocation__c>();
        sked__Job_Allocation__c jobAllocation = new sked__Job_Allocation__c (
        	sked__Job__c = Jobs[0].Id,
			sked__Resource__c = testVehicle.Id          
        );
        jobAllocationList.add(jobAllocation);
        
        insert jobAllocationList;
        
        Integer month = Date.today().month(); 
        Integer year = Date.today().year(); 
        Integer todayDate = Date.today().day(); 
        
        Date date1 = Date.newInstance(year,month,todayDate);
    	Date date2 = Date.newInstance(year,month,todayDate);
    	String typeOfDrive = 'Mobile';
    
    	UpdateDrivesVehicleAllocationFieldsBatch batchObject = new UpdateDrivesVehicleAllocationFieldsBatch(date1, date2, typeOfDrive);
    	Database.executeBatch(batchObject,100);
        
        skedSetting.instance.Admin.migrationMode = FALSE;

        skedHubBase.BypassInsertTriggers = FALSE;
        skedHubBase.BypassUpdateTriggers = FALSE;
        Test.stopTest();
    }
    
    @istest
    public static void unitTestForScheduledBatchRunwithFirstconstructorTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);

        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Test.startTest();
        GenerateMobileDrive.generateDrives(config);
        List<sked_Drive__c> driveList = [SELECT Id, sked_Drive_Date__c, sked_Type_of_Drive__c, sked_No_of_Allocated_Buses__c, sked_No_of_Allocated_CDL__c, sked_No_of_Allocated_DOT__c, sked_Vehicle_Types__c, sked_Vehicle_Capacity__c, (SELECT Id, sked_Drive__c,sked__Type__c,sked__Quantity__c, sked_Resource_Role__c, sked_Asset_Type__c FROM sked_Jobs__r where sked__Type__c = 'Vehicle') FROM sked_Drive__c WHERE sked_Opportunity__c IN: config.oppIds];
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ',
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE,
            	sked_DOT__c = TRUE,
            	sked__Category__c = 'Bus'
            );
        insert testVehicle;
        
        sked__Resource__c testVehicle1 = new sked__Resource__c(
                Name = 'Test Vehicle 1',
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 25,
                sked__Is_Active__c = TRUE,
            	sked_CDL__c = TRUE,
            	sked__Category__c = 'Truck'
            );
        insert testVehicle1;
        
        List<sked__Job__c> Jobs = driveList[0].sked_Jobs__r;
        List<sked__Job_Allocation__c> jobAllocationList = new List<sked__Job_Allocation__c>();
        sked__Job_Allocation__c jobAllocation = new sked__Job_Allocation__c (
        	sked__Job__c = Jobs[0].Id,
			sked__Resource__c = testVehicle.Id          
        );
        jobAllocationList.add(jobAllocation);
        
        sked__Job_Allocation__c jobAllocation1 = new sked__Job_Allocation__c (
        	sked__Job__c = Jobs[0].Id,
			sked__Resource__c = testVehicle1.Id          
        );
        jobAllocationList.add(jobAllocation1);
        
        insert jobAllocationList;
        
        Datetime now = Datetime.now().addMinutes(1); // Get the time 1 minute from now
        Integer second = now.second();
        Integer minute = now.minute();
        Integer hour = now.hour();
        
        String cronExp = second + ' ' + minute + ' ' + hour + ' * * ?'; // Repeats daily at the same time
        
        String typeOfDrive = 'Mobile';
        UpdateDrivesVehicleAllocationSchedulable schedulerJob = new UpdateDrivesVehicleAllocationSchedulable(typeOfDrive);
        System.schedule('Test Schedule UpdateDrivesVehicleAllocationSchedulable', cronExp, schedulerJob);
        
        skedSetting.instance.Admin.migrationMode = FALSE;

        skedHubBase.BypassInsertTriggers = FALSE;
        skedHubBase.BypassUpdateTriggers = FALSE;
        Test.stopTest();
    }
    
    @istest
    public static void unitTestForScheduledBatchRunwithSecondconstructorTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);

        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Test.startTest();
        GenerateMobileDrive.generateDrives(config);
        List<sked_Drive__c> driveList = [SELECT Id, sked_Drive_Date__c, sked_Type_of_Drive__c, sked_No_of_Allocated_Buses__c, sked_No_of_Allocated_CDL__c, sked_No_of_Allocated_DOT__c, sked_Vehicle_Types__c, sked_Vehicle_Capacity__c, (SELECT Id, sked_Drive__c,sked__Type__c,sked__Quantity__c, sked_Resource_Role__c, sked_Asset_Type__c FROM sked_Jobs__r where sked__Type__c = 'Vehicle') FROM sked_Drive__c WHERE sked_Opportunity__c IN: config.oppIds];
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ',
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE,
            	sked_DOT__c = TRUE,
            	sked__Category__c = 'Bus'
            );
        insert testVehicle;
        
        sked__Resource__c testVehicle1 = new sked__Resource__c(
                Name = 'Test Vehicle 1',
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 25,
                sked__Is_Active__c = TRUE,
            	sked_CDL__c = TRUE,
            	sked__Category__c = 'Truck'
            );
        insert testVehicle1;
        
        List<sked__Job__c> Jobs = driveList[0].sked_Jobs__r;
        List<sked__Job_Allocation__c> jobAllocationList = new List<sked__Job_Allocation__c>();
        sked__Job_Allocation__c jobAllocation = new sked__Job_Allocation__c (
        	sked__Job__c = Jobs[0].Id,
			sked__Resource__c = testVehicle.Id          
        );
        jobAllocationList.add(jobAllocation);
        
        sked__Job_Allocation__c jobAllocation1 = new sked__Job_Allocation__c (
        	sked__Job__c = Jobs[0].Id,
			sked__Resource__c = testVehicle1.Id          
        );
        jobAllocationList.add(jobAllocation1);
        
        insert jobAllocationList;
        
        Datetime now = Datetime.now().addMinutes(1); // Get the time 1 minute from now
        Integer second = now.second();
        Integer minute = now.minute();
        Integer hour = now.hour();
        
        String cronExp = second + ' ' + minute + ' ' + hour + ' * * ?'; // Repeats daily at the same time

		Integer month = Date.today().month(); 
        Integer year = Date.today().year(); 
        Integer todayDate = Date.today().day(); 
        
        Date toDate = Date.newInstance(year,month,todayDate);
    	Date fromDate = Date.newInstance(year,month,todayDate);
    	String typeOfDrive = 'Mobile';
    
    	UpdateDrivesVehicleAllocationSchedulable schedulerJob = new UpdateDrivesVehicleAllocationSchedulable(toDate, fromDate, typeOfDrive);
        System.schedule('update Drives Vehicle Allocation for custom drive date', cronExp, schedulerJob);
        
        skedSetting.instance.Admin.migrationMode = FALSE;

        skedHubBase.BypassInsertTriggers = FALSE;
        skedHubBase.BypassUpdateTriggers = FALSE;
        Test.stopTest();
    }
}