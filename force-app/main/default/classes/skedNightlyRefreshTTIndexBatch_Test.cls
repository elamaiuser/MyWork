@isTest
private class skedNightlyRefreshTTIndexBatch_Test {

    private static final Decimal STAGING_LAT = 44.797735;
    private static final Decimal STAGING_LNG = -68.806555;

    private static void setupCOWithStagingLocation(Date nextRefreshDate) {
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c(
            Name = 'Test Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Next_Travel_Time_Refresh_Date__c = nextRefreshDate
        );
        insert co;

        sked_Staging_Location__c stagingLoc = new sked_Staging_Location__c(
            sked_Address__c = '100 Test Lane',
            sked_Geolocation__Latitude__s = STAGING_LAT,
            sked_Geolocation__Longitude__s = STAGING_LNG
        );
        insert stagingLoc;

        sked_Collection_Op_Staging_Location__c cosl = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = co.Id,
            sked_Staging_Location__c = stagingLoc.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert cosl;
    }

    static testmethod void mainTest() {
        setupCOWithStagingLocation(null);

        List<sked_Travel_Time_Index_Item__c> items = new List<sked_Travel_Time_Index_Item__c>();

        sked_Travel_Time_Index_Item__c item1 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = 44.797735,
        	sked_From__Longitude__s = -68.806555,
        	sked_To__Latitude__s = 44.175623,
        	sked_To__Longitude__s = -68.416157,
            sked_Timezone__c = 'America/New_York'
        );
        item1.sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_CO_TO_SITE, Location.newInstance(item1.sked_From__Latitude__s, item1.sked_From__Longitude__s));
        items.add(item1);

        sked_Travel_Time_Index_Item__c item2 = new sked_Travel_Time_Index_Item__c (
        	sked_To__Latitude__s = 44.797735,
        	sked_To__Longitude__s = -68.806555,
        	sked_From__Latitude__s = 44.175623,
        	sked_From__Longitude__s = -68.416157,
            sked_Timezone__c = 'America/New_York'
        );
        item2.sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_SITE_TO_CO, Location.newInstance(item2.sked_From__Latitude__s, item2.sked_From__Longitude__s));
        items.add(item2);

        sked_Travel_Time_Index_Item__c item3 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = 44.797736,
        	sked_From__Longitude__s = -68.806556,
        	sked_To__Latitude__s = 44.175624,
        	sked_To__Longitude__s = -68.416158,
            sked_Timezone__c = 'America/New_York',
            User_Override__c = true
        );
        item3.sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_CO_TO_SITE, Location.newInstance(item1.sked_From__Latitude__s, item1.sked_From__Longitude__s));
        items.add(item3);

        sked_Travel_Time_Index_Item__c item4 = new sked_Travel_Time_Index_Item__c (
        	sked_To__Latitude__s = 44.797736,
        	sked_To__Longitude__s = -68.806556,
        	sked_From__Latitude__s = 44.175624,
        	sked_From__Longitude__s = -68.416158,
            sked_Timezone__c = 'America/New_York',
            User_Override__c = false
        );
        item4.sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_SITE_TO_CO, Location.newInstance(item2.sked_From__Latitude__s, item2.sked_From__Longitude__s));
        items.add(item4);

        insert items;

        Test.startTest();
        Database.executeBatch(new skedNightlyRefreshTravelTimeIndexBatch(true), 200);
        Test.stopTest();

        Integer ttiiRefreshRequestCount = [SELECT COUNT() FROM sked_Travel_Time_Index_Refresh_Request__c];
        List<sked_Travel_Time_Index_Refresh_Request__c> requests = [SELECT sked_Record_Ids__c, CreatedDate FROM sked_Travel_Time_Index_Refresh_Request__c];

        System.assertEquals(2, ttiiRefreshRequestCount);
        for (sked_Travel_Time_Index_Refresh_Request__c request : requests) {
            if (request.sked_Record_Ids__c.contains(item3.Id)) {
                System.assert(false, 'Request with user overrided travel time index item should not be created');
            }
        }
    }

    static testmethod void testNoParamConstructor() {
        setupCOWithStagingLocation(null);

        List<sked_Travel_Time_Index_Item__c> items = new List<sked_Travel_Time_Index_Item__c>();

        sked_Travel_Time_Index_Item__c item1 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = 44.797735,
        	sked_From__Longitude__s = -68.806555,
        	sked_To__Latitude__s = 44.175623,
        	sked_To__Longitude__s = -68.416157,
            sked_Timezone__c = 'America/New_York'
        );
        item1.sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_CO_TO_SITE, Location.newInstance(item1.sked_From__Latitude__s, item1.sked_From__Longitude__s));
        items.add(item1);

        sked_Travel_Time_Index_Item__c item2 = new sked_Travel_Time_Index_Item__c (
        	sked_To__Latitude__s = 44.797735,
        	sked_To__Longitude__s = -68.806555,
        	sked_From__Latitude__s = 44.175623,
        	sked_From__Longitude__s = -68.416157,
            sked_Timezone__c = 'America/New_York'
        );
        item2.sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_SITE_TO_CO, Location.newInstance(item2.sked_From__Latitude__s, item2.sked_From__Longitude__s));
        items.add(item2);

        sked_Travel_Time_Index_Item__c item3 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = 44.797736,
        	sked_From__Longitude__s = -68.806556,
        	sked_To__Latitude__s = 44.175624,
        	sked_To__Longitude__s = -68.416158,
            sked_Timezone__c = 'America/New_York',
            User_Override__c = true
        );
        item3.sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_CO_TO_SITE, Location.newInstance(item1.sked_From__Latitude__s, item1.sked_From__Longitude__s));
        items.add(item3);

        sked_Travel_Time_Index_Item__c item4 = new sked_Travel_Time_Index_Item__c (
        	sked_To__Latitude__s = 44.797736,
        	sked_To__Longitude__s = -68.806556,
        	sked_From__Latitude__s = 44.175624,
        	sked_From__Longitude__s = -68.416158,
            sked_Timezone__c = 'America/New_York',
            User_Override__c = false
        );
        item4.sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_SITE_TO_CO, Location.newInstance(item2.sked_From__Latitude__s, item2.sked_From__Longitude__s));
        items.add(item4);

        insert items;

        Test.startTest();
        Database.executeBatch(new skedNightlyRefreshTravelTimeIndexBatch(), 200);
        Test.stopTest();

        Integer ttiiRefreshRequestCount = [SELECT COUNT() FROM sked_Travel_Time_Index_Refresh_Request__c];
        List<sked_Travel_Time_Index_Refresh_Request__c> requests = [SELECT sked_Record_Ids__c FROM sked_Travel_Time_Index_Refresh_Request__c];

        System.assertEquals(2, ttiiRefreshRequestCount);
        for (sked_Travel_Time_Index_Refresh_Request__c request : requests) {
            if (request.sked_Record_Ids__c.contains(item3.Id)) {
                System.assert(false, 'Request with user overrided travel time index item should not be created');
            }
        }
    }

    static testmethod void testPostProcess() {
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c(
            Name = 'Test Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Next_Travel_Time_Refresh_Date__c = Date.today()
        );
        insert co;

        sked_Staging_Location__c stagingLoc = new sked_Staging_Location__c(
            sked_Address__c = '100 Test Lane',
            sked_Geolocation__Latitude__s = STAGING_LAT,
            sked_Geolocation__Longitude__s = STAGING_LNG
        );
        insert stagingLoc;

        sked_Collection_Op_Staging_Location__c cosl = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = co.Id,
            sked_Staging_Location__c = stagingLoc.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert cosl;

        // TTII already refreshed today — sked_Is_Sync_Refresh_Required__c will be FALSE
        // because DATEVALUE(now) < today evaluates to false
        sked_Travel_Time_Index_Item__c ttii = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = STAGING_LAT,
            sked_From__Longitude__s = STAGING_LNG,
            sked_To__Latitude__s = 44.175623,
            sked_To__Longitude__s = -68.416157,
            sked_Timezone__c = 'America/New_York',
            sked_Collection_Operation__c = co.Id,
            sked_Last_Refresh_Date__c = DateTime.now()
        );
        ttii.sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(
            skedConstants.TTII_DIRECTION_CO_TO_SITE,
            Location.newInstance(STAGING_LAT, STAGING_LNG)
        );
        insert ttii;

        Test.startTest();
        Database.executeBatch(new skedNightlyRefreshTravelTimeIndexBatch(true), 200);
        Test.stopTest();

        Biomed_Collection_Op_Center__c updatedCo = [
            SELECT sked_Next_Travel_Time_Refresh_Date__c
            FROM Biomed_Collection_Op_Center__c
            WHERE Id = :co.Id
        ];
        Integer refreshInterval = skedSetting.instance.TravelTime.refreshInterval;
        System.assertEquals(Date.today().addDays(refreshInterval), updatedCo.sked_Next_Travel_Time_Refresh_Date__c,
            'sked_Next_Travel_Time_Refresh_Date__c should be advanced by the refresh interval');
    }

    static testMethod void testScheduleBatch() {
        Test.startTest();
        SchedulableContext scon;
        skedNightlyRefreshTravelTimeIndexBatch batchInstance = new skedNightlyRefreshTravelTimeIndexBatch();
        batchInstance.execute(scon);
        Test.stopTest();
    }
}