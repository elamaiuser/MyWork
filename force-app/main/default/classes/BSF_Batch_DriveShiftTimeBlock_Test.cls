@IsTest
public class BSF_Batch_DriveShiftTimeBlock_Test {

    @testSetup
    static void setupData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');

        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, SObject> testData = testDataSetup.createAndInsertCommonObjects();

        Account testAccount = (Account) testData.get('MOBILE_ACCOUNT');
        insert testAccount;

        Biomed_Collection_Op_Center__c co = (Biomed_Collection_Op_Center__c) testData.get('COLLECTION_OPP');
        co.External_Id__c = 'TEST-CO-1';
        insert co;

        Biomed_Collection_Op_Center__c co2 = co.clone(false, true, false, false);
        co2.Name = 'Collection Operation 2';
        co2.External_Id__c = 'TEST-CO-2';
        insert co2;

        sked__Location__c mobileSite = (sked__Location__c) testData.get('MOBILE_SITE');
        mobileSite.sked_Collection_Operation__c = co.Id;
        insert mobileSite;

        sked__Location__c fixedSiteWB = (sked__Location__c) testData.get('FIXED_SITE');
        fixedSiteWB.Operation_Type__c = skedConstants.OPERATION_TYPE_WB;
        fixedSiteWB.sked_Collection_Operation__c = co.Id;
        insert fixedSiteWB;

        Opportunity templateOpp = (Opportunity) testData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testAccount.Id;
        templateOpp.Drive_Site__c = mobileSite.Id;
        insert templateOpp;

        Opportunity mobileOpp = (Opportunity) testData.get('MOBILE_OPP');
        mobileOpp.AccountId = testAccount.Id;
        mobileOpp.Parent_Template_Id__c = templateOpp.Id;
        mobileOpp.Is_Template__c = false;
        insert mobileOpp;

        Opportunity cancelledOpp = mobileOpp.clone(false, true, false, false);
        cancelledOpp.Name = 'Test Opportunity - Cancelled';
        Opportunity fixedSiteWBOpp = mobileOpp.clone(false, true, false, false);
        fixedSiteWBOpp.Name = 'Test Opportunity - Fixed Site WB';
        Opportunity co2Opp = mobileOpp.clone(false, true, false, false);
        co2Opp.Name = 'Test Opportunity - CO2';
        insert new List<Opportunity>{ cancelledOpp, fixedSiteWBOpp, co2Opp };

        Date driveDate = sharedDriveDate();
        String dayName = sharedDayOfWeek();

        insert new sked_Drive__c(
            Name = 'Active Mobile Drive',
            sked_Account__c = testAccount.Id,
            sked_Drive_Site__c = mobileSite.Id,
            sked_Opportunity__c = mobileOpp.Id,
            sked_Collection_Operation__c = co.Id,
            sked_Drive_Date__c = driveDate,
            sked_Day_of_Week__c = dayName,
            sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_MOBILE,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Projected_Registered_Donors__c = 30,
            sked_2RBC_Projected_Procedures__c = 2
        );

        insert new sked_Drive__c(
            Name = 'Cancelled Mobile Drive',
            sked_Account__c = testAccount.Id,
            sked_Drive_Site__c = mobileSite.Id,
            sked_Opportunity__c = cancelledOpp.Id,
            sked_Collection_Operation__c = co.Id,
            sked_Drive_Date__c = driveDate,
            sked_Day_of_Week__c = dayName,
            sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_MOBILE,
            sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL,
            sked_Projected_Registered_Donors__c = 30,
            sked_2RBC_Projected_Procedures__c = 2
        );

        insert new sked_Drive__c(
            Name = 'Fixed Site WB Drive',
            sked_Account__c = testAccount.Id,
            sked_Drive_Site__c = fixedSiteWB.Id,
            sked_Opportunity__c = fixedSiteWBOpp.Id,
            sked_Collection_Operation__c = co.Id,
            sked_Drive_Date__c = driveDate,
            sked_Day_of_Week__c = dayName,
            sked_Type_of_Drive__c = 'Fixed Site',
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Projected_Registered_Donors__c = 30,
            sked_2RBC_Projected_Procedures__c = 2
        );

        insert new sked_Drive__c(
            Name = 'Mobile Drive CO2',
            sked_Account__c = testAccount.Id,
            sked_Drive_Site__c = mobileSite.Id,
            sked_Opportunity__c = co2Opp.Id,
            sked_Collection_Operation__c = co2.Id,
            sked_Drive_Date__c = driveDate,
            sked_Day_of_Week__c = dayName,
            sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_MOBILE,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_Projected_Registered_Donors__c = 30,
            sked_2RBC_Projected_Procedures__c = 2
        );

        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('DriveTriggerHandler');
        TriggerHandler.clearBypass('SiteTriggerHandler');
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
    }

    @isTest
    static void testSingleFitTimeBlock_AssignsTimeBlockAndClearsContention() {
        sked_Drive__c drive = [SELECT Id, sked_Collection_Operation__c FROM sked_Drive__c WHERE Name = 'Active Mobile Drive' LIMIT 1];
        Date driveDate = sharedDriveDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Full Day',
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = drive.sked_Collection_Operation__c,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = driveDate.addDays(-1),
            Effective_End_Date__c = driveDate.addDays(1)
        );

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0)
        );
        insert shift;

        Test.startTest();
        Database.executeBatch(new BSF_Batch_DriveShiftTimeBlockAssignment(), 200);
        Test.stopTest();

        shift = [SELECT sked_Time_Block__c, sked_Contention__c FROM sked_Drive_Shift__c WHERE Id = :shift.Id];
        System.assertEquals(tb.Id, shift.sked_Time_Block__c, 'Shift fully inside one time block should be assigned to it.');
        System.assertEquals(null, shift.sked_Contention__c, 'A single clean fit should clear any contention code.');
    }

    @isTest
    static void testShiftOutsideTimeBlock_SetsOutOfTimeBlockContention() {
        sked_Drive__c drive = [SELECT Id, sked_Collection_Operation__c FROM sked_Drive__c WHERE Name = 'Active Mobile Drive' LIMIT 1];
        Date driveDate = sharedDriveDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Morning',
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Time__c = Time.newInstance(12, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = drive.sked_Collection_Operation__c,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = driveDate.addDays(-1),
            Effective_End_Date__c = driveDate.addDays(1)
        );

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(13, 0, 0, 0)
        );
        insert shift;

        Test.startTest();
        Database.executeBatch(new BSF_Batch_DriveShiftTimeBlockAssignment(), 200);
        Test.stopTest();

        shift = [SELECT sked_Time_Block__c, sked_Contention__c FROM sked_Drive_Shift__c WHERE Id = :shift.Id];
        System.assertEquals(tb.Id, shift.sked_Time_Block__c, 'The only applicable time block should still be linked.');
        System.assertEquals(
            skedConstants.CONTENTION_CODE_OUT_OF_TIME_BLOCK,
            shift.sked_Contention__c,
            'A shift extending beyond its single applicable time block should be flagged Out Of Time Block.'
        );
    }

    @isTest
    static void testShiftFitsMultipleTimeBlocks_SetsFitsMultipleContention() {
        sked_Drive__c drive = [SELECT Id, sked_Collection_Operation__c FROM sked_Drive__c WHERE Name = 'Active Mobile Drive' LIMIT 1];
        Date driveDate = sharedDriveDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tbNarrow = new Time_Block__c(
            Name = 'TB Narrow',
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        Time_Block__c tbWide = new Time_Block__c(
            Name = 'TB Wide',
            Start_Time__c = Time.newInstance(6, 0, 0, 0),
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert new List<Time_Block__c>{ tbNarrow, tbWide };

        insert new List<Collection_Operation_Time_Block__c>{
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = drive.sked_Collection_Operation__c,
                Time_Block__c = tbNarrow.Id,
                Effective_Start_Date__c = driveDate.addDays(-1),
                Effective_End_Date__c = driveDate.addDays(1)
            ),
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = drive.sked_Collection_Operation__c,
                Time_Block__c = tbWide.Id,
                Effective_Start_Date__c = driveDate.addDays(-1),
                Effective_End_Date__c = driveDate.addDays(1)
            )
        };

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0)
        );
        insert shift;

        Test.startTest();
        Database.executeBatch(new BSF_Batch_DriveShiftTimeBlockAssignment(), 200);
        Test.stopTest();

        shift = [SELECT sked_Time_Block__c, sked_Contention__c FROM sked_Drive_Shift__c WHERE Id = :shift.Id];
        System.assertEquals(null, shift.sked_Time_Block__c, 'A shift that fits inside more than one time block should not be pinned to either.');
        System.assertEquals(skedConstants.CONTENTION_CODE_FITS_MULTIPLE_TIME_BLOCKS, shift.sked_Contention__c);
    }

    @isTest
    static void testShiftMissingTimeBlock_SetsMissingTimeBlockContention() {
        sked_Drive__c drive = [SELECT Id, sked_Collection_Operation__c FROM sked_Drive__c WHERE Name = 'Active Mobile Drive' LIMIT 1];
        Date driveDate = sharedDriveDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tbEarly = new Time_Block__c(
            Name = 'TB Early',
            Start_Time__c = Time.newInstance(6, 0, 0, 0),
            End_Time__c = Time.newInstance(8, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        Time_Block__c tbLate = new Time_Block__c(
            Name = 'TB Late',
            Start_Time__c = Time.newInstance(15, 0, 0, 0),
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert new List<Time_Block__c>{ tbEarly, tbLate };

        insert new List<Collection_Operation_Time_Block__c>{
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = drive.sked_Collection_Operation__c,
                Time_Block__c = tbEarly.Id,
                Effective_Start_Date__c = driveDate.addDays(-1),
                Effective_End_Date__c = driveDate.addDays(1)
            ),
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = drive.sked_Collection_Operation__c,
                Time_Block__c = tbLate.Id,
                Effective_Start_Date__c = driveDate.addDays(-1),
                Effective_End_Date__c = driveDate.addDays(1)
            )
        };

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(9, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(13, 0, 0, 0)
        );
        insert shift;

        Test.startTest();
        Database.executeBatch(new BSF_Batch_DriveShiftTimeBlockAssignment(), 200);
        Test.stopTest();

        shift = [SELECT sked_Time_Block__c, sked_Contention__c FROM sked_Drive_Shift__c WHERE Id = :shift.Id];
        System.assertEquals(null, shift.sked_Time_Block__c, 'No time block fits the shift, so none should be assigned.');
        System.assertEquals(skedConstants.CONTENTION_CODE_MISSING_TIME_BLOCK, shift.sked_Contention__c);
    }

    @isTest
    static void testNoApplicableTimeBlock_LeavesShiftUnchanged() {
        sked_Drive__c drive = [SELECT Id FROM sked_Drive__c WHERE Name = 'Active Mobile Drive' LIMIT 1];

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0)
        );
        insert shift;

        Test.startTest();
        Database.executeBatch(new BSF_Batch_DriveShiftTimeBlockAssignment(), 200);
        Test.stopTest();

        shift = [SELECT sked_Time_Block__c, sked_Contention__c FROM sked_Drive_Shift__c WHERE Id = :shift.Id];
        System.assertEquals(null, shift.sked_Time_Block__c, 'With no Collection Operation Time Block configured, no assignment should occur.');
        System.assertEquals(null, shift.sked_Contention__c, 'With no applicable time block, contention should be left as-is.');
    }

    @isTest
    static void testCancelledDrive_ShiftExcludedFromProcessing() {
        sked_Drive__c drive = [SELECT Id, sked_Collection_Operation__c FROM sked_Drive__c WHERE Name = 'Cancelled Mobile Drive' LIMIT 1];
        Date driveDate = sharedDriveDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Cancel Test',
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = drive.sked_Collection_Operation__c,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = driveDate.addDays(-1),
            Effective_End_Date__c = driveDate.addDays(1)
        );

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0)
        );
        insert shift;

        Test.startTest();
        Database.executeBatch(new BSF_Batch_DriveShiftTimeBlockAssignment(), 200);
        Test.stopTest();

        shift = [SELECT sked_Time_Block__c, sked_Contention__c FROM sked_Drive_Shift__c WHERE Id = :shift.Id];
        System.assertEquals(null, shift.sked_Time_Block__c, 'Shifts on a Cancelled drive should never be picked up by the batch.');
        System.assertEquals(null, shift.sked_Contention__c);
    }

    @isTest
    static void testFixedSiteNonIntegratedWB_IsIncludedAndAssignsTimeBlock() {
        sked_Drive__c drive = [SELECT Id, sked_Collection_Operation__c FROM sked_Drive__c WHERE Name = 'Fixed Site WB Drive' LIMIT 1];
        Date driveDate = sharedDriveDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Fixed Site WB',
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = drive.sked_Collection_Operation__c,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = driveDate.addDays(-1),
            Effective_End_Date__c = driveDate.addDays(1)
        );

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0)
        );
        insert shift;

        Test.startTest();
        Database.executeBatch(new BSF_Batch_DriveShiftTimeBlockAssignment(), 200);
        Test.stopTest();

        shift = [SELECT sked_Time_Block__c, sked_Contention__c FROM sked_Drive_Shift__c WHERE Id = :shift.Id];
        System.assertEquals(
            tb.Id,
            shift.sked_Time_Block__c,
            'Non Integrated WB fixed site drives should be processed the same way as Mobile drives.'
        );
        System.assertEquals(null, shift.sked_Contention__c);
    }

    @isTest
    static void testConstructorScopesToProvidedCollectionOperationIds() {
        sked_Drive__c inScopeDrive = [SELECT Id, sked_Collection_Operation__c FROM sked_Drive__c WHERE Name = 'Active Mobile Drive' LIMIT 1];
        sked_Drive__c outOfScopeDrive = [SELECT Id, sked_Collection_Operation__c FROM sked_Drive__c WHERE Name = 'Mobile Drive CO2' LIMIT 1];
        Date driveDate = sharedDriveDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tbInScope = new Time_Block__c(
            Name = 'TB CO1',
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        Time_Block__c tbOutOfScope = new Time_Block__c(
            Name = 'TB CO2',
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert new List<Time_Block__c>{ tbInScope, tbOutOfScope };

        insert new List<Collection_Operation_Time_Block__c>{
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = inScopeDrive.sked_Collection_Operation__c,
                Time_Block__c = tbInScope.Id,
                Effective_Start_Date__c = driveDate.addDays(-1),
                Effective_End_Date__c = driveDate.addDays(1)
            ),
            new Collection_Operation_Time_Block__c(
                Collection_Operation__c = outOfScopeDrive.sked_Collection_Operation__c,
                Time_Block__c = tbOutOfScope.Id,
                Effective_Start_Date__c = driveDate.addDays(-1),
                Effective_End_Date__c = driveDate.addDays(1)
            )
        };

        sked_Drive_Shift__c inScopeShift = new sked_Drive_Shift__c(
            sked_Drive__c = inScopeDrive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0)
        );
        sked_Drive_Shift__c outOfScopeShift = new sked_Drive_Shift__c(
            sked_Drive__c = outOfScopeDrive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0)
        );
        insert new List<sked_Drive_Shift__c>{ inScopeShift, outOfScopeShift };

        Test.startTest();
        Database.executeBatch(
            new BSF_Batch_DriveShiftTimeBlockAssignment(new Set<Id>{ inScopeDrive.sked_Collection_Operation__c }),
            200
        );
        Test.stopTest();

        inScopeShift = [SELECT sked_Time_Block__c FROM sked_Drive_Shift__c WHERE Id = :inScopeShift.Id];
        outOfScopeShift = [SELECT sked_Time_Block__c FROM sked_Drive_Shift__c WHERE Id = :outOfScopeShift.Id];

        System.assertEquals(tbInScope.Id, inScopeShift.sked_Time_Block__c, 'Shift under the scoped Collection Operation should be processed.');
        System.assertEquals(null, outOfScopeShift.sked_Time_Block__c, 'Shift under a Collection Operation outside the provided scope should be left untouched.');
    }

    @isTest
    static void testAlreadyResolvedShift_NotProcessedByBatch() {
        sked_Drive__c drive = [SELECT Id, sked_Collection_Operation__c FROM sked_Drive__c WHERE Name = 'Active Mobile Drive' LIMIT 1];
        Date driveDate = sharedDriveDate();
        String dayName = sharedDayOfWeek();

        Time_Block__c tb = new Time_Block__c(
            Name = 'TB Resolved Test',
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = dayName
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = drive.sked_Collection_Operation__c,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = driveDate.addDays(-1),
            Effective_End_Date__c = driveDate.addDays(1)
        );

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(10, 0, 0, 0),
            sked_Contention_Resolution__c = 'Elect to acknowledge the drive shift without Time Block'
        );
        insert shift;

        Test.startTest();
        Database.executeBatch(new BSF_Batch_DriveShiftTimeBlockAssignment(), 200);
        Test.stopTest();

        shift = [SELECT sked_Time_Block__c, sked_Contention__c FROM sked_Drive_Shift__c WHERE Id = :shift.Id];
        System.assertEquals(null, shift.sked_Time_Block__c, 'A shift with an existing Contention Resolution should be skipped entirely by the batch.');
        System.assertEquals(null, shift.sked_Contention__c);
    }

    private static Date sharedDriveDate() {
        return Date.today().addDays(14);
    }

    private static String sharedDayOfWeek() {
        return DateTime.newInstance(sharedDriveDate(), Time.newInstance(0, 0, 0, 0)).format('EEEE');
    }
}
