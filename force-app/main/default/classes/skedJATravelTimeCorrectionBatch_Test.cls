@isTest
private class skedJATravelTimeCorrectionBatch_Test {
    @isTest
    static void skedJATravelTimeCorrectionBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked__Resource__c testResource = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOp1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        Test.startTest();
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(1),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Resource_Role__c = '2RBC',
            sked_Drive__c = testDrive.Id
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Estimated_Travel_Time__c = 50
        );
        insert testJobAllocation;
        
        Database.executeBatch(new skedJATravelTimeCorrectionBatch(null), 1);
        
        Test.stopTest();
    }

    @isTest
    static void skedJATravelTimeCorrectionBatch_SecondaryCO_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked__Resource__c testResource = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        Biomed_Collection_Op_Center__c testCo2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');

        Test.startTest();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        testDrive.sked_Collection_Operation__c = testCo2.Id;
        update testDrive;

        sked_Resource_Biomed_Collection_Op__c testResourceCollectionOp = new sked_Resource_Biomed_Collection_Op__c(
            sked_Resource__c = testResource.Id,
            sked_Biomed_Collection_Op_Center__c = testCo2.Id,
            sked_Start_Date__c = System.today().addDays(-10),
            Sked_End_Date__c = System.today().addDays(100)
        );
        insert testResourceCollectionOp;
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = testDataFactory.summary.startTime,
            sked__Finish__c = testDataFactory.summary.startTime.addHours(1),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Resource_Role__c = '2RBC',
            sked_Drive__c = testDrive.Id
        );
        insert testJob;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Estimated_Travel_Time__c = 50
        );
        insert testJobAllocation;
        
        Database.executeBatch(new skedJATravelTimeCorrectionBatch(null), 1);
        
        Test.stopTest();
    }
}