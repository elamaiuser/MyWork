@isTest
private class slwcAvailabilityPatternService_Test {
    @isTest
    static void saveAvailabilityPattern_Test() {
        sked__Availability_Pattern__c testPattern = [
            SELECT Id, sked__Pattern__c, sked__Hash__c
            FROM sked__Availability_Pattern__c LIMIT 1
        ][0];

        sked__Resource__c testResource = [SELECT Id FROM sked__Resource__c LIMIT 1][0];

        List<String> weekdays = new List<string> {'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'};
        
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);

        skedAvailabilityPatternData patternData = new skedAvailabilityPatternData();
        patternData.type = 'weekly';
        patternData.repeatWeeks = 5;
        patternData.days = new List<skedAvailabilityPatternData.dayModel>();
        
        for (String weekday : weekdays) {
            skedAvailabilityPatternData.intervalModel interval = new skedAvailabilityPatternData.intervalModel();
            interval.startTime = '08:00';
            interval.endTime = '17:00';

            skedAvailabilityPatternData.dayModel day = new skedAvailabilityPatternData.dayModel();
            day.weekday = weekday;
            day.intervals = new List<skedAvailabilityPatternData.intervalModel>();
            day.intervals.add(interval);
            patternData.days.add(day);
        }

        slwcAvailabilityPatternService.availabilityPatternResource resource = new slwcAvailabilityPatternService.availabilityPatternResource();
        resource.resourceId = testResource.Id;

        slwcAvailabilityPatternService.availabilityPattern model = new slwcAvailabilityPatternService.availabilityPattern();
        model.name = 'Test Pattern';
        model.description = 'Test Pattern Description';
        model.patternData = patternData;
        model.pattern = testPattern.sked__Pattern__c;
        model.hash = testPattern.sked__Hash__c;
        model.availabilityPatternResources = new List<slwcAvailabilityPatternService.availabilityPatternResource>();
        model.availabilityPatternResources.add(resource);

        Test.startTest();
            slwcAuraResult result = slwcAvailabilityPatternService.saveAvailabilityPattern(model);
        Test.stopTest();

        System.assert(result.success);
        System.assertNotEquals(null, result.returnedData);
    }

    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }
}