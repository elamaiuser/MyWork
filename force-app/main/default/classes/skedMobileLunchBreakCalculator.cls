/**
 * Mobile-specific entry point for lunch-break timing - delegates the actual algorithm to the
 * shared skedLunchBreakCalculator (also used by the Fixed Site engine), supplying Mobile's own
 * staff-role list. Kept as a thin wrapper so existing callers (skedMobileDriveJobBuilder) and this
 * class's own test suite don't need to change.
 */
public with sharing class skedMobileLunchBreakCalculator {

    private static final List<String> STAFF_SETUP_ROLES = new List<String>{ 'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge' };

    public static List<sked_Lunch_Break_Setting__c> loadLunchBreakSettings() {
        return skedLunchBreakCalculator.loadLunchBreakSettings();
    }

    public static void populateLunchBreakTime(skedMobileDriveJobBuilder.ProposedDriveShift proposed,
            skedMobileDriveShiftCalculator.DriveShiftMetadata shiftMetadata, List<sked_Lunch_Break_Setting__c> lunchBreakSettingsConfig,
            String timezoneSidId, Boolean lockLunchBreak, sked_Drive_Shift__c existingShiftRecord) {
        skedLunchBreakCalculator.populateLunchBreakTime(proposed, shiftMetadata, lunchBreakSettingsConfig, timezoneSidId, lockLunchBreak, existingShiftRecord, STAFF_SETUP_ROLES);
    }
}
