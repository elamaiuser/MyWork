@isTest
private class skedTravelDistanceOneTimeBatch_Test {
    @isTest 
    static void skedTravelDistanceOneTimeBatch_Test() {
        sked_Travel_Time_Index_Item__c testTtii = new sked_Travel_Time_Index_Item__c(
            sked_From__Latitude__s = 36.7450046,
            sked_From__Longitude__s = -120.4816244,
            sked_To__Latitude__s = 38.7450046,
            sked_To__Longitude__s = -122.4816244,
            sked_Ordering_Key__c = skedConstants.TTII_DIRECTION_SITE_TO_CO + 36.7450046 + ':' + -120.4816244,
            sked_Timezone__c = 'America/New_York',
            sked_Travel_Time_Breakdown_JSON__c = '[{"weekday":"Wednesday","travelTime":99,"travelDistance":119213,"startOfWindow":"00:00:00.000Z","siteId":null,"endOfWindow":"08:00:00.000Z","direction":null}]'
        );
        insert testTtii;

        Test.startTest();
        Database.executeBatch(new skedTravelDistanceOneTimeBatch());
        Test.stopTest();

        testTtii = [SELECT Id, sked_Travel_Distance__c FROM sked_Travel_Time_Index_Item__c WHERE Id = :testTtii.Id];
        Assert.isNotNull(testTtii.sked_Travel_Distance__c);
    }
}