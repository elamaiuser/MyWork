@isTest
private class skedVehicleFutureInactivateBatch_Test {

    @testSetup
    static void setupTestData() {
        insert new List<sked__Tag__c>{
            new sked__Tag__c(Name = 'Inside', sked__Type__c = skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE),
            new sked__Tag__c(Name = 'Outside', sked__Type__c = skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE),
            new sked__Tag__c(Name = 'Fixed Site', sked__Type__c = skedConstants.TAG_TYPE_DRIVE_TYPE),
            new sked__Tag__c(Name = 'Mobile', sked__Type__c = skedConstants.TAG_TYPE_DRIVE_TYPE)
        };

        insert new List<sked__Resource__c>{
            new sked__Resource__c(
                Name = 'Test Vehicle',
                sked__Resource_Type__c = skedConstants.RESOURCE_TYPE_ASSET,
                sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
                sked__Is_Active__c = true
            ),
            new sked__Resource__c(
                Name = 'Test Equipment',
                sked__Resource_Type__c = skedConstants.RESOURCE_TYPE_ASSET,
                sked_Asset_Type__c = 'Equipment',
                sked__Is_Active__c = true
            )
        };
    }

    /**
     * Test that a Vehicle resource with Future Inactive Date = today is deactivated by the batch
     */
    @isTest
    static void testVehicleDeactivatedOnFutureInactiveDate() {
        sked__Resource__c testVehicle = [SELECT Id FROM sked__Resource__c WHERE sked_Asset_Type__c = :skedConstants.ASSET_TYPE_VEHICLE LIMIT 1];
        testVehicle.sked_Future_Inactive_Date__c = System.today();
        update testVehicle;

        Test.startTest();
        Database.executeBatch(new skedVehicleFutureInactivateBatch());
        Test.stopTest();

        Assert.isFalse([SELECT sked__Is_Active__c FROM sked__Resource__c WHERE Id = :testVehicle.Id].sked__Is_Active__c,
            'Vehicle should be inactive after batch runs on Future Inactive Date');
    }

    /**
     * Test that a Vehicle resource with a Future Inactive Date in the future is NOT deactivated
     */
    @isTest
    static void testVehicleNotDeactivatedWhenDateIsFuture() {
        sked__Resource__c testVehicle = [SELECT Id FROM sked__Resource__c WHERE sked_Asset_Type__c = :skedConstants.ASSET_TYPE_VEHICLE LIMIT 1];
        testVehicle.sked_Future_Inactive_Date__c = System.today().addDays(5);
        update testVehicle;

        Test.startTest();
        Database.executeBatch(new skedVehicleFutureInactivateBatch());
        Test.stopTest();

        Assert.isTrue([SELECT sked__Is_Active__c FROM sked__Resource__c WHERE Id = :testVehicle.Id].sked__Is_Active__c,
            'Vehicle with a future date should remain active after batch runs');
    }

    /**
     * Test that a non-Vehicle asset (Equipment) with Future Inactive Date = today is NOT deactivated
     */
    @isTest
    static void testNonVehicleAssetNotAffected() {
        sked__Resource__c testEquipment = [SELECT Id FROM sked__Resource__c WHERE sked_Asset_Type__c = 'Equipment' LIMIT 1];
        testEquipment.sked_Future_Inactive_Date__c = System.today();
        update testEquipment;

        Test.startTest();
        Database.executeBatch(new skedVehicleFutureInactivateBatch());
        Test.stopTest();

        Assert.isTrue([SELECT sked__Is_Active__c FROM sked__Resource__c WHERE Id = :testEquipment.Id].sked__Is_Active__c,
            'Non-Vehicle asset should not be affected by the vehicle inactivation batch');
    }

    /**
     * Test that the class can be scheduled without errors
     */
    @isTest
    static void testScheduleExecution() {
        Test.startTest();
        String jobId = System.schedule('Test skedVehicleFutureInactivateBatch', '0 0 2 * * ?', new skedVehicleFutureInactivateBatch());
        Test.stopTest();

        Assert.isNotNull(jobId, 'Scheduled job ID should not be null');
    }
}
