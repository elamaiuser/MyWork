@isTest
private class skedRepopulateDriveStagingLoc_Test {
    @isTest
    static void skedRepopulateDriveStagingLoc_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c) mapTestData.get('testStagingLocation1');
        sked_Staging_Location__c testStagingLocation2 = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 38.7450046,
            sked_Geolocation__Longitude__s = -123.4816244
        );
        insert testStagingLocation2;

        skedHubBase.setBypassAllTriggers(true);
        testDrive.sked_Staging_Location__c = testStagingLocation2.Id;
        update testDrive;
        skedHubBase.setBypassAllTriggers(false);

        Test.startTest();
        Database.executeBatch(new skedRepopulateDriveStagingLocBatch(new Set<Id>{testStagingLocation2.Id}));
        Test.stopTest();

        testDrive = [SELECT Id, sked_Staging_Location__c FROM sked_Drive__c WHERE Id = :testDrive.Id];
        Assert.areEqual(testStagingLocation1.Id, testDrive.sked_Staging_Location__c);
    }
}