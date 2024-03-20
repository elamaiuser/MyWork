@isTest
private class skedNotificationQueueBatch_Test {

    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        testDrive1.sked_Drive_Date__c = system.today().addDays(30);
        update testDrive1;
        
        List<sked_Drive__c> newRecords = new List<sked_Drive__c>();
        sked_Drive__c newTestDrive1 = new sked_Drive__c(
        	Id = testDrive1.Id,
            Name = testDrive1.Name,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_WB_Projected_Procedures__c = testDrive1.sked_WB_Projected_Procedures__c + 10
        );
        newRecords.add(newTestDrive1);
        
        Map<Id, sked_Drive__c> oldMap = new Map<Id, sked_Drive__c>();
        oldMap.put(testDrive1.Id, testDrive1);
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testDrive1.Id);
        
        Map<String, sked_Notification_Setting__mdt> mapCMD = sked_Notification_Setting__mdt.getAll();
        
        sked_Notification_Queue_Item__c item = new sked_Notification_Queue_Item__c(
        	sked_Notification_Setting_Id__c = mapCMD.get('sked_Logistic_Change_SF_Push').Id,
            sked_Batch_Params_1__c = JSON.serialize(recordIds),
            sked_Batch_Params_2__c = JSON.serialize(newRecords),
            sked_Batch_Params_3__c = JSON.serialize(oldMap),
            sked_Status__c = 'Queued'
        );
        insert item;
        
        Database.executeBatch(new skedNotificationQueueBatch());
        
        Test.stopTest();
    }
    
    static testmethod void testDriveDcrQueueTargetDestination() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Set<string> coNames = new Set<string>();
            coNames.add(testCollectionOperation1.Name);
            skedBiomedCollectionOpHandler.createQueues(coNames);
        }
        
        Test.startTest();
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testDrive1.Id);
        
        List<SObject> newRecords = new List<SObject>();
        newRecords.add(testDrive1);
        
        skedNotificationBatchBase.driveDcrQueueTargetDestination cmp = new skedNotificationBatchBase.driveDcrQueueTargetDestination();
        cmp.process(recordIds, newRecords);
        
        Test.stopTest();
    }
    
    static testmethod void testDriveLeadTargetDestination() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        List<sObject> secondList = new List<sObject>();
        sked__Job__c job = new sked__Job__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id,
            sked_Resource_Role__c = 'Charge',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked__Region__c = testRegion1.Id
        );
        secondList.add(job);
        insert secondList;
        
        sked__Job_Allocation__c testResource1_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testVehicle1.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED
        );
        insert testResource1_job1;
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testResource1_job1.Id);
        
        List<SObject> newRecords = new List<SObject>();
        newRecords.add(testResource1_job1);
        
        skedNotificationBatchBase.driveLeadTargetDestination cmp = new skedNotificationBatchBase.driveLeadTargetDestination();
        cmp.process(recordIds, newRecords);
        
        Test.stopTest();
    }
    
    static testmethod void testLogisticChangeRender() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testVehicle1 = (sked__Resource__c)mapTestData.get('testVehicle1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        testDrive1.sked_Drive_Date__c = system.today().addDays(30);
        update testDrive1;
        
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(testDrive1.Id);
        
        List<sked_Drive__c> newRecords = new List<sked_Drive__c>();
        sked_Drive__c newTestDrive1 = new sked_Drive__c(
        	Id = testDrive1.Id,
            Name = testDrive1.Name,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_WB_Projected_Procedures__c = testDrive1.sked_WB_Projected_Procedures__c + 10
        );
        newRecords.add(newTestDrive1);
        
        Map<Id, sked_Drive__c> oldMap = new Map<Id, sked_Drive__c>();
        oldMap.put(testDrive1.Id, testDrive1);
        
        skedNotificationBatchBase.logisticChangeRender cmp = new skedNotificationBatchBase.logisticChangeRender();
        cmp.process(recordIds, newRecords, oldMap);
        
        Test.stopTest();
    }
    
}