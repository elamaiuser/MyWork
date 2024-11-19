@isTest
private class skedResourceTrigger_Test {

    static testmethod void testAssetUpdate_DRD() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();

        sked__Resource__c testVehicle = (sked__Resource__c) mapTestData.get('testVehicle1');

        Profile drdProfile = [SELECT Id FROM Profile WHERE Name LIKE '%DRD%' LIMIT 1];

        Boolean exceptionCaught = false;
        
        Test.startTest();
        
        User testUser = new user(
            alias = 'testuser', email='test@testleton.com', emailencodingkey='UTF-8', firstName='test', lastname='testleton', 
            languagelocalekey='en_US', localesidkey='en_US', profileid = drdProfile.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='test@testleton.com'
        );
        insert testUser;
        
        System.runAs(testUser) {
            try {
                testVehicle.sked_Beds__c = 50;
                update testVehicle;
            } catch (Exception e) { 
                exceptionCaught = true;
            }
        }
        
        Test.stopTest();
    }

    static testmethod void testAssetUpdate() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();

        sked__Resource__c testVehicle = (sked__Resource__c) mapTestData.get('testVehicle1');
        
        Test.startTest();
        
        testVehicle.sked_Beds__c = 50;
        update testVehicle;
        
        Test.stopTest();
    }
    
}