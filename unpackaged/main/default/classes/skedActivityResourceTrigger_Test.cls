@isTest
public class skedActivityResourceTrigger_Test {
	
    static testmethod void testActivityGroup() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        sked__Activity__c skedGroupActivity = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = activityTypes.get(0),
        	sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE
        );
        insert skedGroupActivity;
        
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
        	sked__Activity__c = skedGroupActivity.Id,
            sked__Resource__c = testResource1.Id
        );
        insert skedActivityResource;
        
        //test rescheduling
        skedGroupActivity.sked__Start__c = skedGroupActivity.sked__Start__c.addDays(7);
        skedGroupActivity.sked__End__c = skedGroupActivity.sked__End__c.addDays(7);
        update skedGroupActivity;
        
        delete skedActivityResource;
        
        Test.stopTest();
    }

    @isTest
    static void createAvailabilityForOnCallResources_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        sked__Activity__c skedGroupActivity = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_ON_CALL,
        	sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE
        );
        insert skedGroupActivity;
        
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
        	sked__Activity__c = skedGroupActivity.Id,
            sked__Resource__c = testResource1.Id
        );

        delete [SELECT Id FROM sked__Availability__c];
        insert skedActivityResource;
        Test.stopTest();

        List<sked__Availability__c> testAvailability = [
            SELECT Id, sked__Start__c, sked__Finish__c, sked__Resource__c
            FROM sked__Availability__c
        ];
        System.assertEquals(1, testAvailability.size());
        System.assertEquals(skedGroupActivity.sked__Start__c, testAvailability[0].sked__Start__c);
        System.assertEquals(skedGroupActivity.sked__End__c, testAvailability[0].sked__Finish__c);
    }

    @isTest
    static void deleteAvailabilityForOnCallResources_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        sked__Activity__c skedGroupActivity = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_ON_CALL,
        	sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE
        );
        insert skedGroupActivity;
        
        delete [SELECT Id FROM sked__Availability__c];
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
        	sked__Activity__c = skedGroupActivity.Id,
            sked__Resource__c = testResource1.Id
        );
        insert skedActivityResource;
        delete skedActivityResource;
        Test.stopTest();

        List<sked__Availability__c> testAvailability = [
            SELECT Id
            FROM sked__Availability__c
        ];
        System.assertEquals(0, testAvailability.size());
    }

    @isTest
    static void syncOnCallAvailabilities_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        sked__Activity__c skedGroupActivity = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_ON_CALL,
        	sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE
        );
        insert skedGroupActivity;
        
        delete [SELECT Id FROM sked__Availability__c];
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
        	sked__Activity__c = skedGroupActivity.Id,
            sked__Resource__c = testResource1.Id
        );
        insert skedActivityResource;

        skedGroupActivity.sked__Start__c = testDataFactory.summary.startTime.addHours(10);
        skedGroupActivity.sked__End__c = testDataFactory.summary.startTime.addHours(10);
        update skedGroupActivity;
        Test.stopTest();

        List<sked__Availability__c> testAvailability = [
            SELECT Id, sked__Start__c, sked__Finish__c
            FROM sked__Availability__c
        ];
        System.assertEquals(skedGroupActivity.sked__Start__c, testAvailability[0].sked__Start__c);
        System.assertEquals(skedGroupActivity.sked__End__c, testAvailability[0].sked__Finish__c);
    }
}