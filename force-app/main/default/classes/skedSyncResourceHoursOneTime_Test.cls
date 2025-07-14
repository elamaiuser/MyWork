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

        Test.startTest();
            Database.executeBatch(new skedSyncResourceHoursOneTime_Batch(3), 1);
        Test.stopTest();

        List<sked_Resource_Hours_Record__c> testResourceHoursRecords = [SELECT Id FROM sked_Resource_Hours_Record__c];
        System.assert(!testResourceHoursRecords.isEmpty());
    }
}