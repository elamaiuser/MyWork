@isTest
private class skedResourceOverrideDistrictBatch_Test {

    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        Test.startTest();
        
        sked__Resource_Override__c testResourceOverride = new sked__Resource_Override__c(
            sked__Resource__c = testResource.Id,
            sked__Geolocation__Latitude__s = 30.7575256,
            sked__Geolocation__Longitude__s = -125.4730585,
            sked__End__c = System.now().addHours(6),
            sked__Start__c = System.now().addHours(6),
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Travel_To_Start__c = System.now().addMinutes(5),
            sked_Travel_To_End__c = System.now().addMinutes(5),
            sked_Travel_Back_Start__c = System.now().addMinutes(5),
            sked_Travel_Back_End__c = System.now().addMinutes(5),
            sked_End_Date__c = System.today().addDays(5),
            sked_Start_Date__c = System.today().addDays(-5),
            sked_Travel_Back_End_Date__c = System.today().addDays(5),
            sked_Travel_Back_Start_Date__c = System.today(),
            sked_Travel_To_End_Date__c = System.today(),
            sked_Travel_To_Start_Date__c = System.today(),
            sked_End_Time__c = System.now().time(),
            sked_Travel_Back_End_Time__c = System.now().addMinutes(5).time(),
            sked_Travel_Back_Start_Time__c = System.now().time(),
            sked_Travel_To_End_Time__c = System.now().addMinutes(5).time(),
            sked_Start_Time__c = System.now().time(),
            sked_Travel_To_Start_Time__c = System.now().addMinutes(5).time(),
            sked_Is_Travel_Required__c = true
        );
        insert testResourceOverride;
        
        Database.executeBatch(new skedResourceOverrideDistrictBatch(296));
        
        Test.stopTest();
    }
    
      static testmethod void mainTestWithException() {
        // Setup your base test data
         skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

     //   Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        
        // Insert a bad record (null required lookup or other invalid field)
        sked__Resource_Override__c badOverride = new sked__Resource_Override__c(
            sked__Resource__c = testResource.Id, // Required field left null to force failure
            sked__End__c = System.now().addHours(1),
             sked__Geolocation__Latitude__s = null,
            sked__Geolocation__Longitude__s = null,
           
            sked__Start__c = System.now(),
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Start_Date__c = System.today(),
            sked_End_Date__c = System.today().addDays(1)
        );
        insert badOverride;

        // Start test context
        Test.startTest();
        // Run batch with bad data included
        Database.executeBatch(new skedResourceOverrideDistrictBatch(296), 1);
        Test.stopTest();

        // Add asserts if needed to check post-failure impact or log creation
    }
    
    
    
    
    
    
    
    
    
    
    
}