@isTest
private class skedSyncResourceHoursOneTime_Test {
    @isTest
    static void skedSyncResourceHoursOneTime_JobAllocations_Test() {   
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();

        delete [SELECT Id FROM sked_Resource_Hours_Record__c];

        Test.startTest();
            Database.executeBatch(new skedSyncResourceHoursOneTime_Batch(0), 1);
        Test.stopTest();

        List<sked_Resource_Hours_Record__c> testResourceHoursRecords = [SELECT Id FROM sked_Resource_Hours_Record__c];
        System.assert(!testResourceHoursRecords.isEmpty());
    }

    @isTest
    static void skedSyncResourceHoursOneTime_Availability_Test() {   
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();

        delete [SELECT Id FROM sked_Resource_Hours_Record__c];

        Test.startTest();
            Database.executeBatch(new skedSyncResourceHoursOneTime_Batch(1), 1);
        Test.stopTest();

        List<sked_Resource_Hours_Record__c> testResourceHoursRecords = [SELECT Id FROM sked_Resource_Hours_Record__c];
        System.assert(!testResourceHoursRecords.isEmpty());
    }

    @isTest
    static void skedSyncResourceHoursOneTime_Activity_Test() {   
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();

        delete [SELECT Id FROM sked_Resource_Hours_Record__c];

        Test.startTest();
            Database.executeBatch(new skedSyncResourceHoursOneTime_Batch(2), 1);
        Test.stopTest();

        List<sked_Resource_Hours_Record__c> testResourceHoursRecords = [SELECT Id FROM sked_Resource_Hours_Record__c];
        System.assert(!testResourceHoursRecords.isEmpty());
    }

    @isTest
    static void skedSyncResourceHoursOneTime_ActivityResource_Test() {   
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();

        delete [SELECT Id FROM sked_Resource_Hours_Record__c];

        sked__Activity__c testActivity = (sked__Activity__c) mapTestData.get('testActivity1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = testActivity.Id,
            sked__Resource__c = testResource.Id
        );
        insert testActivityResource;

        Test.startTest();
            Database.executeBatch(new skedSyncResourceHoursOneTime_Batch(3), 1);
        Test.stopTest();

        List<sked_Resource_Hours_Record__c> testResourceHoursRecords = [SELECT Id FROM sked_Resource_Hours_Record__c];
        System.assert(!testResourceHoursRecords.isEmpty());
    }
}