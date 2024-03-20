@isTest
private class skedResourceHoursRecordBatch_Test {
    @isTest
    static void skedResourceHoursRecordBatch_JobAllocation_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        List<sked__Job_Allocation__c> testJobAllocations = [SELECT Id FROM sked__Job_Allocation__c];
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked__Job_Allocation__c jobAllocation : testJobAllocations) {
            jobAllocationIds.add(jobAllocation.Id);
        }
        
        Test.startTest();
        
        Database.executeBatch(new skedResourceHoursRecordBatch(jobAllocationIds));
        
        Test.stopTest();
    }
    
    @isTest
    static void skedResourceHoursRecordBatch_Activity_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Activity__c testActivity = (sked__Activity__c) mapTestData.get('testActivity1');
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Resource__c = testResource.Id,
            sked__Activity__c = testActivity.Id
        );
        insert testActivityResource;
        
        List<sked__Activity__c> testActivities = [SELECT Id FROM sked__Activity__c];
        Set<Id> activityIds = new Set<Id>();
        for (sked__Activity__c activity : testActivities) {
            activityIds.add(activity.Id);
        }
        
        Test.startTest();
        
        Database.executeBatch(new skedResourceHoursRecordBatch(activityIds));
        
        Test.stopTest();
    }
    
    @isTest
    static void skedResourceHoursRecordBatch_Availability_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        sked__Availability__c testAvailability = (sked__Availability__c) mapTestData.get('testAvailability1');
        testAvailability.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
        testAvailability.sked__Is_Available__c = false;
        update testAvailability;
        
        List<sked__Availability__c> testAvailabilities = [SELECT Id FROM sked__Availability__c];
        Set<Id> availabilityIds = new Set<Id>();
        for (sked__Availability__c availability : testAvailabilities) {
            availabilityIds.add(availability.Id);
        }
        
        Test.startTest();
        
        Database.executeBatch(new skedResourceHoursRecordBatch(availabilityIds));
        
        Test.stopTest();
    }
    
    @isTest
    static void skedResourceHoursRecordBatch_ActivityResource_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(1), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Activity__c testActivity = (sked__Activity__c) mapTestData.get('testActivity1');
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Resource__c = testResource.Id,
            sked__Activity__c = testActivity.Id
        );
        insert testActivityResource;
        
        List<sked__Activity_Resource__c> testActivitieResources = [SELECT Id FROM sked__Activity_Resource__c];
        Set<Id> activityResourceIds = new Set<Id>();
        for (sked__Activity_Resource__c activityResource : testActivitieResources) {
            activityResourceIds.add(activityResource.Id);
        }
        
        Test.startTest();
        
        Database.executeBatch(new skedResourceHoursRecordBatch(activityResourceIds));
        
        Test.stopTest();
    }
    
}