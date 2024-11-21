import {
    DateTime
} from 'c/luxon';
import {
    padStart,
    isString,
    cloneDeep
} from 'c/lodash';
import { isNullOrEmpty } from 'c/slwcUtils';

const firstDayMap = {
    'Sunday': 0,
    'Monday': 1,
    'Tuesday': 2,
    'Wednesday': 3,
    'Thursday': 4,
    'Friday': 5,
    'Saturday': 6
}

class SlwcDateUtils {
    timezone;
    dateIsoFormat = 'yyyy-MM-dd';
    timeIsoFormat = 'HH:mm:ss.SSS';
    timeNumberFormat = 'Hmm';
    patternDateTimeCache = {};
    constructor(settings) {
        if (!settings) return;
        this.timezone = settings.timezone;
    }

    dateIso2DateTime = (dateIso) => {
        const dateObj = DateTime.fromISO(dateIso, {
            zone: this.timezone
        });

        return {
            date: DateTime.fromFormat(dateObj.startOf('day').toFormat('yyyy-MM-dd HH:mm'), 'yyyy-MM-dd HH:mm').toJSDate(),
            time: Number(dateObj.toFormat(this.timeNumberFormat))
        }
    }

    dateIso2WeeekDay = (dateIso) => {
        const { weekday, weekdayShort, weekdayLong } = DateTime.fromISO(dateIso, {
            zone: this.timezone
        });

        return {
            weekday,
            weekdayShort,
            weekdayLong,
        }
    }

    date2dateIso = (date) => {
        const dateIso = isString(date) ? date : DateTime.fromJSDate(date).toFormat(this.dateIsoFormat);

        let startOfDate = DateTime.fromISO(dateIso, {
            zone: this.timezone
        });

        return startOfDate.toUTC().toISODate();
    }

    time2Minute = (timeValue) => {
        return (Math.floor(timeValue / 100) * 60) + Math.round(timeValue % 100);
    };

    minute2Time = (minuteValue) => {
        let tsH = Math.floor(minuteValue / 60);
        let tsM = Math.round(minuteValue % 60);

        return ((tsH * 100) + tsM);
    };

    getFirstDayValue = (firstDayString) => {
        if(!firstDayString) return 0; //Sunday
        return firstDayMap[firstDayString] || 0;
    }

    startOfWeek(date, firstDay) {
        if(isString(date)) {
            date = DateTime.fromISO(date);
        }

        const day = date.toJSDate().getDay();
        return date.minus({
            day: (day + 7 - firstDay) % 7
        })
    }

    startOf = (date, unit) => {
        let temp = isString(date) ? DateTime.fromISO(date, {
            zone: this.timezone
        }) : DateTime.fromJSDate(date);
        let result = temp.startOf(unit);

        if (unit === 'week') {
            //Luxon always return Monday as first day => need to - 1
            result = result.minus({
                days: 1
            })
        }

        return result.toISODate();
    }

    endOf = (date, unit) => {
        let temp = isString(date) ? DateTime.fromISO(date, {
            zone: this.timezone
        }) : DateTime.fromJSDate(date);

        if (unit === 'week') {
            temp = temp.plus({
                days: 1
            })
        }

        let result = temp.endOf(unit);

        if (unit === 'week') {
            //Luxon always return Monday as first day => need to - 1
            result = result.minus({
                days: 1
            })
        }

        return result.toISODate();
    }

    diffDays = (date1, date2) => {
        if (!date1 || !date2) return 0;

        let DAY_TIME_VALUE = 86400000;
        let _date1 = new Date(date1);
        let _date2 = new Date(date2);

        _date1.setHours(0, 0, 0, 0);
        _date2.setHours(12, 0, 0, 0);

        return Math.floor((_date2.getTime() - _date1.getTime()) / DAY_TIME_VALUE);
    }

    dateToStringNative = (date) => {
        if (!date) return;
        if (isString(date)) return date;

        let fullYearString = String(date.getFullYear());
        let monthString = String(date.getMonth() + 1);
        let dateString = String(date.getDate());
        if (monthString.length === 1) {
            monthString = '0' + monthString;
        }

        if (dateString.length === 1) {
            dateString = '0' + dateString;
        }

        return fullYearString + '-' + monthString + '-' + dateString;
    };

    getDateTimeInfo = (timestamp) => {
        if(isNullOrEmpty(timestamp)) return null;

        let mm;
        let dateTimeInfo = {
            dateTime: null,
            date: null,
            timeNumber: null,
            dateIso: null
        };

        if (isString(timestamp)) {
            mm = DateTime.fromISO(timestamp, {
                zone: this.timezone
            });
        } else if (this.isNumber(timestamp)) {
            mm = DateTime.fromMillis(timestamp, {
                zone: this.timezone
            });
        } else if (this.isDate(timestamp)) {
            mm = DateTime.fromJSDate(timestamp, {
                zone: this.timezone
            });
        }

        dateTimeInfo.date = new Date(mm.year, mm.month - 1, mm.day, mm.hour, mm.minute, mm.second, 0);

        dateTimeInfo.timeNumber = Number(DateTime.fromJSDate(dateTimeInfo.date).toFormat(this.timeNumberFormat));
        dateTimeInfo.dateTime = cloneDeep(dateTimeInfo.date);
        dateTimeInfo.dateIso = DateTime.fromJSDate(dateTimeInfo.date).toISODate();
        dateTimeInfo.timeIso = DateTime.fromJSDate(dateTimeInfo.date).toFormat(this.timeIsoFormat);
        dateTimeInfo.date.setHours(0, 0, 0, 0);
        
        return dateTimeInfo;
    };

    parseDateTimeInfo = (date, time) => {
        const timeIso = DateTime.fromFormat(padStart(time, 3, '0'), this.timeNumberFormat).toFormat(this.timeIsoFormat);
        const dateIso = isString(date) ? date : DateTime.fromJSDate(date).toFormat(this.dateIsoFormat);

        let dateTimeObj = DateTime.fromISO(dateIso + 'T' + timeIso, {
            zone: this.timezone
        });

        return dateTimeObj.toUTC().toISO();
    };

    convertTimeStrToTimeNumber(input) {
        return Number(input.replace(':', ''));
    };

    compareDateJS(date1, date2) {
        if (!date1 || !date2) return null;
        let date1Time = isString(date1) ? (new Date(date1).getTime()) : date1.getTime();
        let date2Time = isString(date2) ? (new Date(date2).getTime()) : date2.getTime();
        return date1Time === date2Time ? 0 : (date1Time > date2Time ? 1 : -1);
    }

    isDate(myDate) {
        return myDate?.constructor?.toString().indexOf("Date") > -1;
    }

    isNumber(myDate) {
        return myDate?.constructor?.toString().indexOf("Number") > -1;
    }

    addDay(date, noDay) {
        if (this.isDate(date) && this.isNumber(noDay)) {
            let newDate = new Date(date);
            newDate.setDate(newDate.getDate() + noDay);
            return newDate;
        }
        return date;
    };

    addMinute(date, noMinute) {
        if (this.isDate(date) && this.isNumber(noMinute)) {
            let newDate = new Date(date);
            newDate.setMinutes(newDate.getMinutes() + noMinute);
            return newDate;
        }
        return date;
    };

    patternDateTimeCache = {};
    correctPatternDateTimes(date, timeNumber, timezoneSidId) {
        let key = date + timeNumber + timezoneSidId;
        if (this.patternDateTimeCache[key]) {
            return this.patternDateTimeCache[key];
        }

        //correct time by time
        let startDateTimeValue = this.parseDateTimeInfo(date, timeNumber);
        this.patternDateTimeCache[key] = this.getDateTimeInfo(startDateTimeValue, timezoneSidId);

        return this.patternDateTimeCache[key];
    }

    generateDateRange(fromDate, toDate) {
        let dateRange = [];
        let tempDt = new Date(fromDate);
        while (this.compareDateJS(tempDt, toDate) <= 0) {
            dateRange.push(tempDt);
            tempDt = this.addDay(tempDt, 1);
        }

        return dateRange;
    }
};

export default {
    getInstance: (settings) => {
        return new SlwcDateUtils(settings);
    },
    firstDayMap,
}