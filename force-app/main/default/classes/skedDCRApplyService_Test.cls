@isTest
private class skedDCRApplyService_Test {
    private static final Decimal NEW_TOTAL_SLOTS = 77;

    @isTest
    static void testProcess_dcrWithoutChangeItems_stopsWithNoRegenerationMessage() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING
        );
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'sked_Drive__c',
            sked_Field_API_Name__c = 'sked_Total_Slots__c',
            sked_Field_Type__c = 'double',
            sked_Type__c = 'Impact'  // not a 'Change' item
        );

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assertEquals(false, result.applied, 'DCR without Change items must not be applied');
        System.assertEquals(skedDCRApplyService.MSG_NO_REGENERATION_REQUIRED, result.resultMessage,
            'Result message must match the LWC parity string');
    }

    @isTest
    static void testProcess_missingDcr_stopsWithNotFoundMessage() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING
        );
        insert dcr;
        Id dcrId = dcr.Id;
        delete dcr;

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcrId);
        Test.stopTest();

        System.assertEquals(skedDCRApplyService.MSG_DCR_NOT_FOUND, result.resultMessage,
            'Missing DCR must return the not-found parity message');
    }

    @isTest
    static void testProcess_noEngineForDriveType_stopsWithEngineUnavailableMessage() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        // A null sked_Type_of_Drive__c, not Mobile (testDrive1) or Fixed Site (testDrive2) - both of
        // those now resolve to real engines (Mobile always did; Fixed Site + Non Integrated WB,
        // testDrive2/testLocation2's own default, now does too - skedFixedSiteWbDriveRegenEngine).
        // skedConstants.DRIVE_TYPE_RSMO is not usable here: this org's sked_Type_of_Drive__c picklist
        // is restricted to 'Mobile'/'Fixed Site' only, so persisting 'RSMO' via real DML always throws
        // INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST - confirmed live, not assumed. A null type falls
        // through every one of skedDriveRegenEngineFactory.getEngine's branches identically to RSMO,
        // and the field itself is not required, so this is a legitimately persistable "no engine" case.
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        update new sked_Drive__c(Id = drive.Id, sked_Type_of_Drive__c = null);
        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING
        );
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change'
        );
        // No testEngineOverride set - a null drive type still resolves to null.

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assertEquals(false, result.applied, 'Must not be applied when no engine exists');
        System.assertEquals(skedDCRApplyService.MSG_ENGINE_UNAVAILABLE, result.resultMessage,
            'Result message must match the LWC parity string');
    }

    private static sked_Drive_Change_Request__c insertChangeDcr(Id driveId) {
        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = driveId,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING
        );
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change'
        );
        return dcr;
    }

    /**
     * sked_Drive__c.sked_Opportunity__c is a master field (immutable after insert), so each
     * validateOpportunity scenario needs its own fresh Opportunity + Drive pair rather than
     * mutating the shared fixture. Built fresh (not via update) so ISCHANGED-gated Opportunity
     * validation rules (account/date/site reassignment) don't block the scenario setup itself.
     */
    private static sked_Drive__c insertFreshDriveWithOpportunity(Map<String, sObject> testData,
            String stageName, Id accountId, Id driveSiteId, Date driveDate, String typeOfDrive) {
        sked_Territory__c territory1 = (sked_Territory__c) testData.get('testTerritory1');
        Biomed_Collection_Op_Center__c collectionOperation1 = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        sked__Location__c location1 = (sked__Location__c) testData.get('testLocation1');
        sked_Staging_Location__c stagingLocation1 = (sked_Staging_Location__c) testData.get('testStagingLocation1');
        Account account1 = (Account) testData.get('testAccount1');
        Date driveStartDate = driveDate != null ? driveDate : Date.today().addDays(30);

        Opportunity opp = new Opportunity(
            Name = 'Test Fresh Opportunity',
            AccountId = accountId,
            Drive_Date__c = driveDate,
            Drive_Site__c = driveSiteId,
            Type_of_Drive__c = typeOfDrive,
            StageName = stageName,
            CloseDate = driveStartDate,
            Online_Scheduling_Enabled__c = 'No',
            Accept_56_Day_Rule_Violation__c = true
        );
        insert opp;

        sked_Drive__c drive = new sked_Drive__c(
            Name = 'Test Fresh Drive',
            sked_District__c = territory1.Id,
            sked_Collection_Operation__c = collectionOperation1.Id,
            sked_Drive_Date__c = driveStartDate,
            sked_Day_of_Week__c = DateTime.newInstance(driveStartDate, Time.newInstance(0, 0, 0, 0)).format('EEEE'),
            sked_Drive_Site__c = location1.Id,
            sked_Opportunity__c = opp.Id,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = account1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 100,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Total_Products_Projected__c = 30,
            sked_2RBC_Projected_Procedures__c = 10,
            sked_WB_Projected_Procedures__c = 10,
            sked_Staging_Location__c = stagingLocation1.Id
        );
        insert drive;
        return drive;
    }

    @isTest
    static void testValidateOpportunity_missingDriveSite_returnsSiteError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        Account account1 = (Account) testData.get('testAccount1');
        // 'Discovery' stage avoids the Drive_Site_Required rule, which only fires for Solicitation.
        sked_Drive__c drive = insertFreshDriveWithOpportunity(testData, 'Discovery',
            account1.Id, null, Date.today().addDays(30), 'Mobile');

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assertEquals(false, result.applied, 'Validation failure must not apply the DCR');
        System.assert(result.resultMessage.contains(skedDCRApplyService.ERROR_MISSING_SITE),
            'Message must list the missing-site error: ' + result.resultMessage);
    }

    @isTest
    static void testValidateOpportunity_missingAccount_returnsAccountError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked__Location__c location1 = (sked__Location__c) testData.get('testLocation1');
        sked_Drive__c drive = insertFreshDriveWithOpportunity(testData, 'Solicitation',
            null, location1.Id, Date.today().addDays(30), 'Mobile');

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assert(result.resultMessage.contains(skedDCRApplyService.ERROR_MISSING_ACCOUNT),
            'Message must list the missing-account error: ' + result.resultMessage);
    }

    @isTest
    static void testValidateOpportunity_missingDriveDate_returnsDateError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        Account account1 = (Account) testData.get('testAccount1');
        sked__Location__c location1 = (sked__Location__c) testData.get('testLocation1');
        sked_Drive__c drive = insertFreshDriveWithOpportunity(testData, 'Solicitation',
            account1.Id, location1.Id, null, 'Mobile');

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assert(result.resultMessage.contains(skedDCRApplyService.ERROR_MISSING_DATE),
            'Message must list the missing-date error: ' + result.resultMessage);
    }

    @isTest
    static void testValidateOpportunity_missingDriveType_returnsTypeError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        Account account1 = (Account) testData.get('testAccount1');
        sked__Location__c location1 = (sked__Location__c) testData.get('testLocation1');
        sked_Drive__c drive = insertFreshDriveWithOpportunity(testData, 'Solicitation',
            account1.Id, location1.Id, Date.today().addDays(30), null);

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assert(result.resultMessage.contains(skedDCRApplyService.ERROR_MISSING_TYPE),
            'Message must list the missing-type error: ' + result.resultMessage);
    }

    @isTest
    static void testValidateOpportunity_siteHasNoCollectionOperationJunction_returnsNoCoError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        Account account1 = (Account) testData.get('testAccount1');
        sked__Location__c location2 = (sked__Location__c) testData.get('testLocation2'); // no site-CO junction in the fixture
        sked_Drive__c drive = insertFreshDriveWithOpportunity(testData, 'Solicitation',
            account1.Id, location2.Id, Date.today().addDays(30), 'Mobile');

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assert(result.resultMessage.contains(skedDCRApplyService.ERROR_NO_COLLECTION_OPERATION),
            'Message must list the no-collection-operation error: ' + result.resultMessage);
    }

    @isTest
    static void testValidateOpportunity_collectionOperationHasNoVehicle_returnsNoVehicleError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile';
        update opp;
        delete [SELECT Id FROM sked__Resource__c WHERE sked_Asset_Type__c = :skedConstants.ASSET_TYPE_VEHICLE];

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assert(result.resultMessage.contains(skedDCRApplyService.ERROR_NO_VEHICLE),
            'Message must list the no-vehicle error: ' + result.resultMessage);
    }

    /**
     * A vehicle is a Mobile-only resource - both Fixed Site engines list ghost vehicle among the
     * Mobile concepts they never port. The shared fixture's Collection Operation happens to own
     * vehicles, which is why this gate never surfaced here before; stripping them proves the check is
     * skipped by drive type rather than satisfied by luck.
     */
    @isTest
    static void testValidateOpportunity_fixedSiteWithoutVehicles_skipsVehicleCheck() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2'); // Fixed Site
        sked__Location__c site2 = (sked__Location__c) testData.get('testLocation2');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = skedConstants.DRIVE_TYPE_FIXED_SITE;
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId();
        update opp;

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        insert new sked_Site_Collection_Operation__c(
            sked_Site__c = site2.Id, sked_Collection_Operation__c = collectionOperation.Id, sked_Region__c = region.Id,
            sked_Start_Date__c = drive.sked_Drive_Date__c.addDays(-1), sked_End_Date__c = drive.sked_Drive_Date__c.addDays(2)
        );
        delete [SELECT Id FROM sked__Resource__c WHERE sked_Asset_Type__c = :skedConstants.ASSET_TYPE_VEHICLE];

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        Boolean blockedOnVehicle = result.resultMessage != null
            && result.resultMessage.contains(skedDCRApplyService.ERROR_NO_VEHICLE);
        System.assertEquals(false, blockedOnVehicle,
            'A Fixed Site drive must not be blocked for a missing vehicle: ' + result.resultMessage);
    }

    @isTest
    static void testValidateOpportunity_allDataPresent_passesValidation() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile'; // site/account/date already set by the factory fixture
        update opp;

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();
    }

    @isTest
    static void testValidateDraftDrive_militaryAccountMissingAuthorityInfo_returnsMilitaryError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked__Location__c location1 = (sked__Location__c) testData.get('testLocation1');

        Account militaryAccount = new Account(
            Name = 'Test Military Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test Military Internal Name',
            APT_Required__c = false,
            Type = 'Military'
            // Military_Authority_Name__c / Military_Authority_Phone__c left blank on purpose
        );
        insert militaryAccount;

        sked_Drive__c drive = insertFreshDriveWithOpportunity(testData, 'Solicitation',
            militaryAccount.Id, location1.Id, Date.today().addDays(30), 'Mobile');
        // Draft status is already set by insertFreshDriveWithOpportunity; sked_Account__c
        // must point to the military account too so sked_Account_Type__c resolves to 'Military'.
        drive.sked_Account__c = militaryAccount.Id;
        update drive;

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assertEquals(false, result.applied, 'Military account violation must not apply the DCR');
        System.assert(result.resultMessage.containsIgnoreCase('military'),
            'Result message must surface the military-account validation error: ' + result.resultMessage);
    }

    @isTest
    static void testValidateDraftDrive_nonDraftDrive_skipsMilitaryCheck() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked__Location__c location1 = (sked__Location__c) testData.get('testLocation1');

        Account militaryAccount = new Account(
            Name = 'Test Military Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test Military Internal Name',
            APT_Required__c = false,
            Type = 'Military'
        );
        insert militaryAccount;

        sked_Drive__c drive = insertFreshDriveWithOpportunity(testData, 'Solicitation',
            militaryAccount.Id, location1.Id, Date.today().addDays(30), 'Mobile');
        drive.sked_Account__c = militaryAccount.Id;
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        update drive;

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();
    }

    /**
     * promoteIfContentionCleared is the piece of promoteDraftToTentativeIfContentionCleared that
     * doesn't depend on a real pending-approval ProcessInstance (which this test suite has no
     * established way to simulate) - it proves the promotion itself fires once contentions clear,
     * independent of how isPendingApproval was determined.
     */
    @isTest
    static void testPromoteIfContentionCleared_noContention_promotesDraftToTentative() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1'); // Draft by default
        drive.sked_Drive_Date__c = Date.today().addDays(60); // outside 42 days, avoids that contention
        drive.sked_Do_Not_Use_Vehicle__c = true; // avoids lacking-vehicle contention with no vehicle data
        update drive;

        skedDCRApplyService service = new skedDCRApplyService();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);

        Test.startTest();
        service.promoteIfContentionCleared(ctx);
        Test.stopTest();

        System.assertEquals(skedConstants.DRIVE_STATUS_TENTATIVE, ctx.drive.sked_Status__c,
            'A Draft drive with no contention must be promoted to Tentative');
    }

    @isTest
    static void testPromoteIfContentionCleared_hasContention_leavesDriveAsDraft() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        List<sked_Drive_Shift__c> shifts = new List<sked_Drive_Shift__c>{
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id),
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id)
        };
        insert shifts; // 2 shifts -> Multi Shift Drive contention, never overridden here

        skedDCRApplyService service = new skedDCRApplyService();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);

        Test.startTest();
        service.promoteIfContentionCleared(ctx);
        Test.stopTest();

        System.assertEquals(skedConstants.DRIVE_STATUS_DRAFT, ctx.drive.sked_Status__c,
            'A Draft drive with an unresolved contention must NOT be promoted to Tentative');
    }

    /**
     * ctx.drive.sked_Status__c must be the source of truth validateDraftDrive reads - not a
     * snapshot queried once earlier - so a drive already promoted to Tentative in-memory (by
     * promoteDraftToTentativeIfContentionCleared, which runs immediately before this step) skips
     * the Draft-only military-account check even though the drive is still Draft in the database.
     */
    @isTest
    static void testValidateDraftDrive_ctxAlreadyPromotedToTentative_skipsMilitaryCheckDespiteMissingAuthorityInfo() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked__Location__c location1 = (sked__Location__c) testData.get('testLocation1');

        Account militaryAccount = new Account(
            Name = 'Test Military Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test Military Internal Name',
            APT_Required__c = false,
            Type = 'Military'
            // Military_Authority_Name__c / Military_Authority_Phone__c left blank on purpose
        );
        insert militaryAccount;

        sked_Drive__c drive = insertFreshDriveWithOpportunity(testData, 'Solicitation',
            militaryAccount.Id, location1.Id, Date.today().addDays(30), 'Mobile');
        drive.sked_Account__c = militaryAccount.Id;
        update drive; // still Draft in the database - only ctx is promoted, simulating the real timing

        skedDCRApplyService service = new skedDCRApplyService();
        service.driveId = drive.Id;
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        ctx.drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE;
        skedDCRApplyService.applyResult result = new skedDCRApplyService.applyResult();

        Test.startTest();
        Boolean passed = service.validateDraftDrive(result, ctx);
        Test.stopTest();

        System.assertEquals(true, passed,
            'Once ctx.drive.sked_Status__c reads Tentative, the Draft-only military-account check must be skipped entirely');
    }

    @isTest
    static void testProcess_endToEnd_engineChangeAppliesAndDcrApprovedBySystem() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1'); // Draft, Mobile -> autoApprove
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile';
        update opp;

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new TotalSlotsMutatingStubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assertEquals(true, result.applied, 'A fully valid, auto-approvable DCR must be applied');
        System.assertEquals('Your changes have been approved and updates have been made by system.',
            result.resultMessage, 'Result message must match the LWC parity string');

        sked_Drive__c reloadedDrive = [SELECT sked_Total_Slots__c FROM sked_Drive__c WHERE Id = :drive.Id];
        System.assertEquals(NEW_TOTAL_SLOTS, reloadedDrive.sked_Total_Slots__c,
            'The engine-mutated field must be persisted to the database');

        sked_Drive_Change_Request__c reloadedDcr = [SELECT sked_Status__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM, reloadedDcr.sked_Status__c,
            'A fully applied DCR must be marked Approved by System');

        List<sked_Drive_Change_Request_Item__c> impactItems = [
            SELECT Id FROM sked_Drive_Change_Request_Item__c
            WHERE sked_Drive_Change_Request__c = :dcr.Id
            AND sked_Type__c = 'Impact' AND sked_Field_API_Name__c = 'sked_Total_Slots__c'
        ];
        System.assertEquals(1, impactItems.size(), 'An impact item must be captured for the changed tracked field');
    }

    @isTest
    static void testProcess_endToEnd_fixedSiteWalkingSkeleton_reachesSaveInsteadOfEngineUnavailable() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        // testDrive2/testLocation2 default to WB, but this drive stays Draft throughout, so saveDrive's WB-sensitive branch never applies here - see skedMobileAssetReassigner_Test.cls's gate tests for that case.
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2'); // Fixed Site
        sked__Location__c site2 = (sked__Location__c) testData.get('testLocation2');
        sked__Region__c region = (sked__Region__c) testData.get('testRegion1');

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Fixed Site';
        // 'Fixed Site' is only a valid value under the Fixed_Site_Opp record type's restricted picklist - the default record type from setupDriveData() only allows 'Mobile'/'RSMO'.
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId();
        update opp;

        // testLocation2 has no Site-CO junction in the shared fixture (only testLocation1 does), but validateOpportunity's ERROR_NO_COLLECTION_OPERATION check needs one to pass.
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        insert new sked_Site_Collection_Operation__c(
            sked_Site__c = site2.Id, sked_Collection_Operation__c = collectionOperation.Id, sked_Region__c = region.Id,
            sked_Start_Date__c = drive.sked_Drive_Date__c.addDays(-1), sked_End_Date__c = drive.sked_Drive_Date__c.addDays(2)
        );

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        // Test-override only - getEngine() still returns null for Fixed Site in production, so this "Approved by System with a no-op engine" outcome is unreachable outside tests.
        skedDriveRegenEngineFactory.testEngineOverride = new skedFixedSiteDriveRegenEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assertNotEquals(skedDCRApplyService.MSG_ENGINE_UNAVAILABLE, result.resultMessage,
            'With the walking-skeleton engine present, checkDcr must no longer stop the pipeline: ' + result.resultMessage);
        System.assertEquals(true, result.applied, 'A fully valid Fixed Site DCR must reach and complete SAVE_DRIVE: ' + result.resultMessage);

        sked_Drive_Change_Request__c reloadedDcr = [SELECT sked_Status__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM, reloadedDcr.sked_Status__c,
            'A fully applied DCR must be marked Approved by System, same as the equivalent Mobile pipeline');
    }

    @isTest
    static void testProcess_collectionOperationChangeDcr_updatesDriveToNewCollectionOperation() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c newCollectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation2');
        sked__Location__c location1 = (sked__Location__c) testData.get('testLocation1');
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile';
        update opp;

        sked_Site_Collection_Operation__c newSiteCollectionOperation = new sked_Site_Collection_Operation__c(
            sked_Site__c = location1.Id, sked_Collection_Operation__c = newCollectionOperation.Id,
            sked_Start_Date__c = Date.today(), sked_End_Date__c = Date.today().addYears(1)
        );
        insert newSiteCollectionOperation;

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            sked_Type__c = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_COLLECTION_OP,
            sked_New_Collection_Operation__c = newCollectionOperation.Id
        );
        insert dcr;
        insert new List<sked_Drive_Change_Request_Item__c>{
            new sked_Drive_Change_Request_Item__c(
                sked_Drive_Change_Request__c = dcr.Id, sked_Object_API_Name__c = 'sked_Drive__c',
                sked_Field_API_Name__c = 'sked_Collection_Operation__c', sked_Field_Type__c = 'reference',
                sked_Old_Value__c = drive.sked_Collection_Operation__c, sked_New_Value__c = newCollectionOperation.Id,
                sked_Type__c = 'Change'
            ),
            new sked_Drive_Change_Request_Item__c(
                sked_Drive_Change_Request__c = dcr.Id, sked_Object_API_Name__c = 'sked_Drive__c',
                sked_Field_API_Name__c = 'sked_Site_Collection_Operation__c', sked_Field_Type__c = 'reference',
                sked_Old_Value__c = drive.sked_Site_Collection_Operation__c, sked_New_Value__c = newSiteCollectionOperation.Id,
                sked_Type__c = 'Change'
            )
        };
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assertEquals(true, result.applied, 'A Collection Operation Change DCR must be applied: ' + result.resultMessage);
        sked_Drive__c reloadedDrive = [SELECT sked_Collection_Operation__c, sked_Site_Collection_Operation__c FROM sked_Drive__c WHERE Id = :drive.Id];
        System.assertEquals(newCollectionOperation.Id, reloadedDrive.sked_Collection_Operation__c,
            'The drive\'s Collection Operation must be updated to the DCR\'s new value, not silently left as the old one');
        System.assertEquals(newSiteCollectionOperation.Id, reloadedDrive.sked_Site_Collection_Operation__c,
            'The drive\'s Site Collection Operation must also be updated from the paired Change item\'s new value');
    }

    // ctx.operationDriveLimits (and the other 4 CO-scoped reference-data lists) are loaded against
    // the OLD Collection Operation by skedDriveRegenContextLoader.load(), which runs before
    // applyCollectionOperationChange - without a reload, every contention check reading these lists
    // straight off ctx would evaluate the wrong Collection Operation's data after a CO-change DCR.
    @isTest
    static void testApplyCollectionOperationChange_reloadsReferenceDataForNewCollectionOperation() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c newCollectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation2');

        insert new sked_Operation_Drive_Limit__c(
            sked_Collection_Operation__c = newCollectionOperation.Id, sked_Quantity__c = 5,
            sked_Type__c = skedConstants.OPERATION_DRIVE_LIMIT_TYPE_DRIVE_LIMIT
        );

        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        System.assert(ctx.operationDriveLimits.isEmpty(), 'Setup check: the original Collection Operation must have no drive limit configured');

        skedDCRApplyService service = new skedDCRApplyService();
        service.dcr = new sked_Drive_Change_Request__c(sked_New_Collection_Operation__c = newCollectionOperation.Id);
        service.changeItems = new List<sked_Drive_Change_Request_Item__c>();

        Test.startTest();
        service.applyCollectionOperationChange(ctx);
        Test.stopTest();

        System.assertEquals(newCollectionOperation.Id, ctx.drive.sked_Collection_Operation__c, 'Setup check: the CO mutation itself must still apply');
        System.assertEquals(1, ctx.operationDriveLimits.size(),
            'ctx.operationDriveLimits must be reloaded against the NEW Collection Operation, not left stale from the OLD one at load() time');
    }

    /**
     * A Draft drive that isn't pending approval never recomputes contention, so
     * pendingActionReasonCode must be left exactly as loaded.
     */
    @isTest
    static void testSaveDrive_draftNotPendingApproval_preservesExistingPendingActionReasonCode() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1'); // Draft, Mobile -> not pending approval
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile';
        update opp;

        // Deliberately a value the fresh regen wouldn't compute for this 0-shift drive, so the
        // assertion actually proves "untouched" rather than coincidentally matching.
        drive.sked_Pending_Action_Reason_Code__c = skedConstants.DRIVE_CONTENTION_MULTI_SHIFT_DRIVE;
        update drive;

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new TotalSlotsMutatingStubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assertEquals(true, result.applied, 'A Draft, not-pending-approval DCR must still auto-apply');

        sked_Drive__c reloadedDrive = [SELECT sked_Pending_Action_Reason_Code__c FROM sked_Drive__c WHERE Id = :drive.Id];
        System.assertEquals(skedConstants.DRIVE_CONTENTION_MULTI_SHIFT_DRIVE, reloadedDrive.sked_Pending_Action_Reason_Code__c,
            'A Draft drive not pending approval must keep its stored pendingActionReasonCode untouched - the LWC never recomputes it for this case');
    }

    @isTest
    static void testProcess_nonDraftDriveWithContention_routesToSubmittedWithoutSavingDrive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile';
        update opp;
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // non-Draft, non-Fixed-Site
        update drive;
        Decimal originalTotalSlots = drive.sked_Total_Slots__c;

        // 2 shifts on a drive is Multi Shift Drive - this scenario never sets its elect-resolution,
        // so it's guaranteed to still be violated. Start/End Time must fit inside
        // skedTestDataFactory's shared Collection_Operation_Time_Block__c fixture (1AM-11PM) -
        // otherwise the time-block gate fires MISSING_TIME_BLOCK first and this test would never
        // reach MULTI_SHIFT_DRIVE at all.
        insert new List<sked_Drive_Shift__c>{
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Start_Time__c = Time.newInstance(7, 0, 0, 0), sked_End_Time__c = Time.newInstance(17, 0, 0, 0)),
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Start_Time__c = Time.newInstance(7, 0, 0, 0), sked_End_Time__c = Time.newInstance(17, 0, 0, 0))
        };

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new TotalSlotsMutatingStubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assertEquals(true, result.applied, 'Routing a contended DCR for approval still counts as applied');
        System.assertEquals('Drive has been submitted for approval.', result.resultMessage,
            'Result message must match the LWC parity string for the contended, non-Draft, non-Fixed-Site path');

        sked_Drive__c reloadedDrive = [SELECT sked_Total_Slots__c, sked_Status__c FROM sked_Drive__c WHERE Id = :drive.Id];
        System.assertEquals(originalTotalSlots, reloadedDrive.sked_Total_Slots__c,
            'A non-Draft, contended drive must be left completely unmodified - the engine mutation must never persist');
        System.assertEquals(skedConstants.DRIVE_STATUS_TENTATIVE, reloadedDrive.sked_Status__c,
            'Drive status itself must be untouched when the DCR is routed for approval');

        sked_Drive_Change_Request__c reloadedDcr = [
            SELECT sked_Status__c, sked_Drive_Contention__c, sked_Route_Approval_Request_To__c
            FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id
        ];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_SUBMITTED, reloadedDcr.sked_Status__c,
            'A contended non-Draft DCR must be routed to Submitted for human approval');
        System.assert(reloadedDcr.sked_Drive_Contention__c.contains(skedConstants.DRIVE_CONTENTION_MULTI_SHIFT_DRIVE),
            'The DCR must record which contention triggered the routing: ' + reloadedDcr.sked_Drive_Contention__c);
        System.assertEquals('Request APS exception', reloadedDcr.sked_Route_Approval_Request_To__c,
            'HRP-955: without WITHIN_42_DAYS or INSUFFICIENT_RESOURCES among the contentions, routing must '
                + 'be recomputed to APS exception rather than reused from a stale/default drive field');
    }

    @isTest
    static void testSaveDrive_nonDraftFixedSiteNonIntegratedWbWithContention_routesToSubmittedNotAutoApproved() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2'); // Fixed Site
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_TENTATIVE; // non-Draft
        update drive;

        // sked_Drive__c.sked_Operation_Type__c is a formula (TEXT(sked_Drive_Site__r.Operation_Type__c)) -
        // set it on the drive's site, not the drive itself.
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        site.Operation_Type__c = skedConstants.OPERATION_TYPE_WB; // Non Integrated WB
        update site;

        // 2 shifts on a drive is Multi Shift Drive - this scenario never sets its elect-resolution,
        // so it's guaranteed to still be violated. Start/End Time must fit inside
        // skedTestDataFactory's shared Collection_Operation_Time_Block__c fixture (1AM-11PM) -
        // otherwise the time-block gate fires MISSING_TIME_BLOCK first and this test would never
        // reach MULTI_SHIFT_DRIVE at all.
        insert new List<sked_Drive_Shift__c>{
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Start_Time__c = Time.newInstance(7, 0, 0, 0), sked_End_Time__c = Time.newInstance(17, 0, 0, 0)),
            new sked_Drive_Shift__c(sked_Drive__c = drive.Id, sked_Start_Time__c = Time.newInstance(7, 0, 0, 0), sked_End_Time__c = Time.newInstance(17, 0, 0, 0))
        };

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);

        skedDCRApplyService service = new skedDCRApplyService();
        service.dcr = dcr;
        service.isDrivePendingApproval = false;
        skedDCRApplyService.applyResult result = new skedDCRApplyService.applyResult();

        Test.startTest();
        service.saveDrive(result, ctx);
        Test.stopTest();

        System.assertEquals('Drive has been submitted for approval.', result.resultMessage,
            'A Non Integrated WB Fixed Site drive must NOT be treated as Fixed Site by the auto-approve gate, '
                + 'so a contended, non-Draft drive here must still route to a human');

        sked_Drive_Change_Request__c reloadedDcr = [SELECT sked_Status__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_SUBMITTED, reloadedDcr.sked_Status__c,
            'Must route to Submitted for human approval, not silently auto-approve as a real Fixed Site drive would');
    }

    @isTest
    static void testValidateOpportunity_collectionOperationHasOnlyInactiveVehicle_returnsNoVehicleError() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile';
        update opp;
        // Deactivate (not delete) every real vehicle for the CO - proves the sked__Is_Active__c
        // filter itself, not just "zero rows returned".
        List<sked__Resource__c> vehicles = [
            SELECT Id, sked__Is_Active__c FROM sked__Resource__c WHERE sked_Asset_Type__c = :skedConstants.ASSET_TYPE_VEHICLE
        ];
        for (sked__Resource__c vehicle : vehicles) {
            vehicle.sked__Is_Active__c = false;
        }
        update vehicles;

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().process(dcr.Id);
        Test.stopTest();

        System.assert(result.resultMessage.contains(skedDCRApplyService.ERROR_NO_VEHICLE),
            'An inactive-only vehicle pool must still report the no-vehicle error: ' + result.resultMessage);
    }

    @isTest
    static void testProcess_endToEnd_saveFailure_cancelsDcr() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile';
        update opp;

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenEngineFactory.testEngineOverride = new InvalidStatusStubEngine();

        Test.startTest();
        try {
            new skedDCRApplyService().process(dcr.Id);
            System.assert(false, 'saveDrive must throw saveFailureException when persistence fails');
        } catch (skedDCRApplyService.saveFailureException ex) {
            // expected - the batch (not this service) performs the post-rollback DCR cancellation
        }
        Test.stopTest();
    }

    @isTest
    static void testProcessApproved_validDcr_appliesWithoutTouchingDcrStatus() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile';
        update opp;

        // Inserted directly as Approved (not insert-then-update) - transitioning an existing DCR
        // to Approved via update fires skedDriveChangeRequestHandler.createRequestToSyncOppsWithDrives,
        // a pre-existing legacy method with its own unrelated NullPointerException on Change items
        // missing sked_Old_Value__c.
        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED
        );
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change'
        );
        skedDriveRegenEngineFactory.testEngineOverride = new TotalSlotsMutatingStubEngine();

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().processApproved(dcr.Id);
        Test.stopTest();

        System.assertEquals(true, result.applied, 'An already-approved DCR with a working engine must apply successfully');
        System.assertEquals('Drive was updated successfully.', result.resultMessage,
            'Result message must match the LWC parity string for MODE.APPROVE_DCR');

        sked_Drive__c reloadedDrive = [SELECT sked_Total_Slots__c FROM sked_Drive__c WHERE Id = :drive.Id];
        System.assertEquals(NEW_TOTAL_SLOTS, reloadedDrive.sked_Total_Slots__c,
            'The engine-mutated field must be persisted even without the contention/status-decision steps');

        sked_Drive_Change_Request__c reloadedDcr = [SELECT sked_Status__c FROM sked_Drive_Change_Request__c WHERE Id = :dcr.Id];
        System.assertEquals(skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED, reloadedDcr.sked_Status__c,
            'processApproved must never write DCR status itself - parity with MODE.APPROVE_DCR\'s SAVE_DRIVE, which does not either');
    }

    @isTest
    static void testSaveDrive_draftDriveWithExistingVehicleAllocation_releasesAllocationsBeforeSave() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1'); // Draft by default
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c vehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert vehicleJob;
        sked__Resource__c vehicle = new sked__Resource__c(
            Name = 'Existing Van', sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE, sked__Is_Active__c = true
        );
        insert vehicle;
        DateTime windowStart = DateTime.now();
        sked__Job_Allocation__c existingAllocation = new sked__Job_Allocation__c(
            sked__Job__c = vehicleJob.Id, sked__Resource__c = vehicle.Id,
            sked__Start__c = windowStart, sked__Set_End__c = windowStart.addHours(8)
        );
        insert existingAllocation;

        sked_Drive_Change_Request__c dcr = insertChangeDcr(drive.Id);
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        // Simulate the regen engine also proposing a brand-new, not-yet-persisted allocation
        // alongside the real one already on the job.
        ctx.allocationsByJobId.get(vehicleJob.Id).add(
            new sked__Job_Allocation__c(sked__Job__c = vehicleJob.Id, sked__Resource__c = vehicle.Id));

        skedDCRApplyService service = new skedDCRApplyService();
        service.dcr = dcr;
        service.isDrivePendingApproval = false;
        skedDCRApplyService.applyResult result = new skedDCRApplyService.applyResult();

        Test.startTest();
        service.saveDrive(result, ctx);
        Test.stopTest();

        System.assertEquals(true, result.applied, 'A Draft drive must always save: ' + result.resultMessage);

        sked__Job_Allocation__c reloadedExisting = [
            SELECT sked__Status__c FROM sked__Job_Allocation__c WHERE Id = :existingAllocation.Id
        ];
        System.assertEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, reloadedExisting.sked__Status__c,
            'The pre-existing vehicle allocation must be released (marked Deleted), not carried forward as-is');

        List<sked__Job_Allocation__c> allAllocationsForJob = [
            SELECT Id FROM sked__Job_Allocation__c WHERE sked__Job__c = :vehicleJob.Id
        ];
        System.assertEquals(1, allAllocationsForJob.size(),
            'The unsaved (Id == null) allocation the engine proposed must never be persisted - only the '
                + 'pre-existing row (now Deleted) may exist');
    }

    @isTest
    static void testProcessApproved_draftDriveWithExistingEquipmentAllocation_releasesAllocationsBeforeSave() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1'); // Draft by default
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :drive.sked_Opportunity__c];
        opp.Type_of_Drive__c = 'Mobile';
        update opp;
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c equipmentJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert equipmentJob;
        sked__Resource__c equipment = new sked__Resource__c(
            Name = 'Existing Cot', sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT, sked__Is_Active__c = true
        );
        insert equipment;
        DateTime windowStart = DateTime.now();
        sked__Job_Allocation__c existingAllocation = new sked__Job_Allocation__c(
            sked__Job__c = equipmentJob.Id, sked__Resource__c = equipment.Id,
            sked__Start__c = windowStart, sked__Set_End__c = windowStart.addHours(8)
        );
        insert existingAllocation;

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(
            sked_Drive__c = drive.Id,
            sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED
        );
        insert dcr;
        insert new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = dcr.Id,
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Date__c',
            sked_Field_Type__c = 'date',
            sked_Type__c = 'Change'
        );
        skedDriveRegenEngineFactory.testEngineOverride = new AddUnsavedAllocationStubEngine(equipmentJob.Id, equipment.Id);

        Test.startTest();
        skedDCRApplyService.applyResult result = new skedDCRApplyService().processApproved(dcr.Id);
        Test.stopTest();

        System.assertEquals(true, result.applied, 'processApproved must succeed: ' + result.resultMessage);

        sked__Job_Allocation__c reloadedExisting = [
            SELECT sked__Status__c FROM sked__Job_Allocation__c WHERE Id = :existingAllocation.Id
        ];
        System.assertEquals(skedConstants.JOB_ALLOCATION_STATUS_DELETED, reloadedExisting.sked__Status__c,
            'processApproved must also release a Draft drive\'s existing equipment allocation before saving');

        List<sked__Job_Allocation__c> allAllocationsForJob = [
            SELECT Id FROM sked__Job_Allocation__c WHERE sked__Job__c = :equipmentJob.Id
        ];
        System.assertEquals(1, allAllocationsForJob.size(),
            'The engine-proposed unsaved allocation must never be persisted via processApproved either');
    }

    private class StubEngine implements skedDriveRegenEngine {
        public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
        }
    }

    // Simulates a regen engine proposing a brand-new, not-yet-persisted allocation on an existing
    // job - used to prove releaseAllAssetAllocations() drops it rather than saving it.
    private class AddUnsavedAllocationStubEngine implements skedDriveRegenEngine {
        private final Id targetJobId;
        private final Id resourceId;
        AddUnsavedAllocationStubEngine(Id targetJobId, Id resourceId) {
            this.targetJobId = targetJobId;
            this.resourceId = resourceId;
        }
        public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
            if (!ctx.allocationsByJobId.containsKey(targetJobId)) {
                ctx.allocationsByJobId.put(targetJobId, new List<sked__Job_Allocation__c>());
            }
            ctx.allocationsByJobId.get(targetJobId).add(
                new sked__Job_Allocation__c(sked__Job__c = targetJobId, sked__Resource__c = resourceId));
        }
    }

    private class TotalSlotsMutatingStubEngine implements skedDriveRegenEngine {
        public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
            ctx.drive.sked_Total_Slots__c = NEW_TOTAL_SLOTS;
        }
    }

    // Forces a DML failure inside skedDriveGraphSaver.save() by setting a restricted
    // picklist to an invalid value - deterministic, org-independent way to exercise the
    // saveFailureException / post-rollback-cancel path without depending on unknown
    // validation rules. Must NOT touch sked_Status__c: saveDrive's pre-save contention gate
    // reads status to decide Draft-vs-not, and the fixture drive needs to stay Draft here so
    // the "always save" path is actually reached (otherwise a contended non-Draft drive would
    // route to Submitted without ever calling the graph saver, and this test would stop
    // exercising the failure path it's named for).
    private class InvalidStatusStubEngine implements skedDriveRegenEngine {
        public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
            ctx.drive.sked_Type_of_Drive__c = 'Not A Real Type Value';
        }
    }
}
