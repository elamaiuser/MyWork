@isTest
private class skedSlotConfigHandler_Test {

    private static final String WHOLE_BLOOD_JSON = '{"slotDuration":15}';

    @testSetup
    static void setupTestData() {
        skedHubBase.setBypassAllTriggers(true);
        insert new Biomed_Collection_Op_Center__c(
            Name = 'Slot Config Collection Operation',
            External_Id__c = 'slot-config-external-id',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            sked_Low_Weight__c = 10,
            sked_Medium_Weight__c = 15,
            sked_High_Weight__c = 25,
            sked_Role_Priorities_Weight__c = 10
        );
        skedHubBase.setBypassAllTriggers(false);
    }

    @isTest
    static void insert_storesAnOpenEndedPeriodAsTheMaxDateSentinel() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);

        Test.startTest();
        insert slotConfig;
        Test.stopTest();

        sked_Collection_Operation_Slot_Config__c savedConfig = [
            SELECT sked_Effective_End_Date__c FROM sked_Collection_Operation_Slot_Config__c WHERE Id = :slotConfig.Id
        ];
        System.assertEquals(
            skedDateTimeUtils.MAX_DATE,
            savedConfig.sked_Effective_End_Date__c,
            'A blank Effective End Date must be stored as the max date sentinel so the resolver query never special-cases null'
        );
    }

    @isTest
    static void insert_rejectsAPayloadThatIsNotValidForItsProcedureType() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);
        slotConfig.sked_Slot_Configuration__c = '{"slotDuration":7}';

        Test.startTest();
        String errorMessage = insertExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(errorMessage.contains('divide 60 evenly'), 'The trigger must reject an invalid payload regardless of entry point, got: ' + errorMessage);
    }

    @isTest
    static void insert_rejectsAPayloadMissingARequiredField() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);
        slotConfig.sked_Procedure_Type__c = skedConstants.SLOT_CONFIG_PROCEDURE_TYPE_POWER_RED;
        slotConfig.sked_Slot_Configuration__c = '{"roundInterval":60}';

        Test.startTest();
        String errorMessage = insertExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(errorMessage.contains('missing a required field'), 'A Power Red payload without every field must be rejected, got: ' + errorMessage);
    }

    @isTest
    static void insert_rejectsAPayloadCarryingAFieldNoGeneratorConsumes() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);
        slotConfig.sked_Slot_Configuration__c = '{"slotDuration":15,"tailBufferMinutes":30}';

        Test.startTest();
        String errorMessage = insertExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(errorMessage.contains('unexpected field'), 'A field no generator consumes must be rejected, got: ' + errorMessage);
    }

    @isTest
    static void insert_rejectsANonPositiveValue() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);
        slotConfig.sked_Slot_Configuration__c = '{"slotDuration":0}';

        Test.startTest();
        String errorMessage = insertExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(errorMessage.contains('positive whole number'), 'A zero slot duration must be rejected, got: ' + errorMessage);
    }

    @isTest
    static void insert_rejectsMalformedJson() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);
        slotConfig.sked_Slot_Configuration__c = 'not json';

        Test.startTest();
        String errorMessage = insertExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(errorMessage.contains('not valid JSON'), 'An unparseable payload must be rejected, got: ' + errorMessage);
    }

    @isTest
    static void insert_rejectsABlankPayload() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);
        slotConfig.sked_Slot_Configuration__c = NULL;

        Test.startTest();
        String errorMessage = insertExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(errorMessage.contains('Slot Configuration is required'), 'A row without a payload must be rejected, got: ' + errorMessage);
    }

    @isTest
    static void insert_acceptsAValidPowerRedPayload() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);
        slotConfig.sked_Procedure_Type__c = skedConstants.SLOT_CONFIG_PROCEDURE_TYPE_POWER_RED;
        slotConfig.sked_Slot_Configuration__c = '{"roundInterval":60,"numberOfGroups":2,"groupInterval":30,"slotDuration":60}';

        Test.startTest();
        insert slotConfig;
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM sked_Collection_Operation_Slot_Config__c], 'The Power Red payload the admin UI sends must be accepted');
    }

    @isTest
    static void insert_rejectsAFixedSiteRowWithoutAnOperationType() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);
        slotConfig.sked_Drive_Type__c = skedConstants.DRIVE_TYPE_FIXED_SITE;

        Test.startTest();
        String errorMessage = insertExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(
            errorMessage.contains('Fixed Site Operation Type is required'),
            'A Fixed Site row without an operation type has no org-wide default to resolve against, got: ' + errorMessage
        );
    }

    @isTest
    static void insert_rejectsAMobileRowCarryingAnOperationType() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today(), NULL);
        slotConfig.sked_Fixed_Site_Operation_Type__c = skedConstants.OPERATION_TYPE_WB;

        Test.startTest();
        String errorMessage = insertExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(errorMessage.contains('must be blank for a Mobile'), 'A Mobile row must not carry a fixed site operation type, got: ' + errorMessage);
    }

    @isTest
    static void insert_rejectsAStartDateAfterItsEndDate() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today().addDays(10), Date.today());

        Test.startTest();
        String errorMessage = insertExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(errorMessage.contains('on or before'), 'An inverted effective period must be rejected, got: ' + errorMessage);
    }

    @isTest
    static void insert_rejectsAPeriodOverlappingAnExistingOne() {
        insert buildSlotConfig(Date.today(), Date.today().addDays(30));

        Test.startTest();
        String errorMessage = insertExpectingFailure(buildSlotConfig(Date.today().addDays(15), Date.today().addDays(45)));
        Test.stopTest();

        System.assert(errorMessage.contains('overlaps an existing configuration'), 'Overlapping effective periods make resolution ambiguous, got: ' + errorMessage);
    }

    @isTest
    static void insert_allowsAGapBetweenPeriods() {
        insert buildSlotConfig(Date.today(), Date.today().addDays(30));

        Test.startTest();
        insert buildSlotConfig(Date.today().addDays(40), Date.today().addDays(60));
        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT COUNT() FROM sked_Collection_Operation_Slot_Config__c],
            'A deliberate gap is allowed - those dates fall through to the org-wide default'
        );
    }

    @isTest
    static void insert_allowsTheSamePeriodForADifferentProcedureType() {
        insert buildSlotConfig(Date.today(), Date.today().addDays(30));

        sked_Collection_Operation_Slot_Config__c powerRedConfig = buildSlotConfig(Date.today(), Date.today().addDays(30));
        powerRedConfig.sked_Procedure_Type__c = skedConstants.SLOT_CONFIG_PROCEDURE_TYPE_POWER_RED;
        powerRedConfig.sked_Slot_Configuration__c = '{"roundInterval":60,"numberOfGroups":2,"groupInterval":30,"slotDuration":60}';

        Test.startTest();
        insert powerRedConfig;
        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT COUNT() FROM sked_Collection_Operation_Slot_Config__c],
            'Overlap is only ambiguous within one Collection Operation, Drive Type and Procedure Type'
        );
    }

    @isTest
    static void insert_rejectsTwoOverlappingRowsAddedInTheSameTransaction() {
        List<sked_Collection_Operation_Slot_Config__c> slotConfigs = new List<sked_Collection_Operation_Slot_Config__c>{
            buildSlotConfig(Date.today(), Date.today().addDays(30)),
            buildSlotConfig(Date.today().addDays(10), Date.today().addDays(40))
        };

        Test.startTest();
        String errorMessage = '';
        try {
            insert slotConfigs;
        }
        catch (DmlException ex) {
            errorMessage = ex.getDmlMessage(0);
        }
        Test.stopTest();

        System.assert(errorMessage.contains('overlaps an existing configuration'), 'Rows added together must be checked against each other, got: ' + errorMessage);
    }

    @isTest
    static void update_rejectsAStartDateChangeOnceThePeriodHasTakenEffect() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today().addDays(-1), NULL);
        insert slotConfig;

        Test.startTest();
        slotConfig.sked_Effective_Start_Date__c = Date.today().addDays(5);
        String errorMessage = updateExpectingFailure(slotConfig);
        Test.stopTest();

        System.assert(errorMessage.contains('cannot be changed'), 'Moving the start date of a live period would rewrite history, got: ' + errorMessage);
    }

    @isTest
    static void update_allowsAnEndDateChangeOnceThePeriodHasTakenEffect() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today().addDays(-1), NULL);
        insert slotConfig;

        Test.startTest();
        slotConfig.sked_Effective_End_Date__c = Date.today().addDays(30);
        update slotConfig;
        Test.stopTest();

        sked_Collection_Operation_Slot_Config__c savedConfig = [
            SELECT sked_Effective_End_Date__c FROM sked_Collection_Operation_Slot_Config__c WHERE Id = :slotConfig.Id
        ];
        System.assertEquals(
            Date.today().addDays(30),
            savedConfig.sked_Effective_End_Date__c,
            'Closing an open period is how a live configuration is superseded'
        );
    }

    @isTest
    static void update_allowsAStartDateChangeWhileThePeriodIsStillInTheFuture() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(Date.today().addDays(10), NULL);
        insert slotConfig;

        Test.startTest();
        slotConfig.sked_Effective_Start_Date__c = Date.today().addDays(20);
        update slotConfig;
        Test.stopTest();

        sked_Collection_Operation_Slot_Config__c savedConfig = [
            SELECT sked_Effective_Start_Date__c FROM sked_Collection_Operation_Slot_Config__c WHERE Id = :slotConfig.Id
        ];
        System.assertEquals(Date.today().addDays(20), savedConfig.sked_Effective_Start_Date__c, 'A period that has not started yet is still editable');
    }

    /*********************************************************** Test helpers ***********************************************************/
    private static sked_Collection_Operation_Slot_Config__c buildSlotConfig(Date startDate, Date endDate) {
        return new sked_Collection_Operation_Slot_Config__c(
            sked_Collection_Operation__c = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1].Id,
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_MOBILE,
            sked_Procedure_Type__c = skedConstants.SLOT_CONFIG_PROCEDURE_TYPE_WHOLE_BLOOD,
            sked_Slot_Configuration__c = WHOLE_BLOOD_JSON,
            sked_Effective_Start_Date__c = startDate,
            sked_Effective_End_Date__c = endDate
        );
    }

    private static String insertExpectingFailure(sked_Collection_Operation_Slot_Config__c slotConfig) {
        try {
            insert slotConfig;
            return '';
        }
        catch (DmlException ex) {
            return ex.getDmlMessage(0);
        }
    }

    private static String updateExpectingFailure(sked_Collection_Operation_Slot_Config__c slotConfig) {
        try {
            update slotConfig;
            return '';
        }
        catch (DmlException ex) {
            return ex.getDmlMessage(0);
        }
    }
}
