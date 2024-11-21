@isTest
public class skedDateTimeUtils_Test {

    static testMethod void mainTest() {
        string timezoneSidId = UserInfo.getTimeZone().getID();
        skedSetting.instance.App.setTimezoneSidId(timezoneSidId);
        DateTime current = DateTime.now();
        skedDateTimeUtils.addDays(current, 1, timezoneSidId);
        skedDateTimeUtils.addMinutes(current, 15, timezoneSidId);
        skedDateTimeUtils.addMinutes(current, 15.0, timezoneSidId);
        skedDateTimeUtils.addMonths(current, 1, timezoneSidId);
        skedDateTimeUtils.addYears(current, 1, timezoneSidId);
        skedDateTimeUtils.convertTimeNumberToMinutes(1700);
        Date currentDate = skedDateTimeUtils.getDate(current, timezoneSidId);
        skedDateTimeUtils.getDateFromIsoString('2030-01-01');
        skedDateTimeUtils.getDateTimeFromIsoString('2030-01-01T00:00:00Z');
        
        DateTime next10Mins = skedDateTimeUtils.addMinutes(current, 10, timezoneSidId);
        skedDateTimeUtils.getDifferentMinutes(current, next10Mins);
        
        skedDateTimeUtils.getEndOfDate(current, timezoneSidId);
        skedDateTimeUtils.getEndOfDate(currentDate, timezoneSidId);
        skedDateTimeUtils.getEndOfDate('2030-01-01', timezoneSidId);
        
        skedDateTimeUtils.getStartOfDate(current, timezoneSidId);
        skedDateTimeUtils.getStartOfDate(currentDate, timezoneSidId);
        skedDateTimeUtils.getStartOfDate('2030-01-01', timezoneSidId);
        
        skedDateTimeUtils.newDateTimeInstance(currentDate, 900, timezoneSidId);
        skedDateTimeUtils.newDateTimeInstance('2030-01-01', 900, timezoneSidId);
        
        skedDateTimeUtils.roundTime(current, true, 30, timezoneSidId);
        skedDateTimeUtils.roundTime(current, false, 30, timezoneSidId);
        
        skedDateTimeUtils.switchTimezone(current, timezoneSidId, 'GMT');
        skedDateTimeUtils.toTimezone(current, 'GMT');
        
        skedDateTimeUtils.findWeekStartDate(currentDate, 'Sunday');
    }
}