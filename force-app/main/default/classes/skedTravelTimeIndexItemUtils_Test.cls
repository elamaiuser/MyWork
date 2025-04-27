@isTest
private class skedTravelTimeIndexItemUtils_Test {
    
    static testmethod void getKey_Test() {
        Location loc1 = Location.newInstance(44.797734, -68.806554);
        Location loc2 = Location.newInstance(44.175623, -68.416157);
		skedTravelTimeIndexItemUtils.getKey(loc1);
        skedTravelTimeIndexItemUtils.getKey(loc1, loc2);
    }

    static testmethod void getTravelTimeIndexItemsByKey_Test() {
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
        
        Test.startTest();
        
        Location fromLoc1 = Location.newInstance(44.797734, -68.806554);
        Location fromLoc2 = Location.newInstance(44.797735, -68.806555);
        
        Location toLoc = Location.newInstance(44.175623, -68.416157);

        Set<string> keys = new Set<string>();
        keys.add(skedTravelTimeIndexItemUtils.getKey(fromLoc1, toLoc));
        keys.add(skedTravelTimeIndexItemUtils.getKey(fromLoc1, toLoc));
        
        skedTravelTimeIndexItemUtils.getTravelTimeIndexItemsByKey(keys);
        
        Test.stopTest();
    }

    static testmethod void createTravelTimeIndexItems_Test() {
        sked_Travel_Time_Index_Item__c item = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = 44.797734,
        	sked_From__Longitude__s = -68.806554,
        	sked_To__Latitude__s = 44.175623,
        	sked_To__Longitude__s = -68.416157,
            sked_Timezone__c = 'America/New_York'
        );
        insert item;
        
        Test.startTest();
        
        List<skedTravelTimeIndexItemUtils.TravelTimeIndexItem> models = new List<skedTravelTimeIndexItemUtils.TravelTimeIndexItem>();
        
        skedTravelTimeIndexItemUtils.TravelTimeIndexItem model1 = new skedTravelTimeIndexItemUtils.TravelTimeIndexItem(
            Location.newInstance(44.797734, -68.806554),
            Location.newInstance(44.175623, -68.416157),
            'America/New_York',
            skedConstants.TTII_DIRECTION_SITE_TO_CO
        );
        models.add(model1);
        
        skedTravelTimeIndexItemUtils.TravelTimeIndexItem model2 = new skedTravelTimeIndexItemUtils.TravelTimeIndexItem(
            Location.newInstance(44.797735, -68.806555),
            Location.newInstance(44.175623, -68.416157),
            'America/New_York',
            skedConstants.TTII_DIRECTION_SITE_TO_CO
        );
        models.add(model2);
        
        skedTravelTimeIndexItemUtils.createTravelTimeIndexItems(models);
        
        Test.stopTest();
    }
}