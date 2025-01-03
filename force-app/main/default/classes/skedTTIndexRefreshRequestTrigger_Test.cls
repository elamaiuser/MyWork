/* Description: This test class covers skedTravelTimeIndexRefreshRequestTrigger and related handler class */

@isTest
private class skedTTIndexRefreshRequestTrigger_Test {
    
    @isTest
    static void afterInsertUpdateContext_Test() {
        List<sked_Travel_Time_Index_Item__c> testTravelTimeIndexItems = new List<sked_Travel_Time_Index_Item__c>();
        sked_Travel_Time_Index_Item__c testTtii1;
        testTtii1 = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = 36.7450046,
            sked_From__Longitude__s = -120.4816244,
            sked_To__Latitude__s = 38.7450046,
            sked_To__Longitude__s = -122.4816244,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_SITE_TO_CO + 36.7450046 + ':' + -120.4816244,
            sked_Timezone__c = 'America/New_York'
        );
        testTravelTimeIndexItems.add(testTtii1);
        
        testTtii1 = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = 36.74500455,
            sked_From__Longitude__s = -120.4816344,
            sked_To__Latitude__s = 38.7450146,
            sked_To__Longitude__s = -122.4826244,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_SITE_TO_CO + 36.74500455 + ':' + -120.4816344,
            sked_Timezone__c = 'America/New_York'
        );
        testTravelTimeIndexItems.add(testTtii1);
        
        insert testTravelTimeIndexItems;

        Location fromLoc1 = Location.newInstance(testTravelTimeIndexItems[0].sked_From__Latitude__s, testTtii1.sked_From__Longitude__s);
        Location toLoc1 = Location.newInstance(testTravelTimeIndexItems[0].sked_To__Latitude__s, testTtii1.sked_To__Longitude__s);
        Location fromLoc2 = Location.newInstance(testTravelTimeIndexItems[1].sked_From__Latitude__s, testTtii1.sked_From__Longitude__s);
        Location toLoc2 = Location.newInstance(testTravelTimeIndexItems[1].sked_To__Latitude__s, testTtii1.sked_To__Longitude__s);
        
        List<sked_Travel_Time_Index_Refresh_Group__c> testTTIRefreshGroupList = new List<sked_Travel_Time_Index_Refresh_Group__c>();
        
        sked_Travel_Time_Index_Refresh_Group__c testTTIRefreshGroup;
        testTTIRefreshGroup = new sked_Travel_Time_Index_Refresh_Group__c(
        	sked_Collection_Operations_To_Refresh__c = 'Adrian MI;Anaheim CA;Baltimore MD'
        );
        testTTIRefreshGroupList.add(testTTIRefreshGroup);
        
        testTTIRefreshGroup = new sked_Travel_Time_Index_Refresh_Group__c(
        	sked_Collection_Operations_To_Refresh__c = 'Boise ID',
            sked_Status__c = skedConstants.TRAVEL_TIME_INDEX_REFRESH_GROUP_STATUS_PENDING
        );
        testTTIRefreshGroupList.add(testTTIRefreshGroup);
        insert testTTIRefreshGroupList;
		
        Test.startTest();
        
        List<sked_Travel_Time_Index_Refresh_Request__c> testItems = new List<sked_Travel_Time_Index_Refresh_Request__c>();
        sked_Travel_Time_Index_Refresh_Request__c testTtirr;
        
        testTtirr = new sked_Travel_Time_Index_Refresh_Request__c(  
            sked_Record_Ids__c = testTravelTimeIndexItems[0].Id,
            sked_Origins__c = skedTravelTimeIndexItemUtils.getKey(fromLoc1),
            sked_Destinations__c = skedTravelTimeIndexItemUtils.getKey(toLoc1),
            sked_Request_Type__c = 'Travel Time',
            sked_Status__c = 'Pending',
            sked_Run_Id__c = '1'
        );
        testItems.add(testTtirr);
        
        testTtirr = new sked_Travel_Time_Index_Refresh_Request__c(  
            sked_Record_Ids__c = testTravelTimeIndexItems[1].Id,
            sked_Origins__c = skedTravelTimeIndexItemUtils.getKey(fromLoc2),
            sked_Destinations__c = skedTravelTimeIndexItemUtils.getKey(toLoc2),
            sked_Travel_Time_Index_Refresh_Group__c = testTTIRefreshGroupList[1].Id,
            sked_Request_Type__c = 'Travel Time',
            sked_Status__c = 'Pending',
            sked_Run_Id__c = '2'
        );
        testItems.add(testTtirr);
        
        insert testItems;
        
        testItems[0].sked_Status__c = 'Completed';
        testItems[1].sked_Status__c = 'In Progress';
        testItems[0].sked_Travel_Time_Index_Refresh_Group__c = testTTIRefreshGroupList[0].Id;
        update testItems;
        
        Test.stopTest();
    }

}