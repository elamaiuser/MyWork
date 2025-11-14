@isTest
private class skedTravelTimeIndexItemHandler_Test {
    
    static testmethod void mainTest() {
        sked_Travel_Time_Manager__c travelTimeManager = sked_Travel_Time_Manager__c.getOrgDefaults();
        travelTimeManager.sked_Drive_Impact_Threshold__c = 15;
        travelTimeManager.sked_Refresh_Interval__c = 90;
        upsert travelTimeManager;
        
        Test.startTest();
        
        sked_Travel_Time_Index_Item__c item = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = 44.7977342,
        	sked_From__Longitude__s = -68.8065538,
        	sked_To__Latitude__s = 44.175623,
        	sked_To__Longitude__s = -68.416157,
            sked_Timezone__c = 'America/New_York',
            sked_Average_Travel_Time__c = 15
        );
        insert item;
        
        item.sked_Average_Travel_Time__c = 30;
        update item;
        
        Test.stopTest();
    }
    
}