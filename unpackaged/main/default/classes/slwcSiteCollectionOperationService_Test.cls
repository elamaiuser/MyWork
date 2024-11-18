@isTest
private class slwcSiteCollectionOperationService_Test {
    @isTest
    static void manualRefreshTravelTimeIndexes_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Location__c testSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked_Site_Collection_Operation__c testSco = (sked_Site_Collection_Operation__c) mapTestData.get('testLocation1_testCollectionOperation1');
        sked_Staging_Location__c testStagingLoc = (sked_Staging_Location__c) mapTestData.get('testStagingLocation1');

        sked_Travel_Time_Index_Item__c testTtii = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = testSite.sked__Geolocation__Latitude__s,
            sked_From__Longitude__s = testSite.sked__Geolocation__Longitude__s,
            sked_To__Latitude__s = testStagingLoc.sked_Geolocation__Latitude__s,
            sked_To__Longitude__s = testStagingLoc.sked_Geolocation__Longitude__s,
            sked_Timezone__c = 'America/New_York'
        );
        insert testTtii;

        Test.startTest();
            slwcSiteCollectionOperationService.manualRefreshTravelTimeIndexes(testSco.Id);
        Test.stopTest();
    }

    @isTest
    static void hasInvalidTravelTimeData_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Location__c testSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked_Site_Collection_Operation__c testSco = (sked_Site_Collection_Operation__c) mapTestData.get('testLocation1_testCollectionOperation1');
        sked_Staging_Location__c testStagingLoc = (sked_Staging_Location__c) mapTestData.get('testStagingLocation1');

        sked_Travel_Time_Index_Item__c testTtii = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = testSite.sked__Geolocation__Latitude__s,
            sked_From__Longitude__s = testSite.sked__Geolocation__Longitude__s,
            sked_To__Latitude__s = testStagingLoc.sked_Geolocation__Latitude__s,
            sked_To__Longitude__s = testStagingLoc.sked_Geolocation__Longitude__s,
            sked_Timezone__c = 'America/New_York'
        );
        insert testTtii;

        Assert.isTrue(slwcSiteCollectionOperationService.hasInvalidTravelTimeData(testSco.Id));
    }

    @isTest
    static void isManualRefreshInProgress_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked_Site_Collection_Operation__c testSco = (sked_Site_Collection_Operation__c) mapTestData.get('testLocation1_testCollectionOperation1');

        sked_Travel_Time_Index_Refresh_Request__c testTtirr = new sked_Travel_Time_Index_Refresh_Request__c(
            sked_Manual_Refresh_SCO_Id__c = testSco.Id,
            sked_Status__c = 'Pending'
        );
        insert testTtirr;

        Assert.isTrue(slwcSiteCollectionOperationService.isManualRefreshInProgress(testSco.Id));
    }
}