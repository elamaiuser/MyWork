/**
 * Builds the NEW-drive-shape shift + job records (in-memory, not yet inserted) for a real (not WB)
 * Fixed Site drive regeneration. Mirrors skedMobileDriveJobBuilder's own structure per this ticket's
 * Global Constraints, not a line-by-line port of fixedSiteGenerator.js - Fixed Site has no legacy
 * interactive-Apex equivalent to compare against, and this class was built from the Mobile Apex
 * sibling plus the already-ported skedFixedSiteDriveShiftCalculator/skedFixedSiteRoleQuantityCalculator/
 * skedFixedSiteVolunteerCalculator inputs, not from a fresh JS read.
 *
 * A sibling of skedMobileDriveJobBuilder, not a subtype/reuse of it - Fixed Site has no dual role,
 * no VP/HH, and no APT concept, so its RoleQuantity/ProposedDriveShift/job-building logic is
 * structurally simpler and kept in its own copy rather than threading Mobile-only branches through
 * shared code.
 *
 * Scope: builds shift + job records from the shift metadata (skedFixedSiteDriveShiftCalculator),
 * role quantities (skedFixedSiteRoleQuantityCalculator), asset quantities (also
 * skedFixedSiteRoleQuantityCalculator.calculateAssetQuantity), and volunteer quantities
 * (skedFixedSiteVolunteerCalculator) already computed by the caller. Applies role-time to each role
 * job and computes each job/shift's start-finish envelope (populateShiftTime).
 *
 * Deliberately NOT done here: lunch-break field population. shiftMetadata.lunchBreakSettings (set by
 * skedFixedSiteDriveShiftCalculator.calculateDriveShiftsMetadata) only carries the derived
 * lunchBreak/lunchBreakBeforeDrawHours/maximumLunchBreakDuration flags - it never writes the shift
 * record's own sked_Lunch_Break__c/sked_Lunch_Break_Duration__c/etc. fields. That write is
 * skedLunchBreakCalculator.populateLunchBreakTime's job, which needs this class's already-built
 * `proposed.jobs` (for its staff-count lookup) as an input - a future engine task calls it after this
 * builder runs and re-runs populateShiftTime afterward, mirroring skedMobileDriveJobBuilder's own
 * two-pass buildProposedDriveShifts/recalculateLunchBreakForAllShifts split. Until that task lands,
 * populateShiftTime below runs once against an unset (false/null) lunch-break shift record, which is
 * the correct pre-lunch-break-wiring state, not a bug.
 *
 * Also deliberately NOT ported here, even though existing-record carry-forward
 * (applyExistingRecordIds/preserveManuallyCreatedJobsForAllShifts, below) now lands in this class:
 * the volunteer quantity's "retain if zero/locked" carry-forward (per the HRP-10153 JS parity
 * review, fixedSiteGenerator.js:1299-1320, HRP-10534/HRP-13119) - it lives inside JS's
 * job-population step, not a post-build merge, and needs existing shifts threaded into
 * buildProposedDriveShifts itself, not just merged in afterward; and manual role-quantity
 * carry-forward (fixedSiteGenerator.js:928-933) - needs skedFixedSiteRoleQuantityCalculator.RoleQuantity
 * to carry isManuallyCreated/manuallyCreatedFrom, which it doesn't today. Both remain future tasks.
 */
public with sharing class skedFixedSiteDriveJobBuilder {

    public class ProposedDriveShift extends skedProposedDriveShift {
        // Populated by skedFixedSiteSlotGenerator, a later step - never set here.
        public List<sked__Slot__c> slots = new List<sked__Slot__c>();
        // Each freshly built job's starting (unsaved) tag set, keyed by that job's index within
        // `jobs` (jobs have no Id yet at build time). Mirrors
        // skedMobileDriveJobBuilder.ProposedDriveShift's own field - this class never carries
        // jobAllocationsByJobId since Fixed Site's job-allocation carry-forward isn't in scope here.
        public Map<Integer, List<sked__Job_Tag__c>> jobTagsByJobIndex = new Map<Integer, List<sked__Job_Tag__c>>();
    }

    private static final String ASSET_MAP_KEY_VEHICLE = 'Vehicle';
    private static final String ASSET_MAP_KEY_2RBC_EQUIPMENT = 'Equipment - 2RBC Asset';
    private static final String EQUIPMENT_SUBTYPE_2RBC_ASSET = '2RBC Asset';
    private static final String MANUALLY_CREATED_FROM_STAFFING_MODAL = 'Staffing Modal';

    public static List<ProposedDriveShift> buildProposedDriveShifts(sked_Drive__c drive,
            skedFixedSiteDriveShiftCalculator.DriveShiftsMetadata shiftsMetadata,
            Map<String, Map<String, skedFixedSiteRoleQuantityCalculator.RoleQuantity>> roleQuantityByShiftKey,
            Map<String, Decimal> assetQuantityByType, Map<String, Integer> volunteerQuantityByShiftKey,
            Map<String, List<skedMobileDriveShiftCalculator.RequiredJobTag>> jobTagsByResourceType) {
        // Reused directly (public, drive-type-agnostic utility, not a dual-role/VP-HH concern) - see
        // skedMobileAssetReassigner's own cross-class call to loadJobTagsMap for precedent.
        Map<String, String> groupByRole = skedMobileDriveJobBuilder.buildGroupByRoleLookup();
        String timezoneSidId = UserInfo.getTimeZone().getID();

        List<ProposedDriveShift> proposedShifts = new List<ProposedDriveShift>();
        for (Integer i = 0; i < shiftsMetadata.driveShifts.size(); i++) {
            skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shiftMetadata = shiftsMetadata.driveShifts[i];
            ProposedDriveShift proposed = new ProposedDriveShift();
            proposed.shiftRecord = buildShiftRecord(shiftMetadata);

            Map<String, skedFixedSiteRoleQuantityCalculator.RoleQuantity> roleQuantities = roleQuantityByShiftKey.get(shiftMetadata.key);
            for (String role : roleQuantities.keySet()) {
                sked__Job__c job = buildRoleJob(role, roleQuantities.get(role), drive, groupByRole, shiftMetadata.resourceRoleGroupRoleTimeDataMap);
                if (job != null) {
                    proposed.jobs.add(job);
                }
            }

            sked__Job__c volunteerJob = buildVolunteerJob(volunteerQuantityByShiftKey.get(shiftMetadata.key), drive);
            if (volunteerJob != null) {
                proposed.jobs.add(volunteerJob);
            }

            // Only the first shift gets asset jobs - later shifts keep only role/volunteer jobs. Unlike
            // Mobile (which always builds a Vehicle job, even at quantity 0), Fixed Site's own JS gates
            // every asset job - Vehicle included - on a positive quantity (per the HRP-10153 JS parity
            // review, fixedSiteGenerator.js:1323-1324).
            if (i == 0) {
                Decimal vehicleQuantity = assetQuantityByType.get(ASSET_MAP_KEY_VEHICLE);
                if (positive(vehicleQuantity)) {
                    proposed.jobs.add(buildAssetJob(ASSET_MAP_KEY_VEHICLE, vehicleQuantity, drive));
                }
                Decimal equipmentQuantity = assetQuantityByType.get(ASSET_MAP_KEY_2RBC_EQUIPMENT);
                if (positive(equipmentQuantity)) {
                    proposed.jobs.add(buildAssetJob(ASSET_MAP_KEY_2RBC_EQUIPMENT, equipmentQuantity, drive));
                }
            }

            assignFreshJobTags(proposed, jobTagsByResourceType);
            populateShiftTime(proposed, timezoneSidId);
            proposedShifts.add(proposed);
        }
        return proposedShifts;
    }

    private static sked_Drive_Shift__c buildShiftRecord(skedFixedSiteDriveShiftCalculator.DriveShiftMetadata shiftMetadata) {
        return new sked_Drive_Shift__c(
            sked_Drive_Date__c = shiftMetadata.driveDate,
            sked_Start_Time__c = shiftMetadata.startTime,
            sked_End_Time__c = shiftMetadata.endTime,
            sked_2RBC_Projected_Procedures__c = shiftMetadata.x2rbcProjectedProcedures,
            sked_WB_Projected_Procedures__c = shiftMetadata.wbProjectedProcedures,
            sked_Platelet_Projected_Procedures__c = shiftMetadata.plateletProjectedProcedures,
            sked_Plasma_Projected_Procedures__c = shiftMetadata.plasmaProjectedProcedures,
            sked_Platelet_Rounds__c = shiftMetadata.numberOfRounds,
            sked_Total_Procedures_Projected__c = shiftMetadata.totalProceduresProjected,
            sked_Total_Products_Projected__c = shiftMetadata.totalProductsProjected
        );
    }

    // No dual-role, VP/HH, or APT branch - every Fixed Site role (Apheresis, Apheresis Charge) needs
    // only a positive quantity to emit a job.
    private static sked__Job__c buildRoleJob(String role, skedFixedSiteRoleQuantityCalculator.RoleQuantity roleQuantity, sked_Drive__c drive,
            Map<String, String> groupByRole, Map<String, skedRoleTimeData> resourceRoleGroupRoleTimeDataMap) {
        if (!positive(roleQuantity.quantity)) {
            return null;
        }

        sked__Job__c job = new sked__Job__c(
            sked_Resource_Role__c = role,
            sked__Location__c = drive.sked_Drive_Site__c,
            sked__Quantity__c = roleQuantity.quantity,
            sked_System_Quantity__c = roleQuantity.quantity,
            sked_Is_Manually_Created__c = false,
            sked__Job_Allocation_Time_Source__c = false
        );
        applyRoleTimeForSingleJob(job, role, groupByRole, resourceRoleGroupRoleTimeDataMap);
        return job;
    }

    // Simplified single-lookup (no maxOf-of-two-groups) - Fixed Site has no dual-role concept, so
    // there's only ever one role's group data to apply.
    private static void applyRoleTimeForSingleJob(sked__Job__c job, String role, Map<String, String> groupByRole,
            Map<String, skedRoleTimeData> resourceRoleGroupRoleTimeDataMap) {
        String resourceRoleGroup = groupByRole.get(role);
        skedRoleTimeData roleTimeData = resourceRoleGroup == null ? null : resourceRoleGroupRoleTimeDataMap.get(resourceRoleGroup);
        if (roleTimeData == null) {
            return;
        }

        job.sked_Lead_Time__c = roleTimeData.leadTime;
        job.sked_Travel_Time__c = roleTimeData.travelTime;
        job.sked_Site_Logistics_To__c = roleTimeData.siteLogisticsTo;
        job.sked_Setup_Time__c = roleTimeData.setupTime;
        job.sked_Breakdown_Time__c = roleTimeData.breakdownTime;
        job.sked_Travel_Time2__c = roleTimeData.travelTime2;
        job.sked_Site_Logistics_Back__c = roleTimeData.siteLogisticsBack;
        job.sked_Wrap_up_Time__c = roleTimeData.wrapUpTime;
    }

    // assetMapKey is one of skedFixedSiteRoleQuantityCalculator.calculateAssetQuantity's own map keys
    // ('Vehicle' or 'Equipment - 2RBC Asset') - the 2RBC key splits onto the job as
    // sked_Asset_Type__c = Equipment plus sked_Equipment_Subtype__c = '2RBC Asset', mirroring
    // skedMobileDriveJobBuilder.buildAssetJob's own Equipment-subtype split.
    private static sked__Job__c buildAssetJob(String assetMapKey, Decimal quantity, sked_Drive__c drive) {
        Decimal effectiveQuantity = quantity == null ? 0 : quantity;
        sked__Job__c job = new sked__Job__c(
            sked__Location__c = drive.sked_Drive_Site__c,
            sked__Quantity__c = effectiveQuantity,
            sked_System_Quantity__c = effectiveQuantity,
            sked_Is_Manually_Created__c = false
        );
        if (assetMapKey == ASSET_MAP_KEY_VEHICLE) {
            job.sked_Asset_Type__c = skedConstants.ASSET_TYPE_VEHICLE;
        } else if (assetMapKey == ASSET_MAP_KEY_2RBC_EQUIPMENT) {
            job.sked_Asset_Type__c = skedConstants.ASSET_TYPE_EQUIPMENT;
            job.sked_Equipment_Subtype__c = EQUIPMENT_SUBTYPE_2RBC_ASSET;
        }
        return job;
    }

    // Field pattern mirrors skedMobileDriveJobBuilder.buildVolunteerJob exactly - the only difference
    // is the quantity source: Fixed Site's volunteer quantity is per-shift
    // (skedFixedSiteVolunteerCalculator.calculateVolunteerQuantities), unlike Mobile's single
    // drive-wide redcrossVolunteerQuantity applied to every shift.
    private static sked__Job__c buildVolunteerJob(Integer volunteerQuantity, sked_Drive__c drive) {
        if (volunteerQuantity == null || volunteerQuantity <= 0) {
            return null;
        }
        Decimal quantity = volunteerQuantity;
        return new sked__Job__c(
            sked_Volunteer_Role__c = skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR,
            sked__Location__c = drive.sked_Drive_Site__c,
            sked_Redcross_Volunteer_Quantity__c = quantity,
            sked_Sponsor_Volunteer_Quantity__c = 0,
            sked__Quantity__c = quantity,
            sked_System_Quantity__c = quantity,
            sked_Is_Manually_Created__c = false,
            sked__Job_Allocation_Time_Source__c = false
        );
    }

    // Ported verbatim from skedMobileDriveJobBuilder.assignFreshJobTags:109-127 - already
    // drive-type-agnostic (resourceType detection and skedMobileDriveShiftCalculator.RequiredJobTag
    // are the same shape regardless of drive type).
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

    // Fresh copy of skedMobileDriveJobBuilder.populateShiftTime:332-372 - the logic only touches
    // shiftRecord/jobs fields already present on the neutral skedProposedDriveShift base class, so it
    // ports unchanged even though this is a standalone method, not a shared call.
    private static void populateShiftTime(ProposedDriveShift proposed, String timezoneSidId) {
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

    /**
     * Own copy of skedMobileDriveJobBuilder.applyShiftSetupRollups:1013-1044, minus the APT-setup
     * accumulator - Fixed Site jobs never carry sked_APT_Quantity__c (no VP/HH concept), so there is
     * nothing to sum. sked_APT_Setup__c is still unconditionally zeroed below - per the HRP-10153 JS
     * parity review, baseGenerator.js:658 unconditionally zeroes this field for every drive type,
     * Fixed Site included, so this is not actually a "leave it null" case as an earlier revision of
     * this class assumed. Zeroing here also prevents a stale non-zero value surviving into a future
     * regen once the existing-record-carry-forward task lands.
     */
    public static void applyShiftSetupRollups(List<ProposedDriveShift> proposed, Set<String> staffSetupExcludedRoleNames) {
        for (ProposedDriveShift shift : proposed) {
            Decimal shiftStaffSetup = 0;
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
                } else if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                    shiftVehiclesNeeded += quantity;
                } else if (job.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                    shiftEquipment += quantity;
                } else if (String.isNotBlank(job.sked_Volunteer_Role__c)) {
                    shiftVolunteerSetup += quantity;
                }
            }
            shift.shiftRecord.sked_Staff_Setup__c = shiftStaffSetup;
            shift.shiftRecord.sked_APT_Setup__c = 0;
            shift.shiftRecord.sked_Vehicles_Needed__c = shiftVehiclesNeeded;
            shift.shiftRecord.sked_Equipment__c = shiftEquipment;
            shift.shiftRecord.sked_Volunteer_Setup__c = shiftVolunteerSetup;
        }
    }

    private static Boolean isManuallyCreatedFromStaffingModal(sked__Job__c job) {
        return job.sked_Is_Manually_Created__c == true && job.sked_Manually_Created_From__c == MANUALLY_CREATED_FROM_STAFFING_MODAL;
    }

    private static Boolean positive(Decimal value) {
        return value != null && value > 0;
    }

    private static Decimal zeroIfNull(Decimal value) {
        return value == null ? 0 : value;
    }

    // Fixed Site's system-generated role set - verified against helper.js:3551-3552's isSystemRole
    // Fixed-Site branch. Do NOT reuse Mobile's MOBILE_SYSTEM_ROLES (a different, 7-role set).
    private static final Set<String> FIXED_SITE_SYSTEM_ROLES = new Set<String>{ 'Apheresis Charge', 'Apheresis' };

    // ===== Existing-record carry-forward =====

    // Shifts pair by array position only (existingDriveShifts[i] <-> proposed[i]), matching
    // fixedSiteGenerator.js:1151,1195-1196 exactly - never by start/end time. The caller must supply
    // existingDriveShifts in the SAME order the fresh rebuild used (skedDriveRegenContextLoader's own
    // ctx.driveShifts has no sked_Jobs__r subquery today and isn't ordered for this purpose - a real
    // caller needs its own query, not that one, verbatim). existingDriveShifts' sked_Jobs__r subquery
    // must select: Id, sked_Resource_Role__c, sked_Is_Manually_Created__c, sked_Asset_Type__c,
    // sked_Equipment_Subtype__c, sked_Volunteer_Role__c (matching fields, this method) plus
    // sked__Quantity__c, sked_Manually_Created_From__c, sked_Redcross_Volunteer_Quantity__c,
    // sked_Sponsor_Volunteer_Quantity__c (read unconditionally by preserveManuallyCreatedJobs, below -
    // must run first per its own header) and should filter sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
    // per this repo's SOQL rules - a cancelled manually-created job must never be carried forward.
    public static void applyExistingRecordIds(List<ProposedDriveShift> proposed, List<sked_Drive_Shift__c> existingDriveShifts) {
        for (Integer i = 0; i < proposed.size() && i < existingDriveShifts.size(); i++) {
            sked_Drive_Shift__c existingShift = existingDriveShifts[i];
            proposed[i].shiftRecord.Id = existingShift.Id;

            for (sked__Job__c proposedJob : proposed[i].jobs) {
                // Already Id-stamped by preserveManuallyCreatedJobsForAllShifts (must run first) -
                // never re-matched here, same guard as Mobile's own applyExistingRecordIds.
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

    private static sked__Job__c findMatchingExistingJob(sked__Job__c proposedJob, List<sked__Job__c> existingJobs) {
        if (existingJobs == null) {
            return null;
        }
        if (String.isNotBlank(proposedJob.sked_Resource_Role__c)) {
            for (sked__Job__c existingJob : existingJobs) {
                if (String.isBlank(existingJob.sked_Resource_Role__c) || existingJob.sked_Is_Manually_Created__c == true) {
                    continue;
                }
                if (existingJob.sked_Resource_Role__c == proposedJob.sked_Resource_Role__c) {
                    return existingJob;
                }
            }
            return null;
        }
        if (String.isNotBlank(proposedJob.sked_Volunteer_Role__c)) {
            for (sked__Job__c existingJob : existingJobs) {
                if (String.isBlank(existingJob.sked_Volunteer_Role__c) || existingJob.sked_Is_Manually_Created__c == true) {
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
                if (existingJob.sked_Asset_Type__c != proposedJob.sked_Asset_Type__c || existingJob.sked_Is_Manually_Created__c == true) {
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

    // For each carried-forward job (real Id assigned by applyExistingRecordIds, called right before
    // this), add forward any of the EXISTING job's systemCreated, non-Physical-Location-Type tags not
    // already present (by Tag Id) in the job's freshly assigned tag set (assignFreshJobTags, called
    // earlier during buildProposedDriveShifts). Physical Location Type tags are always re-derived
    // fresh from the drive's own site/CO, never carried forward. Ported from
    // skedMobileDriveJobBuilder.cls:808-849, using the same drive-type-agnostic skedMobileJobTagLoader.
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

    // Must run BEFORE applyExistingRecordIds - a manually-created job needs to be present in
    // shift.jobs before capacity/slot generation (a future task) runs, matching
    // fixedSiteGenerator.js's own job-population-time concat, not a later Id-stamping pass.
    public static void preserveManuallyCreatedJobsForAllShifts(List<ProposedDriveShift> proposed, List<sked_Drive_Shift__c> existingDriveShifts) {
        for (Integer i = 0; i < proposed.size() && i < existingDriveShifts.size(); i++) {
            preserveManuallyCreatedJobs(proposed[i], existingDriveShifts[i].sked_Jobs__r);
        }
    }

    // NO quantity gate here - a deliberate, verified divergence from Mobile's preserveManuallyCreatedJobs
    // (which requires positive(existingJob.sked__Quantity__c)). fixedSiteGenerator.js:1352-1356's own
    // concat has no such check; copying Mobile's gate would silently drop a legitimate zero-quantity
    // manually-created Fixed Site job.
    private static void preserveManuallyCreatedJobs(ProposedDriveShift shift, List<sked__Job__c> existingJobs) {
        if (existingJobs == null) {
            return;
        }
        // Snapshot BEFORE the loop starts - the probe below must check against the original fresh
        // jobs, never the live shift.jobs list this same loop appends onto. Probing the live list let
        // a preserved job's own append falsely "match" every LATER manual candidate sharing its
        // sked_Manually_Created_From__c (a very common case - e.g. two manual jobs both added via the
        // Drive Scheduling UI), silently dropping all but the first such candidate.
        List<sked__Job__c> freshProposedJobs = new List<sked__Job__c>(shift.jobs);
        for (sked__Job__c existingJob : existingJobs) {
            if (!isManuallyCreatedJob(existingJob)) {
                continue;
            }
            if (findMatchingProposedJobForManualCandidate(existingJob, freshProposedJobs) != null) {
                continue;
            }
            shift.jobs.add(new sked__Job__c(
                Id = existingJob.Id,
                sked_Resource_Role__c = existingJob.sked_Resource_Role__c,
                sked_Asset_Type__c = existingJob.sked_Asset_Type__c,
                sked_Equipment_Subtype__c = existingJob.sked_Equipment_Subtype__c,
                sked_Volunteer_Role__c = existingJob.sked_Volunteer_Role__c,
                sked_Redcross_Volunteer_Quantity__c = existingJob.sked_Redcross_Volunteer_Quantity__c,
                sked_Sponsor_Volunteer_Quantity__c = existingJob.sked_Sponsor_Volunteer_Quantity__c,
                sked__Quantity__c = existingJob.sked__Quantity__c,
                sked_System_Quantity__c = existingJob.sked__Quantity__c,
                sked_Is_Manually_Created__c = true,
                sked_Manually_Created_From__c = existingJob.sked_Manually_Created_From__c
            ));
        }
    }

    // Fixed Site's system-generated role set is {'Apheresis Charge','Apheresis'} - verified against
    // helper.js:3551-3552, NOT Mobile's 7-role set. Fixed Site's system-generated volunteer role is
    // ONLY 'Donor Ambassador' - independently re-read at helper.js:3558-3564 (isSystemRole's
    // job.volunteerRole branch: `if (isMobileDrive) return false; else return
    // ['Donor Ambassador'].includes(job.volunteerRole);` - Fixed Site takes the else branch). Every
    // other sked_Resource_Volunteer_Roles value (Lead Donor Ambassador, Regulated - Medical Screener,
    // Regulated - RNOR, Translator - confirmed the full value set, no Redcross/Sponsor-prefixed
    // Donor Ambassador variant exists on THIS picklist, unlike sked_Resource_Roles') is NOT
    // system-generated and is eligible for manual preservation just like a role job. An asset job is
    // always system-generated.
    private static Boolean isManuallyCreatedJob(sked__Job__c job) {
        if (job.sked_Is_Manually_Created__c == true) {
            return true;
        }
        if (String.isNotBlank(job.sked_Resource_Role__c)) {
            return !FIXED_SITE_SYSTEM_ROLES.contains(job.sked_Resource_Role__c);
        }
        if (String.isNotBlank(job.sked_Volunteer_Role__c)) {
            return job.sked_Volunteer_Role__c != skedConstants.JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR;
        }
        return job.sked_Asset_Type__c == null;
    }

    // A real probe - matches a manually-created candidate against a job from the CALLER'S ORIGINAL
    // proposed set (the freshProposedJobs snapshot preserveManuallyCreatedJobs takes before its own
    // preservation loop starts - never the live, mutating shift.jobs list, which caused the bug
    // documented on that snapshot). Requires BOTH an origin match (sked_Is_Manually_Created__c == true
    // && the same sked_Manually_Created_From__c) AND a job-identity match (isSameJobIdentity, below).
    // Currently still returns null on every real call because buildRoleJob/buildVolunteerJob/
    // buildAssetJob always hardcode sked_Is_Manually_Created__c = false (manual role-quantity
    // carry-forward is a separate, deferred gap - see class header) - written as a fully real,
    // identity-aware probe anyway so this method needs no revisit once that gap closes.
    private static sked__Job__c findMatchingProposedJobForManualCandidate(sked__Job__c manualJob, List<sked__Job__c> proposedJobs) {
        for (sked__Job__c proposedJob : proposedJobs) {
            if (proposedJob.sked_Is_Manually_Created__c == true
                    && proposedJob.sked_Manually_Created_From__c == manualJob.sked_Manually_Created_From__c
                    && isSameJobIdentity(proposedJob, manualJob)) {
                return proposedJob;
            }
        }
        return null;
    }

    // Role, else asset type/subtype, else volunteer role - re-read against helper.js:2354's
    // isJobsSameRoles (role, else assetType alone with no subtype check, else volunteerRole), then
    // widened to also split Equipment by sked_Equipment_Subtype__c, matching findMatchingExistingJob's
    // own asset-branch pattern elsewhere in this class - a strictly narrower (never broader) match
    // than isJobsSameRoles, so it can't introduce a false-positive match isJobsSameRoles wouldn't have.
    private static Boolean isSameJobIdentity(sked__Job__c jobA, sked__Job__c jobB) {
        if (String.isNotBlank(jobA.sked_Resource_Role__c) || String.isNotBlank(jobB.sked_Resource_Role__c)) {
            return jobA.sked_Resource_Role__c == jobB.sked_Resource_Role__c;
        }
        if (jobA.sked_Asset_Type__c != null || jobB.sked_Asset_Type__c != null) {
            if (jobA.sked_Asset_Type__c != jobB.sked_Asset_Type__c) {
                return false;
            }
            return jobA.sked_Asset_Type__c != skedConstants.ASSET_TYPE_EQUIPMENT
                || jobA.sked_Equipment_Subtype__c == jobB.sked_Equipment_Subtype__c;
        }
        return jobA.sked_Volunteer_Role__c == jobB.sked_Volunteer_Role__c;
    }
}
