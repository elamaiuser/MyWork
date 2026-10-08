@IsTest
public class BSF_Batch_TBStaffingConstraint_Test {

    @testSetup
    static void setupData() {
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c(
            Name = 'Test CO 1',
            External_Id__c = 'TEST-TBS-CO-1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30'
        );
        insert co;

        Biomed_Collection_Op_Center__c deactivatedCo = co.clone(false, true, false, false);
        deactivatedCo.Name = 'Test CO Deactivated';
        deactivatedCo.External_Id__c = 'TEST-TBS-CO-DEACTIVATED';
        deactivatedCo.sked_Is_Deactivated__c = true;
        insert deactivatedCo;
    }

    @isTest
    static void testHappyPath_ClonesConstraintWithMatchingTimeBlock() {
        Biomed_Collection_Op_Center__c co = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Test CO 1' LIMIT 1];
        Date constraintDate = sharedConstraintDate();
        String dayName = sharedDayOfWeek();

        Id tbId = createTimeBlockForCO('TB Happy Path', co.Id, dayName, constraintDate.addDays(-1), constraintDate.addDays(1));
        insert buildConstraint(co.Id, constraintDate, skedConstants.DRIVE_TYPE_MOBILE, null, 42);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_TBStaffingConstraintRollout(), 200);
        Test.stopTest();

        List<sked_Staffing_Constraint__c> results = [
            SELECT sked_Time_Block__c, sked_Total_Staff_Constraints__c
            FROM sked_Staffing_Constraint__c
            WHERE sked_Collection_Operation__c = :co.Id AND sked_Date_of_Constraint__c = :constraintDate
        ];
        System.assertEquals(2, results.size(), 'Original Operation Hours record plus one new Time Block record should exist.');

        sked_Staffing_Constraint__c newRecord;
        for (sked_Staffing_Constraint__c sc : results) {
            if (sc.sked_Time_Block__c != null) {
                newRecord = sc;
            }
        }
        System.assertNotEquals(null, newRecord, 'A new Time Block specific constraint should have been created.');
        System.assertEquals(tbId, newRecord.sked_Time_Block__c);
        System.assertEquals(42, newRecord.sked_Total_Staff_Constraints__c, 'Total Staff Constraints should be preserved from the template via cloning.');
    }

    @isTest
    static void testAlreadyConverted_SkipsWithoutDuplicate() {
        Biomed_Collection_Op_Center__c co = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Test CO 1' LIMIT 1];
        Date constraintDate = sharedConstraintDate();
        String dayName = sharedDayOfWeek();

        Id tbId = createTimeBlockForCO('TB Already Converted', co.Id, dayName, constraintDate.addDays(-1), constraintDate.addDays(1));
        insert buildConstraint(co.Id, constraintDate, skedConstants.DRIVE_TYPE_MOBILE, null, 10);
        insert buildConstraint(co.Id, constraintDate, skedConstants.DRIVE_TYPE_MOBILE, tbId, 10);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_TBStaffingConstraintRollout(), 200);
        Test.stopTest();

        List<sked_Staffing_Constraint__c> withTimeBlock = [
            SELECT Id FROM sked_Staffing_Constraint__c
            WHERE sked_Collection_Operation__c = :co.Id AND sked_Date_of_Constraint__c = :constraintDate AND sked_Time_Block__c != NULL
        ];
        System.assertEquals(1, withTimeBlock.size(), 'Re-running should not create a duplicate Time Block constraint.');
    }

    @isTest
    static void testNoMatchingTimeBlockForDay_SkipsRecord() {
        Biomed_Collection_Op_Center__c co = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Test CO 1' LIMIT 1];
        Date constraintDate = sharedConstraintDate();

        createTimeBlockForCO('TB Wrong Day', co.Id, otherDayOfWeek(), constraintDate.addDays(-1), constraintDate.addDays(1));
        insert buildConstraint(co.Id, constraintDate, skedConstants.DRIVE_TYPE_MOBILE, null, 10);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_TBStaffingConstraintRollout(), 200);
        Test.stopTest();

        List<sked_Staffing_Constraint__c> results = [
            SELECT Id, sked_Time_Block__c FROM sked_Staffing_Constraint__c
            WHERE sked_Collection_Operation__c = :co.Id AND sked_Date_of_Constraint__c = :constraintDate
        ];
        System.assertEquals(1, results.size(), 'No Time Block applies to this day, so no new record should be created.');
        System.assertEquals(null, results[0].sked_Time_Block__c);
    }

    @isTest
    static void testNonMobileDriveType_ExcludedFromProcessing() {
        Biomed_Collection_Op_Center__c co = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Test CO 1' LIMIT 1];
        Date constraintDate = sharedConstraintDate();
        String dayName = sharedDayOfWeek();

        createTimeBlockForCO('TB Fixed Site Excl', co.Id, dayName, constraintDate.addDays(-1), constraintDate.addDays(1));
        insert buildConstraint(co.Id, constraintDate, 'Fixed Site', null, 10);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_TBStaffingConstraintRollout(), 200);
        Test.stopTest();

        List<sked_Staffing_Constraint__c> results = [
            SELECT Id, sked_Time_Block__c FROM sked_Staffing_Constraint__c
            WHERE sked_Collection_Operation__c = :co.Id AND sked_Date_of_Constraint__c = :constraintDate
        ];
        System.assertEquals(1, results.size(), 'Fixed Site constraints are out of scope and must be left untouched.');
        System.assertEquals(null, results[0].sked_Time_Block__c);
    }

    @isTest
    static void testDeactivatedCollectionOperation_ExcludedFromDefaultRun() {
        Biomed_Collection_Op_Center__c deactivatedCo = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Test CO Deactivated' LIMIT 1];
        Date constraintDate = sharedConstraintDate();
        String dayName = sharedDayOfWeek();

        createTimeBlockForCO('TB Deactivated CO', deactivatedCo.Id, dayName, constraintDate.addDays(-1), constraintDate.addDays(1));
        insert buildConstraint(deactivatedCo.Id, constraintDate, skedConstants.DRIVE_TYPE_MOBILE, null, 10);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_TBStaffingConstraintRollout(), 200);
        Test.stopTest();

        List<sked_Staffing_Constraint__c> results = [
            SELECT Id, sked_Time_Block__c FROM sked_Staffing_Constraint__c
            WHERE sked_Collection_Operation__c = :deactivatedCo.Id AND sked_Date_of_Constraint__c = :constraintDate
        ];
        System.assertEquals(1, results.size(), 'A deactivated Collection Operation must not be processed by the default run.');
        System.assertEquals(null, results[0].sked_Time_Block__c);
    }

    @isTest
    static void testConstructorScopedToExplicitIds_BypassesEligibilityFilter() {
        Biomed_Collection_Op_Center__c deactivatedCo = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Test CO Deactivated' LIMIT 1];
        Date constraintDate = sharedConstraintDate();
        String dayName = sharedDayOfWeek();

        Id tbId = createTimeBlockForCO('TB Deactivated Explicit', deactivatedCo.Id, dayName, constraintDate.addDays(-1), constraintDate.addDays(1));
        insert buildConstraint(deactivatedCo.Id, constraintDate, skedConstants.DRIVE_TYPE_MOBILE, null, 10);

        Test.startTest();
        Database.executeBatch(new BSF_Batch_TBStaffingConstraintRollout(new Set<Id>{ deactivatedCo.Id }), 200);
        Test.stopTest();

        List<sked_Staffing_Constraint__c> withTimeBlock = [
            SELECT Id, sked_Time_Block__c FROM sked_Staffing_Constraint__c
            WHERE sked_Collection_Operation__c = :deactivatedCo.Id AND sked_Date_of_Constraint__c = :constraintDate AND sked_Time_Block__c != NULL
        ];
        System.assertEquals(1, withTimeBlock.size(), 'An explicit CO scope should bypass the eligibility query, even for a normally-excluded (deactivated) CO.');
        System.assertEquals(tbId, withTimeBlock[0].sked_Time_Block__c);
    }

    @isTest
    static void testDuplicateTemplatesForSameCoDate_OnlyOneCloneCreated() {
        Biomed_Collection_Op_Center__c co = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Test CO 1' LIMIT 1];
        Date constraintDate = sharedConstraintDate();
        String dayName = sharedDayOfWeek();

        createTimeBlockForCO('TB Duplicate Templates', co.Id, dayName, constraintDate.addDays(-1), constraintDate.addDays(1));
        insert new List<sked_Staffing_Constraint__c>{
            buildConstraint(co.Id, constraintDate, skedConstants.DRIVE_TYPE_MOBILE, null, 5),
            buildConstraint(co.Id, constraintDate, skedConstants.DRIVE_TYPE_MOBILE, null, 15)
        };

        Test.startTest();
        Database.executeBatch(new BSF_Batch_TBStaffingConstraintRollout(), 200);
        Test.stopTest();

        List<sked_Staffing_Constraint__c> withTimeBlock = [
            SELECT Id FROM sked_Staffing_Constraint__c
            WHERE sked_Collection_Operation__c = :co.Id AND sked_Date_of_Constraint__c = :constraintDate AND sked_Time_Block__c != NULL
        ];
        System.assertEquals(1, withTimeBlock.size(), 'Only one clone should be created per (Collection Operation, Date), even with duplicate templates.');
    }

    private static Id createTimeBlockForCO(String tbName, Id coId, String daysOfWeek, Date effStart, Date effEnd) {
        Time_Block__c tb = new Time_Block__c(
            Name = tbName,
            Start_Time__c = Time.newInstance(7, 0, 0, 0),
            End_Time__c = Time.newInstance(17, 0, 0, 0),
            Days_of_Week__c = daysOfWeek
        );
        insert tb;

        insert new Collection_Operation_Time_Block__c(
            Collection_Operation__c = coId,
            Time_Block__c = tb.Id,
            Effective_Start_Date__c = effStart,
            Effective_End_Date__c = effEnd
        );

        return tb.Id;
    }

    private static sked_Staffing_Constraint__c buildConstraint(Id coId, Date constraintDate, String driveType, Id timeBlockId, Decimal totalStaff) {
        return new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = coId,
            sked_Date_of_Constraint__c = constraintDate,
            sked_Drive_Type__c = driveType,
            sked_Time_Block__c = timeBlockId,
            sked_Total_Staff_Constraints__c = totalStaff
        );
    }

    private static Date sharedConstraintDate() {
        return Date.today().addDays(30);
    }

    private static String sharedDayOfWeek() {
        return DateTime.newInstance(sharedConstraintDate(), Time.newInstance(0, 0, 0, 0)).format('EEEE');
    }

    private static String otherDayOfWeek() {
        return sharedDayOfWeek() == 'Monday' ? 'Tuesday' : 'Monday';
    }
}
