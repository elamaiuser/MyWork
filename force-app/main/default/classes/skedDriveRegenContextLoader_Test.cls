@isTest
private class skedDriveRegenContextLoader_Test {
    @isTest
    static void testLoad_populatesContextFromDriveGraph() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        Test.stopTest();

        System.assertEquals(drive.Id, ctx.drive.Id, 'Loaded drive must match the requested Id');
        System.assertNotEquals(null, ctx.snapshot, 'A snapshot must be captured at load time');
    }

    @isTest
    static void testLoad_snapshotIsDeepCloneNotSameReference() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        Test.stopTest();

        Decimal originalSlots = ctx.drive.sked_Total_Slots__c;
        ctx.drive.sked_Total_Slots__c = (originalSlots == null ? 0 : originalSlots) + 999;

        System.assertNotEquals(ctx.drive.sked_Total_Slots__c, ctx.snapshot.drive.sked_Total_Slots__c,
            'Mutating the live context must not affect the snapshot taken at load time');
        System.assertEquals(originalSlots, ctx.snapshot.drive.sked_Total_Slots__c,
            'Snapshot must retain the original value from load time');
    }

    @isTest
    static void testLoad_partitionsJobsByDriveLevelVsShiftLevel() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        sked__Job__c driveLevelJob = new sked__Job__c(sked_Drive__c = drive.Id, sked_Resource_Role__c = 'Team Supervisor', sked__Region__c = regionId, sked__Duration__c = 60);
        sked__Job__c shiftLevelJob = new sked__Job__c(sked_Drive__c = drive.Id, sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'VP/HH', sked__Region__c = regionId, sked__Duration__c = 60);
        insert new List<sked__Job__c>{ driveLevelJob, shiftLevelJob };

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        Test.stopTest();

        Set<Id> driveLevelJobIds = new Set<Id>();
        for (sked__Job__c job : ctx.driveLevelJobs) {
            driveLevelJobIds.add(job.Id);
        }
        System.assert(driveLevelJobIds.contains(driveLevelJob.Id), 'A job with no shift must be classified as drive-level');

        List<sked__Job__c> shiftJobs = ctx.jobsByShiftId.get(shift.Id);
        System.assertNotEquals(null, shiftJobs, 'Jobs for this shift must be grouped under its Id');
        Set<Id> shiftJobIds = new Set<Id>();
        for (sked__Job__c job : shiftJobs) {
            shiftJobIds.add(job.Id);
        }
        System.assert(shiftJobIds.contains(shiftLevelJob.Id), 'A job with a shift must be classified under that shift Id');
    }

    /**
     * skedDriveContentionValidator's STAFFING_COMPLEMENT_CHANGED check keys ctx.jobsByShiftId and
     * ctx.snapshot.jobsByShiftId by the same shift Id to pair current vs. backup jobs. ctx.snapshot
     * only exists via deepClone()'s JSON serialize/deserialize round-trip - this proves that round-trip
     * preserves Map<Id, List<sked__Job__c>> keys well enough for that Id-based lookup to still match,
     * not just that ctx.snapshot exists and differs by reference (already covered above).
     */
    @isTest
    static void testLoad_snapshotJobsByShiftIdKeysSurviveDeepCloneRoundTrip() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;
        sked__Job__c shiftLevelJob = new sked__Job__c(sked_Drive__c = drive.Id, sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'VP/HH', sked__Region__c = regionId, sked__Duration__c = 60);
        insert shiftLevelJob;

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        Test.stopTest();

        System.assertEquals(ctx.jobsByShiftId.keySet(), ctx.snapshot.jobsByShiftId.keySet(),
            'ctx.snapshot.jobsByShiftId must be keyed by the same shift Ids as ctx.jobsByShiftId after the deepClone round-trip');
        List<sked__Job__c> snapshotShiftJobs = ctx.snapshot.jobsByShiftId.get(shift.Id);
        System.assertNotEquals(null, snapshotShiftJobs, 'The shift Id key itself must resolve a lookup against ctx.snapshot.jobsByShiftId, not just compare equal as a set');
        System.assertEquals(1, snapshotShiftJobs.size(), 'The cloned shift-level job must round-trip into the snapshot');
        System.assertEquals(shiftLevelJob.Id, snapshotShiftJobs[0].Id, 'The cloned job must retain its original Id');
    }

    // ===== Staffing-constraint drive type =====

    private static final Decimal MOBILE_STAFF_CONSTRAINT = 11;
    private static final Decimal FIXED_SITE_STAFF_CONSTRAINT = 22;

    // Both drive types are always inserted so the assertion is on WHICH constraint came back, never on
    // the only one that exists.
    private static void insertStaffingConstraintsForBothDriveTypes(sked_Drive__c drive) {
        insert new List<sked_Staffing_Constraint__c>{
            new sked_Staffing_Constraint__c(
                sked_Collection_Operation__c = drive.sked_Collection_Operation__c,
                sked_Drive_Type__c = skedConstants.DRIVE_TYPE_MOBILE,
                sked_Date_of_Constraint__c = drive.sked_Drive_Date__c,
                sked_Total_Staff_Constraints__c = MOBILE_STAFF_CONSTRAINT
            ),
            new sked_Staffing_Constraint__c(
                sked_Collection_Operation__c = drive.sked_Collection_Operation__c,
                sked_Drive_Type__c = skedConstants.DRIVE_TYPE_FIXED_SITE,
                sked_Date_of_Constraint__c = drive.sked_Drive_Date__c,
                sked_Total_Staff_Constraints__c = FIXED_SITE_STAFF_CONSTRAINT
            )
        };
    }

    private static sked_Drive__c queryDriveTypeFields(Id driveId) {
        return [SELECT Id, sked_Type_of_Drive__c, sked_Operation_Type__c FROM sked_Drive__c WHERE Id = :driveId];
    }

    @isTest
    static void testLoadReferenceData_mobileDrive_loadsMobileStaffingConstraint() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        insertStaffingConstraintsForBothDriveTypes(drive);

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        Test.stopTest();

        System.assertEquals(1, ctx.staffingConstraints.size(), 'Exactly one of the two staffing constraints must match a Mobile drive');
        System.assertEquals(MOBILE_STAFF_CONSTRAINT, ctx.staffingConstraints[0].sked_Total_Staff_Constraints__c,
            'A Mobile drive must keep loading Mobile-type staffing constraints');
    }

    // wbFixedSiteGenerator.js:614 hardcodes driveTypes = [DRIVE_TYPE.MOBILE] where both siblings pass
    // this.drive.typeOfDrive (mobileGenerator.js:759, fixedSiteGenerator.js:600).
    @isTest
    static void testLoadReferenceData_wbFixedSiteDrive_loadsMobileStaffingConstraint() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        insertStaffingConstraintsForBothDriveTypes(drive);

        sked_Drive__c driveTypeFields = queryDriveTypeFields(drive.Id);
        System.assertEquals(skedConstants.DRIVE_TYPE_FIXED_SITE, driveTypeFields.sked_Type_of_Drive__c,
            'Fixture check: testDrive2 must be a Fixed Site drive');
        System.assertEquals(skedConstants.OPERATION_TYPE_WB, driveTypeFields.sked_Operation_Type__c,
            'Fixture check: testDrive2 must be a Non Integrated WB drive');

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        Test.stopTest();

        System.assertEquals(1, ctx.staffingConstraints.size(), 'Exactly one of the two staffing constraints must match a WB drive');
        System.assertEquals(MOBILE_STAFF_CONSTRAINT, ctx.staffingConstraints[0].sked_Total_Staff_Constraints__c,
            'A WB Fixed Site drive draws on Mobile-typed staffing pools, so it must load the Mobile constraint (11), not the Fixed Site one (22)');
    }

    // The WB branch must be gated on the operation type, not on Fixed Site alone - an Integrated Fixed
    // Site drive still reads its own drive type. SiteService blocks an Operation Type change while a
    // live Drive references the site, hence the cancel/change/restore dance.
    @isTest
    static void testLoadReferenceData_nonWbFixedSiteDrive_loadsFixedSiteStaffingConstraint() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
        update drive;
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        site.Operation_Type__c = skedConstants.OPERATION_TYPE_INTEGRATED;
        update site;
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        update drive;
        insertStaffingConstraintsForBothDriveTypes(drive);

        sked_Drive__c driveTypeFields = queryDriveTypeFields(drive.Id);
        System.assertEquals(skedConstants.OPERATION_TYPE_INTEGRATED, driveTypeFields.sked_Operation_Type__c,
            'Fixture check: the site\'s Operation Type change must have reached the drive\'s formula field');

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        Test.stopTest();

        System.assertEquals(1, ctx.staffingConstraints.size(), 'Exactly one of the two staffing constraints must match a non-WB Fixed Site drive');
        System.assertEquals(FIXED_SITE_STAFF_CONSTRAINT, ctx.staffingConstraints[0].sked_Total_Staff_Constraints__c,
            'A non-WB Fixed Site drive must keep loading Fixed Site staffing constraints');
    }
}
