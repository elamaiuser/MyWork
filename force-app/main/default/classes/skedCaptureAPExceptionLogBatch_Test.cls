@isTest
private class skedCaptureAPExceptionLogBatch_Test {

    static testmethod void mainTest() {
		skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        
        sked__Activity__c testActivity = new sked__Activity__c(
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked__Type__c = 'Administration',
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(10),
            sked__Address__c = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom',
            sked__GeoLocation__Latitude__s = 51.508105,
            sked__GeoLocation__Longitude__s = -0.132901,
            sked_Is_Group_Activity__c = TRUE
        );
        insert testActivity;
        
        sked__Activity_Resource__c testActivityResource = new sked__Activity_Resource__c(
            sked__Activity__c = testActivity.Id,
            sked__Resource__c = testResource1.Id,
            sked_Start1__c = testActivity.sked__Start__c,
            sked_End__c = testActivity.sked__End__c
        );
        insert testActivityResource;
        
        Test.startTest();
        
        sked__Availability_Pattern_Resource__c testPatternResource1 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = testDataFactory.summary.startTime
        );
        insert testPatternResource1;
        
        Set<Id> activityResourceIds = new Set<Id>();
        activityResourceIds.add(testActivityResource.Id);
        
        Database.executeBatch(new skedCaptureAPExceptionLogBatch(activityResourceIds));
        
        List<skedHC__Exception__c> exceptionLog = [
            SELECT Id
            FROM skedHC__Exception__c
            WHERE skedHC__Activity__c = :testActivityResource.sked__Activity__c
            AND skedHC__Resource__c = :testResource1.Id
            AND sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_ACTIVITY_OUTSIDE_OF_AVAILABILITY_PATTERN
        ];
        
        Assert.isTrue(exceptionLog.size() == 1);
        
        Test.stopTest();
    }

}