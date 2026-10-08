/**
 * Builds the NEW-drive-shape shift + job records (in-memory, not yet inserted) for a Fixed Site
 * "Non Integrated WB" drive regeneration. Ported only from wbFixedSiteGenerator.js's
 * populateDriveShiftJobs (wb:1456-1580) - never from mobileGenerator.js, fixedSiteGenerator.js or
 * any legacy Apex.
 *
 * Scope is per-shift job population ONLY. The outer per-shift loop (shift record, time blocks,
 * fresh job tags, lunch break, shift time) is wbFixedSiteGenerator.js's buildMultiDriveShifts, which
 * differs from mobileGenerator.js's by 4 lines (dropping APTSetup from the proposed shift), so it is
 * reused via skedMobileDriveJobBuilder's ShiftJobPopulator seam rather than forked. Everything
 * downstream - applyExistingRecordIds, restoreUnchangedJobQuantities, applyShiftSetupRollups,
 * updateDriveStaffCapacity, recalculateLunchBreakForAllShifts, calculateDriveProductivityPlanned -
 * is skedMobileDriveJobBuilder's and is called directly by the engine.
 *
 * Expected inputs from the (separately built) WB calculators: `roleQuantityByShiftKey` is shift key
 * -> PLAIN resource role -> skedMobileRoleQuantityCalculator.RoleQuantity (never Mobile's composite
 * "role-dualRole" job key - WB has no dual roles at all), and `volunteerQuantityByShiftKey` is shift
 * key -> Donor Ambassador quantity, the same shape skedFixedSiteVolunteerCalculator returns.
 *
 * How WB's job population differs from Mobile's, all verified against the JS:
 * - No vehicle asset job ever (Mobile's asset loop has an `assetType === VEHICLE ||` escape hatch
 *   that emits one even at zero quantity; wb:1537 is a plain `quantity > 0`). Enforced structurally:
 *   this class takes an equipment quantity and nothing else.
 * - Jobs match/emit on plain resourceRole and no job is ever given a dual role.
 * - An equipment job carries an extra 'Fixed Site' job tag on top of the Equipment tag set (wb:1547).
 * - Volunteer quantities are per shift (wb:1516), not drive-level like Mobile's.
 * - Volunteer and equipment jobs get NO sked_System_Quantity__c (Mobile sets it on both).
 * - Sponsor volunteer quantity is always 0 and is never carried forward - see buildVolunteerJob.
 * - Manually-created-job preservation uses WB's own system-role set and keeps zero-quantity jobs -
 *   see preserveManuallyCreatedJobsForAllShifts.
 * - Lunch-break duration is bucketed by WB's own staff-setup role list - see WB_STAFF_SETUP_ROLES and
 *   recalculateLunchBreakForAllShifts.
 *
 * NOTE: wb:1473-1481 filters the backup drive's locked jobs into `lockedBackupJobs`, then guards the
 * retention on `if(!lockedBackupJobs)` - always false for an array, so locked jobs are never retained.
 * Ported as observed (no retention); the evident intent is deliberately NOT implemented.
 * NOTE: wb:1502/1511/1532's `if(!jobs.find(...))` duplicate guards cannot fire here - a Map keyed by
 * role/shift key can't yield the same role twice - so they have no Apex counterpart.
 * NOTE: wb:1577-1579 tail-calls recalculateVphhQuantity after the manual-job merge. Not wired up by
 * this class: WB's VP/HH recompute has its own Math.ceil behavior and belongs with WB's role-quantity
 * work, not here.
 */
public with sharing class skedFixedSiteWbDriveJobBuilder {

    private static final String ROLE_VPHH = 'VP/HH';
    private static final String EQUIPMENT_SUBTYPE_2RBC_ASSET = '2RBC Asset';

    // helper.js:3553-3554's WB branch - Mobile's list minus Driver and Driver Support.
    private static final Set<String> WB_SYSTEM_ROLES = new Set<String>{
        '2RBC', 'Drive Lead', 'Team Supervisor', 'Charge', ROLE_VPHH
    };

    // wb:1677 and wb:1837's calculateStaffSetup role list - the headcount that picks the lunch-break
    // duration bucket. Mobile's adds Driver and Driver Support.
    private static final List<String> WB_STAFF_SETUP_ROLES = new List<String>{ '2RBC', ROLE_VPHH, 'Charge' };

    public static List<skedMobileDriveJobBuilder.ProposedDriveShift> buildProposedDriveShifts(sked_Drive__c drive,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey,
            Map<String, Integer> volunteerQuantityByShiftKey, Decimal numberOfEquipments, String timezoneSidId,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig,
            Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>> jobTagsByResourceType,
            List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks) {
        WbShiftJobPopulator populator = new WbShiftJobPopulator(drive, roleQuantityByShiftKey, volunteerQuantityByShiftKey, numberOfEquipments);
        // Null aptSetup: WB drops APTSetup from the proposed shift entirely (wb:1365-1379).
        List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed = skedMobileDriveJobBuilder.buildProposedDriveShifts(
            drive, shiftsMetadata, null, timezoneSidId, lunchBreakSettingsConfig, jobTagsByResourceType, collectionOperationTimeBlocks,
            populator, WB_STAFF_SETUP_ROLES);
        stampFixedSiteTagOnEquipmentJobs(proposed);
        return proposed;
    }

    /**
     * The lunch-break recompute that must run after preserveManuallyCreatedJobsForAllShifts, with WB's
     * own staff-setup role list - Mobile's list would count a preserved legacy Driver/Driver Support
     * job's headcount toward the lunch-break duration bucket, which WB's own generator never does.
     */
    public static void recalculateLunchBreakForAllShifts(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig, String timezoneSidId, Boolean lockLunchBreak,
            List<sked_Drive_Shift__c> existingDriveShifts) {
        skedMobileDriveJobBuilder.recalculateLunchBreakForAllShifts(proposed, shiftsMetadata, lunchBreakSettingsConfig, timezoneSidId,
            lockLunchBreak, existingDriveShifts, WB_STAFF_SETUP_ROLES);
    }

    /**
     * WB's own manually-created-job preservation: helper.js:3553-3554's system-role set (so a legacy
     * Driver job on a WB drive counts as manually created and survives, where Mobile's set would treat
     * it as system-generated and drop it), and no quantity > 0 filter - wb:1568 concatenates the
     * manual jobs unfiltered where mobileGenerator.js:2150 keeps only positive-quantity ones.
     */
    public static void preserveManuallyCreatedJobsForAllShifts(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed,
            List<sked_Drive_Shift__c> existingDriveShifts) {
        skedMobileDriveJobBuilder.ManualJobPreservationConfig config = new skedMobileDriveJobBuilder.ManualJobPreservationConfig();
        config.systemResourceRoles = WB_SYSTEM_ROLES;
        config.requirePositiveQuantity = false;
        skedMobileDriveJobBuilder.preserveManuallyCreatedJobsForAllShifts(proposed, existingDriveShifts, config);
    }

    private class WbShiftJobPopulator implements skedMobileDriveJobBuilder.ShiftJobPopulator {
        private final sked_Drive__c drive;
        private final Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey;
        private final Map<String, Integer> volunteerQuantityByShiftKey;
        private final Decimal numberOfEquipments;
        // Built once per drive, never per shift - buildGroupByRoleLookup() issues SOQL.
        private final Map<String, String> groupByRole;

        private WbShiftJobPopulator(sked_Drive__c drive,
                Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey,
                Map<String, Integer> volunteerQuantityByShiftKey, Decimal numberOfEquipments) {
            this.drive = drive;
            this.roleQuantityByShiftKey = roleQuantityByShiftKey;
            this.volunteerQuantityByShiftKey = volunteerQuantityByShiftKey;
            this.numberOfEquipments = numberOfEquipments;
            this.groupByRole = skedMobileDriveJobBuilder.buildGroupByRoleLookup();
        }

        public List<sked__Job__c> buildShiftJobs(Integer shiftIndex, skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata) {
            List<sked__Job__c> jobs = new List<sked__Job__c>();

            Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = roleQuantityByShiftKey == null
                ? null : roleQuantityByShiftKey.get(shiftMetadata.key);
            if (roleQuantities != null) {
                for (String role : roleQuantities.keySet()) {
                    sked__Job__c job = buildRoleJob(role, roleQuantities.get(role), shiftMetadata);
                    if (job != null) {
                        jobs.add(job);
                    }
                }
            }

            Integer volunteerQuantity = volunteerQuantityByShiftKey == null ? null : volunteerQuantityByShiftKey.get(shiftMetadata.key);
            sked__Job__c volunteerJob = buildVolunteerJob(volunteerQuantity);
            if (volunteerJob != null) {
                jobs.add(volunteerJob);
            }

            // Only the first shift keeps asset jobs - wb:1390-1394 drops every non-role, non-volunteer
            // job from later shifts.
            if (shiftIndex == 0 && numberOfEquipments != null && numberOfEquipments > 0) {
                jobs.add(buildEquipmentJob(numberOfEquipments));
            }
            return jobs;
        }

        // VP/HH needs either vphhQuantity or aptQuantity positive; every other role needs quantity
        // positive. sked_Dual_Role__c is deliberately never written - WB has no dual roles.
        private sked__Job__c buildRoleJob(String role, skedMobileRoleQuantityCalculator.RoleQuantity roleQuantity,
                skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata) {
            if (roleQuantity == null) {
                return null;
            }
            Boolean isVpHh = role == ROLE_VPHH;
            Boolean shouldEmit = isVpHh
                ? (positive(roleQuantity.vphhQuantity) || positive(roleQuantity.aptQuantity))
                : positive(roleQuantity.quantity);
            if (!shouldEmit) {
                return null;
            }

            sked__Job__c job = new sked__Job__c(
                sked_Resource_Role__c = role,
                sked__Location__c = drive.sked_Drive_Site__c,
                sked_Is_Manually_Created__c = roleQuantity.isManuallyCreated == true,
                sked_Manually_Created_From__c = roleQuantity.manuallyCreatedFrom,
                sked__Job_Allocation_Time_Source__c = false
            );
            if (isVpHh) {
                job.sked_VPHH_Quantity__c = roleQuantity.vphhQuantity;
                job.sked_APT_Quantity__c = roleQuantity.aptQuantity;
                job.sked__Quantity__c = zeroIfNull(roleQuantity.vphhQuantity) + zeroIfNull(roleQuantity.aptQuantity);
            } else {
                job.sked__Quantity__c = roleQuantity.quantity;
            }
            job.sked_System_Quantity__c = job.sked__Quantity__c;

            skedMobileDriveJobBuilder.applyRoleTimeForSingleJob(job, role, null, groupByRole, shiftMetadata.resourceRoleGroupRoleTimeDataMap);
            return job;
        }

        /**
         * wb:1517-1533. Sponsor quantity is always 0: WB looks the existing volunteer job up in
         * `driveShift.jobs` (wb:1518) - the freshly built proposed shift, always empty at that point -
         * where mobileGenerator.js:2097 and fixedSiteGenerator.js:1306 both read the ORIGINAL shift's
         * job and preserve it. So a WB regen overwrites any saved sponsor quantity with 0. Ported as
         * observed; the engine must NOT call skedMobileDriveJobBuilder.carryForwardVolunteerSponsorQuantity,
         * which would both restore sponsor quantity and write sked_System_Quantity__c.
         */
        private sked__Job__c buildVolunteerJob(Integer volunteerQuantity) {
            if (volunteerQuantity == null || volunteerQuantity <= 0) {
                return null;
            }
            return new sked__Job__c(
                sked_Volunteer_Role__c = skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR,
                sked__Location__c = drive.sked_Drive_Site__c,
                sked_Redcross_Volunteer_Quantity__c = volunteerQuantity,
                sked_Sponsor_Volunteer_Quantity__c = 0,
                sked__Quantity__c = volunteerQuantity,
                sked_Is_Manually_Created__c = false,
                sked__Job_Allocation_Time_Source__c = false
            );
        }

        private sked__Job__c buildEquipmentJob(Decimal quantity) {
            return new sked__Job__c(
                sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT,
                sked_Equipment_Subtype__c = EQUIPMENT_SUBTYPE_2RBC_ASSET,
                sked__Location__c = drive.sked_Drive_Site__c,
                sked__Quantity__c = quantity,
                sked_Is_Manually_Created__c = false
            );
        }
    }

    /**
     * wb:1547 pushes `{ tag: { name: 'Fixed Site' }, systemCreated: true }` onto an equipment job's
     * tags - a tag object with no tagId, which MobileDriveGeneratorDMLService's DMLJobTag maps to a
     * Job Tag with a null Tag lookup. Resolved by name here instead: emitting a null-Tag junction row
     * would be a new failure mode, not inherited behavior. Silently skipped when no such Tag exists.
     * sked__Required__c stays false - the source object has no `required` property.
     */
    private static void stampFixedSiteTagOnEquipmentJobs(List<skedMobileDriveJobBuilder.ProposedDriveShift> proposed) {
        List<sked__Tag__c> fixedSiteTags = [
            SELECT Id
            FROM sked__Tag__c
            WHERE Name = :skedConstants.TAG_FIXED_SITE AND sked__Type__c = :skedConstants.TAG_TYPE_DRIVE_TYPE
        ];
        if (fixedSiteTags.isEmpty()) {
            return;
        }
        Id fixedSiteTagId = fixedSiteTags[0].Id;

        for (skedMobileDriveJobBuilder.ProposedDriveShift shift : proposed) {
            for (Integer i = 0; i < shift.jobs.size(); i++) {
                if (shift.jobs[i].sked_Asset_Type__c != skedConstants.ASSET_TYPE_EQUIPMENT) {
                    continue;
                }
                List<sked__Job_Tag__c> jobTags = shift.jobTagsByJobIndex.get(i);
                if (jobTags == null) {
                    jobTags = new List<sked__Job_Tag__c>();
                    shift.jobTagsByJobIndex.put(i, jobTags);
                }
                if (!containsTag(jobTags, fixedSiteTagId)) {
                    jobTags.add(new sked__Job_Tag__c(sked__Tag__c = fixedSiteTagId, sked__Required__c = false, sked_SystemCreated__c = true));
                }
            }
        }
    }

    private static Boolean containsTag(List<sked__Job_Tag__c> jobTags, Id tagId) {
        for (sked__Job_Tag__c jobTag : jobTags) {
            if (jobTag.sked__Tag__c == tagId) {
                return true;
            }
        }
        return false;
    }

    private static Boolean positive(Decimal value) {
        return value != null && value > 0;
    }

    private static Decimal zeroIfNull(Decimal value) {
        return value == null ? 0 : value;
    }
}
