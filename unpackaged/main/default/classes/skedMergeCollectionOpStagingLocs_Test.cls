@isTest
private class skedMergeCollectionOpStagingLocs_Test {
    @isTest
    static void deleteEarliest() {
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
        
        delete testCoSl1;
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
    static void deleteMiddle() {
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
        
        delete testCoSl2;
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

    @isTest
    static void deleteEnd() {
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

        delete testCoSl3;
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
}