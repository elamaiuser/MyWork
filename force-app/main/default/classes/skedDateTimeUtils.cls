public class skedDateTimeUtils {

    private static Map<string, integer> mMapWeekdayIndex;
    private static Map<string, integer> mapWeekdayIndex {
        get {
            if (mMapWeekdayIndex == NULL) {
                mMapWeekdayIndex = new Map<string, integer>();
                mMapWeekdayIndex.put('Sunday', 0);
                mMapWeekdayIndex.put('Monday', 1);
                mMapWeekdayIndex.put('Tuesday', 2);
                mMapWeekdayIndex.put('Wednesday', 3);
                mMapWeekdayIndex.put('Thursday', 4);
                mMapWeekdayIndex.put('Friday', 5);
                mMapWeekdayIndex.put('Saturday', 6);
            }
            return mMapWeekdayIndex;
        }
    }

    public static final string DATE_FORMAT = 'MM/dd/yyyy';
    public static final string TIME_FORMAT = 'h:mm a';
    public static final string DATE_TIME_FORMAT = 'MM/dd/yyyy hh:mm a';
    public static final string DATE_ISO_FORMAT = 'yyyy-MM-dd';
    public static final string DATE_TIME_ISO_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
    public static final string SHORT_DATE_FORMAT = 'MM/dd';
    public static final string TIME_ISO_FORMAT = 'HH:mm:ss.SSS\'Z\'';
    public static final String INT_TIME_FORMAT = 'Hmm';
    public static final Datetime MAX_DATETIME = Datetime.newInstance(4000, 1, 1, 0, 0, 0);
    public static final Datetime MIN_DATETIME = Datetime.newInstance(1970, 1, 1, 0, 0, 0);
    public static final Date MAX_DATE = Date.newInstance(4000, 1, 1);
    public static final Date MIN_DATE = Date.newInstance(1970, 1, 1);

    public static DateTime addDays(DateTime input, integer days, string timezoneSidId) {
        DateTime result = input.addDays(days);
        if (skedSetting.instance.App.daylightSavingDetected == true) {
            Timezone tz = Timezone.getTimezone(timezoneSidId);
            integer inputOffset = tz.getOffset(input) / 60000;
            integer resultOffset = tz.getOffset(result) / 60000;
            result = result.addMinutes(inputOffset - resultOffset);
        }
        return result;
    }

    public static DateTime addMinutes(DateTime input, decimal minutes, string timezoneSidId) {
        return addMinutes(input, integer.valueOf(minutes), timezoneSidId);
    }

    public static DateTime addMinutes(DateTime input, integer minutes, string timezoneSidId) {
        DateTime result = input.addMinutes(minutes);
        if (skedSetting.instance.App.daylightSavingDetected == true) {
            Timezone tz = Timezone.getTimezone(timezoneSidId);
            integer inputOffset = tz.getOffset(input) / 60000;
            integer resultOffset = tz.getOffset(result) / 60000;
            result = result.addMinutes(inputOffset - resultOffset);
        }
        return result;
    }

    public static DateTime addMonths(DateTime input, integer months, string timezoneSidId) {
        DateTime result = input.addMonths(months);
        if (skedSetting.instance.App.daylightSavingDetected == true) {
            Timezone tz = Timezone.getTimezone(timezoneSidId);
            integer inputOffset = tz.getOffset(input) / 60000;
            integer resultOffset = tz.getOffset(result) / 60000;
            result = result.addMinutes(inputOffset - resultOffset);
        }
        return result;
    }

    public static DateTime addYears(DateTime input, integer years, string timezoneSidId) {
        DateTime result = input.addYears(years);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);

        return result;
    }

    public static integer convertTimeNumberToMinutes(decimal input) {
        integer inputInt = integer.valueOf(input);
        return integer.valueOf(inputInt / 100) * 60 + Math.mod(inputInt, 100);
    }
    
    public static integer convertTimeStrToMinutes(string input) {
        integer inputInt = integer.valueOf(input.replace(':', ''));
        return convertTimeNumberToMinutes(inputInt);
    }

    public static Date findWeekStartDate(Date inputDate, string startWeekday) {
        DateTime inputDateTime = DateTime.newInstance(inputDate, Time.newInstance(0, 0, 0, 0));
        String inputDayOfWeek = inputDateTime.format('EEEE');        
        integer inputIndex = mapWeekdayIndex.get(inputDayOfWeek);
        integer inputStartWeekday = mapWeekdayIndex.get(startWeekday);
        
        integer diffDays = inputIndex - inputStartWeekday;
        Date result = inputDate;
        if (diffDays > 0) {
            result = inputDate.addDays(-diffDays);
        }
        else if (diffDays < 0) {
            result = inputDate.addDays(-(7 + diffDays));
        }
        
        return result;
    }

    public static Date getDate(DateTime input, string timezoneSidId) {
        string dateIsoString = input.format(DATE_ISO_FORMAT, timezoneSidId);
        return (Date)Json.deserialize('"' + dateIsoString + '"', Date.class);
    }

    public static Date getDateFromIsoString(string isoString) {
        return (Date)Json.deserialize('"' + isoString + '"', Date.class);
    }

    public static DateTime getDateTimeFromIsoString(string isoString) {
        return (DateTime)Json.deserialize('"' + isoString + '"', DateTime.class);
    }

    public static integer getDifferentMinutes(DateTime dtime1, DateTime dTime2) {
        return Integer.valueOf((dTime2.getTime() - dtime1.getTime()) / 60000);
    }

    public static Decimal getDifferenceInHoursAndMinutes(DateTime dt1, DateTime dt2) {
        Decimal value = Decimal.valueOf(dt2.getTime() - dt1.getTime()) / 3600000;
        return value;
    }
    
    public static string getDifferentMinutesText(DateTime dtime1, DateTime dTime2) {
        string result = '';
        integer minutes = getDifferentMinutes(dtime1, dTime2);
        integer noOfDays = integer.valueOf(minutes / 1440);
        string dayUnit = noOfDays > 1 ? 'days' : 'day';
        result += (noOfDays + ' ' + dayUnit);
        
        minutes = minutes - (noOfDays * 1440);
        if (minutes > 0) {
            integer noOfHours = integer.valueOf(minutes / 60);
            string hourUnit = noOfHours > 1 ? 'hours' : 'hour';
            result += (' ' + noOfHours + ' ' + hourUnit);
        }
        return result;
    }

    public static DateTime getEndOfDate(Date input, string timezoneSidId) {
        DateTime dateStart = getStartOfDate(input, timezoneSidId);
        return addDays(dateStart, 1, timezoneSidId);
    }

    public static DateTime getEndOfDate(DateTime input, string timezoneSidId) {
        DateTime dateStart = getStartOfDate(input, timezoneSidId);
        return addDays(dateStart, 1, timezoneSidId);
    }

    public static DateTime getEndOfDate(string input, string timezoneSidId) {
        Date inputDate = getDateFromIsoString(input);
        DateTime dateStart = getStartOfDate(inputDate, timezoneSidId);
        return addDays(dateStart, 1, timezoneSidId);
    }

    public static DateTime getStartOfDate(DateTime input, string timezoneSidId) {
        Date inputDate = getDate(input, timezoneSidId);
        return getStartOfDate(inputDate, timezoneSidId);
    }

    public static DateTime getStartOfDate(Date input, string timezoneSidId) {
        DateTime result = DateTime.newInstance(input, time.newInstance(0, 0, 0, 0));
        result = toTimezone(result, timezoneSidId);
        return result;
    }

    public static DateTime getStartOfDate(string input, string timezoneSidId) {
        Date inputDate = getDateFromIsoString(input);
        return getStartOfDate(inputDate, timezoneSidId);
    }

    public static DateTime newDateTimeInstance(string dateStr, integer timeInt, string timezoneSidId) {
        if (dateStr != NULL && timeInt != NULL) {
            Date dateValue = skedDateTimeUtils.getDateFromIsoString(dateStr);
            integer timeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(timeInt);
            DateTime dateStart = skedDateTimeUtils.getStartOfDate(dateValue, timezoneSidId);
            DateTime dateTimeValue = skedDateTimeUtils.addMinutes(dateStart, timeInMinutes, timezoneSidId);
            return dateTimeValue;
        }
        return NULL;
    }
    
    public static DateTime newDateTimeInstance(Date dateValue, integer timeInt, string timezoneSidId) {
        if (dateValue != NULL && timeInt != NULL) {
            integer timeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(timeInt);
            DateTime dateStart = skedDateTimeUtils.getStartOfDate(dateValue, timezoneSidId);
            DateTime dateTimeValue = skedDateTimeUtils.addMinutes(dateStart, timeInMinutes, timezoneSidId);
            return dateTimeValue;
        }
        return NULL;
    }

    public static DateTime roundTime(DateTime input, boolean isRoundUp, integer step, string timezoneSidId) {
        DateTime result;
        Integer minute = Integer.valueOf(input.format('mm', timezoneSidId));
        Integer mod = Math.mod(minute, step);
        if (mod == 0) {
            result = input;
        } else {
            integer addedMinutes;
            if (isRoundUp == true) {
                addedMinutes = step - mod;
            }
            else {
                addedMinutes = (-1) * mod;
            }
            result = skedDateTimeUtils.addMinutes(input, addedMinutes, timezoneSidId);
        }
        return result;
    }

    public static DateTime switchTimezone(DateTime input, string fromTimezoneSidId, string toTimezoneSidId) {
        if (fromTimezoneSidId != toTimezoneSidId) {
            TimeZone fromTz = Timezone.getTimeZone(fromTimezoneSidId);
            Timezone toTz = Timezone.getTimeZone(toTimezoneSidId);
            integer offsetMinutes = fromTz.getOffset(input) - toTz.getOffset(input);
            offsetMinutes = offsetMinutes / 60000;
            
            input = addMinutes(input, offsetMinutes, toTimezoneSidId);
        }
        return input;
    }

    public static DateTime toTimezone(DateTime input, string toTimezoneSidId) {
        return switchTimezone(input, UserInfo.getTimeZone().getID(), toTimezoneSidId);
    }
    
    public static void convertDateTimeToDateAndTime(sObject record, string datetimeFieldApiName, string dateFieldApiName, string timeFieldApiName, string timezoneFieldApiName, string timezoneSidId) {
        if (string.isBlank(timezoneSidId)) {
            timezoneSidId = (string)record.get(timezoneFieldApiName);
            timezoneSidId = timezoneSidId != NULL ? timezoneSidId : UserInfo.getTimeZone().getID();
        }
        DateTime dtValue = (DateTime)record.get(datetimeFieldApiName);
        Date dateValue = NULL;
        Time timeValue = NULL;
        if (dtValue != NULL) {
            string dateIso = dtValue.format(DATE_ISO_FORMAT, timezoneSidId);
            string timeIso = dtValue.format(TIME_ISO_FORMAT, timezoneSidId);
            dateValue = (Date)Json.deserialize('"' + dateIso + '"', Date.class);
            timeValue = (Time)Json.deserialize('"' + timeIso + '"', Time.class);
        }
        record.put(dateFieldApiName, dateValue);
        record.put(timeFieldApiName, timeValue);
    }
    
    public static void convertDateAndTimeToDateTime(sObject record, string datetimeFieldApiName, string dateFieldApiName, string timeFieldApiName, string timezoneFieldApiName, string timezoneSidId) {
        if (string.isBlank(timezoneSidId)) {
            timezoneSidId = (string)record.get(timezoneFieldApiName);
            timezoneSidId = timezoneSidId != NULL ? timezoneSidId : UserInfo.getTimeZone().getID();
        }
        
        Date dateValue = (Date)record.get(dateFieldApiName);
        Time timeValue = (Time)record.get(timeFieldApiName);
        
        DateTime dtValue = NULL;
        if (dateValue != NULL && timeValue != NULL) {
            dtValue = DateTime.newInstance(dateValue, timeValue);
            dtValue = switchTimezone(dtValue, UserInfo.getTimeZone().getID(), timezoneSidId);
        }
        record.put(datetimeFieldApiName, dtValue);
    }

    public static DateTime getDateTimeFromDateAndTime(Date dateValue, Time timeValue, String timezone) {
        DateTime dt = DateTime.newInstance(dateValue, timeValue);
        dt = switchTimezone(dt, UserInfo.getTimeZone().getId(), timezone);
        return dt;
    }

    public static Date getValueOrMaxDate(Date input) {
        return input != NULL ? input : MAX_DATE;
    }

    public static Date getValueOrMinDate(Date input) {
        return input != NULL ? input : MIN_DATE;
    }

    public static String getDateStringFromDate(Date dateValue) {
        return dateValue.year() + '-' + dateValue.month() + '-' + dateValue.day();
    }
}