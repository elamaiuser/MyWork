@isTest
private class skedResourceTrigger_Test {
    
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
        
        insert predefinedData;
        
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
        
        sked__Availability_Pattern__c testWeeklyPattern = new sked__Availability_Pattern__c(
            Name = 'Test Weekly Pattern',
            sked__Hash__c = 'weeklyPatternHash',
            sked_Validate_2CDO_Rule__c = FALSE,
            sked__Pattern__c = '',
            sked_Default_for_Resource_Type__c = 'Equipment'
        );
        insert testWeeklyPattern;
        
        Test.startTest();
        
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
            sked__Primary_Phone__c = '1234567890',
            sked__Is_Active__c = TRUE,
            sked_FCC_Code__c = '83340;83347;',
            sked_Premium_Pay_Roles__c = '2RBC',
            sked_Employee_ID__c = '001',
            sked_Title__c = 'Mr',
            sked_First_Name__c = 'Test',
            sked_Last_Name__c = 'Resource',
            sked_ULID__c = 'ULID1',
            sked_Timezone__c = testDataFactory.summary.timezoneSidId
        );
        insert testResource;
        
        testResource.sked_FCC_Code__c = '83140';
        testResource.sked_Mobile_Type__c = 'Outside';
        update testResource;
        
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
        insert testEquipment;
        
        testEquipment.sked_Site_Type__c = 'Mobile';
        update testEquipment;
        
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
            sked_UFID__c = '123456',
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

    static testmethod void testAssetUpdate_DRD() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();

        sked__Resource__c testVehicle = (sked__Resource__c) mapTestData.get('testVehicle1');

        Profile drdProfile = [SELECT Id FROM Profile WHERE Name LIKE '%DRD%' LIMIT 1];

        Boolean exceptionCaught = false;
        Test.startTest();
        User testUser = new user(alias = 'testuser', email='test@testleton.com', emailencodingkey='UTF-8', firstName='test', lastname='testleton', 
        languagelocalekey='en_US', localesidkey='en_US', profileid = drdProfile.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username='test@testleton.com');
        insert testUser;
        System.runAs(testUser) {
            try {
                testVehicle.sked_Beds__c = 50;
                update testVehicle;
            } catch (Exception e) { 
                exceptionCaught = true;
            }
        }
        Test.stopTest();
        
        System.assert(exceptionCaught);
    }

    static testmethod void testAssetUpdate() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();

        sked__Resource__c testVehicle = (sked__Resource__c) mapTestData.get('testVehicle1');

        Boolean exceptionCaught = false;
        Test.startTest();
        testVehicle.sked_Beds__c = 50;
        update testVehicle;
        Test.stopTest();
        
        System.assert(!exceptionCaught);
    }
}