@isTest
private class skedRoleTimeCalculator_Test {

    private static Map<String, sObject> setupBaseDriveData() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_No_Travel_Time__c = false;
        update collectionOperation;

        return testData;
    }

    private static sked_Drive__c queryDrive(Id driveId) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Collection_Operation__c,
                sked_Travel_Time_Included__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    @isTest
    static void testCalculateDriveRoleTimeData_appliesRoleTimeDetailAndVariance() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);
        sked__Location__c driveSite = [SELECT Id, sked_Travel_Time_to_Staging_Location__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s FROM sked__Location__c WHERE Id = :drive.sked_Drive_Site__c];
        Biomed_Collection_Op_Center__c collectionOperation = [
            SELECT Id, sked_No_Travel_Time__c,
                (SELECT Id, sked_Start_Date__c, sked_End_Date__c,
                    sked_Staging_Location__r.sked_GeoLocation__Latitude__s, sked_Staging_Location__r.sked_GeoLocation__Longitude__s
                 FROM sked_Collection_Op_Staging_Locations__r)
            FROM Biomed_Collection_Op_Center__c WHERE Id = :drive.sked_Collection_Operation__c
        ];

        sked_Role_Time_Detail__c rtd = new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Resource_Role_Group__c = skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES,
            sked_Days_of_Week__c = 'Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday',
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_MOBILE,
            sked_Mobile_Type__c = 'Inside',
            sked_Lead_Time__c = 10,
            sked_Setup_Time__c = 20,
            sked_Breakdown_Time__c = 15,
            sked_Wrap_up_Time__c = 5
        );
        insert rtd;
        Map<String, sked_Role_Time_Detail__c> roleGroupTimeDetailMap = new Map<String, sked_Role_Time_Detail__c>{
            skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES => rtd
        };

        sked_Role_Time_Variance__c rtv = new sked_Role_Time_Variance__c(
            sked_Resource_Role_Group__c = skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES,
            sked_Location__c = drive.sked_Drive_Site__c,
            sked_Days_Of_Week__c = 'Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday',
            sked_Effective_Start_Date__c = drive.sked_Drive_Date__c.addDays(-1),
            sked_Effective_End_Date__c = drive.sked_Drive_Date__c.addDays(1),
            sked_Buffer_Type__c = 'Add',
            sked_Variance_Applies_to__c = 'Lead Time',
            sked_Variation_Amount__c = 5,
            sked_Variation_Type__c = 'Elevator'
        );
        insert rtv;
        Map<String, List<sked_Role_Time_Variance__c>> roleGroupTimeVarianceMap = new Map<String, List<sked_Role_Time_Variance__c>>{
            skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES => new List<sked_Role_Time_Variance__c>{ rtv }
        };

        Test.startTest();
        Map<String, skedRoleTimeData> result = skedRoleTimeCalculator.calculateDriveRoleTimeData(
            drive, roleGroupTimeDetailMap, roleGroupTimeVarianceMap, collectionOperation, driveSite,
            new Map<String, sked_Travel_Time_Index_Item__c>(), UserInfo.getTimeZone().getID());
        Test.stopTest();

        skedRoleTimeData staffRoleTimeData = result.get(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES);
        System.assertEquals(15, staffRoleTimeData.leadTime, 'Lead time must be the RTD base value plus the RTV addition (10 + 5)');
        System.assertEquals(20, staffRoleTimeData.setupTime, 'Setup time must come straight from the RTD with no variance applied');
        System.assertEquals(15, staffRoleTimeData.breakdownTime, 'Breakdown time must come straight from the RTD');
        System.assertEquals(5, staffRoleTimeData.wrapUpTime, 'Wrap-up time must come straight from the RTD');
    }

    @isTest
    static void testCalculateDriveRoleTimeData_noMatchingTravelTimeIndexItem_fallsBackToSiteFlatTravelTime() {
        Map<String, sObject> testData = setupBaseDriveData();
        sked_Drive__c drive = queryDrive(((sked_Drive__c) testData.get('testDrive1')).Id);
        sked__Location__c driveSite = [SELECT Id, sked_Travel_Time_to_Staging_Location__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s FROM sked__Location__c WHERE Id = :drive.sked_Drive_Site__c];
        Biomed_Collection_Op_Center__c collectionOperation = [
            SELECT Id, sked_No_Travel_Time__c,
                (SELECT Id, sked_Start_Date__c, sked_End_Date__c,
                    sked_Staging_Location__r.sked_GeoLocation__Latitude__s, sked_Staging_Location__r.sked_GeoLocation__Longitude__s
                 FROM sked_Collection_Op_Staging_Locations__r)
            FROM Biomed_Collection_Op_Center__c WHERE Id = :drive.sked_Collection_Operation__c
        ];

        Test.startTest();
        Map<String, skedRoleTimeData> result = skedRoleTimeCalculator.calculateDriveRoleTimeData(
            drive, new Map<String, sked_Role_Time_Detail__c>(), new Map<String, List<sked_Role_Time_Variance__c>>(),
            collectionOperation, driveSite, new Map<String, sked_Travel_Time_Index_Item__c>(), UserInfo.getTimeZone().getID());
        Test.stopTest();

        skedRoleTimeData staffRoleTimeData = result.get(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES);
        System.assertEquals(15, staffRoleTimeData.travelTime, 'With no matching Travel Time Index Item, travel time must fall back to the site\'s flat travelTimeToStagingLocation');
        System.assertEquals(15, staffRoleTimeData.travelTime2, 'With no matching Travel Time Index Item, return travel time must fall back to the site\'s flat travelTimeToStagingLocation');
    }

    @isTest
    static void testCalculateMinMaxRoleTimeDuration_filterExcludesDrivingRoles_travelTimeStillExcludedWhenGateOff() {
        skedRoleTimeData drivingRoleData = new skedRoleTimeData();
        drivingRoleData.leadTime = 100;
        drivingRoleData.travelTime = 999;
        skedRoleTimeData staffRoleData = new skedRoleTimeData();
        staffRoleData.leadTime = 10;
        staffRoleData.travelTime = 20;
        Map<String, skedRoleTimeData> roleTimeDataMap = new Map<String, skedRoleTimeData>{
            skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES => drivingRoleData,
            skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES => staffRoleData
        };

        Test.startTest();
        skedRoleTimeCalculator.RoleTimeDurationRange range = skedRoleTimeCalculator.calculateMinMaxRoleTimeDuration(
            roleTimeDataMap, new List<String>{ skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES }, false);
        Test.stopTest();

        System.assertEquals(10, range.maxDurationBefore,
            'A filter excluding Driving roles must ignore that group entirely, and includeTravelTime=false must exclude travelTime from the remaining group\'s duration - leaving just leadTime (10)');
    }

    @isTest
    static void testCalculateMinMaxRoleTimeDuration_includeTravelTimeTrue_addsTravelTimeToDuration() {
        skedRoleTimeData roleData = new skedRoleTimeData();
        roleData.leadTime = 10;
        roleData.travelTime = 20;
        roleData.breakdownTime = 5;
        roleData.travelTime2 = 8;
        Map<String, skedRoleTimeData> roleTimeDataMap = new Map<String, skedRoleTimeData>{
            skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES => roleData
        };

        Test.startTest();
        skedRoleTimeCalculator.RoleTimeDurationRange range = skedRoleTimeCalculator.calculateMinMaxRoleTimeDuration(
            roleTimeDataMap, new List<String>(), true);
        Test.stopTest();

        System.assertEquals(30, range.maxDurationBefore, 'includeTravelTime=true must add travelTime (20) on top of leadTime (10)');
        System.assertEquals(13, range.maxDurationAfter, 'includeTravelTime=true must add travelTime2 (8) on top of breakdownTime (5)');
    }
}
