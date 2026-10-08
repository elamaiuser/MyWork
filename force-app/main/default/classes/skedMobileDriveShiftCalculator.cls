/**
 * Ported only from the slwcDriveGenerator LWC's mobile/base generator logic, never from the
 * legacy GenerateMobileDrive.cls/CreateSkedDrive.cls.
 *
 * Scope: the pure, side-effect-free calculation chain -
 * calculateDriveShiftsMetadata -> calculateTotalProceduresProjected, covering all 5
 * DCR-producible tokens' shared groups. The role-time/travel-time calculation itself lives in
 * skedRoleTimeCalculator (drive-type-agnostic, shared with Fixed Site); this class supplies the
 * Mobile-specific master data and delegates into it. Resource-quantity/dual-role/slot generation
 * and the resource-role branch of correctJobAllocationTimes (Google Maps distance-matrix callout)
 * are handled by other classes in the pipeline.
 */
public with sharing class skedMobileDriveShiftCalculator {

    public class RoleTimeData extends skedRoleTimeData { }

    public class DriveShiftMetadata extends skedDriveShiftMetadata {
        public String key;
        public String label;
        public Decimal aptSetup = 0;
        public Decimal x2rbcProjectedProcedures = 0;
        public Decimal wbProjectedProcedures = 0;
        public Decimal donorsScheduled = 0;
        public Decimal totalProceduresProjected = 0;
        public Decimal totalProductsProjected = 0;
        public Map<String, RoleTimeData> resourceRoleGroupRoleTimeDataMap;
    }

    public class DriveShiftsMetadata {
        public Decimal projectedRegisteredDonors = 0;
        public Decimal x2rbcProjectedProcedures = 0;
        public Decimal wbProjectedProcedures = 0;
        public Decimal aptSetup = 0;
        public Integer numberOfDriveShifts = 0;
        public List<DriveShiftMetadata> driveShifts = new List<DriveShiftMetadata>();
        public Map<String, RoleTimeData> resourceRoleGroupRoleTimeDataMap;
        public Decimal totalProceduresProjected = 0;
        public Decimal totalProductsProjected = 0;
    }

    public class MasterData {
        // The running user's locale timezone, not the drive/CO's own timezone.
        public String timezoneSidId;
        public Map<String, sked_Role_Time_Detail__c> roleGroupTimeDetailMap = new Map<String, sked_Role_Time_Detail__c>();
        public Map<String, List<sked_Role_Time_Variance__c>> roleGroupTimeVarianceMap = new Map<String, List<sked_Role_Time_Variance__c>>();
        public Map<String, sked_Travel_Time_Index_Item__c> travelTimeIndexItemMap = new Map<String, sked_Travel_Time_Index_Item__c>();
        public sked__Location__c driveSite;
        public Biomed_Collection_Op_Center__c collectionOperation;
        public Boolean skipAptCalculation = false;
        // helper.js:86 matches the CO's Skip Last Appointment For against the drive's OWN typeOfDrive,
        // so this is 'Fixed Site' for a WB drive - the name predates ShiftMetadataConfig.driveType and
        // is kept only because skedMobileDriveRegenEngine/skedMobileSlotGenerator_Test read it.
        public Boolean skipLastAppointmentForMobile = false;
        // sked_Admin_Setting__c.getOrgDefaults() callListRecipient/callListRecipientNone, used by
        // skedMobileSlotGenerator's padding-percentage calculation.
        public Decimal callListRecipientCapacity;
        public Decimal callListRecipientNoneCapacity;
        // Driver Support's fallback capacity when the SDM's own Driver Support capacity is unconfigured
        // (<=0) and the job is manually created (not via the Staffing Modal) - used by
        // skedMobileRoleQuantityCalculator.calculateStaffCapacity/skedMobileDriveJobBuilder.recalculateVphhQuantity.
        public Decimal adhocDriverSupportCapacity;
        // A plain Number field (no /100 scaling question like the two above), used by
        // skedMobileDualRoleGenerator's entry gate.
        public Decimal excessStaffCapacityThreshold;
        // The CO's available Vehicle-type sked__Resource__c records for the drive date, scoped per
        // reference_resource_override.md (primary CO + secondary CO + relocated-in), used by
        // skedMobileGhostVehicleCalculator.
        public List<sked__Resource__c> vehicles = new List<sked__Resource__c>();
        // Only the REQUIRED Account/Location tag Ids applicable to the Vehicle asset type are needed
        // (not the full driveTags structure).
        public Set<Id> vehicleRequiredTagIds = new Set<Id>();
        // REQUIRED Account/Location tags, keyed by the resource type they apply to
        // ('Vehicle'/'Equipment'/'Person'), used by skedMobileDriveJobBuilder to assign each freshly
        // built job its starting tag set.
        public Map<String, List<RequiredJobTag>> jobTagsByResourceType = new Map<String, List<RequiredJobTag>>();
        // Non-required Account/Location tags this drive's shifts should carry, computed once per
        // drive (not per shift - Account/Location tags are drive-level facts, identical for every
        // shift on the drive). Only ever used to populate a genuinely NEW shift's
        // sked_Drive_Shift_Tag__c records - an existing shift's tags are never refreshed on regen,
        // matching the legacy interactive path's own insert-once behavior.
        public List<skedDriveShiftTagCalculator.TagResult> driveShiftTagResults = new List<skedDriveShiftTagCalculator.TagResult>();
        // Resource roles excluded from the shift-level Staff_Setup__c rollup, used by skedMobileDriveJobBuilder.
        public Set<String> staffSetupExcludedRoleNames = new Set<String>();
    }

    // A lightweight wrapper since there's no unsaved sked__Job_Tag__c to hold this yet (it needs a
    // real Job Id).
    public class RequiredJobTag {
        public Id tagId;
        public String tagName;
        public String tagType;
        // sked__Account_Tag__c has no equivalent field at all (only sked_Location_Tag__c does) - an
        // account-sourced required tag is therefore never systemCreated, a real structural quirk of
        // the schema, not a porting bug.
        public Boolean systemCreated;
    }

    /**
     * Per-drive-type configuration for loadMasterData and calculateDriveShiftsMetadata, so a WB Fixed
     * Site caller can reuse both instead of forking them. Defaults reproduce Mobile exactly.
     *
     * Four calculateDriveShiftsMetadata levers, not the two a body diff of mobileGenerator.js:1086 vs
     * wbFixedSiteGenerator.js:893 shows. The other two are hidden because helper.js's shared functions
     * branch on drive type themselves, and WB is a typeOfDrive = 'Fixed Site' drive (helper.js:20-22):
     * calculateMinMaxRoleTimeDuration adds travel time only when isMobileDrive (helper.js:1837), and
     * calculateDriveShiftLunchBreakSettings picks the Fixed Site duration field plus the same
     * Supervisory/Staff filter (helper.js:1799-1813). The Apex hoisted both into explicit parameters.
     *
     * driveType is loadMasterData's lever and is the drive's OWN sked_Type_of_Drive__c, matching what
     * the LWC passes: fetch.js:103 reads typeOfDrive off the drive model (not off Fetch's own
     * this.driveType), and helper.js:86 matches Skip Last Appointment For against the same value.
     */
    public class ShiftMetadataConfig {
        public String driveType = skedConstants.DRIVE_TYPE_MOBILE;
        public List<String> roleTimeRoleGroupsFilter = new List<String>();
        public Boolean includeTravelTimeInRoleTimeDuration = true;
        public Boolean calculateApt = true;
        public Boolean useFixedSiteLunchBreakDuration = false;
    }

    public static ShiftMetadataConfig mobileConfig() {
        return new ShiftMetadataConfig();
    }

    // Same three role-time/lunch-break settings skedFixedSiteDriveShiftCalculator already passes
    // (cls:310-313), plus APT off - wbFixedSiteGenerator.js has no APT anywhere.
    public static ShiftMetadataConfig wbFixedSiteConfig() {
        ShiftMetadataConfig config = new ShiftMetadataConfig();
        config.driveType = skedConstants.DRIVE_TYPE_FIXED_SITE;
        config.roleTimeRoleGroupsFilter = new List<String>{
            skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES,
            skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES
        };
        config.includeTravelTimeInRoleTimeDuration = false;
        config.calculateApt = false;
        config.useFixedSiteLunchBreakDuration = true;
        return config;
    }

    private static final Integer TIME_STEP_MINUTES = 15;

    // ===== Master data retrieval (replaces the LWC's slwcDataService/roleTimeDetailService fetch chain) =====

    public static MasterData loadMasterData(sked_Drive__c drive) {
        return loadMasterData(drive, mobileConfig());
    }

    /**
     * @param config Pass wbFixedSiteConfig() for a Fixed Site + Non Integrated WB drive. That variant
     * additionally requires the drive to have been queried with sked_Operation_Type__c.
     */
    public static MasterData loadMasterData(sked_Drive__c drive, ShiftMetadataConfig config) {
        MasterData masterData = new MasterData();
        masterData.timezoneSidId = UserInfo.getTimeZone().getID();
        masterData.skipAptCalculation = false;

        masterData.driveSite = [
            SELECT Id, sked_Physical_Location_Type__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,
                sked_Travel_Time_to_Staging_Location__c
            FROM sked__Location__c
            WHERE Id = :drive.sked_Drive_Site__c
        ];

        masterData.collectionOperation = [
            SELECT Id, sked_Breakdown_Time_Threshold__c, sked_Setup_Time_Threshold__c, sked_Maximum_Shift_Length_Threshold__c,
                sked_Lunch_Break__c, sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Duration_Fixed_Site__c,
                sked_Lunch_Break_Duration_Mobile__c, sked_Unpaid_Lunch_Break_Duration__c, sked_No_Travel_Time__c,
                sked_Skip_Last_Appointment_For__c, sked_Auto_Generate_Dual_Role__c, sked_Only_Generate_Dual_If_1_Machine__c,
                (SELECT Id, sked_Start_Date__c, sked_End_Date__c,
                    sked_Staging_Location__r.sked_GeoLocation__Latitude__s, sked_Staging_Location__r.sked_GeoLocation__Longitude__s
                 FROM sked_Collection_Op_Staging_Locations__r)
            FROM Biomed_Collection_Op_Center__c
            WHERE Id = :drive.sked_Collection_Operation__c
        ];
        masterData.skipLastAppointmentForMobile = masterData.collectionOperation.sked_Skip_Last_Appointment_For__c != null
            && masterData.collectionOperation.sked_Skip_Last_Appointment_For__c.contains(config.driveType);

        sked_Admin_Setting__c adminSetting = sked_Admin_Setting__c.getOrgDefaults();
        masterData.callListRecipientCapacity = adminSetting.sked_Admin_Call_List_Recipient__c != null ? adminSetting.sked_Admin_Call_List_Recipient__c : 115;
        masterData.callListRecipientNoneCapacity = adminSetting.sked_Admin_Call_List_Recipient_None__c != null ? adminSetting.sked_Admin_Call_List_Recipient_None__c : 130;
        masterData.adhocDriverSupportCapacity = adminSetting.sked_Admin_Adhoc_Driver_Support_Capacity__c != null ? adminSetting.sked_Admin_Adhoc_Driver_Support_Capacity__c : 2.2;
        masterData.excessStaffCapacityThreshold = adminSetting.Admin_Excess_Staff_Capacity_Threshold__c != null ? adminSetting.Admin_Excess_Staff_Capacity_Threshold__c : 1;

        for (sked_Staff_Setup_Excluded_Role__c excludedRole : [
            SELECT sked_Resource_Role__c FROM sked_Staff_Setup_Excluded_Role__c WHERE sked_Excluded_For_Staff_Allocated__c = TRUE
        ]) {
            masterData.staffSetupExcludedRoleNames.add(excludedRole.sked_Resource_Role__c);
        }

        loadRoleGroupTimeDetailMap(masterData, drive, config);

        String dayOfWeekName = getDayOfWeekName(drive.sked_Drive_Date__c);
        for (sked_Role_Time_Variance__c rtv : [
            SELECT Id, sked_Resource_Role_Group__c, sked_Buffer_Type__c, sked_Variance_Applies_to__c, sked_Variation_Amount__c, sked_Days_Of_Week__c
            FROM sked_Role_Time_Variance__c
            WHERE sked_Location__c = :drive.sked_Drive_Site__c
                AND sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c
                AND sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c
        ]) {
            if (!includesDayOfWeek(rtv.sked_Days_Of_Week__c, dayOfWeekName)) {
                continue;
            }
            for (String resourceRoleGroup : rtv.sked_Resource_Role_Group__c.split(';')) {
                if (!masterData.roleGroupTimeVarianceMap.containsKey(resourceRoleGroup)) {
                    masterData.roleGroupTimeVarianceMap.put(resourceRoleGroup, new List<sked_Role_Time_Variance__c>());
                }
                masterData.roleGroupTimeVarianceMap.get(resourceRoleGroup).add(rtv);
            }
        }

        masterData.travelTimeIndexItemMap = skedRoleTimeCalculator.loadTravelTimeIndexItemMap(masterData.driveSite, masterData.collectionOperation, drive.sked_Drive_Date__c);
        masterData.vehicles = loadVehicles(drive);
        masterData.vehicleRequiredTagIds = loadVehicleRequiredTagIds(drive);
        masterData.jobTagsByResourceType = loadJobTagsMap(drive);
        masterData.driveShiftTagResults = skedDriveShiftTagCalculator.calculateDriveShiftTags(
            loadAccountTagCandidatesForShiftTags(drive), loadLocationTagCandidatesForShiftTags(drive));

        return masterData;
    }

    // Two passes, Global-or-CO then CO-only, so a CO-specific row overrides Global for the same role
    // group. The LWC runs one query and splits the results in memory (helper.js:692-726); Apex keeps
    // the pass split the shipped Mobile code already had.
    private static void loadRoleGroupTimeDetailMap(MasterData masterData, sked_Drive__c drive, ShiftMetadataConfig config) {
        String dayOfWeekName = getDayOfWeekName(drive.sked_Drive_Date__c);
        Boolean isFixedSiteRoleTime = config.driveType == skedConstants.DRIVE_TYPE_FIXED_SITE;

        mergeRoleTimeDetails(masterData.roleGroupTimeDetailMap, dayOfWeekName, false, isFixedSiteRoleTime
            ? queryFixedSiteRoleTimeDetails(drive, masterData.driveSite, false)
            : queryMobileRoleTimeDetails(drive, masterData.driveSite, false));
        mergeRoleTimeDetails(masterData.roleGroupTimeDetailMap, dayOfWeekName, true, isFixedSiteRoleTime
            ? queryFixedSiteRoleTimeDetails(drive, masterData.driveSite, true)
            : queryMobileRoleTimeDetails(drive, masterData.driveSite, true));
    }

    private static void mergeRoleTimeDetails(Map<String, sked_Role_Time_Detail__c> roleGroupTimeDetailMap, String dayOfWeekName,
            Boolean collectionOperationOnly, List<sked_Role_Time_Detail__c> roleTimeDetails) {
        for (sked_Role_Time_Detail__c rtd : roleTimeDetails) {
            if (!includesDayOfWeek(rtd.sked_Days_of_Week__c, dayOfWeekName)) {
                continue;
            }
            for (String resourceRoleGroup : rtd.sked_Resource_Role_Group__c.split(';')) {
                if (collectionOperationOnly || rtd.sked_Type__c == 'Global' || !roleGroupTimeDetailMap.containsKey(resourceRoleGroup)) {
                    roleGroupTimeDetailMap.put(resourceRoleGroup, rtd);
                }
            }
        }
    }

    // INCLUDES/EXCLUDES don't accept bind variables in Apex SOQL, so the day-of-week match is done
    // in-memory by mergeRoleTimeDetails instead.
    private static List<sked_Role_Time_Detail__c> queryMobileRoleTimeDetails(sked_Drive__c drive, sked__Location__c driveSite, Boolean collectionOperationOnly) {
        if (collectionOperationOnly) {
            return [
                SELECT Id, sked_Type__c, sked_Resource_Role_Group__c, sked_Days_of_Week__c, sked_Lead_Time__c, sked_Setup_Time__c,
                    sked_Breakdown_Time__c, sked_Wrap_up_Time__c
                FROM sked_Role_Time_Detail__c
                WHERE sked_Type__c = 'Collection Operation' AND sked_Collection_Operation__c = :drive.sked_Collection_Operation__c
                    AND sked_Drive_Type__c = :skedConstants.DRIVE_TYPE_MOBILE
                    AND sked_Mobile_Type__c = :driveSite.sked_Physical_Location_Type__c
                    AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                    AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
            ];
        }
        return [
            SELECT Id, sked_Type__c, sked_Resource_Role_Group__c, sked_Days_of_Week__c, sked_Lead_Time__c, sked_Setup_Time__c,
                sked_Breakdown_Time__c, sked_Wrap_up_Time__c
            FROM sked_Role_Time_Detail__c
            WHERE (sked_Type__c = 'Global' OR sked_Collection_Operation__c = :drive.sked_Collection_Operation__c)
                AND sked_Drive_Type__c = :skedConstants.DRIVE_TYPE_MOBILE
                AND sked_Mobile_Type__c = :driveSite.sked_Physical_Location_Type__c
                AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
        ];
    }

    /**
     * fetch.js:103 passes the drive's OWN typeOfDrive - 'Fixed Site' for a WB drive - so a WB drive
     * reads Fixed-Site-typed role time details, and helper.js:696-698 then drops any whose Fixed Site
     * Operation Type is set to something other than the drive's own. Folded into SOQL here, exactly as
     * skedFixedSiteDriveShiftCalculator.cls:97 already does (a blank picklist reads as NULL).
     */
    private static List<sked_Role_Time_Detail__c> queryFixedSiteRoleTimeDetails(sked_Drive__c drive, sked__Location__c driveSite, Boolean collectionOperationOnly) {
        if (collectionOperationOnly) {
            return [
                SELECT Id, sked_Type__c, sked_Resource_Role_Group__c, sked_Days_of_Week__c, sked_Lead_Time__c, sked_Setup_Time__c,
                    sked_Breakdown_Time__c, sked_Wrap_up_Time__c
                FROM sked_Role_Time_Detail__c
                WHERE sked_Type__c = 'Collection Operation' AND sked_Collection_Operation__c = :drive.sked_Collection_Operation__c
                    AND sked_Drive_Type__c = :skedConstants.DRIVE_TYPE_FIXED_SITE
                    AND sked_Mobile_Type__c = :driveSite.sked_Physical_Location_Type__c
                    AND (sked_Fixed_Site_Operation_Type__c = NULL OR sked_Fixed_Site_Operation_Type__c = :drive.sked_Operation_Type__c)
                    AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                    AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
            ];
        }
        return [
            SELECT Id, sked_Type__c, sked_Resource_Role_Group__c, sked_Days_of_Week__c, sked_Lead_Time__c, sked_Setup_Time__c,
                sked_Breakdown_Time__c, sked_Wrap_up_Time__c
            FROM sked_Role_Time_Detail__c
            WHERE (sked_Type__c = 'Global' OR sked_Collection_Operation__c = :drive.sked_Collection_Operation__c)
                AND sked_Drive_Type__c = :skedConstants.DRIVE_TYPE_FIXED_SITE
                AND sked_Mobile_Type__c = :driveSite.sked_Physical_Location_Type__c
                AND (sked_Fixed_Site_Operation_Type__c = NULL OR sked_Fixed_Site_Operation_Type__c = :drive.sked_Operation_Type__c)
                AND (sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= :drive.sked_Drive_Date__c)
        ];
    }

    // Scoped to only what skedMobileGhostVehicleCalculator needs (vehicle capacity/DOT/CDL/tags) -
    // not the full generic resource-scheduling query (job allocations, activities, availabilities,
    // etc. are irrelevant here). CO scoping follows
    // reference_resource_override.md: primary CO, secondary CO (sked_Resource_Biomed_Collection_Op__c),
    // and relocated-in (sked__Resource_Override__c) all count as available for this CO.
    private static List<sked__Resource__c> loadVehicles(sked_Drive__c drive) {
        Set<Id> additionalResourceIds = new Set<Id>();
        for (sked__Resource_Override__c ro : [
            SELECT Id, sked__Resource__c
            FROM sked__Resource_Override__c
            WHERE sked_Collection_Operation__c = :drive.sked_Collection_Operation__c
                AND sked_Start_Date__c <= :drive.sked_Drive_Date__c AND sked_End_Date__c >= :drive.sked_Drive_Date__c
        ]) {
            additionalResourceIds.add(ro.sked__Resource__c);
        }
        for (sked_Resource_Biomed_Collection_Op__c rco : [
            SELECT Id, sked_Resource__c
            FROM sked_Resource_Biomed_Collection_Op__c
            WHERE sked_Biomed_Collection_Op_Center__c = :drive.sked_Collection_Operation__c
                AND (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :drive.sked_Drive_Date__c)
        ]) {
            additionalResourceIds.add(rco.sked_Resource__c);
        }

        return [
            SELECT Id, Name, sked_Asset_Type__c, sked_Pres_Donor_Capacity__c, sked_CDL__c, sked_DOT__c,
                (SELECT Id, sked__Tag__c, sked_Start_Date__c FROM sked__ResourceTags__r WHERE sked_Start_Date__c <= :drive.sked_Drive_Date__c)
            FROM sked__Resource__c
            WHERE sked_Asset_Type__c = :skedConstants.ASSET_TYPE_VEHICLE
                AND sked__Is_Active__c = TRUE
                AND (sked_Effective_Date__c = NULL OR sked_Effective_Date__c <= :drive.sked_Drive_Date__c)
                AND (sked_Future_Inactive_Date__c = NULL OR sked_Future_Inactive_Date__c > :drive.sked_Drive_Date__c)
                AND (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c = :drive.sked_Collection_Operation__c
                     OR Id IN :additionalResourceIds)
        ];
    }

    // Only REQUIRED Account/Location tags whose resourceType includes Vehicle (or has no
    // resourceType restriction) apply.
    private static Set<Id> loadVehicleRequiredTagIds(sked_Drive__c drive) {
        Set<Id> tagIds = new Set<Id>();
        for (sked__Account_Tag__c accountTag : [
            SELECT sked__Tag__c, sked__Tag__r.sked_Resource_Type__c
            FROM sked__Account_Tag__c
            WHERE sked__Account__c = :drive.sked_Account__c AND sked__Required__c = TRUE
        ]) {
            if (tagAppliesToVehicle(accountTag.sked__Tag__r.sked_Resource_Type__c)) {
                tagIds.add(accountTag.sked__Tag__c);
            }
        }
        for (sked_Location_Tag__c locationTag : [
            SELECT sked_Tag__c, sked_Tag__r.sked_Resource_Type__c
            FROM sked_Location_Tag__c
            WHERE sked_Location__c = :drive.sked_Drive_Site__c AND sked_Required__c = TRUE
        ]) {
            if (tagAppliesToVehicle(locationTag.sked_Tag__r.sked_Resource_Type__c)) {
                tagIds.add(locationTag.sked_Tag__c);
            }
        }
        return tagIds;
    }

    // REQUIRED Account/Location tags, expanded per resource type (a blank Resource Type on the tag
    // itself applies to all three - Vehicle/Equipment/Person). Deduped by tag Id within each
    // resource type's list. Public: also reused by skedMobileAssetReassigner for the Equipment tag
    // bucket (no equivalent Equipment-specific loader like loadVehicleRequiredTagIds exists, and
    // this already computes it).
    public static Map<String, List<RequiredJobTag>> loadJobTagsMap(sked_Drive__c drive) {
        Map<String, List<RequiredJobTag>> jobTagsByResourceType = new Map<String, List<RequiredJobTag>>{
            skedConstants.ASSET_TYPE_VEHICLE => new List<RequiredJobTag>(),
            skedConstants.ASSET_TYPE_EQUIPMENT => new List<RequiredJobTag>(),
            skedConstants.RESOURCE_TYPE_PERSON => new List<RequiredJobTag>()
        };
        Map<String, Set<Id>> seenTagIdsByResourceType = new Map<String, Set<Id>>{
            skedConstants.ASSET_TYPE_VEHICLE => new Set<Id>(),
            skedConstants.ASSET_TYPE_EQUIPMENT => new Set<Id>(),
            skedConstants.RESOURCE_TYPE_PERSON => new Set<Id>()
        };

        for (sked__Account_Tag__c accountTag : [
            SELECT sked__Tag__c, sked__Tag__r.Name, sked__Tag__r.sked__Type__c, sked__Tag__r.sked_Resource_Type__c
            FROM sked__Account_Tag__c
            WHERE sked__Account__c = :drive.sked_Account__c AND sked__Required__c = TRUE
        ]) {
            // sked__Account_Tag__c has no SystemCreated field at all - always false, a real schema
            // quirk (see RequiredJobTag's comment), not an omission here.
            addRequiredJobTag(jobTagsByResourceType, seenTagIdsByResourceType, accountTag.sked__Tag__c,
                accountTag.sked__Tag__r.Name, accountTag.sked__Tag__r.sked__Type__c, accountTag.sked__Tag__r.sked_Resource_Type__c, false);
        }
        for (sked_Location_Tag__c locationTag : [
            SELECT sked_Tag__c, sked_Tag__r.Name, sked_Tag__r.sked__Type__c, sked_Tag__r.sked_Resource_Type__c, sked_SystemCreated__c
            FROM sked_Location_Tag__c
            WHERE sked_Location__c = :drive.sked_Drive_Site__c AND sked_Required__c = TRUE
        ]) {
            addRequiredJobTag(jobTagsByResourceType, seenTagIdsByResourceType, locationTag.sked_Tag__c,
                locationTag.sked_Tag__r.Name, locationTag.sked_Tag__r.sked__Type__c, locationTag.sked_Tag__r.sked_Resource_Type__c, locationTag.sked_SystemCreated__c);
        }
        return jobTagsByResourceType;
    }

    private static void addRequiredJobTag(Map<String, List<RequiredJobTag>> jobTagsByResourceType, Map<String, Set<Id>> seenTagIdsByResourceType,
            Id tagId, String tagName, String tagType, String resourceTypeSemicolonList, Boolean systemCreated) {
        List<String> resourceTypes = String.isBlank(resourceTypeSemicolonList)
            ? new List<String>{ skedConstants.ASSET_TYPE_VEHICLE, skedConstants.ASSET_TYPE_EQUIPMENT, skedConstants.RESOURCE_TYPE_PERSON }
            : resourceTypeSemicolonList.split(';');

        for (String resourceType : resourceTypes) {
            if (!jobTagsByResourceType.containsKey(resourceType) || seenTagIdsByResourceType.get(resourceType).contains(tagId)) {
                continue;
            }
            seenTagIdsByResourceType.get(resourceType).add(tagId);
            RequiredJobTag requiredTag = new RequiredJobTag();
            requiredTag.tagId = tagId;
            requiredTag.tagName = tagName;
            requiredTag.tagType = tagType;
            requiredTag.systemCreated = systemCreated == true;
            jobTagsByResourceType.get(resourceType).add(requiredTag);
        }
    }

    // Unfiltered (both required and non-required) Account tags - unlike loadVehicleRequiredTagIds/
    // loadJobTagsMap, skedDriveShiftTagCalculator needs the full set to correctly exclude
    // non-required tags whose name collides with a required one.
    private static List<skedDriveShiftTagCandidate> loadAccountTagCandidatesForShiftTags(sked_Drive__c drive) {
        List<skedDriveShiftTagCandidate> candidates = new List<skedDriveShiftTagCandidate>();
        for (sked__Account_Tag__c accountTag : [
            SELECT sked__Tag__c, sked__Tag__r.Name, sked__Required__c, sked_Minimum_Quantity__c
            FROM sked__Account_Tag__c
            WHERE sked__Account__c = :drive.sked_Account__c
        ]) {
            skedDriveShiftTagCandidate candidate = new skedDriveShiftTagCandidate();
            candidate.tagId = accountTag.sked__Tag__c;
            candidate.tagName = accountTag.sked__Tag__r.Name;
            candidate.required = accountTag.sked__Required__c;
            candidate.minimumQuantity = accountTag.sked_Minimum_Quantity__c;
            candidates.add(candidate);
        }
        return candidates;
    }

    // Unfiltered (both required and non-required) Location tags - see loadAccountTagCandidatesForShiftTags.
    private static List<skedDriveShiftTagCandidate> loadLocationTagCandidatesForShiftTags(sked_Drive__c drive) {
        List<skedDriveShiftTagCandidate> candidates = new List<skedDriveShiftTagCandidate>();
        for (sked_Location_Tag__c locationTag : [
            SELECT sked_Tag__c, sked_Tag__r.Name, sked_Required__c, sked_Minimum_Quantity__c
            FROM sked_Location_Tag__c
            WHERE sked_Location__c = :drive.sked_Drive_Site__c
        ]) {
            skedDriveShiftTagCandidate candidate = new skedDriveShiftTagCandidate();
            candidate.tagId = locationTag.sked_Tag__c;
            candidate.tagName = locationTag.sked_Tag__r.Name;
            candidate.required = locationTag.sked_Required__c;
            candidate.minimumQuantity = locationTag.sked_Minimum_Quantity__c;
            candidates.add(candidate);
        }
        return candidates;
    }

    private static Boolean tagAppliesToVehicle(String resourceTypeSemicolonList) {
        if (String.isBlank(resourceTypeSemicolonList)) {
            return true;
        }
        return resourceTypeSemicolonList.split(';').contains(skedConstants.ASSET_TYPE_VEHICLE);
    }

    // Date.toStartOfWeek() is locale-dependent, so weekday is derived from a fixed Sunday anchor instead.
    private static final Date WEEKDAY_ANCHOR_SUNDAY = Date.newInstance(2000, 1, 2);

    // Public: skedMobileDriveJobBuilder's time-block matching reuses this same locale-safe lookup.
    public static String getDayOfWeekName(Date driveDate) {
        List<String> days = new List<String>{ 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' };
        return days[Math.mod(WEEKDAY_ANCHOR_SUNDAY.daysBetween(driveDate), 7)];
    }

    private static Boolean includesDayOfWeek(String semicolonDelimitedDays, String dayName) {
        if (String.isBlank(semicolonDelimitedDays)) {
            return false;
        }
        return semicolonDelimitedDays.split(';').indexOf(dayName) >= 0;
    }

    // ===== Drive Shifts metadata =====

    public static DriveShiftsMetadata calculateDriveShiftsMetadata(sked_Drive__c drive, MasterData masterData) {
        return calculateDriveShiftsMetadata(drive, masterData, mobileConfig());
    }

    public static DriveShiftsMetadata calculateDriveShiftsMetadata(sked_Drive__c drive, MasterData masterData, ShiftMetadataConfig config) {
        DriveShiftsMetadata shiftsMetadata = new DriveShiftsMetadata();
        shiftsMetadata.projectedRegisteredDonors = drive.sked_Projected_Registered_Donors__c == null ? 0 : drive.sked_Projected_Registered_Donors__c;
        shiftsMetadata.x2rbcProjectedProcedures = drive.sked_2RBC_Projected_Procedures__c == null ? 0 : drive.sked_2RBC_Projected_Procedures__c;
        shiftsMetadata.wbProjectedProcedures = drive.sked_WB_Projected_Procedures__c == null ? 0 : drive.sked_WB_Projected_Procedures__c;
        shiftsMetadata.aptSetup = !config.calculateApt || drive.sked_APT_Quantity__c == null ? 0 : drive.sked_APT_Quantity__c;
        shiftsMetadata.resourceRoleGroupRoleTimeDataMap = calculateDriveRoleTimeDataWrapper(drive, masterData);

        if (drive.sked_Drive_Date__c != null && drive.sked_Start_Time__c != null && drive.sked_End_Time__c != null) {
            DateTime driveStart = skedDateTimeUtils.getDateTimeFromDateAndTime(drive.sked_Drive_Date__c, drive.sked_Start_Time__c, masterData.timezoneSidId);
            Decimal maximumShiftLengthThreshold = masterData.collectionOperation.sked_Maximum_Shift_Length_Threshold__c;
            skedRoleTimeCalculator.RoleTimeDurationRange durationRange = skedRoleTimeCalculator.calculateMinMaxRoleTimeDuration(
                widenRoleTimeDataMap(shiftsMetadata.resourceRoleGroupRoleTimeDataMap),
                config.roleTimeRoleGroupsFilter, config.includeTravelTimeInRoleTimeDuration);
            Integer driveDrawHoursInMinutes = calculateDrawHoursInMinutes(drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c, masterData.timezoneSidId, null);
            Decimal maxDriveLengthInMinutes = driveDrawHoursInMinutes + durationRange.maxDurationBefore + durationRange.maxDurationAfter;
            Integer noOfShifts = maximumShiftLengthThreshold != null && maximumShiftLengthThreshold > 0
                ? Integer.valueOf(Math.ceil(maxDriveLengthInMinutes / maximumShiftLengthThreshold)) : 0;

            if (noOfShifts > 0) {
                Integer drawDurationPerShift = Integer.valueOf(Math.ceil(Decimal.valueOf(driveDrawHoursInMinutes) / noOfShifts));
                Integer redundantDuration = Math.mod(drawDurationPerShift, TIME_STEP_MINUTES);
                if (redundantDuration != 0) {
                    drawDurationPerShift = (drawDurationPerShift / TIME_STEP_MINUTES + 1) * TIME_STEP_MINUTES;
                }

                DateTime shiftStart;
                for (Integer i = 0; i < noOfShifts; i++) {
                    DriveShiftMetadata shift = new DriveShiftMetadata();
                    shift.key = 'drive_shift_' + i;
                    shift.label = 'Drive Shift ' + (i + 1);
                    shift.driveDate = drive.sked_Drive_Date__c;

                    shiftStart = i == 0 ? driveStart
                        : skedDateTimeUtils.getDateTimeFromDateAndTime(drive.sked_Drive_Date__c, shiftsMetadata.driveShifts[i - 1].endTime, masterData.timezoneSidId);
                    DateTime shiftEnd = i < noOfShifts - 1
                        ? skedDateTimeUtils.addMinutes(shiftStart, drawDurationPerShift, masterData.timezoneSidId)
                        : skedDateTimeUtils.addMinutes(shiftStart, driveDrawHoursInMinutes - drawDurationPerShift * i, masterData.timezoneSidId);

                    shift.startTime = extractLocalTime(shiftStart, masterData.timezoneSidId);
                    shift.endTime = extractLocalTime(shiftEnd, masterData.timezoneSidId);
                    shift.aptSetup = shiftsMetadata.aptSetup;
                    shiftsMetadata.driveShifts.add(shift);
                }
            }
        }

        shiftsMetadata.numberOfDriveShifts = shiftsMetadata.driveShifts.size();

        // 2RBC split is gated on the account accepting automation (helper.js's show2RBCField -
        // its own Fixed-Site/operationType half is moot here, this port is Mobile-only, always
        // false for isFixedSiteDrive). WB has no such gate.
        Boolean accountAcceptsAutomation = drive.sked_Account__r.Accepts_Automation2__c == 'Yes';
        splitProjectedProcedures(shiftsMetadata, false, accountAcceptsAutomation);
        splitProjectedProcedures(shiftsMetadata, true, accountAcceptsAutomation);
        splitScheduledDonors(shiftsMetadata, masterData.timezoneSidId, drive.sked_Drive_Date__c);

        applyProcedureTotals(shiftsMetadata);
        if (config.calculateApt && !masterData.skipAptCalculation) {
            shiftsMetadata.aptSetup = recalculateAptQuantity(drive, shiftsMetadata.totalProceduresProjected);
        }

        String lunchBreakDurationPicklistValue = config.useFixedSiteLunchBreakDuration
            ? masterData.collectionOperation.sked_Lunch_Break_Duration_Fixed_Site__c
            : masterData.collectionOperation.sked_Lunch_Break_Duration_Mobile__c;

        for (Integer i = 0; i < shiftsMetadata.driveShifts.size(); i++) {
            DriveShiftMetadata shift = shiftsMetadata.driveShifts[i];
            applyProcedureTotals(shift);
            shift.aptSetup = shiftsMetadata.aptSetup;
            shift.resourceRoleGroupRoleTimeDataMap = convertToLegacyRoleTimeDataMap(skedRoleTimeCalculator.calculateDriveShiftRoleTimeData(
                drive, masterData.collectionOperation, masterData.driveSite, masterData.travelTimeIndexItemMap, masterData.timezoneSidId,
                widenRoleTimeDataMap(shiftsMetadata.resourceRoleGroupRoleTimeDataMap), shift.driveDate, shift.startTime, shift.endTime, i, shiftsMetadata.driveShifts.size()));
            skedLunchBreakSettings lunchBreakSettings = skedRoleTimeCalculator.calculateDriveShiftLunchBreakSettings(
                masterData.collectionOperation, lunchBreakDurationPicklistValue, masterData.timezoneSidId,
                widenRoleTimeDataMap(shift.resourceRoleGroupRoleTimeDataMap), shift.driveDate, shift.startTime, shift.endTime,
                config.roleTimeRoleGroupsFilter, config.includeTravelTimeInRoleTimeDuration);
            shift.lunchBreakSettings = lunchBreakSettings;
        }

        return shiftsMetadata;
    }

    // DriveShiftMetadata/DriveShiftsMetadata.resourceRoleGroupRoleTimeDataMap stay typed
    // Map<String, RoleTimeData> (NOT changed to skedRoleTimeData) - 2 existing tests
    // (testCalculateDriveShiftsMetadata_multiShiftDrive_recomputesTravelTimeAgainstEachShiftsOwnWindow,
    // testCalculateDriveShiftsMetadata_travelTimeIncludedDriversOnly_excludesNonDrivingRoleShiftTravelTime)
    // read shift.resourceRoleGroupRoleTimeDataMap.get(...) into a
    // skedMobileDriveShiftCalculator.RoleTimeData-typed local variable directly - changing the field
    // type would break both without any code change of their own, violating this plan's own
    // "no changes except the 2 that directly call calculateDriveRoleTimeData" constraint. Both of
    // skedRoleTimeCalculator's new methods return the base skedRoleTimeData type, so their results
    // are converted at this boundary instead, via this one shared helper.
    private static Map<String, RoleTimeData> convertToLegacyRoleTimeDataMap(Map<String, skedRoleTimeData> source) {
        Map<String, RoleTimeData> converted = new Map<String, RoleTimeData>();
        for (String key : source.keySet()) {
            RoleTimeData roleTimeData = new RoleTimeData();
            skedRoleTimeData sourceValue = source.get(key);
            roleTimeData.leadTime = sourceValue.leadTime;
            roleTimeData.travelTime = sourceValue.travelTime;
            roleTimeData.siteLogisticsTo = sourceValue.siteLogisticsTo;
            roleTimeData.setupTime = sourceValue.setupTime;
            roleTimeData.breakdownTime = sourceValue.breakdownTime;
            roleTimeData.travelTime2 = sourceValue.travelTime2;
            roleTimeData.siteLogisticsBack = sourceValue.siteLogisticsBack;
            roleTimeData.wrapUpTime = sourceValue.wrapUpTime;
            roleTimeData.travelTimeCoToSiteVariance = sourceValue.travelTimeCoToSiteVariance;
            roleTimeData.travelTimeSiteToCoVariance = sourceValue.travelTimeSiteToCoVariance;
            converted.put(key, roleTimeData);
        }
        return converted;
    }

    // Wraps calculateDriveRoleTimeData's new flat signature for the internal caller still holding a
    // MasterData bundle - kept private since only calculateDriveShiftsMetadata needs this; the
    // flat-parameter signature is what the 2 existing direct tests moved off of (see
    // skedRoleTimeCalculator_Test.cls).
    private static Map<String, RoleTimeData> calculateDriveRoleTimeDataWrapper(sked_Drive__c drive, MasterData masterData) {
        return convertToLegacyRoleTimeDataMap(skedRoleTimeCalculator.calculateDriveRoleTimeData(
            drive, masterData.roleGroupTimeDetailMap, masterData.roleGroupTimeVarianceMap,
            masterData.collectionOperation, masterData.driveSite, masterData.travelTimeIndexItemMap, masterData.timezoneSidId));
    }

    // Apex generics aren't covariant - Map<String, RoleTimeData> is NOT a Map<String, skedRoleTimeData>
    // even though RoleTimeData extends skedRoleTimeData, so every call from calculateDriveShiftsMetadata
    // into skedRoleTimeCalculator's Map<String, skedRoleTimeData>-typed parameters needs this. Each
    // RoleTimeData value already IS a valid skedRoleTimeData instance (true inheritance), so this only
    // needs to rebuild the Map container, not copy any fields.
    private static Map<String, skedRoleTimeData> widenRoleTimeDataMap(Map<String, RoleTimeData> source) {
        Map<String, skedRoleTimeData> widened = new Map<String, skedRoleTimeData>();
        for (String key : source.keySet()) {
            widened.put(key, source.get(key));
        }
        return widened;
    }

    public static Integer calculateDrawHoursInMinutes(Date driveDate, Time startTime, Time endTime, String timezoneSidId, skedLunchBreakSettings lunchBreakSettings) {
        if (driveDate == null || startTime == null || endTime == null) {
            return 0;
        }
        DateTime start = skedDateTimeUtils.getDateTimeFromDateAndTime(driveDate, startTime, timezoneSidId);
        DateTime finish = skedDateTimeUtils.getDateTimeFromDateAndTime(driveDate, endTime, timezoneSidId);
        Long durationInMinutes = (finish.getTime() - start.getTime()) / 60000;

        if (lunchBreakSettings != null && lunchBreakSettings.lunchBreak && !lunchBreakSettings.lunchBreakBeforeDrawHours) {
            durationInMinutes -= lunchBreakSettings.maximumLunchBreakDuration.longValue();
        }
        return Integer.valueOf(durationInMinutes);
    }

    // Extracts the wall-clock Time-of-day this absolute instant represents in timezoneSidId
    // (mirrors skedDateTimeUtils.convertDateTimeToDateAndTime's DateTime -> Date/Time split).
    public static Time extractLocalTime(DateTime dt, String timezoneSidId) {
        String timeIso = dt.format(skedDateTimeUtils.TIME_ISO_FORMAT, timezoneSidId);
        return (Time) JSON.deserialize('"' + timeIso + '"', Time.class);
    }

    private static void splitScheduledDonors(DriveShiftsMetadata shiftsMetadata, String timezoneSidId, Date driveDate) {
        if (shiftsMetadata.driveShifts.isEmpty()) {
            return;
        }
        Map<String, Decimal> durationByKey = new Map<String, Decimal>();
        Decimal totalDuration = 0;
        for (DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Decimal duration = shiftDurationMinutes(shift, timezoneSidId, driveDate);
            durationByKey.put(shift.key, duration);
            totalDuration += duration;
        }

        Decimal totalDonors = shiftsMetadata.projectedRegisteredDonors;
        Decimal remainingDonors = totalDonors;
        for (DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Decimal percentage = totalDuration == 0 ? 0 : durationByKey.get(shift.key) / totalDuration;
            shift.donorsScheduled = (totalDonors * percentage).setScale(0, System.RoundingMode.CEILING);
            if (shift.donorsScheduled > remainingDonors) {
                shift.donorsScheduled = remainingDonors;
            }
            remainingDonors -= shift.donorsScheduled;
        }
    }

    // excludeOverlappedTime only applies to the 2RBC split; WB always uses the plain shift window.
    private static void splitProjectedProcedures(DriveShiftsMetadata shiftsMetadata, Boolean isWholeBlood, Boolean accountAcceptsAutomation) {
        if (shiftsMetadata.driveShifts.isEmpty()) {
            return;
        }
        if (!isWholeBlood && !accountAcceptsAutomation) {
            return;
        }
        Decimal totalProjected = isWholeBlood ? shiftsMetadata.wbProjectedProcedures : shiftsMetadata.x2rbcProjectedProcedures;
        Boolean excludeOverlappedTime = !isWholeBlood;

        Map<String, Decimal> durationByKey = new Map<String, Decimal>();
        Decimal totalDuration = 0;
        for (Integer i = 0; i < shiftsMetadata.driveShifts.size(); i++) {
            DriveShiftMetadata shift = shiftsMetadata.driveShifts[i];
            Decimal shiftStartMinutes = excludeOverlappedTime
                ? shiftStartMinutesExcludingOverlap(shiftsMetadata.driveShifts, i)
                : minutesOfDay(shift.startTime);
            Decimal shiftEndMinutes = minutesOfDay(shift.endTime);
            Decimal duration = shiftEndMinutes - shiftStartMinutes;
            durationByKey.put(shift.key, duration);
            totalDuration += duration;
        }

        Decimal remaining = totalProjected;
        for (DriveShiftMetadata shift : shiftsMetadata.driveShifts) {
            Decimal percentage = totalDuration == 0 ? 0 : durationByKey.get(shift.key) / totalDuration;
            Decimal scheduled = (totalProjected * percentage).setScale(0, System.RoundingMode.CEILING);
            if (scheduled > remaining) {
                scheduled = remaining;
            }
            remaining -= scheduled;
            if (isWholeBlood) {
                shift.wbProjectedProcedures = scheduled;
            } else {
                shift.x2rbcProjectedProcedures = scheduled;
            }
        }
    }

    private static Decimal shiftStartMinutesExcludingOverlap(List<DriveShiftMetadata> shifts, Integer index) {
        DriveShiftMetadata shift = shifts[index];
        Time effectiveStartTime = shift.startTime;
        if (index > 0 && shifts[index - 1].endTime > shift.startTime) {
            effectiveStartTime = shifts[index - 1].endTime;
        }
        // Matches shiftDurationMinutes's own clamp, below - if the previous shift's end overruns
        // even THIS shift's own end, effectiveStartTime would land past endTime, producing a
        // negative duration in splitProjectedProcedures.
        if (effectiveStartTime > shift.endTime) {
            effectiveStartTime = shift.endTime;
        }
        return minutesOfDay(effectiveStartTime);
    }

    private static Decimal minutesOfDay(Time t) {
        return t.hour() * 60 + t.minute();
    }

    private static Decimal shiftDurationMinutes(DriveShiftMetadata shift, String timezoneSidId, Date driveDate) {
        DateTime start = skedDateTimeUtils.getDateTimeFromDateAndTime(driveDate, shift.startTime, timezoneSidId);
        DateTime finish = skedDateTimeUtils.getDateTimeFromDateAndTime(driveDate, shift.endTime, timezoneSidId);
        if (start.getTime() > finish.getTime()) {
            start = finish;
        }
        return (finish.getTime() - start.getTime()) / 60000.0;
    }

    // ===== Procedure totals / APT =====

    private static void applyProcedureTotals(DriveShiftsMetadata shiftsMetadata) {
        shiftsMetadata.totalProceduresProjected = shiftsMetadata.x2rbcProjectedProcedures + shiftsMetadata.wbProjectedProcedures;
        shiftsMetadata.totalProductsProjected = shiftsMetadata.x2rbcProjectedProcedures * 2 + shiftsMetadata.wbProjectedProcedures;
    }

    private static void applyProcedureTotals(DriveShiftMetadata shift) {
        shift.totalProceduresProjected = shift.x2rbcProjectedProcedures + shift.wbProjectedProcedures;
        shift.totalProductsProjected = shift.x2rbcProjectedProcedures * 2 + shift.wbProjectedProcedures;
    }

    // Requires the drive to be queried with sked_Account__r.Type, sked_Account__r.Industry_Code__c.
    private static Decimal recalculateAptQuantity(sked_Drive__c drive, Decimal totalProceduresProjected) {
        Boolean isEducationDrive = drive.sked_Account__r != null && drive.sked_Account__r.Type == skedConstants.ACCOUNT_TYPE_EDUCATION;
        Boolean isMiddleOrElementary = drive.sked_Account__r != null && (
            drive.sked_Account__r.Industry_Code__c == skedConstants.ACCOUNT_INDUSTRY_CODE_MIDDLE_SCHOOL
            || drive.sked_Account__r.Industry_Code__c == skedConstants.ACCOUNT_INDUSTRY_CODE_ELEMENTARY_SCHOOL);

        Decimal aptQuantity = 0;
        if (isEducationDrive) {
            if (!isMiddleOrElementary) {
                aptQuantity = Math.floor((totalProceduresProjected / 40)).setScale(0);
            }
        } else if (totalProceduresProjected >= 40) {
            aptQuantity = 1;
        }
        return aptQuantity;
    }
}
