@isTest
private class skedDriveProductivityOneTimeBatch_Test {
    
    static testmethod void skedPostDriveMigrationBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c mobileTestDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        
        Test.startTest();
        
        mobileTestDrive.sked_MigrationID__c = 'migration-id-1';
        mobileTestDrive.sked_Post_Migration_Processed__c = false;
        
        sked_Drive__c fixedSiteTestDrive = mobileTestDrive.clone(false, false, false, false);
        fixedSiteTestDrive.sked_Type_of_Drive__c = 'Fixed Site';
        fixedSiteTestDrive.sked_MigrationID__c = 'migration-id-2';
        upsert new List<SObject>{mobileTestDrive, fixedSiteTestDrive};
            
            List<sked__Job__c> testJobsToCreate = new List<sked__Job__c>();
        for (sked_Drive__c testDrive : new List<sked_Drive__c>{mobileTestDrive, fixedSiteTestDrive}) {
            testJobsToCreate.add(new sked__Job__c(
                sked__Region__c = testRegion.Id,
                sked__Start__c = testDataFactory.summary.startTime.addHours(11),
                sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
                sked__Duration__c = 60,
                sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
                sked_Drive__c = testDrive.Id,
                sked_Resource_Role__c = '2RBC'
            ));
        }
        insert testJobsToCreate;
        
        sked_Staffing_Decision_Matrix__c sdm = new sked_Staffing_Decision_Matrix__c(
            sked_Driver_Capacity__c = 10,
            sked_Driver_Support_Capacity__c = 10,
            sked_2RBC_Staff_Capacity__c = 10,
            sked_VP_HH_Capacity__c = 10,
            sked_Charge_Capacity__c = 10
        );
        insert sdm;
        
        sked_Collection_Operation_SDM__c cOpSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Effective_Start_Date__c = System.today().addDays(-100),
            sked_Effective_End_Date__c = System.today().addDays(100),
            sked_Staffing_Decision_Matrix__c = sdm.Id
        );
        insert cOpSdm;
        
        Set<Id> driveIds = new Set<Id>();
        driveIds.add(mobileTestDrive.Id);
        driveIds.add(fixedSiteTestDrive.Id);
        
        Database.executeBatch(new skedDriveProductivityOneTimeBatch(driveIds));
        
        Test.stopTest();
    }
    
}