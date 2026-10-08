/**
 * Drive-type-agnostic role-time and travel-time calculation chain, extracted from
 * skedMobileDriveShiftCalculator so the Fixed Site shift calculator can reuse it without
 * duplicating this logic. Fully flat parameters (no bundled context type), matching this
 * ticket's existing pattern (skedDriveShiftTagCalculator, skedSlotGenerator,
 * skedLunchBreakCalculator).
 *
 * calculateMinMaxRoleTimeDuration's resourceRoleGroupsFilter/includeTravelTime params mirror
 * helper.js's calculateMinMaxRoleTimeDuration(drive, resourceRoleGroupRoleTimeDataMap,
 * resourceRoleGroups = []) exactly - a Fixed Site caller passes a filter excluding Driving roles
 * and includeTravelTime = false (helper.js:1837, gated on isMobileDrive); a Mobile caller passes
 * an empty filter (all groups) and includeTravelTime = true.
 */
public class skedRoleTimeCalculator {

    public class RoleTimeDurationRange {
        public Decimal maxDurationBefore = 0;
        public Decimal maxDurationAfter = 0;
    }

    private static final List<String> RESOURCE_ROLE_GROUPS = new List<String>{
        skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES,
        skedConstants.RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES,
        skedConstants.RESOURCE_ROLE_GROUP_STAFF_ROLES
    };

    public static Map<String, skedRoleTimeData> calculateDriveRoleTimeData(sked_Drive__c drive,
            Map<String, sked_Role_Time_Detail__c> roleGroupTimeDetailMap, Map<String, List<sked_Role_Time_Variance__c>> roleGroupTimeVarianceMap,
            Biomed_Collection_Op_Center__c collectionOperation, sked__Location__c driveSite,
            Map<String, sked_Travel_Time_Index_Item__c> travelTimeIndexItemMap, String timezoneSidId) {
        Map<String, skedRoleTimeData> resourceRoleGroupRoleTimeDataMap = new Map<String, skedRoleTimeData>();

        for (String resourceRoleGroup : RESOURCE_ROLE_GROUPS) {
            skedRoleTimeData roleTimeData = new skedRoleTimeData();

            sked_Role_Time_Detail__c roleGroupTimeDetail = roleGroupTimeDetailMap.get(resourceRoleGroup);
            if (roleGroupTimeDetail != null) {
                roleTimeData.leadTime += roleGroupTimeDetail.sked_Lead_Time__c == null ? 0 : roleGroupTimeDetail.sked_Lead_Time__c;
                roleTimeData.breakdownTime += roleGroupTimeDetail.sked_Breakdown_Time__c == null ? 0 : roleGroupTimeDetail.sked_Breakdown_Time__c;
                roleTimeData.setupTime += roleGroupTimeDetail.sked_Setup_Time__c == null ? 0 : roleGroupTimeDetail.sked_Setup_Time__c;
                roleTimeData.wrapUpTime += roleGroupTimeDetail.sked_Wrap_up_Time__c == null ? 0 : roleGroupTimeDetail.sked_Wrap_up_Time__c;
            }

            List<sked_Role_Time_Variance__c> variances = roleGroupTimeVarianceMap.get(resourceRoleGroup);
            if (variances != null) {
                for (sked_Role_Time_Variance__c variance : variances) {
                    Decimal amount = variance.sked_Variation_Amount__c == null ? 0 : variance.sked_Variation_Amount__c;
                    if (variance.sked_Buffer_Type__c == 'Subtract') {
                        amount = -1 * amount;
                    }
                    String appliesTo = variance.sked_Variance_Applies_to__c == null ? '' : variance.sked_Variance_Applies_to__c;
                    if (appliesTo.contains('Lead Time')) {
                        roleTimeData.leadTime += amount;
                    }
                    if (appliesTo.contains('Setup Time')) {
                        roleTimeData.setupTime += amount;
                    }
                    if (appliesTo.contains('Breakdown Time')) {
                        roleTimeData.breakdownTime += amount;
                    }
                    if (appliesTo.contains('Wrap-up Time')) {
                        roleTimeData.wrapUpTime += amount;
                    }
                    Boolean travelTimeVarianceApplies = !collectionOperation.sked_No_Travel_Time__c
                        || resourceRoleGroup == skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES;
                    if (appliesTo.contains('Travel Time To') && travelTimeVarianceApplies) {
                        roleTimeData.travelTimeCoToSiteVariance += amount;
                    }
                    if (appliesTo.contains('Travel Time From') && travelTimeVarianceApplies) {
                        roleTimeData.travelTimeSiteToCoVariance += amount;
                    }
                    if (appliesTo.contains('Site Logistics To')) {
                        roleTimeData.siteLogisticsTo += amount;
                    }
                    if (appliesTo.contains('Site Logistics Back')) {
                        roleTimeData.siteLogisticsBack += amount;
                    }
                }
            }

            calculateDriveTravelTime(drive.sked_Drive_Date__c, drive.sked_Start_Time__c, drive.sked_End_Time__c,
                collectionOperation, driveSite, travelTimeIndexItemMap, timezoneSidId, roleTimeData);
            roleTimeData.travelTime += roleTimeData.travelTimeCoToSiteVariance;
            roleTimeData.travelTime2 += roleTimeData.travelTimeSiteToCoVariance;

            Boolean travelTimeExcludedForNonDrivers = resourceRoleGroup != skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES
                && (drive.sked_Travel_Time_Included__c == 'Drivers Only' || collectionOperation.sked_No_Travel_Time__c);
            if (travelTimeExcludedForNonDrivers) {
                roleTimeData.travelTime = roleTimeData.travelTimeCoToSiteVariance;
                roleTimeData.travelTime2 = roleTimeData.travelTimeSiteToCoVariance;
            }

            resourceRoleGroupRoleTimeDataMap.put(resourceRoleGroup, getAdjustedRoleTimeDetailData(roleTimeData));
        }

        return resourceRoleGroupRoleTimeDataMap;
    }

    // Recomputes travel time against a SHIFT's own start/end window (not necessarily the drive's
    // overall window) - travel-time-index breakdowns vary by time of day, so a multi-shift drive
    // needs one recompute per shift rather than reusing the drive-level value.
    public static void calculateDriveTravelTime(Date driveDate, Time startTime, Time endTime,
            Biomed_Collection_Op_Center__c collectionOperation, sked__Location__c driveSite,
            Map<String, sked_Travel_Time_Index_Item__c> travelTimeIndexItemMap, String timezoneSidId, skedRoleTimeData roleTimeData) {
        Decimal travelTimeToStagingLocation = driveSite.sked_Travel_Time_to_Staging_Location__c != null
            ? driveSite.sked_Travel_Time_to_Staging_Location__c : 45;
        Decimal travelTimeCoToSite = travelTimeToStagingLocation;
        Decimal travelTimeSiteToCo = travelTimeToStagingLocation;

        String driveDateWeekday = skedMobileDriveShiftCalculator.getDayOfWeekName(driveDate);
        DateTime windowStart = skedDateTimeUtils.getDateTimeFromDateAndTime(driveDate, startTime, timezoneSidId);
        DateTime windowEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(driveDate, endTime, timezoneSidId);
        Decimal durationBefore = (roleTimeData.setupTime == null ? 0 : roleTimeData.setupTime) + (roleTimeData.siteLogisticsTo == null ? 0 : roleTimeData.siteLogisticsTo);
        Decimal durationAfter = (roleTimeData.breakdownTime == null ? 0 : roleTimeData.breakdownTime) + (roleTimeData.siteLogisticsBack == null ? 0 : roleTimeData.siteLogisticsBack);
        windowStart = skedDateTimeUtils.addMinutes(windowStart, -1 * durationBefore, timezoneSidId);
        windowEnd = skedDateTimeUtils.addMinutes(windowEnd, durationAfter, timezoneSidId);

        String windowStartIso = windowStart.formatGmt('HH:mm:ss.SSS') + 'Z';
        String windowEndIso = windowEnd.formatGmt('HH:mm:ss.SSS') + 'Z';

        sked_Collection_Op_Staging_Location__c coStagingLocation = findEffectiveStagingLocation(collectionOperation, driveDate);
        sked_Travel_Time_Index_Item__c coToSiteIndex, siteToCoIndex;
        if (coStagingLocation != null) {
            String siteToCoKey = getTravelTimeIndexKey(
                driveSite.sked__GeoLocation__Latitude__s, driveSite.sked__GeoLocation__Longitude__s,
                coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__Latitude__s, coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__Longitude__s
            );
            String coToSiteKey = getTravelTimeIndexKey(
                coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__Latitude__s, coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__Longitude__s,
                driveSite.sked__GeoLocation__Latitude__s, driveSite.sked__GeoLocation__Longitude__s
            );
            siteToCoIndex = travelTimeIndexItemMap.get(siteToCoKey);
            coToSiteIndex = travelTimeIndexItemMap.get(coToSiteKey);
        }

        Decimal coToSiteBreakdown = findTravelTimeBreakdownMinutes(coToSiteIndex, driveDateWeekday, windowStartIso);
        if (coToSiteBreakdown != null) {
            travelTimeCoToSite = coToSiteBreakdown.setScale(0, System.RoundingMode.CEILING);
        }
        Decimal siteToCoBreakdown = findTravelTimeBreakdownMinutes(siteToCoIndex, driveDateWeekday, windowEndIso);
        if (siteToCoBreakdown != null) {
            travelTimeSiteToCo = siteToCoBreakdown.setScale(0, System.RoundingMode.CEILING);
        }

        roleTimeData.travelTime = travelTimeCoToSite;
        roleTimeData.travelTime2 = travelTimeSiteToCo;
    }

    public static sked_Collection_Op_Staging_Location__c findEffectiveStagingLocation(Biomed_Collection_Op_Center__c collectionOperation, Date driveDate) {
        for (sked_Collection_Op_Staging_Location__c stagingLocation : collectionOperation.sked_Collection_Op_Staging_Locations__r) {
            Boolean startOk = stagingLocation.sked_Start_Date__c == null || stagingLocation.sked_Start_Date__c <= driveDate;
            Boolean endOk = stagingLocation.sked_End_Date__c == null || driveDate <= stagingLocation.sked_End_Date__c;
            if (startOk && endOk) {
                return stagingLocation;
            }
        }
        return null;
    }

    public static String getTravelTimeIndexKey(Decimal fromLatitude, Decimal fromLongitude, Decimal toLatitude, Decimal toLongitude) {
        return fromLatitude + ' ' + fromLongitude + ':' + toLatitude + ' ' + toLongitude;
    }

    // Identical for both drive types (driveSite + collectionOperation + driveDate -> travel-time-index
    // map) - moved here (not duplicated) so both skedMobileDriveShiftCalculator and
    // skedFixedSiteDriveShiftCalculator share one copy.
    public static Map<String, sked_Travel_Time_Index_Item__c> loadTravelTimeIndexItemMap(
            sked__Location__c driveSite, Biomed_Collection_Op_Center__c collectionOperation, Date driveDate) {
        sked_Collection_Op_Staging_Location__c coStagingLocation = findEffectiveStagingLocation(collectionOperation, driveDate);
        if (coStagingLocation == null) {
            return new Map<String, sked_Travel_Time_Index_Item__c>();
        }

        String siteToCoKey = getTravelTimeIndexKey(
            driveSite.sked__GeoLocation__Latitude__s, driveSite.sked__GeoLocation__Longitude__s,
            coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__Latitude__s, coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__Longitude__s
        );
        String coToSiteKey = getTravelTimeIndexKey(
            coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__Latitude__s, coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__Longitude__s,
            driveSite.sked__GeoLocation__Latitude__s, driveSite.sked__GeoLocation__Longitude__s
        );

        Map<String, sked_Travel_Time_Index_Item__c> result = new Map<String, sked_Travel_Time_Index_Item__c>();
        for (sked_Travel_Time_Index_Item__c item : [
            SELECT Id, sked_Key__c, sked_Travel_Distance__c, sked_Travel_Time_Breakdown_JSON__c
            FROM sked_Travel_Time_Index_Item__c
            WHERE sked_Key__c IN :new List<String>{ siteToCoKey, coToSiteKey }
        ]) {
            result.put(item.sked_Key__c, item);
        }
        return result;
    }

    private static Decimal findTravelTimeBreakdownMinutes(sked_Travel_Time_Index_Item__c indexItem, String weekday, String timeIso) {
        if (indexItem == null || String.isBlank(indexItem.sked_Travel_Time_Breakdown_JSON__c)) {
            return null;
        }
        List<Object> breakdowns;
        try {
            breakdowns = (List<Object>) JSON.deserializeUntyped(indexItem.sked_Travel_Time_Breakdown_JSON__c);
        } catch (Exception e) {
            return null;
        }
        for (Object entry : breakdowns) {
            Map<String, Object> window = (Map<String, Object>) entry;
            if (window.get('weekday') == weekday
                    && String.valueOf(window.get('startOfWindow')) <= timeIso
                    && timeIso <= String.valueOf(window.get('endOfWindow'))) {
                Object travelTime = window.get('travelTime');
                return travelTime == null ? null : Decimal.valueOf(String.valueOf(travelTime));
            }
        }
        return null;
    }

    private static skedRoleTimeData getAdjustedRoleTimeDetailData(skedRoleTimeData roleTimeData) {
        roleTimeData.leadTime = maxZero(roleTimeData.leadTime);
        roleTimeData.setupTime = maxZero(roleTimeData.setupTime);
        roleTimeData.breakdownTime = maxZero(roleTimeData.breakdownTime);
        roleTimeData.wrapUpTime = maxZero(roleTimeData.wrapUpTime);
        roleTimeData.travelTime = maxZero(roleTimeData.travelTime);
        roleTimeData.travelTime2 = maxZero(roleTimeData.travelTime2);
        roleTimeData.siteLogisticsTo = maxZero(roleTimeData.siteLogisticsTo);
        roleTimeData.siteLogisticsBack = maxZero(roleTimeData.siteLogisticsBack);
        return roleTimeData;
    }

    private static Decimal maxZero(Decimal value) {
        return value == null || value < 0 ? 0 : value;
    }

    // resourceRoleGroupsFilter empty = no filter (every group considered), matching helper.js's
    // default resourceRoleGroups = []. includeTravelTime mirrors helper.js's isMobileDrive(drive)
    // gate - a Mobile caller always passes true; Fixed Site always passes false (helper.js:1837-1840).
    public static RoleTimeDurationRange calculateMinMaxRoleTimeDuration(
            Map<String, skedRoleTimeData> resourceRoleGroupRoleTimeDataMap, List<String> resourceRoleGroupsFilter, Boolean includeTravelTime) {
        RoleTimeDurationRange range = new RoleTimeDurationRange();
        for (String resourceRoleGroup : resourceRoleGroupRoleTimeDataMap.keySet()) {
            if (!resourceRoleGroupsFilter.isEmpty() && !resourceRoleGroupsFilter.contains(resourceRoleGroup)) {
                continue;
            }
            skedRoleTimeData roleTimeData = resourceRoleGroupRoleTimeDataMap.get(resourceRoleGroup);
            Decimal durationBefore = roleTimeData.leadTime + roleTimeData.setupTime + roleTimeData.siteLogisticsTo;
            Decimal durationAfter = roleTimeData.breakdownTime + roleTimeData.wrapUpTime + roleTimeData.siteLogisticsBack;
            if (includeTravelTime) {
                durationBefore += roleTimeData.travelTime;
                durationAfter += roleTimeData.travelTime2;
            }
            if (durationBefore > range.maxDurationBefore) {
                range.maxDurationBefore = durationBefore;
            }
            if (durationAfter > range.maxDurationAfter) {
                range.maxDurationAfter = durationAfter;
            }
        }
        return range;
    }

    // shiftIndex/totalShiftCount drive the setup/breakdown threshold clamps - only the drive's
    // FIRST shift can have its setup time clamped, only the LAST shift can have its breakdown time
    // clamped (mirrors the drive-level calculateDriveRoleTimeData's own per-shift recompute).
    public static Map<String, skedRoleTimeData> calculateDriveShiftRoleTimeData(sked_Drive__c drive,
            Biomed_Collection_Op_Center__c collectionOperation, sked__Location__c driveSite,
            Map<String, sked_Travel_Time_Index_Item__c> travelTimeIndexItemMap, String timezoneSidId,
            Map<String, skedRoleTimeData> driveLevelRoleTimeDataMap, Date shiftDriveDate, Time shiftStartTime, Time shiftEndTime,
            Integer shiftIndex, Integer totalShiftCount) {
        Decimal breakdownTimeThreshold = collectionOperation.sked_Breakdown_Time_Threshold__c;
        Decimal setupTimeThreshold = collectionOperation.sked_Setup_Time_Threshold__c;

        Map<String, skedRoleTimeData> result = new Map<String, skedRoleTimeData>();
        for (String resourceRoleGroup : driveLevelRoleTimeDataMap.keySet()) {
            skedRoleTimeData roleTimeData = cloneRoleTimeData(driveLevelRoleTimeDataMap.get(resourceRoleGroup));

            if (shiftIndex > 0 && setupTimeThreshold != null && roleTimeData.setupTime > setupTimeThreshold) {
                roleTimeData.setupTime = setupTimeThreshold;
            }
            if (shiftIndex < totalShiftCount - 1 && breakdownTimeThreshold != null && roleTimeData.breakdownTime > breakdownTimeThreshold) {
                roleTimeData.breakdownTime = breakdownTimeThreshold;
            }

            calculateDriveTravelTime(shiftDriveDate, shiftStartTime, shiftEndTime, collectionOperation, driveSite, travelTimeIndexItemMap, timezoneSidId, roleTimeData);
            roleTimeData.travelTime += roleTimeData.travelTimeCoToSiteVariance;
            roleTimeData.travelTime2 += roleTimeData.travelTimeSiteToCoVariance;

            Boolean travelTimeExcludedForNonDrivers = resourceRoleGroup != skedConstants.RESOURCE_ROLE_GROUP_DRIVING_ROLES
                && (drive.sked_Travel_Time_Included__c == 'Drivers Only' || collectionOperation.sked_No_Travel_Time__c);
            if (travelTimeExcludedForNonDrivers) {
                roleTimeData.travelTime = roleTimeData.travelTimeCoToSiteVariance;
                roleTimeData.travelTime2 = roleTimeData.travelTimeSiteToCoVariance;
            }

            result.put(resourceRoleGroup, getAdjustedRoleTimeDetailData(roleTimeData));
        }
        return result;
    }

    private static skedRoleTimeData cloneRoleTimeData(skedRoleTimeData source) {
        skedRoleTimeData copy = new skedRoleTimeData();
        copy.leadTime = source.leadTime;
        copy.travelTime = source.travelTime;
        copy.siteLogisticsTo = source.siteLogisticsTo;
        copy.setupTime = source.setupTime;
        copy.breakdownTime = source.breakdownTime;
        copy.travelTime2 = source.travelTime2;
        copy.siteLogisticsBack = source.siteLogisticsBack;
        copy.wrapUpTime = source.wrapUpTime;
        copy.travelTimeCoToSiteVariance = source.travelTimeCoToSiteVariance;
        copy.travelTimeSiteToCoVariance = source.travelTimeSiteToCoVariance;
        return copy;
    }

    // lunchBreakDurationPicklistValue is whichever of collectionOperation.sked_Lunch_Break_Duration_Mobile__c /
    // sked_Lunch_Break_Duration_Fixed_Site__c the caller's drive type needs (helper.js:1799-1803's branch) -
    // the caller decides which field, this method stays drive-type-agnostic.
    public static skedLunchBreakSettings calculateDriveShiftLunchBreakSettings(Biomed_Collection_Op_Center__c collectionOperation,
            String lunchBreakDurationPicklistValue, String timezoneSidId, Map<String, skedRoleTimeData> shiftRoleTimeDataMap,
            Date shiftDriveDate, Time shiftStartTime, Time shiftEndTime, List<String> resourceRoleGroupsFilter, Boolean includeTravelTime) {
        skedLunchBreakSettings settings = new skedLunchBreakSettings();
        settings.lunchBreakBeforeDrawHours = collectionOperation.sked_Lunch_Break_Before_Draw_Hours__c;
        // sked_Lunch_Break_Duration_Mobile__c/sked_Lunch_Break_Duration_Fixed_Site__c are Picklists (numeric-looking string values), not Number fields.
        settings.maximumLunchBreakDuration = String.isBlank(lunchBreakDurationPicklistValue) ? 0 : Decimal.valueOf(lunchBreakDurationPicklistValue);
        settings.unpaidLunchBreakDuration = collectionOperation.sked_Unpaid_Lunch_Break_Duration__c == null ? 0 : collectionOperation.sked_Unpaid_Lunch_Break_Duration__c;

        RoleTimeDurationRange durationRange = calculateMinMaxRoleTimeDuration(shiftRoleTimeDataMap, resourceRoleGroupsFilter, includeTravelTime);
        Integer shiftDrawHoursInMinutes = skedMobileDriveShiftCalculator.calculateDrawHoursInMinutes(shiftDriveDate, shiftStartTime, shiftEndTime, timezoneSidId, null);
        Decimal shiftLengthInMinutes = shiftDrawHoursInMinutes + durationRange.maxDurationBefore + durationRange.maxDurationAfter;
        if (shiftLengthInMinutes >= 360 && collectionOperation.sked_Lunch_Break__c) {
            settings.lunchBreak = true;
        }
        return settings;
    }
}
