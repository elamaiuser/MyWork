@isTest
private class skedFixedSiteWbDriveJobBuilder_Test {

    private static final String SHIFT_KEY_1 = 'wb-shift-1';
    private static final String SHIFT_KEY_2 = 'wb-shift-2';

    // Shift metadata and role/volunteer quantities are hand-built rather than driven through the
    // (separately built) WB shift/role/volunteer calculators, so every assertion below pins job shape
    // alone and stays independent of those classes' own arithmetic. sked_Operation_Type__c is a
    // non-writable formula field, and this builder never reads it - the WB routing happens upstream.
    private static sked_Drive__c buildDrive() {
        return new sked_Drive__c(
            sked_Drive_Date__c = Date.today(),
            sked_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(16, 0, 0, 0),
            sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_FIXED_SITE
        );
    }

    private static skedMobileDriveShiftCalculator.DriveShiftMetadata buildShiftMetadata(String key) {
        skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata = new skedMobileDriveShiftCalculator.DriveShiftMetadata();
        shiftMetadata.key = key;
        shiftMetadata.driveDate = Date.today();
        shiftMetadata.startTime = Time.newInstance(8, 0, 0, 0);
        shiftMetadata.endTime = Time.newInstance(16, 0, 0, 0);
        shiftMetadata.donorsScheduled = 40;
        shiftMetadata.lunchBreakSettings = new skedLunchBreakSettings();
        shiftMetadata.resourceRoleGroupRoleTimeDataMap = new Map<String, skedMobileDriveShiftCalculator.RoleTimeData>();
        return shiftMetadata;
    }

    private static skedMobileDriveShiftCalculator.DriveShiftsMetadata buildShiftsMetadata(List<String> shiftKeys) {
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = new skedMobileDriveShiftCalculator.DriveShiftsMetadata();
        for (String shiftKey : shiftKeys) {
            shiftsMetadata.driveShifts.add(buildShiftMetadata(shiftKey));
        }
        shiftsMetadata.numberOfDriveShifts = shiftKeys.size();
        return shiftsMetadata;
    }

    private static skedMobileRoleQuantityCalculator.RoleQuantity roleQuantity(Decimal quantity) {
        skedMobileRoleQuantityCalculator.RoleQuantity result = new skedMobileRoleQuantityCalculator.RoleQuantity();
        result.quantity = quantity;
        return result;
    }

    private static skedMobileRoleQuantityCalculator.RoleQuantity vphhRoleQuantity(Decimal vphhQuantity, Decimal aptQuantity) {
        skedMobileRoleQuantityCalculator.RoleQuantity result = new skedMobileRoleQuantityCalculator.RoleQuantity();
        result.vphhQuantity = vphhQuantity;
        result.aptQuantity = aptQuantity;
        result.quantity = vphhQuantity + aptQuantity;
        return result;
    }

    private static Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> singleRoleOnEveryShift(
            List<String> shiftKeys, String role, skedMobileRoleQuantityCalculator.RoleQuantity quantity) {
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey =
            new Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>>();
        for (String shiftKey : shiftKeys) {
            roleQuantityByShiftKey.put(shiftKey, new Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>{ role => quantity });
        }
        return roleQuantityByShiftKey;
    }

    private static List<skedMobileDriveJobBuilder.ProposedDriveShift> build(sked_Drive__c drive,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey,
            Map<String, Integer> volunteerQuantityByShiftKey, Decimal numberOfEquipments) {
        return skedFixedSiteWbDriveJobBuilder.buildProposedDriveShifts(drive, shiftsMetadata, roleQuantityByShiftKey,
            volunteerQuantityByShiftKey, numberOfEquipments, 'America/New_York', new List<sked_Lunch_Break_Setting__c>(),
            new Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>>(), new List<Collection_Operation_Time_Block__c>());
    }

    private static sked__Job__c findJobByRole(skedMobileDriveJobBuilder.ProposedDriveShift shift, String role) {
        for (sked__Job__c job : shift.jobs) {
            if (job.sked_Resource_Role__c == role) {
                return job;
            }
        }
        return null;
    }

    private static sked__Job__c findEquipmentJob(skedMobileDriveJobBuilder.ProposedDriveShift shift) {
        for (sked__Job__c job : shift.jobs) {
            if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                return job;
            }
        }
        return null;
    }

    private static Integer findEquipmentJobIndex(skedMobileDriveJobBuilder.ProposedDriveShift shift) {
        for (Integer i = 0; i < shift.jobs.size(); i++) {
            if (shift.jobs[i].sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                return i;
            }
        }
        return null;
    }

    private static Integer findJobIndexByRole(skedMobileDriveJobBuilder.ProposedDriveShift shift, String role) {
        for (Integer i = 0; i < shift.jobs.size(); i++) {
            if (shift.jobs[i].sked_Resource_Role__c == role) {
                return i;
            }
        }
        return null;
    }

    private static sked__Job__c findVolunteerJob(skedMobileDriveJobBuilder.ProposedDriveShift shift) {
        for (sked__Job__c job : shift.jobs) {
            if (job.sked_Volunteer_Role__c == skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR) {
                return job;
            }
        }
        return null;
    }

    private static sked__Tag__c insertFixedSiteTag() {
        sked__Tag__c fixedSiteTag = new sked__Tag__c(Name = skedConstants.TAG_FIXED_SITE, sked__Type__c = skedConstants.TAG_TYPE_DRIVE_TYPE);
        insert fixedSiteTag;
        return fixedSiteTag;
    }

    // ===== No vehicle job, ever (wb:1536-1552 has no `assetType === VEHICLE ||` escape hatch) =====

    @isTest
    static void testBuildProposedDriveShifts_noVehicleAssetJobIsEverBuilt() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1, SHIFT_KEY_2 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)),
            new Map<String, Integer>{ SHIFT_KEY_1 => 3, SHIFT_KEY_2 => 3 }, 4);
        Test.stopTest();

        Integer vehicleJobs = 0;
        for (skedMobileDriveJobBuilder.ProposedDriveShift shift : shifts) {
            for (sked__Job__c job : shift.jobs) {
                if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                    vehicleJobs++;
                }
            }
        }
        System.assertEquals(0, vehicleJobs, 'A WB Fixed Site drive must never produce a Vehicle asset job, unlike Mobile which emits one even at zero quantity');
    }

    @isTest
    static void testBuildProposedDriveShifts_equipmentJobCarries2rbcSubtypeAndQuantity() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)),
            new Map<String, Integer>(), 4);
        Test.stopTest();

        sked__Job__c equipmentJob = findEquipmentJob(shifts[0]);
        System.assertNotEquals(null, equipmentJob, 'A positive equipment quantity must produce one Equipment asset job');
        System.assertEquals('2RBC Asset', equipmentJob.sked_Equipment_Subtype__c, 'The equipment job must carry the 2RBC Asset subtype (wb:1545)');
        System.assertEquals(4, equipmentJob.sked__Quantity__c, 'The equipment job quantity must be the passed-in equipment count');
    }

    @isTest
    static void testBuildProposedDriveShifts_equipmentJobOmittedFromLaterShifts() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1, SHIFT_KEY_2 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)),
            new Map<String, Integer>(), 4);
        Test.stopTest();

        System.assertEquals(null, findEquipmentJob(shifts[1]), 'Only the first shift may carry an asset job - wb:1390-1394 drops every non-role, non-volunteer job from later shifts');
    }

    @isTest
    static void testBuildProposedDriveShifts_equipmentJobHasNoSystemQuantity() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)),
            new Map<String, Integer>(), 4);
        Test.stopTest();

        System.assertEquals(null, findEquipmentJob(shifts[0]).sked_System_Quantity__c,
            'WB\'s asset loop never sets systemQuantity (wb:1549-1550), unlike Mobile\'s which does');
    }

    // ===== Plain resourceRole keying, no dual roles (wb:1484-1491) =====

    @isTest
    static void testBuildProposedDriveShifts_noJobCarriesADualRole() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantities =
            new Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>>{
                SHIFT_KEY_1 => new Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>{
                    '2RBC' => roleQuantity(2), 'Charge' => roleQuantity(1), 'VP/HH' => vphhRoleQuantity(1, 0)
                }
            };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), roleQuantities, new Map<String, Integer>{ SHIFT_KEY_1 => 2 }, 4);
        Test.stopTest();

        for (sked__Job__c job : shifts[0].jobs) {
            System.assertEquals(null, job.sked_Dual_Role__c,
                'No WB job may carry a dual role - wb:1491 assigns resourceRole only and never writes job.dualRole (' + job.sked_Resource_Role__c + ')');
        }
    }

    // A hyphen in the map key is the only way to tell WB's plain-resourceRole keying apart from
    // Mobile's composite "role-dualRole" key parsing, which would split this into role + dual role.
    @isTest
    static void testBuildProposedDriveShifts_hyphenatedRoleKeyIsUsedVerbatimAsTheResourceRole() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, 'Team-Supervisor', roleQuantity(1)),
            new Map<String, Integer>(), 0);
        Test.stopTest();

        System.assertNotEquals(null, findJobByRole(shifts[0], 'Team-Supervisor'),
            'The quantity-map key must be used verbatim as the resourceRole - WB never parses it as a composite role-dualRole job key');
    }

    // ===== The extra 'Fixed Site' equipment job tag (wb:1547) =====

    @isTest
    static void testBuildProposedDriveShifts_equipmentJobCarriesSystemCreatedFixedSiteJobTag() {
        sked__Tag__c fixedSiteTag = insertFixedSiteTag();
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)),
            new Map<String, Integer>(), 4);
        Test.stopTest();

        List<sked__Job_Tag__c> jobTags = shifts[0].jobTagsByJobIndex.get(findEquipmentJobIndex(shifts[0]));
        System.assertEquals(1, jobTags.size(), 'The equipment job must carry exactly the extra Fixed Site tag (no required Account/Location tags seeded here)');
        System.assertEquals(fixedSiteTag.Id, jobTags[0].sked__Tag__c, 'The extra tag must be the Fixed Site Drive Type tag');
        System.assertEquals(true, jobTags[0].sked_SystemCreated__c, 'The extra Fixed Site tag is systemCreated (wb:1547)');
        System.assertEquals(false, jobTags[0].sked__Required__c, 'The extra Fixed Site tag is not required - the source tag object has no required property');
    }

    @isTest
    static void testBuildProposedDriveShifts_roleJobDoesNotCarryFixedSiteJobTag() {
        insertFixedSiteTag();
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)),
            new Map<String, Integer>(), 4);
        Test.stopTest();

        System.assertEquals(null, shifts[0].jobTagsByJobIndex.get(findJobIndexByRole(shifts[0], '2RBC')),
            'The extra Fixed Site tag belongs to the equipment job only - a role job must not receive it');
    }

    // ===== Per-shift volunteer quantities (wb:1516) =====

    @isTest
    static void testBuildProposedDriveShifts_volunteerQuantityComesFromThePerShiftMap() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1, SHIFT_KEY_2 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)),
            new Map<String, Integer>{ SHIFT_KEY_1 => 3, SHIFT_KEY_2 => 7 }, 0);
        Test.stopTest();

        System.assertEquals(3, findVolunteerJob(shifts[0]).sked_Redcross_Volunteer_Quantity__c,
            'The first shift\'s volunteer quantity must come from its own shift key\'s entry, not a drive-level value');
        System.assertEquals(7, findVolunteerJob(shifts[1]).sked_Redcross_Volunteer_Quantity__c,
            'The second shift must get its OWN, different quantity - Mobile\'s volunteer map is flat and drive-level, WB\'s is per shift');
    }

    // Mobile (mob:2097) and Fixed Site (fs:1306) both read the ORIGINAL shift's volunteer job and keep
    // its sponsor quantity; WB looks in the freshly built proposed shift (wb:1518), which is always
    // empty, so sponsor quantity is always 0 and systemQuantity is never written. Ported as observed.
    @isTest
    static void testBuildProposedDriveShifts_volunteerJobHasZeroSponsorQuantityAndNoSystemQuantity() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)),
            new Map<String, Integer>{ SHIFT_KEY_1 => 5 }, 0);
        Test.stopTest();

        sked__Job__c volunteerJob = findVolunteerJob(shifts[0]);
        System.assertEquals(0, volunteerJob.sked_Sponsor_Volunteer_Quantity__c, 'WB never carries a sponsor volunteer quantity forward');
        System.assertEquals(5, volunteerJob.sked__Quantity__c, 'Total quantity is the redcross quantity plus a sponsor quantity of 0');
        System.assertEquals(null, volunteerJob.sked_System_Quantity__c, 'WB\'s volunteer branch never sets systemQuantity (wb:1526-1530), unlike Mobile\'s');
    }

    @isTest
    static void testBuildProposedDriveShifts_zeroVolunteerQuantityEmitsNoVolunteerJob() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)),
            new Map<String, Integer>{ SHIFT_KEY_1 => 0 }, 0);
        Test.stopTest();

        System.assertEquals(null, findVolunteerJob(shifts[0]), 'A zero volunteer quantity must emit no volunteer job at all, matching wb:1531\'s quantity > 0 gate');
    }

    // ===== VP/HH's two-component quantity (wb:1493-1503) =====

    @isTest
    static void testBuildProposedDriveShifts_vphhJobQuantityIsVphhPlusApt() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, 'VP/HH', vphhRoleQuantity(2, 1)),
            new Map<String, Integer>(), 0);
        Test.stopTest();

        sked__Job__c vphhJob = findJobByRole(shifts[0], 'VP/HH');
        System.assertEquals(2, vphhJob.sked_VPHH_Quantity__c, 'The VP/HH component must be kept separately on the job');
        System.assertEquals(1, vphhJob.sked_APT_Quantity__c, 'The APT component must be kept separately on the job');
        System.assertEquals(3, vphhJob.sked__Quantity__c, 'Total quantity must be vphhQuantity + aptQuantity');
        System.assertEquals(3, vphhJob.sked_System_Quantity__c, 'A role job\'s systemQuantity defaults to its own quantity');
    }

    @isTest
    static void testBuildProposedDriveShifts_vphhJobEmittedWhenOnlyAptQuantityIsPositive() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, 'VP/HH', vphhRoleQuantity(0, 1)),
            new Map<String, Integer>(), 0);
        Test.stopTest();

        System.assertEquals(1, findJobByRole(shifts[0], 'VP/HH').sked__Quantity__c,
            'VP/HH must still be emitted when only its APT component is positive (wb:1495), with quantity equal to that component');
    }

    @isTest
    static void testBuildProposedDriveShifts_zeroQuantityRoleEmitsNoJob() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys), singleRoleOnEveryShift(shiftKeys, 'Charge', roleQuantity(0)),
            new Map<String, Integer>(), 0);
        Test.stopTest();

        System.assertEquals(null, findJobByRole(shifts[0], 'Charge'), 'A zero-quantity role must emit no job at all (wb:1506)');
    }

    // ===== No APT at shift level (wb:1365-1379 drops APTSetup) =====

    @isTest
    static void testBuildProposedDriveShifts_shiftRecordCarriesNoAptSetup() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(shiftKeys);
        shiftsMetadata.aptSetup = 7;
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = build(buildDrive(), shiftsMetadata, singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)), new Map<String, Integer>(), 0);
        Test.stopTest();

        System.assertEquals(null, shifts[0].shiftRecord.sked_APT_Setup__c,
            'WB drops APTSetup from the proposed shift entirely, even when the metadata carries one');
    }

    // ===== WB's own lunch-break staff-setup role list (wb:1677, wb:1837) =====

    // Two duration buckets 1-3 and 4-10 staff, so a role list that counts Driver's headcount lands in
    // a different bucket than one that doesn't - without that split the role list looks inert.
    private static List<sked_Lunch_Break_Setting__c> insertLunchBreakConfig() {
        sked_Lunch_Break_Setting__c setting = new sked_Lunch_Break_Setting__c(sked_Maximum_Lunch_Break_Duration__c = '30');
        insert setting;
        insert new List<sked_Lunch_Break_Definition__c>{
            new sked_Lunch_Break_Definition__c(sked_Lunch_Break_Setting__c = setting.Id, sked_Min_Number_of_Staff__c = 1,
                sked_Max_Number_of_Staff__c = 3, sked_Lunch_Break_Duration__c = 15, sked_Slot_Reduction__c = 0),
            new sked_Lunch_Break_Definition__c(sked_Lunch_Break_Setting__c = setting.Id, sked_Min_Number_of_Staff__c = 4,
                sked_Max_Number_of_Staff__c = 10, sked_Lunch_Break_Duration__c = 45, sked_Slot_Reduction__c = 0)
        };
        return skedLunchBreakCalculator.loadLunchBreakSettings();
    }

    private static skedMobileDriveShiftCalculator.DriveShiftsMetadata buildLunchBreakShiftsMetadata() {
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildShiftsMetadata(new List<String>{ SHIFT_KEY_1 });
        skedLunchBreakSettings lunchBreakSettings = new skedLunchBreakSettings();
        lunchBreakSettings.lunchBreak = true;
        lunchBreakSettings.lunchBreakBeforeDrawHours = false;
        lunchBreakSettings.maximumLunchBreakDuration = 30;
        shiftsMetadata.driveShifts[0].lunchBreakSettings = lunchBreakSettings;
        return shiftsMetadata;
    }

    // 2RBC 3 (counted by both lists) plus a legacy Driver job of 2 (counted only by Mobile's list).
    private static Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> buildLunchBreakRoleQuantities() {
        return new Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>>{
            SHIFT_KEY_1 => new Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>{
                '2RBC' => roleQuantity(3), 'Driver' => roleQuantity(2)
            }
        };
    }

    @isTest
    static void testBuildProposedDriveShifts_lunchBreakDurationExcludesDriverHeadcount() {
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = insertLunchBreakConfig();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = skedFixedSiteWbDriveJobBuilder.buildProposedDriveShifts(buildDrive(), buildLunchBreakShiftsMetadata(),
            buildLunchBreakRoleQuantities(), new Map<String, Integer>(), 0, 'America/New_York', lunchBreakSettingsConfig,
            new Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>>(), new List<Collection_Operation_Time_Block__c>());
        Test.stopTest();

        System.assertEquals(15, shifts[0].shiftRecord.sked_Lunch_Break_Duration__c,
            'WB counts only 2RBC/VP/HH/Charge, so 3 staff lands in the 1-3 bucket (15 minutes) even with a Driver job of 2 present');
    }

    // Proves the fixture above discriminates: the same jobs through Mobile's role list count the Driver
    // headcount too, reaching 5 staff and the second bucket.
    @isTest
    static void testBuildProposedDriveShifts_mobileRoleListWouldCountDriverAndPickTheLongerBreak() {
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = insertLunchBreakConfig();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts;

        Test.startTest();
        shifts = skedMobileDriveJobBuilder.buildProposedDriveShifts(buildDrive(), buildLunchBreakShiftsMetadata(),
            buildLunchBreakRoleQuantities(), 0, 0, 'America/New_York', lunchBreakSettingsConfig,
            new Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>>(), new List<Collection_Operation_Time_Block__c>(), 0);
        Test.stopTest();

        System.assertEquals(45, shifts[0].shiftRecord.sked_Lunch_Break_Duration__c,
            'Mobile\'s role list counts the Driver job, so the same fixture reaches 5 staff and the 4-10 bucket (45 minutes)');
    }

    @isTest
    static void testRecalculateLunchBreakForAllShifts_ignoresAPreservedDriverJobsHeadcount() {
        List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig = insertLunchBreakConfig();
        skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata = buildLunchBreakShiftsMetadata();
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = skedFixedSiteWbDriveJobBuilder.buildProposedDriveShifts(
            buildDrive(), shiftsMetadata, singleRoleOnEveryShift(new List<String>{ SHIFT_KEY_1 }, '2RBC', roleQuantity(3)),
            new Map<String, Integer>(), 0, 'America/New_York', lunchBreakSettingsConfig,
            new Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>>(), new List<Collection_Operation_Time_Block__c>());
        shifts[0].jobs.add(new sked__Job__c(sked_Resource_Role__c = 'Driver', sked__Quantity__c = 2, sked_Is_Manually_Created__c = true));

        Test.startTest();
        skedFixedSiteWbDriveJobBuilder.recalculateLunchBreakForAllShifts(shifts, shiftsMetadata, lunchBreakSettingsConfig,
            'America/New_York', false, null);
        Test.stopTest();

        System.assertEquals(15, shifts[0].shiftRecord.sked_Lunch_Break_Duration__c,
            'The post-manual-job-merge recompute must still use WB\'s role list, leaving a preserved Driver job out of the staff count');
    }

    // ===== Manually-created-job preservation with WB's own system-role set =====

    // sked_Jobs__r can't be assigned in memory, and inserting real Job records needs a Region/Drive
    // fixture chain this suite deliberately avoids - deserialization gives the same read-only shape.
    private static List<sked_Drive_Shift__c> existingShiftWithJob(String resourceRole, Decimal quantity) {
        String jobJson = '{"attributes":{"type":"sked__Job__c"},"sked_Resource_Role__c":"' + resourceRole
            + '","sked__Quantity__c":' + quantity + ',"sked_Is_Manually_Created__c":false}';
        String shiftJson = '{"attributes":{"type":"sked_Drive_Shift__c"},"sked_Jobs__r":{"totalSize":1,"done":true,"records":['
            + jobJson + ']}}';
        return new List<sked_Drive_Shift__c>{ (sked_Drive_Shift__c) JSON.deserialize(shiftJson, sked_Drive_Shift__c.class) };
    }

    @isTest
    static void testPreserveManuallyCreatedJobsForAllShifts_legacyDriverJobIsPreserved() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys),
            singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)), new Map<String, Integer>(), 0);

        Test.startTest();
        skedFixedSiteWbDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(shifts, existingShiftWithJob('Driver', 1));
        Test.stopTest();

        System.assertNotEquals(null, findJobByRole(shifts[0], 'Driver'),
            'Driver is not a WB system role (helper.js:3553), so an existing Driver job counts as manually created and must survive the regen');
    }

    @isTest
    static void testPreserveManuallyCreatedJobsForAllShifts_zeroQuantityManualJobIsPreserved() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys),
            singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)), new Map<String, Integer>(), 0);

        Test.startTest();
        skedFixedSiteWbDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(shifts, existingShiftWithJob('Phlebotomist', 0));
        Test.stopTest();

        System.assertNotEquals(null, findJobByRole(shifts[0], 'Phlebotomist'),
            'WB concatenates its manual jobs unfiltered (wb:1568), so a zero-quantity manual job must survive - Mobile\'s own quantity > 0 filter must not apply here');
    }

    @isTest
    static void testPreserveManuallyCreatedJobsForAllShifts_wbSystemRoleJobIsNotDuplicated() {
        List<String> shiftKeys = new List<String>{ SHIFT_KEY_1 };
        List<skedMobileDriveJobBuilder.ProposedDriveShift> shifts = build(buildDrive(), buildShiftsMetadata(shiftKeys),
            singleRoleOnEveryShift(shiftKeys, '2RBC', roleQuantity(2)), new Map<String, Integer>(), 0);
        Integer jobCountBefore = shifts[0].jobs.size();

        Test.startTest();
        skedFixedSiteWbDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(shifts, existingShiftWithJob('Charge', 1));
        Test.stopTest();

        System.assertEquals(jobCountBefore, shifts[0].jobs.size(),
            'Charge IS a WB system role, so an existing non-manual Charge job must not be carried forward as a manual one');
    }
}
