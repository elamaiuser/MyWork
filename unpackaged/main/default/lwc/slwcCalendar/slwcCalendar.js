import { LightningElement, api, track, wire} from 'lwc';
import { extend, isArray, cloneDeep, padStart } from 'c/lodash';
import { CurrentPageReference } from 'lightning/navigation';
import { classNames } from 'c/slwcUtils';
import { DateTime } from 'c/luxon';
import { CALENDAR_FIELD_TYPE, CALENDAR_EVENT_LEVEL } from 'c/slwcConstants';
import slwcCalendarHelper from './slwcCalendarHelper';
import { fireEvent } from 'c/pubsub';
import * as slwcDateUtils from 'c/slwcDateUtils';

import TIME_ZONE from '@salesforce/i18n/timeZone';

const DEFAULT_CALENDAR_SETTINGS = {
  timezone: TIME_ZONE,
  calendarStep: 30,
  calendarStart: 0,
  calendarEnd: 2400,
  firstDay: 0
}

const DETAULT_GRID_RENDER_SETTINGS = {
  leftColWidth: 6.5,
  headerHeight: 3,
  slotSize: {
    w: 11.5,
    h: 2.5
  },
  allDayBlock: {
    h: 1.125,
    m: 0.125
  }
}

export default class SlwcCalendar extends LightningElement {
  initialized = false;
  eventRegistered = false;

  _allowSelectTimes = false;
  @api
  get allowSelectTimes() {
    return this._allowSelectTimes;
  }
  set allowSelectTimes(value) {
    this._allowSelectTimes = /^true$/i.test(value);
  }

  @api settings = null;
  @api gridRenderSettings = null;
  @api metadata = null;
  @api configData = null;

  @wire(CurrentPageReference) pageRef;

  _calendarDateRange = {};
  @api
  get calendarDateRange() {
    return this._calendarDateRange;
  }
  set calendarDateRange(value) {
    this._calendarDateRange = value;

    if (this.initialized) {
      this.gridData = this.processGridData(this._data) || {}
    }
  }

  _data = null;
  @track gridData = null;
  @api
  get calendarData() {
    return this._data;
  }
  set calendarData(data) {
    this._data = data;

    if (this.initialized) {
      this.gridData = this.processGridData(this._data) || {}
    }
  }

  get timezone() {
    const timezone = this.settings ? this.settings.timezone : null;
    if (!timezone) return null;
    return DateTime.local().setZone(timezone).toFormat('ZZZZ');
  }

  get dateUtils() {
    return slwcDateUtils.getInstance(this.settings);
  }

  _calendarHelper = null;
  get calendarHelper() {
    if (!this._calendarHelper) {
      this._calendarHelper = new slwcCalendarHelper(this.settings, this.gridRenderSettings);
    }
    return this._calendarHelper;
  }
  
  get customStyle() {
    const gridRenderSettings = this.gridRenderSettings;
    const gridData = {
      allDayEventsCount: 0
    }
    const timeslots = this.timeslots;
    return {
      layoutTableWrapper: [
        `height: 32rem`,
        'width: 100%',
        `overflow: auto`
      ].join(';'),
      cellLeft: [
        `width: ${gridRenderSettings.leftColWidth}rem`
      ].join(';'),
      timeslotTimezone: [
        `height: ${(gridRenderSettings.headerHeight + (gridData.allDayEventsCount * (gridRenderSettings.allDayBlock.h +      gridRenderSettings.allDayBlock.m))) + 0.0625}rem`,
      ].join(';'),
      timeslots: `
        margin-top: -2.5rem;margin-bottom:0.125rem;
      `,
      timeslot: `
        height: ${gridRenderSettings.slotSize.h}rem
      `,
      headerTable: `
        height: ${(gridRenderSettings.headerHeight + (gridData.allDayEventsCount * (gridRenderSettings.allDayBlock.h + gridRenderSettings.allDayBlock.m)))}rem
      `,
      dataContentContainer: [
        `height: ${(timeslots.length - 1) * gridRenderSettings.slotSize.h}rem`,
        `background-size: auto ${(gridRenderSettings.slotSize.h * 4)}rem, auto ${gridRenderSettings.slotSize.h}rem`
      ].join(';'),
      dayColumn: `
        width: ${gridRenderSettings.slotSize.w}rem
      `
    }
  }

  get customClass() {
  }

  get timeslots() {
    return this.calendarHelper.calculateCalendarTimeslots();
  }
  
  get today() {
    return DateTime.local().toJSDate();
  }

  get calendarDays() {
    if(!this.calendarDateRange || !this.calendarDateRange.startDate || !this.calendarDateRange.endDate) return [];

    const startDate = DateTime.fromFormat(this.calendarDateRange.startDate, 'yyyy-MM-dd').toJSDate();
    const endDate = DateTime.fromFormat(this.calendarDateRange.endDate, 'yyyy-MM-dd').toJSDate();
    const today = this.today;

    let days = this.calendarHelper.calculateCalendarDays(startDate, [], today, endDate);
    if(this.gridData) {
      days.forEach(day => {
        day.allEvents = this.gridData.allEventsByDate[day.dateIso] || [];
      })
    }
    return days;
  }

  constructor() {
    super();
  }

  connectedCallback() {
    this.settings = this.initSettings(this.settings)
    this.metadata = this.initMetadata(this.metadata)
    this.gridRenderSettings = this.initGridRenderSettings(this.gridRenderSettings)
    this.configData = this.initConfigData(this.configData)
    
    if (!this.initialized) {
      this.gridData = this.processGridData(this._data) || {}
      this.initialized = true;
    }
  }

  renderedCallback() {
    this.registerEvents();
  }

  disconnectedCallback() {
    this.unregisterEvents();
  }

  registerEvents = () => {
    if(this.eventRegistered) return;
  }

  unregisterEvents = () => {
  }

  initSettings = (settings) => {
    return  extend(DEFAULT_CALENDAR_SETTINGS, settings);
  }

  initMetadata = (metadata) => {
    return metadata;
  }

  initConfigData = (configData) => {
    return configData;
  }

  initGridRenderSettings = (gridRenderSettings) => {
    return extend(DETAULT_GRID_RENDER_SETTINGS, gridRenderSettings)
  }

  processGridData = (data) => {
    if(!this.settings) return null;

    var gridData = cloneDeep(data || {});
    var allDayEvents = [];
    var builtGridData = {
      today: this.today,
      timezone: this.settings.timezone,
      allDayEventsByDate: {},
      allDayEventsCount: 0,
      allEventsByDate: {}
    };

    var processData = (items, mapObject) => {
      if (isArray(items) && items.length > 0) {
        items.forEach((item) => {
          const startDate = this.calendarHelper.parseDateString(item.start);
          const endDate = this.calendarHelper.parseDateString(item.finish);
        
          //TODO
          // if (item.scheduleId) {
          //   item.schedule = _.find(gridData.schedules, { id: item.scheduleId });
          // }

          // if (this.calendarHelper.isAllDayEvent(item)) {
          //   allDayEvents.push(item);
          // } else {
          //   // var dateKey = dateUtil.dateToString(item.startDate);
          //   var dateKey = DateTime.fromJSDate(new Date(startDate.date)).toISODate();

          //   // push item to data map
          //   if (!isArray(mapObject[dateKey])) {
          //     mapObject[dateKey] = [];
          //   }

          //   mapObject[dateKey].push(item);
          // }

          let _endDate = cloneDeep(endDate);
          if(endDate.time === 0) {
            _endDate.endTime = 2400;
            _endDate.date.setDate(_endDate.date.getDate() - 1);
          }

          var diff = this.dateUtils.diffDays(startDate.date, _endDate.date);
          for (let i = 0; i <= diff; i++) {
            let tmpDate = DateTime.fromJSDate(startDate.date).plus({
              days: i
            }).toJSDate();
            let tempItem = cloneDeep(item);
            let tempStartDate = this.calendarHelper.parseDateString(tempItem.start);
            let tempEndDate = this.calendarHelper.parseDateString(tempItem.finish);

            tempStartDate.date = cloneDeep(tmpDate);
            tempStartDate.time = i === 0 ? startDate.time : 0;
            tempEndDate.date = cloneDeep(tmpDate);
            tempEndDate.time = i === diff ? endDate.time : 2400;

            if(tempEndDate.time === 2400 || tempEndDate.time === 0) {
              tempEndDate.time = 0;
              tempEndDate.date = DateTime.fromJSDate(tempEndDate.date).plus({
                days: 1
              }).toJSDate();
            }

            tempItem.start = this.calendarHelper.stringifyDateString(tempStartDate);
            tempItem.finish = this.calendarHelper.stringifyDateString(tempEndDate);

            let dateKey = DateTime.fromJSDate(tmpDate).toISODate();
            // push item to data map
            if (!isArray(mapObject[dateKey])) {
              mapObject[dateKey] = [];
            }

            mapObject[dateKey].push(tempItem);
          }
        });

        Object.values(mapObject).forEach((items) => {
          this.calendarHelper.processTimeslots(this.timeslots, items, true);
          this.calendarHelper.processTimeslotsPreferredTimes(items, this.timeslots);

          // sort by y position
          items.sort(function (item1, item2) {
            return item1.timeslotData && item2.timeslotData && item1.timeslotData.y - item2.timeslotData.y;
          });

          // check overlapping
          items.forEach((item) => {
            this.calendarHelper.checkOverlappingEvent(items, item, 1);
          });

          // calculate postion and width
          items.forEach(function (item) {
            if (item.overlapInfo) {
              item.overlapInfo.overlappedEvents.forEach(function (overlappedEvent) {
                if (item.overlapInfo.maxLevel < overlappedEvent.overlapInfo.maxLevel) {
                  item.overlapInfo.maxLevel = overlappedEvent.overlapInfo.maxLevel;
                } else {
                  overlappedEvent.overlapInfo.maxLevel = item.overlapInfo.maxLevel;
                }
              });

              if (item.timeslotData) {
                item.timeslotData.w = ((Math.round(10000 / item.overlapInfo.maxLevel)) / 100);
                item.timeslotData.x = item.timeslotData.w * (item.overlapInfo.level - 1);
              }
            }
          });
        });
      }
    };

    this.metadata.forEach(item => {
      if (!builtGridData[item.fieldName + 'ByDate']) {
        builtGridData[item.fieldName + 'ByDate'] = [];
      }

      processData(gridData[item.fieldName], builtGridData[item.fieldName + 'ByDate']);
    }) 

    // concat all events to a single array
    this.calendarDays.forEach((day) => {
      var eventsAndAvailability = this.metadata.reduce((result, item) => {
        return result.concat(builtGridData[item.fieldName + 'ByDate'][day.dateIso] || []);
      }, [])
      var allEvents, event;

      allEvents = extend([], builtGridData.allDayEventsByDate[day.dateIso]);

      if (eventsAndAvailability.length > 0) {
        for (var i = 0; i < allEvents.length; i++) {
          event = allEvents[i];
          if (event.redundant) {
            allEvents[i] = eventsAndAvailability[0];
            eventsAndAvailability.splice(0, 1);

            if (eventsAndAvailability.length === 0) {
              break;
            }
          }
        }

        if (eventsAndAvailability.length > 0) {
          allEvents = allEvents.concat(eventsAndAvailability);
        }
      }

      builtGridData.allEventsByDate[day.dateIso] = allEvents;
    });

    return builtGridData;
  };
}