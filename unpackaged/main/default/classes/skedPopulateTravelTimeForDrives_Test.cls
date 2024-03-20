@isTest
private class skedPopulateTravelTimeForDrives_Test {

    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c)mapTestData.get('testStagingLocation1');
        
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
        
        Test.startTest();
        
        Database.executeBatch(new skedPopulateTravelTimeForDrives());
        
        Test.stopTest();
    }
    
}