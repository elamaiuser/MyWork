@isTest
public with sharing class skedUpdateTTILookupFieldsOnSiteCO_Test {

    @testSetup
    static void prepareTestDataSet() {
        List<sObject> firstList = new List<sObject>();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30'
        );
        firstList.add(testCollectionOperation1);
        
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Address__c = '110 Test Lane, Test Avenue, 10101',
        	sked_Geolocation__Latitude__s = 37.7450047,
            sked_Geolocation__Longitude__s = -122.481626,
            sked_Timezone__c= 'America/New_York'
        );
        firstList.add(testStagingLocation1);
        
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked_Address_1__c = 'Inner Parkside', 
            sked_City__c = 'San Francisco', 
            sked_State__c = 'CA', 
            sked_Zip_Code__c = '94116', 
            sked_County__c = 'USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Timezone__c = 'America/New_York',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );
        firstList.add(testLocation1);
        insert firstList;
        
        List<sObject> secondList = new List<sObject>();
        sked_Site_Collection_Operation__c testSiteCO = new sked_Site_Collection_Operation__c(
        	sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Site__c = testLocation1.Id,
            sked_Travel_Time_Breakdown_JSON__c = 'JSON DATA', 
            sked_Travel_Time_Breakdown_JSON_2__c = 'JSON DATA', 
            sked_Travel_Distance_1__c = 10, 
            sked_Travel_Distance_2__c = 11,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        secondList.add(testSiteCO);
        
        sked_Collection_Op_Staging_Location__c testCollectionOpStagingLoc1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        secondList.add(testCollectionOpStagingLoc1);
        insert secondList;

        List<sObject> thirdList = new List<sObject>();
        
        sked__Location__c testLocationWithGeo = [SELECT Id, sked__GeoLocation__c FROM sked__Location__c WHERE Id = :testLocation1.Id LIMIT 1];
        sked_Staging_Location__c testStagingLocationWithGeo = [SELECT Id, sked_GeoLocation__c FROM sked_Staging_Location__c WHERE Id = :testStagingLocation1.Id LIMIT 1];

        sked_Travel_Time_Index_Item__c newIndexItem;
        newIndexItem = new sked_Travel_Time_Index_Item__c(
            sked_Key__c = skedTravelTimeIndexItemUtils.getKey(testLocationWithGeo.sked__GeoLocation__c, testStagingLocationWithGeo.sked_GeoLocation__c),
            sked_From__Latitude__s = testLocation1.sked__GeoLocation__Latitude__s,
            sked_From__Longitude__s = testLocation1.sked__GeoLocation__Longitude__s,
            sked_To__Latitude__s = testStagingLocation1.sked_Geolocation__Latitude__s,
            sked_To__Longitude__s = testStagingLocation1.sked_GeoLocation__Longitude__s,
            sked_Travel_Time_Breakdown_JSON__c = testSiteCO.sked_Travel_Time_Breakdown_JSON__c,
            sked_Travel_Distance__c = testSiteCO.sked_Travel_Distance_1__c,
            sked_Timezone__c = testStagingLocation1.sked_Timezone__c,
            sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_SITE_TO_CO, testLocationWithGeo.sked__GeoLocation__c)
        );
        thirdList.add(newIndexItem);

        newIndexItem = new sked_Travel_Time_Index_Item__c(
            sked_Key__c = skedTravelTimeIndexItemUtils.getKey(testStagingLocationWithGeo.sked_GeoLocation__c, testLocationWithGeo.sked__GeoLocation__c),
            sked_To__Latitude__s = testLocation1.sked__GeoLocation__Latitude__s,
            sked_To__Longitude__s = testLocation1.sked__GeoLocation__Longitude__s,
            sked_From__Latitude__s = testStagingLocation1.sked_Geolocation__Latitude__s,
            sked_From__Longitude__s = testStagingLocation1.sked_GeoLocation__Longitude__s,
            sked_Travel_Time_Breakdown_JSON__c = testSiteCO.sked_Travel_Time_Breakdown_JSON__c,
            sked_Travel_Distance__c = testSiteCO.sked_Travel_Distance_1__c,
            sked_Timezone__c = testStagingLocation1.sked_Timezone__c,
            sked_Ordering_Key__c = skedTravelTimeIndexItemUtils.getOrderingKey(skedConstants.TTII_DIRECTION_CO_TO_SITE, testStagingLocationWithGeo.sked_GeoLocation__c)
        );
        thirdList.add(newIndexItem);
        skedHubBase.BypassInsertTriggers = TRUE;
        insert thirdList;
        skedHubBase.BypassInsertTriggers = FALSE;
    }

    static testMethod void batchExecutionForSiteCO_Test() {
        Test.startTest();
        Database.executeBatch(new skedUpdateTTILookupFieldsOnSiteCOBatch(true), 200);
        Test.stopTest();
        
        sked_Site_Collection_Operation__c siteCo = [SELECT Id, sked_Travel_Time_Index_Site2CO__c, sked_Travel_Time_Index_CO2Site__c 
                                                    FROM sked_Site_Collection_Operation__c LIMIT 1];
        
        Assert.isTrue(siteCo.sked_Travel_Time_Index_CO2Site__c != NULL);
        Assert.isTrue(siteCo.sked_Travel_Time_Index_Site2CO__c != NULL);
    }

    static testMethod void batchExecutionForTTI_Test() {
        Test.startTest();
        Database.executeBatch(new skedUpdateTTILookupFieldsOnSiteCOBatch(false), 200);
        Test.stopTest();
        
        sked_Site_Collection_Operation__c siteCo = [SELECT Id, sked_Travel_Time_Index_Site2CO__c, sked_Travel_Time_Index_CO2Site__c 
                                                    FROM sked_Site_Collection_Operation__c LIMIT 1];
        
        Assert.isTrue(siteCo.sked_Travel_Time_Index_CO2Site__c != NULL);
        Assert.isTrue(siteCo.sked_Travel_Time_Index_Site2CO__c != NULL);
    }
    
    static testMethod void batchExecutionScheduled_Test() {
        Test.startTest();
        skedUpdateTTILookupFieldsOnSiteCOBatch batchInstance = new skedUpdateTTILookupFieldsOnSiteCOBatch(false);
        SchedulableContext scon;
        batchInstance.execute(scon);
        Test.stopTest();
    }
}