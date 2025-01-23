@isTest
private class slwcCollectionOperationService_Test {
    @isTest
    static void getSkedRegionId_Test() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);

        Biomed_Collection_Op_Center__c testCo = [
            SELECT Id, Staging_Location_Geolocation__Latitude__s, Staging_Location_Geolocation__Longitude__s
            FROM Biomed_Collection_Op_Center__c
            LIMIT 1
        ][0];

        Test.startTest();
            slwcAuraResult result = slwcCollectionOperationService.getSkedRegionId(testCo.Id, testCo.Staging_Location_Geolocation__Latitude__s, testCo.Staging_Location_Geolocation__Longitude__s);
        Test.stopTest();

        System.assert(result.returnedData != null);
    }
    
    @isTest
    static void getSkedRegionIdUsingTaxonomy_Test() {
        List<Biomed_Collection_Op_Center__c> testCo = [SELECT Id FROM Biomed_Collection_Op_Center__c where Name = 'Test Collection Operation 94116'];
        Test.startTest();
        Date dToday = Date.today();
		String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
        slwcAuraResult result = slwcCollectionOperationService.getSkedRegionIdUsingTaxonomy(testCo[0].Id, '94116', dateStr, dateStr);
        List<sked__Region__c> queryResults = [SELECT Id, sked__Timezone__c
                                              FROM sked__Region__c
                                              WHERE sked_Biomed_Collection_Op_Center__c = :testCo[0].Id];
        Test.stopTest();
        System.assert(result.returnedData != null);
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Biomed_Collection_Op_Center__c testCo = new Biomed_Collection_Op_Center__c(
            Name = 'Test Collection Operation 94116',
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
            sked__Timezone__c = 'America/Los_Angeles',
            sked_Biomed_Collection_Op_Center__c = testCo.Id
        );
        insert testRegion;
        
        Id recordTypeId = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();

        Taxonomy__c testTx1 = new Taxonomy__c(
            Collection_Operation_Name__c = 'Test Collection Operation',
            Zip_Code__c = '94116',
            Start_Date__c = Date.newInstance(2023, 1, 1),
            End_Date__c = Date.newInstance(4000, 12, 31),
            recordTypeId = recordTypeId,
            Time_Zone__c = 'America/Los_Angeles'
        );
        
        insert testTx1;
    }
}