@isTest
private class skedFixedSiteDriveJobBuilder_Test {

    // See reference_fixed_site_test_fixture_gotchas.md - testDrive2/testLocation2 default to WB.
    private static sked_Drive__c setOperationTypeAndQuery(sked_Drive__c drive, sked__Location__c site, String operationType) {
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
        update drive;
        site.Operation_Type__c = operationType;
        update site;
        drive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
        update drive;

        return queryDriveForJobBuilder(drive.Id);
    }

    private static sked_Drive__c queryDriveForJobBuilder(Id driveId) {
        return [
            SELECT Id, sked_Drive_Site__c, sked_Collection_Operation__c, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c,
                sked_Operation_Type__c, sked_Account__c, sked_Account__r.Accepts_Automation2__c, sked_Travel_Time_Included__c,
                sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c,
                sked_Plasma_Projected_Procedures__c, sked_Number_of_Vehicles__c, sked_Number_of_2RBC_Assets__c
            FROM sked_Drive__c
            WHERE Id = :driveId
        ];
    }

    // Chains the real Fixed Site calculators exactly as a future engine task will, mirroring
    // skedMobileDriveJobBuilder_Test's own buildShifts helper for the Mobile side.
    private static List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> buildShifts(sked_Drive__c drive) {
        skedFixedSiteDriveShiftCalculator.MasterData shiftMasterData = skedFixedSiteDriveShiftCalculator.loadMasterData(drive);
        skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata(drive, shiftMasterData);

        skedFixedSiteRoleQuantityCalculator.MasterData roleMasterData = skedFixedSiteRoleQuantityCalculator.loadMasterData(drive);
        Map<String, Map<String, skedFixedSiteRoleQuantityCalculator.RoleQuantity>> roleQuantities =
            skedFixedSiteRoleQuantityCalculator.calculateRoleQuantities(drive, shiftsMetadata, roleMasterData);
        Map<String, Decimal> assetQuantityByType = skedFixedSiteRoleQuantityCalculator.calculateAssetQuantity(drive);

        skedFixedSiteVolunteerCalculator.MasterData volunteerMasterData = skedFixedSiteVolunteerCalculator.loadMasterData(drive);
        Map<String, Integer> volunteerQuantityByShiftKey =
            skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities(shiftsMetadata, volunteerMasterData, shiftMasterData.timezoneSidId);

        Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>> jobTagsByResourceType = skedMobileDriveShiftCalculator.loadJobTagsMap(drive);

        return skedFixedSiteDriveJobBuilder.buildProposedDriveShifts(
            drive, shiftsMetadata, roleQuantities, assetQuantityByType, volunteerQuantityByShiftKey, jobTagsByResourceType);
    }

    // setupCommonTestData already links testCollectionOperation1 to a generic Fixed Site SDM covering
    // the whole test date range - loadMasterData's LIMIT 1 query has no ORDER BY, so a second matching
    // junction is a collision, not an addition. Remove the existing one first.
    private static void replaceFixedSiteSdmLink(Id collectionOperationId, Id staffingDecisionMatrixId) {
        delete [
            SELECT Id FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c = :collectionOperationId
                AND sked_Staffing_Decision_Matrix__r.RecordType.Name = :skedConstants.DRIVE_TYPE_FIXED_SITE
        ];
        insert new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collectionOperationId,
            sked_Staffing_Decision_Matrix__c = staffingDecisionMatrixId
        );
    }

    private static void deleteFixedSiteSdmLink(Id collectionOperationId) {
        delete [
            SELECT Id FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c = :collectionOperationId
                AND sked_Staffing_Decision_Matrix__r.RecordType.Name = :skedConstants.DRIVE_TYPE_FIXED_SITE
        ];
    }

    private static sked_Staffing_Decision_Matrix__c buildFixedSiteStaffingDecisionMatrix() {
        return new sked_Staffing_Decision_Matrix__c(
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByName().get(skedConstants.DRIVE_TYPE_FIXED_SITE).getRecordTypeId()
        );
    }

    private static sked_Role_Time_Detail__c buildRoleTimeDetail(String resourceRoleGroup, Decimal leadTime, Decimal setupTime, Decimal breakdownTime, Decimal wrapUpTime) {
        return new sked_Role_Time_Detail__c(
            sked_Type__c = 'Global',
            sked_Resource_Role_Group__c = resourceRoleGroup,
            sked_Days_of_Week__c = 'Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday',
            sked_Drive_Type__c = skedConstants.DRIVE_TYPE_FIXED_SITE,
            sked_Mobile_Type__c = 'Inside',
            sked_Lead_Time__c = leadTime,
            sked_Setup_Time__c = setupTime,
            sked_Breakdown_Time__c = breakdownTime,
            sked_Wrap_up_Time__c = wrapUpTime
        );
    }

    private static sked__Job__c findJobByRole(List<sked__Job__c> jobs, String role) {
        for (sked__Job__c job : jobs) {
            if (job.sked_Resource_Role__c == role) {
                return job;
            }
        }
        return null;
    }

    private static sked__Job__c findVolunteerJob(List<sked__Job__c> jobs) {
        for (sked__Job__c job : jobs) {
            if (String.isNotBlank(job.sked_Volunteer_Role__c)) {
                return job;
            }
        }
        return null;
    }

    private static sked__Job__c findAssetJob(List<sked__Job__c> jobs, String assetType, String equipmentSubtype) {
        for (sked__Job__c job : jobs) {
            if (job.sked_Asset_Type__c == assetType && (equipmentSubtype == null || job.sked_Equipment_Subtype__c == equipmentSubtype)) {
                return job;
            }
        }
        return null;
    }

    private static Integer indexOfRoleJob(List<sked__Job__c> jobs, String role) {
        for (Integer i = 0; i < jobs.size(); i++) {
            if (jobs[i].sked_Resource_Role__c == role) {
                return i;
            }
        }
        return -1;
    }

    private static Integer indexOfVolunteerJob(List<sked__Job__c> jobs) {
        for (Integer i = 0; i < jobs.size(); i++) {
            if (String.isNotBlank(jobs[i].sked_Volunteer_Role__c)) {
                return i;
            }
        }
        return -1;
    }

    private static Integer indexOfAssetJob(List<sked__Job__c> jobs, String assetType) {
        for (Integer i = 0; i < jobs.size(); i++) {
            if (jobs[i].sked_Asset_Type__c == assetType) {
                return i;
            }
        }
        return -1;
    }

    private static Boolean containsTagId(List<sked__Job_Tag__c> jobTags, Id tagId) {
        if (jobTags == null) {
            return false;
        }
        for (sked__Job_Tag__c jobTag : jobTags) {
            if (jobTag.sked__Tag__c == tagId) {
                return true;
            }
        }
        return false;
    }

    @isTest
    static void testBuildProposedDriveShifts_roleJob_builtWithCorrectFieldsWhenQuantityPositive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = queryDriveForJobBuilder(((sked_Drive__c) testData.get('testDrive2')).Id);
        // Platelet-driven Apheresis staffing has no Operation Type gate (unlike WB/2RBC) - testDrive2's
        // default WB operation type is left untouched, no cancel/flip/restore dance needed.
        drive.sked_Platelet_Projected_Procedures__c = 20;

        // Both thresholds default to 0 (required field) - skedRoleTimeCalculator.calculateDriveShiftRoleTimeData
        // clamps setup time on every shift but the first, and breakdown time on every shift but the
        // last, down to whichever threshold is configured. Raise both so shift 0's full, unclamped
        // Staff-roles values are asserted below, not an artifact of the multi-shift clamp.
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Breakdown_Time_Threshold__c = 999;
        collectionOperation.sked_Setup_Time_Threshold__c = 999;
        update collectionOperation;

        sked_Staffing_Decision_Matrix__c sdm = buildFixedSiteStaffingDecisionMatrix();
        sdm.sked_Platelet_Round_Capacity__c = 2;
        insert sdm;
        replaceFixedSiteSdmLink(drive.sked_Collection_Operation__c, sdm.Id);

        // Deliberately distinct values per group - Apheresis maps to Staff roles, Apheresis Charge to
        // Supervisory roles (skedTestDataFactory.setupPredefinedData) - if the group lookup resolved
        // to the wrong group, or dropped the lookup and left every value 0, this test would catch it.
        insert new List<sked_Role_Time_Detail__c>{
            buildRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES, 5, 10, 20, 3),
            buildRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES, 1, 2, 4, 1)
        };

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        // 20 platelet procedures / 4 total rounds (testDrive2's default 10-hour window) / capacity 2 =
        // 2.5, rounds half-up to 3 - a positive quantity, so a job must be built.
        sked__Job__c apheresisJob = findJobByRole(shifts[0].jobs, 'Apheresis');
        System.assertNotEquals(null, apheresisJob, 'A positive Apheresis quantity must produce a role job');
        System.assertEquals(3, apheresisJob.sked__Quantity__c, 'Job quantity must equal the role-quantity calculator\'s output');
        System.assertEquals(3, apheresisJob.sked_System_Quantity__c, 'System quantity must mirror quantity for a freshly built job');
        System.assertEquals(false, apheresisJob.sked_Is_Manually_Created__c, 'A freshly built role job must never be flagged manually created');
        System.assertEquals(5, apheresisJob.sked_Lead_Time__c, 'Apheresis maps to the Staff roles group - lead time must come from that group\'s Role Time Detail, not Supervisory\'s');
        System.assertEquals(20, apheresisJob.sked_Breakdown_Time__c, 'Breakdown time must also come from the Staff roles group');
    }

    @isTest
    static void testBuildProposedDriveShifts_roleJob_notBuiltWhenQuantityZero() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        // testDrive2 defaults sked_Platelet_Projected_Procedures__c to 0/unset and stays WB (Apheresis's
        // non-Platelet contribution is gated to Integrated/APH only) - Apheresis resolves to a real 0
        // with zero extra setup, while Apheresis Charge (no quantity gate at all) still gets built.
        sked_Drive__c drive = queryDriveForJobBuilder(((sked_Drive__c) testData.get('testDrive2')).Id);

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        System.assertEquals(null, findJobByRole(shifts[0].jobs, 'Apheresis'), 'A zero Apheresis quantity must not produce a role job');
        sked__Job__c chargeJob = findJobByRole(shifts[0].jobs, 'Apheresis Charge');
        System.assertNotEquals(null, chargeJob, 'Apheresis Charge is always exactly 1 and must still be built');
        System.assertEquals(1, chargeJob.sked__Quantity__c, 'Apheresis Charge quantity must be exactly 1');
    }

    @isTest
    static void testBuildProposedDriveShifts_assetJobs_splitsIntoVehicleAndEquipmentOnFirstShift() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);
        drive.sked_Number_of_Vehicles__c = 3;
        drive.sked_Number_of_2RBC_Assets__c = 2;

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        sked__Job__c vehicleJob = findAssetJob(shifts[0].jobs, skedConstants.ASSET_TYPE_VEHICLE, null);
        System.assertNotEquals(null, vehicleJob, 'The first shift must get a Vehicle job');
        System.assertEquals(3, vehicleJob.sked__Quantity__c, 'Vehicle job quantity must be a flat passthrough of the drive field');

        sked__Job__c equipmentJob = findAssetJob(shifts[0].jobs, skedConstants.ASSET_TYPE_EQUIPMENT, '2RBC Asset');
        System.assertNotEquals(null, equipmentJob, 'The first shift must get an Equipment job with the 2RBC Asset subtype when Integrated');
        System.assertEquals(2, equipmentJob.sked__Quantity__c, 'Equipment job quantity must be a flat passthrough of the drive field');
    }

    @isTest
    static void testBuildProposedDriveShifts_assetJobs_vehicleAbsentWhenQuantityZero() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        // testDrive2 defaults sked_Number_of_Vehicles__c to null/unset - unlike Mobile's
        // buildAssetJob (always builds a Vehicle job, even at quantity 0), Fixed Site's asset jobs -
        // Vehicle included - must never be built at a non-positive quantity.
        sked_Drive__c drive = queryDriveForJobBuilder(((sked_Drive__c) testData.get('testDrive2')).Id);

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        System.assertEquals(null, findAssetJob(shifts[0].jobs, skedConstants.ASSET_TYPE_VEHICLE, null),
            'A zero/unset Vehicle quantity must not produce a phantom Vehicle job, even on the first shift');
    }

    @isTest
    static void testBuildProposedDriveShifts_assetJobs_absentOnShiftsAfterTheFirst() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);
        drive.sked_Number_of_Vehicles__c = 3;
        drive.sked_Number_of_2RBC_Assets__c = 2;

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        System.assertEquals(2, shifts.size(), 'testDrive2\'s default 10-hour window must still produce 2 shifts');
        System.assertEquals(null, findAssetJob(shifts[1].jobs, skedConstants.ASSET_TYPE_VEHICLE, null), 'Only the first shift may get a Vehicle job');
        System.assertEquals(null, findAssetJob(shifts[1].jobs, skedConstants.ASSET_TYPE_EQUIPMENT, null), 'Only the first shift may get an Equipment job');
    }

    @isTest
    static void testBuildProposedDriveShifts_volunteerJob_builtWhenQuantityPositive() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = queryDriveForJobBuilder(((sked_Drive__c) testData.get('testDrive2')).Id);
        drive.sked_Platelet_Projected_Procedures__c = 20;

        sked_Staffing_Decision_Matrix__c sdm = buildFixedSiteStaffingDecisionMatrix();
        sdm.sked_Platelet_Round_Capacity__c = 2;
        sdm.sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 0;
        sdm.sked_NR_Volunteer_Fixed_Site_Band_Upper__c = 5;
        insert sdm;
        replaceFixedSiteSdmLink(drive.sked_Collection_Operation__c, sdm.Id);

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        // Shift 0's 10 total projected procedures (20 platelet split evenly across 2 shifts) exceed the
        // band upper bound of 5, landing in the "high" band (quantity 2).
        sked__Job__c volunteerJob = findVolunteerJob(shifts[0].jobs);
        System.assertNotEquals(null, volunteerJob, 'A positive volunteer band quantity must produce a volunteer job');
        System.assertEquals(2, volunteerJob.sked_Redcross_Volunteer_Quantity__c, 'Redcross volunteer quantity must equal the band-derived value');
        System.assertEquals(0, volunteerJob.sked_Sponsor_Volunteer_Quantity__c, 'A freshly built volunteer job must never carry a sponsor quantity');
        System.assertEquals(2, volunteerJob.sked__Quantity__c, 'Quantity must equal the Redcross quantity with no sponsor contribution');
    }

    @isTest
    static void testBuildProposedDriveShifts_volunteerJob_absentWhenNoStaffingDecisionMatrixConfigured() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = queryDriveForJobBuilder(((sked_Drive__c) testData.get('testDrive2')).Id);
        // With no Fixed Site SDM linked, calculateVolunteerQuantities returns an empty map entirely -
        // every shift's volunteer quantity resolves to null/missing rather than 0.
        deleteFixedSiteSdmLink(drive.sked_Collection_Operation__c);

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        for (skedFixedSiteDriveJobBuilder.ProposedDriveShift shift : shifts) {
            System.assertEquals(null, findVolunteerJob(shift.jobs), 'With no Fixed Site SDM configured, no shift may get a volunteer job');
        }
    }

    @isTest
    static void testAssignFreshJobTags_attachesPersonTagSetToRoleAndVolunteerJobs() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = queryDriveForJobBuilder(((sked_Drive__c) testData.get('testDrive2')).Id);
        drive.sked_Platelet_Projected_Procedures__c = 20;

        sked_Staffing_Decision_Matrix__c sdm = buildFixedSiteStaffingDecisionMatrix();
        sdm.sked_Platelet_Round_Capacity__c = 2;
        sdm.sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 0;
        sdm.sked_NR_Volunteer_Fixed_Site_Band_Upper__c = 5;
        insert sdm;
        replaceFixedSiteSdmLink(drive.sked_Collection_Operation__c, sdm.Id);

        sked__Tag__c personTag = new sked__Tag__c(Name = 'Person Required Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION, sked_Resource_Type__c = 'Person');
        insert personTag;
        insert new sked__Account_Tag__c(sked__Account__c = drive.sked_Account__c, sked__Tag__c = personTag.Id, sked__Required__c = true);

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift0 = shifts[0];
        Integer apheresisIndex = indexOfRoleJob(shift0.jobs, 'Apheresis');
        Integer volunteerIndex = indexOfVolunteerJob(shift0.jobs);
        System.assert(apheresisIndex >= 0, 'An Apheresis job must exist to check its tags');
        System.assert(volunteerIndex >= 0, 'A volunteer job must exist to check its tags');
        System.assert(containsTagId(shift0.jobTagsByJobIndex.get(apheresisIndex), personTag.Id), 'A role job (Person resource type) must get the Person-required tag');
        System.assert(containsTagId(shift0.jobTagsByJobIndex.get(volunteerIndex), personTag.Id), 'A volunteer job (Person resource type) must get the same Person-required tag');
    }

    @isTest
    static void testAssignFreshJobTags_attachesAssetTypeTagSetToMatchingAssetJob() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);
        drive.sked_Number_of_Vehicles__c = 2;
        drive.sked_Number_of_2RBC_Assets__c = 1;

        sked__Tag__c vehicleTag = new sked__Tag__c(Name = 'Vehicle Required Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION, sked_Resource_Type__c = 'Vehicle');
        sked__Tag__c equipmentTag = new sked__Tag__c(Name = 'Equipment Required Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION, sked_Resource_Type__c = 'Equipment');
        // The cancel->flip->restore dance above already queues this test method's one allowed async
        // batch (a DCR-creation batch on the Operation Type change) - bypass triggers for this insert
        // alone so a second Account Tag-driven batch doesn't push the test over Apex's one-executeBatch-
        // per-test-method limit. We only need these rows queryable by loadJobTagsMap, not their own
        // trigger side effects.
        skedHubBase.setBypassAllTriggers(true);
        insert new List<sked__Tag__c>{ vehicleTag, equipmentTag };
        insert new List<sked__Account_Tag__c>{
            new sked__Account_Tag__c(sked__Account__c = drive.sked_Account__c, sked__Tag__c = vehicleTag.Id, sked__Required__c = true),
            new sked__Account_Tag__c(sked__Account__c = drive.sked_Account__c, sked__Tag__c = equipmentTag.Id, sked__Required__c = true)
        };
        skedHubBase.setBypassAllTriggers(false);

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift0 = shifts[0];
        Integer vehicleIndex = indexOfAssetJob(shift0.jobs, skedConstants.ASSET_TYPE_VEHICLE);
        Integer equipmentIndex = indexOfAssetJob(shift0.jobs, skedConstants.ASSET_TYPE_EQUIPMENT);
        System.assert(vehicleIndex >= 0, 'A Vehicle job must exist to check its tags');
        System.assert(equipmentIndex >= 0, 'An Equipment job must exist to check its tags');
        System.assert(containsTagId(shift0.jobTagsByJobIndex.get(vehicleIndex), vehicleTag.Id), 'The Vehicle job must get the Vehicle-required tag');
        System.assert(containsTagId(shift0.jobTagsByJobIndex.get(equipmentIndex), equipmentTag.Id), 'The Equipment job must get the Equipment-required tag');
        System.assert(!containsTagId(shift0.jobTagsByJobIndex.get(vehicleIndex), equipmentTag.Id), 'The Vehicle job must not pick up the Equipment-only tag');
    }

    @isTest
    static void testBuildProposedDriveShifts_populateShiftTime_computesExactJobAndShiftEnvelope() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = queryDriveForJobBuilder(((sked_Drive__c) testData.get('testDrive2')).Id);
        drive.sked_Platelet_Projected_Procedures__c = 20;
        drive.sked_Number_of_Vehicles__c = 2;

        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        collectionOperation.sked_Breakdown_Time_Threshold__c = 999;
        collectionOperation.sked_Setup_Time_Threshold__c = 999;
        // Zeroes travel/site-logistics time for every non-driving role group, so the before/after-draw-
        // hours durations below are deterministic (lead/setup/breakdown/wrap-up only, no travel-time
        // fallback noise).
        collectionOperation.sked_No_Travel_Time__c = true;
        update collectionOperation;

        sked_Staffing_Decision_Matrix__c sdm = buildFixedSiteStaffingDecisionMatrix();
        sdm.sked_Platelet_Round_Capacity__c = 2;
        sdm.sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 0;
        sdm.sked_NR_Volunteer_Fixed_Site_Band_Upper__c = 5;
        insert sdm;
        replaceFixedSiteSdmLink(drive.sked_Collection_Operation__c, sdm.Id);

        insert new List<sked_Role_Time_Detail__c>{
            buildRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES, 5, 10, 20, 3),
            buildRoleTimeDetail(skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES, 1, 2, 4, 1)
        };

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        sked_Drive_Shift__c shift0 = shifts[0].shiftRecord;
        String timezoneSidId = UserInfo.getTimeZone().getID();
        DateTime drawHoursStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift0.sked_Drive_Date__c, shift0.sked_Start_Time__c, timezoneSidId);
        DateTime drawHoursEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift0.sked_Drive_Date__c, shift0.sked_End_Time__c, timezoneSidId);

        sked__Job__c apheresisJob = findJobByRole(shifts[0].jobs, 'Apheresis');
        System.assertEquals(drawHoursStart.addMinutes(-15), apheresisJob.sked__Start__c,
            'Apheresis (Staff roles: lead 5 + setup 10 = 15) must start exactly 15 minutes before draw hours');
        System.assertEquals(drawHoursEnd.addMinutes(23), apheresisJob.sked__Finish__c,
            'Apheresis (Staff roles: breakdown 20 + wrap-up 3 = 23) must finish exactly 23 minutes after draw hours');

        // Apheresis Charge (Supervisory roles: lead 1 + setup 2 = 3 before, breakdown 4 + wrap-up 1 = 5
        // after) has a narrower envelope than Apheresis - the shift-level min/max must track Apheresis.
        System.assertEquals(apheresisJob.sked__Start__c, shift0.sked_Start__c, 'Shift start must be the earliest job start across the shift\'s jobs (Apheresis, not the narrower Apheresis Charge)');
        System.assertEquals(apheresisJob.sked__Finish__c, shift0.sked_Finish__c, 'Shift finish must be the latest job finish across the shift\'s jobs (Apheresis, not the narrower Apheresis Charge)');

        sked__Job__c volunteerJob = findVolunteerJob(shifts[0].jobs);
        sked__Job__c vehicleJob = findAssetJob(shifts[0].jobs, skedConstants.ASSET_TYPE_VEHICLE, null);
        System.assertNotEquals(null, volunteerJob, 'A volunteer job must exist to check its envelope');
        System.assertNotEquals(null, vehicleJob, 'A vehicle job must exist to check its envelope');
        System.assertEquals(shift0.sked_Start__c, volunteerJob.sked__Start__c, 'A volunteer job must adopt the shift\'s own start, not compute its own from its (non-existent) role time');
        System.assertEquals(shift0.sked_Finish__c, volunteerJob.sked__Finish__c, 'A volunteer job must adopt the shift\'s own finish');
        System.assertEquals(shift0.sked_Start__c, vehicleJob.sked__Start__c, 'An asset job must adopt the shift\'s own start, not compute its own from its (non-existent) role time');
        System.assertEquals(shift0.sked_Finish__c, vehicleJob.sked__Finish__c, 'An asset job must adopt the shift\'s own finish');
    }

    @isTest
    static void testBuildProposedDriveShifts_shiftRecord_carriesAllKnownShiftMetadataFields() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c rawDrive = (sked_Drive__c) testData.get('testDrive2');
        sked__Location__c site = (sked__Location__c) testData.get('testLocation2');
        sked_Drive__c drive = setOperationTypeAndQuery(rawDrive, site, skedConstants.OPERATION_TYPE_INTEGRATED);
        // Same known inputs as skedFixedSiteDriveShiftCalculator_Test's own
        // testCalculateDriveShiftsMetadata_integratedOperationType_splitsAllFourProcedureTypesAcrossTwoShifts
        // - testDrive2's default 07:00-17:00 window splits into shift 0 (07:00-13:00, 2 of 4 rounds)
        // and shift 1 (13:00-17:00).
        drive.sked_2RBC_Projected_Procedures__c = 10;
        drive.sked_WB_Projected_Procedures__c = 20;
        drive.sked_Platelet_Projected_Procedures__c = 9;
        drive.sked_Plasma_Projected_Procedures__c = 6;

        Test.startTest();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> shifts = buildShifts(drive);
        Test.stopTest();

        sked_Drive_Shift__c shift0 = shifts[0].shiftRecord;
        System.assertEquals(drive.sked_Drive_Date__c, shift0.sked_Drive_Date__c, 'Shift date must be carried from shift metadata');
        System.assertEquals(Time.newInstance(7, 0, 0, 0), shift0.sked_Start_Time__c, 'Shift 0 must start at the drive\'s own 07:00 start time');
        System.assertEquals(Time.newInstance(13, 0, 0, 0), shift0.sked_End_Time__c, 'Shift 0 must end at the midpoint of testDrive2\'s default 10-hour, 4-round window (2 rounds = 6 hours)');
        System.assertEquals(2, shift0.sked_Platelet_Rounds__c, 'Shift 0 must carry exactly 2 of the drive\'s 4 total platelet rounds');
        System.assertEquals(6, shift0.sked_2RBC_Projected_Procedures__c, '2RBC is duration-weighted: shift 0 (360 of 600 minutes) gets ceil(10 * 360/600) = 6');
        System.assertEquals(12, shift0.sked_WB_Projected_Procedures__c, 'WB is duration-weighted: shift 0 gets ceil(20 * 360/600) = 12');
        System.assertEquals(5, shift0.sked_Platelet_Projected_Procedures__c, 'Platelet is round-weighted: shift 0 gets ceil(9 * 2/4) = 5');
        System.assertEquals(3, shift0.sked_Plasma_Projected_Procedures__c, 'Plasma is round-weighted: shift 0 gets ceil(6 * 2/4) = 3');
        System.assertEquals(26, shift0.sked_Total_Procedures_Projected__c, 'Total procedures projected must sum all 4 procedure types (6 + 12 + 5 + 3)');
        System.assertEquals(32, shift0.sked_Total_Products_Projected__c, 'Total products projected must double-count 2RBC (2*6 + 12 + 5 + 3)');
    }

    @isTest
    static void testApplyShiftSetupRollups_sumsQuantitiesAcrossJobTypes() {
        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 3));
        shift.jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Apheresis Charge', sked__Quantity__c = 1));
        shift.jobs.add(new sked__Job__c(sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE, sked__Quantity__c = 2));
        shift.jobs.add(new sked__Job__c(sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT, sked_Equipment_Subtype__c = '2RBC Asset', sked__Quantity__c = 1));
        shift.jobs.add(new sked__Job__c(sked_Volunteer_Role__c = skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR, sked__Quantity__c = 2));

        Test.startTest();
        skedFixedSiteDriveJobBuilder.applyShiftSetupRollups(new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift }, new Set<String>());
        Test.stopTest();

        System.assertEquals(4, shift.shiftRecord.sked_Staff_Setup__c, 'Staff setup must sum both role jobs\' quantities');
        System.assertEquals(0, shift.shiftRecord.sked_APT_Setup__c, 'Fixed Site has no APT concept - APT setup must always be zeroed, matching baseGenerator.js');
        System.assertEquals(2, shift.shiftRecord.sked_Vehicles_Needed__c, 'Vehicles needed must equal the Vehicle job\'s quantity');
        System.assertEquals(1, shift.shiftRecord.sked_Equipment__c, 'Equipment must equal the Equipment job\'s quantity');
        System.assertEquals(2, shift.shiftRecord.sked_Volunteer_Setup__c, 'Volunteer setup must equal the volunteer job\'s quantity');
    }

    @isTest
    static void testApplyShiftSetupRollups_excludesConfiguredRoleNamesFromStaffSetup() {
        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 3));
        shift.jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Apheresis Charge', sked__Quantity__c = 1));

        Test.startTest();
        skedFixedSiteDriveJobBuilder.applyShiftSetupRollups(
            new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift }, new Set<String>{ 'Apheresis Charge' });
        Test.stopTest();

        System.assertEquals(3, shift.shiftRecord.sked_Staff_Setup__c,
            'A role name in staffSetupExcludedRoleNames must be omitted from the sum, leaving only the non-excluded role\'s quantity');
    }

    @isTest
    static void testApplyShiftSetupRollups_skipsManuallyCreatedFromStaffingModalJob() {
        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 3));
        shift.jobs.add(new sked__Job__c(
            sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 99, sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Staffing Modal'
        ));

        Test.startTest();
        skedFixedSiteDriveJobBuilder.applyShiftSetupRollups(new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift }, new Set<String>());
        Test.stopTest();

        System.assertEquals(3, shift.shiftRecord.sked_Staff_Setup__c, 'A job manually created from the Staffing Modal must be excluded from the rollup sum');
    }

    // ===== Existing-record carry-forward =====

    private static List<sked_Drive_Shift__c> queryShiftsWithJobs(Id driveShiftId) {
        return [
            SELECT Id, (SELECT Id, sked_Resource_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c,
                    sked_Equipment_Subtype__c, sked_Volunteer_Role__c, sked__Quantity__c, sked_Manually_Created_From__c,
                    sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c
                FROM sked_Jobs__r)
            FROM sked_Drive_Shift__c
            WHERE Id = :driveShiftId
        ];
    }

    @isTest
    static void testApplyExistingRecordIds_stampsShiftIdAndMatchesRoleJobByResourceRoleAlone() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c existingJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Apheresis',
            sked__Quantity__c = 3, sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingJob;
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 3));
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(existingShift.Id, shift.shiftRecord.Id, 'The proposed shift record must be stamped with the existing shift\'s Id');
        System.assertEquals(existingJob.Id, shift.jobs[0].Id, 'A role job matched by sked_Resource_Role__c alone must be stamped with the existing job\'s Id');
    }

    @isTest
    static void testApplyExistingRecordIds_doesNotMatchManuallyCreatedExistingJob() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c existingManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Apheresis',
            sked__Quantity__c = 1, sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingManualJob;
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 3));
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(null, shift.jobs[0].Id, 'findMatchingExistingJob must skip a manually-created existing job, leaving the fresh role job unmatched');
    }

    @isTest
    static void testPreserveManuallyCreatedJobs_zeroQuantityManualJob_stillCarriedForward_unlikeMobile() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        // 'Charge' is outside FIXED_SITE_SYSTEM_ROLES ({'Apheresis Charge','Apheresis'}), so
        // isManuallyCreatedJob treats it as manual purely by role, with no explicit flag needed.
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c existingManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Charge',
            sked__Quantity__c = 0, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingManualJob;
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(1, shift.jobs.size(), 'A zero-quantity manually-created job must still be carried forward, unlike Mobile\'s positive-quantity gate');
        System.assertEquals(existingManualJob.Id, shift.jobs[0].Id, 'The carried-forward job must retain the existing job\'s Id');
        System.assertEquals(0, shift.jobs[0].sked__Quantity__c, 'The carried-forward job must keep its zero quantity, not be dropped or defaulted');
    }

    @isTest
    static void testPreserveManuallyCreatedJobs_systemRoleWithExplicitManualFlag_stillTreatedAsManual() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        // 'Apheresis' IS in FIXED_SITE_SYSTEM_ROLES - only the explicit flag makes this one manual.
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c existingManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Apheresis',
            sked__Quantity__c = 5, sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingManualJob;
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(1, shift.jobs.size(), 'The explicit sked_Is_Manually_Created__c flag must win over a system-role role name, carrying the job forward');
        System.assertEquals(existingManualJob.Id, shift.jobs[0].Id, 'The carried-forward job must retain the existing job\'s Id');
    }

    @isTest
    static void testMergeForwardJobTags_mergesSystemCreatedTag_excludesPhysicalLocationAndNonSystemCreatedTags() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c existingJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Apheresis',
            sked__Quantity__c = 3, sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingJob;

        sked__Tag__c systemCreatedTag = new sked__Tag__c(Name = 'Merge Forward Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION, sked_Resource_Type__c = 'Person');
        sked__Tag__c physicalLocationTag = new sked__Tag__c(Name = 'Physical Location Tag', sked__Type__c = skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE, sked_Resource_Type__c = 'Person');
        sked__Tag__c nonSystemCreatedTag = new sked__Tag__c(Name = 'Non System Created Tag', sked__Type__c = skedConstants.TAG_TYPE_CERTIFICATION, sked_Resource_Type__c = 'Person');
        insert new List<sked__Tag__c>{ systemCreatedTag, physicalLocationTag, nonSystemCreatedTag };
        insert new List<sked__Job_Tag__c>{
            new sked__Job_Tag__c(sked__Job__c = existingJob.Id, sked__Tag__c = systemCreatedTag.Id, sked_SystemCreated__c = true),
            new sked__Job_Tag__c(sked__Job__c = existingJob.Id, sked__Tag__c = physicalLocationTag.Id, sked_SystemCreated__c = true),
            new sked__Job_Tag__c(sked__Job__c = existingJob.Id, sked__Tag__c = nonSystemCreatedTag.Id, sked_SystemCreated__c = false)
        };
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 3));
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(existingJob.Id, shift.jobs[0].Id, 'Setup check: the role job must be matched and Id-stamped before tags can be merged forward');
        List<sked__Job_Tag__c> mergedTags = shift.jobTagsByJobIndex.get(0);
        System.assert(containsTagId(mergedTags, systemCreatedTag.Id), 'A systemCreated, non-Physical-Location-Type tag must be merged forward');
        System.assert(!containsTagId(mergedTags, physicalLocationTag.Id), 'A Physical Location Type tag must never be carried forward, even if systemCreated');
        System.assert(!containsTagId(mergedTags, nonSystemCreatedTag.Id), 'A non-systemCreated tag must not be carried forward');
    }

    // Exercises the real production call order (preserveManuallyCreatedJobsForAllShifts, THEN
    // applyExistingRecordIds) - a test that only calls one step can't catch applyExistingRecordIds
    // re-matching an already-Id-stamped manually-preserved job against the system job of the same
    // role and overwriting its Id, which would leave two jobs sharing one Id. Mirrors
    // skedMobileDriveJobBuilder_Test.testApplyExistingRecordIds_afterManualJobAlreadyPreserved_doesNotOverwriteItsId.
    @isTest
    static void testApplyExistingRecordIds_afterManualJobAlreadyPreserved_doesNotOverwriteItsId() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c existingSystemJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Apheresis',
            sked__Quantity__c = 3, sked_Is_Manually_Created__c = false, sked__Region__c = regionId, sked__Duration__c = 60
        );
        sked__Job__c existingManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Apheresis',
            sked__Quantity__c = 1, sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert new List<sked__Job__c>{ existingSystemJob, existingManualJob };
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Apheresis', sked__Quantity__c = 3));
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);
        skedFixedSiteDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        Set<Id> apheresisJobIds = new Set<Id>();
        for (sked__Job__c job : shift.jobs) {
            if (job.sked_Resource_Role__c == 'Apheresis') {
                apheresisJobIds.add(job.Id);
            }
        }
        System.assertEquals(2, apheresisJobIds.size(),
            'The system job and the manually-created duplicate must retain two DISTINCT Ids after applyExistingRecordIds runs - a collision means one got silently overwritten');
        System.assert(apheresisJobIds.contains(existingSystemJob.Id), 'The fresh role job must carry the persisted system job\'s Id');
        System.assert(apheresisJobIds.contains(existingManualJob.Id), 'The preserved manually-created job must still carry its OWN persisted Id, not the system job\'s');
    }

    // Regression test for a real bug: preserveManuallyCreatedJobs appends each preserved job directly
    // onto the live shift.jobs list it's iterating candidates against. Before the fix, the SECOND
    // manual candidate's probe (findMatchingProposedJobForManualCandidate) saw the FIRST candidate's
    // own just-appended preserved job, matched on sked_Manually_Created_From__c alone (no identity
    // check), and silently dropped the second candidate. Two distinct roles sharing one
    // sked_Manually_Created_From__c value (a common real case - e.g. both added via the same Drive
    // Scheduling UI session) must both survive with their own distinct, correct Ids.
    @isTest
    static void testPreserveManuallyCreatedJobs_twoManualJobsSharingManuallyCreatedFrom_bothPreservedWithDistinctIds() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c firstManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Charge',
            sked__Quantity__c = 1, sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Drive Scheduling',
            sked__Region__c = regionId, sked__Duration__c = 60
        );
        sked__Job__c secondManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Driver',
            sked__Quantity__c = 2, sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Drive Scheduling',
            sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert new List<sked__Job__c>{ firstManualJob, secondManualJob };
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(2, shift.jobs.size(), 'Both manual candidates sharing sked_Manually_Created_From__c must be preserved, not just the first');
        Set<Id> preservedIds = new Set<Id>();
        for (sked__Job__c job : shift.jobs) {
            preservedIds.add(job.Id);
        }
        System.assert(preservedIds.contains(firstManualJob.Id), 'The first manual job must be preserved with its own Id');
        System.assert(preservedIds.contains(secondManualJob.Id), 'The second manual job (distinct role, same manuallyCreatedFrom) must ALSO be preserved with its own Id, not dropped as a false match on the first');
    }

    // Isolates the snapshot fix from the job-identity-check fix: two manual candidates with the SAME
    // role AND the same sked_Manually_Created_From__c. The identity check alone can't save this case -
    // same role means the two candidates ARE identity-equal to each other, so without the
    // freshProposedJobs snapshot the live-list probe would still (correctly, per its own logic) match
    // the second candidate against the first's just-appended preserved job and drop it. Only probing
    // the pre-loop snapshot (which has neither preserved job in it yet) keeps both - matching
    // fixedSiteGenerator.js:1352-1356's own concat, which has no de-duplication at all.
    @isTest
    static void testPreserveManuallyCreatedJobs_twoManualJobsSameRoleAndManuallyCreatedFrom_bothPreserved() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c firstManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Charge',
            sked__Quantity__c = 1, sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Drive Scheduling',
            sked__Region__c = regionId, sked__Duration__c = 60
        );
        sked__Job__c secondManualJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Resource_Role__c = 'Charge',
            sked__Quantity__c = 1, sked_Is_Manually_Created__c = true, sked_Manually_Created_From__c = 'Drive Scheduling',
            sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert new List<sked__Job__c>{ firstManualJob, secondManualJob };
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(2, shift.jobs.size(), 'Two manual candidates that are identity-equal (same role) AND share manuallyCreatedFrom must still both be preserved, matching the JS concat\'s own no-dedupe behavior');
        Set<Id> preservedIds = new Set<Id>();
        for (sked__Job__c job : shift.jobs) {
            preservedIds.add(job.Id);
        }
        System.assert(preservedIds.contains(firstManualJob.Id), 'The first manual job must be preserved with its own Id');
        System.assert(preservedIds.contains(secondManualJob.Id), 'The second manual job must ALSO be preserved with its own Id - only the pre-loop snapshot (not the identity check alone) prevents it from being dropped here');
    }

    @isTest
    static void testPreserveManuallyCreatedJobs_nonDonorAmbassadorVolunteerRole_treatedAsManualAndCarriedForward() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        // Only 'Donor Ambassador' is system-generated on Fixed Site - any other volunteer role (here,
        // the Medical Screener constant) is eligible for manual preservation like a role job would be.
        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c existingVolunteerJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Volunteer_Role__c = skedConstants.JOB_VOLUNTEER_ROLE_MEDICAL_SCREENER,
            sked__Quantity__c = 1, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingVolunteerJob;
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(1, shift.jobs.size(), 'A non-Donor-Ambassador volunteer role must be treated as manual and carried forward, unlike Mobile\'s "every volunteer job is system" pattern');
        System.assertEquals(existingVolunteerJob.Id, shift.jobs[0].Id, 'The carried-forward volunteer job must retain the existing job\'s Id');
    }

    @isTest
    static void testApplyExistingRecordIds_doesNotMatchManuallyCreatedExistingAssetJob() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive2');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c existingShift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert existingShift;
        sked__Job__c existingManualVehicleJob = new sked__Job__c(
            sked_Drive_Shift__c = existingShift.Id, sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE,
            sked__Quantity__c = 1, sked_Is_Manually_Created__c = true, sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert existingManualVehicleJob;
        List<sked_Drive_Shift__c> existingShifts = queryShiftsWithJobs(existingShift.Id);

        skedFixedSiteDriveJobBuilder.ProposedDriveShift shift = new skedFixedSiteDriveJobBuilder.ProposedDriveShift();
        shift.shiftRecord = new sked_Drive_Shift__c();
        shift.jobs.add(new sked__Job__c(sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE, sked__Quantity__c = 3));
        List<skedFixedSiteDriveJobBuilder.ProposedDriveShift> proposed = new List<skedFixedSiteDriveJobBuilder.ProposedDriveShift>{ shift };

        Test.startTest();
        skedFixedSiteDriveJobBuilder.applyExistingRecordIds(proposed, existingShifts);
        Test.stopTest();

        System.assertEquals(null, shift.jobs[0].Id,
            'findMatchingExistingJob\'s asset branch must skip a manually-created existing Vehicle job, leaving the fresh asset job unmatched - otherwise both the preserved manual job and the fresh job would end up sharing the same Id');
    }
}
