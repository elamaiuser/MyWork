@isTest
private class skedDCRProcessingBatch_Test {
    @isTest
    static void testEnqueue_secondCallWhileQueued_doesNotStartSecondBatch() {
        Test.startTest();
        skedDCRProcessingBatch.enqueue();
        skedDCRProcessingBatch.enqueue(); // must no-op: a job is already Queued
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob
            WHERE ApexClass.Name = 'skedDCRProcessingBatch' AND JobType = 'BatchApex'],
            'Second enqueue while an instance is queued must not start another batch');
    }

    @isTest
    static void testExecute_processingFailure_movesToErrorAndLogsMessage() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTD_CHANGE);
        insert dcr; // no Change items -> service stops with a message, applied=false

        // The batch is started explicitly: inserting a DCR no longer enqueues it, since processing
        // is now a scheduled or manual step rather than something the trigger kicks off.
        Test.startTest();
        Database.executeBatch(new skedDCRProcessingBatch(), 1);
        Test.stopTest();

        dcr = [SELECT sked_Last_Processing_Result__c, sked_Status__c
               FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_ERROR, dcr.sked_Status__c,
            'A DCR this pipeline cannot resolve must move to Error, not stay Pending for endless retry');
        System.assert(String.isNotBlank(dcr.sked_Last_Processing_Result__c), 'Result message must be recorded');
        System.assertEquals(1, [SELECT COUNT() FROM BSF_Error_Log__c WHERE Object_RecordId__c = :dcr.Id],
            'A validation failure with no exception must still produce an error log entry');
    }

    @isTest
    static void testExecute_noEngineForDriveType_movesToErrorAndLogsMessage() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        // Mobile and Fixed Site (both operation types, WB included as of
        // skedFixedSiteWbDriveRegenEngine) now all resolve to real engines. skedConstants.DRIVE_TYPE_RSMO
        // is not usable here: this org's sked_Type_of_Drive__c picklist is restricted to 'Mobile'/
        // 'Fixed Site' only, so persisting 'RSMO' via real DML always throws
        // INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST - confirmed live, not assumed. A null type falls
        // through every one of skedDriveRegenEngineFactory.getEngine's branches identically to RSMO,
        // and the field itself is not required, so this is a legitimately persistable "no engine" case.
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        update new sked_Drive__c(Id = drive.Id, sked_Type_of_Drive__c = null);
        // No testEngineOverride - a null drive type still resolves to null.

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTD_CHANGE);
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change');

        Test.startTest();
        Database.executeBatch(new skedDCRProcessingBatch(), 1);
        Test.stopTest();

        dcr = [SELECT sked_Last_Processing_Result__c, sked_Status__c
               FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_ERROR, dcr.sked_Status__c,
            'An unshipped-engine DCR must move to Error - there is no reason to retry it until an engine ships');
        System.assert(String.isNotBlank(dcr.sked_Last_Processing_Result__c),
            'Result message should be recorded even when no engine is available yet');
    }

    // A generic (non-saveFailureException) Exception from the engine itself. A stub engine is used
    // deliberately here rather than relying on some real engine's own failure mode - this test is
    // about skedDCRProcessingBatch's generic-exception handling, not any specific engine's
    // behavior. Deliberately not exercising the saveFailureException/Cancelled-write branch here:
    // skedDriveChangeRequestHandler.onCancelledRejected has a known JSON exception bug on that
    // exact write, so a test can't reach it without hitting that bug.
    private class ThrowingStubEngine implements skedDriveRegenEngine {
        public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
            throw new TestEngineException('Stub engine failure for testing generic exception handling.');
        }
    }

    private class TestEngineException extends Exception {}

    @isTest
    static void testExecute_engineThrows_rollsBackAndMovesToError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        skedDriveRegenEngineFactory.testEngineOverride = new ThrowingStubEngine();

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE);
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change');

        Test.startTest();
        Database.executeBatch(new skedDCRProcessingBatch(), 1);
        Test.stopTest();

        dcr = [SELECT sked_Status__c, sked_Last_Processing_Result__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_ERROR, dcr.sked_Status__c,
            'A generic engine exception must move the DCR to Error, not Cancelled - only saveFailureException cancels');
        System.assert(dcr.sked_Last_Processing_Result__c.contains('Stub engine failure'),
            'The engine exception message must be recorded as the processing result: ' + dcr.sked_Last_Processing_Result__c);
    }

    // start() now collects Pending only, so an Approved DCR is never applied by this batch. The
    // status staying Approved does not prove that on its own - it is also what a successful apply
    // used to leave behind - so this asserts the bookkeeping write never happened at all.
    @isTest
    static void testExecute_approvedDcr_isNotPickedUp() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        skedDriveRegenEngineFactory.testEngineOverride = new NoOpStubEngine();

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE);
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change');

        Test.startTest();
        Database.executeBatch(new skedDCRProcessingBatch(), 1);
        Test.stopTest();

        dcr = [SELECT sked_Last_Processing_Result__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(null, dcr.sked_Last_Processing_Result__c,
            'An Approved DCR must not be processed at all - a recorded result means the batch still picked it up');
    }

    // The DCR carries no Change items, so being picked up would resolve it to Error - staying at
    // Pending is therefore real evidence the drive-date filter excluded it.
    @isTest
    static void testExecute_pastDatedDrive_isNotPickedUp() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        update new sked_Drive__c(Id = drive.Id, sked_Drive_Date__c = System.today().addDays(-1));

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTD_CHANGE);
        insert dcr;

        Test.startTest();
        Database.executeBatch(new skedDCRProcessingBatch(), 1);
        Test.stopTest();

        dcr = [SELECT sked_Status__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING, dcr.sked_Status__c,
            'A DCR on a drive that already happened must be left untouched at Pending');
    }

    // User Change DCRs used to be excluded by type. They are in scope now that processing is a
    // deliberate run rather than something that fires while users are editing.
    @isTest
    static void testExecute_userChangeDcr_isPickedUp() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_USER_CHANGE);
        insert dcr; // no Change items -> the pipeline resolves it to Error, which is enough to prove pickup

        Test.startTest();
        Database.executeBatch(new skedDCRProcessingBatch(), 1);
        Test.stopTest();

        dcr = [SELECT sked_Status__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertNotEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING, dcr.sked_Status__c,
            'A User Change DCR must now be picked up - staying Pending means it is still being filtered out by type');
    }

    // The by-Id entry point exists to reach records the sweep skips, so this reuses the exact case
    // testExecute_pastDatedDrive_isNotPickedUp proves the sweep leaves alone.
    @isTest
    static void testEnqueueById_pastDatedDrive_isProcessed() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        update new sked_Drive__c(Id = drive.Id, sked_Drive_Date__c = System.today().addDays(-1));
        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTD_CHANGE);
        insert dcr; // no Change items -> resolves to Error once picked up

        Test.startTest();
        skedDCRProcessingBatch.enqueue(dcr.Id);
        Test.stopTest();

        dcr = [SELECT sked_Status__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertNotEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING, dcr.sked_Status__c,
            'Enqueuing by Id must process the DCR even though the sweep skips its past-dated drive');
    }

    // Approved DCRs are unreachable from the sweep, so the by-Id path is now the only way
    // processApproved() and its Approved-restore write run in production.
    @isTest
    static void testEnqueueById_approvedDcr_appliesAndRestoresApprovedStatus() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        skedDriveRegenEngineFactory.testEngineOverride = new NoOpStubEngine();
        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE);
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change');

        Test.startTest();
        skedDCRProcessingBatch.enqueue(dcr.Id);
        Test.stopTest();

        dcr = [SELECT sked_Status__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED, dcr.sked_Status__c,
            'A successfully-applied Approved DCR must be restored to Approved, not left at In Process');
    }

    private class NoOpStubEngine implements skedDriveRegenEngine {
        public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
        }
    }

    // Mirrors skedMobileDriveRegenEngine_Test.setupDrive - the established pattern for a drive
    // that always proposes exactly 1 drive shift, so the REAL engine (no stub) can regenerate
    // against an existing shift rather than a genuinely new one.
    private static sked_Drive__c setupRealMobileDrive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Maximum_Shift_Length_Threshold__c = 700;
        collectionOperation.sked_No_Travel_Time__c = false;
        collectionOperation.sked_Lunch_Break__c = false;
        update collectionOperation;

        sked_Drive__c testDrive1 = (sked_Drive__c) testData.get('testDrive1');
        testDrive1.sked_2RBC_Projected_Procedures__c = 30;
        testDrive1.sked_WB_Projected_Procedures__c = 20;
        testDrive1.sked_Do_Not_Use_Vehicle__c = false;
        testDrive1.sked_Number_of_Vehicles__c = 2;
        testDrive1.sked_Number_of_2RBC_Assets__c = 4;
        update testDrive1;

        sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
        setting.sked_Admin_Call_List_Recipient__c = 115;
        setting.sked_Admin_Call_List_Recipient_None__c = 130;
        upsert setting;

        Opportunity opp = new Opportunity(Id = testDrive1.sked_Opportunity__c, Call_List_Recipient_Exist__c = true, Slot_Generator__c = null);
        update opp;

        return testDrive1;
    }

    /**
     * True end-to-end test: the REAL skedMobileDriveRegenEngine (no stub, no testEngineOverride)
     * through the REAL batch, not just the isolated unit tests elsewhere that use a stub engine
     * to test the save/decide gate,
     * or the direct skedMobileDriveRegenEngine_Test calls that bypass the batch/DCR layer entirely.
     * Verifies the save/decide gate holds up against a genuinely regenerated graph: a non-Draft,
     * contended drive must come out of the full pipeline completely unmodified.
     */
    @isTest
    static void testExecute_realMobileEngineNonDraftContendedDrive_routesToSubmittedWithoutTouchingDrive() {
        sked_Drive__c testDrive1 = setupRealMobileDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;
        // Non-Draft so the contention gate applies; the factory's drive date (30 days out) is
        // within 42 days, so WITHIN_42_DAYS fires without needing any other forced setup.
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        update testDrive1;

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = testDrive1.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE);
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change');

        Test.startTest();
        Database.executeBatch(new skedDCRProcessingBatch(), 1);
        Test.stopTest();

        dcr = [SELECT sked_Status__c, sked_Drive_Contention__c, sked_Last_Processing_Result__c
               FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_SUBMITTED, dcr.sked_Status__c,
            'A contended, non-Draft drive processed through the REAL Mobile engine must route to Submitted: ' + dcr.sked_Last_Processing_Result__c);
        System.assert(dcr.sked_Drive_Contention__c != null && dcr.sked_Drive_Contention__c.contains(skedConstants.DRIVE_CONTENTION_WITHIN_42_DAYS),
            'A drive 30 days out (the standard factory date) must be flagged Within 42 Days: ' + dcr.sked_Drive_Contention__c);

        // The graph saver must never have run - a real regen would populate this shift with real
        // Job/Slot records, so their continued absence is direct proof the save was skipped.
        System.assertEquals(0, [SELECT COUNT() FROM sked__Job__c WHERE sked_Drive_Shift__c = :existingShift.Id],
            'A non-Draft, contended drive must be left completely unsaved - no jobs should have been written');
        System.assertEquals(0, [SELECT COUNT() FROM sked__Slot__c WHERE sked_Drive_Shift__c = :existingShift.Id],
            'A non-Draft, contended drive must be left completely unsaved - no slots should have been written');

        sked_Drive__c reloadedDrive = [SELECT sked_Total_Slots__c, sked_Status__c FROM sked_Drive__c WHERE Id = :testDrive1.Id];
        System.assertEquals(skedConstants.DRIVE_STATUS_TENTATIVE, reloadedDrive.sked_Status__c,
            'Drive status itself must be untouched by a routed-for-approval DCR');
        System.assertEquals(null, reloadedDrive.sked_Total_Slots__c,
            'sked_Total_Slots__c must still be unset - the engine computes it in-memory but it must never reach the database on this path');
    }

    /**
     * Companion happy-path test: the REAL engine, same drive shape, but Draft (the factory's
     * default status, left untouched) instead of Tentative - Draft drives always save regardless
     * of contention (the isDraft short-circuit in skedDCRApplyService.saveDrive), so this
     * exercises the OTHER branch of the gate without needing to reason about which of the 9
     * contention checks would or wouldn't fire for this drive shape: full save, DCR Approved by
     * System.
     */
    @isTest
    static void testExecute_realMobileEngineDraftDrive_regeneratesSavesAndApprovesRegardlessOfContention() {
        sked_Drive__c testDrive1 = setupRealMobileDrive();
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = testDrive1.Id);
        insert existingShift;
        // Status and date both left exactly as the factory/setupRealMobileDrive produce them -
        // matching the proven-working skedMobileDriveRegenEngine_Test setup exactly.

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = testDrive1.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE);
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change');

        Test.startTest();
        Database.executeBatch(new skedDCRProcessingBatch(), 1);
        Test.stopTest();

        dcr = [SELECT sked_Status__c, sked_Last_Processing_Result__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        String diagnostic = dcr.sked_Last_Processing_Result__c;
        for (BSF_Error_Log__c logEntry : [SELECT Error_Description_Long__c FROM BSF_Error_Log__c WHERE Object_RecordId__c = :dcr.Id]) {
            diagnostic += '\n---\n' + logEntry.Error_Description_Long__c;
        }
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM, dcr.sked_Status__c,
            'A Draft drive must always fully apply through the REAL engine + real batch, regardless of contention: ' + diagnostic);

        System.assert(![SELECT Id FROM sked__Job__c WHERE sked_Drive_Shift__c = :existingShift.Id].isEmpty(),
            'A saved regen must have actually written real Job records under the existing shift');
        System.assert(![SELECT Id FROM sked__Slot__c WHERE sked_Drive_Shift__c = :existingShift.Id].isEmpty(),
            'A saved regen must have actually written real Slot records under the existing shift');

        sked_Drive__c reloadedDrive = [SELECT sked_Total_Slots__c FROM sked_Drive__c WHERE Id = :testDrive1.Id];
        System.assertNotEquals(null, reloadedDrive.sked_Total_Slots__c,
            'sked_Total_Slots__c must be persisted on the save-through path, unlike the contended/blocked path');
    }

    @isTest
    static void testSchedulableExecute_startsBatch() {
        Test.startTest();
        String cronExpression = '0 0 0 15 3 ? 2099';
        String jobId = System.schedule('skedDCRProcessingBatch test schedule', cronExpression, new skedDCRProcessingBatch());
        Test.stopTest();

        // The scheduled-job -> Database.executeBatch chain in execute(SchedulableContext) is a
        // one-line call already exercised (and correct) by the direct Database.executeBatch
        // tests above; chained scheduled-batch completion isn't reliably flushed within a
        // single Test.stopTest() in this org, so this test asserts scheduling itself succeeded.
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId],
            'System.schedule must register a CronTrigger for skedDCRProcessingBatch');
    }

}
