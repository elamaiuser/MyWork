@isTest
private class skedActivityDistrictBatch_Test {

    static testmethod void mainTest() {
        sked_Admin_Setting__c skedAdminSetting = sked_Admin_Setting__c.getOrgDefaults();
        skedAdminSetting.sked_Admin_DateTime_Conversion__c = TRUE;
        upsert skedAdminSetting;
        
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();
        
        sked__Activity__c activity = new sked__Activity__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'Administration',
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901
        );
        insert activity;
        
        Database.executeBatch(new skedActivityDistrictBatch());
        
        Test.stopTest();
    }
    
}