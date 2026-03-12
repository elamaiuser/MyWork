@isTest
private class skedTtiiCoPopulationOneTimeBatch_Test {

    static testmethod void mainTest() {
        List<sObject> firstList = new List<sObject>();
        Biomed_Collection_Op_Center__c testCollectionOperation = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30'
        );
        firstList.add(testCollectionOperation);

        sked_Staging_Location__c testStagingLocation = new sked_Staging_Location__c(
            sked_Address__c = '110 Test Lane, Test Avenue, 10101',
            sked_Geolocation__Latitude__s = 37.7450047,
            sked_Geolocation__Longitude__s = -122.481626
        );
        firstList.add(testStagingLocation);

        sked__Location__c testLocation = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked_Address_1__c = 'Inner Parkside',
            sked_City__c = 'San Francisco',
            sked_State__c = 'CA',
            sked_Zip_Code__c = '94116',
            sked_County__c = 'USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );
        firstList.add(testLocation);
        insert firstList;

        List<sObject> secondList = new List<sObject>();
        sked_Site_Collection_Operation__c testSiteCO = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = testCollectionOperation.Id,
            sked_Site__c = testLocation.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        secondList.add(testSiteCO);

        sked_Collection_Op_Staging_Location__c testCollectionOpStagingLoc = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOperation.Id,
            sked_Staging_Location__c = testStagingLocation.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        secondList.add(testCollectionOpStagingLoc);
        insert secondList;

        Location coLoc = Location.newInstance(37.7450047, -122.481626);
        Location siteLoc = Location.newInstance(37.7450046, -122.4816244);

        sked_Travel_Time_Index_Item__c testTtii = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = coLoc.latitude,
            sked_From__Longitude__s = coLoc.longitude,
            sked_To__Latitude__s = siteLoc.latitude,
            sked_To__Longitude__s = siteLoc.longitude,
            sked_Timezone__c = 'America/New_York',
            sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(
                skedConstants.TTII_DIRECTION_CO_TO_SITE,
                coLoc
            )
        );
        insert testTtii;

        Test.startTest();
        Database.executeBatch(new skedTtiiCoPopulationOneTimeBatch(), 200);
        Test.stopTest();
    }

    static testmethod void testWithLastId() {
        sked_Travel_Time_Index_Item__c testTtii = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = 37.7450047,
            sked_From__Longitude__s = -122.481626,
            sked_To__Latitude__s = 37.7450046,
            sked_To__Longitude__s = -122.4816244,
            sked_Timezone__c = 'America/New_York',
            sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(
                skedConstants.TTII_DIRECTION_CO_TO_SITE,
                Location.newInstance(37.7450047, -122.481626)
            )
        );
        insert testTtii;

        Test.startTest();
        Database.executeBatch(new skedTtiiCoPopulationOneTimeBatch(testTtii.Id), 200);
        Test.stopTest();
    }
}