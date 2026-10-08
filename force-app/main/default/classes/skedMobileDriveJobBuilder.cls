/**
 * Builds the NEW-drive-shape shift + job records (in-memory, not yet inserted) for a Mobile drive
 * regeneration. Ported only from the slwcDriveGenerator LWC's mobile/base generator logic, never
 * from the legacy GenerateMobileDrive.cls/CreateSkedDrive.cls.
 *
 * Scope: builds shift + job records from the shift metadata (skedMobileDriveShiftCalculator) and
 * role quantities (skedMobileRoleQuantityCalculator) already computed. Applies role-time to each
 * job, populates lunch-break fields (skedMobileLunchBreakCalculator), computes job/shift
 * start-finish times, and computes each shift's staff capacity
 * (skedMobileRoleQuantityCalculator.calculateDriveShiftStaffCapacity, via updateDriveStaffCapacity
 * below).
 *
 * applyExistingRecordIds (below) matches proposed shifts/jobs against an existing drive's real
 * records so skedDriveGraphSaver updates instead of duplicate-inserting. Shifts match purely by
 * array position (index i <-> index i) - never by start/end time. Jobs match by role: role jobs by
 * resourceRole+dualRole among non-manually-created existing jobs; volunteer jobs by volunteerRole;
 * asset jobs by assetType (+ equipmentSubtype for Equipment).
 *
 * Manually-created-job preservation (preserveManuallyCreatedJobsForAllShifts, below) runs BEFORE
 * capacity/slot generation, matching the source's own job-merge ordering so those steps already
 * reflect a manual job's contribution. recalculateVphhQuantityForAllShifts (below) IS ported - fills
 * the VP/HH capacity gap a manually-preserved job leaves behind. jobTag assignment+merging
 * (assignFreshJobTags + mergeForwardJobTags, below) IS ported - fresh required tags come from
 * skedMobileDriveShiftCalculator.MasterData.jobTagsByResourceType, and existing systemCreated tags
 * merge forward via skedMobileJobTagLoader. jobAllocation carry-forward is a separate class
 * (skedMobileJobAllocationCarryForward). The lockLunchBreak/restoreLunchBreak override-preservation
 * branch of lunch-break population IS ported (recalculateLunchBreakForAllShifts, below - see
 * skedMobileLunchBreakCalculator for the restore logic itself). Still deliberately NOT ported: the
 * shift-level tag summary/display-name string (cosmetic, no bearing on the job/tag records
 * themselves), time blocks, and volunteer jobs (not built by this port).
 * Known gap even after this: skedDriveGraphSaver.deleteRemovedRecords() never explicitly removes
 * Job (or Job Tag) records that disappear from the graph (only slots/delivery-jobs/shifts) - a
 * skedDriveGraphSaver-level gap, out of scope for this class.
 */
public with sharing class skedMobileDriveJobBuilder {

    public class ProposedDriveShift extends skedProposedDriveShift {
        // Populated by skedMobileSlotGenerator, a later step - never set here.
        public List<sked__Slot__c> slots = new List<sked__Slot__c>();
        // Populated by skedMobileJobAllocationCarryForward, a later step - never set here. Keyed by
        // the carried-forward Job Id (jobs with no carried-forward Id never have an entry).
        public Map<Id, List<sked__Job_Allocation__c>> jobAllocationsByJobId = new Map<Id, List<sked__Job_Allocation__c>>();
        // Each freshly built job's starting (unsaved) tag set, keyed by that job's index within
        // `jobs` (jobs have no Id yet at build time, so an Id-keyed map like jobAllocationsByJobId
        // above doesn't work here). applyExistingRecordIds merges existing systemCreated tags
        // forward into the same index's list once a job's real Id is known.
        public Map<Integer, List<sked__Job_Tag__c>> jobTagsByJobIndex = new Map<Integer, List<sked__Job_Tag__c>>();
    }

    private static final String ROLE_2RBC = '2RBC';
    private static final String ROLE_VPHH = 'VP/HH';
    private static final String ROLE_DRIVER = 'Driver';
    private static final String ROLE_DRIVER_SUPPORT = 'Driver Support';

    /**
     * Per-shift job population seam. Everything else the outer loop below does (shift record, time
     * blocks, fresh job tags, lunch break, shift time) is drive-type-agnostic - only the job set
     * itself differs, so a non-Mobile drive type supplies its own populator instead of forking the
     * loop (skedFixedSiteWbDriveJobBuilder is the first).
     */
    public interface ShiftJobPopulator {
        List<sked__Job__c> buildShiftJobs(Integer shiftIndex, skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata);
    }

    public static List<ProposedDriveShift> buildProposedDriveShifts(sked_Drive__c drive,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey,
            Decimal numberOfVehicles, Decimal numberOfEquipments, String timezoneSidId,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig,
            Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>> jobTagsByResourceType,
            List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks, Decimal redcrossVolunteerQuantity) {
        return buildProposedDriveShifts(drive, shiftsMetadata, shiftsMetadata.aptSetup, timezoneSidId, lunchBreakSettingsConfig,
            jobTagsByResourceType, collectionOperationTimeBlocks,
            new MobileShiftJobPopulator(drive, roleQuantityByShiftKey, numberOfVehicles, numberOfEquipments, redcrossVolunteerQuantity));
    }

    /**
     * Drive-type-neutral outer loop: the Mobile entry point above delegates here with its own
     * populator, and every other drive type passes its own. `shiftAptSetup` is written to each
     * shift's sked_APT_Setup__c at build time (applyShiftSetupRollups recomputes it later from the
     * jobs themselves) - null for a drive type with no APT concept at all. A null `staffSetupRoles`
     * means Mobile's own list (skedMobileLunchBreakCalculator's), the roles whose headcount picks the
     * lunch-break duration bucket.
     */
    public static List<ProposedDriveShift> buildProposedDriveShifts(sked_Drive__c drive,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, Decimal shiftAptSetup, String timezoneSidId,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig,
            Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>> jobTagsByResourceType,
            List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks, ShiftJobPopulator jobPopulator,
            List<String> staffSetupRoles) {
        List<ProposedDriveShift> proposedShifts = new List<ProposedDriveShift>();
        for (Integer i = 0; i < shiftsMetadata.driveShifts.size(); i++) {
            skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata = shiftsMetadata.driveShifts[i];
            ProposedDriveShift proposed = new ProposedDriveShift();
            proposed.shiftRecord = buildShiftRecord(shiftMetadata, shiftAptSetup);
            populateDriveShiftTimeBlocks(proposed.shiftRecord, drive, collectionOperationTimeBlocks);

            proposed.jobs.addAll(jobPopulator.buildShiftJobs(i, shiftMetadata));

            assignFreshJobTags(proposed, jobTagsByResourceType);
            // No existing-shift data is loaded yet at this point in the engine (see
            // recalculateLunchBreakForAllShifts's header) - lock/restore can only apply there.
            populateLunchBreakTime(proposed, shiftMetadata, lunchBreakSettingsConfig, timezoneSidId, false, null, staffSetupRoles);
            populateShiftTime(proposed, timezoneSidId);
            proposedShifts.add(proposed);
        }
        return proposedShifts;
    }

    public static List<ProposedDriveShift> buildProposedDriveShifts(sked_Drive__c drive,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, Decimal shiftAptSetup, String timezoneSidId,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig,
            Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>> jobTagsByResourceType,
            List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks, ShiftJobPopulator jobPopulator) {
        return buildProposedDriveShifts(drive, shiftsMetadata, shiftAptSetup, timezoneSidId, lunchBreakSettingsConfig,
            jobTagsByResourceType, collectionOperationTimeBlocks, jobPopulator, null);
    }

    // skedMobileLunchBreakCalculator hardcodes Mobile's staff-setup role list, so a non-Mobile role
    // list has to go straight to the shared calculator instead.
    private static void populateLunchBreakTime(ProposedDriveShift proposed, skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig, String timezoneSidId, Boolean lockLunchBreak,
            sked_Drive_Shift__c existingShiftRecord, List<String> staffSetupRoles) {
        if (staffSetupRoles == null) {
            skedMobileLunchBreakCalculator.populateLunchBreakTime(proposed, shiftMetadata, lunchBreakSettingsConfig, timezoneSidId,
                lockLunchBreak, existingShiftRecord);
            return;
        }
        skedLunchBreakCalculator.populateLunchBreakTime(proposed, shiftMetadata, lunchBreakSettingsConfig, timezoneSidId,
            lockLunchBreak, existingShiftRecord, staffSetupRoles);
    }

    private class MobileShiftJobPopulator implements ShiftJobPopulator {
        private final sked_Drive__c drive;
        private final Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey;
        private final Decimal numberOfVehicles;
        private final Decimal numberOfEquipments;
        private final Decimal redcrossVolunteerQuantity;
        // Built once per drive, never per shift - buildGroupByRoleLookup() issues SOQL.
        private final Map<String, String> groupByRole;

        private MobileShiftJobPopulator(sked_Drive__c drive,
                Map<String, Map<String, skedMobileRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey,
                Decimal numberOfVehicles, Decimal numberOfEquipments, Decimal redcrossVolunteerQuantity) {
            this.drive = drive;
            this.roleQuantityByShiftKey = roleQuantityByShiftKey;
            this.numberOfVehicles = numberOfVehicles;
            this.numberOfEquipments = numberOfEquipments;
            this.redcrossVolunteerQuantity = redcrossVolunteerQuantity;
            this.groupByRole = buildGroupByRoleLookup();
        }

        public List<sked__Job__c> buildShiftJobs(Integer shiftIndex, skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata) {
            List<sked__Job__c> jobs = new List<sked__Job__c>();
            Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> roleQuantities = roleQuantityByShiftKey.get(shiftMetadata.key);
            for (String jobKey : roleQuantities.keySet()) {
                // A merged dual-role entry (skedMobileDualRoleGenerator) is keyed "role-dualRole" -
                // role names themselves never contain '-'.
                List<String> keyParts = jobKey.split('-');
                String role = keyParts[0];
                String dualRole = keyParts.size() > 1 ? keyParts[1] : '';
                sked__Job__c job = buildRoleJob(role, dualRole, roleQuantities.get(jobKey), drive, groupByRole, shiftMetadata.resourceRoleGroupRoleTimeDataMap);
                if (job != null) {
                    jobs.add(job);
                }
            }

            // Every shift gets a volunteer job (same drive-level quantity, mirroring the source) -
            // only asset jobs are restricted to the first shift.
            sked__Job__c volunteerJob = buildVolunteerJob(redcrossVolunteerQuantity, drive);
            if (volunteerJob != null) {
                jobs.add(volunteerJob);
            }

            // Only the first shift gets asset jobs - later shifts keep only resourceRole/volunteerRole jobs.
            if (shiftIndex == 0) {
                jobs.add(buildAssetJob(skedConstants.ASSET_TYPE_VEHICLE, numberOfVehicles, drive));
                if (numberOfEquipments != null && numberOfEquipments > 0) {
                    jobs.add(buildAssetJob(skedConstants.ASSET_TYPE_EQUIPMENT, numberOfEquipments, drive));
                }
            }
            return jobs;
        }
    }

    // A role job (including VP/HH) and a volunteer job both always get the Person tag set; an asset
    // job gets Vehicle or Equipment depending on assetType.
    private static void assignFreshJobTags(ProposedDriveShift shift, Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>> jobTagsByResourceType) {
        for (Integer i = 0; i < shift.jobs.size(); i++) {
            sked__Job__c job = shift.jobs[i];
            String resourceType = String.isNotBlank(job.sked_Resource_Role__c) || String.isNotBlank(job.sked_Volunteer_Role__c)
                ? skedConstants.RESOURCE_TYPE_PERSON
                : job.sked_Asset_Type__c;
            List<skedMobileDriveShiftCalculator.RequiredJobTag> requiredTags = jobTagsByResourceType.get(resourceType);
            if (requiredTags == null) {
                continue;
            }
            List<sked__Job_Tag__c> jobTags = new List<sked__Job_Tag__c>();
            for (skedMobileDriveShiftCalculator.RequiredJobTag requiredTag : requiredTags) {
                jobTags.add(new sked__Job_Tag__c(sked__Tag__c = requiredTag.tagId, sked__Required__c = true, sked_SystemCreated__c = requiredTag.systemCreated));
            }
            shift.jobTagsByJobIndex.put(i, jobTags);
        }
    }

    private static sked_Drive_Shift__c buildShiftRecord(skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata, Decimal aptSetup) {
        return new sked_Drive_Shift__c(
            sked_Drive_Date__c = shiftMetadata.driveDate,
            sked_Start_Time__c = shiftMetadata.startTime,
            sked_End_Time__c = shiftMetadata.endTime,
            sked_2RBC_Projected_Procedures__c = shiftMetadata.x2rbcProjectedProcedures,
            sked_WB_Projected_Procedures__c = shiftMetadata.wbProjectedProcedures,
            sked_Donors_Scheduled__c = shiftMetadata.donorsScheduled,
            sked_APT_Setup__c = aptSetup
        );
    }

    // Ported from helper.js's populateDriveShiftTimeBlocks. The source's timeBlockManuallyChanged
    // preservation branch is a single-UI-session-only concept (a flag never persisted to any field,
    // only kept in-memory across the modal's own recalculations) with no batch-regen equivalent - a
    // still-unported gap, unlike lockLunchBreak/restoreLunchBreak (a real persisted drive-level flag,
    // now ported - see recalculateLunchBreakForAllShifts). A fresh proposed shift record has no time
    // block yet, so there's no stale value to reset.
    private static void populateDriveShiftTimeBlocks(sked_Drive_Shift__c shiftRecord, sked_Drive__c drive,
            List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks) {
        if (!skedCollectionOperationTimeBlockMatcher.isDriveUseTimeBlock(drive, collectionOperationTimeBlocks)) {
            return;
        }

        List<Collection_Operation_Time_Block__c> availableTimeBlocks = skedCollectionOperationTimeBlockMatcher.findAvailableTimeBlocks(
            drive, shiftRecord.sked_Start_Time__c, shiftRecord.sked_End_Time__c, collectionOperationTimeBlocks);

        if (availableTimeBlocks.size() == 1) {
            shiftRecord.sked_Time_Block__c = availableTimeBlocks[0].Time_Block__c;
            return;
        }

        // 0 matched on time (>1 is left ambiguous/unset, matching the source) - fall back to the CO's
        // time blocks for the day alone, ignoring shift start/end time.
        if (availableTimeBlocks.isEmpty()) {
            List<Collection_Operation_Time_Block__c> availableCOTimeBlocks = skedCollectionOperationTimeBlockMatcher.findAvailableCOTimeBlocks(drive, collectionOperationTimeBlocks);
            if (availableCOTimeBlocks.size() == 1) {
                shiftRecord.sked_Time_Block__c = availableCOTimeBlocks[0].Time_Block__c;
            }
        }
    }

    // VP/HH needs either vphhQuantity or aptQuantity positive; every other role needs quantity positive.
    private static sked__Job__c buildRoleJob(String role, String dualRole, skedMobileRoleQuantityCalculator.RoleQuantity roleQuantity, sked_Drive__c drive,
            Map<String, String> groupByRole, Map<String, skedMobileDriveShiftCalculator.RoleTimeData> resourceRoleGroupRoleTimeDataMap) {
        Boolean isVpHh = role == ROLE_VPHH;
        Boolean shouldEmit = isVpHh
            ? (positive(roleQuantity.vphhQuantity) || positive(roleQuantity.aptQuantity))
            : positive(roleQuantity.quantity);
        if (!shouldEmit) {
            return null;
        }

        sked__Job__c job = new sked__Job__c(
            sked_Resource_Role__c = role,
            sked_Dual_Role__c = dualRole,
            sked__Location__c = drive.sked_Drive_Site__c,
            sked__Quantity__c = roleQuantity.quantity,
            sked_System_Quantity__c = roleQuantity.quantity,
            sked_Is_Manually_Created__c = false,
            sked__Job_Allocation_Time_Source__c = false
        );
        if (isVpHh) {
            job.sked_VPHH_Quantity__c = roleQuantity.vphhQuantity;
            job.sked_APT_Quantity__c = roleQuantity.aptQuantity;
        }

        applyRoleTimeForSingleJob(job, role, dualRole, groupByRole, resourceRoleGroupRoleTimeDataMap);
        return job;
    }

    private static sked__Job__c buildAssetJob(String assetType, Decimal quantity, sked_Drive__c drive) {
        Decimal effectiveQuantity = quantity == null ? 0 : quantity;
        sked__Job__c job = new sked__Job__c(
            sked_Asset_Type__c = assetType,
            sked__Location__c = drive.sked_Drive_Site__c,
            sked__Quantity__c = effectiveQuantity,
            sked_System_Quantity__c = effectiveQuantity,
            sked_Is_Manually_Created__c = false
        );
        if (assetType == skedConstants.ASSET_TYPE_EQUIPMENT) {
            job.sked_Equipment_Subtype__c = '2RBC Asset';
        }
        return job;
    }

    // sponsorVolunteerQuantity always starts at 0 here - carryForwardVolunteerSponsorQuantity (below)
    // fills it in once existingDriveShifts is available, since a fresh job has no existing counterpart
    // to read it from yet. redcrossVolunteerQuantity is drive-level (not per-shift), same value on
    // every shift, mirroring mobileGenerator.js's mapVolunteerQuantity.forEach running once per shift
    // build with the same drive-wide map. No job at all when the quantity isn't positive - matches
    // the source's own `if (quantity > 0) jobs.push(job)` gate.
    private static sked__Job__c buildVolunteerJob(Decimal redcrossVolunteerQuantity, sked_Drive__c drive) {
        if (!positive(redcrossVolunteerQuantity)) {
            return null;
        }
        return new sked__Job__c(
            sked_Volunteer_Role__c = skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR,
            sked__Location__c = drive.sked_Drive_Site__c,
            sked_Redcross_Volunteer_Quantity__c = redcrossVolunteerQuantity,
            sked_Sponsor_Volunteer_Quantity__c = 0,
            sked__Quantity__c = redcrossVolunteerQuantity,
            sked_System_Quantity__c = redcrossVolunteerQuantity,
            sked_Is_Manually_Created__c = false,
            sked__Job_Allocation_Time_Source__c = false
        );
    }

    // Carries forward an existing volunteer job's sponsor-recruited quantity onto the freshly-built
    // one - this port never computes sponsorVolunteerQuantity itself (a separate, non-regen workflow
    // owns it), so it must survive untouched. Must run after existingDriveShifts is loaded, which is
    // after buildProposedDriveShifts already built a fresh (sponsor = 0) volunteer job - matches
    // populateDriveShiftJobs's own job = (originalDriveShift?.jobs || []).find(...) lookup, just as a
    // separate pass rather than inline, since this port builds shifts before it has existing data.
    public static void carryForwardVolunteerSponsorQuantity(List<ProposedDriveShift> proposed, List<sked_Drive_Shift__c> existingDriveShifts) {
        for (Integer i = 0; i < proposed.size() && i < existingDriveShifts.size(); i++) {
            sked__Job__c volunteerJob = findVolunteerJob(proposed[i].jobs);
            if (volunteerJob == null) {
                continue;
            }
            sked__Job__c existingVolunteerJob = findVolunteerJob(existingDriveShifts[i].sked_Jobs__r);
            if (existingVolunteerJob == null || !positive(existingVolunteerJob.sked_Sponsor_Volunteer_Quantity__c)) {
                continue;
            }
            volunteerJob.sked_Sponsor_Volunteer_Quantity__c = existingVolunteerJob.sked_Sponsor_Volunteer_Quantity__c;
            volunteerJob.sked__Quantity__c = volunteerJob.sked_Redcross_Volunteer_Quantity__c + existingVolunteerJob.sked_Sponsor_Volunteer_Quantity__c;
            volunteerJob.sked_System_Quantity__c = volunteerJob.sked__Quantity__c;
        }
    }

    private static sked__Job__c findVolunteerJob(List<sked__Job__c> jobs) {
        for (sked__Job__c job : jobs) {
            if (job.sked_Volunteer_Role__c == skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR) {
                return job;
            }
        }
        return null;
    }

    private static Boolean positive(Decimal value) {
        return value != null && value > 0;
    }

    // skedResourceUtils.getResourceRolesByGroup() splits its source text on ';' without trimming,
    // leaving a leading space on every role after the first (pre-existing, unrelated data quirk) -
    // trim defensively here rather than "fixing" the shared utility. Public: also reused by
    // skedMobileJobAllocationCarryForward's driving-role check.
    public static Map<String, String> buildGroupByRoleLookup() {
        Map<String, String> groupByRole = new Map<String, String>();
        Map<String, Set<String>> rolesByGroup = skedResourceUtils.getResourceRolesByGroup();
        for (String resourceRoleGroup : rolesByGroup.keySet()) {
            for (String role : rolesByGroup.get(resourceRoleGroup)) {
                groupByRole.put(role.trim(), resourceRoleGroup);
            }
        }
        return groupByRole;
    }

    // For a dual-role job, each time field takes the MAX of the primary and dual role's group data -
    // UNLESS the primary role's group isn't Driving Roles but the dual role's is, in which case the
    // dual role's (Driving Roles) data is used outright as the base (a driving-role's travel/lead/etc.
    // times dominate a non-driving role's).
    // Public: baseGenerator.js owns this (shared by every generator), so a non-Mobile job builder
    // applies role time through it too, passing a null dualRole.
    public static void applyRoleTimeForSingleJob(sked__Job__c job, String role, String dualRole, Map<String, String> groupByRole,
            Map<String, skedMobileDriveShiftCalculator.RoleTimeData> resourceRoleGroupRoleTimeDataMap) {
        String resourceRoleGroup = groupByRole.get(role);
        skedMobileDriveShiftCalculator.RoleTimeData roleTimeData = resourceRoleGroup == null ? null : resourceRoleGroupRoleTimeDataMap.get(resourceRoleGroup);

        skedMobileDriveShiftCalculator.RoleTimeData dualRoleTimeData = null;
        if (resourceRoleGroup != skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES && String.isNotBlank(dualRole)) {
            String dualRoleGroup = groupByRole.get(dualRole);
            dualRoleTimeData = dualRoleGroup == null ? null : resourceRoleGroupRoleTimeDataMap.get(dualRoleGroup);
            if (dualRoleGroup == skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES) {
                roleTimeData = dualRoleTimeData;
            }
        }
        if (roleTimeData == null) {
            return;
        }

        job.sked_Lead_Time__c = maxOf(roleTimeData.leadTime, dualRoleTimeData == null ? null : dualRoleTimeData.leadTime);
        job.sked_Travel_Time__c = maxOf(roleTimeData.travelTime, dualRoleTimeData == null ? null : dualRoleTimeData.travelTime);
        job.sked_Site_Logistics_To__c = maxOf(roleTimeData.siteLogisticsTo, dualRoleTimeData == null ? null : dualRoleTimeData.siteLogisticsTo);
        job.sked_Setup_Time__c = maxOf(roleTimeData.setupTime, dualRoleTimeData == null ? null : dualRoleTimeData.setupTime);
        job.sked_Breakdown_Time__c = maxOf(roleTimeData.breakdownTime, dualRoleTimeData == null ? null : dualRoleTimeData.breakdownTime);
        job.sked_Travel_Time2__c = maxOf(roleTimeData.travelTime2, dualRoleTimeData == null ? null : dualRoleTimeData.travelTime2);
        job.sked_Site_Logistics_Back__c = maxOf(roleTimeData.siteLogisticsBack, dualRoleTimeData == null ? null : dualRoleTimeData.siteLogisticsBack);
        job.sked_Wrap_up_Time__c = maxOf(roleTimeData.wrapUpTime, dualRoleTimeData == null ? null : dualRoleTimeData.wrapUpTime);
    }

    // With no dual-role data, just the primary value; otherwise the larger of the two.
    private static Decimal maxOf(Decimal value1, Decimal value2) {
        Decimal v1 = value1 == null ? 0 : value1;
        if (value2 == null) {
            return v1;
        }
        Decimal v2 = value2;
        return v1 > v2 ? v1 : v2;
    }

    // Role-time-bearing jobs push the shift's start/finish envelope outward (further still when
    // lunchBreakBeforeDrawHours applies); asset jobs then adopt that same envelope. Requires
    // skedMobileLunchBreakCalculator.populateLunchBreakTime to have already run on this shift so
    // its lunch-break fields are populated.
    private static void populateShiftTime(ProposedDriveShift proposed, String timezoneSidId) {
        skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata = null;
        sked_Drive_Shift__c shift = proposed.shiftRecord;
        if (shift.sked_Drive_Date__c == null || shift.sked_Start_Time__c == null || shift.sked_End_Time__c == null) {
            return;
        }

        DateTime drawHoursStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.sked_Drive_Date__c, shift.sked_Start_Time__c, timezoneSidId);
        DateTime drawHoursEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shift.sked_Drive_Date__c, shift.sked_End_Time__c, timezoneSidId);

        DateTime minStart = drawHoursStart;
        DateTime maxEnd = drawHoursEnd;
        for (sked__Job__c job : proposed.jobs) {
            if (String.isBlank(job.sked_Resource_Role__c)) {
                continue;
            }
            Decimal durationBeforeDrawHours = zeroIfNull(job.sked_Lead_Time__c) + zeroIfNull(job.sked_Setup_Time__c)
                + zeroIfNull(job.sked_Travel_Time__c) + zeroIfNull(job.sked_Site_Logistics_To__c);
            if (shift.sked_Lunch_Break__c == true && shift.sked_Lunch_Break_Before_Draw_Hours__c == true) {
                durationBeforeDrawHours += zeroIfNull(shift.sked_Lunch_Break_Duration__c);
            }
            Decimal durationAfterDrawHours = zeroIfNull(job.sked_Breakdown_Time__c) + zeroIfNull(job.sked_Wrap_up_Time__c)
                + zeroIfNull(job.sked_Travel_Time2__c) + zeroIfNull(job.sked_Site_Logistics_Back__c);

            job.sked__Start__c = drawHoursStart.addMinutes(-1 * durationBeforeDrawHours.intValue());
            job.sked__Finish__c = drawHoursEnd.addMinutes(durationAfterDrawHours.intValue());

            if (minStart > job.sked__Start__c) {
                minStart = job.sked__Start__c;
            }
            if (maxEnd < job.sked__Finish__c) {
                maxEnd = job.sked__Finish__c;
            }
        }

        for (sked__Job__c job : proposed.jobs) {
            if (job.sked_Asset_Type__c != null || String.isNotBlank(job.sked_Volunteer_Role__c)) {
                job.sked__Start__c = minStart;
                job.sked__Finish__c = maxEnd;
            }
        }

        shift.sked_Start__c = minStart;
        shift.sked_Finish__c = maxEnd;
    }

    private static Decimal zeroIfNull(Decimal value) {
        return value == null ? 0 : value;
    }

    /**
     * Ported from baseGenerator.js's calculateDriveProductivityPlanned: totalProductsProjected
     * divided by weighted staff-hours across every staffed, non-manually-created job (draw duration
     * minus in-window lunch break, plus lead/setup/breakdown/wrap-up/travel/site-logistics time,
     * quantity-weighted). Calculate-and-write only, per product decision - the source's
     * STEP.VALIDATE_DRIVE_PRODUCTIVITY confirmation gate (< 0.8 needs a human to confirm before
     * continuing) is deliberately NOT ported, since there's no interactive user in this headless
     * DCR pipeline; the value is still written so it feeds sked_Drive_Productivity_Banding__c (a
     * formula field) and reporting.
     *
     * Draw-duration-minus-lunch-break reuses skedMobileDriveShiftCalculator.calculateDrawHoursInMinutes
     * rather than re-deriving it, but NOT with shiftMetadata.lunchBreakSettings directly - that's
     * computed early (calculateDriveShiftsMetadata, before recalculateLunchBreakForAllShifts' lock/
     * restore logic runs), so its lunchBreak/lunchBreakBeforeDrawHours flags can be stale once
     * sked_Lock_Lunch_Break__c restores different ones onto the shift record itself. This builds a
     * corrected LunchBreakSettings using the shift record's OWN (possibly restored) flags, keeping
     * only maximumLunchBreakDuration (the matched setting's configured ceiling, not itself subject
     * to restore) from the original - matching the source's driveShift.lunchBreak/
     * lunchBreakBeforeDrawHours/maximumLunchBreakDuration (baseGenerator.js:628-631), which read the
     * shift's own final state. This is deliberately NOT sked_Lunch_Break_Duration__c - that persisted
     * field holds a DIFFERENT resolved value depending on which populateLunchBreakTime branch ran
     * (the per-staff-count sked_Lunch_Break_Definition__c duration, or unpaidLunchBreakDuration),
     * never the plain configured maximum this formula actually needs.
     *
     * Returns null (caller leaves the field unchanged) when the source's own guard conditions
     * aren't met or the weighted sum is 0.
     */
    public static Decimal calculateDriveProductivityPlanned(sked_Drive__c drive, List<ProposedDriveShift> proposedShifts,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, Decimal totalProductsProjected, String timezoneSidId) {
        if (drive.sked_Drive_Date__c == null || drive.sked_Start_Time__c == null || drive.sked_End_Time__c == null || proposedShifts.isEmpty()) {
            return null;
        }

        Decimal sum = 0;
        for (Integer i = 0; i < proposedShifts.size(); i++) {
            ProposedDriveShift proposed = proposedShifts[i];
            skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata = shiftsMetadata.driveShifts[i];
            skedLunchBreakSettings restoredLunchBreakSettings = new skedLunchBreakSettings();
            restoredLunchBreakSettings.lunchBreak = proposed.shiftRecord.sked_Lunch_Break__c == true;
            restoredLunchBreakSettings.lunchBreakBeforeDrawHours = proposed.shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c == true;
            restoredLunchBreakSettings.maximumLunchBreakDuration = shiftMetadata.lunchBreakSettings != null
                ? shiftMetadata.lunchBreakSettings.maximumLunchBreakDuration : 0;
            Decimal drawDuration = skedMobileDriveShiftCalculator.calculateDrawHoursInMinutes(
                shiftMetadata.driveDate, shiftMetadata.startTime, shiftMetadata.endTime, timezoneSidId, restoredLunchBreakSettings);

            for (sked__Job__c job : proposed.jobs) {
                if (String.isBlank(job.sked_Resource_Role__c) || isManuallyCreatedFromStaffingModal(job)) {
                    continue;
                }
                Decimal quantity = zeroIfNull(job.sked__Quantity__c);
                sum += quantity * (drawDuration + zeroIfNull(job.sked_Travel_Time__c) + zeroIfNull(job.sked_Site_Logistics_To__c)
                    + zeroIfNull(job.sked_Lead_Time__c) + zeroIfNull(job.sked_Setup_Time__c) + zeroIfNull(job.sked_Breakdown_Time__c)
                    + zeroIfNull(job.sked_Wrap_up_Time__c) + zeroIfNull(job.sked_Travel_Time2__c) + zeroIfNull(job.sked_Site_Logistics_Back__c));
            }
        }
        if (sum <= 0) {
            return null;
        }
        // totalProductsProjected / (sum/60) rearranged to a single divide() call with an explicit
        // scale - plain Decimal '/' throws MathException on a non-terminating quotient, which a
        // real-world sum (durations aren't guaranteed to divide evenly into products projected)
        // would eventually hit.
        return (zeroIfNull(totalProductsProjected) * 60).divide(sum, 2, System.RoundingMode.HALF_UP);
    }

    /**
     * Sets each shift's sked_Max_Donor_Capacity__c and returns the drive-level total (caller
     * assigns it to sked_Drive__c.sked_Staff_Capacity__c - this class doesn't touch the drive
     * record). Requires shiftsMetadata.driveShifts to be in the
     * same order as proposedShifts (guaranteed - both come from the same buildProposedDriveShifts
     * pass), and each shift's lunch-break fields to already be populated by
     * skedMobileLunchBreakCalculator.populateLunchBreakTime.
     */
    public static Decimal updateDriveStaffCapacity(List<ProposedDriveShift> proposedShifts,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            Decimal numberOf2rbcAssets, String timezoneSidId, Decimal adhocDriverSupportCapacity) {
        if (staffingDecisionMatrix == null) {
            return 0;
        }
        Decimal driveStaffCapacity = 0;
        for (Integer i = 0; i < proposedShifts.size(); i++) {
            ProposedDriveShift proposed = proposedShifts[i];
            skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata = shiftsMetadata.driveShifts[i];
            Decimal shiftCapacity = skedMobileRoleQuantityCalculator.calculateDriveShiftStaffCapacity(proposed.jobs, shiftMetadata,
                staffingDecisionMatrix, numberOf2rbcAssets, timezoneSidId, false,
                proposed.shiftRecord.sked_Lunch_Break__c, proposed.shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c, adhocDriverSupportCapacity);
            proposed.shiftRecord.sked_Max_Donor_Capacity__c = shiftCapacity;
            driveStaffCapacity += shiftCapacity;
        }
        return driveStaffCapacity;
    }

    // ===== Restore-unchanged-quantity =====

    // Public - also reused by skedMobileRoleQuantityCalculator's Driver-Support adhoc-capacity fallback.
    public static final String MANUALLY_CREATED_FROM_STAFFING_MODAL = 'Staffing Modal';

    /**
     * When NO system-role job anywhere on the drive shows a systemQuantity change relative to its
     * persisted value, every eligible job's quantity/systemQuantity/vphhQuantity/aptQuantity is
     * restored from its persisted value instead of the freshly computed one - preserving a user's
     * manually-bumped-above-system-minimum quantity that a same-system-quantity regen would
     * otherwise silently overwrite. isDriveGettingRegenerated is true only when 'regenerateDrive'
     * is an applied token - the gate's own comparisons are skipped entirely (forced "changed")
     * whenever it's true, so a genuine regenerate always uses the freshly computed quantity.
     * `existingShifts` must carry sked_System_Quantity__c on sked_Jobs__r
     * (skedMobileDriveRegenEngine.loadExistingShiftsWithJobs).
     */
    public static void restoreUnchangedJobQuantities(List<ProposedDriveShift> proposed, List<sked_Drive_Shift__c> existingShifts,
            Decimal freshAptSetup, Decimal persistedAptQuantity, Boolean isDriveGettingRegenerated) {
        if (isDriveGettingRegenerated || hasAnySystemQuantityChange(proposed, existingShifts, freshAptSetup, persistedAptQuantity)) {
            return;
        }
        for (Integer i = 0; i < proposed.size() && i < existingShifts.size(); i++) {
            for (sked__Job__c job : proposed[i].jobs) {
                if (!isEligibleForQuantityRestore(job)) {
                    continue;
                }
                sked__Job__c existingJob = findJobBySameRole(job, existingShifts[i].sked_Jobs__r);
                if (existingJob == null) {
                    continue;
                }
                job.sked__Quantity__c = existingJob.sked__Quantity__c;
                job.sked_System_Quantity__c = existingJob.sked_System_Quantity__c;
                job.sked_VPHH_Quantity__c = existingJob.sked_VPHH_Quantity__c;
                job.sked_APT_Quantity__c = existingJob.sked_APT_Quantity__c;
            }
        }
    }

    // Eligibility filter: system role, resourceRole set, no dual role, never Driver/Driver Support -
    // those two roles are vehicle-count-driven and always recomputed regardless of this gate.
    private static Boolean isEligibleForQuantityRestore(sked__Job__c job) {
        if (String.isBlank(job.sked_Resource_Role__c) || String.isNotBlank(job.sked_Dual_Role__c)) {
            return false;
        }
        if (!MOBILE_SYSTEM_ROLES.contains(job.sked_Resource_Role__c)) {
            return false;
        }
        return job.sked_Resource_Role__c != ROLE_DRIVER && job.sked_Resource_Role__c != ROLE_DRIVER_SUPPORT;
    }

    // Collapsed to a boolean - the gate only ever checks whether newJobs/changedJobs/deletedJobs is
    // non-empty, never their contents.
    private static Boolean hasAnySystemQuantityChange(List<ProposedDriveShift> proposed, List<sked_Drive_Shift__c> existingShifts,
            Decimal freshAptSetup, Decimal persistedAptQuantity) {
        for (Integer i = 0; i < proposed.size(); i++) {
            List<sked__Job__c> existingJobs = i < existingShifts.size() ? existingShifts[i].sked_Jobs__r : null;
            for (sked__Job__c job : proposed[i].jobs) {
                if (!isSystemGeneratedGateCandidate(job)) {
                    continue;
                }
                sked__Job__c existingJob = existingJobs == null ? null : findJobBySameRole(job, existingJobs);
                if (existingJob == null || systemQuantityChanged(job, existingJob, freshAptSetup, persistedAptQuantity)) {
                    return true; // newJobs / changedJobs
                }
            }
        }
        for (Integer i = 0; i < existingShifts.size(); i++) {
            List<sked__Job__c> proposedJobs = i < proposed.size() ? proposed[i].jobs : null;
            for (sked__Job__c existingJob : existingShifts[i].sked_Jobs__r) {
                if (!isSystemGeneratedGateCandidate(existingJob)) {
                    continue;
                }
                if (proposedJobs == null || findJobBySameRole(existingJob, proposedJobs) == null) {
                    return true; // deletedJobs
                }
            }
        }
        return false;
    }

    private static Boolean isSystemGeneratedGateCandidate(sked__Job__c job) {
        if (job.sked_Is_Manually_Created__c == true && job.sked_Manually_Created_From__c == MANUALLY_CREATED_FROM_STAFFING_MODAL) {
            return false;
        }
        return String.isNotBlank(job.sked_Resource_Role__c) && MOBILE_SYSTEM_ROLES.contains(job.sked_Resource_Role__c);
    }

    // VP/HH nets out the job's own aptQuantity from its systemQuantity against the DRIVE-level APT
    // setup (fresh: shiftsMetadata.aptSetup: persisted: drive.sked_APT_Quantity__c) before comparing
    // - a plain systemQuantity comparison for every other role.
    private static Boolean systemQuantityChanged(sked__Job__c freshJob, sked__Job__c existingJob, Decimal freshAptSetup, Decimal persistedAptQuantity) {
        if (freshJob.sked_Resource_Role__c == ROLE_VPHH) {
            Boolean freshHasApt = positive(freshJob.sked_APT_Quantity__c);
            Boolean existingHasApt = positive(existingJob.sked_APT_Quantity__c);
            if (freshHasApt != existingHasApt) {
                return true;
            }
            if (freshHasApt && existingHasApt && freshJob.sked_APT_Quantity__c != existingJob.sked_APT_Quantity__c) {
                return true;
            }
            Decimal freshVphhSystemQuantity = maxOfZero(zeroIfNull(freshJob.sked_System_Quantity__c) - zeroIfNull(freshAptSetup));
            Decimal existingVphhSystemQuantity = maxOfZero(zeroIfNull(existingJob.sked_System_Quantity__c) - zeroIfNull(persistedAptQuantity));
            return freshVphhSystemQuantity != existingVphhSystemQuantity;
        }
        return freshJob.sked_System_Quantity__c != existingJob.sked_System_Quantity__c;
    }

    private static Decimal maxOfZero(Decimal value) {
        return value < 0 ? 0 : value;
    }

    // Plain resourceRole+dualRole equality, no manual-flag distinction (unlike findMatchingExistingJob
    // below, which the gate/restore never use).
    private static Boolean isSameRoleAndDualRole(sked__Job__c job1, sked__Job__c job2) {
        return job1.sked_Resource_Role__c == job2.sked_Resource_Role__c
            && blankToEmpty(job1.sked_Dual_Role__c) == blankToEmpty(job2.sked_Dual_Role__c);
    }

    private static sked__Job__c findJobBySameRole(sked__Job__c job, List<sked__Job__c> candidates) {
        if (candidates == null) {
            return null;
        }
        for (sked__Job__c candidate : candidates) {
            if (isSameRoleAndDualRole(job, candidate)) {
                return candidate;
            }
        }
        return null;
    }

    // ===== Existing-record carry-forward =====

    /**
     * Mutates proposed in place: sets shiftRecord.Id/job.Id wherever a matching existing record is
     * found, so skedDriveGraphSaver updates real records instead of inserting duplicates. Shifts
     * pair by array position only (existingDriveShifts[i] <-> proposed[i]) - never by start/end
     * time, exactly as the source does. existingDriveShifts must have sked_Jobs__r populated
     * (Id, sked_Resource_Role__c, sked_Dual_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c,
     * sked_Equipment_Subtype__c) for job matching. Manually-created-job preservation is a separate,
     * earlier-running step - see preserveManuallyCreatedJobsForAllShifts, below.
     */
    public static void applyExistingRecordIds(List<ProposedDriveShift> proposed, List<sked_Drive_Shift__c> existingDriveShifts) {
        for (Integer i = 0; i < proposed.size() && i < existingDriveShifts.size(); i++) {
            sked_Drive_Shift__c existingShift = existingDriveShifts[i];
            proposed[i].shiftRecord.Id = existingShift.Id;

            for (sked__Job__c proposedJob : proposed[i].jobs) {
                // Already Id-stamped by preserveManuallyCreatedJobs, which ran earlier - must never
                // be re-matched here. findMatchingExistingJob only excludes manually-created
                // CANDIDATES, not a manually-created PROBE, so without this guard a manually-created
                // job sharing a role with a system-generated job would have its real Id overwritten
                // by the system job's Id, leaving two jobs with the same Id.
                if (proposedJob.Id != null) {
                    continue;
                }
                sked__Job__c matchedJob = findMatchingExistingJob(proposedJob, existingShift.sked_Jobs__r);
                if (matchedJob != null) {
                    proposedJob.Id = matchedJob.Id;
                }
            }
        }

        mergeForwardJobTags(proposed);
    }

    // Manually-created jobs are merged in before capacity/slot generation run, so those steps
    // already reflect a manual job's contribution. Must run before those steps, separately from
    // applyExistingRecordIds (whose Id-stamping pass belongs later, once slots/capacity are settled
    // - moving it earlier would just re-run it for no benefit).
    public static void preserveManuallyCreatedJobsForAllShifts(List<ProposedDriveShift> proposed, List<sked_Drive_Shift__c> existingDriveShifts) {
        preserveManuallyCreatedJobsForAllShifts(proposed, existingDriveShifts, new ManualJobPreservationConfig());
    }

    /**
     * Which roles this drive type's engine generates itself, and whether a zero-quantity manual job
     * still carries forward - both differ per drive type (helper.js:3544-3555's three isSystemRole
     * branches, and only Mobile's own populateDriveShiftJobs filters the concat on quantity > 0).
     */
    public class ManualJobPreservationConfig {
        public Set<String> systemResourceRoles = MOBILE_SYSTEM_ROLES;
        public Boolean requirePositiveQuantity = true;
    }

    public static void preserveManuallyCreatedJobsForAllShifts(List<ProposedDriveShift> proposed, List<sked_Drive_Shift__c> existingDriveShifts,
            ManualJobPreservationConfig config) {
        for (Integer i = 0; i < proposed.size() && i < existingDriveShifts.size(); i++) {
            preserveManuallyCreatedJobs(proposed[i], existingDriveShifts[i].sked_Jobs__r, config);
        }
    }

    private static final List<String> VPHH_RECALC_ROLES = new List<String>{ ROLE_DRIVER, ROLE_DRIVER_SUPPORT, ROLE_2RBC, 'Charge' };

    /**
     * Recomputes VP/HH quantity to fill the capacity gap a manually-preserved job leaves behind -
     * ported from mobileGenerator.js's recalculateVphhQuantity (called inline right after the manual-
     * job merge, mobileGenerator.js:2136-2163) and isRoleHoldCapacity (helper.js:4278-4305), which
     * gates whether it's even worth calling. Must run after preserveManuallyCreatedJobsForAllShifts
     * (needs the merged job list) and before recalculateLunchBreakForAllShifts - VP/HH participates
     * in that pass's staff-count bucket via skedMobileLunchBreakCalculator's STAFF_SETUP_ROLES
     * whitelist, and that pass already re-runs populateShiftTime unconditionally, covering any job
     * this method adds/removes/changes without needing a third populateShiftTime pass here.
     */
    public static void recalculateVphhQuantityForAllShifts(List<ProposedDriveShift> proposed, skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            sked_Drive__c drive, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, Decimal numberOf2rbcAssets, String timezoneSidId,
            Decimal adhocDriverSupportCapacity) {
        if (staffingDecisionMatrix == null) {
            return;
        }
        Map<String, String> groupByRole = buildGroupByRoleLookup();
        for (Integer i = 0; i < proposed.size() && i < shiftsMetadata.driveShifts.size(); i++) {
            ProposedDriveShift shift = proposed[i];
            if (!anyManuallyCreatedJobHoldsCapacity(shift, staffingDecisionMatrix, adhocDriverSupportCapacity)) {
                continue;
            }
            recalculateVphhQuantity(shift, shiftsMetadata.driveShifts[i], drive, staffingDecisionMatrix, numberOf2rbcAssets, timezoneSidId,
                adhocDriverSupportCapacity, groupByRole);
        }
    }

    // Gate: does ANY manually-created (non-Staffing-Modal, non-VP/HH) job on this shift hold real
    // capacity via its resourceRole or dualRole? Mirrors mobileGenerator.js:2138-2148's inline find().
    private static Boolean anyManuallyCreatedJobHoldsCapacity(ProposedDriveShift shift, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix,
            Decimal adhocDriverSupportCapacity) {
        for (sked__Job__c job : shift.jobs) {
            if (job.sked_Resource_Role__c == ROLE_VPHH || !isManuallyCreatedJob(job)
                    || job.sked_Manually_Created_From__c == MANUALLY_CREATED_FROM_STAFFING_MODAL) {
                continue;
            }
            if (isRoleHoldCapacity(job.sked_Resource_Role__c, true, job.sked_Manually_Created_From__c, staffingDecisionMatrix, adhocDriverSupportCapacity)
                    || isRoleHoldCapacity(job.sked_Dual_Role__c, true, job.sked_Manually_Created_From__c, staffingDecisionMatrix, adhocDriverSupportCapacity)) {
                return true;
            }
        }
        return false;
    }

    // Ported from helper.js's isRoleHoldCapacity - same Driver-Support adhoc-capacity fallback as
    // skedMobileRoleQuantityCalculator.calculateStaffCapacity, applied here to a single role/job
    // rather than an aggregated resourceQuantityMap entry.
    private static Boolean isRoleHoldCapacity(String resourceRole, Boolean isManuallyCreated, String manuallyCreatedFrom,
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, Decimal adhocDriverSupportCapacity) {
        if (String.isBlank(resourceRole)) {
            return false;
        }
        Decimal roleCapacity = skedMobileRoleQuantityCalculator.getCapacityForRole(staffingDecisionMatrix, resourceRole);
        if (resourceRole == ROLE_DRIVER_SUPPORT && roleCapacity <= 0 && isManuallyCreated == true
                && manuallyCreatedFrom != MANUALLY_CREATED_FROM_STAFFING_MODAL) {
            roleCapacity = adhocDriverSupportCapacity == null ? 0 : adhocDriverSupportCapacity;
        }
        return roleCapacity > 0;
    }

    private static void recalculateVphhQuantity(ProposedDriveShift shift, skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata,
            sked_Drive__c drive, sked_Staffing_Decision_Matrix__c staffingDecisionMatrix, Decimal numberOf2rbcAssets, String timezoneSidId,
            Decimal adhocDriverSupportCapacity, Map<String, String> groupByRole) {
        if (staffingDecisionMatrix.sked_VP_HH_Capacity__c == null || staffingDecisionMatrix.sked_VP_HH_Capacity__c <= 0) {
            return;
        }

        Map<String, skedMobileRoleQuantityCalculator.RoleQuantity> resourceQuantityMap = skedMobileRoleQuantityCalculator.buildResourceQuantityFromJobs(shift.jobs);
        Decimal staffCapacity = skedMobileRoleQuantityCalculator.calculateStaffCapacity(VPHH_RECALC_ROLES, resourceQuantityMap, shiftMetadata,
            staffingDecisionMatrix, numberOf2rbcAssets, timezoneSidId, false, adhocDriverSupportCapacity);

        Decimal vpHhCapacity = staffingDecisionMatrix.sked_VP_HH_Capacity__c;
        Decimal totalVpHhCapacity = zeroIfNull(shiftMetadata.donorsScheduled) - staffCapacity;
        if (totalVpHhCapacity < 0) {
            totalVpHhCapacity = 0;
        }

        Decimal drawHours = skedMobileRoleQuantityCalculator.calculateShiftDrawHours(shiftMetadata, timezoneSidId);
        Integer noOfVpHhStaffs = 0;
        if (totalVpHhCapacity > 0 && drawHours != null && drawHours > 0) {
            // totalVpHhCapacity / (vpHhCapacity * drawHours) via a single safe-scale divide() - see
            // calculateDriveProductivityPlanned's header for why plain Decimal '/' risks MathException.
            Decimal ratio = totalVpHhCapacity.divide(vpHhCapacity * drawHours, 10, System.RoundingMode.HALF_UP);
            noOfVpHhStaffs = Math.ceil(ratio).intValue();
        }

        sked__Job__c existingVphhJob;
        for (sked__Job__c job : shift.jobs) {
            if (job.sked_Resource_Role__c == ROLE_VPHH && String.isBlank(job.sked_Dual_Role__c)) {
                existingVphhJob = job;
                break;
            }
        }
        if (existingVphhJob != null && existingVphhJob.sked_Manually_Created_From__c == MANUALLY_CREATED_FROM_STAFFING_MODAL) {
            return;
        }

        if (noOfVpHhStaffs > 0) {
            if (existingVphhJob != null) {
                existingVphhJob.sked_VPHH_Quantity__c = noOfVpHhStaffs;
                existingVphhJob.sked__Quantity__c = noOfVpHhStaffs + zeroIfNull(existingVphhJob.sked_APT_Quantity__c);
                existingVphhJob.sked_System_Quantity__c = existingVphhJob.sked__Quantity__c;
            } else {
                skedMobileRoleQuantityCalculator.RoleQuantity newVphhQuantity = new skedMobileRoleQuantityCalculator.RoleQuantity();
                newVphhQuantity.vphhQuantity = noOfVpHhStaffs;
                newVphhQuantity.aptQuantity = 0;
                newVphhQuantity.quantity = noOfVpHhStaffs;
                sked__Job__c newJob = buildRoleJob(ROLE_VPHH, null, newVphhQuantity, drive, groupByRole, shiftMetadata.resourceRoleGroupRoleTimeDataMap);
                if (newJob != null) {
                    shift.jobs.add(newJob);
                }
            }
        } else if (existingVphhJob != null) {
            if (positive(existingVphhJob.sked_APT_Quantity__c)) {
                existingVphhJob.sked_VPHH_Quantity__c = 0;
                existingVphhJob.sked__Quantity__c = existingVphhJob.sked_APT_Quantity__c;
                existingVphhJob.sked_System_Quantity__c = existingVphhJob.sked__Quantity__c;
            } else {
                shift.jobs.remove(shift.jobs.indexOf(existingVphhJob));
            }
        }
    }

    /**
     * buildProposedDriveShifts already populated lunch-break fields once, against the pre-manual-job
     * list - needed at that point since populateShiftTime (also inside buildProposedDriveShifts)
     * reads sked_Lunch_Break_Duration__c for the before-draw-hours case. But the other case's
     * duration comes from a staff-count bucket lookup, so it must be recomputed here, after
     * preserveManuallyCreatedJobsForAllShifts, once the job list actually reflects a preserved
     * manual job's contribution to that count.
     *
     * This is also the only pass that can be lock/restore-aware (existingDriveShifts isn't loaded
     * yet during buildProposedDriveShifts - see that call site) - existingDriveShifts is matched to
     * `proposed` purely by array position, same convention as applyExistingRecordIds/
     * preserveManuallyCreatedJobsForAllShifts. Since a restore can change a shift's lunch-break
     * flags after buildProposedDriveShifts already sized each job's start/finish envelope around the
     * PRE-restore flags, populateShiftTime is re-run here for every shift - mirroring
     * mobileGenerator.js's own action list, where populateLunchBreakTime and populateShiftTime always
     * run back-to-back as a pair, not just once at initial build.
     */
    public static void recalculateLunchBreakForAllShifts(List<ProposedDriveShift> proposed,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig, String timezoneSidId,
            Boolean lockLunchBreak, List<sked_Drive_Shift__c> existingDriveShifts) {
        recalculateLunchBreakForAllShifts(proposed, shiftsMetadata, lunchBreakSettingsConfig, timezoneSidId, lockLunchBreak,
            existingDriveShifts, null);
    }

    // A null `staffSetupRoles` means Mobile's own list - see buildProposedDriveShifts' header.
    public static void recalculateLunchBreakForAllShifts(List<ProposedDriveShift> proposed,
            skedMobileDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig, String timezoneSidId,
            Boolean lockLunchBreak, List<sked_Drive_Shift__c> existingDriveShifts, List<String> staffSetupRoles) {
        for (Integer i = 0; i < proposed.size() && i < shiftsMetadata.driveShifts.size(); i++) {
            sked_Drive_Shift__c existingShiftRecord = (existingDriveShifts != null && i < existingDriveShifts.size()) ? existingDriveShifts[i] : null;
            populateLunchBreakTime(proposed[i], shiftsMetadata.driveShifts[i], lunchBreakSettingsConfig, timezoneSidId,
                lockLunchBreak, existingShiftRecord, staffSetupRoles);
            populateShiftTime(proposed[i], timezoneSidId);
        }
    }

    // For each carried-forward job (real Id assigned above), add forward any of the EXISTING job's
    // systemCreated, non-Physical-Location-Type tags not already present (by Tag Id) in the job's
    // freshly assigned tag set (assignFreshJobTags, called earlier during buildProposedDriveShifts).
    // Physical Location Type tags are always re-derived fresh from the drive's own site/CO, never
    // carried forward from a prior regeneration.
    private static void mergeForwardJobTags(List<ProposedDriveShift> proposed) {
        List<Id> carriedForwardJobIds = new List<Id>();
        for (ProposedDriveShift shift : proposed) {
            for (sked__Job__c job : shift.jobs) {
                if (job.Id != null) {
                    carriedForwardJobIds.add(job.Id);
                }
            }
        }
        if (carriedForwardJobIds.isEmpty()) {
            return;
        }

        Map<Id, List<sked__Job_Tag__c>> existingTagsByJobId = skedMobileJobTagLoader.loadForJobs(carriedForwardJobIds);
        for (ProposedDriveShift shift : proposed) {
            for (Integer i = 0; i < shift.jobs.size(); i++) {
                sked__Job__c job = shift.jobs[i];
                if (job.Id == null || !existingTagsByJobId.containsKey(job.Id)) {
                    continue;
                }

                List<sked__Job_Tag__c> jobTags = shift.jobTagsByJobIndex.get(i);
                if (jobTags == null) {
                    jobTags = new List<sked__Job_Tag__c>();
                    shift.jobTagsByJobIndex.put(i, jobTags);
                }
                Set<Id> tagIdsAlreadyPresent = new Set<Id>();
                for (sked__Job_Tag__c jobTag : jobTags) {
                    tagIdsAlreadyPresent.add(jobTag.sked__Tag__c);
                }

                for (sked__Job_Tag__c existingJobTag : existingTagsByJobId.get(job.Id)) {
                    Boolean isSystemCreated = existingJobTag.sked_SystemCreated__c == true;
                    Boolean isPhysicalLocationType = existingJobTag.sked__Tag__r.sked__Type__c == skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE;
                    if (!isSystemCreated || isPhysicalLocationType || tagIdsAlreadyPresent.contains(existingJobTag.sked__Tag__c)) {
                        continue;
                    }
                    jobTags.add(new sked__Job_Tag__c(sked__Tag__c = existingJobTag.sked__Tag__c));
                    tagIdsAlreadyPresent.add(existingJobTag.sked__Tag__c);
                }
            }
        }
    }

    // Unconditional on every regen, NOT gated behind the modal-only staffingComplementChanged path
    // (that's a different mechanism: backupDualRolesMap/restoreDualRoles, deferred separately in
    // skedMobileDualRoleGenerator). Without this, any existing job whose role isn't one of the
    // system-generatable roles (a genuinely manually-added one-off role, or any job predating
    // sked_Is_Manually_Created__c being tracked) silently drops out of the regenerated graph.
    // recalculateVphhQuantityForAllShifts (below) handles the VP/HH-recompute consequence of a
    // preserved manually-created job holding capacity - see its own header for why it must run after this.
    private static void preserveManuallyCreatedJobs(ProposedDriveShift shift, List<sked__Job__c> existingJobs, ManualJobPreservationConfig config) {
        if (existingJobs == null) {
            return;
        }
        for (sked__Job__c existingJob : existingJobs) {
            if (!isManuallyCreatedJob(existingJob, config.systemResourceRoles)) {
                continue;
            }
            if (config.requirePositiveQuantity == true && !positive(existingJob.sked__Quantity__c)) {
                continue;
            }
            // Run in reverse: does this manually-created existing job's role already have a fresh,
            // system-generated counterpart in the proposed list?
            if (findMatchingProposedJobForManualCandidate(existingJob, shift.jobs) != null) {
                continue;
            }
            // Consumed via dual role: a proposed job's dualRole equals this existing job's plain role.
            Boolean isConsumedViaDualRole = false;
            for (sked__Job__c proposedJob : shift.jobs) {
                if (proposedJob.sked_Dual_Role__c == existingJob.sked_Resource_Role__c) {
                    isConsumedViaDualRole = true;
                    break;
                }
            }
            if (isConsumedViaDualRole) {
                continue;
            }

            shift.jobs.add(new sked__Job__c(
                Id = existingJob.Id,
                sked_Resource_Role__c = existingJob.sked_Resource_Role__c,
                sked_Dual_Role__c = existingJob.sked_Dual_Role__c,
                sked_Asset_Type__c = existingJob.sked_Asset_Type__c,
                sked_Equipment_Subtype__c = existingJob.sked_Equipment_Subtype__c,
                sked_Volunteer_Role__c = existingJob.sked_Volunteer_Role__c,
                sked_Redcross_Volunteer_Quantity__c = existingJob.sked_Redcross_Volunteer_Quantity__c,
                sked_Sponsor_Volunteer_Quantity__c = existingJob.sked_Sponsor_Volunteer_Quantity__c,
                sked__Quantity__c = existingJob.sked__Quantity__c,
                sked_VPHH_Quantity__c = existingJob.sked_VPHH_Quantity__c,
                sked_APT_Quantity__c = existingJob.sked_APT_Quantity__c,
                sked_System_Quantity__c = existingJob.sked__Quantity__c,
                sked_Is_Manually_Created__c = true,
                sked_Manually_Created_From__c = existingJob.sked_Manually_Created_From__c
            ));
        }
    }

    // helper.js:3549-3550's Mobile branch, and ManualJobPreservationConfig's default. The flag alone
    // isn't trusted because data migration never tracked sked_Is_Manually_Created__c: a role that isn't
    // one of these system-generatable roles is treated as manually created regardless of the flag.
    private static final Set<String> MOBILE_SYSTEM_ROLES = new Set<String>{
        ROLE_DRIVER, ROLE_DRIVER_SUPPORT, ROLE_2RBC, 'Drive Lead', 'Team Supervisor', 'Charge', ROLE_VPHH
    };

    private static Boolean isManuallyCreatedJob(sked__Job__c job) {
        return isManuallyCreatedJob(job, MOBILE_SYSTEM_ROLES);
    }

    private static Boolean isManuallyCreatedJob(sked__Job__c job, Set<String> systemResourceRoles) {
        if (job.sked_Is_Manually_Created__c == true) {
            return true;
        }
        if (String.isNotBlank(job.sked_Resource_Role__c)) {
            return !systemResourceRoles.contains(job.sked_Resource_Role__c);
        }
        // A volunteer job is a system role like any other in MOBILE_SYSTEM_ROLES (this engine now
        // computes its quantity) - only an explicit sked_Is_Manually_Created__c flag (checked above)
        // makes one manually created. An asset job is always a system role.
        if (String.isNotBlank(job.sked_Volunteer_Role__c)) {
            return false;
        }
        return job.sked_Asset_Type__c == null;
    }

    // For a role job, match same resourceRole+dualRole among non-manually-created existing jobs. For a
    // volunteer job, match same volunteerRole. For an asset job, match same assetType (+
    // equipmentSubtype when Equipment). Only valid when
    // `proposedJob` itself is non-manually-created - applyExistingRecordIds enforces this by skipping
    // any proposed job that already has an Id (a manually-preserved job stamped earlier by
    // preserveManuallyCreatedJobs) before ever calling this. preserveManuallyCreatedJobs's own reverse
    // probe goes through findMatchingProposedJobForManualCandidate instead (a manually-created probe
    // only ever matches an equally-manually-created candidate with the same manuallyCreatedFrom -
    // never one of these non-manual candidates).
    private static sked__Job__c findMatchingExistingJob(sked__Job__c proposedJob, List<sked__Job__c> existingJobs) {
        if (existingJobs == null) {
            return null;
        }
        if (String.isNotBlank(proposedJob.sked_Resource_Role__c)) {
            for (sked__Job__c existingJob : existingJobs) {
                if (String.isBlank(existingJob.sked_Resource_Role__c) || existingJob.sked_Is_Manually_Created__c) {
                    continue;
                }
                if (existingJob.sked_Resource_Role__c == proposedJob.sked_Resource_Role__c
                        && blankToEmpty(existingJob.sked_Dual_Role__c) == blankToEmpty(proposedJob.sked_Dual_Role__c)) {
                    return existingJob;
                }
            }
            return null;
        }
        if (String.isNotBlank(proposedJob.sked_Volunteer_Role__c)) {
            for (sked__Job__c existingJob : existingJobs) {
                if (String.isBlank(existingJob.sked_Volunteer_Role__c) || existingJob.sked_Is_Manually_Created__c) {
                    continue;
                }
                if (existingJob.sked_Volunteer_Role__c == proposedJob.sked_Volunteer_Role__c) {
                    return existingJob;
                }
            }
            return null;
        }
        if (proposedJob.sked_Asset_Type__c != null) {
            for (sked__Job__c existingJob : existingJobs) {
                if (existingJob.sked_Asset_Type__c != proposedJob.sked_Asset_Type__c) {
                    continue;
                }
                if (proposedJob.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT
                        && existingJob.sked_Equipment_Subtype__c != proposedJob.sked_Equipment_Subtype__c) {
                    continue;
                }
                return existingJob;
            }
        }
        return null;
    }

    private static String blankToEmpty(String value) {
        return value == null ? '' : value;
    }

    // A manually-created probe only ever matches a candidate that is ALSO manually created (with the
    // same manuallyCreatedFrom). Our freshly built proposed jobs are never manually created, so this
    // always returns null when called from preserveManuallyCreatedJobs's reverse probe - meaning a
    // user-added duplicate-role job (manually created, same role as a system-generated job) is
    // correctly treated as NOT already covered, instead of being matched against - and silently
    // dropped in favor of - the unrelated system-generated job of that same role.
    private static sked__Job__c findMatchingProposedJobForManualCandidate(sked__Job__c manualJob, List<sked__Job__c> proposedJobs) {
        return null;
    }

    // ===== Shift-level setup rollups =====

    /**
     * Must run after applyExistingRecordIds (preserveManuallyCreatedJobs runs inside it) so a
     * Staffing-Modal-manual job is present in `shift.jobs` and can be excluded here, matching the
     * excludeManuallyCreatedFromStaffingModal filter applied before every rollup below. The
     * drive-level Total_Staff/Equipment/Vehicle_Requested__c fields need no Apex write at all -
     * they're roll-up summary fields on sked_Staff_Setup__c/sked_Equipment__c/
     * sked_Vehicles_Needed__c below, computed by the platform once the shift records are saved.
     *
     * Volunteer_Setup__c sums any job with neither a resourceRole nor an assetType - in practice
     * always the fresh buildVolunteerJob job (built every regen when required+quantity are positive;
     * isManuallyCreatedJob treats an ordinary volunteer job as system-generated, so
     * preserveManuallyCreatedJobs's fallback never carries one forward - see that method's header).
     * Never double-counted for the same shift/role: findMatchingExistingJob's volunteer branch matches a fresh job to its existing
     * counterpart by role before this runs, so there's exactly one job per volunteer role here, not a
     * double-count. Previously hardcoded to 0 on every regen, which zeroed a real volunteer job's
     * contribution even though the job itself survived in shift.jobs - a live data-correctness bug,
     * fixed independently of (and before) volunteer-job creation itself being wired in
     * (mobileGenerator.js's own accumulator, updateShiftMobileSetup at baseGenerator.js:657-684, sums
     * job.quantity the same way).
     */
    public static void applyShiftSetupRollups(List<ProposedDriveShift> proposed, Set<String> staffSetupExcludedRoleNames) {
        for (ProposedDriveShift shift : proposed) {
            Decimal shiftStaffSetup = 0;
            Decimal shiftAptSetup = 0;
            Decimal shiftVehiclesNeeded = 0;
            Decimal shiftEquipment = 0;
            Decimal shiftVolunteerSetup = 0;
            for (sked__Job__c job : shift.jobs) {
                if (isManuallyCreatedFromStaffingModal(job)) {
                    continue;
                }
                Decimal quantity = job.sked__Quantity__c == null ? 0 : job.sked__Quantity__c;
                if (String.isNotBlank(job.sked_Resource_Role__c)) {
                    if (!staffSetupExcludedRoleNames.contains(job.sked_Resource_Role__c)) {
                        shiftStaffSetup += quantity;
                    }
                    shiftAptSetup += job.sked_APT_Quantity__c == null ? 0 : job.sked_APT_Quantity__c;
                } else if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                    shiftVehiclesNeeded += quantity;
                } else if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                    shiftEquipment += quantity;
                } else {
                    shiftVolunteerSetup += quantity;
                }
            }
            shift.shiftRecord.sked_Staff_Setup__c = shiftStaffSetup;
            shift.shiftRecord.sked_APT_Setup__c = shiftAptSetup;
            shift.shiftRecord.sked_Vehicles_Needed__c = shiftVehiclesNeeded;
            shift.shiftRecord.sked_Equipment__c = shiftEquipment;
            shift.shiftRecord.sked_Volunteer_Setup__c = shiftVolunteerSetup;
        }
    }

    private static Boolean isManuallyCreatedFromStaffingModal(sked__Job__c job) {
        return job.sked_Is_Manually_Created__c == true && job.sked_Manually_Created_From__c == MANUALLY_CREATED_FROM_STAFFING_MODAL;
    }
}
