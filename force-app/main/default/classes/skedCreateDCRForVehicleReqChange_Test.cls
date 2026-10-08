@isTest
private class skedCreateDCRForVehicleReqChange_Test {

    @isTest
    static void execute_flagsMobileDriveWhoseValueDiffersFromNewSiteValue() {
        Fixture fixture = setupFixture();

        runBatch(fixture.mobileSiteId, true);

        System.assertEquals(true, reload(fixture.mobileDriveId).sked_Vehicle_Req_Change_DCR_Required__c,
            'A mobile drive whose current value (false) differs from the new site value (true) should be flagged for a DCR');
    }

    @isTest
    static void execute_doesNotFlagMobileDriveAlreadyMatchingNewSiteValue() {
        Fixture fixture = setupFixture();
        update new sked_Drive__c(Id = fixture.mobileDriveId, sked_Do_Not_Use_Vehicle__c = true);

        runBatch(fixture.mobileSiteId, true);

        System.assertEquals(false, reload(fixture.mobileDriveId).sked_Vehicle_Req_Change_DCR_Required__c,
            'A drive whose current value already equals the new site value needs no DCR');
    }

    @isTest
    static void execute_flagsOverriddenDriveIdenticallyToInheritingDrive() {
        Fixture fixture = setupFixture();
        update new sked_Drive__c(Id = fixture.mobileDriveId, sked_Do_Not_Use_Vehicle__c = true);

        runBatch(fixture.mobileSiteId, false);

        System.assertEquals(true, reload(fixture.mobileDriveId).sked_Vehicle_Req_Change_DCR_Required__c,
            'A manually overridden drive that disagrees with the new site value is flagged like any other; rejecting the DCR is what preserves the override');
    }

    @isTest
    static void execute_doesNotFlagFixedSiteDrive() {
        Fixture fixture = setupFixture();

        runBatch(fixture.fixedSiteId, true);

        System.assertEquals(false, reload(fixture.fixedSiteDriveId).sked_Vehicle_Req_Change_DCR_Required__c,
            'Fixed site drives are out of scope for the site-level flag and must never be flagged');
    }

    @isTest
    static void execute_doesNotFlagCancelledDrive() {
        Fixture fixture = setupFixture();
        update new sked_Drive__c(Id = fixture.mobileDriveId, sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL);

        runBatch(fixture.mobileSiteId, true);

        System.assertEquals(false, reload(fixture.mobileDriveId).sked_Vehicle_Req_Change_DCR_Required__c,
            'Cancelled drives must never be flagged');
    }

    @isTest
    static void execute_doesNotFlagCompletedDrive() {
        Fixture fixture = setupFixture();
        update new sked_Drive__c(Id = fixture.mobileDriveId, sked_Status__c = skedConstants.DRIVE_STATUS_COMPLETE);

        runBatch(fixture.mobileSiteId, true);

        System.assertEquals(false, reload(fixture.mobileDriveId).sked_Vehicle_Req_Change_DCR_Required__c,
            'Completed drives must never be flagged');
    }

    @isTest
    static void execute_doesNotFlagDriveAtAnUnrelatedSite() {
        Fixture fixture = setupFixture();

        runBatch(fixture.fixedSiteId, true);

        System.assertEquals(false, reload(fixture.mobileDriveId).sked_Vehicle_Req_Change_DCR_Required__c,
            'Only drives belonging to the changed site should be considered');
    }

    private static void runBatch(Id siteId, Boolean newSiteValue) {
        Test.startTest();
        Database.executeBatch(new skedCreateDCRForVehicleReqChangeBatch(new Map<Id, Boolean>{ siteId => newSiteValue }), 200);
        Test.stopTest();
    }

    private static sked_Drive__c reload(Id driveId) {
        return [SELECT Id, sked_Vehicle_Req_Change_DCR_Required__c FROM sked_Drive__c WHERE Id = :driveId];
    }

    private static Fixture setupFixture() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        testDataFactory.setupCommonTestData();
        Map<String, SObject> mapTestData = testDataFactory.setupDriveData();

        Fixture fixture = new Fixture();
        fixture.mobileDriveId = ((sked_Drive__c)mapTestData.get('testDrive1')).Id;
        fixture.fixedSiteDriveId = ((sked_Drive__c)mapTestData.get('testDrive2')).Id;
        fixture.mobileSiteId = ((sked__Location__c)mapTestData.get('testLocation1')).Id;
        fixture.fixedSiteId = ((sked__Location__c)mapTestData.get('testLocation2')).Id;
        return fixture;
    }

    private class Fixture {
        Id mobileDriveId;
        Id fixedSiteDriveId;
        Id mobileSiteId;
        Id fixedSiteId;
    }
}