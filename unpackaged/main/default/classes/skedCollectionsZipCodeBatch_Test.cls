@isTest
private class skedCollectionsZipCodeBatch_Test {
    @isTest
    static void batchTest() {
        sked_Admin_Setting__c skedAdminSetting = sked_Admin_Setting__c.getOrgDefaults();
        skedAdminSetting.sked_Admin_Last_Collections_Zip_Run__c = System.now().addDays(-1);
        upsert skedAdminSetting;

        Biomed_Collection_Op_Center__c testCo = new Biomed_Collection_Op_Center__c(
            Name = 'Test Collection Operation',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'external-id'
        );
        insert testCo;

        sked__Region__c testRegion = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCo.Id
        );
        insert testRegion;

        sked__Location__c testSite1 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked_Address_1__c = 'Inner Parkside', 
            sked_City__c = 'San Francisco', 
            sked_State__c = 'CA', 
            sked_Zip_Code__c = '94116', 
            sked_County__c = 'USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCo.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = System.today(),
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4321',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );

        sked__Location__c testSite2 = new sked__Location__c(
            Name = 'Test Location 2',
            sked__Address__c = 'Outer Parkside, San Francisco, CA, USA',
            sked_Address_1__c = 'Outer Parkside', 
            sked_City__c = 'San Francisco', 
            sked_State__c = 'CA', 
            sked_Zip_Code__c = '61149', 
            sked_County__c = 'USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCo.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = System.today(),
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4321',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Timezone__c = UserInfo.getTimezone().getID(),
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );

        insert new List<sked__Location__c>{testSite1, testSite2};

        Id recordTypeId = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();

        Taxonomy__c testTx1 = new Taxonomy__c(
            Collection_Operation_Name__c = 'Test Collection Operation',
            Zip_Code__c = '94116',
            Start_Date__c = Date.newInstance(2023, 1, 1),
            End_Date__c = Date.newInstance(2023, 3, 31),
            recordTypeId = recordTypeId
        );
        Taxonomy__c testTx2 = new Taxonomy__c(
            Collection_Operation_Name__c = 'Test Collection Operation',
            Zip_Code__c = '61149',
            Start_Date__c = Date.newInstance(2023, 4, 1),
            End_Date__c = Date.newInstance(2023, 8, 31),
            recordTypeId = recordTypeId
            
        );

        Taxonomy__c testTx3 = new Taxonomy__c(
            Collection_Operation_Name__c = 'Test Collection Operation',
            Zip_Code__c = '94116',
            Start_Date__c = Date.newInstance(2023, 9, 1),
            End_Date__c = Date.newInstance(2023, 12, 31),
            recordTypeId = recordTypeId
        );

        Taxonomy__c testTx4 = new Taxonomy__c(
            Collection_Operation_Name__c = 'Test Collection Operation',
            Zip_Code__c = '94116',
            Start_Date__c = Date.newInstance(2024, 1, 1),
            End_Date__c = Date.newInstance(4000, 12, 31),
            recordTypeId = recordTypeId
        );

        insert new List<Taxonomy__c>{testTx1, testTx2, testTx3, testTx4};

        Collections_Territory__c ct = new Collections_Territory__c(
            Zip__c = '94116',
            sked_Start_Date__c = Date.newInstance(2023, 9, 1),
            sked_End_Date__c = Date.newInstance(4000, 12, 31),
            Collection_Operation__c = testCo.Id
        );
        insert ct;

        sked_Site_Collection_Operation__c sco = new sked_Site_Collection_Operation__c(
            sked_Site__c = testSite1.Id,
            sked_Start_Date__c = Date.newInstance(2023, 9, 1),
            sked_End_Date__c = Date.newInstance(4000, 12, 31),
            sked_Collections_Zip_Code__c = ct.Id,
            sked_Collection_Operation__c = testCo.Id
        );
        insert sco;

        Test.startTest();
            
        Database.executeBatch(new skedCollectionsZipCodeBatch(), 4);
        
        Test.stopTest();
    }
    
}