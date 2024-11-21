@isTest
private class skedCreateBulkActivity_Test {
    @isTest
    static void skedCreateBulkActivity_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, SObject> mapTestData = testDataFactory.setupCommonTestData();

        skedModels.recurringSchedule testRecurringSchedule = new skedModels.recurringSchedule();
        testRecurringSchedule.events = new List<skedModels.event>();

        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Territory__c testTerritory = (sked_Territory__c) mapTestData.get('testTerritory1');

        for (Integer i = 0; i < 200; i++) {
            DateTime activityDate = System.now().addDays(i);
            skedModels.activity testActivityModel = new skedModels.activity();
            testActivityModel.isGroupActivity = true;
            testActivityModel.activityTitle = 'Test Activity';
            testActivityModel.address = new skedModels.address();
            testActivityModel.address.fullAddress = 'Strawberry Ln, Louisville, KY, USA';
            testActivityModel.address.geometry = new skedModels.geometry(38.1716096, -85.7522617);
            testActivityModel.start = activityDate;
            testActivityModel.startDate = '' + activityDate.year() + '-' + activityDate.month() + '-' + activityDate.day();
            testActivityModel.startTime = 500;
            testActivityModel.finish = activityDate.addHours(1);
            testActivityModel.endDate = '' + activityDate.year() + '-' + activityDate.month() + '-' + activityDate.day();
            testActivityModel.endTime = 600;
            testActivityModel.biomedCollectionOpId = testCo.Id;
            testActivityModel.districtId = testTerritory.Id;
            testActivityModel.eventType = 'Administrative';
            testActivityModel.scheduleId = 'temp_17029166276141';
            testRecurringSchedule.events.add(testActivityModel);
        }

        Test.startTest();
        Database.executeBatch(new skedCreateBulkActivityBatch(testRecurringSchedule, UserInfo.getUserId(), 0));
        Test.stopTest();

        List<sked__Activity__c> activities = [SELECT Id FROM sked__Activity__c];
        Assert.areEqual(200, activities.size());
    }
}