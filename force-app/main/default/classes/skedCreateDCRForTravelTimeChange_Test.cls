@isTest
private class skedCreateDCRForTravelTimeChange_Test {
    @isTest
    static void skedCreateDCRForTravelTimeChange_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c)mapTestData.get('testStagingLocation1');

        Test.startTest();
        
        List<sked_Travel_Time_Index_Item__c> items = new List<sked_Travel_Time_Index_Item__c>();
        
        sked_Travel_Time_Index_Item__c item1 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = testLocation1.sked__GeoLocation__Latitude__s,
        	sked_From__Longitude__s = testLocation1.sked__GeoLocation__Longitude__s,
        	sked_To__Latitude__s = testStagingLocation1.sked_Geolocation__Latitude__s,
        	sked_To__Longitude__s = testStagingLocation1.sked_Geolocation__Longitude__s,
            sked_Timezone__c = 'America/New_York'
        );
        items.add(item1);
        
        sked_Travel_Time_Index_Item__c item2 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = testStagingLocation1.sked_Geolocation__Latitude__s,
        	sked_From__Longitude__s = testStagingLocation1.sked_Geolocation__Longitude__s,
        	sked_To__Latitude__s = testLocation1.sked__GeoLocation__Latitude__s,
        	sked_To__Longitude__s = testLocation1.sked__GeoLocation__Longitude__s,
            sked_Timezone__c = 'America/New_York'
        );
        items.add(item2);
        
        insert items;
        
        testDrive1.sked_Travel_Time_Site_To_CO__c = item1.Id;
        testDrive1.sked_Travel_Time_CO_To_Site__c = item2.Id;
        update testDrive1;
        
        Set<Id> indexIds = new Set<Id>();
        indexIds.add(item1.Id);
        Database.executeBatch(new skedCreateDCRForTravelTimeChangeBatch(indexIds, new Set<Id>()));

        Test.stopTest();
    }
}