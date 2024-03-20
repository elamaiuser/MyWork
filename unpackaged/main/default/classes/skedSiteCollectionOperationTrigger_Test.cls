@isTest
private class skedSiteCollectionOperationTrigger_Test {
    @isTest
    static void createTravelTimeIndexItems_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Location__c testSite = (sked__Location__c) mapTestData.get('testLocation1');
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');

        sked_Staging_Location__c testStagingLocation = new sked_Staging_Location__c(
            sked_Geolocation__Latitude__s = 38.7450046,
            sked_Geolocation__Longitude__s = -123.4816244,
            sked_Timezone__c = 'America/Chicago'
        );
        insert testStagingLocation;

        sked_Collection_Op_Staging_Location__c testCosl = new sked_Collection_Op_Staging_Location__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Staging_Location__c = testStagingLocation.Id,
            sked_Start_Date__c = skedConstants.EARLIEST_START_DATE,
            sked_End_Date__c = skedConstants.LATEST_END_DATE
        );
        insert testCosl;

        delete [SELECT Id FROM sked_Travel_Time_Index_Item__c];
        Test.startTest();
        sked_Site_Collection_Operation__c testSCO = new sked_Site_Collection_Operation__c(
            sked_Site__c = testSite.Id,
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Start_Date__c = System.today().addDays(-100),
            sked_End_Date__c = System.today().addDays(100)
        );
        insert testSCO;
        Test.stopTest();

        List<sked_Travel_Time_Index_Item__c> ttiis = [SELECT Id FROM sked_Travel_Time_Index_Item__c];
        Assert.isFalse(ttiis.isEmpty());
    }
}