@isTest
private class skedNightlyRefreshTTIndexBatch_Test {
    static testmethod void mainTest() {
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
        List<Id> itemIds = new List<Id>{item3.Id};
        List<sked_Travel_Time_Index_Refresh_Request__c> requests = [SELECT sked_Record_Ids__c, CreatedDate FROM sked_Travel_Time_Index_Refresh_Request__c];

        System.assertEquals(2, ttiiRefreshRequestCount);
        for (sked_Travel_Time_Index_Refresh_Request__c request : requests) {
            if (request.sked_Record_Ids__c.contains(item3.Id)) {
                System.assert(false, 'Request with user overrided travel time index item should not be created');
            }
        }
    }
    
    static testmethod void testNoParamConstructor() {
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
        List<Id> itemIds = new List<Id>{item3.Id};
        List<sked_Travel_Time_Index_Refresh_Request__c> requests = [SELECT sked_Record_Ids__c FROM sked_Travel_Time_Index_Refresh_Request__c];

        System.assertEquals(2, ttiiRefreshRequestCount);
        for (sked_Travel_Time_Index_Refresh_Request__c request : requests) {
            if (request.sked_Record_Ids__c.contains(item3.Id)) {
                System.assert(false, 'Request with user overrided travel time index item should not be created');
            }
        }
    }
    
    static testMethod void testScheduleBatch() {
        Test.startTest();
        SchedulableContext scon;
        skedNightlyRefreshTravelTimeIndexBatch batchInstance = new skedNightlyRefreshTravelTimeIndexBatch();
        batchInstance.execute(scon);
        Test.stopTest();
    }
}