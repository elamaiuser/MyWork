@IsTest
public class BSF_Batch_ActivityTimeBlock_Test {

    @testSetup
    static void setupData() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, SObject> testData = testDataSetup.createAndInsertCommonObjects();

        Biomed_Collection_Op_Center__c co = (Biomed_Collection_Op_Center__c) testData.get('COLLECTION_OPP');
        co.External_Id__c = 'TEST-ACT-CO-1';
        insert co;

        Biomed_Collection_Op_Center__c co2 = co.clone(false, true, false, false);
        co2.Name = 'Activity Collection Operation 2';
        co2.External_Id__c = 'TEST-ACT-CO-2';
        insert co2;
    }

    @isTest
    static void testExactMatch_AssignsTimeBlock() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Exact',
            Start_Time__c = Time.newInstance(8, 0, 0, 0),
            End_Time__c = Time.newInstance(10, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = coId,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = activityDate.addDays(-1),
            Effective_End_Date__c = activityDate.addDays(1)
        );

        sked__Activity__c act = buildActivity(coId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        insertActivity(act);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(tb.Id, act.sked_Time_Block__c, 'An activity whose start/end exactly matches a time block should be assigned to it.');
    }

    @isTest
    static void testFitsWithinWiderTimeBlock_AssignsTimeBlock() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Full Day',
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = coId,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = activityDate.addDays(-1),
            Effective_End_Date__c = activityDate.addDays(1)
        );

        sked__Activity__c act = buildActivity(coId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        insertActivity(act);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(tb.Id, act.sked_Time_Block__c, 'An activity fully contained within a wider time block should be assigned to it, even without matching its start/end exactly.');
    }

    @isTest
    static void testExtendsBeyondTimeBlock_LeavesTimeBlockBlank() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Morning',
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Time__c = Time.newInstance(12, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = coId,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = activityDate.addDays(-1),
            Effective_End_Date__c = activityDate.addDays(1)
        );

        sked__Activity__c act = buildActivity(coId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(13, 0, 0, 0));
        insertActivity(act);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(null, act.sked_Time_Block__c, 'An activity extending beyond its only applicable time block on both ends should be left unassigned.');
    }

    @isTest
    static void testNoApplicableTimeBlock_LeavesActivityUnchanged() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();

        sked__Activity__c act = buildActivity(coId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        insertActivity(act);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(null, act.sked_Time_Block__c, 'With no Collection Operation Time Block configured, no assignment should occur.');
    }

    @isTest
    static void testFitsMultipleTimeBlocks_LeavesBlank() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tbOne = new Time_Block__c(
            Name = 'TB Narrow',
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        Time_Block__c tbTwo = new Time_Block__c(
            Name = 'TB Wide',
            Start_Time__c = Time.newInstance(6, 0, 0, 0),
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert new List<Time_Block__c>{ tbOne, tbTwo };

        insert new List<Collection_Operation_Time_Block__c>{
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = coId,
                Time_Block__c = tbOne.Id,
                Effective_Start_Date__c = activityDate.addDays(-1),
                Effective_End_Date__c = activityDate.addDays(1)
            ),
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = coId,
                Time_Block__c = tbTwo.Id,
                Effective_Start_Date__c = activityDate.addDays(-1),
                Effective_End_Date__c = activityDate.addDays(1)
            )
        };

        sked__Activity__c act = buildActivity(coId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        insertActivity(act);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(null, act.sked_Time_Block__c, 'When an activity fits inside more than one time block, the assignment is ambiguous and should be left blank.');
    }

    @isTest
    static void testActivityWithResourceAssignment_ExcludedFromProcessing() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Resourced',
            Start_Time__c = Time.newInstance(8, 0, 0, 0),
            End_Time__c = Time.newInstance(10, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = coId,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = activityDate.addDays(-1),
            Effective_End_Date__c = activityDate.addDays(1)
        );

        sked__Activity__c act = buildActivity(coId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        insertActivity(act);

        Id resourceId = createTestResource(coId);

        skedHubBase.BypassInsertTriggers = true;
        insert new sked__Activity_Resource__c(
            sked__Activity__c = act.Id,
            sked__Resource__c = resourceId
        );
        skedHubBase.BypassInsertTriggers = false;

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(null, act.sked_Time_Block__c, 'An activity that already has a resource assignment should never be touched by the batch, even with an exact-matching time block available.');
    }

    @isTest
    static void testAlreadyHasTimeBlock_NotProcessedByBatch() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c originalTb = new Time_Block__c(
            Name = 'TB Original',
            Start_Time__c = Time.newInstance(6, 0, 0, 0),
            End_Time__c = Time.newInstance(12, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        Time_Block__c newExactTb = new Time_Block__c(
            Name = 'TB New Exact',
            Start_Time__c = Time.newInstance(8, 0, 0, 0),
            End_Time__c = Time.newInstance(10, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert new List<Time_Block__c>{ originalTb, newExactTb };

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = coId,
            Time_Block__c = newExactTb.Id,
            Effective_Start_Date__c = activityDate.addDays(-1),
            Effective_End_Date__c = activityDate.addDays(1)
        );

        sked__Activity__c act = buildActivity(coId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        act.sked_Time_Block__c = originalTb.Id;
        insertActivity(act);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(originalTb.Id, act.sked_Time_Block__c, 'An activity that already has a time block assigned should not be reprocessed by the batch.');
    }

    @isTest
    static void testWrongDayOfWeek_LeavesActivityUnchanged() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();
        String otherDay = dayName == 'Monday' ? 'Tuesday' : 'Monday';

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Other Day',
            Start_Time__c = Time.newInstance(8, 0, 0, 0),
            End_Time__c = Time.newInstance(10, 0, 0, 0),
            Days_of_Week__c = otherDay
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = coId,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = activityDate.addDays(-1),
            Effective_End_Date__c = activityDate.addDays(1)
        );

        sked__Activity__c act = buildActivity(coId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        insertActivity(act);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(null, act.sked_Time_Block__c, 'A time block that does not apply to the activity day of week should not be assigned.');
    }

    @isTest
    static void testOutsideEffectiveDateRange_LeavesActivityUnchanged() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Expired',
            Start_Time__c = Time.newInstance(8, 0, 0, 0),
            End_Time__c = Time.newInstance(10, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = coId,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = activityDate.addDays(-30),
            Effective_End_Date__c = activityDate.addDays(-10)
        );

        sked__Activity__c act = buildActivity(coId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        insertActivity(act);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(null, act.sked_Time_Block__c, 'A time block whose effective date range does not cover the activity date should not be assigned.');
    }

    @isTest
    static void testConstructorScopesToProvidedCollectionOperationIds() {
        Id inScopeCoId = collectionOperationId('TEST-ACT-CO-1');
        Id outOfScopeCoId = collectionOperationId('TEST-ACT-CO-2');
        Date activityDate = sharedActivityDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tbInScope = new Time_Block__c(
            Name = 'TB CO1',
            Start_Time__c = Time.newInstance(8, 0, 0, 0),
            End_Time__c = Time.newInstance(10, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        Time_Block__c tbOutOfScope = new Time_Block__c(
            Name = 'TB CO2',
            Start_Time__c = Time.newInstance(8, 0, 0, 0),
            End_Time__c = Time.newInstance(10, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert new List<Time_Block__c>{ tbInScope, tbOutOfScope };

        insert new List<Collection_Operation_Time_Block__c>{
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = inScopeCoId,
                Time_Block__c = tbInScope.Id,
                Effective_Start_Date__c = activityDate.addDays(-1),
                Effective_End_Date__c = activityDate.addDays(1)
            ),
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = outOfScopeCoId,
                Time_Block__c = tbOutOfScope.Id,
                Effective_Start_Date__c = activityDate.addDays(-1),
                Effective_End_Date__c = activityDate.addDays(1)
            )
        };

        sked__Activity__c inScopeAct = buildActivity(inScopeCoId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        sked__Activity__c outOfScopeAct = buildActivity(outOfScopeCoId, activityDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        insertActivities(new List<sked__Activity__c>{ inScopeAct, outOfScopeAct });

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(new Set<Id>{ inScopeCoId }), 200);
        Test.stopTest();

        inScopeAct = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :inScopeAct.Id];
        outOfScopeAct = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :outOfScopeAct.Id];

        System.assertEquals(tbInScope.Id, inScopeAct.sked_Time_Block__c, 'Activity under the scoped Collection Operation should be processed.');
        System.assertEquals(null, outOfScopeAct.sked_Time_Block__c, 'Activity under a Collection Operation outside the provided scope should be left untouched.');
    }

    @isTest
    static void testPastStartDate_ExcludedFromProcessing() {
        Id coId = collectionOperationId('TEST-ACT-CO-1');
        Date pastDate = Date.today().addDays(-1);
        String dayName = DateTime.newInstance(pastDate, Time.newInstance(0, 0, 0, 0)).format('EEEE');

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Past',
            Start_Time__c = Time.newInstance(8, 0, 0, 0),
            End_Time__c = Time.newInstance(10, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = coId,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = pastDate.addDays(-1),
            Effective_End_Date__c = pastDate.addDays(1)
        );

        sked__Activity__c act = buildActivity(coId, pastDate, dayName, Time.newInstance(8, 0, 0, 0), Time.newInstance(10, 0, 0, 0));
        insertActivity(act);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_ActivityTimeBlockAssignment(), 200);
        Test.stopTest();

        act = [SELECT sked_Time_Block__c FROM sked__Activity__c WHERE Id = :act.Id];
        System.assertEquals(null, act.sked_Time_Block__c, 'An activity dated in the past should not be picked up by the batch at all.');
    }

    private static Id createTestResource(Id coId) {
        Map<String, Schema.RecordTypeInfo> territoryRecordTypes = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName();

        sked_Territory__c division = new sked_Territory__c(
            RecordTypeId = territoryRecordTypes.get('Division').getRecordTypeId(),
            Name = 'ATB Test Division',
            Start_Date__c = Date.today().addDays(-500),
            End_Date__c = Date.today().addDays(500)
        );
        TriggerHandler.bypass('TerritoryTriggerHandler');
        insert division;

        sked_Territory__c region = new sked_Territory__c(
            RecordTypeId = territoryRecordTypes.get('ARC Region').getRecordTypeId(),
            Name = 'ATB Test ARC Region',
            Start_Date__c = Date.today().addDays(-500),
            End_Date__c = Date.today().addDays(500),
            sked_Parent__c = division.Id
        );
        TriggerHandler.bypass('TerritoryTriggerHandler');
        insert region;

        sked_Territory__c district = new sked_Territory__c(
            RecordTypeId = territoryRecordTypes.get('District').getRecordTypeId(),
            Name = 'ATB Test District',
            Start_Date__c = Date.today().addDays(-500),
            End_Date__c = Date.today().addDays(500),
            sked_Parent__c = region.Id
        );
        TriggerHandler.bypass('TerritoryTriggerHandler');
        insert district;

        sked__Region__c skedRegion = new sked__Region__c(
            Name = 'ATB Test Region',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = coId,
            sked_Territory__c = district.Id
        );
        insert skedRegion;

        Id staffRecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Staff').getRecordTypeId();
        sked__Resource__c resource = new sked__Resource__c(
            RecordTypeId = staffRecordTypeId,
            sked__Email__c = 'atbtestresource@example.com',
            sked_Employee_ID__c = 'ATB-TEST-001',
            sked__Is_Active__c = true,
            sked_Title__c = 'Test',
            sked_First_Name__c = 'ATB',
            sked_Preferred_First_Name__c = 'ATB',
            sked_Last_Name__c = 'TestResource',
            sked_ULID__c = 'ATB-ULID-001',
            sked__Category__c = 'Employee',
            sked_Employment_Status__c = 'Active',
            sked_Timezone__c = 'America/Los_Angeles',
            sked__Resource_Type__c = 'Person',
            sked__Primary_Region__c = skedRegion.Id
        );

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('ResourceTriggerHandler');
        insert resource;
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;

        return resource.Id;
    }

    private static void insertActivity(sked__Activity__c act) {
        insertActivities(new List<sked__Activity__c>{ act });
    }

    private static void insertActivities(List<sked__Activity__c> acts) {
        skedHubBase.BypassInsertTriggers = true;
        insert acts;
        skedHubBase.BypassInsertTriggers = false;
    }

    private static sked__Activity__c buildActivity(Id coId, Date activityDate, String dayName, Time startTime, Time endTime) {
        return new sked__Activity__c(
            sked_Collection_Operation__c = coId,
            sked_Start_Date__c = activityDate,
            sked_Day_of_Week__c = dayName,
            sked_Start_Time__c = startTime,
            sked_End_Time__c = endTime,
            sked__Start__c = DateTime.newInstance(activityDate, startTime),
            sked__End__c = DateTime.newInstance(activityDate, endTime)
        );
    }

    private static Id collectionOperationId(String externalId) {
        return [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE External_Id__c = :externalId LIMIT 1].Id;
    }

    private static Date sharedActivityDate() {
        return Date.today().addDays(14);
    }

    private static String sharedDayOfWeek() {
        return DateTime.newInstance(sharedActivityDate(), Time.newInstance(0, 0, 0, 0)).format('EEEE');
    }
}
