@isTest
private class skedCancelAvailabilityPatternBatch_Test {
    @isTest
    static void skedCancelAvailabilityPatternBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked__Recurring_Schedule__c testSchedule = new sked__Recurring_Schedule__c();
        insert testSchedule;

        List<sked__Availability__c> availabilities = new List<sked__Availability__c>();
        for (Integer i = 0; i < 5; i++) {
            availabilities.add(new sked__Availability__c(
                sked__Resource__c = testResource.Id,
                sked_Recurring_Schedule__c = testSchedule.Id,
                sked__Is_Available__c = TRUE,
                sked__Status__c = 'Approved',
                sked__Start__c = Datetime.newInstance(System.today().addDays(i), Time.newInstance(0,0,0,0)),
                sked__Finish__c = Datetime.newInstance(System.today().addDays(i), Time.newInstance(23,59,59,0)),
                sked_Bypass_Auto_Approval_Process__c = FALSE,
                sked_Custom_Status__c = 'Approved',
                sked__Type__c = 'Overtime'
            ));
        }

        delete [SELECT Id FROM sked__Availability__c];
        insert availabilities;

        sked__Availability__c testAvailability = [
            SELECT Id, sked_Start_Date__c
            FROM sked__Availability__c
            WHERE Id = :availabilities[0].Id
        ];
        Database.executeBatch(new skedCancelAvailabilityPatternBatch(testAvailability, testSchedule.Id, 'same_weekday'), 100);
        Test.stopTest();

        List<sked__Availability__c> cancelledAvailabilities = [SELECT Id FROM sked__Availability__c WHERE sked_Custom_Status__c = 'Cancelled'];
        System.assert(!cancelledAvailabilities.isEmpty());
    }
}