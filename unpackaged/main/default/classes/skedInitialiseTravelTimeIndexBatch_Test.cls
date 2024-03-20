@isTest
private class skedInitialiseTravelTimeIndexBatch_Test {
    
    static testmethod void mainTest() {
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
            sked_Geolocation__Longitude__s = -122.481626
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
            
        Test.startTest();
        
        Database.executeBatch(new skedInitialiseTravelTimeIndexBatch());
        
        Test.stopTest();
    }

}