@isTest
private class skedImmediateRefreshTTIIndexBatch_Test {
    static testmethod void mainTest() {
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
        
        List<Id> itemIds = new List<Id>();
        for (sked_Travel_Time_Index_Item__c item : items) {
            itemIds.add(item.Id);
        }
        Database.executeBatch(new skedImmediateRefreshTravelTimeIndexBatch(itemIds, skedSetting.instance.TravelTime.newIndexPriority), 200);
        
        Test.stopTest();
    }
}