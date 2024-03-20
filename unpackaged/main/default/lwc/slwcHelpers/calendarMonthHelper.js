import { cloneDeep, isArray, isDate, padStart, uniqueId } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { classNames } from 'c/slwcUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcDateUtils from 'c/slwcDateUtils';

export default class slwcCalendarHelper {
  configData;
  calendarSettings;

  get dateUtils() {
    return slwcDateUtils.getInstance(this.calendarSettings);
  }
  
  constructor(calendarSettings) {
    this.calendarSettings = calendarSettings;
  }

  getDateRange = (selectedMonth) => {
    return {
      startDate: DateTime.fromFormat(selectedMonth, 'yyyy-MM-dd').startOf('month').toISODate(),
      endDate: DateTime.fromFormat(selectedMonth, 'yyyy-MM-dd').endOf('month').toISODate(),
    }
  }

  parseDateString = (isoString) => {
    return this.dateUtils.dateIso2DateTime(isoString);
  }

  stringifyDateString = (dateInfo) => {
    return this.dateUtils.parseDateTimeInfo(dateInfo.date, dateInfo.time);
  }

  isNullOrEmpty = (value) => {
    return value === undefined || value === null || value === '';
  };

  isAllDayEvent = (event) => {
    let isAllDay = false;
    const endDate = this.parseDateString(event.finish);
    const startDate = this.parseDateString(event.start);
    let checkingEndDate = cloneDeep(endDate.date),
      checkingEndTime = endDate.time;

    if (checkingEndTime === 0) {
      checkingEndDate.setDate(checkingEndDate.getDate() - 1);
      checkingEndTime = 2400;
    }

    isAllDay = event.isAllDay || (checkingEndDate.getTime() > startDate.date.getTime()) || (startDate.time === 0 && checkingEndTime === 2400);

    return isAllDay;
  };

  isInPast = (date, today) => {
    return this.dateUtils.diffDays(today, date) < 0;
  };
                  
  calculateCalendarDays = (calStartDate, regions, today, calEndDate, holidays = [], calendarMessages = []) => {
    let ONE_DAY_TIME = 86400000;
    let tmpDate, startDate, endDate, dw;
    let tmpHoliday, tmpHolidayDateTime, holidayStartDate, holidayEndDate;
    let tmpCalendarMessage, tmpCalendarMessageDateTime, calendarMessageStartDate, calendarMessageEndDate;
    let regionIds, tmpCalStartDate, tmpCalEndDate;
    let yesterday = cloneDeep(today);
    let daysMap = {};
    let regionIdx;

    yesterday.setDate(today.getDate() - 1);
    if (this.calendarSettings && this.calendarSettings && isDate(calStartDate)) {
      //startDate = new Date(calStartDate.getFullYear(), calStartDate.getMonth(), calStartDate.getDate() - calStartDate.getDay());
      startDate = new Date(calStartDate.getFullYear(), calStartDate.getMonth(), calStartDate.getDate());

      if (isDate(calEndDate)) {
        endDate = new Date(calEndDate.getFullYear(), calEndDate.getMonth(), calEndDate.getDate() + 1);
      } else {
        endDate = cloneDeep(startDate);
        endDate.setDate(endDate.getDate() + (7 * (this.calendarSettings.viewPeriod || 2)));
      }

      for (tmpDate = cloneDeep(startDate); tmpDate < endDate; tmpDate.setDate(tmpDate.getDate() + 1)) {
        dw = tmpDate.getDay();
        
        daysMap[tmpDate.getTime()] = {
          // dateIso: dateUtil.dateToString(tmpDate),
          dateIso: DateTime.fromJSDate(tmpDate).toISODate(),
          date: cloneDeep(tmpDate),
          isWeekend: (dw === 0 || dw === 6),
          isInPast: this.isInPast(tmpDate, today),
          isToday: DateTime.fromJSDate(tmpDate).hasSame(DateTime.fromJSDate(today), 'day'),
          isYesterday: DateTime.fromJSDate(tmpDate).hasSame(DateTime.fromJSDate(yesterday), 'day')
        };
      }

      // identify holiday information
      tmpCalStartDate = startDate.getTime();
      tmpCalEndDate = endDate.getTime();
      regionIds = regions ? regions.map(function (region) {
        return region.id;
      }) : [];

      if (holidays && holidays.length > 0) {
        for (let i = 0; i < holidays.length; i++) {
          tmpHoliday = holidays[i];
          if (tmpHoliday && tmpHoliday.startDate && tmpHoliday.endDate) {
            holidayStartDate = DateTime.fromString(tmpHoliday.startDate, 'yyyy-MM-dd').toJSDate().getTime();
            holidayEndDate = DateTime.fromString(tmpHoliday.endDate, 'yyyy-MM-dd').toJSDate().getTime();

            if (holidayStartDate <= tmpCalEndDate && holidayEndDate >= tmpCalStartDate) {
              if (holidayStartDate < tmpCalStartDate) {
                tmpHolidayDateTime = tmpCalStartDate;
              } else {
                tmpHolidayDateTime = holidayStartDate;
              }

              for (; tmpHolidayDateTime <= holidayEndDate && tmpHolidayDateTime <= tmpCalEndDate; tmpHolidayDateTime += ONE_DAY_TIME) {
                if (daysMap[tmpHolidayDateTime]) {
                  if (!isArray(daysMap[tmpHolidayDateTime].holidays)) {
                    daysMap[tmpHolidayDateTime].holidays = [];
                  }

                  daysMap[tmpHolidayDateTime].holidays.push(tmpHoliday);
                }
              }
            }
          }
        }
      }

      if (calendarMessages && calendarMessages.length > 0) {
        for (let i = 0; i < calendarMessages.length; i++) {
          tmpCalendarMessage = calendarMessages[i];
          if (tmpCalendarMessage && tmpCalendarMessage.startDate && tmpCalendarMessage.endDate) {
            calendarMessageStartDate = DateTime.fromString(tmpCalendarMessage.startDate, 'yyyy-MM-dd').toJSDate().getTime();
            calendarMessageEndDate = DateTime.fromString(tmpCalendarMessage.endDate, 'yyyy-MM-dd').toJSDate().getTime();

            if (calendarMessageStartDate <= tmpCalEndDate && calendarMessageEndDate >= tmpCalStartDate) {
              if (calendarMessageStartDate < tmpCalStartDate) {
                tmpCalendarMessageDateTime = tmpCalStartDate;
              } else {
                tmpCalendarMessageDateTime = calendarMessageStartDate;
              }

              for (; tmpCalendarMessageDateTime <= calendarMessageEndDate && tmpCalendarMessageDateTime <= tmpCalEndDate; tmpCalendarMessageDateTime += ONE_DAY_TIME) {
                if (daysMap[tmpCalendarMessageDateTime]) {
                  if (!isArray(daysMap[tmpCalendarMessageDateTime].calendarMessages)) {
                    daysMap[tmpCalendarMessageDateTime].calendarMessages = [];
                  }

                  daysMap[tmpCalendarMessageDateTime].calendarMessages.push(tmpCalendarMessage);
                }
              }
            }
          }
        }
      }
    }


    return Object.values(daysMap).map(day => {
      return {
        ...day,
        hasHolidays: day.holidays && day.holidays.length,
        class: classNames('slds-text-color_weak', {
          'yesterday': day.isYesterday,
          'today': day.isToday,
          'holiday': day.holidays && day.holidays.length,
        })
      }
    })
  };

  buildCalendarWeeks = (selectedDate, today, holidays = [], calendarMessages = []) => {
    let weeks = [];
    let tmpWeek, tmpDate;

    const firstDay = this.calendarSettings.firstDay || 0;
    const date = DateTime.fromString(selectedDate, 'yyyy-MM-dd').toJSDate();
    const currentMonth = date.getMonth();

    let startDate = cloneDeep(date);
    let endDate = cloneDeep(date);
    startDate.setDate(1);
    endDate.setDate(1);

    // identify calendar start date
    // TODO: wrong if firstDay = 1
    startDate.setDate(1 - startDate.getDay() + firstDay);

    // identify calendar end date
    endDate.setMonth(endDate.getMonth() + 1);
    endDate.setDate(endDate.getDate() - 1);
  
    const restDayCount = (6 - endDate.getDay() + firstDay);
    if (restDayCount < 7) {
      endDate.setDate(endDate.getDate() + restDayCount);
    }

    let calendarDays = this.calculateCalendarDays(startDate, [], today, endDate, holidays, calendarMessages);

    if (isArray(calendarDays) && calendarDays.length > 0) {
      calendarDays.forEach(function (calDay, idx) {
        tmpDate = calDay.date;

        if (idx === 0 || tmpDate.getDay() === firstDay) {
          tmpWeek = {
            key: uniqueId('week_'),
            days: []
          }
          weeks.push(tmpWeek);
        }

        // check month
        calDay.isOutOfMonth = (currentMonth >= 0 && calDay.date.getMonth() !== currentMonth);
        calDay.isFirstDayOfMonth = calDay.date.getDate() === 1;
        calDay.isHoliday = false;

        calDay.class = classNames('resource-date-cell', calDay.class, {
          'cal-weekend': calDay.isWeekend,
          'today': calDay.isToday,
          'cal-out-of-month': calDay.isOutOfMonth,
          'holiday': calDay.holidays && calDay.holidays.length,
          'cal-past-day': calDay.isInPast
        });

        tmpWeek.days[(7 + tmpDate.getDay() - firstDay) % 7] = calDay;
      });
    }

    return weeks;
  };

  buildWeekDays = (shortFormat = false) => {
    const WEEK_DAYS = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    let weekDays = [];
    let firstDay = this.calendarSettings.firstDay || 0;

    for (let i = 0 ; i < 7; i++) {
      var weekDay = WEEK_DAYS[((i + firstDay)%7)];
      if(shortFormat) {
        weekDay = weekDay.substring(0, 3); 
      }
      weekDays.push(weekDay);
    }

    return weekDays;
  }
}