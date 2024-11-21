@isTest
private class skedAsyncJobTrigger_Test {
    @isTest
    static void afterInsert_Test() {
        sked_Travel_Time_Index_Item__c testTtii1 = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = 36.7450046,
            sked_From__Longitude__s = -120.4816244,
            sked_To__Latitude__s = 38.7450046,
            sked_To__Longitude__s = -122.4816244,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_SITE_TO_CO + 36.7450046 + ':' + -120.4816244,
            sked_Timezone__c = 'America/New_York'
        );
        insert testTtii1;

        Location fromLoc = Location.newInstance(testTtii1.sked_From__Latitude__s, testTtii1.sked_From__Longitude__s);
        Location toLoc = Location.newInstance(testTtii1.sked_To__Latitude__s, testTtii1.sked_To__Longitude__s);

        sked_Travel_Time_Index_Refresh_Request__c testTtirr = new sked_Travel_Time_Index_Refresh_Request__c(
            sked_Record_Ids__c = testTtii1.Id,
            sked_Origins__c = skedTravelTimeIndexItemUtils.getKey(fromLoc),
            sked_Destinations__c = skedTravelTimeIndexItemUtils.getKey(toLoc),
            sked_Request_Type__c = 'Travel Distance',
            sked_Status__c = 'Pending',
            sked_Run_Id__c = '1'
        );
        insert testTtirr;

        Test.startTest();
        sked__Async_Job__c testAsyncJob = new sked__Async_Job__c(
            sked_Run_Id__c = '1',
            sked__Status__c = 'Complete',
            sked__Message__c = 'test-run-id',
            sked_API_Response__c = '[{"values":[[{"status":"OK","duration":153170,"distance":0}]],"fromTime":"2021-07-06T14:00:00","toTime":"2021-07-06T17:00:00"}]'
        );
        insert testAsyncJob;
        Test.stopTest();
    }

    @isTest
    static void afterInsertException_Test() {
        sked_Travel_Time_Index_Item__c testTtii1 = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = 36.7450046,
            sked_From__Longitude__s = -120.4816244,
            sked_To__Latitude__s = 38.7450046,
            sked_To__Longitude__s = -122.4816244,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_SITE_TO_CO + 36.7450046 + ':' + -120.4816244,
            sked_Timezone__c = 'America/New_York'
        );
        insert testTtii1;

        Location fromLoc = Location.newInstance(testTtii1.sked_From__Latitude__s, testTtii1.sked_From__Longitude__s);
        Location toLoc = Location.newInstance(testTtii1.sked_To__Latitude__s, testTtii1.sked_To__Longitude__s);

        sked_Travel_Time_Index_Refresh_Request__c testTtirr = new sked_Travel_Time_Index_Refresh_Request__c(
            sked_Record_Ids__c = testTtii1.Id,
            sked_Origins__c = skedTravelTimeIndexItemUtils.getKey(fromLoc),
            sked_Destinations__c = skedTravelTimeIndexItemUtils.getKey(toLoc),
            sked_Request_Type__c = 'Travel Distance',
            sked_Status__c = 'Pending',
            sked_Run_Id__c = '1'
        );
        insert testTtirr;

        Test.startTest();
        sked__Async_Job__c testAsyncJob = new sked__Async_Job__c(
            sked_Run_Id__c = '1',
            sked__Status__c = 'Complete',
            sked__Message__c = 'test-run-id',
            sked_API_Response__c = '[{"values":[[{"status":"OK","duration":153170,"distance":0}],[{"status":"OK","duration":153170,"distance":0}]],"fromTime":"2021-07-06T14:00:00","toTime":"2021-07-06T17:00:00"}]'
        );
        insert testAsyncJob;
        Test.stopTest();
    }
}