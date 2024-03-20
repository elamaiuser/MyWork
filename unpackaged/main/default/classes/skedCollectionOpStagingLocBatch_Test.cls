@isTest
private class skedCollectionOpStagingLocBatch_Test {
    @isTest
    static void insert_OverlapBefore_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 39.7450046,
            sked_Geolocation__Longitude__s = -124.4816244,
            sked_Address__c = '101 Test Road, Testtown, Testville'
        );
        insert testStagingLocation2;

        skedHubBase.setBypassAllTriggers(true);
        delete [SELECT Id FROM sked_Collection_Op_Staging_Location__c];
        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert testCoSl1;
        
        sked_Collection_Op_Staging_Location__c testCoSl2 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation2.Id,
            sked_Start_Date__c = System.today(), 
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert testCoSl2;
        skedHubBase.setBypassAllTriggers(false);
        Test.startTest();
            Database.executeBatch(new skedCollectionOpStagingLocBatch(new List<skedCoslWrapper>{new skedCoslWrapper(testCoSl2)}), 1);
        Test.stopTest();

        List<sked_Collection_Op_Staging_Location__c> collectionOpStagingLocs = [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c 
            FROM sked_Collection_Op_Staging_Location__c
            ORDER BY sked_Start_Date__c ASC
        ];

        System.assertEquals(2, collectionOpStagingLocs.size());
        System.assertEquals(collectionOpStagingLocs[0].sked_Start_Date__c, skedConstants.EARLIEST_START_DATE);
        System.assertEquals(collectionOpStagingLocs[0].sked_End_Date__c, System.today().addDays(-1));
        System.assertEquals(collectionOpStagingLocs[1].sked_Start_Date__c, System.today());
        System.assertEquals(collectionOpStagingLocs[1].sked_End_Date__c, skedConstants.LATEST_END_DATE);
    }

    @isTest
    static void insert_OverlapAfter_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 39.7450046,
            sked_Geolocation__Longitude__s = -124.4816244,
            sked_Address__c = '101 Test Road, Testtown, Testville'
        );
        insert testStagingLocation2;

        skedHubBase.setBypassAllTriggers(true);
        delete [SELECT Id FROM sked_Collection_Op_Staging_Location__c];
        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert testCoSl1;

        sked_Collection_Op_Staging_Location__c testCoSl2 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation2.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE, 
            sked_End_Date__c = System.today()
        );
        insert testCoSl2;
        skedHubBase.setBypassAllTriggers(false);

        Database.executeBatch(new skedCollectionOpStagingLocBatch(new List<skedCoslWrapper>{new skedCoslWrapper(testCoSl2)}), 1);
        Test.stopTest();

        List<sked_Collection_Op_Staging_Location__c> collectionOpStagingLocs = [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c 
            FROM sked_Collection_Op_Staging_Location__c
            ORDER BY sked_Start_Date__c ASC
        ];

        System.assertEquals(2, collectionOpStagingLocs.size());
        System.assertEquals(collectionOpStagingLocs[0].sked_Start_Date__c, skedConstants.EARLIEST_START_DATE);
        System.assertEquals(collectionOpStagingLocs[0].sked_End_Date__c, System.today());
        System.assertEquals(collectionOpStagingLocs[1].sked_Start_Date__c, System.today().addDays(1));
        System.assertEquals(collectionOpStagingLocs[1].sked_End_Date__c, skedConstants.LATEST_END_DATE);
    }

    @isTest

    static void insert_CoversExisting_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 39.7450046,
            sked_Geolocation__Longitude__s = -124.4816244,
            sked_Address__c = '101 Test Road, Testtown, Testville'
        );
        insert testStagingLocation2;

        sked_Staging_Location__c testStagingLocation3 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 38.7450046,
            sked_Geolocation__Longitude__s = -123.4816244,
            sked_Address__c = '101 Test Street, Testland, Testshire'
        );
        insert testStagingLocation3;

        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = System.today().addDays(-11)
        );

        sked_Collection_Op_Staging_Location__c testCoSl2 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation2.Id,
            sked_Start_Date__c = System.today().addDays(10),
            sked_End_Date__c = System.today().addDays(10)
        );

        sked_Collection_Op_Staging_Location__c testCoSl3 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = System.today().addDays(11),
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );

        skedHubBase.setBypassAllTriggers(true);
        delete [SELECT Id FROM sked_Collection_Op_Staging_Location__c];
        insert new List<sked_Collection_Op_Staging_Location__c>{testCoSl1, testCoSl2, testCoSl3};
        skedHubBase.setBypassAllTriggers(false);
        
        insert new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation3.Id,
            sked_Start_Date__c = System.today().addDays(-15), 
            sked_End_Date__c = System.today().addDays(15)
        );
        Test.stopTest();

        List<sked_Collection_Op_Staging_Location__c> collectionOpStagingLocs = [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c 
            FROM sked_Collection_Op_Staging_Location__c
            ORDER BY sked_Start_Date__c ASC
        ];

        System.assertEquals(3, collectionOpStagingLocs.size());
        System.assertEquals(collectionOpStagingLocs[0].sked_Start_Date__c, skedConstants.EARLIEST_START_DATE);
        System.assertEquals(collectionOpStagingLocs[0].sked_End_Date__c, System.today().addDays(-16));
        System.assertEquals(collectionOpStagingLocs[1].sked_Start_Date__c, System.today().addDays(-15));
        System.assertEquals(collectionOpStagingLocs[1].sked_End_Date__c, System.today().addDays(15));
        System.assertEquals(collectionOpStagingLocs[2].sked_Start_Date__c, System.today().addDays(16));
        System.assertEquals(collectionOpStagingLocs[2].sked_End_Date__c, skedConstants.LATEST_END_DATE);
    }

    @isTest
    static void insert_MiddleOfExisting_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 39.7450046,
            sked_Geolocation__Longitude__s = -124.4816244,
            sked_Address__c = '101 Test Road, Testtown, Testville'
        );
        insert testStagingLocation2;

        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );

        sked_Collection_Op_Staging_Location__c testCoSl2 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation2.Id,
            sked_Start_Date__c = System.today(), 
            sked_End_Date__c = System.today().addDays(10)
        );
        
        skedHubBase.setBypassAllTriggers(true);
        delete [SELECT Id FROM sked_Collection_Op_Staging_Location__c];
        insert new List<sked_Collection_Op_Staging_Location__c>{testCoSl1, testCoSl2};
        skedHubBase.setBypassAllTriggers(false);

        Database.executeBatch(new skedCollectionOpStagingLocBatch(new List<skedCoslWrapper>{new skedCoslWrapper(testCoSl2)}), 1);
        Test.stopTest();

        List<sked_Collection_Op_Staging_Location__c> collectionOpStagingLocs = [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c 
            FROM sked_Collection_Op_Staging_Location__c
            ORDER BY sked_Start_Date__c ASC
        ];

        System.assertEquals(3, collectionOpStagingLocs.size());
        System.assertEquals(collectionOpStagingLocs[0].sked_Start_Date__c, skedConstants.EARLIEST_START_DATE);
        System.assertEquals(collectionOpStagingLocs[0].sked_End_Date__c, System.today().addDays(-1));
        System.assertEquals(collectionOpStagingLocs[1].sked_Start_Date__c, System.today());
        System.assertEquals(collectionOpStagingLocs[1].sked_End_Date__c, System.today().addDays(10));
        System.assertEquals(collectionOpStagingLocs[2].sked_Start_Date__c, System.today().addDays(11));
        System.assertEquals(collectionOpStagingLocs[2].sked_End_Date__c, skedConstants.LATEST_END_DATE);
    }

    @isTest
    static void update_ChangeStartEndDate_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 39.7450046,
            sked_Geolocation__Longitude__s = -124.4816244,
            sked_Address__c = '101 Test Road, Testtown, Testville'
        );
        insert testStagingLocation2;

        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = System.today().addDays(-11)
        );

        sked_Collection_Op_Staging_Location__c testCoSl2 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation2.Id,
            sked_Start_Date__c = System.today().addDays(10),
            sked_End_Date__c = System.today().addDays(10)
        );

        sked_Collection_Op_Staging_Location__c testCoSl3 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = System.today().addDays(11),
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        skedHubBase.setBypassAllTriggers(true);
        delete [SELECT Id FROM sked_Collection_Op_Staging_Location__c];
        insert new List<sked_Collection_Op_Staging_Location__c>{testCoSl1, testCoSl2, testCoSl3};
        skedHubBase.setBypassAllTriggers(false);

        testCoSl2.sked_Start_Date__c = System.today().addDays(-20);
        testCoSl2.sked_End_Date__c = System.today().addDays(20);
        update testCoSl2;
        Test.stopTest();

        List<sked_Collection_Op_Staging_Location__c> collectionOpStagingLocs = [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c 
            FROM sked_Collection_Op_Staging_Location__c
            ORDER BY sked_Start_Date__c ASC
        ];

        System.assertEquals(3, collectionOpStagingLocs.size());
        System.assertEquals(collectionOpStagingLocs[0].sked_Start_Date__c, skedConstants.EARLIEST_START_DATE);
        System.assertEquals(collectionOpStagingLocs[0].sked_End_Date__c, System.today().addDays(-21));
        System.assertEquals(collectionOpStagingLocs[1].sked_Start_Date__c, System.today().addDays(-20));
        System.assertEquals(collectionOpStagingLocs[1].sked_End_Date__c, System.today().addDays(20));
        System.assertEquals(collectionOpStagingLocs[2].sked_Start_Date__c, System.today().addDays(21));
        System.assertEquals(collectionOpStagingLocs[2].sked_End_Date__c, skedConstants.LATEST_END_DATE);
    }

    @isTest
    static void update_ChangeToEarliestStart_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 39.7450046,
            sked_Geolocation__Longitude__s = -124.4816244,
            sked_Address__c = '101 Test Road, Testtown, Testville'
        );
        insert testStagingLocation2;

        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = System.today().addDays(-11)
        );

        sked_Collection_Op_Staging_Location__c testCoSl2 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation2.Id,
            sked_Start_Date__c = System.today().addDays(-10),
            sked_End_Date__c = System.today().addDays(10)
        );

        sked_Collection_Op_Staging_Location__c testCoSl3 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = System.today().addDays(11),
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        skedHubBase.setBypassAllTriggers(true);
        delete [SELECT Id FROM sked_Collection_Op_Staging_Location__c];
        insert new List<sked_Collection_Op_Staging_Location__c>{testCoSl1, testCoSl2, testCoSl3};
        skedHubBase.setBypassAllTriggers(false);

        testCoSl2.sked_Start_Date__c = skedConstants.EARLIEST_START_DATE;
        update testCoSl2;
        Test.stopTest();

        List<sked_Collection_Op_Staging_Location__c> collectionOpStagingLocs = [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c 
            FROM sked_Collection_Op_Staging_Location__c
            ORDER BY sked_Start_Date__c ASC
        ];

        System.assertEquals(2, collectionOpStagingLocs.size());
        System.assertEquals(collectionOpStagingLocs[0].sked_Start_Date__c, skedConstants.EARLIEST_START_DATE);
        System.assertEquals(collectionOpStagingLocs[0].sked_End_Date__c, System.today().addDays(10));
        System.assertEquals(collectionOpStagingLocs[1].sked_Start_Date__c, System.today().addDays(11));
        System.assertEquals(collectionOpStagingLocs[1].sked_End_Date__c, skedConstants.LATEST_END_DATE);
    }

    @isTest
    static void update_ChangeToLatestEnd_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 39.7450046,
            sked_Geolocation__Longitude__s = -124.4816244,
            sked_Address__c = '101 Test Road, Testtown, Testville'
        );
        insert testStagingLocation2;

        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = System.today().addDays(-11)
        );

        sked_Collection_Op_Staging_Location__c testCoSl2 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation2.Id,
            sked_Start_Date__c = System.today().addDays(-10),
            sked_End_Date__c = System.today().addDays(10)
        );

        sked_Collection_Op_Staging_Location__c testCoSl3 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = System.today().addDays(11),
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        skedHubBase.setBypassAllTriggers(true);
        delete [SELECT Id FROM sked_Collection_Op_Staging_Location__c];
        insert new List<sked_Collection_Op_Staging_Location__c>{testCoSl1, testCoSl2, testCoSl3};
        skedHubBase.setBypassAllTriggers(false);

        testCoSl2.sked_End_Date__c = skedConstants.LATEST_END_DATE;
        update testCoSl2;
        Test.stopTest();

        List<sked_Collection_Op_Staging_Location__c> collectionOpStagingLocs = [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c 
            FROM sked_Collection_Op_Staging_Location__c
            ORDER BY sked_Start_Date__c ASC
        ];

        System.assertEquals(2, collectionOpStagingLocs.size());
        System.assertEquals(collectionOpStagingLocs[0].sked_Start_Date__c, skedConstants.EARLIEST_START_DATE);
        System.assertEquals(collectionOpStagingLocs[0].sked_End_Date__c, System.today().addDays(-11));
        System.assertEquals(collectionOpStagingLocs[1].sked_Start_Date__c, System.today().addDays(-10));
        System.assertEquals(collectionOpStagingLocs[1].sked_End_Date__c, skedConstants.LATEST_END_DATE);
    }

    @isTest
    static void update_ChangeToEarliestStartLatestEnd_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244,
            sked_Address__c = '101 Test Avenue, Testville, Testleton-On-Sea'
        );
        insert testStagingLocation1;
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 39.7450046,
            sked_Geolocation__Longitude__s = -124.4816244,
            sked_Address__c = '101 Test Road, Testtown, Testville'
        );
        insert testStagingLocation2;

        sked_Collection_Op_Staging_Location__c testCoSl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = System.today().addDays(-11)
        );

        sked_Collection_Op_Staging_Location__c testCoSl2 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation2.Id,
            sked_Start_Date__c = System.today().addDays(-10),
            sked_End_Date__c = System.today().addDays(10)
        );

        sked_Collection_Op_Staging_Location__c testCoSl3 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = System.today().addDays(11),
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        skedHubBase.setBypassAllTriggers(true);
        delete [SELECT Id FROM sked_Collection_Op_Staging_Location__c];
        insert new List<sked_Collection_Op_Staging_Location__c>{testCoSl1, testCoSl2, testCoSl3};
        skedHubBase.setBypassAllTriggers(false);

        testCoSl2.sked_Start_Date__c = skedConstants.EARLIEST_START_DATE;
        testCoSl2.sked_End_Date__c = skedConstants.LATEST_END_DATE;
        update testCoSl2;
        Test.stopTest();

        List<sked_Collection_Op_Staging_Location__c> collectionOpStagingLocs = [
            SELECT Id, sked_Start_Date__c, sked_End_Date__c 
            FROM sked_Collection_Op_Staging_Location__c
            ORDER BY sked_Start_Date__c ASC
        ];

        System.assertEquals(1, collectionOpStagingLocs.size());
        System.assertEquals(collectionOpStagingLocs[0].sked_Start_Date__c, skedConstants.EARLIEST_START_DATE);
        System.assertEquals(collectionOpStagingLocs[0].sked_End_Date__c, skedConstants.LATEST_END_DATE);
    }
}