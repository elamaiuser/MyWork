import { cloneDeep, isArray, isDate, padStart } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { classNames } from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';

export default class slwcCalendarHelper {
  configData;
  calendarSettings;
  gridRenderSettings;

  get dateUtils() {
    return slwcDateUtils.getInstance(this.calendarSettings);
  }
  
  constructor(calendarSettings, gridRenderSettings) {
    this.calendarSettings = calendarSettings;
    this.gridRenderSettings = gridRenderSettings;
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

  getRemValue = (timeValue) => {
    return ((Math.round((timeValue / this.calendarSettings.calendarStep) * 1000) / 1000) * this.gridRenderSettings.slotSize.h);
  };

  isAllDayEvent = (event) => {
    let isAllDay = false;
    const endDate = this.dateUtils.dateIso2DateTime(event.finish);
    const startDate = this.dateUtils.dateIso2DateTime(event.start);
    let checkingEndDate = cloneDeep(endDate.date),
      checkingEndTime = endDate.time;

    if (checkingEndTime === 0) {
      checkingEndDate.setDate(checkingEndDate.getDate() - 1);
      checkingEndTime = 2400;
    }

    isAllDay = event.isAllDay || (checkingEndDate.getTime() > startDate.date.getTime()) || (startDate.time === 0 && checkingEndTime === 2400);

    return isAllDay;
  };

  /**
   * check if 2 events are overlapped
   */
  isEventsOverlapped = (event1, event2) => {
    if (!event1.timeslotData || !event2.timeslotData) return false;

    let start1 = event1.timeslotData.y,
      start2 = event2.timeslotData.y,
      end1 = event1.timeslotData.y + event1.timeslotData.h,
      end2 = event2.timeslotData.y + event2.timeslotData.h;

    return (start1 < end2 && end1 > start2);
  };

  /**
   * go through list to put overlapping information for each event
   */
  checkOverlappingEvent = (checkingList, event, startLevel) => {
    let tmpEvent, maxLevel;

    if (isArray(checkingList) && checkingList.length > 1) {

      if (!event.overlapInfo) {
        event.overlapInfo = {
          level: startLevel,
          maxLevel: startLevel,
          overlappedEvents: []
        };

        for (let i = 0; i < checkingList.length; i++) {
          tmpEvent = checkingList[i];

          if (event !== tmpEvent && this.isEventsOverlapped(event, tmpEvent)) {
            event.overlapInfo.overlappedEvents.push(tmpEvent);
            maxLevel = this.checkOverlappingEvent(checkingList, tmpEvent, startLevel + 1);
          }
        }

      }

      if (maxLevel > event.overlapInfo.maxLevel) {
        event.overlapInfo.maxLevel = maxLevel;
      }

      return event.overlapInfo.maxLevel;
    }

    return startLevel;
  };

  processTimeslots = (timeSlots, events, acceptOutOfRange) => {
    let startCalSlot = timeSlots[0],
      endCalSlot = timeSlots[timeSlots.length - 1],
      startCalMinuteVal = ((startCalSlot && !this.isNullOrEmpty(startCalSlot.start)) ? this.dateUtils.time2Minute(startCalSlot.start) : -1),
      endCalMinuteVal = ((endCalSlot && !this.isNullOrEmpty(endCalSlot.start)) ? this.dateUtils.time2Minute(endCalSlot.start) : -1);

    if (startCalMinuteVal >= 0 && endCalMinuteVal >= 0 && isArray(events)) {
      events.forEach((event) => {
        let yPosition, xPosition, slotHeight, slotWidth, boxHeight;
        let startDate = this.dateUtils.dateIso2DateTime(event.start);
        let endDate = this.dateUtils.dateIso2DateTime(event.finish);
        let startEventMinuteVal = this.dateUtils.time2Minute(startDate.time),
          endEventMinuteVal = this.dateUtils.time2Minute((endDate.time === 0) ? 2400 : endDate.time),
          travelMinuteVal = (event.travelTime || 0),
          startSlotMinuteVal = startEventMinuteVal - travelMinuteVal;
        let isOutTravel = false,
          isOutStart = false,
          isOutEnd = false,
          isOutCal = false;

        xPosition = 0;
        slotWidth = 100;

        if (acceptOutOfRange === true) {
          if (startSlotMinuteVal < startCalMinuteVal) {
            startSlotMinuteVal = startCalMinuteVal;
            isOutTravel = true;

            isOutStart = (startEventMinuteVal < startCalMinuteVal);
          }

          if (endEventMinuteVal > endCalMinuteVal) {
            endEventMinuteVal = endCalMinuteVal;
            isOutEnd = true;
          }
        }

        // identify y position
        yPosition = this.getRemValue(startSlotMinuteVal - startCalMinuteVal);
        // identify event height
        slotHeight = this.getRemValue(endEventMinuteVal - startSlotMinuteVal);
        // identify box height
        boxHeight = this.getRemValue(endEventMinuteVal - startEventMinuteVal);

        if (boxHeight > slotHeight) {
          boxHeight = slotHeight;
        }

        isOutCal = (endEventMinuteVal <= startCalMinuteVal || startEventMinuteVal >= endCalMinuteVal);

        if (yPosition >= 0 && !isOutCal) {
          event.timeslotData = {
            y: yPosition,
            x: xPosition,
            w: slotWidth,
            h: slotHeight,
            b: boxHeight,
            travelBeforeGrid: isOutTravel,
            startBeforeGrid: isOutStart,
            endAfterGrid: isOutEnd
          };
        }
      });
    }
  };

  /**
   * calculate timeslots tobe shown on calendar
   */
  calculateCalendarTimeslots = () => {
    let tmpTimeSlot, tmpNextTimeSlot, tsH, tsM, tsEH, tsEM, tsHN, tsMN, tsAP;
    let interval, isShown, isTimePart;
    let timeslots = [];
    let tsSurplus, tsAbsolute;

    if (this.calendarSettings && this.calendarSettings.calendarStart >= 0 && this.calendarSettings.calendarEnd >= 0) {
      interval = this.calendarSettings.calendarStep;

      let calendarStartInMinutes = this.dateUtils.time2Minute(this.calendarSettings.calendarStart);
      let calendarEndInMinutes = this.dateUtils.time2Minute(this.calendarSettings.calendarEnd);
      for (tmpTimeSlot = calendarStartInMinutes;
        tmpTimeSlot <= calendarEndInMinutes;
        tmpTimeSlot += interval) {
        tsH = Math.floor(tmpTimeSlot / 60);
        tsM = Math.round(tmpTimeSlot % 60);

        tmpNextTimeSlot = tmpTimeSlot + interval;
        tsEH = Math.floor(tmpNextTimeSlot / 60);
        tsEM = Math.round(tmpNextTimeSlot % 60);

        // hour name
        tsSurplus = tsH % 12;
        tsAbsolute = Math.floor(tsH / 12);
        if (tsSurplus === 0) {
          tsHN = '12';
        } else {
          //tsHN = ('00' + tsSurplus).substr(-2);
          tsHN = tsSurplus;
        }
        tsAP = (tsAbsolute % 2 === 1) ? 'PM' : 'AM';

        // minute name
        tsMN = ('00' + tsM).substr(-2);

        // show timeslot label
        isShown = (tsM === 0 || tsM % interval === 0);
        isTimePart = (tsM !== 0);

        timeslots.push({
          start: (tsH * 100) + tsM,
          end: (tsEH * 100) + tsEM,
          key: ((tsH * 100) + tsM) + '',
          name: tsHN + ':' + tsMN + ' ' + tsAP,
          shown: isShown,
          timePart: isTimePart,
          class: classNames('timeslot-label', 'slds-text-color_weak', {
            'timeslot-label_small': isTimePart
          })
        });
      }
    }

    return timeslots;
  };

  processTimeslotsPreferredTimes = (items, timeSlots) => {
    let startCalSlot = timeSlots[0],
      startCalMinuteVal = ((startCalSlot && !this.isNullOrEmpty(startCalSlot.start)) ? this.dateUtils.time2Minute(startCalSlot.start) : -1);

    items.forEach(function (item) {
      if ((item.hasPreferredTimes || item.isAllTimePreferred) && item.timeslotData) {
        let startTimeMinVal = this.dateUtils.time2Minute(item.startTime);
        let preferredStartTimeMinVal = this.dateUtils.time2Minute(item.preferredStartTime);
        let preferredOffsetStartDuration = preferredStartTimeMinVal - startTimeMinVal;
        let isOutOfCal = startTimeMinVal < startCalMinuteVal;
        let isPreferredTimeOutOfCal = preferredStartTimeMinVal < startCalMinuteVal;
        let timeSlotHeight = item.timeslotData.h;
        let outOfCalDuration = isOutOfCal ? startCalMinuteVal - startTimeMinVal : 0;
        let prferredOutOfCalDuration = isPreferredTimeOutOfCal ? startCalMinuteVal - preferredStartTimeMinVal : 0;
        item.timeSlotPreferredTimeData = {
          t: Math.max(timeSlotHeight * (preferredOffsetStartDuration - prferredOutOfCalDuration - outOfCalDuration) / (item.duration - outOfCalDuration), 0),
          h: timeSlotHeight * (item.preferredTimeDuration - prferredOutOfCalDuration) / (item.duration - outOfCalDuration)
        };
      }
    });
  };

  isInPast = (date, today) => {
    return date.getTime() < today.getTime();
  };

  calculateCalendarDays = (calStartDate, regions, today, calEndDate) => {
    let ONE_DAY_TIME = 86400000;
    let tmpDate, startDate, endDate, dw;
    let tmpHoliday, tmpHolidayDateTime, holidayStartDate, holidayEndDate;
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

      if (this.configData && this.configData.holidays && this.configData.holidays.length > 0) {
        for (let i = 0; i < this.configData.holidays.length; i++) {
          tmpHoliday = this.configData.holidays[i];
          regionIdx = (tmpHoliday.regionId ? regionIds.indexOf(tmpHoliday.regionId) : -1);
          if (tmpHoliday &&
            isDate(tmpHoliday.startDate) && isDate(tmpHoliday.finishDate) &&
            (tmpHoliday.isGlobal || regionIds.indexOf(tmpHoliday.regionId) > -1)) {
            holidayStartDate = tmpHoliday.startDate.getTime();
            holidayEndDate = tmpHoliday.finishDate.getTime();

            if (holidayStartDate <= tmpCalEndDate && holidayEndDate >= tmpCalStartDate) {
              if (holidayStartDate < tmpCalStartDate) {
                tmpHolidayDateTime = tmpCalStartDate;
              } else {
                tmpHolidayDateTime = holidayStartDate;
              }

              if (regionIdx > -1) {
                tmpHoliday.region = regions[regionIdx];
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
    }


    return Object.values(daysMap).map(day => {
      return {
        ...day,
        hasHolidays: day.holidays && day.holidays.length,
        class: classNames('slds-text-color_weak', 'slds-text-align_center', {
          'yesterday': day.isYesterday,
          'today': day.isToday,
          'holiday': day.holidays && day.holidays.length,
        })
      }
    })
  };

  buildCalendarWeeks = (calendarDays, currentMonth, firstDay) => {
    let weeks = [];
    let tmpWeek, tmpDate;

    firstDay = firstDay || 0;

    if (isArray(calendarDays) && calendarDays.length > 0) {
      calendarDays.forEach(function (calDay, idx) {
        tmpDate = calDay.date;

        if (idx === 0 || tmpDate.getDay() === firstDay) {
          tmpWeek = new Array(7);
          weeks.push(tmpWeek);
        }

        // check month
        calDay.isOutofMonth = (currentMonth >= 0 && calDay.date.getMonth() !== currentMonth);

        tmpWeek[(7 + tmpDate.getDay() - firstDay) % 7] = calDay;

      });
    }

    return weeks;
  };
}