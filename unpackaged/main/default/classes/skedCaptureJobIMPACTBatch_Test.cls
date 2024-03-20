@isTest
private class skedCaptureJobIMPACTBatch_Test {
    
    static testmethod void batchTest_TeamSupervisorToDriveLead() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testOpCenter = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        
        Test.startTest();

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, time.newInstance(6, 0, 0, 0)),
            sked__Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, time.newInstance(12, 0, 0, 0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = skedConstants.JOB_RESOURCE_ROLE_TEAM_SUPERVISOR
        );
        insert testJob;

        sked__Tag__c teamSupervisorTag = skedResourceTagHandler_Cache.getTeamSupervisorTag();
        sked__Job_Tag__c testSupervisorTag = new sked__Job_Tag__c(
            sked__Tag__c = teamSupervisorTag.Id,
            sked__Job__c = testJob.Id
        );
        insert testSupervisorTag;
        
        testOpCenter.sked_IMPACT_Start_Date__c = System.today();
        testOpCenter.sked_IMPACT_End_Date__c = System.today().addDays(10);
        skedCOImpactChangedModel testModel = new skedCOImpactChangedModel(testOpCenter, null, null);
        Database.executeBatch(new skedCaptureJobIMPACTBatch(new List<skedCOImpactChangedModel>{testModel}), 1);
        
        Test.stopTest();
    }

    static testmethod void batchTest_DriveLeadToTeamSupervisor() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testOpCenter = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        Test.startTest();

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, time.newInstance(6, 0, 0, 0)),
            sked__Finish__c = DateTime.newInstance(testDrive.sked_Drive_Date__c, time.newInstance(12, 0, 0, 0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = skedConstants.JOB_RESOURCE_ROLE_DRIVE_LEAD
        );
        insert testJob;

        sked__Tag__c driveLeadTag = skedResourceTagHandler_Cache.getDriveLeadTag();
        sked__Job_Tag__c testDriveLeadTag = new sked__Job_Tag__c(
            sked__Tag__c = driveLeadTag.Id,
            sked__Job__c = testJob.Id
        );
        insert testDriveLeadTag;
        
        testOpCenter.sked_IMPACT_Start_Date__c = System.today().addYears(5);
        testOpCenter.sked_IMPACT_End_Date__c = System.today().addYears(10);
        skedCOImpactChangedModel testModel = new skedCOImpactChangedModel(testOpCenter, null, null);
        Database.executeBatch(new skedCaptureJobIMPACTBatch(new List<skedCOImpactChangedModel>{testModel}), 1);
        
        Test.stopTest();
    }
}