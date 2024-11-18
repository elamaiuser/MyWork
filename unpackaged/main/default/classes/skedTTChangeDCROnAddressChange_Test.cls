@isTest
private class skedTTChangeDCROnAddressChange_Test {
	@isTest
    static void skedTTChangeDCROnAddressChange_Test(){
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        sked_Staging_Location__c testStagingLocation1 = (sked_Staging_Location__c) mapTestData.get('testStagingLocation1');
        
        testLocation1.sked__Address__c = '2418 20th Ave, San Francisco, CA 94116, USA';
        testLocation1.sked__GeoLocation__Latitude__s  = 37.7426879;
        testLocation1.sked__GeoLocation__Longitude__s  = -122.4763891;
        
        skedHubBase.setBypassAllTriggers(true);
        update testLocation1;
        skedHubBase.setBypassAllTriggers(false);
        
        Test.startTest();
        Database.executeBatch(new skedTTChangeDCROnAddressChangeBatch(new Set<Id>{testLocation1.Id}));
        Test.stopTest();
        
        testDrive = [SELECT Id, sked_Travel_Time_Change_DCR_Required__c FROM sked_Drive__c WHERE Id = :testDrive.Id];
        Assert.areEqual(True, testDrive.sked_Travel_Time_Change_DCR_Required__c);
	}
}