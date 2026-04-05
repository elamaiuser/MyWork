@isTest
private class skedCollectionsZipCodeBatch_Test {
    
    /* ---------- Test Data Setup ---------- */
    @testSetup
    static void setupData() {
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
            sked_Collection_Operation__c = testCo.Id,
            sked_Travel_Time_Breakdown_JSON__c = '{"t":1}',
            sked_Travel_Time_Breakdown_JSON_2__c = '{"t":2}',
            sked_Travel_Distance_1__c = 11,
            sked_Travel_Distance_2__c = 21
        );
        insert sco;

        

    }
    @isTest
    static void batchTest() {
        
        Test.startTest();
            
        Database.executeBatch(new skedCollectionsZipCodeBatch(), 4);
        
        Test.stopTest();
    }

    /* ---------- Batch Execution ---------- */
    @IsTest
    static void testBatchExecutionAndMergeLogic() {

        Test.startTest();
        Database.executeBatch(new skedCollectionsZipCodeBatch(), 4);
        Test.stopTest();

        // Collections Territory should be MERGED
        List<Collections_Territory__c> cts = [
            SELECT Id, Zip__c, sked_Start_Date__c, sked_End_Date__c
            FROM Collections_Territory__c
            WHERE Zip__c = '94116'
        ];

        System.assertEquals(
            2,
            cts.size(),
            'Non-contiguous taxonomy ranges must produce multiple Collections_Territories'
        );

        System.assertEquals(
            Date.newInstance(2023,09,1),
            cts[0].sked_Start_Date__c
        );

        System.assertEquals(
            Date.newInstance(4000,12,31),
            cts[0].sked_End_Date__c
        );

        // Site COs should be created
        List<sked_Site_Collection_Operation__c> siteCOs = [
            SELECT Id, sked_Site__c, sked_Start_Date__c, sked_End_Date__c
            FROM sked_Site_Collection_Operation__c
        ];

        System.assert(
            siteCOs.size() > 0,
            'Site Collection Operations must be created'
        );
    }

    /* ---------- Travel Time Copy + Delete Path ---------- */
    @IsTest
    static void testRunTheBatchAgain() {

        Taxonomy__c lastTaxo = [select id from Taxonomy__c limit 1];
        sked_Site_Collection_Operation__c existing = new sked_Site_Collection_Operation__c(
            sked_Site__c = [SELECT Id FROM sked__Location__c LIMIT 1].Id,
            sked_Collection_Operation__c = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1].Id,
            sked_Start_Date__c = Date.newInstance(2023,1,1),
            sked_End_Date__c = Date.newInstance(2023,12,31),
            sked_Travel_Time_Breakdown_JSON__c = '{"t":1}',
            sked_Travel_Time_Breakdown_JSON_2__c = '{"t":2}',
            sked_Travel_Distance_1__c = 10,
            sked_Travel_Distance_2__c = 20
        );
        insert existing;

        Test.startTest();
        Database.executeBatch(new skedCollectionsZipCodeBatch(lastTaxo.Id), 4);
        Test.stopTest();
    }

    /* ---------- Travel Time Copy + Delete Path ---------- */
    @IsTest
    static void testTravelTimeCopyAndDelete() {

        sked_Site_Collection_Operation__c existing = new sked_Site_Collection_Operation__c(
            sked_Site__c = [SELECT Id FROM sked__Location__c LIMIT 1].Id,
            sked_Collection_Operation__c = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1].Id,
            sked_Start_Date__c = Date.newInstance(2023,1,1),
            sked_End_Date__c = Date.newInstance(2023,12,31),
            sked_Travel_Time_Breakdown_JSON__c = '{"t":1}',
            sked_Travel_Time_Breakdown_JSON_2__c = '{"t":2}',
            sked_Travel_Distance_1__c = 10,
            sked_Travel_Distance_2__c = 20
        );
        insert existing;

        Test.startTest();
        Database.executeBatch(new skedCollectionsZipCodeBatch(), 4);
        Test.stopTest();

        sked_Site_Collection_Operation__c updated = [
            SELECT sked_Post_Migration_Processed__c
            FROM sked_Site_Collection_Operation__c
            WHERE Id = :existing.Id
        ];

        System.assertEquals(
            true,
            updated.sked_Post_Migration_Processed__c,
            'Travel time data copy should mark record as post-migration processed'
        );
    }

    @IsTest
    static void testSchedulableExecuteCoverage() {

        // IMPORTANT: Reduce data visibility for this test
        // We want start() to return ONLY 1 record

        // Force start() to return ZERO records
        sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
        setting.sked_Admin_Last_Collections_Zip_Run__c = System.now().addDays(1);
        update setting;

        Test.startTest();

        // Schedule the job (this is what triggers execute(SchedulableContext))
        String jobId = System.schedule(
            'Test skedCollectionsZipCodeBatch Scheduler',
            '0 0 0 1 1 ? 2099',
            new skedCollectionsZipCodeBatch()
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'Schedulable job should be successfully scheduled'
        );
    }

    /* ---------- testInconsitentData ---------- */
    @IsTest
    static void testInconsitentData() {

        sked_Admin_Setting__c skedAdminSetting = sked_Admin_Setting__c.getOrgDefaults();
        skedAdminSetting.sked_Admin_Last_Collections_Zip_Run__c = System.now().addDays(-1);
        upsert skedAdminSetting;

        Biomed_Collection_Op_Center__c testCo2 = new Biomed_Collection_Op_Center__c(
            Name = 'Test Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'external-id2'
        );
        insert testCo2;
        sked__Region__c testRegion = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCo2.Id
        );
        insert testRegion;
		
        sked__Location__c testSite3 = new sked__Location__c(
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
            sked_Collection_Operation__c = testCo2.Id,
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
        insert testSite3;

        Collections_Territory__c ct1 = new Collections_Territory__c(
            Zip__c = '94116',
            sked_Start_Date__c = Date.newInstance(2023, 9, 1),
            sked_End_Date__c = Date.newInstance(4000, 12, 31),
            Collection_Operation__c = testCo2.Id
        );
        insert ct1;

        sked_Site_Collection_Operation__c existing = new sked_Site_Collection_Operation__c(
            sked_Site__c = testSite3.Id,//[SELECT Id FROM sked__Location__c LIMIT 1].Id,
            sked_Collection_Operation__c = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1].Id,
            sked_Start_Date__c = Date.newInstance(2023,1,1),
            sked_End_Date__c = Date.newInstance(2023,12,31),
            sked_Travel_Time_Breakdown_JSON__c = '{"t":1}',
            sked_Travel_Time_Breakdown_JSON_2__c = '{"t":2}',
            sked_Travel_Distance_1__c = 10,
            sked_Travel_Distance_2__c = 20
        );
        insert existing;

        Test.startTest();
        Database.executeBatch(new skedCollectionsZipCodeBatch(), 4);
        Test.stopTest();

        sked_Site_Collection_Operation__c refreshed = [
            SELECT Id,
                sked_Post_Migration_Processed__c,
                sked_Start_Date__c,
                sked_End_Date__c
            FROM sked_Site_Collection_Operation__c
            WHERE Id = :existing.Id
        ];

        System.assertNotEquals(
            null,
            refreshed,
            'Existing Site Collection Operation should not be deleted even with inconsistent data'
        );

    }

    
}