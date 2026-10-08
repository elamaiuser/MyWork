/**
 * Shared Collection Operation Time Block matching logic (day-of-week/date-range/CO/shift-time),
 * ported from the slwcDriveGenerator LWC's isDriveUseTimeBlock/findAvailableCOTimeBlocks/
 * findAvailableTimeBlocks in helper.js. Used by both skedMobileDriveJobBuilder (assigning a
 * shift's time block during regen) and skedDriveContentionValidator (validating that assignment
 * still holds at save time) - both need byte-identical matching so the two can never disagree
 * about what "available" means.
 */
public with sharing class skedCollectionOperationTimeBlockMatcher {

    // A Non Integrated WB Fixed Site drive is never treated as Fixed Site, even though its
    // typeOfDrive otherwise matches - mirrors skedDCRApplyService.saveDrive's identical expression.
    public static Boolean isFixedSiteDrive(sked_Drive__c drive) {
        return drive.sked_Type_of_Drive__c == skedConstants.DRIVE_TYPE_FIXED_SITE
            && drive.sked_Operation_Type__c != skedConstants.OPERATION_TYPE_WB;
    }

    public static Boolean isDriveUseTimeBlock(sked_Drive__c drive, List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks) {
        return !isFixedSiteDrive(drive) && !findAvailableCOTimeBlocks(drive, collectionOperationTimeBlocks).isEmpty();
    }

    // CO Time Block records valid for this drive's CO, date, and day of week, ignoring shift
    // start/end time. A null Effective_End_Date__c is preserved as "never valid" (not
    // "open-ended") - the source's own string/date comparison behaves that way, a quirk kept
    // intentionally rather than fixed.
    public static List<Collection_Operation_Time_Block__c> findAvailableCOTimeBlocks(sked_Drive__c drive,
            List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks) {
        List<Collection_Operation_Time_Block__c> available = new List<Collection_Operation_Time_Block__c>();
        if (drive.sked_Drive_Date__c == null) {
            return available;
        }
        String driveDayOfWeek = skedMobileDriveShiftCalculator.getDayOfWeekName(drive.sked_Drive_Date__c);
        for (Collection_Operation_Time_Block__c coTimeBlock : collectionOperationTimeBlocks) {
            Boolean isDriveDateValid = coTimeBlock.Effective_Start_Date__c <= drive.sked_Drive_Date__c
                && coTimeBlock.Effective_End_Date__c != null && drive.sked_Drive_Date__c <= coTimeBlock.Effective_End_Date__c;
            Boolean isCollectionOperationValid = coTimeBlock.Collection_Operation__c == drive.sked_Collection_Operation__c;
            Boolean isDayOfWeekValid = coTimeBlock.Time_Block__r.Days_of_Week__c != null
                && coTimeBlock.Time_Block__r.Days_of_Week__c.split(';').contains(driveDayOfWeek);
            if (isDriveDateValid && isCollectionOperationValid && isDayOfWeekValid) {
                available.add(coTimeBlock);
            }
        }
        return available;
    }

    // The CO Time Blocks above, further restricted to ones whose Time_Block window fully covers
    // [startTime, endTime].
    public static List<Collection_Operation_Time_Block__c> findAvailableTimeBlocks(sked_Drive__c drive, Time startTime, Time endTime,
            List<Collection_Operation_Time_Block__c> collectionOperationTimeBlocks) {
        List<Collection_Operation_Time_Block__c> available = new List<Collection_Operation_Time_Block__c>();
        for (Collection_Operation_Time_Block__c coTimeBlock : findAvailableCOTimeBlocks(drive, collectionOperationTimeBlocks)) {
            if (coTimeBlock.Time_Block__r.Start_Time__c <= startTime && endTime <= coTimeBlock.Time_Block__r.End_Time__c) {
                available.add(coTimeBlock);
            }
        }
        return available;
    }
}
