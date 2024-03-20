@isTest
private class skedResourceOverrideUtils_Test {
    @isTest
    static void getJobAllocationsForOverrides_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Test.startTest();
        sked__Resource__c testResource = (sked__Resource__c)mapTestData.get('testResource1');
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');

        sked__Resource_Override__c testResourceOverride = new sked__Resource_Override__c(
            sked__Resource__c = testResource.Id,
            sked_Collection_Operation__c = testCo.Id,
            sked__End__c = System.now().addHours(6),
            sked__Start__c = System.now().addHours(6),
            sked_Travel_To_Start__c = System.now().addMinutes(5),
            sked_Travel_To_End__c = System.now().addMinutes(5),
            sked_Travel_Back_Start__c = System.now().addMinutes(5),
            sked_Travel_Back_End__c = System.now().addMinutes(5),
            sked_End_Date__c = System.today().addDays(5),
            sked_Start_Date__c = System.today().addDays(-5),
            sked_Travel_Back_End_Date__c = System.today(),
            sked_Travel_Back_Start_Date__c = System.today(),
            sked_Travel_To_End_Date__c = System.today(),
            sked_Travel_To_Start_Date__c = System.today(),
            sked_End_Time__c = System.now().time(),
            sked_Travel_Back_End_Time__c = System.now().addMinutes(5).time(),
            sked_Travel_Back_Start_Time__c = System.now().time(),
            sked_Travel_To_End_Time__c = System.now().addMinutes(5).time(),
            sked_Start_Time__c = System.now().time(),
            sked_Travel_To_Start_Time__c = System.now().addMinutes(5).time()
        );
        insert testResourceOverride;
    
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = testDataFactory.summary.startTime.addHours(11),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(12),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive1.Id
        );
        insert job;
        
        sked__Job_Allocation__c testResource_job1 = new sked__Job_Allocation__c(
        	sked__Job__c = job.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
        );
        insert testResource_job1;

        Map<Id, skedModels.startEnd> modelsByResource = new Map<Id, skedModels.startEnd>();
        skedModels.startEnd modelForResource = new skedModels.startEnd();
        modelForResource.startDate = Date.newInstance(testResourceOverride.sked__Start__c.year(), testResourceOverride.sked__Start__c.month(), testResourceOverride.sked__Start__c.day());
        modelForResource.endDate = Date.newInstance(testResourceOverride.sked__End__c.year(), testResourceOverride.sked__End__c.month(), testResourceOverride.sked__End__c.day());
        modelsByResource.put(testResourceOverride.sked__Resource__c, modelForResource);
        skedResourceOverrideUtils.getJobAllocationsForOverrides(modelsByResource);
        Test.stopTest();
    }
}