/**
 * Shared lunch-break timing logic, extracted from skedMobileLunchBreakCalculator so a future
 * Fixed Site engine can reuse it - the underlying algorithm (mobileGenerator.js/fixedSiteGenerator.js's
 * populateLunchBreakTime/moveLunchBreakToDuringDrawHours) is identical between the two drive types
 * except for the staff-role list used to compute headcount, which callers supply.
 *
 * Lock/restore (sked_Drive__c.sked_Lock_Lunch_Break__c, a drive-wide "Lock Lunch Break?" toggle, not
 * a per-shift edit): when locked and an existing (pre-regen) shift is available, only the on/off and
 * before/during-draw-hours BOOLEANS are restored from it - the literal start/end time and duration
 * are always recomputed fresh below, lock or no lock. Every branch past the restore point reads back
 * off shiftRecord's own just-assigned flags (not lunchBreakSettings' fresh values), matching the JS
 * reading driveShift.lunchBreak/lunchBreakBeforeDrawHours (the possibly-restored value) for the rest
 * of the function.
 */
public with sharing class skedLunchBreakCalculator {

    public static List<sked_Lunch_Break_Setting__c> loadLunchBreakSettings() {
        return [
            SELECT Id, sked_Maximum_Lunch_Break_Duration__c,
                (SELECT Id, sked_Lunch_Break_Duration__c, sked_Max_Number_of_Staff__c, sked_Min_Number_of_Staff__c, sked_Slot_Reduction__c
                 FROM sked_Lunch_Break_Definitions__r)
            FROM sked_Lunch_Break_Setting__c
        ];
    }

    public static void populateLunchBreakTime(skedProposedDriveShift proposed,
            skedDriveShiftMetadata shiftMetadata, List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig,
            String timezoneSidId, Boolean lockLunchBreak, sked_Drive_Shift__c existingShiftRecord, List<String> staffSetupRoles) {
        skedLunchBreakSettings lunchBreakSettings = shiftMetadata.lunchBreakSettings;
        sked_Drive_Shift__c shiftRecord = proposed.shiftRecord;

        if (lockLunchBreak == true && existingShiftRecord != null) {
            shiftRecord.sked_Lunch_Break__c = existingShiftRecord.sked_Lunch_Break__c;
            shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c = existingShiftRecord.sked_Lunch_Break_Before_Draw_Hours__c;
        } else {
            shiftRecord.sked_Lunch_Break__c = lunchBreakSettings.lunchBreak;
            shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c = lunchBreakSettings.lunchBreakBeforeDrawHours;
        }

        if (shiftRecord.sked_Lunch_Break__c != true) {
            shiftRecord.sked_Lunch_Break_Start_Time__c = null;
            shiftRecord.sked_Lunch_Break_End_Time__c = null;
            shiftRecord.sked_Lunch_Break_Duration__c = null;
            return;
        }

        DateTime drawHoursStart = skedDateTimeUtils.getDateTimeFromDateAndTime(shiftMetadata.driveDate, shiftMetadata.startTime, timezoneSidId);
        DateTime lunchStart;
        DateTime lunchEnd;
        Decimal duration;

        if (shiftRecord.sked_Lunch_Break_Before_Draw_Hours__c == true) {
            duration = lunchBreakSettings.unpaidLunchBreakDuration;
            lunchEnd = drawHoursStart;
            lunchStart = skedDateTimeUtils.addMinutes(lunchEnd, -duration, timezoneSidId);
        } else {
            sked_Lunch_Break_Setting__c matchedSetting = findLunchBreakSetting(lunchBreakSettingsConfig, lunchBreakSettings.maximumLunchBreakDuration);
            Decimal staffSetup = calculateStaffSetup(proposed.jobs, staffSetupRoles);
            sked_Lunch_Break_Definition__c matchedDefinition = findLunchBreakDefinition(matchedSetting, staffSetup);
            duration = matchedDefinition.sked_Lunch_Break_Duration__c;

            DateTime drawHoursEnd = skedDateTimeUtils.getDateTimeFromDateAndTime(shiftMetadata.driveDate, shiftMetadata.endTime, timezoneSidId);
            Decimal drawHoursDuration = (drawHoursEnd.getTime() - drawHoursStart.getTime()) / 60000;
            Decimal durationBeforeLunch = Math.floor((drawHoursDuration - duration) / 2);
            if (Math.mod(durationBeforeLunch.intValue(), 15) != 0) {
                durationBeforeLunch = Math.floor(durationBeforeLunch / 15) * 15;
            }
            lunchStart = skedDateTimeUtils.addMinutes(drawHoursStart, durationBeforeLunch, timezoneSidId);
            lunchEnd = skedDateTimeUtils.addMinutes(lunchStart, duration, timezoneSidId);
        }

        shiftRecord.sked_Lunch_Break_Duration__c = duration;
        shiftRecord.sked_Lunch_Break_Start_Time__c = skedMobileDriveShiftCalculator.extractLocalTime(lunchStart, timezoneSidId);
        shiftRecord.sked_Lunch_Break_End_Time__c = skedMobileDriveShiftCalculator.extractLocalTime(lunchEnd, timezoneSidId);
    }

    // Both return null when nothing matches (no setting for the duration, or no definition spanning
    // the computed staff count) - populateLunchBreakTime deliberately lets that surface as an NPE,
    // treating it as a config-data error (e.g. a Collection Operation's lunch-break duration has no
    // matching sked_Lunch_Break_Setting__c) rather than silently guessing a fallback.
    public static sked_Lunch_Break_Setting__c findLunchBreakSetting(List<sked_Lunch_Break_Setting__c> config, Decimal maximumLunchBreakDuration) {
        for (sked_Lunch_Break_Setting__c setting : config) {
            if (String.isNotBlank(setting.sked_Maximum_Lunch_Break_Duration__c)
                    && Decimal.valueOf(setting.sked_Maximum_Lunch_Break_Duration__c) == maximumLunchBreakDuration) {
                return setting;
            }
        }
        return null;
    }

    public static sked_Lunch_Break_Definition__c findLunchBreakDefinition(sked_Lunch_Break_Setting__c setting, Decimal staffSetup) {
        for (sked_Lunch_Break_Definition__c definition : setting.sked_Lunch_Break_Definitions__r) {
            if (definition.sked_Min_Number_of_Staff__c <= staffSetup && staffSetup <= definition.sked_Max_Number_of_Staff__c) {
                return definition;
            }
        }
        return null;
    }

    // Derived from the proposed shift's own jobs rather than a resourceQuantityByShiftKey map,
    // mirroring getDriveShiftResourceQuantity's job-based extraction. The VP/HH special case is
    // harmless for a role list that never contains 'VP/HH' (e.g. Fixed Site's) - the ternary simply
    // never takes that branch.
    public static Decimal calculateStaffSetup(List<sked__Job__c> jobs, List<String> staffSetupRoles) {
        Decimal staffSetup = 0;
        for (sked__Job__c job : jobs) {
            if (!staffSetupRoles.contains(job.sked_Resource_Role__c)) {
                continue;
            }
            Decimal quantity = job.sked_Resource_Role__c == 'VP/HH' ? job.sked_VPHH_Quantity__c : job.sked__Quantity__c;
            staffSetup += quantity == null ? 0 : quantity;
        }
        return staffSetup;
    }
}