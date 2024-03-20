@isTest
private class skedCollectionOpStagingLocTrigger_Test {
 
    @isTest
    static void Insert_populateData_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCollectionOp2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c) mapTestData.get('testStagingLocation1');

        Test.startTest();
            sked_Collection_Op_Staging_Location__c testCosl = new sked_Collection_Op_Staging_Location__c(
                sked_Collection_Operation__c = testCollectionOp2.Id,
                sked_Staging_Location__c = testStagingLocation1.Id,
                sked_Start_Date__c = System.today(),
                sked_End_Date__c = System.today()
            );
            insert testCosl;
        Test.stopTest();

        testCosl = [SELECT Id, sked_Start_Date__c, sked_End_Date__c FROM sked_Collection_Op_Staging_Location__c WHERE Id = :testCosl.Id];
        System.assertEquals(skedConstants.EARLIEST_START_DATE, testCosl.sked_Start_Date__c);
        System.assertEquals(skedConstants.LATEST_END_DATE, testCosl.sked_End_Date__c);
    }

    @isTest
    static void Update_populateData_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCollectionOp2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c) mapTestData.get('testStagingLocation1');

        sked_Collection_Op_Staging_Location__c testCosl = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = System.today(),
            sked_End_Date__c = System.today()
        );
        insert testCosl;

        Test.startTest();
        testCosl.sked_Start_Date__c = System.today().addDays(-10);
        testCosl.sked_End_Date__c = System.today().addDays(10);
        update testCosl;
        Test.stopTest();

        testCosl = [SELECT Id, sked_Start_Date__c, sked_End_Date__c FROM sked_Collection_Op_Staging_Location__c WHERE Id = :testCosl.Id];
        System.assertEquals(skedConstants.EARLIEST_START_DATE, testCosl.sked_Start_Date__c);
        System.assertEquals(skedConstants.LATEST_END_DATE, testCosl.sked_End_Date__c);
    }

    @isTest
    static void afterDelete_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Biomed_Collection_Op_Center__c testCollectionOp2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c) mapTestData.get('testStagingLocation1');

        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 37.7450046,
            sked_Geolocation__Longitude__s = -122.4816244
        );
        insert testStagingLocation2;

        skedHubBase.setBypassAllTriggers(true);
        delete [SELECT Id FROM sked_Collection_Op_Staging_Location__c];
        List<sked_Collection_Op_Staging_Location__c> cosls = new List<sked_Collection_Op_Staging_Location__c>();
        sked_Collection_Op_Staging_Location__c testCosl1 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = System.today().addDays(-101)
        );
        sked_Collection_Op_Staging_Location__c testCosl2 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Staging_Location__c = testStagingLocation2.Id,
            sked_Start_Date__c = System.today().addDays(-100),
            sked_End_Date__c = System.today().addDays(101)
        );
        sked_Collection_Op_Staging_Location__c testCosl3 = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp2.Id,
            sked_Staging_Location__c = testStagingLocation1.Id,
            sked_Start_Date__c = System.today().addDays(101),
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert new List<sked_Collection_Op_Staging_Location__c>{testCosl1, testCosl2, testCosl3};
        skedHubBase.setBypassAllTriggers(false);

        Test.startTest();
        delete testCosl2;
        Test.stopTest();

        cosls = [SELECT Id, sked_Start_Date__c, sked_End_Date__c FROM sked_Collection_Op_Staging_Location__c];
        System.assertEquals(1, cosls.size());
    }

    @isTest
    static void validateDeletion_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Location__c testSite = (sked__Location__c) mapTestData.get('testLocation1');
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Collection_Op_Staging_Location__c cosl = (sked_Collection_Op_Staging_Location__c) mapTestData.get('testCollectionOpStagingLoc1');
        
        Boolean caughtException = false;
        try {
            delete cosl;
        } catch (Exception ex) {
            caughtException = true;
        }
        System.assert(caughtException);
    }

    
    @isTest
    static void createTravelTimeIndexItems_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked_Staging_Location__c testStagingLoc = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 34.786373,
            sked_Geolocation__Longitude__s = -90.402279
        );
        insert testStagingLoc;
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');

        Test.startTest();
        sked_Collection_Op_Staging_Location__c testCoSl = new sked_Collection_Op_Staging_Location__c(
            sked_Staging_Location__c = testStagingLoc.Id,
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Start_Date__c = System.today().addDays(-100),
            sked_End_Date__c = System.today().addDays(100)
        );
        insert testCoSl;
        Test.stopTest();

        List<sked_Travel_Time_Index_Item__c> ttiis = [SELECT Id FROM sked_Travel_Time_Index_Item__c];
        System.assert(ttiis.size() > 0);
    }
}