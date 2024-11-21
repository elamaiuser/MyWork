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

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
    }
}