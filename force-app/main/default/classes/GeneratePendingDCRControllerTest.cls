@istest
private class GeneratePendingDCRControllerTest {
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('DriveTriggerHandler');
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
    }
    
    static testMethod void createRequestForDCRTest() { 
        Test.startTest();
        
        String messageCheck = GeneratePendingDCRController.createRequestForDCR(new List<Id>{[SELECT Id FROM sked_Drive__c LIMIT 1].Id});
        Assert.isTrue(messageCheck != null);
        
        Test.stopTest();
    }  
    
    static testMethod void getDriveRecordsTest() { 
        Test.startTest();
        sked_Drive__c testDrive = [SELECT Id, sked_Travel_Time_Site_To_CO__c, sked_Travel_Time_CO_To_Site__c FROM sked_Drive__c LIMIT 1];  
        sked__Location__c testLocation = [SELECT Id, sked__GeoLocation__Latitude__s, 
                                          sked__GeoLocation__Longitude__s
                                          FROM sked__Location__c 
                                          LIMIT 1];

        List<sked_Travel_Time_Index_Item__c> items = new List<sked_Travel_Time_Index_Item__c>();
        sked_Travel_Time_Index_Item__c item1 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = testLocation.sked__GeoLocation__Latitude__s,
        	sked_From__Longitude__s = testLocation.sked__GeoLocation__Longitude__s,
        	sked_To__Latitude__s = testLocation.sked__GeoLocation__Latitude__s,
        	sked_To__Longitude__s = testLocation.sked__GeoLocation__Longitude__s,
            sked_Timezone__c = 'America/New_York'
        );
        items.add(item1);
        
        sked_Travel_Time_Index_Item__c item2 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = testLocation.sked__GeoLocation__Latitude__s,
        	sked_From__Longitude__s = testLocation.sked__GeoLocation__Longitude__s,
        	sked_To__Latitude__s = testLocation.sked__GeoLocation__Latitude__s,
        	sked_To__Longitude__s = testLocation.sked__GeoLocation__Longitude__s,
            sked_Timezone__c = 'America/New_York'
        );
        items.add(item2);
        insert items;
        
        testDrive.sked_Travel_Time_Site_To_CO__c = item1.Id;
        testDrive.sked_Travel_Time_CO_To_Site__c = item2.Id;
        update testDrive;
        
        List<Id> travelTimeIndexIds = new List<Id>{item1.Id, item2.Id};
		GeneratePendingDCRController.getData(travelTimeIndexIds, travelTimeIndexIds);  
       
        Test.stopTest();
       
    }
}