@istest
private class skedLocationTrigger_Test {

    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30'
        );
        insert testCollectionOperation1;

        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;
        testStagingLocation1.sked_Zip_Code__c = '61149';
        update testStagingLocation1;

        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE, 
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert testCoSl1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Account testAccount1 = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal Name',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1;
        
        
        Collections_Territory__c collectionZipcode = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '94116',
            External_Id__c = '123',
            External_Id_BackEnd__c = '123'

        );
        insert collectionZipcode;
        
        Test.startTest();
        
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked_Address_1__c = 'Inner Parkside', 
            sked_City__c = 'San Francisco', 
            sked_State__c = 'CA', 
            sked_Zip_Code__c = '94116', 
            sked_County__c = 'USA',
            sked__GeoLocation__Latitude__s = 38.7450046,
            sked__GeoLocation__Longitude__s = -123.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = system.today(),
            sked_End_Date__c = system.today().addDays(14),
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
            sked_Start_Date__c = system.today(),
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );
        insert testLocation1;
        
        testLocation1.sked_Physical_Location_Type__c = 'Outside';
        testLocation1.sked_National_Name__c = 'new usa';
        update testLocation1;
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = testAccount1.Id,
            Drive_Date__c = system.today(),
            Drive_Site__c = testLocation1.Id,
            StageName = 'Solicitation',
            CloseDate = system.today(),
            Flow_End_Time_Field__c = '1501',
            Web_Scheduling_End_Time_Offset__c = 2
        );
        insert testOpportunity;
        
        testLocation1.sked_Start_Date__c = testLocation1.sked_Start_Date__c.addDays(1);
        update testLocation1;
        
        Test.stopTest();
    }

    @isTest
    static void validateAfterAddressChanged_Test_NoMatchingCO() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244
        );
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Account testAccount1 = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal Name',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1;
        
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery', 
            CloseDate = system.today(),
            Is_template__c = TRUE,
            Online_Scheduling_Enabled__c = 'No',
            Web_Sched_Offset_from_CO_Global_Settings__c= false,
            Web_Scheduling_Start_Date_Offset__c = -120,
            Web_Scheduling_End_Time_Offset__c = 0,
            Web_Scheduling_End_Date_Offset__c= 0,
            Web_Scheduling_Start_Time__c = '0030'
        );
        insert parentOpp;
        
        Collections_Territory__c collectionZipcode = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '94116',
            External_Id__c = '123',
            External_Id_BackEnd__c = '123'
        );
        insert collectionZipcode;
        
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
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = system.today(),
            sked_End_Date__c = system.today().addDays(14),
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
            sked_Start_Date__c = system.today(),
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );
        insert testLocation1;

        Test.startTest();
            testLocation1.sked_Address_1__c = 'Outer Parkside';
            testLocation1.sked_Zip_Code__c = '61149';
            testLocation1.sked_State__c = 'AC';

            Boolean caughtException = false;
            try {
                update testLocation1;
            } catch (Exception ex) { 
                caughtException = true;
            }
            System.assert(caughtException);
        Test.stopTest();
    }

    @isTest
    static void validateAfterAddressChanged_Test_MatchingCO() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244
        );
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Account testAccount1 = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal Name',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1;
        
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery', 
            CloseDate = system.today(),
            Is_template__c = TRUE,
            Online_Scheduling_Enabled__c = 'No',
            Web_Sched_Offset_from_CO_Global_Settings__c= false,
            Web_Scheduling_Start_Date_Offset__c = -120,
            Web_Scheduling_End_Time_Offset__c = 0,
            Web_Scheduling_End_Date_Offset__c= 0,
            Web_Scheduling_Start_Time__c = '0030'
        );
        insert parentOpp;
        
        Collections_Territory__c collectionZipcode = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '94116',
            External_Id__c = '123',
            External_Id_BackEnd__c = '123'
        );

        Collections_Territory__c collectionZipcode2 = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '61149',
            External_Id__c = '234',
            External_Id_BackEnd__c = '234'
        );
        insert new List<Collections_Territory__c>{collectionZipcode, collectionZipcode2};
        
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
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = system.today(),
            sked_End_Date__c = system.today().addDays(14),
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
            sked_Start_Date__c = system.today(),
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );
        insert testLocation1;

        Test.startTest();
            testLocation1.sked_Address_1__c = 'Outer Parkside';
            testLocation1.sked_Zip_Code__c = '61149';
            testLocation1.sked_State__c = 'AC';

            update testLocation1;
        Test.stopTest();
    }

    static testmethod void validateAddressChanged() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30'
        );
        insert testCollectionOperation1;

        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;

        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE, 
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert testCoSl1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Account testAccount1 = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal Name',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1;
        
        
        Collections_Territory__c collectionZipcode = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '94116',
            External_Id__c = '123',
            External_Id_BackEnd__c = '123'
        );
        insert collectionZipcode;
        
        Test.startTest();
        
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
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = system.today(),
            sked_End_Date__c = system.today().addDays(14),
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
            sked_Start_Date__c = system.today(),
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );
        insert testLocation1;


        testLocation1.sked__Address__c = 'Inner Parkside 2, San Francisco, CA, USA';
        testLocation1.sked_Address_1__c = 'Inner Parkside 2';
        testLocation1.sked_City__c = 'San Francisco';
        testLocation1.sked_State__c = 'CA';
        testLocation1.sked_Zip_Code__c = '94116';
        testLocation1.sked_County__c = 'USA';
        testLocation1.sked__GeoLocation__Latitude__s = 38.7450046;
        testLocation1.sked__GeoLocation__Longitude__s = -123.4816244;
        update testLocation1;
        
        Test.stopTest();
    }
    
    @isTest
    static void siteContainsTwoSCO_test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244
        );
        
        Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            Staging_Location_Geolocation__Latitude__s = 36.7450046,
            Staging_Location_Geolocation__Longitude__s = -123.4816244
        );
        insert new List<Biomed_Collection_Op_Center__c>{testCollectionOperation1, testCollectionOperation2};
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        
        sked__Region__c testRegion2 = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation2.Id
        );
        insert new List<sked__Region__c>{testRegion1, testRegion2};
        
        Account testAccount1 = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal Name',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1;
        
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery', 
            CloseDate = system.today(),
            Is_template__c = TRUE,
            Online_Scheduling_Enabled__c = 'No',
            Web_Sched_Offset_from_CO_Global_Settings__c= false,
            Web_Scheduling_Start_Date_Offset__c = -120,
            Web_Scheduling_End_Time_Offset__c = 0,
            Web_Scheduling_End_Date_Offset__c= 0,
            Web_Scheduling_Start_Time__c = '0030'
        );
        insert parentOpp;
        
        Collections_Territory__c collectionZipcode = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '94116',
            External_Id__c = '123',
            External_Id_BackEnd__c = '123'
        );

        Collections_Territory__c collectionZipcode2 = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(20),
            sked_Start_Date__c = system.today().addDays(15),
            Zip__c = '94116',
            External_Id__c = '234',
            External_Id_BackEnd__c = '234'
        );
        
        Collections_Territory__c collectionZipcode3 = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '61149',
            External_Id__c = '345',
            External_Id_BackEnd__c = '345'
        );
        
        Collections_Territory__c collectionZipcode4 = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(20),
            sked_Start_Date__c = system.today().addDays(15),
            Zip__c = '61149',
            External_Id__c = '456',
            External_Id_BackEnd__c = '456'
        );
        insert new List<Collections_Territory__c>{collectionZipcode, collectionZipcode2, collectionZipcode3, collectionZipcode4};
        
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
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = system.today(),
            sked_End_Date__c = system.today().addDays(14),
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
            sked_Start_Date__c = system.today(),
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated'
        );
        insert testLocation1;

        Test.startTest();
            testLocation1.sked_Address_1__c = 'Outer Parkside';
            testLocation1.sked_Zip_Code__c = '61149';
            testLocation1.sked_State__c = 'AC';

            update testLocation1;
        Test.stopTest();
    }
    
    @isTest
    static void deactivateSites_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        List<sObject> predefinedData = testDataFactory.setupPredefinedData();
        insert predefinedData;
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244
        );
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Account testAccount1 = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal Name',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1;
        
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery', 
            CloseDate = system.today(),
            Is_template__c = TRUE,
            Online_Scheduling_Enabled__c = 'No',
            Web_Sched_Offset_from_CO_Global_Settings__c= false,
            Web_Scheduling_Start_Date_Offset__c = -120,
            Web_Scheduling_End_Time_Offset__c = 0,
            Web_Scheduling_End_Date_Offset__c= 0,
            Web_Scheduling_Start_Time__c = '0030'
        );
        insert parentOpp;
        
        Collections_Territory__c collectionZipcode = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '94116',
            External_Id__c = '123',
            External_Id_BackEnd__c = '123'
        );

        Collections_Territory__c collectionZipcode2 = new Collections_Territory__c(
        	Collection_Operation__c = testCollectionOperation1.Id,
            sked_End_Date__c = system.today().addDays(14),
            sked_Start_Date__c = system.today(),
            Zip__c = '61149',
            External_Id__c = '234',
            External_Id_BackEnd__c = '234'
        );
        insert new List<Collections_Territory__c>{collectionZipcode, collectionZipcode2};
        
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
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = system.today(),
            sked_End_Date__c = system.today().addDays(14),
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
            sked_Start_Date__c = system.today(),
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            Source__c = 'Custom New Form',
            Operation_Type__c = 'Integrated',
            sked_Active__c = TRUE
        );
        insert testLocation1;

        Test.startTest();
        	skedSetting.instance.Admin.exavaluIntegration = TRUE;
            testLocation1.sked_Active__c = FALSE;
            
            update testLocation1;
        skedSetting.instance.Admin.exavaluIntegration = FALSE;
        Test.stopTest();
    }
    
}