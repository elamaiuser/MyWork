@isTest
private class skedTravelTimeIndexDistanceBatch_Test {

    static testmethod void mainTest() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        setupTestData();
        
        Test.startTest();
        
        Database.executeBatch(new skedTravelTimeIndexTravelDistanceBatch(), 1);
        
        Test.stopTest();
    }
    
    static testmethod void testErrorHandler() {
        setupTestData();
        
        Test.startTest();
        
        Database.executeBatch(new skedTravelTimeIndexTravelDistanceBatch(), 1);
        
        Test.stopTest();
    }
    
    private static void setupTestData() {
        List<sked_Travel_Time_Index_Item__c> items = new List<sked_Travel_Time_Index_Item__c>();
        
        sked_Travel_Time_Index_Item__c item1 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = 44.797734,
        	sked_From__Longitude__s = -68.806554,
        	sked_To__Latitude__s = 44.175623,
        	sked_To__Longitude__s = -68.416157,
            sked_Timezone__c = 'America/New_York'
        );
        items.add(item1);
        
        sked_Travel_Time_Index_Item__c item2 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = 44.797735,
        	sked_From__Longitude__s = -68.806555,
        	sked_To__Latitude__s = 44.175623,
        	sked_To__Longitude__s = -68.416157,
            sked_Timezone__c = 'America/New_York'
        );
        items.add(item2);
        
        insert items;
        
        Set<string> indexItemIds = new Set<string>();
        indexItemIds.add(item1.Id);
        indexItemIds.add(item2.Id);
        
        Location fromLoc1 = Location.newInstance(item1.sked_From__Latitude__s, item1.sked_From__Longitude__s);
        Location fromLoc2 = Location.newInstance(item2.sked_From__Latitude__s, item2.sked_From__Longitude__s);

        Set<string> origins = new Set<string>();
        origins.add(skedTravelTimeIndexItemUtils.getKey(fromLoc1));
        origins.add(skedTravelTimeIndexItemUtils.getKey(fromLoc2));
        
        Location toLoc1 = Location.newInstance(item1.sked_To__Latitude__s, item1.sked_To__Longitude__s);

        Set<string> destinations = new Set<string>();
        destinations.add(skedTravelTimeIndexItemUtils.getKey(toLoc1));
        
        sked_Travel_Time_Index_Refresh_Request__c request = new sked_Travel_Time_Index_Refresh_Request__c(
            sked_Record_Ids__c = string.join(indexItemIds, ';'),
            sked_Origins__c = string.join(origins, ';'),
            sked_Destinations__c = string.join(destinations, ';'),
            sked_Request_Type__c = 'Travel Distance',
            sked_Status__c = 'Pending'
        );
        insert request;
    }
    
}