@isTest
private class skedResourceHandler_Test {
    
    static testmethod void testDataPopulation() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);

        sked_Admin_Setting__c skedAdminSetting = sked_Admin_Setting__c.getOrgDefaults();
        skedAdminSetting.sked_Admin_DateTime_Conversion__c = TRUE;
        skedAdminSetting.sked_Max_CDL_DOT_Duration__c = 14;
        skedAdminSetting.sked_Admin_FCC_Code_Mobile__c = '83140';
        skedAdminSetting.sked_Admin_FCC_Code_Fixed_Site__c = '83340;83347';
        upsert skedAdminSetting;
        
        List<sObject> predefinedData = new List<sObject>();

        List<string> roles = skedUtils.getPickListValues('sked__Resource__c', 'sked_Roles__c');
        for (string role : roles) {
            sked__Tag__c roleTag = new sked__Tag__c(
                Name = role,
                sked__Type__c = 'Role'
            );
            predefinedData.add(roleTag);
        }
        sked__Tag__c physicalLocationTypeTagInside = new sked__Tag__c(
            Name = 'Inside',
            sked__Type__c = 'Physical Location Type'
        );
        predefinedData.add(physicalLocationTypeTagInside);
        sked__Tag__c physicalLocationTypeTagOutside = new sked__Tag__c(
            Name = 'Outside',
            sked__Type__c = 'Physical Location Type'
        );
        predefinedData.add(physicalLocationTypeTagOutside);
        
        sked__Tag__c assetTypeTagVehicle = new sked__Tag__c(
            Name = 'Vehicle',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTagVehicle);
        sked__Tag__c assetTypeTagEquipment = new sked__Tag__c(
            Name = 'Equipment',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTagEquipment);
        sked__Tag__c assetTypeTag2RBC = new sked__Tag__c(
            Name = '2RBC Asset',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTag2RBC);
        sked__Tag__c assetTypeTagPlasma = new sked__Tag__c(
            Name = 'Plasma Asset',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTagPlasma);
        sked__Tag__c assetTypeTagPlatelet = new sked__Tag__c(
            Name = 'Platelet Asset',
            sked__Type__c = 'Asset Type'
        );
        predefinedData.add(assetTypeTagPlatelet);

        sked__Tag__c driveTypeTagMobile = new sked__Tag__c(
            Name = 'Mobile',
            sked__Type__c = 'Drive Type'
        );
        predefinedData.add(driveTypeTagMobile);

        sked__Tag__c driveTypeTagFixedSite = new sked__Tag__c(
            Name = 'Fixed Site',
            sked__Type__c = 'Drive Type'
        );
        predefinedData.add(driveTypeTagFixedSite);
        
        sked__Tag__c realIdTypeTag = new sked__Tag__c(
            Name = 'REAL ID',
            sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION
        );
        predefinedData.add(realIdTypeTag);
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        predefinedData.add(testCollectionOperation1);
        
        sked__Availability_Pattern__c testWeeklyPattern = new sked__Availability_Pattern__c(
            Name = 'Test Weekly Pattern',
            sked__Hash__c = 'weeklyPatternHash',
            sked_Validate_2CDO_Rule__c = FALSE,
            sked__Pattern__c = '',
            sked_Default_for_Resource_Type__c = 'Equipment'
        );
        predefinedData.add(testWeeklyPattern);
        
        insert predefinedData;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Test.startTest();
        
        List<sked__Resource__c> testResources = new List<sked__Resource__c>();
        sked__Resource__c testResource = new sked__Resource__c(
            sked__Primary_Region__c = testRegion1.Id,
            sked__User__c = UserInfo.getUserId(),
            sked__Resource_Type__c = 'Person',
            sked__Employment_Type__c = 'Full-time ',
            sked__Category__c = '',
            sked__Home_Address__c = 'Inner Sunset, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked__Email__c = 'test@com.test1',
            sked_Primary_Phone_Type__c = 'Mobile Phone',
            sked__Mobile_Phone__c = '1234567890',
            sked_Work_Phone__c = '1233445560',
            sked__Is_Active__c = TRUE,
            sked_FCC_Code__c = '83340;83347;',
            sked_Premium_Pay_Roles__c = '2RBC',
            sked_Employee_ID__c = '001',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Test',
            sked_Last_Name__c = 'Resource',
            sked_ULID__c = 'ULID1',
            sked_Timezone__c = testDataFactory.summary.timezoneSidId,
            sked_REAL_ID_Compliant_indicator__c = true,
            sked_Supervisor_Email__c = UserInfo.getUserEmail()
        );
        testResources.add(testResource);
        
        sked__Resource__c testEquipment = new sked__Resource__c(
            Name = 'Test Equipment',
            sked__Primary_Region__c = testRegion1.Id,
            sked__Resource_Type__c = 'Asset',
            sked_Asset_Type__c = 'Equipment',
            sked_Equipment_Subtype__c = '2RBC Asset',
            sked_Site_Type__c = 'Fixed Site',
            sked__Is_Active__c = TRUE,
            sked_Timezone__c = testDataFactory.summary.timezoneSidId,
            sked_Max_Hours_Per_Weekend__c = null,
            sked_Max_Hours_Per_Week__c = null
        );
        testResources.add(testEquipment);
        
        insert testResources;
        
        Set<Id> affectedRegions = skedResourceHandler.getAffectedArcRegions(testResources);
        
        TriggerHandler.bypass('ResourceTriggerHandler');
        testResource.sked_FCC_Code__c = '83140';
        testResource.sked_Mobile_Type__c = 'Outside';
        testResource.sked_Primary_Phone_Type__c = 'Work Phone';
        update testResource;
        
        testEquipment.sked_Site_Type__c = 'Mobile';
        update testEquipment;
        TriggerHandler.clearBypass('ResourceTriggerHandler');
        
        Test.stopTest();
    }
    
    static testmethod void testException() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Account testAccount = (Account) mapTestData.get('testAccount1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        Test.startTest();
        
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
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert testDriveShift;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED
        );
        insert testJobAllocation;
        
        testResource.sked__Employment_Type__c = 'Part-time';
        update testResource;
        
        Test.stopTest();
    }

    static testmethod void testSeniorityBatch() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        sked__Resource__c testResource = [
            SELECT Id, sked_Timezone__c 
            FROM sked__Resource__c 
            LIMIT 1
        ];

        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Territory__c testDistrict = (sked_Territory__c) mapTestData.get('testTerritory1');
        sked_Territory__c testArcRegion = new sked_Territory__c(
            Name = 'ARC Region',
            RecordTypeId = sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('sked_ARC_Region').getRecordTypeId()
        );
        insert testArcRegion;

        testDistrict.sked_Parent__c = testArcRegion.Id;
        testCollectionOp.sked_Territory__c = testDistrict.Id;
        update new List<SObject>{testDistrict, testCollectionOp};

        Test.startTest();
            testResource.sked_Employment_Status__c = 'Inactive';
            update testResource;
        Test.stopTest();
    }

    static testmethod void testPopulateTimezone() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        sked__Resource__c testResource = [
            SELECT Id, sked_Timezone__c 
            FROM sked__Resource__c 
            WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_ASSET
            LIMIT 1
        ];

        sked__Region__c testRegion2 = (sked__Region__c) mapTestData.get('testRegion2');
        testRegion2.sked__Timezone__c = 'Europe/London';
        update testRegion2;

        Test.startTest();
            testResource.sked__Primary_Region__c = testRegion2.Id;
            update testResource;
        Test.stopTest();
    }

    static testmethod void testCaptureExceptionLogOnResourceLeaveOrTerminated() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        sked__Resource__c testResource = [
            SELECT Id, sked_Timezone__c 
            FROM sked__Resource__c 
            WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            LIMIT 1
        ];

        Test.startTest();
        
        testResource.sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE;
        testResource.sked_Anticipated_Leave_Return_Date__c = System.today().addDays(100);
        testResource.sked_Planned_Termination_Date__c = System.today().addDays(130);
        update testResource;
        
        Test.stopTest();
    }

    static testmethod void testCancelTimeOffOnResourceTerminationOrLeave() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Resource__c testResource = (sked__Resource__c)mapTestData.get('testResource1');

        sked__Availability__c unavailability = new sked__Availability__c(
            sked__Resource__c = testResource.Id,
            sked__Is_Available__c = FALSE,
            sked__Start__c = System.now(),
            sked__Finish__c = System.now().addhours(1),
            sked__Timezone__c = testResource.sked_Timezone__c,
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_PENDING
        );

        insert unavailability;

        Test.startTest();
        
        testResource.sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE;
        testResource.sked_Anticipated_Leave_Return_Date__c = System.today().addDays(2);
        testResource.sked_Planned_Termination_Date__c = System.today().addDays(1);
        update testResource;

        unavailability.sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
        update unavailability;

        activateResource(testResource);
        testResource.sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE;
        testResource.sked_Anticipated_Leave_Return_Date__c = System.today().addDays(2);
        update testResource;

        activateResource(testResource);
        testResource.sked_Planned_Termination_Date__c = System.today().addDays(1);
        update testResource;

        activateResource(testResource);
        testResource.sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_LEAVE;
        update testResource;
        
        Test.stopTest();
    }

    static testmethod void testCaptureWorkDaysPerWeekException() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
		
		sked_Resource_Hours_Record__c rhr = new sked_Resource_Hours_Record__c();
		rhr.sked_Resource__c = testResource1.id;
		rhr.sked_Start_Date__c = System.today();
		rhr.sked_End_Date__c = System.today().addDays(7);
		insert rhr;

        testResource1.sked_Min_Working_Days_Per_Week__c = '3';
		update testResource1;		
    }

    static void activateResource(sked__Resource__c resource) {
        resource.sked_Employment_Status__c = skedConstants.RESOURCE_EMPLOYMENT_STATUS_ACTIVE;
        resource.sked_Anticipated_Leave_Return_Date__c = NULL;
        resource.sked_Planned_Termination_Date__c = NULL;
        resource.sked_Termination_Date__c = NULL;
        skedHubBase.setBypassAllTriggers(true);
        update resource;
        skedHubBase.setBypassAllTriggers(false);
    }
    
    static testmethod void testUpdateRealIdTags() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        sked__Resource__c testResource = [
            SELECT Id, sked_Timezone__c 
            FROM sked__Resource__c 
            WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            LIMIT 1
        ];

        Test.startTest();
        
        testResource.sked_REAL_ID_Compliant_indicator__c = true;
        update testResource;
        
        Test.stopTest();
    }
    
}