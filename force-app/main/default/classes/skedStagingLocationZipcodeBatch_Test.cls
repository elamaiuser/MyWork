@isTest
private class skedStagingLocationZipcodeBatch_Test {

    static testmethod void mainTest() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        List<sObject> firstList = new List<sObject>();
        sked_Staging_Location__c testStagingLocation1 = new sked_Staging_Location__c(
            sked_Address__c = '110 Test Lane, Test Avenue, 10101',
        	sked_Geolocation__Latitude__s = 37.7450047,
            sked_Geolocation__Longitude__s = -122.481626
        );
        firstList.add(testStagingLocation1);
        insert firstList;
        
        Test.startTest();
        
        Database.executeBatch(new skedStagingLocationZipcodeBatch());
        
        Test.stopTest();
    }
    
}