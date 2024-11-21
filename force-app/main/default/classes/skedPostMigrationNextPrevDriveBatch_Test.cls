@isTest
private class skedPostMigrationNextPrevDriveBatch_Test {
    
    static testmethod void skedPostMigrationNextPreviousDriveBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();

        List<sked_Drive__c> drivesToUpsert = new List<sked_Drive__c>();
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_Post_Migration_Processed__c = false;
        testDrive.sked_Post_Migration_Completed_Steps__c = 'Process Linked Drive';
        testDrive.sked_Drive_Date__c = System.today().addDays(20);
        testDrive.sked_MigrationID__c = 'test-migration-id';
        drivesToUpsert.add(testDrive);

        sked_Drive__c testDrivePrev = testDrive.clone(false, false, false, false);
        testDrivePrev.sked_Drive_Date__c = System.today().addDays(10);
        testDrivePrev.sked_MigrationID__c = 'test-migration-id-2';
        drivesToUpsert.add(testDrivePrev);

        sked_Drive__c testDriveNext = testDrive.clone(false, false, false, false);
        testDriveNext.sked_Drive_Date__c = System.today().addDays(30);
        testDriveNext.sked_MigrationID__c = 'test-migration-id-3';
        drivesToUpsert.add(testDriveNext);

        upsert drivesToUpsert;

        Database.executeBatch(new skedPostMigrationNextPreviousDriveBatch(testDrive.Id));
        
        Test.stopTest();
    }
    
}