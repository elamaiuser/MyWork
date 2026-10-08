@isTest
private class skedLocationHandler_Test {

    @isTest
    static void getSitesWithChangedVehicleRequirement_detectsFlagBeingSetOnMobileSite() {
        Id siteId = fakeSiteId(1);

        Map<Id, Boolean> result = detect(siteId, skedConstants.SITE_TYPE_MOBILE, false, true);

        System.assertEquals(true, result.get(siteId),
            'Setting the flag on a Mobile Site should report the new value for that site');
    }

    @isTest
    static void getSitesWithChangedVehicleRequirement_detectsFlagBeingRemovedOnMobileSite() {
        Id siteId = fakeSiteId(2);

        Map<Id, Boolean> result = detect(siteId, skedConstants.SITE_TYPE_MOBILE, true, false);

        System.assertEquals(false, result.get(siteId),
            'Removing the flag should be reported just like setting it, carrying the new value');
    }

    @isTest
    static void getSitesWithChangedVehicleRequirement_ignoresFixedSite() {
        Id siteId = fakeSiteId(3);

        Map<Id, Boolean> result = detect(siteId, skedConstants.SITE_TYPE_FIXED, false, true);

        System.assertEquals(true, result.isEmpty(),
            'Flag changes on a Fixed Site are out of scope and must never be reported');
    }

    @isTest
    static void getSitesWithChangedVehicleRequirement_ignoresUnchangedFlag() {
        Id siteId = fakeSiteId(4);

        Map<Id, Boolean> result = detect(siteId, skedConstants.SITE_TYPE_MOBILE, true, true);

        System.assertEquals(true, result.isEmpty(),
            'A site update that leaves the flag untouched must not create any DCR work');
    }

    @isTest
    static void onAfterUpdate_persistsTheFlagOnAMobileSite() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        testDataFactory.setupCommonTestData();
        Map<String, SObject> mapTestData = testDataFactory.setupDriveData();
        Id siteId = ((sked__Location__c)mapTestData.get('testLocation1')).Id;
        update new sked__Location__c(Id = siteId, sked__Type__c = skedConstants.SITE_TYPE_MOBILE);

        Test.startTest();
        update new sked__Location__c(Id = siteId, sked_Do_Not_Use_Vehicle__c = true);
        Test.stopTest();

        sked__Location__c updatedSite = [
            SELECT Id, sked_Do_Not_Use_Vehicle__c FROM sked__Location__c WHERE Id = :siteId
        ];
        System.assertEquals(true, updatedSite.sked_Do_Not_Use_Vehicle__c,
            'The site-level flag should save through the trigger without error');
    }

    private static Map<Id, Boolean> detect(Id siteId, String siteType, Boolean oldValue, Boolean newValue) {
        sked__Location__c oldSite = new sked__Location__c(
            Id = siteId, sked__Type__c = siteType, sked_Do_Not_Use_Vehicle__c = oldValue);
        sked__Location__c newSite = new sked__Location__c(
            Id = siteId, sked__Type__c = siteType, sked_Do_Not_Use_Vehicle__c = newValue);

        return skedLocationHandler.getSitesWithChangedVehicleRequirement(
            new List<sked__Location__c>{ newSite },
            new Map<Id, sked__Location__c>{ siteId => oldSite }
        );
    }

    private static Id fakeSiteId(Integer index) {
        String keyPrefix = sked__Location__c.SObjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(index).leftPad(12, '0'));
    }
}